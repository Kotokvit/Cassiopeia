## GravityManager.gd — Global Singleton
## Управляет гравитацией 1.4g и её эффектами
## Падение >2м = мгновенный летальный урон без защиты
extends Node

signal gravity_zone_changed(zone_type: String, g_value: float)
signal fall_damage_triggered(fall_height: float, damage: float)
signal lethal_fall_triggered(fall_height: float)
signal gravity_stress_updated(stress_level: float)

const CASSIOPEIA_G: float = 13.72  # 1.4 * 9.8 m/s²
const EARTH_G: float = 9.8
const LETHAL_FALL_HEIGHT: float = 2.0  # meters — instant death
const SAFE_FALL_HEIGHT: float = 0.8  # meters — no damage
const GRAVITY_STRESS_BASE: float = 1.4  # multiplier for stamina drain

# Local gravity overrides (e.g., maglev platforms, rune effects)
var local_gravity_override: float = -1.0  # -1 means use global
var gravity_zones: Dictionary = {}  # zone_name -> g_value

# Player tracking
var player_node: Node3D = null
var last_ground_y: float = 0.0
var was_on_ground: bool = true
var fall_start_y: float = 0.0
var is_falling: bool = false

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	# Register default gravity zone
	gravity_zones["default"] = CASSIOPEIA_G
	gravity_zones["maglev_platform"] = 5.0  # reduced gravity
	gravity_zones["rune_lightened"] = EARTH_G  # 1.0g via rune

func get_current_gravity() -> float:
	if local_gravity_override >= 0:
		return local_gravity_override
	return gravity_zones.get("default", CASSIOPEIA_G)

func get_gravity_vector() -> Vector3:
	return Vector3(0, -get_current_gravity(), 0)

func get_gravity_stress_factor() -> float:
	var g = get_current_gravity()
	return g / EARTH_G  # 1.4 for default, less for reduced zones

## Enter a gravity zone (maglev, rune effect, etc.)
func enter_gravity_zone(zone_name: String) -> void:
	if gravity_zones.has(zone_name):
		local_gravity_override = gravity_zones[zone_name]
		gravity_zone_changed.emit(zone_name, local_gravity_override)

## Leave gravity zone, return to default
func leave_gravity_zone() -> void:
	local_gravity_override = -1.0
	gravity_zone_changed.emit("default", CASSIOPEIA_G)

## Check fall damage when player lands
func check_fall_damage(fall_height: float) -> Dictionary:
	if fall_height >= LETHAL_FALL_HEIGHT:
		lethal_fall_triggered.emit(fall_height)
		return {"lethal": true, "damage": 99999.0}
	elif fall_height > SAFE_FALL_HEIGHT:
		# Linear damage between safe and lethal
		var damage_range = LETHAL_FALL_HEIGHT - SAFE_FALL_HEIGHT
		var damage_percent = (fall_height - SAFE_FALL_HEIGHT) / damage_range
		var damage = damage_percent * 80.0  # up to 80 HP
		fall_damage_triggered.emit(fall_height, damage)
		return {"lethal": false, "damage": damage}
	return {"lethal": false, "damage": 0.0}

## Apply rune "Lightness" effect (reduce effective gravity for target)
func apply_rune_lightness(duration: float = 10.0) -> void:
	enter_gravity_zone("rune_lightened")
	# Auto-restore after duration
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(leave_gravity_zone)

## Apply gravity constant change (Resonator-Editor S-class ability)
func set_local_gravity_constant(g_value: float, duration: float = 5.0) -> void:
	local_gravity_override = g_value
	gravity_zone_changed.emit("custom", g_value)
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		local_gravity_override = -1.0
		gravity_zone_changed.emit("default", CASSIOPEIA_G)
	)

func register_player(player: Node3D) -> void:
	player_node = player

func unregister_player() -> void:
	player_node = null
