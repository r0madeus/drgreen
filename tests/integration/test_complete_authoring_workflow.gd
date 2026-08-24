class_name TestCompleteAuthoringWorkflow
extends TestCase

## Phase 36 — Complete In-Game Content Authoring & Mod Creation Workflow Suite.
## Tests end-to-end authoring from scratch using only In-Game Editor components:
##   - Mod Workspace Creation
##   - Asset Import & Custom Texture Resolution
##   - Item, Crop, Tool Authoring
##   - NPC Authoring & Schedule / Social configuration
##   - World Creation & Tile / Layer setup
##   - NPC World Placement
##   - Dialogue Tree Authoring & Simulation
##   - Quest Authoring & Objective / Reward linking
##   - Project Outline / Content Tree hierarchy
##   - Cross-Editor Navigation
##   - Global Validation & Broken Reference Detection
##   - Undo / Redo of Entity Authoring
##   - Atomic Save & Cold Restart Reload Persistence
##   - Gameplay Managers Synchronization & Playtest Simulation
##   - .bhmod Package Export
##   - Clean Environment Reset & Base Game Isolation
##   - .bhmod Clean Import & Activation Lifecycle

var NPC_PANEL_SCRIPT
var WORLD_PANEL_SCRIPT
var DIALOGUE_PANEL_SCRIPT
var QUEST_PANEL_SCRIPT
var ITEM_PANEL_SCRIPT
var ASSET_PANEL_SCRIPT
var MOD_PANEL_SCRIPT
var SHELL_SCRIPT
var DATA_SERVICE_SCRIPT

func test_name_id() -> String:
	return "COMPLETE_AUTHORING_WORKFLOW.Phase36Suite"

func _init_scripts() -> void:
	NPC_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/npc_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	WORLD_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/world_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DIALOGUE_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/dialogue_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	QUEST_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/quest_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ITEM_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/item_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ASSET_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/asset_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	MOD_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/mod_manager_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	SHELL_SCRIPT = ResourceLoader.load("res://editor/ui/editor_shell.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DATA_SERVICE_SCRIPT = ResourceLoader.load("res://editor/core/editor_data_service.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func _clean_state(service: EditorService) -> void:
	service.reset_all()
	service.save()

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()
	
	var service := EditorService.get_instance()
	if not service.data_service.has_method("create_entity"):
		service.data_service = DATA_SERVICE_SCRIPT.new(service.undo_manager, service.mod_manager)
		
	_clean_state(service)

	# --- 1. Mod Creation Workspace ---
	_test_01_create_mod_workspace()

	# --- 2. Asset Import & Registration ---
	_test_02_author_assets_and_import()

	# --- 3. Item, Crop, Tool Authoring ---
	_test_03_author_item_crop_and_tool()

	# --- 4. NPC Creation & Configuration ---
	_test_04_author_npc_with_schedule_and_social()

	# --- 5. World Creation & NPC Placement ---
	_test_05_author_world_and_place_npc()

	# --- 6. Dialogue Tree Creation ---
	_test_06_author_dialogue_tree_and_choices()

	# --- 7. Quest Creation & Linking ---
	_test_07_author_quest_with_objectives_and_rewards()

	# --- 8. Project Outline & Hierarchy ---
	_test_08_project_outline_tree_structure()

	# --- 9. Cross-Editor Reference Navigation ---
	_test_09_cross_editor_navigation_links()

	# --- 10. Global Validation Engine ---
	_test_10_global_validation_and_broken_references()

	# --- 11. Undo / Redo Authoring Actions ---
	_test_11_undo_redo_authoring_actions()

	# --- 12. Save & Reload Persistence ---
	_test_12_save_and_reload_persistence()

	# --- 13. Playtest Simulation Workflow ---
	_test_13_playtest_gameplay_simulation_loop()

	# --- 14. .bhmod Package Export ---
	_test_14_export_bhmod_package()

	# --- 15. Clean Reset & Base Game Isolation ---
	_test_15_clean_reset_and_base_game_isolation()

	# --- 16. .bhmod Import & Activation ---
	_test_16_bhmod_import_and_activation_lifecycle()

# ===========================================================================
# 1. Mod Creation Workspace
# ===========================================================================

func _test_01_create_mod_workspace() -> void:
	begin_test("01_CreateModWorkspace")
	var service := EditorService.get_instance()
	_clean_state(service)
	
	var mod_panel = MOD_PANEL_SCRIPT.new()
	mod_panel.setup(service)
	
	var mod = mod_panel.create_mod_workspace(
		"moonlit_garden",
		"Moonlit Garden Mod",
		"Botanist Dev",
		"1.0.0",
		"A magical new botanical expansion."
	)
	
	assert_true(mod != null, "Mod instance created in workspace")
	assert_eq(mod.id, "moonlit_garden", "Mod ID matches normalized slug")
	assert_eq(mod.name, "Moonlit Garden Mod", "Display name stored")
	assert_eq(mod.author, "Botanist Dev", "Author stored")
	assert_true(service.mod_manager.get_mod("moonlit_garden") != null, "Mod registered in ModManager")
	
	mod_panel.free()

# ===========================================================================
# 2. Asset Import & Registration
# ===========================================================================

func _test_02_author_assets_and_import() -> void:
	begin_test("02_AuthorAssetsAndImport")
	var service := EditorService.get_instance()
	var asset_panel = ASSET_PANEL_SCRIPT.new()
	asset_panel.setup(service)
	
	# Create a dummy image to simulate user artwork on disk
	var dummy_path = "user://temp_moon_flower.png"
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.4, 1.0))
	img.save_png(dummy_path)
	
	var dest_path = asset_panel.import_file(dummy_path, "item.moon_flower_icon")
	assert_true(dest_path != "", "Asset imported to user layer")
	assert_true(FileAccess.file_exists(dest_path), "File physically created on disk")
	
	var tex = AssetRegistry.get_asset_texture("item.moon_flower_icon")
	assert_true(tex != null and tex is Texture2D, "AssetRegistry resolves imported texture")
	
	asset_panel.free()

