extends Node

## Gravity System for Cassiopeia (Planet orbiting Kronos red dwarf Helios)
## Constant Gravity = 1.4g (13.729 m/s^2)
## Fall damage formula: Height > 2.0m -> lethal / high damage scaling with mass * g

signal gravity_changed(new_gravity_val: float)
signal fall_damage_triggered(target: Node, damage: float, height: float)

const EARTH_GRAVITY: float = 9.80665
const GRAVITY_MULTIPLIER: float = 1.4
const BASE_GRAVITY: float = EARTH_GRAVITY * GRAVITY_MULTIPLIER # 13.72931 m/s^2
const LETHAL_FALL_HEIGHT: float = 2.0 # Fall > 2m causes massive/lethal damage without protective buffs

var current_gravity: float = BASE_GRAVITY

func _ready() -> void:
	print("[GravitySystem] Initialized. Constant 1.4g = %.3f m/s^2" % current_gravity)

## Calculates fall damage based on fall height in meters and target mass
func calculate_fall_damage(fall_height: float, target_mass: float, has_protection: bool) -> float:
	if fall_height <= LETHAL_FALL_HEIGHT:
		return 0.0
	
	if has_protection:
		# Protective rune/effect reduces lethal multiplier
		return (fall_height - LETHAL_FALL_HEIGHT) * target_mass * 10.0
	else:
		# Fall > 2.0m is lethal without active protection (Rule from GDD)
		var excess_height: float = fall_height - LETHAL_FALL_HEIGHT
		var base_lethal_damage: float = 999.0 + (excess_height * 200.0)
		return base_lethal_damage

func set_local_gravity(new_val: float) -> void:
	current_gravity = new_val
	gravity_changed.emit(current_gravity)
