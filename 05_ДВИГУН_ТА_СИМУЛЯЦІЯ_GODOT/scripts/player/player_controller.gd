## PlayerController.gd — Main player controller
## Handles movement, combat, rune activation, POLER interaction
extends CharacterBody3D

# Movement constants (1.4g adapted)
const WALK_SPEED: float = 4.0
const SPRINT_SPEED: float = 7.0
const JUMP_VELOCITY_BASE: float = 6.5  # adjusted for 1.4g
const ACCELERATION: float = 8.0
const DECELERATION: float = 10.0
const MOUSE_SENSITIVITY: float = 0.003
const MAX_CARRY_WEIGHT_KG: float = 30.0  # Σ archetype bonus

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var interaction_ray: RayCast3D = $Camera3D/InteractionRay
@onready var weapon_raycast: RayCast3D = $Camera3D/WeaponRaycast
@onready var resonance_area: Area3D = $ResonanceArea
@onready var mesh: MeshInstance3D = $CharacterMesh

# State
var input_dir: Vector2 = Vector2.ZERO
var is_sprinting: bool = false
var is_perception_active: bool = false
var current_weapon: String = "none"
var weapon_damage_base: float = 10.0
var attack_cooldown: float = 0.5
var attack_timer: float = 0.0
var gravity_stress_applied: bool = false
var fall_tracking_y: float = 0.0
var was_in_air: bool = false

# Archetype-specific overrides
var speed_modifier: float = 1.0
var jump_modifier: float = 1.0
var damage_modifier: float = 1.0
var carry_modifier: float = 1.0

signal hp_changed(current: float, max_v: float)

func _ready() -> void:
	if GravityManager:
		GravityManager.register_player(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_apply_archetype()

func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_fall_damage()
	_handle_combat(delta)
	_handle_interactions()
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2 + 0.1, PI/2 - 0.1)
	
	if event.is_action_pressed("perception_mode"):
		if POLERSystem:
			if is_perception_active:
				POLERSystem.deactivate_perception()
				is_perception_active = false
			else:
				POLERSystem.activate_perception()
				is_perception_active = true
	
	if event.is_action_pressed("rune_menu"):
		get_tree().call_group("ui", "show_rune_menu")
	
	if event.is_action_pressed("rune_activate"):
		_activate_equipped_rune()
	
	if event.is_action_pressed("interact"):
		_interact_with_object()
	
	if event.is_action_pressed("inventory"):
		get_tree().call_group("ui", "toggle_inventory")