# ===========================================================================
# 3. Item, Crop, Tool Authoring
# ===========================================================================

func _test_03_author_item_crop_and_tool() -> void:
	begin_test("03_AuthorItemCropAndTool")
	var service := EditorService.get_instance()
	var item_panel = ITEM_PANEL_SCRIPT.new()
	item_panel.setup(service)
	
	# 1. Author Item
	var item_data = item_panel.create_item("item.moon_flower", "Moon Flower", "flower", 150, "item.moon_flower_icon")
	assert_eq(item_data["id"], "moon_flower", "Item ID stored")
	assert_eq(item_data["sell_price"], 150.0, "Sell price stored")
	assert_true(service.data_service.has_override("item.moon_flower"), "item.moon_flower staged in DataService")
	
	# 2. Author Crop
	var crop_data = item_panel.create_crop("crop.moon_flower_seed", "Moon Flower", 3, "item.moon_flower")
	assert_eq(crop_data["growth_days"], 3, "Growth duration stored")
	assert_eq(crop_data["harvest_item"], "item.moon_flower", "Harvest item link stored")
	assert_true(service.data_service.has_override("crop.moon_flower_seed"), "crop.moon_flower_seed staged")
	assert_true(service.data_service.has_override("item.seed_moon_flower_seed"), "Seed item automatically generated")
	
	# 3. Author Tool
	var tool_data = item_panel.create_tool("tool.crystal_hoe", "Crystal Hoe", 2, 1)
	assert_eq(tool_data["power"], 2, "Tool power stored")
	assert_true(service.data_service.has_override("tool.crystal_hoe"), "tool.crystal_hoe staged")
	
	item_panel.free()

# ===========================================================================
# 4. NPC Creation & Configuration
# ===========================================================================

func _test_04_author_npc_with_schedule_and_social() -> void:
	begin_test("04_AuthorNpcWithScheduleAndSocial")
	var service := EditorService.get_instance()
	var npc_panel = NPC_PANEL_SCRIPT.new()
	npc_panel.setup(service)
	
	var npc_id = npc_panel.create_npc("npc.elara", "Elara", "moonlit_garden", "botanist", {
		"personality": "mysterious",
		"dialogue_id": "elara"
	})
	
	assert_eq(npc_id, "elara", "NPC ID cleaned to elara")
	assert_true(service.data_service.has_override("npc.elara"), "npc.elara staged")
	assert_true(service.data_service.has_override("schedule.elara"), "schedule.elara automatically staged")
	assert_true(service.data_service.has_override("social.elara"), "social.elara automatically staged")
	
	var resolved_npc = service.data_service.get_resolved_object("npc.elara")
	assert_eq(resolved_npc.get("display_name", ""), "Elara", "Resolved NPC display name matches")
	assert_eq(resolved_npc.get("world", ""), "moonlit_garden", "Default world assigned")
	
	npc_panel.free()

# ===========================================================================
# 5. World Creation & NPC Placement
# ===========================================================================

