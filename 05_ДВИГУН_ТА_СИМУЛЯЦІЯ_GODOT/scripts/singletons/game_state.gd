## GameState.gd — Global Singleton
## Глобальное состояние игры: уровень, фракции, квесты, финалы
extends Node

signal tier_changed(new_tier: String)
signal faction_relation_changed(faction: String, new_level: float)
signal zgraya_member_recruited(member_id: String)
signal game_phase_changed(phase: String)
signal ending_unlocked(ending_type: String)

# Tier system (Ulamok vertical city)
enum Tier { CHREVO = 0, TELO = 1, NEBO = 2 }  # Чрево, Тело, Небо
var current_tier: Tier = Tier.CHREVO
var accessible_tiers: Array = [Tier.CHREVO]

# Game phase
enum GamePhase { PROLOGUE, MIDGAME, ENDGAME, FINAL_BATTLE }
var current_phase: GamePhase = GamePhase.PROLOGUE

# Player archetype
var player_archetype: String = ""  # "resonator_editor", "biomech_active", "resonator_analyst"
var player_custom_profile: Dictionary = {
	"biomech_active": 0.5,  # 0-1
	"cognitive_profile": 0.5,  # 0-1
	"skeleton_density": 1.0,
	"muscle_density": 1.0,
	"metabolism": 1.0,
	"rune_manipulation": 1.0,
	"l_logic_speed": 1.0,
	"stress_threshold": 1.0,
}

# Faction relations (-100 to 100)
var faction_relations: Dictionary = {
	"bureau_sterilization": -20.0,  # Бюро Стерилизации — hostile
	"shadows": -50.0,  # Тіні — very hostile
	"coral_cartel": 0.0,  # Коралловый Картель — neutral
	"lex_synthesis": 10.0,  # Lex Σύνθησις — slightly friendly
	"architect": -100.0,  # Архитектор — hidden antagonist
}

# Zgraya members recruited
var zgraya_members: Dictionary = {
	"skiya": {"recruited": false, "trust": 0.0},
	"roan": {"recruited": false, "trust": 0.0},
	"mika": {"recruited": false, "trust": 0.0},
	"yuna": {"recruited": false, "trust": 0.0},
}

# Ending tracking
var endings_unlocked: Array = []
var h_psi_zero_progress: float = 0.0  # 0-100 progress toward HΨ=0

# Story flags
var story_flags: Dictionary = {
	"prologue_complete": false,
	"distribution_done": false,
	"first_safehouse_reached": false,
	"egida_alerted": false,
	"deep_rift_accident": true,
	"rusty nail_operation": false,
}

# Stats tracking
var total_combat_events: int = 0
var total_rune_activations: int = 0
var total_corals_collected: float = 0.0
var total_distance_traveled: float = 0.0
var play_time: float = 0.0

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	play_time += delta

func set_tier(tier: Tier) -> void:
	current_tier = tier
	tier_changed.emit(_tier_name(tier))

func advance_tier() -> void:
	if current_tier < Tier.NEBO:
		current_tier += 1
		accessible_tiers.append(current_tier)
		tier_changed.emit(_tier_name(current_tier))

func set_game_phase(phase: GamePhase) -> void:
	current_phase = phase
	game_phase_changed.emit(_phase_name(phase))

func set_archetype(archetype: String, custom_profile: Dictionary = {}) -> void:
	player_archetype = archetype
	if not custom_profile.is_empty():
		player_custom_profile = custom_profile
	else:
		match archetype:
			"resonator_editor":
				player_custom_profile = {
					"biomech_active": 0.3,
					"cognitive_profile": 0.9,
					"skeleton_density": 0.8,
					"muscle_density": 0.7,
					"metabolism": 1.2,
					"rune_manipulation": 1.0,
					"l_logic_speed": 1.5,
					"stress_threshold": 0.6,
				}
				ATF_Balance.atf_regen_penalty = 0.5
			"biomech_active":
				player_custom_profile = {
					"biomech_active": 0.95,
					"cognitive_profile": 0.3,
					"skeleton_density": 2.6,  # g/cm³
					"muscle_density": 1.4,  # +40%
					"metabolism": 0.8,
					"rune_manipulation": 0.3,
					"l_logic_speed": 0.7,
					"stress_threshold": 1.5,
				}
				ATF_Balance.atf_regen_penalty = 1.5  # low recovery
				ATF_Balance.gravity_stress_factor = 0.5  # adapted to 1.4g
			"resonator_analyst":
				player_custom_profile = {
					"biomech_active": 0.4,
					"cognitive_profile": 0.85,
					"skeleton_density": 1.0,
					"muscle_density": 1.0,
					"metabolism": 1.0,
					"rune_manipulation": 0.7,
					"l_logic_speed": 1.3,
					"stress_threshold": 0.8,
				}
	ResonanceEngine.set_archetype(archetype)

