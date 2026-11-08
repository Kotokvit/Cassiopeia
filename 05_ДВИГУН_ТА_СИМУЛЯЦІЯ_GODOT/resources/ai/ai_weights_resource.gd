## AIWeightsResource — Custom Resource for enemy AI plasticity weights
## Export/Import for No Excuses Protocol persistence
class_name AIWeightsResource
extends Resource

@export var weights: Dictionary = {
	"attack": 0.7,
	"flank": 0.1,
	"ambush": 0.05,
	"retreat": 0.1,
	"shield": 0.05,
}
@export var learned_patterns: Dictionary = {}
@export var plasticity_level: float = 0.1
@export var faction: String = ""
@export var enemy_class: String = ""
