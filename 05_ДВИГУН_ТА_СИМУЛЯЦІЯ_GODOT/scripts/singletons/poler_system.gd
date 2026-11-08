## POLERSystem.gd — Global Singleton
## ℘–O–L–ε–R[n] — пять слоев игровой механики
extends Node

signal perception_activated()
signal perception_deactivated()
signal perception_node_highlighted(node_type: String, position: Vector3)
signal image_crafted(combo_id: String)
signal logic_barrier_detected(barrier_type: String, position: Vector3)
signal logic_barrier_bypassed(barrier_type: String, rune_used: String)
signal epsilon_plasticity_changed(new_level: float)
signal epsilon_tactics_changed(tactic: String)
signal no_excuses_tension_changed(tension: float)
signal no_excuses_refraction_triggered(position: Vector3, danger_level: float)

# ℘ — Perception
var perception_active: bool = false
var perception_boost_duration: float = 0.0
var perception_boost_timer: float = 0.0
var highlighted_nodes: Array = []

# O — Image (handled by RunesRegistry)
var crafting_queue: Array = []

# L — Logic (causal geometry)
var causal_barriers: Dictionary = {}
var projectile_trajectories: Array = []

# ε — Energy of Significance (dynamic difficulty)
var plasticity_level: float = 0.0  # 0-100, scales with player aggression
var aggression_score: float = 0.0
var recent_combat_events: Array = []  # timestamps
var enemy_tactics_pool: Array = ["flank", "ambush", "overwhelm", "snipe", "shield_wall"]
var active_enemy_tactics: Array = ["basic_attack"]

# R[n] — No Excuses Protocol
var tension_energy: float = 0.0
var tension_threshold: float = 50.0
var failed_attempts_log: Array = []
var refraction_zones: Array = []

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if perception_boost_timer > 0:
		perception_boost_timer -= delta
		if perception_boost_timer <= 0:
			perception_boost_duration = 0
	_update_epsilon(delta)
	_update_tension(delta)

func _update_tension(_delta: float) -> void:
	pass

# === ℘ (Perception) ===
func activate_perception() -> void:
	if ATF_Balance and not ATF_Balance.spend_atf(5.0, 1.0):
		return
	perception_active = true
	perception_activated.emit()
	_scan_environment()

func deactivate_perception() -> void:
	perception_active = false
	perception_deactivated.emit()
	highlighted_nodes.clear()

func activate_perception_boost(duration: float) -> void:
	perception_boost_duration = duration
	perception_boost_timer = duration
	activate_perception()

func _scan_environment() -> void:
	var sample_nodes = [
		{"type": "structural_weakness", "position": Vector3(5, 0, 3)},
		{"type": "patrol_route", "position": Vector3(-10, 2, 7)},
		{"type": "resonance_hotspot", "position": Vector3(0, 5, -5)},
	]
	for node in sample_nodes:
		highlighted_nodes.append(node)
		perception_node_highlighted.emit(node["type"], node["position"])

# === L (Logic) ===
func check_trajectory(_origin: Vector3, _direction: Vector3, _max_range: float = 100.0) -> Dictionary:
	var result = {
		"valid": true,
		"barrier": null,
		"barrier_type": "",
		"damage_multiplier": 1.0
	}
	
	for barrier_id in causal_barriers:
		var barrier = causal_barriers[barrier_id]
		if barrier.get("impenetrable", false) and not _has_passage_rune():
			result["valid"] = false
			result["barrier"] = barrier_id
			result["barrier_type"] = barrier["type"]
			result["damage_multiplier"] = 0.0
			logic_barrier_detected.emit(barrier["type"], barrier["position"])
			return result
	
	return result

func register_barrier(barrier_id: String, barrier_type: String, position: Vector3, impenetrable: bool = true) -> void:
	causal_barriers[barrier_id] = {
		"type": barrier_type,
		"position": position,
		"impenetrable": impenetrable
	}

func remove_barrier(barrier_id: String) -> void:
	causal_barriers.erase(barrier_id)

func _has_passage_rune() -> bool:
	if not RunesRegistry:
		return false
	var disc = RunesRegistry.get("discovered_combinations") if RunesRegistry.get("discovered_combinations") != null else []
	var learned = RunesRegistry.get("learned_runes") if RunesRegistry.get("learned_runes") != null else []
	return "passage" in disc or ("vei" in learned and "nul" in learned)

# === ε (Energy of Significance) ===
func _update_epsilon(_delta: float) -> void:
	var recent_count = 0
	var now = Time.get_ticks_msec() / 1000.0
	for timestamp in recent_combat_events:
		if now - timestamp < 60.0:
			recent_count += 1
	
	aggression_score = recent_count / 10.0
	plasticity_level = min(aggression_score * 20.0 + 10.0, 100.0)
	
	if plasticity_level > 30.0:
		active_enemy_tactics = ["basic_attack", "flank"]
	if plasticity_level > 50.0:
		active_enemy_tactics = ["basic_attack", "flank", "ambush"]
	if plasticity_level > 70.0:
		active_enemy_tactics = ["basic_attack", "flank", "ambush", "overwhelm", "snipe"]
	
	epsilon_plasticity_changed.emit(plasticity_level)

func register_combat_event() -> void:
	recent_combat_events.append(Time.get_ticks_msec() / 1000.0)
	if recent_combat_events.size() > 30:
		recent_combat_events = recent_combat_events.slice(-30)

func get_current_tactics() -> Array:
	return active_enemy_tactics

# === R[n] (No Excuses Protocol) ===
func register_failed_attempt(context: String) -> void:
	failed_attempts_log.append({
		"context": context,
		"timestamp": Time.get_ticks_msec() / 1000.0
	})
	tension_energy += 5.0
	no_excuses_tension_changed.emit(tension_energy)
	
	if tension_energy >= tension_threshold:
		trigger_refraction()

func trigger_refraction() -> void:
	tension_energy = 0.0
	var danger_level = randf_range(0.3, 0.8)
	no_excuses_refraction_triggered.emit(Vector3.ZERO, danger_level)
	refraction_zones.append({
		"position": Vector3.ZERO,
		"danger_level": danger_level,
		"type": "wall_breach"
	})

func clear_tension() -> void:
	tension_energy = 0.0
	failed_attempts_log.clear()

func get_tension_level() -> float:
	return tension_energy / tension_threshold

func get_refraction_zones() -> Array:
	return refraction_zones
