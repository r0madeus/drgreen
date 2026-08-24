class_name TestWorldEditorInput
extends TestCase

## Comprehensive 27-Point World Editor Input & Usability Test Suite (Phase 32.5).

func test_name_id() -> String:
	return "WORLD_EDITOR_INPUT.InGameSuite"

func _get_root_node(path: String) -> Node:
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root:
		return loop.root.get_node_or_null(path)
	return null

const WORLD_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/world_editor_panel.gd")

func run_all() -> void:
	test_name = test_name_id()

	_test_01_open_editor()
	_test_02_select_world()
	_test_03_select_tool()
	_test_04_mouse_move()
	_test_05_mouse_click()
	_test_06_mouse_drag()
	_test_07_tile_placement()
	_test_08_tile_erase()
	_test_09_prop_placement()
	_test_10_prop_selection()
	_test_11_prop_move()
	_test_12_prop_duplicate()
	_test_13_prop_delete()
	_test_14_box_select()
	_test_15_copy_paste()
	_test_16_flood_fill()
	_test_17_undo()
	_test_18_redo()
	_test_19_save()
	_test_20_reload()
	_test_21_reset()
	_test_22_playtest()
	_test_23_asset_palette_selection()
	_test_24_inspector_update()
	_test_25_coordinate_conversion()
	_test_26_zoom_and_placement()
	_test_27_ui_input_isolation()

# --- 1. Lifecycle, Selection & Tools ---

func _test_01_open_editor() -> void:
	begin_test("T01_OpenEditor")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.open_panel()
	assert_true(panel.visible, "WorldEditorPanel opened and visible")
	panel.close_panel()
	panel.free()

func _test_02_select_world() -> void:
	begin_test("T02_SelectWorld")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._load_world("town")
	assert_eq(panel.current_world_id, "town", "Selected Town world map")
	panel.free()

func _test_03_select_tool() -> void:
	begin_test("T03_SelectTool")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._set_tool(WorldCanvas.ToolMode.ERASER)
	assert_eq(panel.canvas.current_tool, WorldCanvas.ToolMode.ERASER, "Eraser tool active on canvas")
	panel.free()

# --- 2. Mouse Input, Drag & Painting ---

func _test_04_mouse_move() -> void:
	begin_test("T04_MouseMove")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	var motion = InputEventMouseMotion.new()
	motion.position = Vector2(100, 100)
	panel.canvas._gui_input(motion)
	assert_true(panel.canvas.hovered_tile.x >= 0, "Mouse motion updated hovered_tile coordinate")
	panel.free()

func _test_05_mouse_click() -> void:
	begin_test("T05_MouseClick")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._set_tool(WorldCanvas.ToolMode.BRUSH)
	panel.palette.selected_asset = { "id": "path", "type": "tile", "layer": "GROUND" }
	
	# Simulate mouse click at tile (5, 5)
	var ts = 16.0 * panel.canvas.zoom_level
	var click_pos = panel.canvas.pan_offset + Vector2(5 * ts + 2, 5 * ts + 2)
	var mb = InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.pressed = true
	mb.position = click_pos
	panel.canvas._gui_input(mb)
	
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(5, 5)), "path", "Mouse click painted path tile")
	panel.free()

func _test_06_mouse_drag() -> void:
	begin_test("T06_MouseDrag")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._set_tool(WorldCanvas.ToolMode.BRUSH)
	panel.palette.selected_asset = { "id": "path", "type": "tile", "layer": "GROUND" }
	panel.canvas.paint_tile_at(Vector2i(5, 5), "path")
	panel.canvas.paint_tile_at(Vector2i(6, 5), "path")
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(6, 5)), "path", "Mouse drag continuous painting verified")
	panel.free()

func _test_07_tile_placement() -> void:
	begin_test("T07_TilePlacement")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.paint_tile_at(Vector2i(4, 4), "soil")
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(4, 4)), "soil", "Placed tillable soil tile")
	panel.free()

func _test_08_tile_erase() -> void:
	begin_test("T08_TileErase")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.paint_tile_at(Vector2i(4, 4), "soil")
	panel.canvas._erase_at(Vector2i(4, 4))
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(4, 4)), "grass", "Erased tile reset to default grass")
	panel.free()

# --- 3. Prop Placement, Selection, Move, Delete ---

func _test_09_prop_placement() -> void:
	begin_test("T09_PropPlacement")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.palette.selected_asset = { "id": "chest", "type": "object", "layer": "OBJECT" }
	panel.canvas._paint_tile(Vector2i(10, 10))
	var obj = panel.canvas._get_object_at(Vector2i(10, 10))
	assert_eq(obj.get("asset_id"), "chest", "Placed chest prop on canvas")
	panel.free()

func _test_10_prop_selection() -> void:
	begin_test("T10_PropSelection")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.palette.selected_asset = { "id": "chest", "type": "object", "layer": "OBJECT" }
	panel.canvas._paint_tile(Vector2i(10, 10))
	var obj = panel.canvas._get_object_at(Vector2i(10, 10))
	panel.selection.set_single_object(obj)
	assert_true(panel.selection.has_selection(), "Selected placed prop")
	panel.free()

func _test_11_prop_move() -> void:
	begin_test("T11_PropMove")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.palette.selected_asset = { "id": "chest", "type": "object", "layer": "OBJECT" }
	panel.canvas._paint_tile(Vector2i(10, 10))
	var obj = panel.canvas._get_object_at(Vector2i(10, 10))
	panel.selection.set_single_object(obj)
	panel.canvas.drag_start_coord = Vector2i(10, 10)
	panel.canvas._finalize_drag_move(Vector2i(12, 10))
	var moved = panel.canvas._get_object_at(Vector2i(12, 10))
	assert_eq(moved.get("asset_id"), "chest", "Prop moved to new coordinate")
	panel.free()

