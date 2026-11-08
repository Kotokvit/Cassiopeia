## EconomyManager.gd — Global Singleton
## Система расходников и экономики (кораллы, никотиноиды, технеций)
extends Node

signal corals_changed(new_amount: float)
signal item_consumed(item_id: String)
signal purchase_completed(item_id: String, cost: float)
signal purchase_failed(item_id: String, reason: String)
signal radiation_level_changed(level: float)

# Currency: Luminescent Corals
var corals: float = 0.0
var corals_max_carry: float = 500.0

# Inventory system
var inventory: Dictionary = {}  # item_id -> {count, data}
var inventory_max_slots: int = 20

# Item definitions
const ITEMS: Dictionary = {
	"nicotine_taurine": {
		"name": "Никотиноиды + Таурин",
		"description": "Антигравитационный стабилизатор. +15% выносливость на 30 сек.",
		"type": "consumable",
		"cost_corals": 5.0,
		"stack_max": 10,
		"effect": "stamina_boost",
		"use_function": "apply_nicotine_taurine"
	},
	"technetium_pack": {
		"name": "Технециевый пайок",
		"description": "Регенерация +25% HP/сек. Радиация +0.02 Sv за использование.",
		"type": "consumable",
		"cost_corals": 15.0,
		"stack_max": 5,
		"effect": "healing",
		"use_function": "apply_technetium_pack",
		"radiation_per_use": 0.02
	},
	"technetium_pack_improved": {
		"name": "Улучшенный технециевый пайок (Мика)",
		"description": "Регенерация +25% HP/сек. Радиация +0.01 Sv (меньше побочного эффекта).",
		"type": "consumable",
		"cost_corals": 25.0,
		"stack_max": 5,
		"effect": "healing",
		"use_function": "apply_technetium_pack_improved",
		"radiation_per_use": 0.01
	},
	"coral_raw": {
		"name": "Сырой люминесцентный коралл",
		"description": "Энергоноситель и валюта. Можно продать или зарядить гаджеты.",
		"type": "resource",
		"cost_corals": 1.0,
		"stack_max": 100,
	},
	"oxygen_canister": {
		"name": "Кислородный баллон",
		"description": "Восстанавливает 50% кислорода.",
		"type": "consumable",
		"cost_corals": 8.0,
		"stack_max": 5,
		"effect": "oxygen_restore",
		"use_function": "apply_oxygen_canister"
	},
	"gravity_boots": {
		"name": "Гравитационные ботинки",
		"description": "Снижают эффект 1.4g. +10% к мобильности.",
		"type": "equipment",
		"cost_corals": 50.0,
		"stack_max": 1,
		"effect": "gravity_reduction",
	},
	"resonance_suppressor": {
		"name": "Подавитель резонанса",
		"description": "Уменьшает эффективность рун на 40% в радиусе 5м (враги используют).",
		"type": "equipment",
		"cost_corals": 30.0,
		"stack_max": 1,
		"effect": "rune_suppress",
	},
	"heavy_weapon_roan": {
		"name": "Тяжёлое вооружение (Роан)",
		"description": "Урон scales с массой оружия * g.",
		"type": "equipment",
		"cost_corals": 80.0,
		"stack_max": 1,
		"effect": "gravity_weapon",
	},
	"skiya_hack_tool": {
		"name": "Хакерский инструмент (Ския)",
		"description": "Взлом энергосетей. Операция «Ржавый гвоздь».",
		"type": "equipment",
		"cost_corals": 40.0,
		"stack_max": 1,
		"effect": "network_hack",
	},
	"yuna_nav_device": {
		"name": "Навигационный прибор (Юна)",
		"description": "Раскрытие скрытых маршрутов через слепые пятна.",
		"type": "equipment",
		"cost_corals": 45.0,
		"stack_max": 1,
		"effect": "navigation",
	},
	"plasma_whip": {
		"name": "Плазменный кнут (Тіні)",
		"description": "Проникающее оружие. Высокий урон, низкая защита от зоны.",
		"type": "weapon",
		"cost_corals": 60.0,
		"stack_max": 1,
	},
	"sweep_baton": {
		"name": "Дубинка-подметатель (Бюро)",
		"description": "Тяжёлая ударная дубинка Бюро Стерилизации.",
		"type": "weapon",
		"cost_corals": 20.0,
		"stack_max": 1,
	},
}

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

