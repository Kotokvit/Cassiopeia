## PrologueZone.gd — Prologue level (zone сброса, Чрево)
extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var environment: Node3D = $Environment
@onready var enemies: Node3D = $Enemies
@onready var npcs: Node3D = $NPCs
@onready var items: Node3D = $Items
@onready var triggers: Node3D = $Triggers
@onready var lighting: DirectionalLight3D = $Lighting/RedStarLight
@onready var ambient_light: OmniLight3D = $Lighting/AmbientGlow

func _ready() -> void:
	if player and GravityManager:
		GravityManager.register_player(player)
	_setup_environment()
	_setup_lighting()
	_setup_enemies()
	_setup_npcs()
	_setup_items()
	_setup_triggers()
	
	if GameState:
		GameState.set_game_phase(GameState.GamePhase.PROLOGUE)
		GameState.set_tier(GameState.Tier.CHREVO)
	if POLERSystem and POLERSystem.has_method("register_barrier"):
		POLERSystem.register_barrier("chrevo_wall_main", "structural", Vector3(10, 0, 5), true)
		POLERSystem.register_barrier("chrevo_door_locked", "locked_door", Vector3(-5, 0, -10), true)
	if QuestManager and "prologue_escape" not in QuestManager.active_quests:
		QuestManager.start_quest("prologue_escape")

func _setup_environment() -> void:
	var ground = CSGBox3D.new()
	ground.size = Vector3(100, 0.5, 100)
	ground.position = Vector3(0, -0.25, 0)
	ground.material = _mat(Color(0.15, 0.12, 0.1))
	environment.add_child(ground)
	
	for i in range(8):
		var wall = CSGBox3D.new()
		var h = [3.0, 5.0, 7.0, 10.0][i % 4]
		wall.size = Vector3(1.0, h, randf_range(3.0, 8.0))
		wall.position = Vector3(randf_range(-40, 40), h / 2, randf_range(-40, 40))
		wall.material = _mat(Color(0.2, 0.15, 0.1))
		environment.add_child(wall)
	
	for i in range(6):
		var pipe = CSGCylinder3D.new()
		pipe.radius = 0.3
		pipe.height = randf_range(3, 10)
		pipe.position = Vector3(randf_range(-30, 30), pipe.height / 2, randf_range(-30, 30))
		pipe.rotation_degrees = Vector3(randf_range(0, 45), randf_range(0, 360), 0)
		pipe.material = _mat(Color(0.3, 0.25, 0.15))
		environment.add_child(pipe)
	
	for i in range(12):
		var plant = CSGSphere3D.new()
		plant.radius = randf_range(0.2, 0.5)
		plant.position = Vector3(randf_range(-35, 35), 0.5, randf_range(-35, 35))
		plant.material = _glow_mat(Color(0.05, 0.02, 0.02), Color(0.1, 0.3, 0.2))
		environment.add_child(plant)

func _setup_lighting() -> void:
	if lighting:
		lighting.light_color = Color(0.9, 0.3, 0.1)
		lighting.light_energy = 0.4
	if ambient_light:
		ambient_light.light_color = Color(0.1, 0.3, 0.2)
		ambient_light.light_energy = 0.3
		ambient_light.omni_range = 20.0
	
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.01, 0.04)
	env.ambient_light_color = Color(0.1, 0.05, 0.03)
	env.ambient_light_energy = 0.2
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.02, 0.04)
	env.fog_depth_begin = 10.0
	env.fog_depth_end = 50.0
	world_env.environment = env
	add_child(world_env)

func _setup_enemies() -> void:
	for i in range(3):
		var enemy = _create_enemy("bureau_sterilization", "egida_patrol_%d" % i)
		if enemy:
			enemy.position = Vector3(randf_range(-20, 20), 1, randf_range(-20, 20))
			if enemy.has_method("set_patrol_points"):
				enemy.call("set_patrol_points", [
					Vector3(randf_range(-25, -10), 1, randf_range(-25, -10)),
					Vector3(randf_range(10, 25), 1, randf_range(-25, -10)),
					Vector3(randf_range(10, 25), 1, randf_range(10, 25)),
				])
			enemies.add_child(enemy)

func _setup_npcs() -> void:
	var contacter = _create_npc("old_contacter", "Старый контактёр", "faction", "prologue_contact", "")
	if contacter:
		contacter.position = Vector3(5, 1, -8)
		npcs.add_child(contacter)
	
	var skiya = _create_npc("skiya", "Ския", "zgraya", "skiya_intro", "skiya_recruitment")
	if skiya:
		skiya.set("is_recruitable", true)
		skiya.position = Vector3(-15, 1, 10)
		npcs.add_child(skiya)

func _setup_items() -> void:
	for i in range(5):
		var coral = _create_item_pickup("coral_raw", Vector3(randf_range(-30, 30), 0.5, randf_range(-30, 30)))
		items.add_child(coral)
	var nic = _create_item_pickup("nicotine_taurine", Vector3(-10, 0.5, -5))
	items.add_child(nic)

