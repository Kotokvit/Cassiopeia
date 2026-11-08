extends Node

## ATF Metabolic Economy & Axiom of Veris (V = -k * Delta_H)
## Replaces traditional "mana". Tracks ATP pool, Blood Oxygen,
## Body Temperature, Heart Rate, Rune Echo Heat, and Radiation (Sv).

signal atf_changed(current: float, max_val: float)
signal oxygen_changed(level: float)
signal heat_updated(temp_celsius: float, heart_rate_bpm: float, echo_heat: float)
signal overheat_damage_tick(damage: float)
signal radiation_changed(sv_level: float)

# Base Metabolic Parameters
@export var max_atf: float = 100.0
var current_atf: float = 100.0

@export var max_health: float = 100.0
var current_health: float = 100.0

var oxygen_level: float = 100.0 # Percentage 0-100%

# Thermal & Cardiac Physiology
var base_temp: float = 36.6 # Normal body temp °C
var body_temperature: float = 36.6 # Max dangerous 40.8°C
var base_heart_rate: float = 70.0 # Normal BPM
var heart_rate: float = 70.0 # Max tachycardia 232 BPM

var rune_echo_heat: float = 0.0 # Heat accumulation from excessive rune usage
var radiation_sv: float = 0.0 # Radiation level in Sieverts

# Axiom of Veris constant k
var veris_k_constant: float = 1.0

func _ready() -> void:
	print("[ATFSystem] Initialized. Axiom of Veris (V = -k * Delta_H) active.")

func _process(delta: float) -> void:
	_update_metabolism(delta)

## Consumes ATP and Oxygen for actions (Rune casts, power jumps, PM usage)
func consume_atf(amount: float, oxygen_cost: float = 2.0, generate_echo: float = 5.0) -> bool:
	if current_atf < amount:
		# Overexertion: Force consumption, converting deficit into severe Rune Echo Heat!
		var deficit: float = amount - current_atf
		current_atf = 0.0
		rune_echo_heat += generate_echo + (deficit * 3.0)
		atf_changed.emit(current_atf, max_atf)
		return true
	
	current_atf -= amount
	oxygen_level = maxf(0.0, oxygen_level - oxygen_cost)
	rune_echo_heat += generate_echo
	
	atf_changed.emit(current_atf, max_atf)
	oxygen_changed.emit(oxygen_level)
	return true

## Use Nicotinoid + Taurine Anti-Gravity Stabilizers
func consume_stabilizer() -> void:
	rune_echo_heat = maxf(0.0, rune_echo_heat - 30.0)
	current_atf = minf(max_atf, current_atf + 40.0)
	oxygen_level = minf(100.0, oxygen_level + 20.0)
	print("[ATFSystem] Consumed Nicotinoids + Taurine. ATP & Heat stabilized.")

## Use Technecium Ration (0.01 ppm) - Heals 25% HP/sec for 4s, but adds +0.02 Sv radiation
func consume_technecium_ration() -> void:
	radiation_sv += 0.02
	current_health = minf(max_health, current_health + 25.0)
	radiation_changed.emit(radiation_sv)
	print("[ATFSystem] Consumed Technecium Ration. Radiation level: %.2f Sv" % radiation_sv)

func _update_metabolism(delta: float) -> void:
	# Natural ATP regeneration
	if current_atf < max_atf:
		current_atf = minf(max_atf, current_atf + 8.0 * delta)
		atf_changed.emit(current_atf, max_atf)
	
	# Natural Oxygen recovery
	if oxygen_level < 100.0:
		oxygen_level = minf(100.0, oxygen_level + 10.0 * delta)
		oxygen_changed.emit(oxygen_level)
	
	# Cool down Rune Echo Heat
	if rune_echo_heat > 0.0:
		rune_echo_heat = maxf(0.0, rune_echo_heat - 4.0 * delta)
	
	# Calculate Temperature and Heart Rate based on Echo Heat
	var heat_ratio: float = minf(1.0, rune_echo_heat / 100.0)
	body_temperature = lerpf(base_temp, 40.8, heat_ratio)
	heart_rate = lerpf(base_heart_rate, 232.0, heat_ratio)
	
	heat_updated.emit(body_temperature, heart_rate, rune_echo_heat)
	
	# Overheat damage when temperature exceeds 40.0°C
	if body_temperature > 40.0:
		var overheat_dmg: float = (body_temperature - 40.0) * 15.0 * delta
		current_health = maxf(0.0, current_health - overheat_dmg)
		overheat_damage_tick.emit(overheat_dmg)
