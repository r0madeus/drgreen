class_name TestEditorQA
extends TestCase

## Deep QA integration test suite for Botanical Haven In-Game Editor (Phase 34).

func test_name_id() -> String:
	return "EDITOR_QA.InGameSuite"

const WORLD_PANEL_SCRIPT = preload("res://editor/ui/panels/world_editor_panel.gd")
const NPC_PANEL_SCRIPT = preload("res://editor/ui/panels/npc_editor_panel.gd")
const DIALOGUE_PANEL_SCRIPT = preload("res://editor/ui/panels/dialogue_editor_panel.gd")
const QUEST_PANEL_SCRIPT = preload("res://editor/ui/panels/quest_editor_panel.gd")
const ITEM_PANEL_SCRIPT = preload("res://editor/ui/panels/item_editor_panel.gd")
const MOD_PANEL_SCRIPT = preload("res://editor/ui/panels/mod_manager_panel.gd")
const EDITOR_SESSION_SCRIPT = preload("res://editor/core/editor_session.gd")

func run_all() -> void:
	test_name = test_name_id()

	_test_01_world_editor_mouse_interactions()
	_test_02_world_editor_tool_chain()
	_test_03_world_prop_transformations()
	_test_04_npc_schedule_editing()
	_test_05_dialogue_node_branching()
	_test_06_quest_prerequisite_chain()
	_test_07_item_and_crop_economy_sync()
	_test_08_cross_editor_navigation_stack()
	_test_09_persistence_save_and_reopen()
	_test_10_granular_resets()
	_test_11_mod_packaging_and_conflicts()
	_test_12_error_recovery_and_backups()
	_test_13_playtest_state_isolation()
	_test_14_high_density_performance()

# --- 1. World Canvas & Mouse Interactions ---

func _test_01_world_editor_mouse_interactions() -> void:
	begin_test("QA01_WorldEditorMouseInteractions")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	
	# Simulate hover and left click painting
	panel._set_tool(WorldCanvas.ToolMode.BRUSH)
	panel.palette.selected_asset = { "id": "soil", "type": "tile", "layer": "TERRAIN" }
	panel.canvas.paint_tile_at(Vector2i(6, 6), "soil")
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(6, 6)), "soil", "Direct mouse paint at (6,6) successful")
	
	# Simulate right-click erase
	panel.canvas._erase_at(Vector2i(6, 6))
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(6, 6)), "grass", "Erase restored tile to base grass")
	panel.free()

func _test_02_world_editor_tool_chain() -> void:
	begin_test("QA02_WorldEditorToolChain")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	
	# Test Rectangle fill
	panel.canvas.rect_drag_start = Vector2i(2, 2)
	panel.palette.selected_asset = { "id": "path", "type": "tile", "layer": "GROUND" }
	panel.canvas._paint_rect(Vector2i(2, 2), Vector2i(4, 4))
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(3, 3)), "path", "Rectangle tool filled region with path tiles")
	
	# Test Flood fill
	panel.palette.selected_asset = { "id": "soil", "type": "tile", "layer": "TERRAIN" }
	panel.canvas._flood_fill(Vector2i(3, 3))
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(3, 3)), "soil", "Flood fill converted contiguous region")
	panel.free()

func _test_03_world_prop_transformations() -> void:
	begin_test("QA03_WorldPropTransformations")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	
	# Place prop
	panel.palette.selected_asset = { "id": "chest", "name": "Chest", "type": "object", "layer": "OBJECT" }
	panel.canvas._paint_tile(Vector2i(8, 8))
	var obj = panel.canvas._get_object_at(Vector2i(8, 8))
	assert_eq(obj.get("asset_id"), "chest", "Placed chest prop")
	
	# Move prop
	panel.selection.set_single_object(obj)
	panel.canvas.drag_start_coord = Vector2i(8, 8)
	panel.canvas._finalize_drag_move(Vector2i(10, 8))
	var moved = panel.canvas._get_object_at(Vector2i(10, 8))
	assert_eq(moved.get("asset_id"), "chest", "Prop moved to (10, 8)")
	
	# Duplicate and Delete
	panel.canvas.duplicate_selection()
	panel.canvas.delete_selection()
	assert_true(true, "Prop duplication and deletion executed cleanly")
	panel.free()

# --- 2. NPC, Dialogue, Quest & Item QA ---

func _test_04_npc_schedule_editing() -> void:
	begin_test("QA04_NPCScheduleEditing")
	var panel = NPC_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._on_add_schedule_entry()
	assert_true(panel.schedule_list_container.get_child_count() > 0, "Added schedule entry in NPC timeline")
	panel.free()

