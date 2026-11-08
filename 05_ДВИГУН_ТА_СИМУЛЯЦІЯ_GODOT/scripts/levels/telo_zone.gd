## TeIoZone.gd — Средний ярус Уламка (Тело)
## Жилые кварталы, рынки, административные центры
extends Node3D

func _ready() -> void:
	_setup_environment()
	_setup_lighting()
	_setup_npcs()

func _setup_environment() -> void:
	# Тело: more structured, market areas, residential
	# Walls and buildings — more organized architecture
	var ground = CSGBox3D.new()
	ground.size = Vector3(120, 0.5, 120)
	ground.position = Vector3(0, -0.25, 0)
	ground.material = _mat(Color(0.18, 0.15, 0.13))
	add_child(ground)
	
	# Residential blocks
	for i in range(12):
		var block = CSGBox3D.new()
		block.size = Vector3(randf_range(4, 8), randf_range(5, 15), randf_range(4, 8))
		block.position = Vector3(randf_range(-50, 50), block.size.y / 2, randf_range(-50, 50))
		block.material = _mat(Color(0.25, 0.22, 0.18))
		add_child(block)
	
	# Market stalls
	for i in range(6):
		var stall = CSGBox3D.new()
		stall.size = Vector3(2, 1.5, 2)
		stall.position = Vector3(randf_range(-20, 20), 0.75, randf_range(-20, 20))
		stall.material = _mat(Color(0.3, 0.25, 0.15))
		add_child(stall)

func _setup_lighting() -> void:
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.05)
	env.ambient_light_color = Color(0.15, 0.08, 0.04)
	env.ambient_light_energy = 0.3
	env.fog_enabled = true
	env.fog_light_color = Color(0.06, 0.03, 0.05)
	env.fog_depth_begin = 15.0
	env.fog_depth_end = 60.0
	world_env.environment = env
	add_child(world_env)
	
	# Market lighting (neon signs)
	for i in range(4):
		var neon = OmniLight3D.new()
		neon.light_color = Color(0.3, 0.6, 0.8) if i % 2 == 0 else Color(0.8, 0.3, 0.2)
		neon.light_energy = 0.5
		neon.omni_range = 8.0
		neon.position = Vector3(randf_range(-20, 20), 3, randf_range(-20, 20))
		add_child(neon)

func _setup_npcs() -> void:
	# Роан — training hall
	var roan = _create_npc("roan", "Роан", "zgraya", "roan_intro", "roan_recruitment")
	roan.position = Vector3(10, 1, 5)
	add_child(roan)
	
	# Мика — bio lab
	var mika = _create_npc("mika", "Мика", "zgraya", "mika_intro", "mika_recruitment")
	mika.position = Vector3(-20, 1, 15)
	add_child(mika)
	
	# Юна — navigation station
	var yuna = _create_npc("yuna", "Юна", "zgraya", "yuna_intro", "yuna_recruitment")
	yuna.position = Vector3(25, 1, -10)
	add_child(yuna)
	
	# Coral Cartel vendor
	var vendor = _create_npc("coral_vendor", "Коралловый торговец", "faction", "", "")
	vendor.is_vendor = true
	vendor.vendor_items = ["oxygen_canister", "nicotine_taurine", "technetium_pack"]
	vendor.position = Vector3(0, 1, 0)
	add_child(vendor)

func _create_npc(nid: String, nname: String, ntype: String, did: String, qid: String) -> CharacterBody3D:
	var npc = CharacterBody3D.new()
	npc.set_script(load("res://scripts/npc/npc_base.gd"))
	npc.npc_id = nid
	npc.npc_name = nname
	npc.npc_type = ntype
	npc.npc_dialogue_id = did
	npc.npc_quest_id = qid
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
	npc.add_child(mesh_inst)
	npc.add_child(col)
	npc.add_child(label3d)
	return npc

func _mat(color: Color) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	return m
