## RunesRegistry.gd — Global Singleton
## 10 фундаментальных рун + система крафтинга комбинаций
extends Node

signal rune_learned(rune_id: String)
signal rune_combination_discovered(combo_id: String, result_id: String)
signal rune_equipped(rune_id: String, slot: int)
signal rune_unequipped(rune_id: String, slot: int)

# 10 Fundamental Runes
const FUNDAMENTAL_RUNES: Dictionary = {
	"tet": {"name": "Тет", "name_en": "Tet", "description": "Структура — упорядочивает материю", "element": "structure", "base_cost": 10.0, "color": Color(0.8, 0.2, 0.1)},
	"oro": {"name": "Оро", "name_en": "Oro", "description": "Поток — управляет направлением энергии", "element": "flow", "base_cost": 8.0, "color": Color(0.2, 0.6, 0.8)},
	"ka": {"name": "Ка", "name_en": "Ka", "description": "Связь — соединяет разрозненные элементы", "element": "connection", "base_cost": 12.0, "color": Color(0.9, 0.9, 0.1)},
	"vei": {"name": "Вей", "name_en": "Vei", "description": "Пустота — создаёт вакуум и пустоты", "element": "void", "base_cost": 15.0, "color": Color(0.1, 0.1, 0.3)},
	"nul": {"name": "Нул", "name_en": "Nul", "description": "Аннулирование — стирает свойства", "element": "negation", "base_cost": 18.0, "color": Color(0.0, 0.0, 0.0)},
	"sol": {"name": "Сол", "name_en": "Sol", "description": "Свет — генерирует фотонные потоки", "element": "light", "base_cost": 7.0, "color": Color(1.0, 0.95, 0.8)},
	"zen": {"name": "Зен", "name_en": "Zen", "description": "Предел — устанавливает границы", "element": "boundary", "base_cost": 14.0, "color": Color(0.5, 0.5, 0.5)},
	"ari": {"name": "Ари", "name_en": "Ari", "description": "Возврат — возвращает к исходному состоянию", "element": "return", "base_cost": 11.0, "color": Color(0.6, 0.3, 0.8)},
	"dyn": {"name": "Дин", "name_en": "Dyn", "description": "Сила — усиливает физические параметры", "element": "force", "base_cost": 9.0, "color": Color(0.9, 0.4, 0.1)},
	"mir": {"name": "Мир", "name_en": "Mir", "description": "Отражение — создаёт симметричные копии", "element": "reflection", "base_cost": 13.0, "color": Color(0.3, 0.7, 0.6)}
}

# Combinations (rune crafting — "Image" / O in POLER)
const COMBINATIONS: Dictionary = {
	"tet_oro": {"id": "lightness", "name": "Лёгкость", "description": "Уменьшает эффективную массу объекта на 30%", "effect_type": "mass_reduction", "effect_value": 0.7, "cost": 20.0, "echo": 5.0, "duration": 10.0},
	"tet_vei": {"id": "aerogel", "name": "Аэрогель", "description": "Превращает плотный материал в аэрогель", "effect_type": "density_change", "effect_value": 0.01, "cost": 30.0, "echo": 10.0, "duration": 8.0},
	"oro_dyn": {"id": "acceleration", "name": "Ускорение", "description": "Увеличивает скорость движения на 50%", "effect_type": "speed_boost", "effect_value": 1.5, "cost": 18.0, "echo": 4.0, "duration": 5.0},
	"ka_sol": {"id": "illumination", "name": "Освещение", "description": "Создает источник биолюминесцентного света", "effect_type": "light_source", "effect_value": 1.0, "cost": 15.0, "echo": 2.0, "duration": 30.0},
	"vei_nul": {"id": "passage", "name": "Проход", "description": "Создает квантовый туннель через барьер", "effect_type": "quantum_tunnel", "effect_value": 1.0, "cost": 35.0, "echo": 12.0, "duration": 3.0},
	"nul_ari": {"id": "reset", "name": "Сброс", "description": "Возвращает объект к исходному состоянию", "effect_type": "reset_state", "effect_value": 1.0, "cost": 25.0, "echo": 7.0, "duration": 0.0},
	"zen_sol": {"id": "shield", "name": "Щит", "description": "Создает защитный барьер от резонанса", "effect_type": "resonance_shield", "effect_value": 0.6, "cost": 22.0, "echo": 6.0, "duration": 15.0},
	"dyn_mir": {"id": "blast", "name": "Взрыв", "description": "Силовое отражение — наносит двойный урон", "effect_type": "damage_mirror", "effect_value": 2.0, "cost": 28.0, "echo": 9.0, "duration": 2.0},
	"ari_vei": {"id": "trap", "name": "Ловушка", "description": "Вакуумная ловушка — замедляет врагов", "effect_type": "snare", "effect_value": 0.3, "cost": 16.0, "echo": 3.0, "duration": 20.0},
	"mir_ka": {"id": "clone", "name": "Двойник", "description": "Создает временную копию предмета", "effect_type": "item_clone", "effect_value": 1.0, "cost": 24.0, "echo": 8.0, "duration": 5.0},
	"tet_dyn": {"id": "fortify", "name": "Укрепление", "description": "Увеличивает плотность и прочность материала", "effect_type": "density_increase", "effect_value": 3.0, "cost": 22.0, "echo": 6.0, "duration": 12.0},
	"oro_ka": {"id": "bridge", "name": "Мост", "description": "Соединяет два объекта силовой связью", "effect_type": "connection_bridge", "effect_value": 1.0, "cost": 20.0, "echo": 5.0, "duration": 8.0},
	"sol_zen": {"id": "reveal", "name": "Раскрытие", "description": "Подсвечивает скрытые объекты и уязвимости", "effect_type": "perception_boost", "effect_value": 2.0, "cost": 12.0, "echo": 2.0, "duration": 15.0},
	"dyn_oro": {"id": "projectile", "name": "Снаряд", "description": "Силовой поток — направленный энергетический удар", "effect_type": "energy_projectile", "effect_value": 40.0, "cost": 20.0, "echo": 6.0, "duration": 0.0},
	"vei_sol": {"id": "stealth", "name": "Незаметность", "description": "Пустота+Свет = невидимость", "effect_type": "stealth", "effect_value": 0.9, "cost": 25.0, "echo": 8.0, "duration": 8.0},
}

