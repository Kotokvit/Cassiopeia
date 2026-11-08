## ItemData — Custom Resource for consumable/equipment items
class_name ItemData
extends Resource

@export var item_id: String = ""
@export var item_name: String = ""
@export var description: String = ""
@export var item_type: String = "consumable"  # consumable, equipment, weapon, resource
@export var cost_corals: float = 5.0
@export var stack_max: int = 10
@export var effect_type: String = ""
@export var effect_value: float = 0.0
@export var use_function: String = ""
@export var radiation_per_use: float = 0.0
@export var duration: float = 0.0
@export var icon_path: String = ""
