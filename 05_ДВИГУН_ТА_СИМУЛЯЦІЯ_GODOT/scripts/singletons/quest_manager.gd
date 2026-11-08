## QuestManager.gd — Global Singleton
## Управление квестами, контракты Lex Σύνθησις, Зграя квесты
extends Node

signal quest_started(quest_id: String)
signal quest_progress(quest_id: String, step: int)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

const QUESTS: Dictionary = {
	# === PROLOGUE ===
	"prologue_escape": {
		"name": "Побег из зоны сброса",
		"description": "Система «Эгида» классифицировала вас как «Ошибка/Шум». Выживите и доберитесь до убежища.",
		"phase": "prologue",
		"steps": [
			{"description": "Прийти в сознание после аварии в Глубоком Яру", "type": "trigger"},
			{"description": "Избежать отряда зачистки Эгида", "type": "avoid"},
			{"description": "Найти ближайшее убежище в Чреве", "type": "reach_location"},
			{"description": "Обратиться к первому контактёру", "type": "interact_npc"}
		],
		"reward": {"corals": 10.0, "rune": "sol"},
		"required": true,
		"next_quest": "distribution"
	},
	"distribution": {
		"name": "Распределение",
		"description": "Процедура определения резонансной совместимости. Выберите архетип.",
		"phase": "prologue",
		"steps": [
			{"description": "Пройти тест на резонансную совместимость", "type": "interact_npc"},
			{"description": "Выбрать архетип (или кастомизировать)", "type": "choice"}
		],
		"reward": {"unlock_archetype": true},
		"required": true,
		"next_quest": "first_contract"
	},
	
	# === MIDGAME — Zgraya Recruitment ===
	"skiya_recruitment": {
		"name": "Операция «Ржавый гвоздь» — Ския",
		"description": "Помогите Скии взломать энергосеть Бюро Стерилизации.",
		"phase": "midgame",
		"steps": [
			{"description": "Найти Скию в трущобах Чрева", "type": "interact_npc"},
			{"description": "Проникнуть в энергосеть Бюро", "type": "hack"},
			{"description": "Установить вирус саботажа", "type": "interact_object"},
			{"description": "Вернуться к Скии за наградой", "type": "interact_npc"}
		],
		"reward": {"corals": 30.0, "zgraya_member": "skiya", "rune": "vei", "equipment": "skiya_hack_tool"},
		"next_quest": "skiya_advanced_hack"
	},
	"roan_recruitment": {
		"name": "Техники гравитационного стресса — Роан",
		"description": "Роан обучит вас преодолению 1.4g в ближнем бою.",
		"phase": "midgame",
		"steps": [
			{"description": "Найти Роана в тренировочном зале Тела", "type": "interact_npc"},
			{"description": "Пройти испытание ближнего боя (3 раунда)", "type": "combat_challenge"},
			{"description": "Доказать адаптацию к гравитации (прыжок + приземление)", "type": "skill_test"},
			{"description": "Получить обучение от Роана", "type": "interact_npc"}
		],
		"reward": {"corals": 25.0, "zgraya_member": "roan", "equipment": "heavy_weapon_roan"},
		"next_quest": "roan_tournament"
	},
	"mika_recruitment": {
		"name": "Биохакинг — Мика",
		"description": "Мика предлагает улучшенные технециевые пайки с меньшей радиацией.",
		"phase": "midgame",
		"steps": [
			{"description": "Найти Мику в биолаборатории Тела", "type": "interact_npc"},
			{"description": "Собрать образцы люминесцентных кораллов", "type": "collect"},
			{"description": "Помочь Мике в эксперименте по очистке технеция", "type": "quest_task"},
			{"description": "Получить улучшенные пайки", "type": "interact_npc"}
		],
		"reward": {"corals": 20.0, "zgraya_member": "mika", "items": {"technetium_pack_improved": 3}},
		"next_quest": "mika_bio_lab"
	},
	"yuna_recruitment": {
		"name": "Слепые пятна — Юна",
		"description": "Юна раскрывает скрытые маршруты через геометрию уровня.",
		"phase": "midgame",
		"steps": [
			{"description": "Найти Юну в навигационной станции Тела", "type": "interact_npc"},
			{"description": "Пройти через скрытый вентиляционный маршрут", "type": "reach_location"},
			{"description": "Раскрыть слепое пятно в геометрии Неба", "type": "perception_test"},
			{"description": "Получить навигационный прибор", "type": "interact_npc"}
		],
		"reward": {"corals": 25.0, "zgraya_member": "yuna", "equipment": "yuna_nav_device"},
		"next_quest": "yuna_deep_navigation"
	},
	
	# === MIDGAME — Faction Contracts ===
	"lex_synthesis_contract_1": {
		"name": "Контракт Lex Σύνθησις — Торговый коридор",
		"description": "Установить торговый маршрут между Чревом и Телом.",
		"phase": "midgame",
		"steps": [
			{"description": "Встретиться с представителем Lex Σύνθησις", "type": "interact_npc"},
			{"description": "Защитить торговый караван от Бюро Стерилизации", "type": "combat"},
			{"description": "Доставить груз в рынок Тела", "type": "deliver"}
		],
		"reward": {"corals": 40.0, "faction": {"lex_synthesis": 15.0}},
		"next_quest": "lex_synthesis_contract_2"
	},
	"coral_cartel_deal": {
		"name": "Сделка Кораллового Картеля",
		"description": "Добыть кораллы из симбиотических рифов под Уламком.",
		"phase": "midgame",
		"steps": [
			{"description": "Найти вход в подводные рифы", "type": "reach_location"},
			{"description": "Собрать 50 люминесцентных кораллов", "type": "collect"},
			{"description": "Вернуться к представителю Картеля", "type": "interact_npc"}
		],
		"reward": {"corals": 50.0, "faction": {"coral_cartel": 20.0}},
		"next_quest": "coral_cartel_deep"
	},
	
	# === ENDGAME ===
	"endgame_axiom": {
		"name": "Аксиома — Сервер-ядро",
		"description": "Проникнуть в серверную зону «Аксиома», хранящую значение k в уравнении Вериса.",
		"phase": "endgame",
		"steps": [
			{"description": "Получить доступ к верхнему ярусу Неба", "type": "reach_location"},
			{"description": "Найти серверную зону Аксиома", "type": "reach_location"},
			{"description": "Обойти или нейтрализовать защитные системы Архитектора", "type": "hack_or_combat"},
			{"description": "Добраться до ядра уравнения", "type": "reach_location"}
		],
		"reward": {"h_psi_zero_progress": 50.0},
		"next_quest": "final_battle"
	},
	"final_battle": {
		"name": "Битва за уравнение реальности",
		"description": "HΨ=0 — Информационная сверхпроводимость. Измените фундаментальное уравнение планеты.",
		"phase": "final_battle",
		"steps": [
			{"description": "Войти в ядро уравнения", "type": "trigger"},
			{"description": "Менять параметры уравнения через комбинации рун", "type": "rune_challenge"},
			{"description": "АТФ-пульсы в точных временных окнах", "type": "timing_challenge"},
			{"description": "Выбрать финал: Стабилизация / Перезапись / Разрыв", "type": "choice"}
		],
		"reward": {"ending": true},
		"required": true,
	},
}

