## DistributionMenu.gd — Archetype selection / customization screen
## Выбор архетипа после процедуры «Распределение»
extends Control

signal archetype_selected(archetype: String)
signal custom_profile_created(profile: Dictionary)

@onready var editor_button: Button = $ArchetypePanel/EditorButton
@onready var biomech_button: Button = $ArchetypePanel/BiomechButton
@onready var analyst_button: Button = $ArchetypePanel/AnalystButton
@onready var custom_button: Button = $ArchetypePanel/CustomButton
@onready var custom_panel: Panel = $CustomPanel
@onready var biomech_slider: HSlider = $CustomPanel/BiomechSlider
@onready var cognitive_slider: HSlider = $CustomPanel/CognitiveSlider
@onready var skeleton_slider: HSlider = $CustomPanel/SkeletonSlider
@onready var muscle_slider: HSlider = $CustomPanel/MuscleSlider
@onready var metabolism_slider: HSlider = $CustomPanel/MetabolismSlider
@onready var rune_slider: HSlider = $CustomPanel/RuneSlider
@onready var l_logic_slider: HSlider = $CustomPanel/LogicSlider
@onready var stress_slider: HSlider = $CustomPanel/StressSlider
@onready var confirm_button: Button = $CustomPanel/ConfirmButton
@onready var description_label: Label = $DescriptionPanel/DescriptionLabel
@onready var stats_preview: RichTextLabel = $DescriptionPanel/StatsPreview

var selected_archetype: String = ""

func _ready() -> void:
	editor_button.connect("pressed", _select_archetype.bind("resonator_editor"))
	biomech_button.connect("pressed", _select_archetype.bind("biomech_active"))
	analyst_button.connect("pressed", _select_archetype.bind("resonator_analyst"))
	custom_button.connect("pressed", _show_custom_panel)
	confirm_button.connect("pressed", _confirm_selection)

func _select_archetype(archetype: String) -> void:
	selected_archetype = archetype
	_update_description(archetype)
	_update_stats_preview(archetype)

func _show_custom_panel() -> void:
	custom_panel.visible = true
	selected_archetype = "custom"

func _update_description(archetype: String) -> void:
	match archetype:
		"resonator_editor":
			description_label.text = """Резонатор-Редактор (Класс S – Аномалия)

Прямое изменение базового кода реальности через 10 фундаментальных рун.
Может понижать плотность материалов (вольфрам → аэрогель),
создавать квантовые туннели, менять локальное значение гравитационной постоянной.

Стоимость: расход АТФ + технецием → накопление «Рунического эха» при перерасходе."""
		"biomech_active":
			description_label.text = """Биомеханический Актив (Класс Σ – Вершина, тип «Роан»)

Физическое превосходство. Плотность костей 2.6 г/см³,
мышечная сила +40% к базовой. Полная адаптация к 1.4g —
игнорирование дебаффов гравитационного стресса,
повышенная грузоподъёмность (до 30 кг снаряжения),
смертоносный ближний бой (урон scales с массой оружия * g).

Ограничение: низкая скорость восстановления АТФ после тяжёлых нагрузок."""
		"resonator_analyst":
			description_label.text = """Резонатор-Аналитик (Проектор Причинности)

Стелс, взлом инфраструктуры, использование Пространственных Манипуляторов (ПМ).
Видение «слепых пятен» в геометрии уровня и вероятностных траекторий врагов.

Ресурс: потребление АТФ при активации ПМ, но без технециевого побочного эффекта."""
		"custom":
			description_label.text = """Кастомный профиль

Настройте два параметра:
— Биомеханический актив (структура скелета, мышечная плотность, метаболизм)
— Когнитивный профиль (манипуляция рунами, скорость L-логики, порог стресса)

Внимание: баланс имеет цену. Высокий биомех → низкие руны. Высокие руны → слабое тело."""

func _update_stats_preview(archetype: String) -> void:
	match archetype:
		"resonator_editor":
			stats_preview.text = """[b]Статы Резонатор-Редактор:[/b]
ATF реген: базовый -0.5 штраф
Плотность костей: 0.8 г/см³
Мышечная сила: -30%
Манипуляция рунами: 100% (полная)
L-логика: +50%
Порог стресса: низкий (0.6)
Урон ближний: 0.7x
Грузоподъёмность: 15 кг"""
		"biomech_active":
			stats_preview.text = """[b]Статы Биомеханический Актив:[/b]
ATF реген: базовый -1.5 штраф (низкое восстановление)
Плотность костей: 2.6 г/см³
Мышечная сила: +40%
Манипуляция рунами: 30% (ограничена)
L-логика: -30%
Порог стресса: высокий (1.5)
Урон ближний: 1.4x (scales с g)
Грузоподъёмность: 30 кг"""
		"resonator_analyst":
			stats_preview.text = """[b]Статы Резонатор-Аналитик:[/b]
ATF реген: базовый
Плотность костей: 1.0 г/см³
Мышечная сила: базовая
Манипуляция рунами: 70%
L-логика: +30%
Порог стресса: средний (0.8)
Урон: 0.5x
Грузоподъёмность: 12 кг
Слепые пятна: да (ПМ)
Стелс: да"""

func _confirm_selection() -> void:
	if selected_archetype == "custom":
		var profile = {
			"biomech_active": biomech_slider.value,
			"cognitive_profile": cognitive_slider.value,
			"skeleton_density": skeleton_slider.value,
			"muscle_density": 1.0 + (muscle_slider.value - 0.5) * 0.8,
			"metabolism": metabolism_slider.value,
			"rune_manipulation": rune_slider.value,
			"l_logic_speed": 0.5 + l_logic_slider.value,
			"stress_threshold": stress_slider.value,
		}
		GameState.set_archetype("custom", profile)
		custom_profile_created.emit(profile)
	else:
		GameState.set_archetype(selected_archetype)
	archetype_selected.emit(selected_archetype)
	GameState.set_story_flag("distribution_done", true)
	QuestManager.advance_quest("distribution")
	visible = false

func show_menu() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	custom_panel.visible = false
