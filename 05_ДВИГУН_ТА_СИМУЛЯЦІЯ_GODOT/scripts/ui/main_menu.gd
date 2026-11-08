## MainMenu.gd — Main menu scene
extends Control

@onready var start_button: Button = $MenuPanel/StartButton
@onready var load_button: Button = $MenuPanel/LoadButton
@onready var settings_button: Button = $MenuPanel/SettingsButton
@onready var quit_button: Button = $MenuPanel/QuitButton
@onready var title_label: Label = $TitlePanel/TitleLabel
@onready var subtitle_label: Label = $TitlePanel/SubtitleLabel
@onready var status_label: Label = $MenuPanel/StatusLabel

var save_system: Node = null

func _ready() -> void:
	start_button.connect("pressed", _on_start)
	load_button.connect("pressed", _on_load)
	settings_button.connect("pressed", _on_settings)
	quit_button.connect("pressed", _on_quit)
	title_label.text = "КАССИОПЕЯ"
	subtitle_label.text = "Резонанс Разрыва"
	
	save_system = Node.new()
	save_system.set_script(load("res://scripts/systems/save_load_system.gd"))
	add_child(save_system)
	
	load_button.disabled = not save_system.has_save(0)

func _on_start() -> void:
	# Go to prologue scene
	get_tree().change_scene_to_file("res://scenes/levels/prologue_zone.tscn")

func _on_load() -> void:
	if save_system.load_game(0):
		status_label.text = "Загрузка..."
	else:
		status_label.text = "Ошибка загрузки"

func _on_settings() -> void:
	# Settings panel (placeholder)
	status_label.text = "Настройки (в разработке)"

func _on_quit() -> void:
	get_tree().quit()
