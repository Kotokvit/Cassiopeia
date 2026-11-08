## EnemyBase.gd — Base enemy script with adaptive AI
## Supports ε plasticity and faction-based behavior
extends CharacterBody3D

signal enemy_died(enemy_id: String, faction: String)
signal enemy_alerted(enemy_id: String, target_position: Vector3)
signal enemy_combat_event(enemy_id: String, event_type: String)

# Identity
@export var enemy_id: String = "enemy_default"
@export var faction: String = "bureau_sterilization"  # bureau, shadows, anomaly
@export var enemy_class: String = "patrol"  # patrol, assassin, anomaly_shum

# Stats
@export var hp: float = 50.0
@export var hp_max: float = 50.0
@export var speed: float = 3.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 5.0
@export var detection_range: float = 15.0
@export var suppression_resistance: float = 0.6  # resistance to resonance suppressors

# Adaptive AI (ε plasticity)
var ai_weights: Dictionary = {
	"attack": 0.7,
	"flank": 0.1,
	"ambush": 0.05,
	"retreat": 0.1,
	"shield": 0.05,
}
var ai_plasticity: float = 0.1  # how fast AI adapts to player
var learned_player_patterns: Dictionary = {}
var last_player_position: Vector3 = Vector3.ZERO
var player_detected: bool = false
var combat_state: String = "idle"  # idle, patrol, alerted, combat, retreating

# Movement
var patrol_points: Array = []
var current_patrol_index: int = 0
var patrol_wait_time: float = 3.0
var patrol_timer: float = 0.0

# Timers
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var flank_timer: float = 0.0

func _ready() -> void:
	# Set collision layer to Enemies
	collision_layer = 2
	collision_mask = 1 | 4 | 7  # Player, Environment, Triggers
	
	# Faction-specific configuration
	_apply_faction_config()

func _physics_process(delta: float) -> void:
	_update_detection()
	_update_ai(delta)
	_update_combat(delta)
	move_and_slide()

