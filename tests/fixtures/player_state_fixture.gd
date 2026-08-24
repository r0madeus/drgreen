class_name PlayerStateFixture
extends RefCounted

## Fixture factory for isolated PlayerState instances used in tests.
## Never touches live autoloads or the scene tree.

static func create_default() -> PlayerState:
	var ps = PlayerState.new("test_player", "TestBotanist")
	ps.gold = 100
	ps.energy = 100.0
	ps.max_energy = 100.0
	ps.current_world = "farm"
	ps.position = Vector2(256.0, 192.0)
	ps.inventory.clear()
	ps.hotbar_slots = ["hoe_basic", "watering_can_basic", "axe_basic", "pickaxe_basic", "seed_red_flower", "seed_blue_flower", "seed_yellow_herb", "", "", ""]
	ps.selected_hotbar_slot = 0
	ps.selected_item_id = "hoe_basic"
	return ps

static func create_with_items(items: Dictionary) -> PlayerState:
	var ps = create_default()
	for item_id in items:
		ps.inventory[item_id] = items[item_id]
	return ps

static func create_rich() -> PlayerState:
	var ps = create_default()
	ps.gold = 9999
	ps.energy = 100.0
	ps.inventory = {
		"hoe_basic": 1, "watering_can_basic": 1, "axe_basic": 1, "pickaxe_basic": 1,
		"seed_red_flower": 10, "red_flower": 5, "wood": 20, "stone": 15
	}
	return ps
