## NPCBase.gd — Base NPC script (Зграя + faction NPCs)
extends CharacterBody3D

signal npc_interacted(npc_id: String)
signal npc_dialogue_started(npc_id: String, dialogue_id: String)

@export var npc_id: String = "npc_default"
@export var npc_name: String = "NPC"
@export var npc_type: String = "zgraya"  # zgraya, faction, vendor, quest_giver
@export var npc_faction: String = ""
@export var npc_dialogue_id: String = ""
@export var npc_quest_id: String = ""
@export var is_recruitable: bool = false
@export var trust_level: float = 0.0
@export var trust_max: float = 100.0
@export var is_vendor: bool = false

# Vendor inventory
@export var vendor_items: Array = []  # item_ids available for purchase

# Movement
var wander_radius: float = 5.0
var home_position: Vector3 = Vector3.ZERO
var wander_target: Vector3 = Vector3.ZERO
var wander_timer: float = 0.0
var npc_speed: float = 1.5

func _ready() -> void:
	home_position = global_position
	collision_layer = 4  # NPC layer
	collision_mask = 1 | 4 | 8  # Player, NPC, Environment
	_pick_wander_target()

func _physics_process(delta: float) -> void:
	_wander(delta)
	move_and_slide()

func _wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0:
		_pick_wander_target()
		wander_timer = randf_range(3.0, 8.0)
	
	if global_position.distance_to(wander_target) > 0.5:
		var direction = (wander_target - global_position).normalized()
		velocity.x = direction.x * npc_speed
		velocity.z = direction.z * npc_speed
	else:
		velocity.x = 0
		velocity.z = 0
	velocity.y -= GravityManager.get_current_gravity() * delta

func _pick_wander_target() -> void:
	wander_target = home_position + Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))

func interact() -> void:
	npc_interacted.emit(npc_id)
	
	if npc_dialogue_id != "":
		DialogueSystem.start_dialogue(npc_dialogue_id)
		npc_dialogue_started.emit(npc_id, npc_dialogue_id)
	
	if npc_quest_id != "" and npc_quest_id not in QuestManager.active_quests:
		QuestManager.start_quest(npc_quest_id)
	
	if is_vendor:
		get_tree().call_group("ui", "show_vendor_menu", npc_id, vendor_items)

func start_dialogue() -> void:
	if npc_dialogue_id != "":
		DialogueSystem.start_dialogue(npc_dialogue_id)

func increase_trust(amount: float) -> void:
	trust_level = min(trust_level + amount, trust_max)

func decrease_trust(amount: float) -> void:
	trust_level = max(trust_level - amount, 0.0)

## Get vendor items for sale
func get_vendor_inventory() -> Array:
	var items: Array = []
	for item_id in vendor_items:
		if EconomyManager.ITEMS.has(item_id):
			items.append({
				"id": item_id,
				"data": EconomyManager.ITEMS[item_id]
			})
	return items
