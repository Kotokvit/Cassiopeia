## HUD.gd — Main HUD overlay
## Shows ATF, HP, Oxygen, Rune Echo, Body Temp, Heart Rate, Equipped Runes
extends Control

@onready var hp_bar: ProgressBar = $TopBar/HPBar
@onready var atf_bar: ProgressBar = $TopBar/ATFBar
@onready var oxygen_bar: ProgressBar = $TopBar/OxygenBar
@onready var echo_bar: ProgressBar = $TopBar/EchoBar
@onready var hp_label: Label = $TopBar/HPBar/Label
@onready var atf_label: Label = $TopBar/ATFBar/Label
@onready var oxygen_label: Label = $TopBar/OxygenBar/Label
@onready var echo_label: Label = $TopBar/EchoBar/Label
@onready var temp_label: Label = $StatsPanel/TempLabel
@onready var heart_label: Label = $StatsPanel/HeartLabel
@onready var radiation_label: Label = $StatsPanel/RadiationLabel
@onready var tier_label: Label = $StatsPanel/TierLabel
@onready var corals_label: Label = $StatsPanel/CoralsLabel
@onready var tension_label: Label = $StatsPanel/TensionLabel
@onready var rune_slots: HBoxContainer = $RunePanel/RuneSlots
@onready var perception_indicator: ColorRect = $PerceptionIndicator
@onready var overheating_warning: Label = $OverheatingWarning
@onready var cascade_warning: Label = $CascadeWarning
@onready var dialogue_panel: Panel = $DialoguePanel
@onready var dialogue_text: Label = $DialoguePanel/DialogueText
@onready var dialogue_speaker: Label = $DialoguePanel/SpeakerLabel
@onready var dialogue_choices: VBoxContainer = $DialoguePanel/Choices

func _ready() -> void:
	_connect_signals()
	_setup_rune_slots()
	hide_dialogue()

func _connect_signals() -> void:
	if ATF_Balance:
		ATF_Balance.hp_changed.connect(_on_hp_changed)
		ATF_Balance.atf_changed.connect(_on_atf_changed)
		ATF_Balance.oxygen_changed.connect(_on_oxygen_changed)
		ATF_Balance.rune_echo_changed.connect(_on_echo_changed)
		ATF_Balance.body_temperature_changed.connect(_on_temp_changed)
		ATF_Balance.heart_rate_changed.connect(_on_heart_changed)
		ATF_Balance.overheating_started.connect(_on_overheating_start)
		ATF_Balance.overheating_ended.connect(_on_overheating_end)
		ATF_Balance.atf_critical.connect(_on_atf_critical)
	if ResonanceEngine:
		ResonanceEngine.resonance_cascade_warning.connect(_on_cascade_warning)
		ResonanceEngine.resonance_stabilized.connect(_on_cascade_stable)
	if POLERSystem:
		POLERSystem.perception_activated.connect(_on_perception_on)
		POLERSystem.perception_deactivated.connect(_on_perception_off)
		POLERSystem.no_excuses_tension_changed.connect(_on_tension_changed)
	if DialogueSystem:
		DialogueSystem.dialogue_started.connect(_on_dialogue_start)
		DialogueSystem.dialogue_line_spoken.connect(_on_dialogue_line)
		DialogueSystem.dialogue_choice_presented.connect(_on_dialogue_choices)
		DialogueSystem.dialogue_ended.connect(_on_dialogue_end)
	if EconomyManager:
		EconomyManager.corals_changed.connect(_on_corals_changed)
	if GameState:
		GameState.tier_changed.connect(_on_tier_changed)

func _setup_rune_slots() -> void:
	for i in range(min(5, rune_slots.get_child_count())):
		var slot = rune_slots.get_child(i)
		if slot:
			slot.connect("gui_input", _on_rune_slot_input.bind(i))

func _on_hp_changed(current: float, max_val: float) -> void:
	hp_bar.value = current / max_val * 100
	hp_label.text = "HP: %d/%d" % [int(current), int(max_val)]
	if current / max_val < 0.3:
		hp_bar.modulate = Color.RED
	else:
		hp_bar.modulate = Color.GREEN

func _on_atf_changed(current: float, max_val: float) -> void:
	atf_bar.value = current / max_val * 100
	atf_label.text = "ATF: %d/%d" % [int(current), int(max_val)]