# Player state
var learned_runes: Array = []
var equipped_runes: Array = ["", "", "", "", ""]  # 5 slots
var discovered_combinations: Array = []
var active_combo_effects: Dictionary = {}

func _ready() -> void:
	# Start with basic runes (learned during Distribution)
	learned_runes = ["tet", "oro", "ka"]

func get_rune_data(rune_id: String) -> Dictionary:
	return FUNDAMENTAL_RUNES.get(rune_id, {})

func learn_rune(rune_id: String) -> bool:
	if rune_id in learned_runes:
		return false
	if not FUNDAMENTAL_RUNES.has(rune_id):
		return false
	learned_runes.append(rune_id)
	rune_learned.emit(rune_id)
	return true

func equip_rune(rune_id: String, slot: int) -> bool:
	if slot < 0 or slot >= equipped_runes.size():
		return false
	if rune_id not in learned_runes:
		return false
	# Unequip from current slot if occupied
	if equipped_runes[slot] != "":
		rune_unequipped.emit(equipped_runes[slot], slot)
	# Unequip from other slot if same rune there
	for i in range(equipped_runes.size()):
		if equipped_runes[i] == rune_id:
			equipped_runes[i] = ""
			rune_unequipped.emit(rune_id, i)
	equipped_runes[slot] = rune_id
	rune_equipped.emit(rune_id, slot)
	return true

func unequip_rune(slot: int) -> void:
	if slot < 0 or slot >= equipped_runes.size():
		return
	if equipped_runes[slot] != "":
		rune_unequipped.emit(equipped_runes[slot], slot)
		equipped_runes[slot] = ""

## Craft combination from two runes
func craft_combination(rune_a: String, rune_b: String) -> Dictionary:
	var combo_key = _make_combo_key(rune_a, rune_b)
	var reverse_key = _make_combo_key(rune_b, rune_a)
	
	var result = COMBINATIONS.get(combo_key, COMBINATIONS.get(reverse_key, {}))
	if result.is_empty():
		return {}  # No valid combination
	
	if result["id"] not in discovered_combinations:
		discovered_combinations.append(result["id"])
		rune_combination_discovered.emit(combo_key, result["id"])
	
	return result

func _make_combo_key(a: String, b: String) -> String:
	return a + "_" + b

## Activate a crafted combination effect
func activate_combination(combo_id: String, target_position: Vector3 = Vector3.ZERO) -> bool:
	var combo_data = _find_combo_by_id(combo_id)
	if combo_data.is_empty():
		return false
	
	if not ATF_Balance.spend_atf(combo_data["cost"], combo_data["echo"]):
		return false
	
	var effect = {
		"combo_id": combo_id,
		"effect_type": combo_data["effect_type"],
		"value": combo_data["effect_value"],
		"duration": combo_data["duration"],
		"time_left": combo_data["duration"],
		"position": target_position
	}
	active_combo_effects[combo_id] = effect
	
	# Apply specific effects
	_apply_combo_effect(effect)
	
	return true

func _find_combo_by_id(combo_id: String) -> Dictionary:
	for key in COMBINATIONS:
		if COMBINATIONS[key]["id"] == combo_id:
			return COMBINATIONS[key]
	return {}

func _apply_combo_effect(effect: Dictionary) -> void:
	match effect["effect_type"]:
		"mass_reduction":
			ResonanceEngine.trigger_rune("lightness", effect["value"])
			GravityManager.apply_rune_lightness(effect["duration"])
		"density_change":
			ResonanceEngine.trigger_rune("aerogel", effect["value"])
		"speed_boost":
			# Applied to player in PlayerController
			pass
		"light_source":
			ResonanceEngine.trigger_rune("illumination", effect["value"])
		"quantum_tunnel":
			ResonanceEngine.trigger_rune("passage", effect["value"])
		"resonance_shield":
			ResonanceEngine.trigger_rune("shield", effect["value"])
		"damage_mirror":
			ResonanceEngine.trigger_rune("blast", effect["value"])
		"snare":
			ResonanceEngine.trigger_rune("trap", effect["value"])
		"stealth":
			ResonanceEngine.trigger_rune("stealth", effect["value"])
		"perception_boost":
			POLERSystem.activate_perception_boost(effect["duration"])

func get_all_learned_runes() -> Array:
	return learned_runes

func get_equipped_runes() -> Array:
	return equipped_runes

func get_discovered_combinations() -> Array:
	return discovered_combinations

func get_available_combinations() -> Array:
	var available: Array = []
	for key in COMBINATIONS:
		var parts = key.split("_")
		if parts[0] in learned_runes and parts[1] in learned_runes:
			available.append(COMBINATIONS[key]["id"])
	return available
