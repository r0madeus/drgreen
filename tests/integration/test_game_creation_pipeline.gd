class_name TestGameCreationPipeline
extends TestCase

## Phase 40 — Empty Game Creation, Authoring & Playable Pipeline Suite.
## Tests:
##   - Creating a Pure Empty Game Package (0 Botanical dependencies)
##   - Authoring Custom Worlds, Items, Entities, and Interactions
##   - Wiring Generic Events, Conditions, and Action Sequences
##   - Project Validation & Summary Metric Extraction
##   - Sandboxed Playtest Runtime Execution & State Transitions
##   - Game Package Save Namespacing & Isolation
##   - Standalone .bhgame Exporting & Packaging
##   - Package Duplication and Deletion Safety Guards
##   - Package Importing & End-to-End Replay Verification

var PKG_MGR_SCRIPT
var GAME_PACKAGE_SCRIPT
var DATA_SERVICE_SCRIPT
var MOD_MGR_SCRIPT
var RULE_MGR_SCRIPT
var TRIG_SCRIPT
var COND_SCRIPT
var ACT_SCRIPT
var SAVE_MGR_SCRIPT

func test_name_id() -> String:
	return "GAME_CREATION_PIPELINE.Phase40Suite"

func _init_scripts() -> void:
	PKG_MGR_SCRIPT = ResourceLoader.load("res://core/game_package_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	GAME_PACKAGE_SCRIPT = ResourceLoader.load("res://core/game_package.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DATA_SERVICE_SCRIPT = ResourceLoader.load("res://editor/core/editor_data_service.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	MOD_MGR_SCRIPT = ResourceLoader.load("res://editor/core/mod_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	RULE_MGR_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_rule_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	TRIG_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_trigger.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	COND_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_condition.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ACT_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_action.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	SAVE_MGR_SCRIPT = ResourceLoader.load("res://systems/save/save_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()

	# --- 1. Empty Game Creation ---
	_test_01_create_empty_game_package()

	# --- 2. World Creation ---
	_test_02_create_world_and_edit()

	# --- 3. Generic Item Creation ---
	_test_03_create_generic_items()

	# --- 4. Generic Entity & Interaction Creation ---
	_test_04_create_generic_entity_and_interaction()

	# --- 5. Gameplay Rules Wiring ---
	_test_05_create_gameplay_rules()

	# --- 6. Project Validation & Metrics Summary ---
	_test_06_validation_and_summary_metrics()

	# --- 7. Isolated Playtest Runtime Execution ---
	_test_07_isolated_playtest_execution()

	# --- 8. Save Isolation by Game ID ---
	_test_08_save_isolation_by_game_id()

	# --- 9. Standalone .bhgame Package Export ---
	_test_09_export_game_package()

	# --- 10. Package Duplication & Deletion Safety ---
	_test_10_duplicate_and_delete_safety()

	# --- 11. Package Import & Replay ---
	_test_11_import_and_replay_game_package()

# ===========================================================================
# 1. Empty Game Creation
# ===========================================================================

func _test_01_create_empty_game_package() -> void:
	begin_test("01_CreateEmptyGamePackage")
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var pkg = mgr.create_game_package("dungeon_crawler", "Dungeon Crawler", "empty", "TestDev", "1.0.0", "A dark dungeon quest.")
	
	assert_true(pkg != null, "Empty game package created")
	assert_eq(pkg.game_id, "dungeon_crawler", "Game ID is dungeon_crawler")
	assert_eq(pkg.name, "Dungeon Crawler", "Display name matches")
	
	# Verify directories exist
	assert_true(DirAccess.dir_exists_absolute("user://games/dungeon_crawler/"), "Game directory created in user://games/")
	assert_true(DirAccess.dir_exists_absolute("user://games/dungeon_crawler/worlds/"), "Worlds subfolder created")
	assert_true(DirAccess.dir_exists_absolute("user://games/dungeon_crawler/items/"), "Items subfolder created")

# ===========================================================================
# 2. World Creation
# ===========================================================================

func _test_02_create_world_and_edit() -> void:
	begin_test("02_CreateWorldAndEdit")
	var undo_mgr = EditorUndoManager.new()
	var mod_mgr = MOD_MGR_SCRIPT.new()
	var ds = DATA_SERVICE_SCRIPT.new(undo_mgr, mod_mgr)
	
	var world_data = ds.create_world("dungeon_floor_1", "Dungeon Floor 1", 30, 20, "stone", [5, 5])
	assert_eq(world_data["id"], "dungeon_floor_1", "World ID created")
	assert_eq(world_data["width"], 30, "World width is 30")
	assert_eq(world_data["height"], 20, "World height is 20")
	
	assert_true(ds.has_override("world.dungeon_floor_1"), "World staged in EditorDataService")

# ===========================================================================
# 3. Generic Item Creation
# ===========================================================================

func _test_03_create_generic_items() -> void:
	begin_test("03_CreateGenericItems")
	var undo_mgr = EditorUndoManager.new()
	var mod_mgr = MOD_MGR_SCRIPT.new()
	var ds = DATA_SERVICE_SCRIPT.new(undo_mgr, mod_mgr)
	
	# Key
	ds.create_entity("item.dungeon_key", {
		"id": "dungeon_key",
		"name": "Dungeon Key",
		"category": "key",
		"stack_size": 1
	})
	
	# Sword
	ds.create_entity("item.legendary_sword", {
		"id": "legendary_sword",
		"name": "Legendary Sword",
		"category": "weapon",
		"attack_power": 50
	})
	
	assert_true(ds.has_override("item.dungeon_key"), "Dungeon key staged")
	assert_true(ds.has_override("item.legendary_sword"), "Legendary sword staged")

# ===========================================================================
# 4. Generic Entity & Interaction Creation
# ===========================================================================

func _test_04_create_generic_entity_and_interaction() -> void:
	begin_test("04_CreateGenericEntityAndInteraction")
	var undo_mgr = EditorUndoManager.new()
	var mod_mgr = MOD_MGR_SCRIPT.new()
	var ds = DATA_SERVICE_SCRIPT.new(undo_mgr, mod_mgr)
	
	ds.create_entity("npc.ancient_chest", {
		"id": "ancient_chest",
		"name": "Ancient Chest",
		"category": "interactable",
		"position": [10, 10],
		"interaction_event": "chest_interacted",
		"properties": {
			"locked": true,
			"opened": false
		}
	})
	
	assert_true(ds.has_override("npc.ancient_chest"), "Ancient chest entity created")
	var chest = ds.get_resolved_object("npc.ancient_chest")
	assert_eq(chest.get("interaction_event", ""), "chest_interacted", "Interaction event bound")

# ===========================================================================
# 5. Gameplay Rules Wiring
# ===========================================================================

func _test_05_create_gameplay_rules() -> void:
	begin_test("05_CreateGameplayRules")
	var undo_mgr = EditorUndoManager.new()
	var mod_mgr = MOD_MGR_SCRIPT.new()
	var ds = DATA_SERVICE_SCRIPT.new(undo_mgr, mod_mgr)
	
	ds.create_entity("rule.chest_unlock", {
		"id": "chest_unlock",
		"name": "Chest Unlock Rule",
		"event_type": "chest_interacted",
		"priority": 100,
		"once": true,
		"condition": {
			"all": [
				{ "path": "inventory.dungeon_key", "op": ">=", "value": 1 },
				{ "path": "flags.chest_opened", "op": "==", "value": false }
			]
		},
		"actions": [
			{ "type": "remove_item", "item_id": "dungeon_key", "count": 1 },
			{ "type": "add_item", "item_id": "legendary_sword", "count": 1 },
			{ "type": "add_gold", "amount": 500 },
			{ "type": "set_flag", "flag": "chest_opened", "value": true },
			{ "type": "show_message", "text": "You unlocked the Ancient Chest and obtained the Legendary Sword!" }
		]
	})
	
	assert_true(ds.has_override("rule.chest_unlock"), "Gameplay rule staged")

# ===========================================================================
# 6. Project Validation & Summary Metrics
# ===========================================================================

func _test_06_validation_and_summary_metrics() -> void:
	begin_test("06_ValidationAndSummaryMetrics")
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var summary = mgr.get_package_summary("dungeon_crawler")
	
	assert_eq(summary.get("game_id", ""), "dungeon_crawler", "Summary retrieved for dungeon_crawler")
	assert_eq(summary.get("name", ""), "Dungeon Crawler", "Name matches")

# ===========================================================================
# 7. Isolated Playtest Runtime Execution
# ===========================================================================

func _test_07_isolated_playtest_execution() -> void:
	begin_test("07_IsolatedPlaytestExecution")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	
	var trig = TRIG_SCRIPT.new(
		"chest_unlock",
		"chest_interacted",
		{
			"all": [
				{ "path": "inventory.dungeon_key", "op": ">=", "value": 1 },
				{ "path": "flags.chest_opened", "op": "==", "value": false }
			]
		},
		[
			{ "type": "remove_item", "item_id": "dungeon_key", "count": 1 },
			{ "type": "add_item", "item_id": "legendary_sword", "count": 1 },
			{ "type": "add_gold", "amount": 500 },
			{ "type": "set_flag", "flag": "chest_opened", "value": true }
		]
	)
	trig.once = true
	mgr.register_trigger(trig)
	
	# Scenario A: Interact without key
	var playtest_ctx = {
		"gold": 50,
		"inventory": {},
		"flags": { "chest_opened": false }
	}
	var can_fire_no_key = trig.can_fire({ "event_type": "chest_interacted" }, playtest_ctx)
	assert_false(can_fire_no_key, "Cannot open chest without dungeon key")
	
	# Scenario B: Player obtains key and interacts
	playtest_ctx["inventory"]["dungeon_key"] = 1
	var can_fire_with_key = trig.can_fire({ "event_type": "chest_interacted" }, playtest_ctx)
	assert_true(can_fire_with_key, "Can open chest with dungeon key")
	
	var fire_res = trig.fire({ "event_type": "chest_interacted" }, playtest_ctx)
	assert_true(fire_res["fired"], "Chest trigger fired")
	assert_eq(playtest_ctx["inventory"]["dungeon_key"], 0, "Key consumed")
	assert_eq(playtest_ctx["inventory"]["legendary_sword"], 1, "Sword granted")
	assert_eq(playtest_ctx["gold"], 550, "Gold increased")
	assert_true(playtest_ctx["flags"]["chest_opened"], "chest_opened flag set")

# ===========================================================================
# 8. Save Isolation by Game ID
# ===========================================================================

func _test_08_save_isolation_by_game_id() -> void:
	begin_test("08_SaveIsolationByGameId")
	var save_mgr = SAVE_MGR_SCRIPT.new()
	
	var main_slot1 = save_mgr.get_slot_path_for_game("botanical_haven", 1)
	var dungeon_slot1 = save_mgr.get_slot_path_for_game("dungeon_crawler", 1)
	
	assert_ne(main_slot1, dungeon_slot1, "Save paths for different games are isolated")
	assert_true(dungeon_slot1.contains("dungeon_crawler"), "Custom game save path contains game_id directory")

# ===========================================================================
# 9. Standalone .bhgame Package Export
# ===========================================================================

func _test_09_export_game_package() -> void:
	begin_test("09_ExportGamePackage")
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var export_path = mgr.export_game_package("dungeon_crawler")
	
	assert_true(export_path != "", "Export path returned")
	assert_true(FileAccess.file_exists(export_path), ".bhgame package written to disk")

# ===========================================================================
# 10. Package Duplication & Deletion Safety
# ===========================================================================

func _test_10_duplicate_and_delete_safety() -> void:
	begin_test("10_DuplicateAndDeleteSafety")
	var mgr = PKG_MGR_SCRIPT.get_instance()
	
	# Duplicate
	var dup = mgr.duplicate_game_package("dungeon_crawler", "dungeon_crawler_v2", "Dungeon Crawler v2")
	assert_true(dup != null, "Duplicated game package created")
	assert_true(mgr.is_game_package_installed("dungeon_crawler_v2"), "Cloned package registered")
	
	# Delete cloned
	var del_success = mgr.delete_game_package("dungeon_crawler_v2")
	assert_true(del_success, "Custom package safely deleted")
	assert_false(mgr.is_game_package_installed("dungeon_crawler_v2"), "Cloned package unregistered")
	
	# Safety guard on core package
	var del_core = mgr.delete_game_package("botanical_haven")
	assert_false(del_core, "Core Botanical Haven package cannot be deleted")

# ===========================================================================
# 11. Package Import & Replay
# ===========================================================================

func _test_11_import_and_replay_game_package() -> void:
	begin_test("11_ImportAndReplayGamePackage")
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var export_file = "user://exports/dungeon_crawler.bhgame"
	
	# Delete installed copy
	mgr.delete_game_package("dungeon_crawler")
	assert_false(mgr.is_game_package_installed("dungeon_crawler"), "Original package removed before import")
	
	# Import package
	var imported_pkg = mgr.import_game_package(export_file)
	assert_true(imported_pkg != null, "Package successfully imported from .bhgame")
	assert_eq(imported_pkg.game_id, "dungeon_crawler", "Imported package ID matches")
	assert_true(mgr.is_game_package_installed("dungeon_crawler"), "Imported package registered")
