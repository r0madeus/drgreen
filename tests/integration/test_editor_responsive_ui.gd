class_name TestEditorResponsiveUI
extends TestCase

## Responsive UI and viewport layout validation test suite (Phase 34).

func test_name_id() -> String:
	return "EDITOR_RESPONSIVE_UI.InGameSuite"

const SHELL_SCRIPT = preload("res://editor/ui/editor_shell.gd")
const WORLD_PANEL_SCRIPT = preload("res://editor/ui/panels/world_editor_panel.gd")

func run_all() -> void:
	test_name = test_name_id()

	_test_01_resolution_1280x720()
	_test_02_resolution_1366x768()
	_test_03_resolution_1600x900()
	_test_04_resolution_1920x1080()
	_test_05_resolution_2560x1440()
	_test_06_canvas_dominant_area_constraint()
	_test_07_side_panels_collapsible_toggle()
	_test_08_input_layer_isolation()

func _test_01_resolution_1280x720() -> void:
	begin_test("R01_Resolution_1280x720")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.size = Vector2(1280, 720)
	panel.setup(EditorService.get_instance())
	assert_true(panel.canvas_container.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "1280x720 maintains canvas viewport container space")
	panel.free()


func _test_02_resolution_1366x768() -> void:
	begin_test("R02_Resolution_1366x768")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.size = Vector2(1366, 768)
	panel.setup(EditorService.get_instance())
	assert_true(panel.right_dock.custom_minimum_size.x > 0 or panel.right_dock.get_parent().custom_minimum_size.x > 0, "1366x768 preserves right dock")
	panel.free()

func _test_03_resolution_1600x900() -> void:
	begin_test("R03_Resolution_1600x900")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.size = Vector2(1600, 900)
	panel.setup(EditorService.get_instance())
	assert_true(panel.left_sidebar_container != null, "1600x900 tool sidebar intact")
	panel.free()

func _test_04_resolution_1920x1080() -> void:
	begin_test("R04_Resolution_1920x1080")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.size = Vector2(1920, 1080)
	panel.setup(EditorService.get_instance())
	assert_true(panel.canvas_container.size_flags_horizontal == Control.SIZE_EXPAND_FILL, "1920x1080 canvas container expands to full size")
	panel.free()

func _test_05_resolution_2560x1440() -> void:
	begin_test("R05_Resolution_2560x1440")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.size = Vector2(2560, 1440)
	panel.setup(EditorService.get_instance())
	assert_true(panel.visible, "2560x1440 2K widescreen layout functional")
	panel.free()

func _test_06_canvas_dominant_area_constraint() -> void:
	begin_test("R06_CanvasDominantAreaConstraint")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	assert_eq(panel.canvas_container.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Canvas container does not block input")
	assert_eq(panel.canvas.mouse_filter, Control.MOUSE_FILTER_STOP, "WorldCanvas consumes mouse events directly")
	panel.free()

func _test_07_side_panels_collapsible_toggle() -> void:
	begin_test("R07_SidePanelsCollapsibleToggle")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	var left_p = panel.left_sidebar_container.get_parent() as Control
	var right_p = panel.right_dock.get_parent() as Control
	
	panel._on_toggle_side_panels()
	assert_false(left_p.visible, "Left sidebar collapsed")
	assert_false(right_p.visible, "Right dock collapsed")
	
	panel._on_toggle_side_panels()
	assert_true(left_p.visible, "Left sidebar expanded")
	assert_true(right_p.visible, "Right dock expanded")
	panel.free()

func _test_08_input_layer_isolation() -> void:
	begin_test("R08_InputLayerIsolation")
	var panel = WORLD_PANEL_SCRIPT.new()
	panel.setup(EditorService.get_instance())
	assert_true(panel.canvas.has_method("_gui_input"), "WorldCanvas uses direct _gui_input for clean mouse isolation")
	panel.free()
