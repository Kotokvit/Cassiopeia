class_name ArchetypeData
extends Resource

enum ArchetypeType {
	RESONATOR_EDITOR,    # Class S - Anomaly
	BIOMECHANICAL_ASSET, # Class Sigma - Type Roan
	CAUSALITY_ANALYST    # Causality Projector
}

@export var archetype_type: ArchetypeType = ArchetypeType.RESONATOR_EDITOR
@export var archetype_name: String = ""
@export var bone_density: float = 1.8 # g/cm^3
@export var muscle_strength_mult: float = 1.0
@export var max_carry_weight_kg: float = 15.0
@export var atf_regen_mult: float = 1.0
@export var rune_affinity: float = 1.0
@export var gravity_debuff_immunity: bool = false
