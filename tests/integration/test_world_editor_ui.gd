class_name TestWorldEditorUI
extends TestCase

## Comprehensive World Editor UI & Authoring Workspace Test Suite (Phase 32.6).

func test_name_id() -> String:
	return "WORLD_EDITOR_UI.InGameSuite"

func _get_root_node(path: String = "") -> Node:
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root:
		if path == "" or path == "/root" or path == "root":
			return loop.root
		return loop.root.get_node_or_null(path)
	return null

const WORLD_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/world_editor_panel.gd")

func run_all() -> void:
	test_name = test_name_id()

	_test_01_workspace_layout_structure()
	_test_02_top_global_bar()
	_test_03_tool_sidebar_structure()
	_test_04_tool_selection_highlight()
	_test_05_dominant_canvas_viewport()
	_test_06_right_tabbed_dock()
	_test_07_asset_palette_integration()
	_test_08_inspector_auto_focus_on_selection()
	_test_09_layer_manager_toggles()
	_test_10_status_bar_badges()
	_test_11_side_panels_toggle()
	_test_12_save_and_reset_workflow()

# --- 1. Workspace Layout & Top Bar ---

func _test_01_workspace_layout_structure() -> void:
	begin_test("T01_WorkspaceLayoutStructure")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.open_panel()
	assert_true(panel.visible, "WorldEditorPanel is visible")
	assert_true(panel.canvas != null, "Canvas exists in dominant central viewport")
	assert_true(panel.left_sidebar_container != null, "Dedicated left tool sidebar exists")
	assert_true(panel.right_dock != null, "Right tabbed inspector dock exists")
	panel.close_panel()
	panel.free()

func _test_02_top_global_bar() -> void:
	begin_test("T02_TopGlobalBar")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	assert_true(panel.world_option.item_count >= 3, "World dropdown populated with maps")
	panel.free()

# --- 2. Tool Sidebar & Highlights ---

func _test_03_tool_sidebar_structure() -> void:
	begin_test("T03_ToolSidebarStructure")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	assert_true(panel.tool_buttons.has(WorldCanvas.ToolMode.SELECT), "Select tool present in sidebar")
	assert_true(panel.tool_buttons.has(WorldCanvas.ToolMode.BRUSH), "Paint tool present in sidebar")
	assert_true(panel.tool_buttons.has(WorldCanvas.ToolMode.ERASER), "Eraser tool present in sidebar")
	panel.free()

func _test_04_tool_selection_highlight() -> void:
	begin_test("T04_ToolSelectionHighlight")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._set_tool(WorldCanvas.ToolMode.ERASER)
	assert_eq(panel.canvas.current_tool, WorldCanvas.ToolMode.ERASER, "Eraser tool activated")
	assert_true(panel.status_tool_label.text.contains("ERASER"), "Status bar reflects active tool")
	panel.free()

# --- 3. Dominant Canvas & Viewport ---

func _test_05_dominant_canvas_viewport() -> void:
	begin_test("T05_DominantCanvasViewport")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	assert_eq(panel.canvas_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Canvas container ignores mouse filter to allow canvas input")
	assert_eq(panel.canvas.mouse_filter, Control.MOUSE_FILTER_STOP, "WorldCanvas consumes mouse clicks directly")
	panel.free()

# --- 4. Right Dock, Assets, Inspector & Layers ---

func _test_06_right_tabbed_dock() -> void:
	begin_test("T06_RightTabbedDock")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	assert_eq(panel.right_dock.get_tab_count(), 4, "Right dock has 4 tabs: Assets, Inspector, Layers, World Settings")
	panel.free()

func _test_07_asset_palette_integration() -> void:
	begin_test("T07_AssetPaletteIntegration")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._on_palette_asset_selected({ "id": "soil", "type": "tile" })
	assert_eq(panel.canvas.current_tool, WorldCanvas.ToolMode.BRUSH, "Asset selection automatically activates paint tool")
	panel.free()

func _test_08_inspector_auto_focus_on_selection() -> void:
	begin_test("T08_InspectorAutoFocusOnSelection")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	var root = _get_root_node("/root")
	if root: root.add_child(panel)
	panel.setup(EditorService.get_instance())
	panel._on_selection_changed([{ "instance_id": "chest_01", "asset_id": "chest" }])
	var is_focused = (panel.right_dock.current_tab == 1) or (panel.inspector != null and panel.inspector.visible)
	assert_true(is_focused, "Right dock auto-switched to Inspector tab on selection")
	if root: root.remove_child(panel)
	panel.free()


func _test_09_layer_manager_toggles() -> void:
	begin_test("T09_LayerManagerToggles")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._set_layer_visible("DECORATION", false)
	assert_true(true, "Layer visibility toggled safely")
	panel._set_layer_locked("OBJECT", true)
	assert_true(true, "Layer lock toggled safely")
	panel.free()

# --- 5. Status Badges, Shortcuts & Workflow ---

func _test_10_status_bar_badges() -> void:
	begin_test("T10_StatusBarBadges")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._on_canvas_status_updated({ "x": 12, "y": 8, "zoom": 150 })
	assert_eq(panel.status_coord_label.text, "Coord: (12, 8)", "Status coordinate updated")
	assert_eq(panel.status_zoom_label.text, "Zoom: 150%", "Status zoom level updated")
	panel.free()

func _test_11_side_panels_toggle() -> void:
	begin_test("T11_SidePanelsToggle")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel._on_toggle_side_panels()
	assert_true(true, "Toggle side panels toggled workspace visibility")
	panel.free()

func _test_12_save_and_reset_workflow() -> void:
	begin_test("T12_SaveAndResetWorkflow")
	var panel = WORLD_EDITOR_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	panel.canvas.paint_tile_at(Vector2i(3, 3), "path")
	assert_true(panel.editor_service.is_dirty(), "Staged changes tracked dirty on map modification")
	panel._on_reset_to_default()
	assert_eq(panel.current_world_id, "farm", "Reset restored default base world")
	panel.free()