func _setup_triggers() -> void:
	var safehouse = Area3D.new()
	var sh_shape = CollisionShape3D.new()
	var sh_box = BoxShape3D.new()
	sh_box.size = Vector3(3, 3, 3)
	sh_shape.shape = sh_box
	safehouse.add_child(sh_shape)
	safehouse.position = Vector3(20, 1, 20)
	safehouse.connect("body_entered", _on_safehouse_entered)
	triggers.add_child(safehouse)
	
	var maglev = Area3D.new()
	var ml_shape = CollisionShape3D.new()
	var ml_box = BoxShape3D.new()
	ml_box.size = Vector3(6, 0.5, 6)
	ml_shape.shape = ml_box
	maglev.add_child(ml_shape)
	maglev.position = Vector3(0, 0.5, 0)
	maglev.connect("body_entered", _on_maglev_entered)
	maglev.connect("body_exited", _on_maglev_exited)
	triggers.add_child(maglev)

func _on_safehouse_entered(body: Node3D) -> void:
	if body == player:
		if GameState:
			GameState.set_story_flag("first_safehouse_reached", true)
		if QuestManager:
			QuestManager.advance_quest("prologue_escape")

func _on_maglev_entered(body: Node3D) -> void:
	if body == player and GravityManager:
		GravityManager.enter_gravity_zone("maglev_platform")

func _on_maglev_exited(body: Node3D) -> void:
	if body == player and GravityManager:
		GravityManager.leave_gravity_zone()

func _create_enemy(faction: String, id: String) -> CharacterBody3D:
	var enemy_script = load("res://scripts/enemies/enemy_base.gd")
	var enemy = CharacterBody3D.new()
	enemy.set_script(enemy_script)
	enemy.set("enemy_id", id)
	enemy.set("faction", faction)
	var mesh_inst = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.5
	mesh_inst.mesh = cap
	match faction:
		"bureau_sterilization":
			mesh_inst.material_override = _mat(Color(0.3, 0.3, 0.35))
		"shadows":
			mesh_inst.material_override = _mat(Color(0.05, 0.05, 0.1))
		"anomaly_shum":
			mesh_inst.material_override = _mat(Color(0.4, 0.2, 0.5))
	var col = CollisionShape3D.new()
	var cs = CapsuleShape3D.new()
	cs.radius = 0.3
	cs.height = 1.5
	col.shape = cs
	enemy.add_child(mesh_inst)
	enemy.add_child(col)
	return enemy

func _create_npc(nid: String, nname: String, ntype: String, did: String, qid: String) -> CharacterBody3D:
	var npc_script = load("res://scripts/npc/npc_base.gd")
	var npc = CharacterBody3D.new()
	npc.set_script(npc_script)
	npc.set("npc_id", nid)
	npc.set("npc_name", nname)
	npc.set("npc_type", ntype)
	npc.set("npc_dialogue_id", did)
	npc.set("npc_quest_id", qid)
	var mesh_inst = MeshInstance3D.new()
	var cap = CapsuleMesh.new()
	cap.radius = 0.25
	cap.height = 1.4
	mesh_inst.mesh = cap
	mesh_inst.material_override = _mat(Color(0.6, 0.5, 0.4))
	var col = CollisionShape3D.new()
	var cs = CapsuleShape3D.new()
	cs.radius = 0.25
	cs.height = 1.4
	col.shape = cs
	var label3d = Label3D.new()
	label3d.text = nname
	label3d.position = Vector3(0, 1.2, 0)
	label3d.font_size = 16
	npc.add_child(mesh_inst)
	npc.add_child(col)
	npc.add_child(label3d)
	return npc

func _create_item_pickup(item_id: String, pos: Vector3) -> Node3D:
	var node = Node3D.new()
	node.position = pos
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh_inst.mesh = sphere
	match item_id:
		"coral_raw":
			mesh_inst.material_override = _glow_mat(Color(0.1, 0.3, 0.2), Color(0.2, 0.5, 0.3))
		"nicotine_taurine":
			mesh_inst.material_override = _mat(Color(0.3, 0.3, 0.1))
	node.add_child(mesh_inst)
	var area = Area3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 0.5
	area.add_child(shape)
	area.connect("body_entered", _on_item_pickup.bind(item_id, node))
	node.add_child(area)
	return node

func _on_item_pickup(item_id: String, node: Node3D, body: Node3D) -> void:
	if body == player and EconomyManager:
		if EconomyManager.add_item(item_id):
			if item_id == "coral_raw":
				EconomyManager.add_corals(randf_range(1.0, 5.0))
			node.queue_free()

func _mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m

func _glow_mat(base: Color, glow: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = base
	m.emission = glow
	m.emission_energy = 2.0
	m.roughness = 0.6
	return m
