## RuneCraftingUI.gd — Rune crafting and equipping interface
extends Control

signal rune_crafted(combo_id: String)
signal rune_equipped(rune_id: String, slot: int)

@onready var learned_runes_grid: GridContainer = $LearnedRunes/Grid
@onready var combo_a_selector: OptionButton = $CraftingPanel/RuneASelector
@onready var combo_b_selector: OptionButton = $CraftingPanel/RuneBSelector
@onready var craft_button: Button = $CraftingPanel/CraftButton
@onready var result_preview: Label = $CraftingPanel/ResultPreview
@onready var equipped_slots: HBoxContainer = $EquippedSlots
@onready var combo_history:ItemList = $HistoryPanel/ComboHistory
@onready var available_combos_list: ItemList = $AvailableCombos/List

func _ready() -> void:
	craft_button.connect("pressed", _on_craft)
	_refresh_rune_selectors()
	_refresh_available_combos()

func show_rune_crafting() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_rune_selectors()
	_refresh_available_combos()
	_refresh_equipped_slots()
	_refresh_learned_runes()

func hide_rune_crafting() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _refresh_rune_selectors() -> void:
	combo_a_selector.clear()
	combo_b_selector.clear()
	for rune_id in RunesRegistry.learned_runes:
		var data = RunesRegistry.get_rune_data(rune_id)
		combo_a_selector.add_item(data.get("name", rune_id))
		combo_b_selector.add_item(data.get("name", rune_id))

func _refresh_available_combos() -> void:
	available_combos_list.clear()
	for combo_id in RunesRegistry.get_available_combinations():
		var combo_data = RunesRegistry._find_combo_by_id(combo_id)
		available_combos_list.add_item(combo_data.get("name", combo_id) + " - " + combo_data.get("description", ""))
	
	for combo_id in RunesRegistry.discovered_combinations:
		var combo_data = RunesRegistry._find_combo_by_id(combo_id)
		combo_history.add_item(combo_data.get("name", combo_id))

func _refresh_equipped_slots() -> void:
	for i in range(equipped_slots.get_child_count()):
		var slot = equipped_slots.get_child(i)
		var rune_id = RunesRegistry.equipped_runes[i]
		if rune_id != "":
			var data = RunesRegistry.get_rune_data(rune_id)
			slot.text = data.get("name", rune_id)
			slot.modulate = data.get("color", Color.WHITE)
		else:
			slot.text = "Empty"
			slot.modulate = Color.GRAY

func _refresh_learned_runes() -> void:
	for child in learned_runes_grid.get_children():
		child.queue_free()
	for rune_id in RunesRegistry.learned_runes:
		var data = RunesRegistry.get_rune_data(rune_id)
		var button = Button.new()
		button.text = data.get("name", rune_id)
		button.modulate = data.get("color", Color.WHITE)
		button.connect("pressed", _on_learned_rune_clicked.bind(rune_id))
		learned_runes_grid.add_child(button)

func _on_learned_rune_clicked(rune_id: String) -> void:
	# Try to equip in first empty slot
	for i in range(RunesRegistry.equipped_runes.size()):
		if RunesRegistry.equipped_runes[i] == "":
			RunesRegistry.equip_rune(rune_id, i)
			_refresh_equipped_slots()
			return

func _on_craft() -> void:
	var index_a = combo_a_selector.selected
	var index_b = combo_b_selector.selected
	if index_a < 0 or index_b < 0:
		result_preview.text = "Select two runes to craft"
		return
	
	var rune_a = RunesRegistry.learned_runes[index_a]
	var rune_b = RunesRegistry.learned_runes[index_b]
	
	var result = RunesRegistry.craft_combination(rune_a, rune_b)
	if result.is_empty():
		result_preview.text = "No valid combination found"
		return
	
	result_preview.text = "Result: %s\n%s\nCost: %.0f ATF\nEcho: %.0f\nDuration: %.0f sec" % [
		result["name"], result["description"], result["cost"], result["echo"], result["duration"]
	]
	
	# Activate the combination
	if RunesRegistry.activate_combination(result["id"]):
		rune_crafted.emit(result["id"])
		_refresh_available_combos()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("rune_menu") and visible:
		hide_rune_crafting()
