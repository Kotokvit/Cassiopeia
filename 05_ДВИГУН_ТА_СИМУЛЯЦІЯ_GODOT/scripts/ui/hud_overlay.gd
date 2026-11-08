extends Control

@onready var health_label: Label = $VBoxContainer/HealthLabel
@onready var atf_label: Label = $VBoxContainer/ATFLabel
@onready var temp_label: Label = $VBoxContainer/TempLabel
@onready var heart_label: Label = $VBoxContainer/HeartLabel
@onready var gravity_label: Label = $VBoxContainer/GravityLabel
@onready var poler_label: Label = $VBoxContainer/PolerLabel

func _ready() -> void:
	ATFSystem.atf_changed.connect(_on_atf_changed)
	ATFSystem.heat_updated.connect(_on_heat_updated)
	GravitySystem.gravity_changed.connect(_on_gravity_changed)
	POLERSystem.perception_toggled.connect(_on_poler_toggled)
	
	_update_all_hud()

func _process(_delta: float) -> void:
	health_label.text = "HP: %.1f / %.1f" % [ATFSystem.current_health, ATFSystem.max_health]

func _update_all_hud() -> void:
	atf_label.text = "АТФ (ATP Pool): %.1f / %.1f" % [ATFSystem.current_atf, ATFSystem.max_atf]
	temp_label.text = "Температура: %.1f °C" % ATFSystem.body_temperature
	heart_label.text = "Пульс (Heart Rate): %.0f BPM" % ATFSystem.heart_rate
	gravity_label.text = "Гравитация: %.2f m/s² (1.4g)" % GravitySystem.current_gravity
	poler_label.text = "POLER [P] Наблюдатель: ВЫКЛ"

func _on_atf_changed(curr: float, max_v: float) -> void:
	atf_label.text = "АТФ (ATP Pool): %.1f / %.1f" % [curr, max_v]

func _on_heat_updated(temp: float, heart: float, echo: float) -> void:
	temp_label.text = "Температура: %.1f °C [Эхо-Тепло: %.1f]" % [temp, echo]
	heart_label.text = "Пульс: %.0f BPM" % heart

func _on_gravity_changed(g_val: float) -> void:
	gravity_label.text = "Гравитация: %.2f m/s²" % g_val

func _on_poler_toggled(active: bool) -> void:
	poler_label.text = "POLER [P] Наблюдатель: " + ("ВКЛ (АКТИВЕН)" if active else "ВЫКЛ")