func _test_05_author_world_and_place_npc() -> void:
	begin_test("05_AuthorWorldAndPlaceNpc")
	var service := EditorService.get_instance()
	var world_panel = WORLD_PANEL_SCRIPT.new()
	world_panel.setup(service)
	
	var world_dict = world_panel.create_new_world("world.moonlit_garden", "Moonlit Garden", 32, 24, "grass")
	assert_eq(world_dict.get("id", ""), "moonlit_garden", "World ID stored")
	assert_eq(world_dict.get("width", 0), 32, "World width 32")
	assert_eq(world_dict.get("height", 0), 24, "World height 24")
	assert_true(service.data_service.has_override("world.moonlit_garden"), "world.moonlit_garden staged in DataService")
	
	# Place NPC in World
	world_panel.place_npc("npc.elara", Vector2i(16, 10), "down")
	var res_world = service.data_service.get_resolved_object("world.moonlit_garden")
	var spawns: Array = res_world.get("npc_spawns", [])
	assert_true(spawns.size() >= 1, "NPC spawn entry created in world")
	assert_eq(spawns[0].get("npc_id", ""), "elara", "Placed NPC ID matches elara")
	
	world_panel.free()

# ===========================================================================
# 6. Dialogue Tree Creation
# ===========================================================================

func _test_06_author_dialogue_tree_and_choices() -> void:
	begin_test("06_AuthorDialogueTreeAndChoices")
	var service := EditorService.get_instance()
	var diag_panel = DIALOGUE_PANEL_SCRIPT.new()
	diag_panel.setup(service)
	
	var diag_data = diag_panel.create_dialogue(
		"dialogue.elara",
		"elara",
		"start",
		["Welcome to the Moonlit Garden! Please grow a Moon Flower for my research."]
	)
	
	assert_eq(diag_data.get("id", ""), "elara", "Dialogue ID stored")
	assert_true(service.data_service.has_override("dialogue.elara"), "dialogue.elara staged in DataService")
	
	var nodes: Dictionary = diag_data.get("nodes", {})
	assert_true(nodes.has("start"), "Start node present in dialogue tree")
	
	diag_panel.free()

# ===========================================================================
# 7. Quest Creation & Linking
# ===========================================================================

func _test_07_author_quest_with_objectives_and_rewards() -> void:
	begin_test("07_AuthorQuestWithObjectivesAndRewards")
	var service := EditorService.get_instance()
	var quest_panel = QUEST_PANEL_SCRIPT.new()
	quest_panel.setup(service)
	
	var quest_dict = quest_panel.create_quest(
		"quest.the_moonlit_garden",
		"The Moonlit Garden",
		"Elara",
		[{ "type": "harvest", "target": "item.moon_flower", "amount": 1.0, "current": 0.0, "description": "Harvest 1 Moon Flower" }],
		{ "gold": 200.0, "items": { "item.moon_flower": 1 } }
	)
	
	assert_eq(quest_dict.get("id", ""), "the_moonlit_garden", "Quest ID stored")
	assert_eq(quest_dict.get("giver", ""), "Elara", "Giver NPC linked")
	assert_true(service.data_service.has_override("quest.the_moonlit_garden"), "quest.the_moonlit_garden staged in DataService")
	
	quest_panel.free()

# ===========================================================================
# 8. Project Outline & Hierarchy
# ===========================================================================

func _test_08_project_outline_tree_structure() -> void:
	begin_test("08_ProjectOutlineTreeStructure")
	var service := EditorService.get_instance()
	var shell = SHELL_SCRIPT.new()
	
	var outline = shell.get_project_outline()
	assert_true(outline.has("worlds"), "Outline contains worlds")
	assert_true(outline.has("npcs"), "Outline contains npcs")
	assert_true(outline.has("items"), "Outline contains items")
	assert_true(outline.has("crops"), "Outline contains crops")
	assert_true(outline.has("quests"), "Outline contains quests")
	assert_true(outline.has("dialogues"), "Outline contains dialogues")
	
	var worlds: Array = outline["worlds"]
	var npcs: Array = outline["npcs"]
	var quests: Array = outline["quests"]
	
	assert_true(worlds.has("world.moonlit_garden"), "Authored world in project outline")
	assert_true(npcs.has("npc.elara"), "Authored NPC in project outline")
	assert_true(quests.has("quest.the_moonlit_garden"), "Authored quest in project outline")
	
	shell.free()

# ===========================================================================
# 9. Cross-Editor Reference Navigation
# ===========================================================================

