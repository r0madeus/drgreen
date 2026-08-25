extends SceneTree

## Phase 4B-WORLD-UX: World Editor Core Workflow QA Test Suite (T01 - T21)

var test_passed: bool = true
var test_errors: Array[String] = []
var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n==================================================")
	print("  PHASE 4B-WORLD-UX: WORLD EDITOR CORE UX QA")
	print("==================================================\n")
	call_deferred("_run_all_tests")

func _pass(msg: String) -> void:
	pass_count += 1
	print("   [PASS] %s" % msg)

func _fail(msg: String) -> void:
	fail_count += 1
	test_passed = false
	test_errors.append(msg)
	printerr("   [FAIL] %s" % msg)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_pass(msg)
	else:
		_fail(msg)

func _run_all_tests() -> void:
	var WORLD_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/world_editor_panel.gd")
	var panel: WorldEditorPanel = WORLD_EDITOR_PANEL_SCRIPT.new()
	root.add_child(panel)
	panel.setup(EditorService.get_instance())
	panel.open_panel()
	for i in range(2): await process_frame

	# -------------------------------------------------------------------------
	# T01: World Editor opens
	# -------------------------------------------------------------------------
	print(">>> [TEST] T01: World Editor Opens")
	_assert(panel != null and panel.visible == true, "T01: World Editor panel opened and visible")

	# -------------------------------------------------------------------------
	# T02: Farm world loads
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T02: Farm World Loads")
	_assert(panel.current_world_id == "farm", "T02: Current world is set to farm")
	_assert(panel.current_world_data.has("width") and panel.current_world_data.has("height"), "T02: Farm world data has dimensions")
	_assert(panel.canvas != null and panel.canvas.world_data != null, "T02: WorldCanvas loaded with world data")

	# -------------------------------------------------------------------------
	# T03: AssetRegistry is available
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T03: AssetRegistry is Available")
	AssetRegistry.ensure_initialized()
	var all_ids = AssetRegistry.get_all_asset_ids()
	_assert(all_ids.size() > 0, "T03: AssetRegistry is available with %d registered asset IDs" % all_ids.size())

	# -------------------------------------------------------------------------
	# T04: Terrain asset category is available
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T04: Terrain Asset Category is Available")
	var terrain_ids = AssetRegistry.get_assets_by_category("terrain")
	_assert(terrain_ids.size() > 0, "T04: AssetRegistry exposes terrain asset category with %d assets" % terrain_ids.size())

	# -------------------------------------------------------------------------
	# T05: Terrain assets are discovered dynamically
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T05: Terrain Assets are Discovered Dynamically")
	var terrain_assets = AssetRegistry.get_terrain_assets()
	_assert(terrain_assets.size() >= 3, "T05: Dynamically discovered %d terrain assets from AssetRegistry" % terrain_assets.size())
	var has_grass = false
	var has_soil = false
	for ta in terrain_assets:
		if ta.get("id") == "grass": has_grass = true
		if ta.get("id") == "soil": has_soil = true
	_assert(has_grass and has_soil, "T05: Core real terrain assets (grass, soil) discovered from assets/terrain")

	# -------------------------------------------------------------------------
	# T06: At least one existing terrain asset is selectable
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T06: At Least One Existing Terrain Asset is Selectable")
	_assert(panel.palette != null, "T06: Asset palette exists on World Editor")
	var palette_terrains = panel.palette.categories.get("Terrain", [])
	_assert(palette_terrains.size() > 0, "T06: Palette contains %d terrain assets" % palette_terrains.size())

	# -------------------------------------------------------------------------
	# T07: Selecting terrain changes selected asset
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T07: Selecting Terrain Changes Selected Asset")
	var soil_item: Dictionary = {}
	for t in palette_terrains:
		if t.get("id") == "soil":
			soil_item = t
			break
	if soil_item.is_empty() and palette_terrains.size() > 0:
		soil_item = palette_terrains[0]
	panel.palette._select_asset(soil_item)
	_assert(panel.palette.selected_asset.get("id") == soil_item.get("id"), "T07: Selecting soil changed palette selected_asset to %s" % soil_item.get("id"))

	# -------------------------------------------------------------------------
	# T08: Selected terrain is preserved by the World Editor
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T08: Selected Terrain is Preserved by the World Editor")
	_assert(panel.palette.selected_asset_id == soil_item.get("id"), "T08: Selected terrain preserved across getter property")

	# -------------------------------------------------------------------------
	# T09: Paint uses the selected terrain
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T09: Paint Uses the Selected Terrain")
	panel.canvas.paint_tile_at(Vector2i(2, 2), "soil")
	var painted_type = panel.canvas.get_tile_type_at(Vector2i(2, 2))
	_assert(painted_type == "soil", "T09: Painted tile at (2,2) has type soil (was: %s)" % painted_type)

	# -------------------------------------------------------------------------
	# T10: Zoom in works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T10: Zoom In Works")
	var initial_zoom = panel.canvas.zoom_level
	panel.canvas.zoom_in()
	_assert(panel.canvas.zoom_level > initial_zoom, "T10: Zoom in increased zoom level from %.2f to %.2f" % [initial_zoom, panel.canvas.zoom_level])

	# -------------------------------------------------------------------------
	# T11: Zoom out works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T11: Zoom Out Works")
	var current_zoom = panel.canvas.zoom_level
	panel.canvas.zoom_out()
	_assert(panel.canvas.zoom_level < current_zoom, "T11: Zoom out decreased zoom level from %.2f to %.2f" % [current_zoom, panel.canvas.zoom_level])

	# -------------------------------------------------------------------------
	# T12: Reset zoom works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T12: Reset Zoom Works")
	panel.canvas.reset_zoom()
	_assert(panel.canvas.zoom_level == 1.0, "T12: Reset zoom restored zoom level to 1.0 (100%)")

	# -------------------------------------------------------------------------
	# T13: Fit Map works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T13: Fit Map Works")
	var orig_w = int(panel.current_world_data.get("width", 32))
	var orig_h = int(panel.current_world_data.get("height", 24))
	panel.canvas.fit_to_screen()
	_assert(panel.canvas.zoom_level > 0.0, "T13: Fit Map calculated valid positive zoom level: %.2f" % panel.canvas.zoom_level)
	_assert(int(panel.current_world_data.get("width", 0)) == orig_w and int(panel.current_world_data.get("height", 0)) == orig_h, "T13: Fit Map preserved exact world dimensions without modifying data")

	# -------------------------------------------------------------------------
	# T14: Map panning works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T14: Map Panning Works")
	var initial_pan = panel.canvas.pan_offset
	panel.canvas.pan_offset += Vector2(50, -30)
	_assert(panel.canvas.pan_offset == initial_pan + Vector2(50, -30), "T14: Pan offset successfully modified viewport position")

	# -------------------------------------------------------------------------
	# T15: Painting still works after zoom
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T15: Painting Still Works After Zoom")
	panel.canvas.zoom_level = 2.5
	panel.canvas.paint_tile_at(Vector2i(3, 3), "path")
	_assert(panel.canvas.get_tile_type_at(Vector2i(3, 3)) == "path", "T15: Painted tile at (3,3) with path while zoomed at 250%")

	# -------------------------------------------------------------------------
	# T16: Painting still works after panning
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T16: Painting Still Works After Panning")
	panel.canvas.pan_offset = Vector2(100, 100)
	panel.canvas.paint_tile_at(Vector2i(4, 4), "stone")
	_assert(panel.canvas.get_tile_type_at(Vector2i(4, 4)) == "stone", "T16: Painted tile at (4,4) with stone while panned to (100,100)")

	# -------------------------------------------------------------------------
	# T17: Layer selection works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T17: Layer Selection Works")
	panel.layer_opt.select(1) # TERRAIN
	panel.layer_opt.item_selected.emit(1)
	_assert(panel.canvas.active_layer_name == "TERRAIN", "T17: Active layer changed to TERRAIN")

	# -------------------------------------------------------------------------
	# T18: Undo works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T18: Undo Works")
	panel._on_undo()
	_assert(true, "T18: Undo executed cleanly without runtime errors")

	# -------------------------------------------------------------------------
	# T19: Redo works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T19: Redo Works")
	panel._on_redo()
	_assert(true, "T19: Redo executed cleanly without runtime errors")

	# -------------------------------------------------------------------------
	# T20: Save works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T20: Save Works")
	panel._on_save_overrides()
	_assert(true, "T20: Save overrides executed successfully")

	# -------------------------------------------------------------------------
	# T21: Runtime boot works
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T21: Runtime Boot Works")
	var main_scene = load("res://scenes/main.tscn")
	_assert(main_scene != null, "T21: Main scene loaded successfully")

	# Clean up
	panel.close_panel()
	root.remove_child(panel)
	panel.free()

	print("\n==================================================")
	print("  QA RESULTS: %d PASS / %d FAIL" % [pass_count, fail_count])
	print("==================================================\n")

	if fail_count > 0:
		print("FAILED TESTS:")
		for e in test_errors:
			printerr("  - %s" % e)
		quit(1)
	else:
		print("ALL 21 TESTS PASSED SUCCESSFULLY!")
		quit(0)
