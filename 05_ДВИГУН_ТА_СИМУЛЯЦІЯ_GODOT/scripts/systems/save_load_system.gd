## SaveLoadSystem.gd — Save/Load game state
extends Node

const SAVE_DIR: String = "user://saves/"
const SAVE_EXTENSION: String = ".sav"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int = 0) -> bool:
	var save_data = GameState.save_game_state()
	save_data["scene_path"] = get_tree().current_scene.scene_file_path
	save_data["player_position"] = _get_player_position()
	
	# Enemy AI states
	var enemy_states: Dictionary = {}
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("export_ai_state"):
			enemy_states[enemy.enemy_id] = enemy.export_ai_state()
	save_data["enemy_ai_states"] = enemy_states
	
	# Inventory
	save_data["inventory"] = EconomyManager.inventory
	save_data["corals"] = EconomyManager.corals
	
	# Quests
	save_data["active_quests"] = QuestManager.active_quests
	save_data["completed_quests"] = QuestManager.completed_quests
	
	# POLER state
	save_data["plasticity_level"] = POLERSystem.plasticity_level
	save_data["tension_energy"] = POLERSystem.tension_energy
	save_data["refraction_zones"] = POLERSystem.refraction_zones
	
	var file_path = SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		return true
	return false

func load_game(slot: int = 0) -> bool:
	var file_path = SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return false
	
	var save_data = json.data
	GameState.load_game_state(save_data)
	
	# Restore inventory
	EconomyManager.inventory = save_data.get("inventory", {})
	EconomyManager.corals = save_data.get("corals", 0.0)
	
	# Restore quests
	QuestManager.active_quests = save_data.get("active_quests", {})
	QuestManager.completed_quests = save_data.get("completed_quests", [])
	
	# Restore POLER
	POLERSystem.plasticity_level = save_data.get("plasticity_level", 0.0)
	POLERSystem.tension_energy = save_data.get("tension_energy", 0.0)
	POLERSystem.refraction_zones = save_data.get("refraction_zones", [])
	
	# Load scene
	var scene_path = save_data.get("scene_path", "")
	if scene_path != "":
		get_tree().change_scene_to_file(scene_path)
	
	return true

func has_save(slot: int = 0) -> bool:
	var file_path = SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]
	return FileAccess.file_exists(file_path)

func delete_save(slot: int = 0) -> void:
	var file_path = SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

func get_save_info(slot: int = 0) -> Dictionary:
	var file_path = SAVE_DIR + "slot_%d%s" % [slot, SAVE_EXTENSION]
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	json.parse(json_string)
	return {
		"archetype": json.data.get("player_archetype", ""),
		"play_time": json.data.get("play_time", 0.0),
		"tier": json.data.get("current_tier", 0),
	}

func _get_player_position() -> Vector3:
	var player = GravityManager.player_node
	if player:
		return player.global_position
	return Vector3.ZERO