func _on_oxygen_changed(current: float, max_val: float) -> void:
	oxygen_bar.value = current / max_val * 100
	oxygen_label.text = "O2: %d/%d" % [int(current), int(max_val)]
	if current / max_val < 0.2:
		oxygen_bar.modulate = Color.YELLOW

func _on_echo_changed(current: float) -> void:
	var echo_max: float = ATF_Balance.rune_echo_max if ATF_Balance else 50.0
	echo_bar.value = current / echo_max * 100
	echo_label.text = "Echo: %.1f" % current

func _on_temp_changed(temp: float) -> void:
	temp_label.text = "T: %.1f°C" % temp
	if temp >= 40.0:
		temp_label.modulate = Color.RED

func _on_heart_changed(rate: float) -> void:
	heart_label.text = "HR: %d/min" % int(rate)

func _on_overheating_start() -> void:
	overheating_warning.visible = true
	overheating_warning.text = "⚠ ПЕРЕГРЕВ! Руническое эхо!"

func _on_overheating_end() -> void:
	overheating_warning.visible = false

func _on_atf_critical() -> void:
	atf_bar.modulate = Color.YELLOW

func _on_cascade_warning(level: float) -> void:
	cascade_warning.visible = true
	cascade_warning.text = "⚠ КАСКАД РЕЗОНАНСА: %.1f%%" % level

func _on_cascade_stable() -> void:
	cascade_warning.visible = false

func _on_perception_on() -> void:
	perception_indicator.visible = true
	perception_indicator.color = Color(0.2, 0.6, 0.9, 0.3)

func _on_perception_off() -> void:
	perception_indicator.visible = false

func _on_corals_changed(amount: float) -> void:
	corals_label.text = "Corals: %.1f" % amount

func _on_tension_changed(tension: float) -> void:
	var threshold: float = POLERSystem.tension_threshold if POLERSystem and POLERSystem.get("tension_threshold") != null else 100.0
	tension_label.text = "Tension: %.1f%%" % (tension / threshold * 100)

func _on_tier_changed(tier: String) -> void:
	tier_label.text = "Tier: " + tier

func _on_rune_slot_input(slot_index: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		show_rune_menu()

func _on_dialogue_start(_dialogue_id: String, npc_name: String) -> void:
	dialogue_panel.visible = true
	dialogue_speaker.text = npc_name

func _on_dialogue_line(line: String, speaker: String) -> void:
	dialogue_text.text = line
	dialogue_speaker.text = speaker

func _on_dialogue_choices(choices: Array) -> void:
	dialogue_choices.visible = true
	for child in dialogue_choices.get_children():
		child.queue_free()
	for i in range(choices.size()):
		var button = Button.new()
		button.text = choices[i]["text"]
		if DialogueSystem and DialogueSystem.has_method("make_choice"):
			button.connect("pressed", DialogueSystem.make_choice.bind(i))
		dialogue_choices.add_child(button)

func _on_dialogue_end(_dialogue_id: String) -> void:
	hide_dialogue()

func hide_dialogue() -> void:
	dialogue_panel.visible = false
	dialogue_choices.visible = false

func show_rune_menu() -> void:
	get_tree().call_group("rune_ui", "show_rune_crafting")

func _process(_delta: float) -> void:
	# Update rune slot displays
	if RunesRegistry and RunesRegistry.get("equipped_runes"):
		var eq_runes: Array = RunesRegistry.equipped_runes
		for i in range(min(5, rune_slots.get_child_count())):
			var slot = rune_slots.get_child(i)
			if slot:
				var rune_id = eq_runes[i] if i < eq_runes.size() else ""
				if rune_id != "":
					var rune_data = RunesRegistry.get_rune_data(rune_id) if RunesRegistry.has_method("get_rune_data") else {}
					slot.text = rune_data.get("name", rune_id)
					slot.modulate = rune_data.get("color", Color.WHITE)
				else:
					slot.text = "-"
					slot.modulate = Color.GRAY
	
	# Radiation display
	if ATF_Balance:
		radiation_label.text = "Rad: %.3f Sv" % ATF_Balance.personal_radiation
		if ATF_Balance.personal_radiation >= ATF_Balance.radiation_threshold:
			radiation_label.modulate = Color.RED