func _handle_input(_delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	is_sprinting = Input.is_action_pressed("sprint")
	
	if is_sprinting and velocity.length() > WALK_SPEED and ATF_Balance:
		ATF_Balance.spend_oxygen(ATF_Balance.oxygen_consumption_sprint)
		ATF_Balance.spend_atf(0.5, 0.0)

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		var grav = GravityManager.get_current_gravity() if GravityManager else 13.72
		velocity.y -= grav * delta
		if not was_in_air:
			fall_tracking_y = global_position.y
			was_in_air = true
	else:
		was_in_air = false
		fall_tracking_y = global_position.y
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		var jump_vel = JUMP_VELOCITY_BASE * jump_modifier
		if GravityManager:
			var grav_ratio = GravityManager.get_current_gravity() / GravityManager.CASSIOPEIA_G
			jump_vel *= grav_ratio
		velocity.y = jump_vel
		if ATF_Balance:
			ATF_Balance.spend_atf(3.0, 1.0)

func _handle_movement(delta: float) -> void:
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_speed = (WALK_SPEED if not is_sprinting else SPRINT_SPEED) * speed_modifier
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, ACCELERATION * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		velocity.z = move_toward(velocity.z, 0, DECELERATION * delta)
	
	if GameState and GameState.get("player_archetype") != "biomech_active" and GravityManager and ATF_Balance:
		var stress = GravityManager.get_gravity_stress_factor()
		ATF_Balance.gravity_stress_factor = stress

func _handle_fall_damage() -> void:
	if is_on_floor() and was_in_air and GravityManager and ATF_Balance:
		var fall_height = fall_tracking_y - global_position.y
		var result = GravityManager.check_fall_damage(fall_height)
		if result.get("lethal", false):
			ATF_Balance.hp = 0
			ATF_Balance.is_dead = true
			ATF_Balance.player_died.emit()
		elif result.get("damage", 0) > 0:
			ATF_Balance.hp -= result["damage"]
			hp_changed.emit(ATF_Balance.hp, ATF_Balance.hp_max)

func _handle_combat(delta: float) -> void:
	attack_timer -= delta
	if attack_timer > 0:
		return
	
	if Input.is_action_pressed("attack_primary"):
		_primary_attack()
	elif Input.is_action_pressed("attack_secondary"):
		_secondary_attack()

func _handle_interactions() -> void:
	pass

func _primary_attack() -> void:
	attack_timer = attack_cooldown
	
	if POLERSystem and POLERSystem.has_method("check_trajectory"):
		var trajectory_check = POLERSystem.check_trajectory(
			camera.global_position, -camera.global_transform.basis.z, 100.0
		)
		if not trajectory_check.get("valid", true):
			return
	
	var damage = weapon_damage_base * damage_modifier
	if GameState and GameState.get("player_archetype") == "biomech_active" and GravityManager:
		damage *= GravityManager.get_current_gravity() / GravityManager.EARTH_G
	
	if ATF_Balance and ATF_Balance.has_method("get_mutation_debuffs"):
		var debuffs = ATF_Balance.get_mutation_debuffs()
		if debuffs.has("rune_accuracy_penalty"):
			damage *= (1.0 - debuffs["rune_accuracy_penalty"])
	
	weapon_raycast.target_position = Vector3(0, 0, -50)
	weapon_raycast.force_raycast_update()
	if weapon_raycast.is_colliding():
		var target = weapon_raycast.get_collider()
		if target and target.has_method("take_damage"):
			target.take_damage(damage)
			if POLERSystem and POLERSystem.has_method("register_combat_event"):
				POLERSystem.register_combat_event()
	
	if ATF_Balance:
		ATF_Balance.spend_atf(2.0, 0.5)

func _secondary_attack() -> void:
	attack_timer = attack_cooldown * 2
	var damage = weapon_damage_base * damage_modifier * 2.0
	if ATF_Balance:
		ATF_Balance.spend_atf(5.0, 2.0)
	
	weapon_raycast.target_position = Vector3(0, 0, -30)
	weapon_raycast.force_raycast_update()
	if weapon_raycast.is_colliding():
		var target = weapon_raycast.get_collider()
		if target and target.has_method("take_damage"):
			target.take_damage(damage)

func _activate_equipped_rune() -> void:
	if RunesRegistry and RunesRegistry.get("equipped_runes"):
		var eq_runes: Array = RunesRegistry.equipped_runes
		if eq_runes.size() > 0 and eq_runes[0] != "" and ResonanceEngine:
			ResonanceEngine.trigger_rune(eq_runes[0], 1.0)

func _interact_with_object() -> void:
	interaction_ray.target_position = Vector3(0, 0, -3)
	interaction_ray.force_raycast_update()
	if interaction_ray.is_colliding():
		var target = interaction_ray.get_collider()
		if target:
			if target.has_method("interact"):
				target.interact()
			elif target.has_method("start_dialogue"):
				target.start_dialogue()

func _apply_archetype() -> void:
	var arch_type: String = GameState.player_archetype if GameState else "resonator_editor"
	match arch_type:
		"resonator_editor":
			speed_modifier = 0.9
			jump_modifier = 0.85
			damage_modifier = 0.7
			carry_modifier = 1.0
		"biomech_active":
			speed_modifier = 0.95
			jump_modifier = 0.9
			damage_modifier = 1.4
			carry_modifier = 2.0
			attack_cooldown = 0.8
		"resonator_analyst":
			speed_modifier = 1.1
			jump_modifier = 0.85
			damage_modifier = 0.5
			carry_modifier = 0.8

func take_damage(amount: float) -> void:
	if ATF_Balance:
		ATF_Balance.hp -= amount
		if ATF_Balance.hp <= 0:
			ATF_Balance.hp = 0
			ATF_Balance.is_dead = true
			ATF_Balance.player_died.emit()

func heal(amount: float) -> void:
	if ATF_Balance:
		ATF_Balance.heal_hp(amount)
