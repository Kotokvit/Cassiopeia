## FinalBattle.gd — Эндгейм: битва за изменение уравнения реальности
## Игрок меняет параметры V = -k·ΔH через комбинации рун
extends Node3D

signal equation_parameter_changed(param: String, new_value: float)
signal ending_triggered(ending_type: String)

# Equation parameters (modifiable in real-time)
var equation_k: float = 0.85  # k constant
var equation_delta_h: float = 0.0  # ΔH (energy deficit)
var equation_sign: int = -1  # sign of equation (-1 default)

# Timed windows for parameter changes
var active_windows: Array = []
var window_duration: float = 3.0  # seconds per window
var windows_remaining: int = 10  # total available windows
var current_window_index: int = 0

# Phase tracking
var battle_phase: String = "approach"  # approach, equation_core, modification, choice
var is_in_core: bool = false

func _ready() -> void:
	_setup_core_environment()
	_setup_equation_display()
	_setup_windows()
	GameState.set_game_phase(GameState.GamePhase.FINAL_BATTLE)

func _setup_core_environment() -> void:
	# The core is a surreal space — reality is visible as code
	var ground = CSGBox3D.new()
	ground.size = Vector3(30, 0.5, 30)
	ground.material = _mat(Color(0.05, 0.05, 0.2))  # dark quantum
	add_child(ground)
	
	# Equation pillars — visual representation of k, ΔH, sign
	for i in range(3):
		var pillar = CSGCylinder3D.new()
		pillar.radius = 0.5
		pillar.height = 5.0
		pillar.position = Vector3(i * 5 - 5, 2.5, 0)
		pillar.material = _glow(Color(0.3, 0.5, 0.9), Color(0.2, 0.4, 0.8))
		add_child(pillar)
	
	# Architect defense systems
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.05)  # deep void
	env.ambient_light_color = Color(0.3, 0.3, 0.5)
	env.ambient_light_energy = 0.5
	world_env.environment = env
	add_child(world_env)

func _setup_equation_display() -> void:
	# Display the current equation state
	pass  # UI overlay handled by HUD

func _setup_windows() -> void:
	for i in range(windows_remaining):
		active_windows.append({
			"index": i,
			"param": ["k", "sign", "delta_h"][i % 3],
			"start_time": i * window_duration + 2.0,
			"duration": window_duration,
			"is_open": false,
			"is_used": false,
		})

func _process(delta: float) -> void:
	# Check timed windows
	var elapsed = Time.get_ticks_msec() / 1000.0
	for window in active_windows:
		if elapsed >= window["start_time"] and elapsed < window["start_time"] + window["duration"]:
			window["is_open"] = true
		else:
			window["is_open"] = false

## Modify equation parameter during active window
func modify_parameter(param: String, new_value: float) -> bool:
	# Check if current window allows this parameter
	for window in active_windows:
		if window["is_open"] and window["param"] == param and not window["is_used"]:
			match param:
				"k":
					equation_k = new_value
				"sign":
					equation_sign = int(new_value)
				"delta_h":
					equation_delta_h = new_value
			
			window["is_used"] = true
			equation_parameter_changed.emit(param, new_value)
			GameState.h_psi_zero_progress += 10.0
			
			# ATF cost for parameter change
			ATF_Balance.spend_atf(20.0, 5.0)
			return true
	
	return false

## Check ending conditions
func check_ending() -> String:
	var ending = GameState.check_ending_conditions()
	if ending != "":
		trigger_ending(ending)
	return ending

func trigger_ending(ending_type: String) -> void:
	match ending_type:
		"stabilization":
			# Fix equation, reality preserved, player marked as "Noise"
			equation_sign = -1
			equation_k = 0.85
			GameState.set_story_flag("ending_stabilization", true)
		"rewrite":
			# Change sign of k, g drops to 1.0, chaos bursts
			equation_sign = 1
			equation_k = 0.6
			GravityManager.set_local_gravity_constant(9.8, 9999.0)  # permanent 1.0g
			GameState.set_story_flag("ending_rewrite", true)
		"rift":
			# Destroy equation, reality fragments, player becomes resonance node
			equation_k = 0.0  # equation destroyed
			GameState.set_story_flag("ending_rift", true)
	
	ending_triggered.emit(ending_type)
	GameState.endings_unlocked.append(ending_type)
	GameState.h_psi_zero_progress = 100.0

## Calculate current equation value
func get_current_equation_value() -> float:
	return float(equation_sign) * equation_k * equation_delta_h

func get_equation_display() -> String:
	var sign_str = "-" if equation_sign == -1 else "+"
	return "V = %s %.2f × %.2f = %.2f" % [sign_str, equation_k, equation_delta_h, get_current_equation_value()]

func get_active_window() -> Dictionary:
	for window in active_windows:
		if window["is_open"] and not window["is_used"]:
			return window
	return {}

func _mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.7
	return m

func _glow(base: Color, em: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = base
	m.emission = em
	m.emission_energy = 3.0
	m.roughness = 0.5
	return m
