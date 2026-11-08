## PlayerArchetypeProfile — Custom Resource
## Хранит биомеханический и когнитивный профиль архетипа
class_name PlayerArchetypeProfile
extends Resource

@export var archetype_name: String = "custom"
@export var archetype_class: String = "custom"  # S, Σ, or P (Projector)

# Biomechanical profile
@export_range(0.0, 1.0) var biomech_active: float = 0.5
@export var skeleton_density: float = 1.0  # g/cm³ (normal ~1.0, Σ ~2.6)
@export var muscle_density_modifier: float = 1.0  # +40% for Σ = 1.4
@export var metabolism_rate: float = 1.0
@export var atf_regen_modifier: float = 1.0
@export var carry_capacity_modifier: float = 1.0
@export var gravity_adaptation: float = 1.0  # 1.0 = normal, <1 = adapted (Σ)

# Cognitive profile
@export_range(0.0, 1.0) var cognitive_profile: float = 0.5
@export var rune_manipulation_power: float = 1.0
@export var l_logic_speed: float = 1.0
@export var stress_threshold_modifier: float = 1.0
@export var can_edit_reality_code: bool = false  # S-class only
@export var can_see_blind_spots: bool = false  # Analyst only
@export var spatial_manipulator_range: float = 0.0  # Analyst only

# Derived stats
func get_max_carry_kg() -> float:
	return 15.0 * carry_capacity_modifier  # base 15kg, Σ gets 30kg

func get_jump_modifier() -> float:
	return gravity_adaptation

func get_damage_modifier() -> float:
	return muscle_density_modifier

func get_speed_modifier() -> float:
	return 1.0 - (skeleton_density - 1.0) * 0.1 + (metabolism_rate - 1.0) * 0.2

func get_rune_cost_modifier() -> float:
	return 1.0 / rune_manipulation_power

func get_atf_regen_rate() -> float:
	return 2.0 * atf_regen_modifier * metabolism_rate