## Add corals (currency)
func add_corals(amount: float) -> void:
	corals = min(corals + amount, corals_max_carry)
	corals_changed.emit(corals)

## Remove corals
func remove_corals(amount: float) -> bool:
	if corals < amount:
		return false
	corals -= amount
	corals_changed.emit(corals)
	return true

## Add item to inventory
func add_item(item_id: String, count: int = 1) -> bool:
	if not ITEMS.has(item_id):
		return false
	
	var item_data = ITEMS[item_id]
	if inventory.has(item_id):
		var current_count = inventory[item_id]["count"]
		if current_count + count > item_data["stack_max"]:
			return false
		inventory[item_id]["count"] += count
	else:
		if inventory.size() >= inventory_max_slots:
			return false
		inventory[item_id] = {"count": count, "data": item_data}
	return true

## Remove item from inventory
func remove_item(item_id: String, count: int = 1) -> bool:
	if not inventory.has(item_id):
		return false
	if inventory[item_id]["count"] < count:
		return false
	inventory[item_id]["count"] -= count
	if inventory[item_id]["count"] <= 0:
		inventory.erase(item_id)
	return true

## Use a consumable item
func use_item(item_id: String) -> bool:
	if not inventory.has(item_id):
		return false
	
	var item_data = inventory[item_id]["data"]
	if item_data["type"] != "consumable":
		return false
	
	match item_data.get("use_function", ""):
		"apply_nicotine_taurine":
			ATF_Balance.apply_nicotine_taurine()
		"apply_technetium_pack":
			ATF_Balance.apply_technetium_pack()
		"apply_technetium_pack_improved":
			ATF_Balance.personal_radiation += 0.01
			ATF_Balance.add_effect("technetium_improved", 10.0, {
				"hp_regen_bonus": 25.0,
				"radiation_accumulation": 0.001
			})
		"apply_oxygen_canister":
			ATF_Balance.restore_oxygen(ATF_Balance.oxygen_max * 0.5)
	
	remove_item(item_id, 1)
	item_consumed.emit(item_id)
	radiation_level_changed.emit(ATF_Balance.personal_radiation)
	return true

## Purchase item from NPC/shop
func purchase_item(item_id: String) -> bool:
	if not ITEMS.has(item_id):
		purchase_failed.emit(item_id, "item_not_found")
		return false
	
	var cost = ITEMS[item_id]["cost_corals"]
	if not remove_corals(cost):
		purchase_failed.emit(item_id, "insufficient_corals")
		return false
	
	if add_item(item_id):
		purchase_completed.emit(item_id, cost)
		return true
	
	# Refund if inventory full
	add_corals(cost)
	purchase_failed.emit(item_id, "inventory_full")
	return false

## Get inventory as list
func get_inventory_list() -> Array:
	var result: Array = []
	for item_id in inventory:
		result.append({
			"id": item_id,
			"count": inventory[item_id]["count"],
			"data": inventory[item_id]["data"]
		})
	return result

## Check if player has item
func has_item(item_id: String, min_count: int = 1) -> bool:
	return inventory.has(item_id) and inventory[item_id]["count"] >= min_count

## Get carrying capacity (affected by biomech archetype)
func get_carry_capacity() -> int:
	var base = inventory_max_slots
	if GameState.player_archetype == "biomech_active":
		base += 10  # Σ archetype bonus: can carry up to 30kg
	return base
