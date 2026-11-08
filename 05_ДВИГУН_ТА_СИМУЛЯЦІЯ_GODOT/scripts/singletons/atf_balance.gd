## ATF_Balance.gd — Global Singleton
## Аксиома Вериса (V = -k·ΔH) — метаболическая экономика
## Управляет АТФ, кислородом, Руническим эхом, перегревом
extends Node

signal atf_changed(new_value: float, max_value: float)
signal oxygen_changed(new_value: float, max_value: float)
signal hp_changed(new_value: float, max_value: float)
signal rune_echo_changed(current_echo: float)
signal body_temperature_changed(temp: float)
signal heart_rate_changed(rate: float)
signal overheating_started()
signal overheating_ended()
signal player_died()
signal atf_critical()

# Аксиома Вериса constants
const VERISA_K: float = 0.85  # Base coefficient k in V = -k·ΔH
const BASE_ATF_MAX: float = 100.0
const BASE_HP_MAX: float = 100.0
const BASE_OXYGEN_MAX: float = 100.0
const CRITICAL_ATF_THRESHOLD: float = 15.0
const ECHO_OVERHEAT_THRESHOLD: float = 40.0  # °C body temp threshold
const ECHO_MAX_BEFORE_DAMAGE: float = 30.0
const HEART_RATE_BASE: float = 80.0
const HEART_RATE_MAX: float = 232.0
const OVERHEAT_DAMAGE_PER_SEC: float = 5.0

# Current state
var atf: float = BASE_ATF_MAX
var atf_max: float = BASE_ATF_MAX
var oxygen: float = BASE_OXYGEN_MAX
var oxygen_max: float = BASE_OXYGEN_MAX
var hp: float = BASE_HP_MAX
var hp_max: float = BASE_HP_MAX
var rune_echo: float = 0.0
var rune_echo_max: float = 50.0
var body_temperature: float = 36.6
var heart_rate: float = HEART_RATE_BASE
var is_overheating: bool = false
var is_dead: bool = false

# Archetype modifiers
var atf_regen_rate: float = 2.0  # per second baseline
var atf_regen_penalty: float = 0.0  # Σ archetype penalty
var echo_decay_rate: float = 0.5  # per second natural decay
var gravity_stress_factor: float = 1.0  # multiplier for 1.4g stress

# Consumption rates
var oxygen_consumption_base: float = 0.8  # per second at rest
var oxygen_consumption_sprint: float = 3.2
var oxygen_consumption_rune: float = 15.0  # per rune activation

# Radiation tracking
var personal_radiation: float = 0.0  # in Sv
var radiation_threshold: float = 0.5  # Sv before mutation debuffs

# Consumable effects (timers)
var _active_effects: Dictionary = {}

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if is_dead:
		return
	
	# Natural ATF regeneration
	var regen = atf_regen_rate - atf_regen_penalty
	if regen > 0:
		atf = min(atf + regen * delta, atf_max)
	
	# Echo natural decay
	if rune_echo > 0:
		rune_echo = max(rune_echo - echo_decay_rate * delta, 0.0)
	
	# Calculate body temperature from echo
	body_temperature = 36.6 + (rune_echo / rune_echo_max) * 4.2  # up to 40.8°C
	
	# Heart rate from echo and activity
	heart_rate = HEART_RATE_BASE + (rune_echo / rune_echo_max) * (HEART_RATE_MAX - HEART_RATE_BASE)
	
	# Overheating damage
	if body_temperature >= ECHO_OVERHEAT_THRESHOLD:
		if not is_overheating:
			is_overheating = true
			overheating_started.emit()
		hp -= OVERHEAT_DAMAGE_PER_SEC * delta
		if hp <= 0:
			hp = 0
			is_dead = true
			player_died.emit()
	elif is_overheating:
		is_overheating = false
		overheating_ended.emit()
	
	# Oxygen consumption (base)
	oxygen = max(oxygen - oxygen_consumption_base * delta * gravity_stress_factor, 0.0)
	
	# No oxygen → HP drain
	if oxygen <= 0:
		hp -= 3.0 * delta
		if hp <= 0:
			hp = 0
			is_dead = true
			player_died.emit()
	
	# Process active consumable effects
	_process_effects(delta)
	
	# Emit signals
	atf_changed.emit(atf, atf_max)
	oxygen_changed.emit(oxygen, oxygen_max)
	hp_changed.emit(hp, hp_max)
	rune_echo_changed.emit(rune_echo)
	body_temperature_changed.emit(body_temperature)
	heart_rate_changed.emit(heart_rate)
	
	if atf < CRITICAL_ATF_THRESHOLD:
		atf_critical.emit()

