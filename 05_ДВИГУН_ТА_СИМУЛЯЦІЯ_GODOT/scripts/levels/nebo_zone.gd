## NeboZone.gd — Верхний ярус Уламка (Небо)
## Элитные районы, исследовательские комплексы, орбитальная станция «Разбитый бог»
extends Node3D

func _ready() -> void:
	_setup_environment()
	_setup_lighting()
	_setup_endgame_content()

func _setup_environment() -> void:
	# Небо: cleaner, more advanced architecture
	# Orbital station area "Разбитый бог"
	var ground = CSGBox3D.new()
	ground.size = Vector3(80, 0.5, 80)
	ground.position = Vector3(0, -0.25, 0)
	ground.material = _mat(Color(0.25, 0.22, 0.2))
	add_child(ground)
	
	# Research complex buildings
	for i in range(5):
		var building = CSGBox3D.new()
		building.size = Vector3(randf_range(6, 12), randf_range(8, 20), randf_range(6, 12))
		building.position = Vector3(randf_range(-30, 30), building.size.y / 2, randf_range(-30, 30))
		building.material = _mat(Color(0.3, 0.28, 0.25))
		add_child(building)
	
	# Server zone "Аксиома" — the final location
	var axiom_server = CSGBox3D.new()
	axiom_server.size = Vector3(10, 5, 10)
	axiom_server.position = Vector3(30, 2.5, 30)
	axiom_server.material = _mat(Color(0.1, 0.1, 0.3))  # dark tech
	add_child(axiom_server)
	
	# Orbital station connection
	var station_link = CSGCylinder3D.new()
	station_link.radius = 1.5
	station_link.height = 15.0
	station_link.position = Vector3(-20, 7.5, -20)
	station_link.material = _mat(Color(0.15, 0.15, 0.2))
	add_child(station_link)

func _setup_lighting() -> void:
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.03, 0.08)  # deeper dark
	env.ambient_light_color = Color(0.2, 0.1, 0.15)  # cleaner light
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.08, 0.04, 0.1)
	env.fog_depth_begin = 20.0
	env.fog_depth_end = 80.0
	world_env.environment = env
	add_child(world_env)
	
	# Research lighting — cold, clinical
	var research_light = OmniLight3D.new()
	research_light.light_color = Color(0.5, 0.5, 0.6)
	research_light.light_energy = 0.4
	research_light.omni_range = 15.0
	research_light.position = Vector3(0, 5, 0)
	add_child(research_light)

func _setup_endgame_content() -> void:
	# Server zone trigger (endgame)
	POLERSystem.register_barrier("axiom_door", "quantum_lock", Vector3(30, 2.5, 30), true)
	
	# Шіні (Shadows) — elite assassins near axiom
	for i in range(2):
		var shadow = CharacterBody3D.new()
		shadow.set_script(load("res://scripts/enemies/enemy_base.gd"))
		shadow.enemy_id = "shadow_%d" % i
		shadow.faction = "shadows"
		shadow.position = Vector3(randf_range(20, 35), 1, randf_range(20, 35))
		var mesh_inst = MeshInstance3D.new()
		var cap = CapsuleMesh.new()
		cap.radius = 0.25
		cap.height = 1.4
		mesh_inst.mesh = cap
		mesh_inst.material_override = _mat(Color(0.05, 0.05, 0.1))
		var col = CollisionShape3D.new()
		var cs = CapsuleShape3D.new()
		cs.radius = 0.25
		cs.height = 1.4
		col.shape = cs
		shadow.add_child(mesh_inst)
		shadow.add_child(col)
		add_child(shadow)

func _mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.7
	return m
