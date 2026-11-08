## GameDataExporter.gd — Exports game data for modding / balancing
extends Node

func export_all_data() -> Dictionary:
	return {
		"runes": RunesRegistry.FUNDAMENTAL_RUNES,
		"combinations": RunesRegistry.COMBINATIONS,
		"items": EconomyManager.ITEMS,
		"quests": QuestManager.QUESTS,
		"dialogues": DialogueSystem.DIALOGUES,
		"archetypes": {
			"resonator_editor": GameState.player_custom_profile if GameState.player_archetype == "resonator_editor" else {},
			"biomech_active": GameState.player_custom_profile if GameState.player_archetype == "biomech_active" else {},
			"resonator_analyst": GameState.player_custom_profile if GameState.player_archetype == "resonator_analyst" else {},
		},
		"gravity_zones": GravityManager.gravity_zones,
		"physics": {
			"cassiopeia_g": GravityManager.CASSIOPEIA_G,
			"earth_g": GravityManager.EARTH_G,
			"lethal_fall_height": GravityManager.LETHAL_FALL_HEIGHT,
			"safe_fall_height": GravityManager.SAFE_FALL_HEIGHT,
		},
		"atf_system": {
			"verisa_k": ATF_Balance.VERISA_K,
			"base_atf_max": ATF_Balance.BASE_ATF_MAX,
			"base_hp_max": ATF_Balance.BASE_HP_MAX,
			"base_oxygen_max": ATF_Balance.BASE_OXYGEN_MAX,
			"overheat_threshold": ATF_Balance.ECHO_OVERHEAT_THRESHOLD,
			"radiation_threshold": ATF_Balance.radiation_threshold,
		},
		"poler_system": {
			"tension_threshold": POLERSystem.tension_threshold,
			"cascade_threshold": ResonanceEngine.CASCADE_THRESHOLD,
		},
		"factions": GameState.faction_relations,
	}

func export_to_json(file_path: String) -> bool:
	var data = export_all_data()
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		return true
	return false

func import_mod_data(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return false
	
	var mod_data = json.data
	
	# Apply mod modifications (would need validation in full version)
	if mod_data.has("runes"):
		for rune_id in mod_data["runes"]:
			if RunesRegistry.FUNDAMENTAL_RUNES.has(rune_id):
				RunesRegistry.FUNDAMENTAL_RUNES[rune_id].merge(mod_data["runes"][rune_id])
	if mod_data.has("items"):
		for item_id in mod_data["items"]:
			if EconomyManager.ITEMS.has(item_id):
				EconomyManager.ITEMS[item_id].merge(mod_data["items"][item_id])
	if mod_data.has("physics"):
		if mod_data["physics"].has("cassiopeia_g"):
			GravityManager.gravity_zones["default"] = mod_data["physics"]["cassiopeia_g"]
	
	return true
