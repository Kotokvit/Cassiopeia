extends Node

## POLER[Ψ] Architecture Engine
## P - Perception (Observer's Eye Mode - Alt key)
## O - Outcome (Rune Combination Engine)
## L - Logic (Causality Geometry Combat)
## e - Energy Value (Dynamic AI Weight Plasticity)
## R[n] - No Excuses Protocol & Spontaneous Refraction

signal perception_toggled(active: bool)
signal rune_crafted(rune_name: String, effect_data: Dictionary)
signal refraction_triggered(location: Vector3, hazard_type: String)
signal ai_plasticity_updated(new_weight: float)

var perception_mode_active: bool = false
var ai_plasticity_weight: float = 1.0 # Increases with player aggression
var tension_energy: float = 0.0 # Accumulates during failure/stuck state for R[n] Refraction
const REFRACTION_THRESHOLD: float = 100.0

func _ready() -> void:
	print("[POLERSystem] Initialized. No Excuses Protocol R[n] active.")

func toggle_perception_mode() -> bool:
	perception_mode_active = !perception_mode_active
	perception_toggled.emit(perception_mode_active)
	print("[POLERSystem] Perception Observer's Eye (P): ", perception_mode_active)
	return perception_mode_active

## Combine base runes (e.g. Tet + Oro -> Lightness Rune)
func craft_rune_combination(rune_a: String, rune_b: String) -> Dictionary:
	var result: Dictionary = {}
	if (rune_a == "Tet" and rune_b == "Oro") or (rune_a == "Oro" and rune_b == "Tet"):
		result = {
			"name": "Lightness Rune (Лёгкость)",
			"mass_reduction": 0.30, # Reduces effective mass by 30%
			"atf_cost": 15.0
		}
	else:
		result = {
			"name": "Resonance Spike (Резонансный Всплеск)",
			"mass_reduction": 0.0,
			"atf_cost": 25.0
		}
	rune_crafted.emit(result["name"], result)
	return result

## Check Causality Geometry (L-Logic) for weapons and projectiles
func validate_causality_path(origin: Vector3, target: Vector3, has_passage_rune: bool) -> bool:
	# If path is obstructed without Passage rune, damage is negated (0 damage)
	if not has_passage_rune and origin.distance_to(target) > 50.0:
		print("[POLERSystem] Causality Path Blocked: Shot negated (0 damage).")
		return false
	return true

## Register player aggression to scale AI Plasticity (e-Energy)
func record_aggression_event(damage_dealt: float) -> void:
	ai_plasticity_weight += damage_dealt * 0.001
	ai_plasticity_updated.emit(ai_plasticity_weight)

## R[n] No Excuses Protocol: accumulate tension energy when player fails or gets stuck
func add_stuck_tension(amount: float, player_position: Vector3) -> void:
	tension_energy += amount
	print("[POLERSystem] R[n] Tension Energy: %.1f / %.1f" % [tension_energy, REFRACTION_THRESHOLD])
	
	if tension_energy >= REFRACTION_THRESHOLD:
		_trigger_spontaneous_refraction(player_position)

func _trigger_spontaneous_refraction(pos: Vector3) -> void:
	tension_energy = 0.0
	print("[POLERSystem] R[n] REFRACTION TRIGGERED! Wall collapsed creating new high-radiation path.")
	refraction_triggered.emit(pos, "Radiation Hazard / Structural Collapse")