## Spend ATF for an action. Returns true if successful.
func spend_atf(amount: float, adds_echo: float = 0.0) -> bool:
	if atf < amount:
		return false
	atf -= amount
	rune_echo = min(rune_echo + adds_echo, rune_echo_max)
	return true

## Spend oxygen for an activity (sprint, rune, etc.)
func spend_oxygen(amount: float) -> bool:
	if oxygen < amount * delta_time_approx():
		return false
	oxygen -= amount * get_process_delta_time()
	return true

## Heal HP
func heal_hp(amount: float) -> void:
	hp = min(hp + amount, hp_max)
	
	# Radiation check if using technetium
	if _active_effects.has("technetium"):
		personal_radiation += 0.02  # +0.02 Sv per use

## Restore oxygen
func restore_oxygen(amount: float) -> void:
	oxygen = min(oxygen + amount, oxygen_max)

## Restore ATF
func restore_atf(amount: float) -> void:
	atf = min(atf + amount, atf_max)

## Reduce echo (cooling consumables)
func reduce_echo(amount: float) -> void:
	rune_echo = max(rune_echo - amount, 0.0)

## Add a timed consumable effect
func add_effect(effect_name: String, duration: float, modifier: Dictionary) -> void:
	_active_effects[effect_name] = {
		"duration": duration,
		"time_left": duration,
		"modifier": modifier
	}
	_apply_effect_modifier(effect_name, modifier, true)

## Remove all effects
func clear_all_effects() -> void:
	for effect_name in _active_effects:
		_apply_effect_modifier(effect_name, _active_effects[effect_name]["modifier"], false)
	_active_effects.clear()

## Apply nicotine/taurine stabilizer
func apply_nicotine_taurine() -> void:
	add_effect("nicotine_taurine", 30.0, {
		"stamina_bonus": 0.15,
		"gravity_stress_reduction": 0.3,
		"echo_decay_boost": 2.0
	})

## Apply technetium pack
func apply_technetium_pack() -> void:
	personal_radiation += 0.02
	add_effect("technetium", 10.0, {
		"hp_regen_bonus": 25.0,  # +25% HP/sec
		"radiation_accumulation": 0.002
	})

func _process_effects(delta: float) -> void:
	var to_remove: Array = []
	for effect_name in _active_effects:
		var effect = _active_effects[effect_name]
		effect["time_left"] -= delta
		# Per-second effects
		if effect_name == "technetium":
			hp = min(hp + effect["modifier"]["hp_regen_bonus"] * delta / 100.0 * hp_max, hp_max)
			personal_radiation += effect["modifier"]["radiation_accumulation"] * delta
		if effect_name == "nicotine_taurine":
			echo_decay_rate += effect["modifier"]["echo_decay_boost"]
			gravity_stress_factor = max(gravity_stress_factor - effect["modifier"]["gravity_stress_reduction"], 0.5)
		if effect["time_left"] <= 0:
			to_remove.append(effect_name)
	for effect_name in to_remove:
		_apply_effect_modifier(effect_name, _active_effects[effect_name]["modifier"], false)
		_active_effects.erase(effect_name)

func _apply_effect_modifier(effect_name: String, modifier: Dictionary, apply: bool) -> void:
	var sign_mult = 1.0 if apply else -1.0
	if modifier.has("stamina_bonus"):
		atf_regen_rate += modifier["stamina_bonus"] * sign_mult
	if modifier.has("echo_decay_boost"):
		echo_decay_rate += modifier["echo_decay_boost"] * sign_mult
	if modifier.has("gravity_stress_reduction"):
		gravity_stress_factor -= modifier["gravity_stress_reduction"] * sign_mult

## Get mutation debuffs from radiation
func get_mutation_debuffs() -> Dictionary:
	if personal_radiation >= radiation_threshold:
		var severity = (personal_radiation - radiation_threshold) / 0.5
		return {
			"vision_penalty": severity * 0.3,
			"rune_accuracy_penalty": severity * 0.4,
			"random_rune_trigger_chance": severity * 0.1
		}
	return {}

## Calculate V (Вериса value) for current state
func calculate_verisa() -> float:
	var delta_h = atf_max - atf  # Energy deficit
	return -VERISA_K * delta_h

## Reset for respawn
func reset_state() -> void:
	atf = atf_max
	oxygen = oxygen_max
	hp = hp_max
	rune_echo = 0.0
	body_temperature = 36.6
	heart_rate = HEART_RATE_BASE
	is_overheating = false
	is_dead = false
	_active_effects.clear()

func delta_time_approx() -> float:
	return get_process_delta_time()