func modify_faction_relation(faction: String, delta_change: float) -> void:
	if faction_relations.has(faction):
		faction_relations[faction] = clampf(faction_relations[faction] + delta_change, -100.0, 100.0)
		faction_relation_changed.emit(faction, faction_relations[faction])

func recruit_zgraya_member(member_id: String) -> void:
	if zgraya_members.has(member_id):
		zgraya_members[member_id]["recruited"] = true
		zgraya_member_recruited.emit(member_id)
		
		# Grant unique abilities
		match member_id:
			"skiya":
				RunesRegistry.learn_rune("vei")
				story_flags["rusty nail_operation"] = true
			"roan":
				ATF_Balance.atf_regen_penalty -= 0.3
			"mika":
				# Better technetium packs with less radiation
				pass
			"yuna":
				ResonanceEngine.can_see_blind_spots = true

func set_story_flag(flag: String, value: bool) -> void:
	story_flags[flag] = value

func check_ending_conditions() -> String:
	var ending = ""
	if h_psi_zero_progress >= 100.0:
		if zgraya_members.values().filter(func(m): return m["recruited"]).size() >= 3:
			ending = "rewrite"
		elif faction_relations["architect"] >= 0:
			ending = "stabilization"
		else:
			ending = "rift"
	return ending

func _tier_name(tier: Tier) -> String:
	match tier:
		Tier.CHREVO: return "Чрево"
		Tier.TELO: return "Тело"
		Tier.NEBO: return "Небо"
	return "Unknown"

func _phase_name(phase: GamePhase) -> String:
	match phase:
		GamePhase.PROLOGUE: return "Пролог"
		GamePhase.MIDGAME: return "Мидгейм"
		GamePhase.ENDGAME: return "Эндгейм"
		GamePhase.FINAL_BATTLE: return "Финальная битва"
	return "Unknown"

func save_game_state() -> Dictionary:
	return {
		"current_tier": current_tier,
		"current_phase": current_phase,
		"player_archetype": player_archetype,
		"player_custom_profile": player_custom_profile,
		"faction_relations": faction_relations,
		"zgraya_members": zgraya_members,
		"story_flags": story_flags,
		"h_psi_zero_progress": h_psi_zero_progress,
		"endings_unlocked": endings_unlocked,
		"atf": ATF_Balance.atf,
		"hp": ATF_Balance.hp,
		"oxygen": ATF_Balance.oxygen,
		"rune_echo": ATF_Balance.rune_echo,
		"learned_runes": RunesRegistry.learned_runes,
		"equipped_runes": RunesRegistry.equipped_runes,
		"discovered_combinations": RunesRegistry.discovered_combinations,
		"personal_radiation": ATF_Balance.personal_radiation,
		"play_time": play_time,
	}

func load_game_state(data: Dictionary) -> void:
	current_tier = data.get("current_tier", Tier.CHREVO)
	current_phase = data.get("current_phase", GamePhase.PROLOGUE)
	player_archetype = data.get("player_archetype", "")
	player_custom_profile = data.get("player_custom_profile", {})
	faction_relations = data.get("faction_relations", faction_relations)
	zgraya_members = data.get("zgraya_members", zgraya_members)
	story_flags = data.get("story_flags", story_flags)
	h_psi_zero_progress = data.get("h_psi_zero_progress", 0.0)
	endings_unlocked = data.get("endings_unlocked", [])
	ATF_Balance.atf = data.get("atf", ATF_Balance.atf_max)
	ATF_Balance.hp = data.get("hp", ATF_Balance.hp_max)
	ATF_Balance.oxygen = data.get("oxygen", ATF_Balance.oxygen_max)
	ATF_Balance.rune_echo = data.get("rune_echo", 0.0)
	ATF_Balance.personal_radiation = data.get("personal_radiation", 0.0)
	RunesRegistry.learned_runes = data.get("learned_runes", ["tet", "oro", "ka"])
	RunesRegistry.equipped_runes = data.get("equipped_runes", ["", "", "", "", ""])
	RunesRegistry.discovered_combinations = data.get("discovered_combinations", [])
	play_time = data.get("play_time", 0.0)
