class_name TestPlayerState
extends TestCase

## Unit tests for PlayerState — inventory, gold, energy, hotbar, serialization.
## Fully isolated: no autoloads, no scene tree, no file I/O.

func test_name_id() -> String:
	return "UNIT.PlayerState"

func run_all() -> void:
	test_name = test_name_id()
	_test_item_add()
	_test_item_remove()
	_test_item_stack()
	_test_insufficient_quantity()
	_test_invalid_item()
	_test_gold_add()
	_test_gold_spend()
	_test_gold_insufficient()
	_test_energy_use()
	_test_energy_restore()
	_test_hotbar_select()
	_test_hotbar_cycle()
	_test_hotbar_set_slot()
	_test_world_state()
	_test_serialization_roundtrip()
	_test_legacy_grid_migration()
	_test_world_space_position()
	_test_personal_quest_state()
	_test_reward_duplicate_protection()
	_test_friendship()

# --- Inventory ---

func _test_item_add() -> void:
	begin_test("item_add")
	var ps = PlayerStateFixture.create_default()
	ps.add_item("wood", 5)
	assert_eq(ps.get_item_count("wood"), 5, "add 5 wood")
	ps.add_item("wood", 3)
	assert_eq(ps.get_item_count("wood"), 8, "stack to 8 wood")

func _test_item_remove() -> void:
	begin_test("item_remove")
	var ps = PlayerStateFixture.create_with_items({"stone": 10})
	var ok = ps.remove_item("stone", 4)
	assert_true(ok, "remove returns true")
	assert_eq(ps.get_item_count("stone"), 6, "6 stone remain")

func _test_item_stack() -> void:
	begin_test("item_stack")
	var ps = PlayerStateFixture.create_default()
	ps.add_item("wood", 1)
	ps.add_item("wood", 1)
	ps.add_item("wood", 1)
	assert_eq(ps.get_item_count("wood"), 3, "stack to 3")

func _test_insufficient_quantity() -> void:
	begin_test("insufficient_quantity")
	var ps = PlayerStateFixture.create_with_items({"wood": 2})
	var ok = ps.remove_item("wood", 5)
	assert_false(ok, "cannot remove more than owned")
	assert_eq(ps.get_item_count("wood"), 2, "quantity unchanged after failed remove")

func _test_invalid_item() -> void:
	begin_test("invalid_item")
	var ps = PlayerStateFixture.create_default()
	ps.add_item("", 5) # empty id — should be silently ignored
	assert_false(ps.inventory.has(""), "empty item id not added")
	ps.add_item("wood", 0) # zero quantity — silently ignored
	assert_false(ps.inventory.has("wood"), "zero quantity not added")

# --- Economy ---

func _test_gold_add() -> void:
	begin_test("gold_add")
	var ps = PlayerStateFixture.create_default()
	ps.add_gold(50)
	assert_eq(ps.gold, 150, "gold increased to 150")

func _test_gold_spend() -> void:
	begin_test("gold_spend")
	var ps = PlayerStateFixture.create_default()
	var ok = ps.spend_gold(60)
	assert_true(ok, "spend returns true")
	assert_eq(ps.gold, 40, "40 gold remain")

func _test_gold_insufficient() -> void:
	begin_test("gold_insufficient")
	var ps = PlayerStateFixture.create_default()
	var ok = ps.spend_gold(200)
	assert_false(ok, "cannot spend more than owned")
	assert_eq(ps.gold, 100, "gold unchanged")

# --- Energy ---

func _test_energy_use() -> void:
	begin_test("energy_use")
	var ps = PlayerStateFixture.create_default()
	var ok = ps.use_energy(20.0)
	assert_true(ok, "use_energy returns true")
	assert_approx_eq(ps.energy, 80.0, 0.01, "80 energy remain")

func _test_energy_restore() -> void:
	begin_test("energy_restore")
	var ps = PlayerStateFixture.create_default()
	ps.energy = 50.0
	ps.restore_energy(30.0)
	assert_approx_eq(ps.energy, 80.0, 0.01, "energy restored to 80")
	ps.restore_energy(999.0)
	assert_approx_eq(ps.energy, ps.max_energy, 0.01, "energy capped at max")

# --- Hotbar ---

func _test_hotbar_select() -> void:
	begin_test("hotbar_select")
	var ps = PlayerStateFixture.create_default()
	ps.select_hotbar_slot(2)
	assert_eq(ps.selected_hotbar_slot, 2, "slot 2 selected")
	assert_eq(ps.selected_item_id, ps.hotbar_slots[2], "selected_item matches slot")

func _test_hotbar_cycle() -> void:
	begin_test("hotbar_cycle")
	var ps = PlayerStateFixture.create_default()
	ps.selected_hotbar_slot = 9
	ps.cycle_hotbar_slot(1)
	assert_eq(ps.selected_hotbar_slot, 0, "wrap around from 9 to 0")
	ps.cycle_hotbar_slot(-1)
	assert_eq(ps.selected_hotbar_slot, 9, "wrap back from 0 to 9")

