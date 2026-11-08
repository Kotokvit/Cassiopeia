## DialogueSystem.gd — Global Singleton
## Диалоговая система с ветками, влияющими на финал
extends Node

signal dialogue_started(dialogue_id: String, npc_name: String)
signal dialogue_line_spoken(line: String, speaker: String)
signal dialogue_choice_presented(choices: Array)
signal dialogue_choice_made(choice_index: int, choice_text: String)
signal dialogue_ended(dialogue_id: String)

const DIALOGUES: Dictionary = {
	"prologue_contact": {
		"npc": "Старый contactёр",
		"lines": [
			{"text": "Ты ещё жив? Эгида не любит ошибки. Двигайся — или станешь списанным.", "speaker": "npc"},
			{"text": "Что мне делать?", "speaker": "player", "choices": [
				{"text": "Найти убежище (безопасный путь)", "effect": {"quest_advance": true}},
				{"text": "Узнать о резонансе (риск — больше информации)", "effect": {"rune": "oro", "tension": 5.0}},
				{"text": "Напасть на патруль (агрессивный)", "effect": {"combat": true, "epsilon": 10.0}}
			]},
			{"text": "Уламок — не место для списанных. Но списанные — это те, кто ещё не проснулся.", "speaker": "npc"},
		]
	},
	"distribution_test": {
		"npc": "Архитектор-экзаменатор",
		"lines": [
			{"text": "Процедура Распределения. Ваш резонанс будет классифицирован.", "speaker": "npc"},
			{"text": "Выберите профиль:", "speaker": "npc", "choices": [
				{"text": "Резонатор-Редактор (Класс S)", "effect": {"archetype": "resonator_editor"}},
				{"text": "Биомеханический Актив (Класс Σ, тип «Роан»)", "effect": {"archetype": "biomech_active"}},
				{"text": "Резонатор-Аналитик (Проектор Причинности)", "effect": {"archetype": "resonator_analyst"}},
				{"text": "Кастомизировать параметры вручную", "effect": {"archetype": "custom"}}
			]},
		]
	},
	"skiya_intro": {
		"npc": "Ския",
		"lines": [
			{"text": "Энергосети — это нервная система Уламка. Если знаешь код — контролируешь всё.", "speaker": "npc"},
			{"text": "Что предлагаешь?", "speaker": "player", "choices": [
				{"text": "Помочь с саботажем (Операция «Ржавый гвоздь»)", "effect": {"quest": "skiya_recruitment"}},
				{"text": "Только обмен информацией", "effect": {"faction": {"lex_synthesis": 5.0}}},
			]},
			{"text": "Бюро думает, что они контролируют Чрево. Они ошибаются.", "speaker": "npc"},
		]
	},
	"roan_intro": {
		"npc": "Роан",
		"lines": [
			{"text": "1.4g — это не проклятие. Это преимущество. Урон scales с массой оружия * g.", "speaker": "npc"},
			{"text": "Обучишь меня?", "speaker": "player", "choices": [
				{"text": "Да, хочу научиться ближнему бою в 1.4g", "effect": {"quest": "roan_recruitment"}},
				{"text": "Мне больше нужны руны, не мышцы", "effect": {"quest_skip": true}},
			]},
			{"text": "Плотность костей 2.6 г/см³ — каждый удар — это удар гравитации.", "speaker": "npc"},
		]
	},
	"mika_intro": {
		"npc": "Мика",
		"lines": [
			{"text": "Технеций — оружие и яд. 0.01 ppm — лечилка, но каждый пайок — +0.02 Sv. Я нашла способ снизить дозу.", "speaker": "npc"},
			{"text": "Помоги мне с очисткой технеция?", "speaker": "player", "choices": [
				{"text": "Да, давай работаем вместе", "effect": {"quest": "mika_recruitment"}},
				{"text": "Не хочу рисковать с радиацией", "effect": {"quest_skip": true}},
			]},
		]
	},
	"yuna_intro": {
		"npc": "Юна",
		"lines": [
			{"text": "В геометрии Уламка есть слепые пятна. Неевклидовы щели, которые архитектор не видит.", "speaker": "npc"},
			{"text": "Покажи мне маршруты?", "speaker": "player", "choices": [
				{"text": "Да, раскрой слепые пятна", "effect": {"quest": "yuna_recruitment"}},
				{"text": "Я сам найду путь", "effect": {"tension": 3.0}},
			]},
		]
	},
	"final_battle_dialogue": {
		"npc": "Уравнение Вериса (система)",
		"lines": [
			{"text": "V = -k·ΔH. Вы стоите перед фундаментальным уравнением реальности Кассиопеи.", "speaker": "system"},
			{"text": "k = {current_k}. ΔH = {current_delta_h}.", "speaker": "system"},
			{"text": "Выберите судьбу реальности:", "speaker": "system", "choices": [
				{"text": "Стабилизация — зафиксировать уравнение (k остаётся)", "effect": {"ending": "stabilization"}},
				{"text": "Перезапись — сменить знак k (g → 1.0)", "effect": {"ending": "rewrite"}},
				{"text": "Разрыв — уничтожить уравнение", "effect": {"ending": "rift"}},
			]},
		]
	},
}