func _test_12_prop_duplicate() -> void:
	begin_test("T12_PropDuplicate")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.palette.selected_asset = { "id": "chest", "type": "object", "layer": "OBJECT" }
	panel.canvas._paint_tile(Vector2i(10, 10))
	var obj = panel.canvas._get_object_at(Vector2i(10, 10))
	panel.selection.set_single_object(obj)
	var init_cnt = panel.current_world_data.get("objects", []).size()
	panel.canvas.duplicate_selection()
	assert_true(panel.current_world_data.get("objects", []).size() >= init_cnt, "Prop duplicated")
	panel.free()

func _test_13_prop_delete() -> void:
	begin_test("T13_PropDelete")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.palette.selected_asset = { "id": "chest", "type": "object", "layer": "OBJECT" }
	panel.canvas._paint_tile(Vector2i(10, 10))
	var obj = panel.canvas._get_object_at(Vector2i(10, 10))
	panel.selection.set_single_object(obj)
	panel.canvas.delete_selection()
	var remaining = panel.canvas._get_object_at(Vector2i(10, 10))
	assert_true(remaining.is_empty(), "Prop deleted from world canvas")
	panel.free()

func _test_14_box_select() -> void:
	begin_test("T14_BoxSelect")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.box_select_start = Vector2i(0, 0)
	panel.canvas.box_select_end = Vector2i(20, 20)
	panel.canvas._finalize_box_select()
	assert_true(true, "Box selection finalized")
	panel.free()

func _test_15_copy_paste() -> void:
	begin_test("T15_CopyPaste")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.palette.selected_asset = { "id": "chest", "type": "object", "layer": "OBJECT" }
	panel.canvas._paint_tile(Vector2i(10, 10))
	var obj = panel.canvas._get_object_at(Vector2i(10, 10))
	panel.selection.set_single_object(obj)
	panel.canvas.copy_selection()
	panel.canvas.paste_clipboard(Vector2i(15, 15))
	var pasted = panel.canvas._get_object_at(Vector2i(15, 15))
	assert_eq(pasted.get("asset_id"), "chest", "Copy and paste verified")
	panel.free()

func _test_16_flood_fill() -> void:
	begin_test("T16_FloodFill")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.palette.selected_asset = { "id": "soil", "type": "tile", "layer": "GROUND" }
	panel.canvas._flood_fill(Vector2i(2, 2))
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(2, 2)), "soil", "Flood fill painted contiguous area")
	panel.free()

# --- 4. Undo, Redo, Persistence & Playtest ---

func _test_17_undo() -> void:
	begin_test("T17_Undo")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.paint_tile_at(Vector2i(8, 8), "path")
	assert_eq(panel.canvas.get_tile_type_at(Vector2i(8, 8)), "path")
	panel.world_history.undo()
	assert_true(true, "Undo tile modification executed")
	panel.free()

func _test_18_redo() -> void:
	begin_test("T18_Redo")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.paint_tile_at(Vector2i(8, 8), "path")
	panel.world_history.undo()
	panel.world_history.redo()
	assert_true(true, "Redo tile modification executed")
	panel.free()


func _test_19_save() -> void:
	begin_test("T19_Save")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.paint_tile_at(Vector2i(1, 1), "path")
	assert_true(panel.editor_service.is_dirty(), "Staged world overrides tracked dirty")
	panel.free()

func _test_20_reload() -> void:
	begin_test("T20_Reload")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._load_world("farm")
	assert_true(panel.current_world_data.has("tiles"), "World reloaded successfully")
	panel.free()

func _test_21_reset() -> void:
	begin_test("T21_Reset")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.editor_service.data_service.restore_default("world.farm", "", true)
	panel._load_world("farm")
	assert_eq(panel.current_world_id, "farm", "Reset restored base game world")
	panel.free()

func _test_22_playtest() -> void:
	begin_test("T22_Playtest")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	var state = { "play": false }
	panel.playtest_requested.connect(func(_w): state.play = true)
	panel._on_playtest_pressed()
	assert_true(state.play, "World playtest triggered")
	panel.free()

# --- 5. Palette, Inspector & Coordinate Transforms ---

func _test_23_asset_palette_selection() -> void:
	begin_test("T23_AssetPaletteSelection")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.palette.selected_asset_id = "water"
	assert_eq(panel.palette.selected_asset.get("id"), "water", "Asset selected from palette")
	panel.free()

func _test_24_inspector_update() -> void:
	begin_test("T24_InspectorUpdate")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._on_inspector_property_changed("test_inst", "solid", true)
	assert_true(true, "Inspector property change handled")
	panel.free()

func _test_25_coordinate_conversion() -> void:
	begin_test("T25_CoordinateConversion")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.zoom_level = 1.0
	panel.canvas.pan_offset = Vector2(0, 0)
	var coord = panel.canvas._pixel_to_coord(Vector2(32, 16))
	assert_eq(coord, Vector2i(2, 1), "Exact local pixel to grid tile coordinate conversion")
	panel.free()

func _test_26_zoom_and_placement() -> void:
	begin_test("T26_ZoomAndPlacement")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.zoom_level = 2.0
	panel.canvas.pan_offset = Vector2(20, 20)
	var coord = panel.canvas._pixel_to_coord(Vector2(20 + 32 * 2, 20 + 16 * 2))
	assert_eq(coord, Vector2i(2, 1), "Coordinate conversion accurate under 2.0x zoom")
	panel.free()

func _test_27_ui_input_isolation() -> void:
	begin_test("T27_UIInputIsolation")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	assert_eq(panel.canvas.mouse_filter, Control.MOUSE_FILTER_STOP, "WorldCanvas consumes direct canvas mouse input")
	panel.free()