func _test_hotbar_set_slot() -> void:
	begin_test("hotbar_set_slot")
	var ps = PlayerStateFixture.create_default()
	ps.set_hotbar_slot(5, "stone")
	assert_eq(ps.get_hotbar_slot(5), "stone", "slot 5 is stone")
	ps.set_hotbar_slot(-1, "stone") # out of bounds — should be silently ignored
	ps.set_hotbar_slot(10, "stone") # out of bounds
	assert_eq(ps.get_hotbar_slot(-1), "", "negative index returns empty")

# --- World State ---

func _test_world_state() -> void:
	begin_test("world_state")
	var ps = PlayerStateFixture.create_default()
	assert_eq(ps.current_world, "farm", "starts in farm")
	ps.current_world = "town"
	assert_eq(ps.current_world, "town", "world updated to town")

func _test_world_space_position() -> void:
	begin_test("world_space_position")
	var ps = PlayerStateFixture.create_default()
	# Position must be a continuous Vector2, not grid-snapped
	ps.position = Vector2(264.7, 193.2)
	assert_approx_eq(ps.position.x, 264.7, 0.01, "x is float")
	assert_approx_eq(ps.position.y, 193.2, 0.01, "y is float")
	# Must NOT be a multiple of 16 (would indicate grid snap)
	assert_ne(int(ps.position.x) % 16, 0, "position is not grid-snapped")

# --- Serialization ---

func _test_serialization_roundtrip() -> void:
	begin_test("serialization_roundtrip")
	var ps = PlayerStateFixture.create_rich()
	ps.gold = 500
	ps.energy = 75.0
	ps.current_world = "town"
	ps.position = Vector2(123.4, 56.7)
	ps.selected_item_id = "hoe_basic"
	
	var data = ps.to_dict()
	var restored = PlayerState.from_dict(data)
	
	assert_eq(restored.gold, 500, "gold preserved")
	assert_approx_eq(restored.energy, 75.0, 0.01, "energy preserved")
	assert_eq(restored.current_world, "town", "current_world preserved")
	assert_approx_eq(restored.position.x, 123.4, 0.01, "position.x preserved")
	assert_approx_eq(restored.position.y, 56.7, 0.01, "position.y preserved")
	assert_eq(restored.selected_item_id, "hoe_basic", "selected_item preserved")
	
	# Verify no localised text in save blob
	var json_str = JSON.stringify(data)
	assert_false(json_str.contains("plant."), "no localisation key in save")
	assert_false(json_str.contains("tool.quality"), "no quality key in save")
	assert_eq(data.get("position_space", ""), "world", "position_space is 'world'")

func _test_legacy_grid_migration() -> void:
	begin_test("legacy_grid_migration")
	# Simulate old grid-based save
	var legacy_data = {
		"player_id": "player_001",
		"display_name": "Botanist",
		"current_world": "farm",
		"position": [16, 12], # grid coords
		# position_space missing = defaults to "grid"
		"gold": 100,
		"energy": 100.0,
		"max_energy": 100.0
	}
	var restored = PlayerState.from_dict(legacy_data)
	# Grid (16, 12) → world-space pixel (16*16+8, 12*16+8) = (264, 200)
	assert_approx_eq(restored.position.x, 264.0, 0.01, "legacy x migrated to world space")
	assert_approx_eq(restored.position.y, 200.0, 0.01, "legacy y migrated to world space")

# --- Quests & Rewards ---

func _test_personal_quest_state() -> void:
	begin_test("personal_quest_state")
	var ps = PlayerStateFixture.create_default()
	ps.personal_quests["q_tutorial"] = { "status": "active", "progress": [2, 5] }
	assert_has(ps.personal_quests, "q_tutorial", "quest recorded")
	assert_eq(ps.personal_quests["q_tutorial"]["status"], "active", "status active")

func _test_reward_duplicate_protection() -> void:
	begin_test("reward_duplicate_protection")
	var ps = PlayerStateFixture.create_default()
	assert_false(ps.has_claimed_reward("reward_001"), "unclaimed initially")
	ps.mark_reward_claimed("reward_001")
	assert_true(ps.has_claimed_reward("reward_001"), "now claimed")
	ps.mark_reward_claimed("reward_001")
	assert_true(ps.has_claimed_reward("reward_001"), "still claimed (no error on double)")

func _test_friendship() -> void:
	begin_test("friendship")
	var ps = PlayerStateFixture.create_default()
	assert_eq(ps.get_friendship("rowan"), 0, "starts at 0")
	ps.add_friendship("rowan", 10)
	assert_eq(ps.get_friendship("rowan"), 10, "friendship 10")
	ps.add_friendship("rowan", -5)
	assert_eq(ps.get_friendship("rowan"), 5, "friendship -5 = 5")