var active_quests: Dictionary = {}  # quest_id -> {current_step, status}
var completed_quests: Array = []
var failed_quests: Array = []

func _ready() -> void:
	# Auto-start prologue quest
	start_quest("prologue_escape")

func start_quest(quest_id: String) -> bool:
	if not QUESTS.has(quest_id):
		return false
	if quest_id in active_quests or quest_id in completed_quests:
		return false
	
	active_quests[quest_id] = {
		"current_step": 0,
		"status": "active",
		"data": QUESTS[quest_id]
	}
	quest_started.emit(quest_id)
	return true

func advance_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	
	var quest = active_quests[quest_id]
	quest["current_step"] += 1
	
	if quest["current_step"] >= quest["data"]["steps"].size():
		return complete_quest(quest_id)
	
	quest_progress.emit(quest_id, quest["current_step"])
	return true

func complete_quest(quest_id: String) -> bool:
	if not active_quests.has(quest_id):
		return false
	
	var quest = active_quests[quest_id]
	var reward = quest["data"]["reward"]
	
	# Apply rewards
	if reward.has("corals"):
		EconomyManager.add_corals(reward["corals"])
	if reward.has("rune"):
		RunesRegistry.learn_rune(reward["rune"])
	if reward.has("zgraya_member"):
		GameState.recruit_zgraya_member(reward["zgraya_member"])
	if reward.has("equipment"):
		EconomyManager.add_item(reward["equipment"])
	if reward.has("items"):
		for item_id in reward["items"]:
			EconomyManager.add_item(item_id, reward["items"][item_id])
	if reward.has("faction"):
		for faction in reward["faction"]:
			GameState.modify_faction_relation(faction, reward["faction"][faction])
	if reward.has("h_psi_zero_progress"):
		GameState.h_psi_zero_progress += reward["h_psi_zero_progress"]
	if reward.has("unlock_archetype"):
		GameState.set_story_flag("distribution_done", true)
	
	# Mark completed
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	quest_completed.emit(quest_id)
	
	# Start next quest if chain
	if quest["data"].has("next_quest") and quest["data"]["next_quest"] != "":
		start_quest(quest["data"]["next_quest"])
	
	return true

func fail_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	active_quests.erase(quest_id)
	failed_quests.append(quest_id)
	quest_failed.emit(quest_id)
	# Register as failed attempt for R[n] No Excuses
	POLERSystem.register_failed_attempt("quest_" + quest_id)

func get_active_quests() -> Dictionary:
	return active_quests

func get_quest_progress(quest_id: String) -> int:
	if active_quests.has(quest_id):
		return active_quests[quest_id]["current_step"]
	return -1

func get_available_quests() -> Array:
	var available: Array = []
	for quest_id in QUESTS:
		if quest_id not in active_quests and quest_id not in completed_quests:
			var phase = QUESTS[quest_id]["phase"]
			if _is_phase_accessible(phase):
				available.append(quest_id)
	return available

func _is_phase_accessible(phase: String) -> bool:
	match phase:
		"prologue": return true
		"midgame": return GameState.current_phase >= GameState.GamePhase.MIDGAME
		"endgame": return GameState.current_phase >= GameState.GamePhase.ENDGAME
		"final_battle": return GameState.current_phase >= GameState.GamePhase.FINAL_BATTLE
	return false