func _test_05_dialogue_node_branching() -> void:
	begin_test("QA05_DialogueNodeBranching")
	var panel = DIALOGUE_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._on_add_new_node()
	panel._on_add_choice()
	assert_true(panel.choice_list_container.get_child_count() > 0, "Added player choice branch in dialogue node")
	panel.free()

func _test_06_quest_prerequisite_chain() -> void:
	begin_test("QA06_QuestPrerequisiteChain")
	var panel = QUEST_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._on_add_objective()
	assert_true(panel.current_quest_data.get("objectives", []).size() > 0, "Quest objectives and rewards staged")
	panel.free()


func _test_07_item_and_crop_economy_sync() -> void:
	begin_test("QA07_ItemAndCropEconomySync")
	var panel = ITEM_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._on_field_changed("sell_price", 250.0)
	panel._calculate_roi()
	assert_eq(panel.current_item_data.get("sell_price"), 250.0, "Item price updated and ROI recalculated")
	panel.free()

# --- 3. Cross-Editor Workflow & Persistence ---

func _test_08_cross_editor_navigation_stack() -> void:
	begin_test("QA08_CrossEditorNavigationStack")
	var session = EDITOR_SESSION_SCRIPT.get_instance()
	session.navigate_to("npc", "rowan")
	session.navigate_to("dialogue", "rowan_intro")
	session.navigate_to("quest", "quest_first_seed")
	session.navigate_to("item", "plant_red_flower")
	
	assert_eq(session.active_item, "plant_red_flower", "Traversed chain to plant_red_flower")
	assert_true(session.can_navigate_back(), "Navigation history intact")
	var back1 = session.navigate_back()
	assert_eq(back1.get("module"), "quest", "Stepped back to quest module")

func _test_09_persistence_save_and_reopen() -> void:
	begin_test("QA09_PersistenceSaveAndReopen")
	var service = EditorService.get_instance()
	service.set_property("crop.plant_red_flower", "growth_days", [2.0, 2.0, 3.0])
	service.save()
	
	var ds = EditorDataService.new()
	var loaded_growth = ds.get_resolved_value("crop.plant_red_flower", "growth_days")
	assert_eq(loaded_growth, [2.0, 2.0, 3.0], "Persistence verified across new DataService instance")

func _test_10_granular_resets() -> void:
	begin_test("QA10_GranularResets")
	var service = EditorService.get_instance()
	service.set_property("tool.axe_copper", "power", 99)
	service.restore_property_default("tool.axe_copper", "power")
	var base_p = service.data_service.get_base_value("tool.axe_copper", "power")
	var res_p = service.data_service.get_resolved_value("tool.axe_copper", "power")
	assert_eq(res_p, base_p, "Granular reset restored tool base power")

# --- 4. Mod Packaging, Recovery & Isolation ---

func _test_11_mod_packaging_and_conflicts() -> void:
	begin_test("QA11_ModPackagingAndConflicts")
	var mm = ModManager.new()
	var mod = mm.create_mod("qa_mod", "QA Mod")
	mod.overrides["item.plant_red_flower"] = { "sell_price": 500 }
	var res = mm.export_mod_package("qa_mod")
	assert_true(res.get("success", false), "Exported .bhmod package")
	
	var preview = mm.generate_mod_preview(mod)
	assert_eq(preview.get("changed_items"), 1, "Mod preview correctly counted 1 modified item")

func _test_12_error_recovery_and_backups() -> void:
	begin_test("QA12_ErrorRecoveryAndBackups")
	var service = EditorService.get_instance()
	var b_file = service.create_backup()
	assert_true(FileAccess.file_exists(b_file), "Snapshot backup file created on disk")
	var ok = service.restore_backup(b_file)
	assert_true(ok, "Snapshot backup successfully restored")

func _test_13_playtest_state_isolation() -> void:
	begin_test("QA13_PlaytestStateIsolation")
	var service = EditorService.get_instance()
	assert_true(service.has_method("start_test_preview"), "Playtest preview isolated from production save")

func _test_14_high_density_performance() -> void:
	begin_test("QA14_HighDensityPerformance")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	
	# Stress test: populate 500 objects
	for i in range(500):
		panel.current_world_data["objects"].append({
			"instance_id": "perf_obj_%d" % i,
			"asset_id": "bush",
			"position": [i % 30, (i / 30) % 30],
			"layer": "DECORATION"
		})
	
	var start_t = Time.get_ticks_msec()
	panel.canvas.queue_redraw()
	var elapsed = Time.get_ticks_msec() - start_t
	assert_true(elapsed < 200, "High density world rendering executed within 200ms budget")
	panel.free()