var current_dialogue_id: String = ""
var current_line_index: int = 0
var is_in_dialogue: bool = false
var dialogue_history: Array = []

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

func start_dialogue(dialogue_id: String) -> void:
	if not DIALOGUES.has(dialogue_id):
		return
	
	current_dialogue_id = dialogue_id
	current_line_index = 0
	is_in_dialogue = true
	dialogue_started.emit(dialogue_id, DIALOGUES[dialogue_id]["npc"])
	_show_current_line()

func _show_current_line() -> void:
	var dialogue = DIALOGUES[current_dialogue_id]
	if current_line_index >= dialogue["lines"].size():
		end_dialogue()
		return
	
	var line = dialogue["lines"][current_line_index]
	dialogue_line_spoken.emit(line["text"], line["speaker"])
	dialogue_history.append({"text": line["text"], "speaker": line["speaker"]})
	
	if line.has("choices"):
		dialogue_choice_presented.emit(line["choices"])

func advance_dialogue() -> void:
	current_line_index += 1
	_show_current_line()

func make_choice(choice_index: int) -> void:
	var dialogue = DIALOGUES[current_dialogue_id]
	var line = dialogue["lines"][current_line_index]
	if not line.has("choices") or choice_index >= line["choices"].size():
		return
	
	var choice = line["choices"][choice_index]
	dialogue_choice_made.emit(choice_index, choice["text"])
	dialogue_history.append({"text": "→ " + choice["text"], "speaker": "player"})
	
	# Apply choice effects
	var effects = choice["effect"]
	if effects.has("archetype"):
		GameState.set_archetype(effects["archetype"])
	if effects.has("quest"):
		QuestManager.start_quest(effects["quest"])
	if effects.has("quest_advance"):
		QuestManager.advance_quest("prologue_escape")
	if effects.has("rune"):
		RunesRegistry.learn_rune(effects["rune"])
	if effects.has("combat"):
		POLERSystem.register_combat_event()
	if effects.has("epsilon"):
		POLERSystem.aggression_score += effects["epsilon"] / 20.0
	if effects.has("tension"):
		POLERSystem.register_failed_attempt("dialogue_choice")
	if effects.has("faction"):
		for faction in effects["faction"]:
			GameState.modify_faction_relation(faction, effects["faction"][faction])
	if effects.has("ending"):
		GameState.endings_unlocked.append(effects["ending"])
		GameState.h_psi_zero_progress = 100.0
	
	current_line_index += 1
	_show_current_line()

func end_dialogue() -> void:
	is_in_dialogue = false
	dialogue_ended.emit(current_dialogue_id)
	current_dialogue_id = ""
	current_line_index = 0
