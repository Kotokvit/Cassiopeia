## SoundManager.gd — Global Singleton
## Звуковая система (атмосфера, музыка, эффекты резонанса)
extends Node

signal sound_effect_played(effect_id: String)
signal ambient_changed(zone: String)

# Audio buses
const BUS_MASTER: String = "Master"
const BUS_AMBIENT: String = "Ambient"
const BUS_SFX: String = "SFX"
const BUS_RESONANCE: String = "Resonance"
const BUS_DIALOGUE: String = "Dialogue"
const BUS_MUSIC: String = "Music"

# Ambient zones
var current_ambient_zone: String = "chrevo"
var ambient_players: Dictionary = {}
var sfx_players: Dictionary = {}

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	_setup_ambient_zones()

func _setup_audio_buses() -> void:
	# Create custom audio buses for the game
	for bus_name in [BUS_AMBIENT, BUS_SFX, BUS_RESONANCE, BUS_DIALOGUE, BUS_MUSIC]:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)

func _setup_ambient_zones() -> void:
	ambient_zones = {
		"chrevo": {"description": "Industrial hum, distant machinery, dripping water", "volume": -6.0},
		"telo": {"description": "Market bustle, neon hum, crowd murmur", "volume": -8.0},
		"nebo": {"description": "Clean air, research equipment hum, distant wind", "volume": -12.0},
		"ocean_reefs": {"description": "Underwater currents, coral luminescence crackle", "volume": -10.0},
	}

func play_sfx(effect_id: String, position: Vector3 = Vector3.ZERO) -> void:
	sound_effect_played.emit(effect_id)
	# In full implementation: load and play appropriate audio stream
	# Placeholder: create procedural audio or use Godot AudioStreamPlayer

func set_ambient_zone(zone: String) -> void:
	current_ambient_zone = zone
	ambient_changed.emit(zone)

func play_resonance_sound(rune_id: String, intensity: float) -> void:
	# Rune activation sounds — unique per rune
	var resonance_config = {
		"tet": {"frequency": 220.0, "waveform": "square"},
		"oro": {"frequency": 330.0, "waveform": "sine"},
		"ka": {"frequency": 440.0, "waveform": "triangle"},
		"vei": {"frequency": 554.0, "waveform": "noise"},
		"nul": {"frequency": 0.0, "waveform": "silence"},  # void
		"sol": {"frequency": 880.0, "waveform": "sine"},
		"zen": {"frequency": 165.0, "waveform": "square"},
		"ari": {"frequency": 297.0, "waveform": "triangle"},
		"dyn": {"frequency": 110.0, "waveform": "square"},
		"mir": {"frequency": 660.0, "waveform": "sine"},
	}
	# Apply resonance audio filter effects
	sound_effect_played.emit("rune_" + rune_id)

func play_overheating_warning() -> void:
	sound_effect_played.emit("overheating_warning")

func play_cascade_alert() -> void:
	sound_effect_played.emit("cascade_alert")

var ambient_zones: Dictionary = {}