func _test_09_cross_editor_navigation_links() -> void:
	begin_test("09_CrossEditorNavigationLinks")
	var service := EditorService.get_instance()
	
	# NPC Navigation
	service.navigate_to("npc", "elara")
	assert_eq(service.session.active_module, "npc", "Navigated to NPC module")
	assert_eq(service.session.active_npc, "elara", "Target NPC focused")
	
	# Dialogue Navigation
	service.navigate_to("dialogue", "elara")
	assert_eq(service.session.active_module, "dialogue", "Navigated to dialogue module")
	assert_eq(service.session.active_dialogue, "elara", "Target dialogue focused")
	
	# Quest Navigation
	service.navigate_to("quest", "the_moonlit_garden")
	assert_eq(service.session.active_module, "quest", "Navigated to quest module")
	assert_eq(service.session.active_quest, "the_moonlit_garden", "Target quest focused")
	
	# Item Navigation
	service.navigate_to("item", "moon_flower")
	assert_eq(service.session.active_module, "item", "Navigated to item module")
	
	# World Navigation
	service.navigate_to("world", "moonlit_garden")
	assert_eq(service.session.active_module, "world", "Navigated to world module")
	assert_eq(service.session.active_world, "moonlit_garden", "Target world focused")

# ===========================================================================
# 10. Global Validation Engine
# ===========================================================================

func _test_10_global_validation_and_broken_references() -> void:
	begin_test("10_GlobalValidationAndBrokenReferences")
	var service := EditorService.get_instance()
	var report = service.validate()
	assert_true(report is Dictionary, "Validation returns report dictionary")
	
	# Test injecting broken reference
	service.set_property("quest.the_moonlit_garden", "objectives", [
		{ "type": "harvest", "target": "item.NONEXISTENT_XYZ_ITEM", "amount": 1.0 }
	])
	var broken_report = service.validate()
	assert_true(broken_report.has("errors"), "Validator detects broken references")
	
	# Restore valid objective
	service.set_property("quest.the_moonlit_garden", "objectives", [
		{ "type": "harvest", "target": "item.moon_flower", "amount": 1.0 }
	])

# ===========================================================================
# 11. Undo / Redo Authoring Actions
# ===========================================================================

func _test_11_undo_redo_authoring_actions() -> void:
	begin_test("11_UndoRedoAuthoringActions")
	var service := EditorService.get_instance()
	var ds = service.data_service
	
	# Create temporary entity
	ds.create_entity("item.temp_gem", { "name": "Temp Gem", "sell_price": 50 })
	assert_true(ds.has_override("item.temp_gem"), "Temp entity exists before undo")
	
	# Undo creation
	service.undo()
	assert_false(ds.has_override("item.temp_gem"), "Undo successfully removed created entity")
	
	# Redo creation
	service.redo()
	assert_true(ds.has_override("item.temp_gem"), "Redo restored created entity")
	
	# Cleanup
	ds.delete_entity("item.temp_gem", false)

# ===========================================================================
# 12. Save & Reload Persistence
# ===========================================================================

func _test_12_save_and_reload_persistence() -> void:
	begin_test("12_SaveAndReloadPersistence")
	var service := EditorService.get_instance()
	var ok = service.save()
	assert_true(ok, "Authoring changes saved to disk")
	
	# Cold reload in fresh DataService instance
	var ds_reload = DATA_SERVICE_SCRIPT.new(service.undo_manager, service.mod_manager)
	var load_ok = ds_reload.load_saved_overrides()
	assert_true(load_ok, "Overrides reloaded from disk")
	
	assert_true(ds_reload.has_override("npc.elara"), "npc.elara persisted across reload")
	assert_true(ds_reload.has_override("world.moonlit_garden"), "world.moonlit_garden persisted across reload")
	assert_true(ds_reload.has_override("item.moon_flower"), "item.moon_flower persisted across reload")
	assert_true(ds_reload.has_override("crop.moon_flower_seed"), "crop.moon_flower_seed persisted across reload")
	assert_true(ds_reload.has_override("quest.the_moonlit_garden"), "quest.the_moonlit_garden persisted across reload")
	assert_true(ds_reload.has_override("dialogue.elara"), "dialogue.elara persisted across reload")

# ===========================================================================
# 13. Playtest Simulation Workflow
# ===========================================================================

