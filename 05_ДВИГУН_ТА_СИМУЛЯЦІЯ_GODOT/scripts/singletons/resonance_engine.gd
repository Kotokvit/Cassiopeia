## ResonanceEngine.gd — Global Singleton
## Управляет резонансными эффектами, рунами, квантовыми туннелями
## Связывает POLER-систему с игровыми механиками
extends Node

signal resonance_triggered(rune_id: String, intensity: float)
signal quantum_tunnel_opened(position: Vector3, duration: float)
signal reality_density_changed(object_path: String, new_density: float)
signal resonance_cascade_warning(level: float)
signal resonance_stabilized()
signal blind_spot_revealed(position: Vector3, type: String)

const MAX_RESONANCE_INTENSITY: float = 100.0
const CASCADE_THRESHOLD: float = 80.0
const STABILITY_THRESHOLD: float = 20.0
const TUNNEL_BASE_COST: float = 35.0  # ATF
const DENSITY_CHANGE_COST: float = 25.0  # ATF

var global_resonance_level: float = 0.0
var active_resonance_effects: Array = []
var quantum_tunnels: Array = []
var resonance_hotspots: Dictionary = {}  # position -> intensity
var cascade_counter: float = 0.0
var is_cascade_imminent: bool = false

# Resonator-Editor specific
var can_edit_reality_code: bool = false
var reality_edit_power: float = 1.0  # scales with level

# Resonator-Analyst specific  
var can_see_blind_spots: bool = false
var spatial_manipulator_range: float = 10.0

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	# Natural resonance decay
	if global_resonance_level > 0:
		global_resonance_level = max(global_resonance_level - 0.1 * delta, 0.0)
	
	# Check cascade threshold
	if global_resonance_level >= CASCADE_THRESHOLD:
		if not is_cascade_imminent:
			is_cascade_imminent = true
			resonance_cascade_warning.emit(global_resonance_level)
	elif is_cascade_imminent:
		is_cascade_imminent = false
		resonance_stabilized.emit()
	
	# Update active effects
	_update_effects(delta)

## Trigger a rune resonance effect
func trigger_rune(rune_id: String, intensity: float = 1.0) -> bool:
	var echo_add = intensity * 5.0
	if not ATF_Balance.spend_atf(15.0 * intensity, echo_add):
		return false
	
	global_resonance_level = min(global_resonance_level + intensity * 10.0, MAX_RESONANCE_INTENSITY)
	
	var effect = {
		"rune_id": rune_id,
		"intensity": intensity,
		"duration": 5.0 * intensity,
		"time_left": 5.0 * intensity,
		"position": Vector3.ZERO  # set by caller
	}
	active_resonance_effects.append(effect)
	resonance_triggered.emit(rune_id, intensity)
	return true

## Open a quantum tunnel (Resonator-Editor ability)
func open_quantum_tunnel(from: Vector3, to: Vector3, duration: float = 3.0) -> bool:
	if not can_edit_reality_code:
		return false
	if not ATF_Balance.spend_atf(TUNNEL_BASE_COST, 8.0):
		return false
	
	var tunnel = {
		"from": from,
		"to": to,
		"duration": duration,
		"time_left": duration,
		"is_active": true
	}
	quantum_tunnels.append(tunnel)
	quantum_tunnel_opened.emit(from, duration)
	return true

## Change material density (Resonator-Editor S-class)
## Example: wolfram -> aerogel
func change_density(object_path: String, original_density: float, target_density: float) -> bool:
	if not can_edit_reality_code:
		return false
	var cost = DENSITY_CHANGE_COST * (original_density / target_density)
	if not ATF_Balance.spend_atf(cost, cost * 0.3):
		return false
	
	var density_ratio = target_density / original_density
	reality_density_changed.emit(object_path, target_density)
	
	# Apply to actual node if exists
	var node = get_node_or_null(object_path)
	if node and node is RigidBody3D:
		node.mass *= density_ratio
	
	return true

## Reveal blind spot (Resonator-Analyst ability)
func reveal_blind_spot(position: Vector3, spot_type: String) -> void:
	if not can_see_blind_spots:
		return
	blind_spot_revealed.emit(position, spot_type)

## Use Spatial Manipulator (Resonator-Analyst)
func use_spatial_manipulator(target_pos: Vector3, manipulation_type: String) -> bool:
	var cost = 20.0
	if not ATF_Balance.spend_atf(cost, 3.0):
		return false
	
	# Types: "vent_access", "enemy_path_prediction", "secret_route"
	match manipulation_type:
		"vent_access":
			reveal_blind_spot(target_pos, "ventilation")
		"enemy_path_prediction":
			reveal_blind_spot(target_pos, "enemy_trajectory")
		"secret_route":
			reveal_blind_spot(target_pos, "hidden_path")
	return true

func _update_effects(delta: float) -> void:
	var to_remove: Array = []
	for i in range(active_resonance_effects.size()):
		var effect = active_resonance_effects[i]
		effect["time_left"] -= delta
		if effect["time_left"] <= 0:
			to_remove.append(i)
	for i in to_remove:
		active_resonance_effects.remove_at(i)
	
	# Update quantum tunnels
	var tunnel_remove: Array = []
	for i in range(quantum_tunnels.size()):
		var tunnel = quantum_tunnels[i]
		tunnel["time_left"] -= delta
		if tunnel["time_left"] <= 0:
			tunnel["is_active"] = false
			tunnel_remove.append(i)
	for i in tunnel_remove:
		quantum_tunnels.remove_at(i)

## Get active tunnel near position
func get_active_tunnel_near(pos: Vector3, max_distance: float = 2.0) -> Dictionary:
	for tunnel in quantum_tunnels:
		if tunnel["is_active"]:
			if pos.distance_to(tunnel["from"]) <= max_distance:
				return tunnel
	return {}

## Register resonance hotspot
func register_hotspot(position: Vector3, intensity: float) -> void:
	resonance_hotspots[position] = intensity

## Get hotspot intensity at position
func get_hotspot_at(pos: Vector3, radius: float = 5.0) -> float:
	var max_intensity = 0.0
	for hotspot_pos in resonance_hotspots:
		if pos.distance_to(hotspot_pos) <= radius:
			max_intensity = max(max_intensity, resonance_hotspots[hotspot_pos])
	return max_intensity

## Set archetype abilities
func set_archetype(archetype: String) -> void:
	match archetype:
		"resonator_editor":
			can_edit_reality_code = true
			can_see_blind_spots = false
			reality_edit_power = 1.0
		"biomech_active":
			can_edit_reality_code = false
			can_see_blind_spots = false
		"resonator_analyst":
			can_edit_reality_code = false
			can_see_blind_spots = true
			spatial_manipulator_range = 10.0