func _update_combat(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

func _apply_faction_config() -> void:
	match faction:
		"bureau_sterilization":
			hp_max = 60.0
			attack_damage = 20.0
			speed = 2.5
			suppression_resistance = 0.8
		"shadows":
			hp_max = 40.0
			attack_damage = 35.0  # penetrating weapon
			speed = 5.0
			detection_range = 20.0
			suppression_resistance = 0.3  # low defense against zone damage
		"anomaly_shum":
			hp_max = 80.0
			attack_damage = 25.0  # chaotic waves
			speed = 2.0
	
	hp = hp_max

func _update_detection() -> void:
	# Check if player is in detection range
	var player = GravityManager.player_node if GravityManager else null
	if player:
		var dist = global_position.distance_to(player.global_position)
		if dist <= detection_range:
			player_detected = true
			last_player_position = player.global_position
			if combat_state == "idle" or combat_state == "patrol":
				combat_state = "alerted"
				enemy_alerted.emit(enemy_id, player.global_position)
		elif combat_state != "retreating":
			player_detected = false
			combat_state = "patrol"

func _update_ai(delta: float) -> void:
	# ε plasticity: adapt AI weights based on player behavior
	if player_detected:
		_adapt_weights(delta)
	
	# Choose action based on weighted probabilities
	if combat_state == "combat" or combat_state == "alerted":
		var action = _choose_action()
		_execute_action(action, delta)
	elif combat_state == "patrol":
		_patrol(delta)

func _adapt_weights(delta: float) -> void:
	if not POLERSystem:
		return
	var tactics = POLERSystem.get_current_tactics() if POLERSystem.has_method("get_current_tactics") else []
	var plasticity = (POLERSystem.get("plasticity_level") if POLERSystem.get("plasticity_level") != null else 10.0) / 100.0
	
	# Increase weight of tactics available at current ε level
	for tactic in tactics:
		if ai_weights.has(tactic):
			ai_weights[tactic] += plasticity * delta * 0.5
	
	# Learn player patterns
	var player = GravityManager.player_node if GravityManager else null
	if player:
		var pattern_key = str(int(player.global_position.x / 5)) + "_" + str(int(player.global_position.z / 5))
		if not learned_player_patterns.has(pattern_key):
			learned_player_patterns[pattern_key] = {"count": 1, "direction": player.velocity.normalized()}
		else:
			learned_player_patterns[pattern_key]["count"] += 1
	
	# Normalize weights
	var total = 0.0
	for key in ai_weights:
		total += ai_weights[key]
	if total > 0:
		for key in ai_weights:
			ai_weights[key] /= total

func _choose_action() -> String:
	var rng = randf()
	var cumulative = 0.0
	for action in ai_weights:
		cumulative += ai_weights[action]
		if rng <= cumulative:
			return action
	return "attack"

func _execute_action(action: String, delta: float) -> void:
	var player = GravityManager.player_node if GravityManager else null
	if not player:
		return
	
	match action:
		"attack":
			var dist = global_position.distance_to(player.global_position)
			if dist <= attack_range:
				if attack_timer <= 0:
					_do_attack(player)
					attack_timer = attack_cooldown
			else:
				_move_toward(player.global_position, speed, delta)
		"flank":
			var flank_pos = player.global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
			_move_toward(flank_pos, speed * 1.2, delta)
		"ambush":
			combat_state = "ambushing"
		"retreat":
			var retreat_dir = (global_position - player.global_position).normalized()
			_move_toward(global_position + retreat_dir * 10, speed, delta)
			if global_position.distance_to(player.global_position) > detection_range * 1.5:
				combat_state = "patrol"
		"shield":
			pass

func _do_attack(target: Node3D) -> void:
	if not target or not target.has_method("take_damage"):
		return
	
	var damage = attack_damage
	
	# Faction-specific attack modifiers
	match faction:
		"shadows":
			if randf() < 0.3:
				var teleport_offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
				global_position = target.global_position + teleport_offset
				damage *= 1.5
		"anomaly_shum":
			damage = attack_damage * randf_range(0.5, 1.5)
			_apply_anomaly_debuffs(target)
		"bureau_sterilization":
			_apply_suppression(target)
	
	target.take_damage(damage)
	enemy_combat_event.emit(enemy_id, "attack")
	if POLERSystem and POLERSystem.has_method("register_combat_event"):
		POLERSystem.register_combat_event()

func _apply_anomaly_debuffs(target: Node3D) -> void:
	if not ATF_Balance:
		return
	var debuff_type = ["disorientation", "accuracy_penalty", "random_rune_trigger"][randi() % 3]
	match debuff_type:
		"disorientation":
			ATF_Balance.add_effect("disorientation", 5.0, {"speed_penalty": 0.5})
		"accuracy_penalty":
			ATF_Balance.add_effect("accuracy_penalty", 8.0, {"rune_accuracy_penalty": 0.3})
		"random_rune_trigger":
			ATF_Balance.add_effect("random_rune", 3.0, {})

func _apply_suppression(target: Node3D) -> void:
	if not ATF_Balance:
		return
	var dist = global_position.distance_to(target.global_position)
	if dist <= 5.0:
		ATF_Balance.add_effect("rune_suppressed", 10.0, {"rune_efficiency_penalty": 0.4})

func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return
	
	patrol_timer -= delta
	if patrol_timer <= 0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		patrol_timer = patrol_wait_time
	
	_move_toward(patrol_points[current_patrol_index], speed * 0.5, delta)

func _move_toward(target_pos: Vector3, move_speed: float, delta: float) -> void:
	var direction = (target_pos - global_position).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	var gravity_val: float = GravityManager.get_current_gravity() if GravityManager else 13.72
	velocity.y -= gravity_val * delta

func take_damage(amount: float) -> void:
	hp -= amount
	if EconomyManager and EconomyManager.has_item("resonance_suppressor"):
		amount *= 0.6
	
	if hp <= 0:
		hp = 0
		_die()
	
	combat_state = "combat"

func _die() -> void:
	enemy_died.emit(enemy_id, faction)
	_drop_loot()
	queue_free()

func _drop_loot() -> void:
	if not EconomyManager:
		return
	match faction:
		"bureau_sterilization":
			EconomyManager.add_item("sweep_baton", 1)
		"shadows":
			EconomyManager.add_item("plasma_whip", 1)
			EconomyManager.add_corals(randf_range(5.0, 15.0))
		"anomaly_shum":
			EconomyManager.add_corals(randf_range(2.0, 8.0))

func set_patrol_points(points: Array) -> void:
	patrol_points = points

func export_ai_state() -> Dictionary:
	return {
		"weights": ai_weights,
		"patterns": learned_player_patterns,
		"plasticity": ai_plasticity,
		"combat_state": combat_state,
	}

func import_ai_state(state: Dictionary) -> void:
	ai_weights = state.get("weights", ai_weights)
	learned_player_patterns = state.get("patterns", {})
	ai_plasticity = state.get("plasticity", ai_plasticity)