func _test_13_playtest_gameplay_simulation_loop() -> void:
	begin_test("13_PlaytestGameplaySimulationLoop")
	var service := EditorService.get_instance()
	service.data_service.apply_to_gameplay_managers()
	
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if not root: return
	
	var npc_mgr = root.get_node_or_null("/root/NPCManager")
	var quest_mgr = root.get_node_or_null("/root/QuestManager")
	var diag_mgr = root.get_node_or_null("/root/DialogueManager")
	var plant_mgr = root.get_node_or_null("/root/PlantManager")
	
	if npc_mgr:
		assert_true(npc_mgr.npcs_catalog.has("elara"), "Elara available in NPCManager for Playtest")
	if quest_mgr:
		var has_q = false
		for q in quest_mgr.quests:
			if str(q.get("id", "")) == "the_moonlit_garden":
				has_q = true
				break
		assert_true(has_q, "Quest available in QuestManager for Playtest")
	if diag_mgr:
		assert_true(diag_mgr.dialogue_catalog.has("elara"), "Dialogue available in DialogueManager for Playtest")
	if plant_mgr:
		assert_true(plant_mgr.plants_database.has("moon_flower_seed"), "Plant available in PlantManager for Playtest")

# ===========================================================================
# 14. .bhmod Package Export
# ===========================================================================

func _test_14_export_bhmod_package() -> void:
	begin_test("14_ExportBhmodPackage")
	var service := EditorService.get_instance()
	var mm = service.mod_manager
	
	var mod = mm.create_mod("moonlit_garden", "Moonlit Garden Mod", "Botanist Dev", "1.0.0")
	mod.overrides = service.data_service._staged_overrides.duplicate(true)
	
	var res = mm.export_mod_package("moonlit_garden", "user://mods")
	assert_true(res.get("success", false) == true, "Mod packaged into .bhmod successfully")
	var pkg_path = str(res.get("path", "user://mods/moonlit_garden.bhmod"))
	assert_true(FileAccess.file_exists(pkg_path), ".bhmod file written to disk")

# ===========================================================================
# 15. Clean Reset & Base Game Isolation
# ===========================================================================

func _test_15_clean_reset_and_base_game_isolation() -> void:
	begin_test("15_CleanResetAndBaseGameIsolation")
	var service := EditorService.get_instance()
	_clean_state(service)
	
	assert_false(service.data_service.has_override("npc.elara"), "Mod NPC absent after clean reset")
	assert_false(service.data_service.has_override("world.moonlit_garden"), "Mod world absent after clean reset")
	assert_false(service.data_service.has_override("quest.the_moonlit_garden"), "Mod quest absent after clean reset")
	
	# Verify base game data is intact
	var base_rowan = service.data_service.get_resolved_object("npc.rowan")
	assert_true(base_rowan.size() > 0, "Base NPC Rowan preserved and unaffected")
	var base_farm = service.data_service.get_resolved_object("world.farm")
	assert_true(base_farm.size() > 0, "Base Farm World preserved and unaffected")

# ===========================================================================
# 16. .bhmod Import & Activation
# ===========================================================================

func _test_16_bhmod_import_and_activation_lifecycle() -> void:
	begin_test("16_BhmodImportAndActivationLifecycle")
	var mm_clean = ModManager.new()
	var pkg_path = "user://mods/moonlit_garden.bhmod"
	
	var res = mm_clean.import_mod(pkg_path)
	assert_true(res.get("success", false) == true, "Imported .bhmod in clean ModManager")
	var imported_mod = res.get("mod", null)
	assert_true(imported_mod != null, "Imported mod object is valid")
	assert_true(imported_mod.overrides.has("npc.elara"), "Imported mod contains npc.elara")
	assert_true(imported_mod.overrides.has("world.moonlit_garden"), "Imported mod contains world.moonlit_garden")
	assert_true(imported_mod.overrides.has("item.moon_flower"), "Imported mod contains item.moon_flower")
	assert_true(imported_mod.overrides.has("quest.the_moonlit_garden"), "Imported mod contains quest.the_moonlit_garden")
	
	# Test mod activation in DataService
	var ds_mod = DATA_SERVICE_SCRIPT.new(null, mm_clean)
	assert_true(ds_mod.get_all_stable_ids().has("npc.elara"), "Activated mod resolves npc.elara in DataService")
	assert_true(ds_mod.get_all_stable_ids().has("world.moonlit_garden"), "Activated mod resolves world.moonlit_garden in DataService")
	
	# Test mod deactivation
	mm_clean.disable_mod("moonlit_garden")
	assert_false(ds_mod.get_all_stable_ids().has("npc.elara"), "Deactivated mod removes npc.elara from resolution")
	
	mm_clean.unregister_mod("moonlit_garden")
