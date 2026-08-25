class_name WorldEditorPanel
extends EditorPanel

## In-Game World & Map Editor Panel for Botanical Haven (Phase 32.6 Refactor).
## Professional authoring workspace with uncluttered global bar, dedicated left tool sidebar,
## dominant central canvas, right tabbed asset & inspector dock, and comprehensive status bar.

const CANVAS_SCRIPT = preload("res://editor/world_builder/world_canvas.gd")
const PALETTE_SCRIPT = preload("res://editor/world_builder/asset_palette.gd")
const HISTORY_SCRIPT = preload("res://editor/world_builder/editor_history.gd")
const INSPECTOR_SCRIPT = preload("res://editor/world_builder/world_inspector.gd")
const SELECTION_SCRIPT = preload("res://editor/world_builder/selection_manager.gd")
const VALIDATOR_SCRIPT = preload("res://editor/world_builder/world_validator.gd")
const SERIALIZER_SCRIPT = preload("res://editor/world_builder/world_serializer.gd")
const GRAPH_DIALOG_SCRIPT = preload("res://editor/world_builder/world_graph_dialog.gd")

signal world_changed(world_id: String)
signal playtest_requested(world_id: String)

var current_world_id: String = "farm"
var current_world_data: Dictionary = {}

# Top Bar
var world_option: OptionButton
var btn_zoom_reset: Button

# Left Sidebar & Tool Buttons
var left_sidebar_container: VBoxContainer
var tool_buttons: Dictionary = {} # ToolMode -> Button
var layer_opt: OptionButton

# Center Canvas & Overlays
var canvas: WorldCanvas
var canvas_container: PanelContainer
var grid_toggle: CheckBox
var collision_toggle: CheckBox
var nav_toggle: CheckBox

# Right Dock
var right_dock: TabContainer
var palette: AssetPalette
var inspector: WorldInspector
var layers_vbox: VBoxContainer

# Bottom Status Badges
var status_coord_label: Label
var status_world_label: Label
var status_tool_label: Label
var status_asset_label: Label
var status_zoom_label: Label
var status_selection_label: Label
var status_changes_label: Label
var validation_status_label: Label

# Systems
var selection: SelectionManager
var world_history: EditorHistory
var graph_dialog: WorldGraphDialog
var clipboard_object: Dictionary = {}
var _is_dirty: bool = false
var _available_worlds: Array[String] = ["farm", "central_town", "town", "forest", "greenhouse"]

func _init() -> void:
	super._init("world", "ui.editor.cat_world", "icon_world")

func setup(p_service: Variant) -> void:
	super.setup(p_service)
	selection = SELECTION_SCRIPT.new()
	world_history = HISTORY_SCRIPT.new()
	_build_ui()
	_load_world(current_world_id)

func open_panel() -> void:
	super.open_panel()
	if canvas: canvas.set_process(true)
	refresh()

func close_panel() -> void:
	super.close_panel()
	if canvas: canvas.set_process(false)

func refresh() -> void:
	_populate_world_dropdown()
	if canvas: canvas.queue_redraw()

func _build_ui() -> void:
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.grow_horizontal = GROW_DIRECTION_BOTH
	main_vbox.grow_vertical = GROW_DIRECTION_BOTH
	add_child(main_vbox)

	# =========================================================================
	# 1. TOP GLOBAL BAR (Clean, compact viewport & world controls)
	# =========================================================================
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 32)
	main_vbox.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 6)
	top_bar.add_child(top_hbox)

	var title_lbl = Label.new()
	title_lbl.text = "🌍 World Editor"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.modulate = Color(0.95, 0.88, 0.4)
	top_hbox.add_child(title_lbl)

	var sep_w = VSeparator.new()
	top_hbox.add_child(sep_w)

	var world_lbl = Label.new()
	world_lbl.text = "World:"
	world_lbl.add_theme_font_size_override("font_size", 11)
	top_hbox.add_child(world_lbl)

	world_option = OptionButton.new()
	world_option.custom_minimum_size = Vector2(110, 24)
	world_option.add_theme_font_size_override("font_size", 11)
	world_option.item_selected.connect(_on_world_selected)
	top_hbox.add_child(world_option)

	var sep_v = VSeparator.new()
	top_hbox.add_child(sep_v)

	# --- Viewport Navigation Controls ---
	var btn_zoom_out = Button.new()
	btn_zoom_out.text = "−"
	btn_zoom_out.tooltip_text = "Zoom Out (Wheel Down)"
	btn_zoom_out.add_theme_font_size_override("font_size", 12)
	btn_zoom_out.pressed.connect(func(): if canvas: canvas.zoom_out())
	top_hbox.add_child(btn_zoom_out)

	btn_zoom_reset = Button.new()
	btn_zoom_reset.text = "100%"
	btn_zoom_reset.tooltip_text = "Reset Zoom to 100%"
	btn_zoom_reset.add_theme_font_size_override("font_size", 11)
	btn_zoom_reset.pressed.connect(func(): if canvas: canvas.reset_zoom())
	top_hbox.add_child(btn_zoom_reset)

	var btn_zoom_in = Button.new()
	btn_zoom_in.text = "+"
	btn_zoom_in.tooltip_text = "Zoom In (Wheel Up)"
	btn_zoom_in.add_theme_font_size_override("font_size", 12)
	btn_zoom_in.pressed.connect(func(): if canvas: canvas.zoom_in())
	top_hbox.add_child(btn_zoom_in)

	var btn_fit = Button.new()
	btn_fit.text = "Fit"
	btn_fit.tooltip_text = "Fit entire map in viewport (Home)"
	btn_fit.add_theme_font_size_override("font_size", 11)
	btn_fit.pressed.connect(func(): if canvas: canvas.fit_to_screen())
	top_hbox.add_child(btn_fit)

	var btn_center = Button.new()
	btn_center.text = "⊙"
	btn_center.tooltip_text = "Center view on map (F)"
	btn_center.add_theme_font_size_override("font_size", 12)
	btn_center.pressed.connect(func(): if canvas: canvas.center_map())
	top_hbox.add_child(btn_center)

	var spacer_top = Control.new()
	spacer_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer_top)

	# --- Actions: Undo / Redo / Save / Reset / Playtest ---
	var undo_btn = Button.new()
	undo_btn.text = "↶ Undo"
	undo_btn.tooltip_text = "Undo last action (Ctrl+Z)"
	undo_btn.add_theme_font_size_override("font_size", 11)
	undo_btn.pressed.connect(_on_undo)
	top_hbox.add_child(undo_btn)

	var redo_btn = Button.new()
	redo_btn.text = "↷ Redo"
	redo_btn.tooltip_text = "Redo last action (Ctrl+Y)"
	redo_btn.add_theme_font_size_override("font_size", 11)
	redo_btn.pressed.connect(_on_redo)
	top_hbox.add_child(redo_btn)

	var save_btn = Button.new()
	save_btn.text = "💾 Save"
	save_btn.tooltip_text = "Save world modifications"
	save_btn.add_theme_font_size_override("font_size", 11)
	save_btn.pressed.connect(_on_save_overrides)
	top_hbox.add_child(save_btn)

	var reset_btn = Button.new()
	reset_btn.text = "↺ Reset"
	reset_btn.tooltip_text = "Reset world to base defaults"
	reset_btn.add_theme_font_size_override("font_size", 11)
	reset_btn.pressed.connect(_on_reset_to_default)
	top_hbox.add_child(reset_btn)

	var playtest_btn = Button.new()
	playtest_btn.text = "▶ Test World"
	playtest_btn.tooltip_text = "Launch live playtest for this world"
	playtest_btn.modulate = Color(0.4, 1.0, 0.5)
	playtest_btn.add_theme_font_size_override("font_size", 11)
	playtest_btn.pressed.connect(_on_playtest_pressed)
	top_hbox.add_child(playtest_btn)

	# =========================================================================
	# 2. MAIN 3-ZONE WORKSPACE (Sidebar | Dominant Canvas | Inspector Dock)
	# =========================================================================
	var left_split = HSplitContainer.new()
	left_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(left_split)

	# -------------------------------------------------------------------------
	# 2A. LEFT TOOL SIDEBAR (Compact palette: Tools, Entities, Options)
	# -------------------------------------------------------------------------
	var sidebar_panel = PanelContainer.new()
	sidebar_panel.custom_minimum_size = Vector2(130, 0)
	left_split.add_child(sidebar_panel)

	left_sidebar_container = VBoxContainer.new()
	left_sidebar_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sidebar_panel.add_child(left_sidebar_container)

	_build_tool_sidebar(left_sidebar_container)

	# -------------------------------------------------------------------------
	# 2B. CENTER DOMINANT CANVAS VIEWPORT
	# -------------------------------------------------------------------------
	var right_split = HSplitContainer.new()
	right_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_split.add_child(right_split)

	canvas_container = PanelContainer.new()
	canvas_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_split.add_child(canvas_container)

	var canvas_vbox = VBoxContainer.new()
	canvas_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_container.add_child(canvas_vbox)

	# Minimal Floating Canvas Overlay Bar
	var canvas_top_overlay = HBoxContainer.new()
	canvas_vbox.add_child(canvas_top_overlay)

	grid_toggle = CheckBox.new()
	grid_toggle.text = "Grid"
	grid_toggle.button_pressed = true
	grid_toggle.toggled.connect(func(v): if canvas: canvas.show_grid_lines = v; canvas.queue_redraw())
	canvas_top_overlay.add_child(grid_toggle)

	collision_toggle = CheckBox.new()
	collision_toggle.text = "Collision"
	collision_toggle.toggled.connect(func(v): if canvas: canvas.show_collision_debug = v; canvas.queue_redraw())
	canvas_top_overlay.add_child(collision_toggle)

	nav_toggle = CheckBox.new()
	nav_toggle.text = "Navigation"
	nav_toggle.toggled.connect(func(v): if canvas: canvas.show_navigation_debug = v; canvas.queue_redraw())
	canvas_top_overlay.add_child(nav_toggle)

	canvas_top_overlay.add_spacer(false)

	var toggle_panels_btn = Button.new()
	toggle_panels_btn.text = "[Toggle Panels]"
	toggle_panels_btn.pressed.connect(_on_toggle_side_panels)
	canvas_top_overlay.add_child(toggle_panels_btn)

	# World Canvas
	canvas = CANVAS_SCRIPT.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_vbox.add_child(canvas)

	# -------------------------------------------------------------------------
	# 2C. RIGHT TABBED DOCK (Assets | Inspector | Layers)
	# -------------------------------------------------------------------------
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(260, 0)
	right_split.add_child(right_panel)

	right_dock = TabContainer.new()
	right_dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_dock)

	# Tab 1: Assets Browser
	palette = PALETTE_SCRIPT.new()
	palette.name = "[Asset] Assets"
	palette.asset_selected.connect(_on_palette_asset_selected)
	right_dock.add_child(palette)

	# Tab 2: Inspector
	inspector = INSPECTOR_SCRIPT.new()
	inspector.name = "[Inspector] Inspector"
	inspector.property_changed.connect(_on_inspector_property_changed)
	right_dock.add_child(inspector)

	# Tab 3: Layers
	var layer_tab = ScrollContainer.new()
	layer_tab.name = "[Layers] Layers"
	right_dock.add_child(layer_tab)

	layers_vbox = VBoxContainer.new()
	layers_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer_tab.add_child(layers_vbox)
	_build_layers_tab(layers_vbox)

	# Tab 4: World Settings
	var ws_tab = ScrollContainer.new()
	ws_tab.name = "[Settings] World Settings"
	right_dock.add_child(ws_tab)
	var ws_vbox = VBoxContainer.new()
	ws_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ws_tab.add_child(ws_vbox)
	
	var ws_w_lbl = Label.new()
	ws_w_lbl.text = "Width:"
	ws_vbox.add_child(ws_w_lbl)
	var ws_w_spin = SpinBox.new()
	ws_w_spin.min_value = 16
	ws_w_spin.max_value = 4096
	ws_w_spin.value = 32
	ws_w_spin.name = "WidthSpin"
	ws_vbox.add_child(ws_w_spin)
	
	var ws_h_lbl = Label.new()
	ws_h_lbl.text = "Height:"
	ws_vbox.add_child(ws_h_lbl)
	var ws_h_spin = SpinBox.new()
	ws_h_spin.min_value = 16
	ws_h_spin.max_value = 4096
	ws_h_spin.value = 24
	ws_h_spin.name = "HeightSpin"
	ws_vbox.add_child(ws_h_spin)
	
	var ws_apply_btn = Button.new()
	ws_apply_btn.text = "Apply Resize"
	ws_apply_btn.pressed.connect(func():
		var nw = int(ws_w_spin.value)
		var nh = int(ws_h_spin.value)
		if canvas:
			canvas.resize_world(nw, nh)
	)
	ws_vbox.add_child(ws_apply_btn)

	# =========================================================================
	# 3. BOTTOM STATUS BAR (Informative, compact badges)
	# =========================================================================
	var bottom_bar = PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 24)
	main_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_bar.add_child(bottom_hbox)

	status_coord_label = Label.new()
	status_coord_label.text = "Coord: (0, 0)"
	status_coord_label.add_theme_font_size_override("font_size", 10)
	bottom_hbox.add_child(status_coord_label)

	bottom_hbox.add_spacer(false)

	status_world_label = Label.new()
	status_world_label.text = "World: Farm"
	status_world_label.add_theme_font_size_override("font_size", 10)
	bottom_hbox.add_child(status_world_label)

	bottom_hbox.add_spacer(false)

	status_tool_label = Label.new()
	status_tool_label.text = "Tool: Paint"
	status_tool_label.add_theme_font_size_override("font_size", 10)
	bottom_hbox.add_child(status_tool_label)

	bottom_hbox.add_spacer(false)

	status_asset_label = Label.new()
	status_asset_label.text = "Asset: grass"
	status_asset_label.add_theme_font_size_override("font_size", 10)
	bottom_hbox.add_child(status_asset_label)

	bottom_hbox.add_spacer(false)

	status_zoom_label = Label.new()
	status_zoom_label.text = "Zoom: 150%"
	status_zoom_label.add_theme_font_size_override("font_size", 10)
	bottom_hbox.add_child(status_zoom_label)

	bottom_hbox.add_spacer(false)

	status_selection_label = Label.new()
	status_selection_label.text = "Selected: None"
	status_selection_label.add_theme_font_size_override("font_size", 10)
	bottom_hbox.add_child(status_selection_label)

	bottom_hbox.add_spacer(false)

	status_changes_label = Label.new()
	status_changes_label.text = "Changes: 0"
	status_changes_label.add_theme_font_size_override("font_size", 10)
	bottom_hbox.add_child(status_changes_label)

	bottom_hbox.add_spacer(false)

	validation_status_label = Label.new()
	validation_status_label.text = "Validation: OK"
	validation_status_label.modulate = Color(0.4, 0.9, 0.4)
	validation_status_label.add_theme_font_size_override("font_size", 10)
	bottom_hbox.add_child(validation_status_label)

	# Graph Dialog Instance
	graph_dialog = GRAPH_DIALOG_SCRIPT.new()
	add_child(graph_dialog)

	# Connect canvas signals
	canvas.status_updated.connect(_on_canvas_status_updated)
	canvas.map_modified.connect(_on_map_modified)
	selection.selection_changed.connect(_on_selection_changed)

	_populate_world_dropdown()

func _build_tool_sidebar(container: VBoxContainer) -> void:
	var tools_lbl = Label.new()
	tools_lbl.text = "TOOLS"
	tools_lbl.add_theme_font_size_override("font_size", 11)
	tools_lbl.modulate = Color(0.7, 0.7, 0.7)
	container.add_child(tools_lbl)

	tool_buttons[WorldCanvas.ToolMode.SELECT] = _add_sidebar_tool_btn(container, "🖱 Select [1]", WorldCanvas.ToolMode.SELECT, "Select and move entities. Shortcut: 1")
	tool_buttons[WorldCanvas.ToolMode.BRUSH] = _add_sidebar_tool_btn(container, "🖌 Paint [2]", WorldCanvas.ToolMode.BRUSH, "Paint selected tile onto the map. Shortcut: 2")
	tool_buttons[WorldCanvas.ToolMode.ERASER] = _add_sidebar_tool_btn(container, "🧹 Erase [3]", WorldCanvas.ToolMode.ERASER, "Remove tiles or entities from map. Shortcut: 3")
	tool_buttons[WorldCanvas.ToolMode.FILL] = _add_sidebar_tool_btn(container, "🪣 Fill [4]", WorldCanvas.ToolMode.FILL, "Flood fill contiguous tiles. Shortcut: 4")
	tool_buttons[WorldCanvas.ToolMode.RECTANGLE] = _add_sidebar_tool_btn(container, "▭ Rect [5]", WorldCanvas.ToolMode.RECTANGLE, "Paint rectangular area. Shortcut: 5")
	tool_buttons[WorldCanvas.ToolMode.LINE] = _add_sidebar_tool_btn(container, "╱ Line", WorldCanvas.ToolMode.LINE, "Paint straight line between points.")
	tool_buttons[WorldCanvas.ToolMode.SCATTER] = _add_sidebar_tool_btn(container, "✨ Scatter", WorldCanvas.ToolMode.SCATTER, "Randomly distribute selected asset.")
	tool_buttons[WorldCanvas.ToolMode.TRANSITION] = _add_sidebar_tool_btn(container, "🚪 Transition", WorldCanvas.ToolMode.TRANSITION, "Create/edit world transition point.")

	var sep = HSeparator.new()
	container.add_child(sep)

	var ent_lbl = Label.new()
	ent_lbl.text = "ENTITIES"
	ent_lbl.add_theme_font_size_override("font_size", 11)
	ent_lbl.modulate = Color(0.7, 0.7, 0.7)
	container.add_child(ent_lbl)

	var spawn_btn = Button.new()
	spawn_btn.text = "📍 Spawn"
	spawn_btn.tooltip_text = "Set player spawn location"
	spawn_btn.add_theme_font_size_override("font_size", 11)
	spawn_btn.pressed.connect(_on_set_spawn_tool)
	container.add_child(spawn_btn)

	var trans_btn = Button.new()
	trans_btn.text = "🚪 Transition"
	trans_btn.tooltip_text = "Add world exit / portal transition point"
	trans_btn.add_theme_font_size_override("font_size", 11)
	trans_btn.pressed.connect(_on_add_transition)
	container.add_child(trans_btn)

	var npc_btn = Button.new()
	npc_btn.text = "👤 NPC Point"
	npc_btn.tooltip_text = "Place an NPC location anchor"
	npc_btn.add_theme_font_size_override("font_size", 11)
	npc_btn.pressed.connect(_on_add_npc_point)
	container.add_child(npc_btn)

	var graph_btn = Button.new()
	graph_btn.text = "🗺 Graph"
	graph_btn.tooltip_text = "Open world transition map graph"
	graph_btn.add_theme_font_size_override("font_size", 11)
	graph_btn.pressed.connect(_on_open_graph_dialog)
	container.add_child(graph_btn)

	var sep2 = HSeparator.new()
	container.add_child(sep2)

	var opt_lbl = Label.new()
	opt_lbl.text = "LAYER"
	opt_lbl.add_theme_font_size_override("font_size", 11)
	opt_lbl.modulate = Color(0.7, 0.7, 0.7)
	container.add_child(opt_lbl)

	layer_opt = OptionButton.new()
	layer_opt.add_item("GROUND", 0)
	layer_opt.add_item("TERRAIN", 1)
	layer_opt.add_item("OBJECT", 2)
	layer_opt.add_item("DECORATION", 3)
	layer_opt.add_item("NPC", 4)
	layer_opt.add_theme_font_size_override("font_size", 11)
	layer_opt.item_selected.connect(func(idx): if canvas: canvas.active_layer_name = layer_opt.get_item_text(idx))
	container.add_child(layer_opt)

func _add_sidebar_tool_btn(container: VBoxContainer, text: String, mode: WorldCanvas.ToolMode, tooltip_msg: String = "") -> Button:
	var btn = Button.new()
	btn.text = text
	btn.tooltip_text = tooltip_msg
	btn.add_theme_font_size_override("font_size", 11)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): _set_tool(mode))
	container.add_child(btn)
	return btn

func _build_layers_tab(container: VBoxContainer) -> void:
	var layers = ["GROUND", "TERRAIN", "OBJECT", "DECORATION", "NPC"]
	for l in layers:
		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = l
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		var vis_check = CheckBox.new()
		vis_check.text = "👁"
		vis_check.tooltip_text = "Toggle Layer Visibility"
		vis_check.button_pressed = true
		vis_check.toggled.connect(func(v): _set_layer_visible(l, v))
		hbox.add_child(vis_check)

		var lock_check = CheckBox.new()
		lock_check.text = "🔒"
		lock_check.tooltip_text = "Lock Layer Against Edits"
		lock_check.button_pressed = false
		lock_check.toggled.connect(func(v): _set_layer_locked(l, v))
		hbox.add_child(lock_check)

		container.add_child(hbox)

func _set_layer_visible(layer_name: String, is_vis: bool) -> void:
	for l in current_world_data.get("layers", []):
		if l.get("name") == layer_name:
			l["visible"] = is_vis
			break
	if canvas: canvas.queue_redraw()

func _set_layer_locked(layer_name: String, is_locked: bool) -> void:
	for l in current_world_data.get("layers", []):
		if l.get("name") == layer_name:
			l["locked"] = is_locked
			break

func _populate_world_dropdown() -> void:
	if not world_option: return
	world_option.clear()

	var stable_ids: Array[String] = []
	if editor_service and editor_service.data_service:
		stable_ids = editor_service.data_service.get_all_stable_ids("world.")

	var worlds = _available_worlds.duplicate()
	for s_id in stable_ids:
		var w_name = s_id.replace("world.", "")
		if not worlds.has(w_name):
			worlds.append(w_name)

	for i in range(worlds.size()):
		var w = worlds[i]
		world_option.add_item(w.capitalize(), i)
		world_option.set_item_metadata(i, w)
		if w == current_world_id:
			world_option.selected = i

func _load_world(world_id: String) -> void:
	current_world_id = world_id
	var stable_id = "world." + world_id

	if editor_service and editor_service.data_service:
		current_world_data = editor_service.data_service.get_resolved_object(stable_id)

	if current_world_data.is_empty():
		var path = "res://data/worlds/%s.json" % world_id
		current_world_data = SERIALIZER_SCRIPT.load_world(path)

	if canvas:
		if not world_history: world_history = HISTORY_SCRIPT.new()
		canvas.setup(current_world_data, world_history, selection, palette)

	if inspector:
		if inspector.has_method("clear_inspector"):
			inspector.clear_inspector()
		elif inspector.has_method("clear_inspection"):
			inspector.clear_inspection()

	if status_world_label:
		status_world_label.text = "World: " + world_id.capitalize()

	if right_dock:
		var w_spin = right_dock.find_child("WidthSpin", true, false)
		var h_spin = right_dock.find_child("HeightSpin", true, false)
		if w_spin: w_spin.value = int(current_world_data.get("width", 32))
		if h_spin: h_spin.value = int(current_world_data.get("height", 24))

	_update_tool_highlights()
	world_changed.emit(world_id)

func _on_world_selected(idx: int) -> void:
	var w = str(world_option.get_item_metadata(idx))
	if w != "" and w != current_world_id:
		_load_world(w)

const TOOL_NAMES = {
	WorldCanvas.ToolMode.SELECT: "SELECT",
	WorldCanvas.ToolMode.BRUSH: "BRUSH",
	WorldCanvas.ToolMode.ERASER: "ERASER",
	WorldCanvas.ToolMode.RECTANGLE: "RECTANGLE",
	WorldCanvas.ToolMode.FILL: "FILL",
	WorldCanvas.ToolMode.LINE: "LINE",
	WorldCanvas.ToolMode.SCATTER: "SCATTER",
	WorldCanvas.ToolMode.TRANSITION: "TRANSITION"
}

func _set_tool(mode: WorldCanvas.ToolMode) -> void:
	if canvas:
		canvas.set_tool_mode(mode)
	_update_tool_highlights()
	if status_tool_label:
		status_tool_label.text = "Tool: " + TOOL_NAMES.get(mode, "SELECT")


func _update_tool_highlights() -> void:
	var active_mode = canvas.current_tool if canvas else WorldCanvas.ToolMode.BRUSH
	for m in tool_buttons.keys():
		var btn = tool_buttons[m]
		if btn:
			if m == active_mode:
				btn.modulate = Color(1.0, 0.95, 0.5)
			else:
				btn.modulate = Color(1.0, 1.0, 1.0)

func _on_palette_asset_selected(asset_info: Dictionary) -> void:
	var aid = str(asset_info.get("id", "none"))
	var aname = str(asset_info.get("name", aid.capitalize()))
	var atype = str(asset_info.get("type", "terrain"))
	if status_asset_label:
		if atype in ["terrain", "tile"]:
			status_asset_label.text = "Terrain: " + aname
		else:
			status_asset_label.text = "Asset: " + aname
	_set_tool(WorldCanvas.ToolMode.BRUSH)

func _on_set_spawn_tool() -> void:
	_set_tool(WorldCanvas.ToolMode.SELECT)
	if canvas and current_world_data:
		var p = canvas.hovered_tile
		current_world_data["spawn"] = [p.x, p.y]
		_on_map_modified()

func _on_add_transition() -> void:
	if not current_world_data.has("transitions"):
		current_world_data["transitions"] = []
	var pos = canvas.hovered_tile if canvas else Vector2i(0, 0)
	var new_tr = {
		"id": "trans_%d_%d" % [pos.x, pos.y],
		"name": "To Town",
		"position": [pos.x, pos.y],
		"target_world": "town",
		"target_spawn": "default",
		"direction": "north"
	}
	current_world_data["transitions"].append(new_tr)
	_on_map_modified()

func _on_add_npc_point() -> void:
	if not current_world_data.has("objects"):
		current_world_data["objects"] = []
	var pos = canvas.hovered_tile if canvas else Vector2i(0, 0)
	var npc_pt = {
		"instance_id": "npc_pt_%d_%d" % [pos.x, pos.y],
		"asset_id": "npc_waypoint",
		"name": "NPC Waypoint",
		"position": [pos.x, pos.y],
		"layer": "NPC",
		"properties": {
			"npc_id": "rowan",
			"activity": "wander"
		}
	}
	current_world_data["objects"].append(npc_pt)
	_on_map_modified()

func _on_open_graph_dialog() -> void:
	if graph_dialog:
		graph_dialog.populate_graph()
		graph_dialog.popup_centered(Vector2i(700, 500))

func _on_playtest_pressed() -> void:
	playtest_requested.emit(current_world_id)
	if editor_service:
		editor_service.start_test_preview()

func _on_save_overrides() -> void:
	if editor_service:
		editor_service.save_changes()

func _on_reset_to_default() -> void:
	if editor_service and editor_service.data_service:
		editor_service.data_service.restore_default("world." + current_world_id, "", true)
	_load_world(current_world_id)

func _on_undo() -> void:
	if editor_service:
		editor_service.undo()
	elif world_history:
		world_history.undo()
	if canvas: canvas.queue_redraw()

func _on_redo() -> void:
	if editor_service:
		editor_service.redo()
	elif world_history:
		world_history.redo()
	if canvas: canvas.queue_redraw()

func _on_toggle_side_panels() -> void:
	if left_sidebar_container and left_sidebar_container.get_parent():
		var p1 = left_sidebar_container.get_parent() as Control
		p1.visible = not p1.visible
	if right_dock and right_dock.get_parent():
		var p2 = right_dock.get_parent() as Control
		p2.visible = not p2.visible

func _on_canvas_status_updated(info: Dictionary) -> void:
	if status_coord_label:
		status_coord_label.text = "Coord: (%d, %d)" % [info.get("x", 0), info.get("y", 0)]
	if status_zoom_label:
		status_zoom_label.text = "Zoom: %d%%" % int(info.get("zoom", 100))
	if btn_zoom_reset:
		btn_zoom_reset.text = "%d%%" % int(info.get("zoom", 100))

func _on_map_modified() -> void:
	_is_dirty = true
	var stable_id = "world." + current_world_id
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override(stable_id, "tiles", current_world_data.get("tiles", []), false)
		editor_service.data_service.set_staged_override(stable_id, "objects", current_world_data.get("objects", []), false)
		editor_service.data_service.set_staged_override(stable_id, "transitions", current_world_data.get("transitions", []), false)
		editor_service.data_service.set_staged_override(stable_id, "spawn", current_world_data.get("spawn", [16, 12]), false)
	if status_changes_label:
		var count = editor_service.data_service.get_change_count() if editor_service else 1
		status_changes_label.text = "Changes: %d" % count
	panel_dirtied.emit()

func _on_selection_changed(arg1: Variant = null, arg2: Variant = null) -> void:
	var items: Array = []
	if arg2 is Array:
		items = arg2
	elif arg1 is Array:
		items = arg1
	if status_selection_label:
		if items.is_empty():
			status_selection_label.text = "Selected: None"
		elif items.size() == 1:
			status_selection_label.text = "Selected: %s" % items[0].get("instance_id", "Object")
		else:
			status_selection_label.text = "Selected: %d objects" % items.size()

	if inspector:
		inspector.inspect_selection(items)
	if not items.is_empty() and right_dock:
		right_dock.current_tab = 1 # Switch to Inspector tab automatically


func _on_inspector_property_changed(instance_id: String, prop_key: String, new_val: Variant) -> void:
	if not current_world_data.has("objects"): return
	for o in current_world_data["objects"]:
		if o.get("instance_id") == instance_id:
			if not o.has("properties"): o["properties"] = {}
			o["properties"][prop_key] = new_val
			break
	_on_map_modified()
	if canvas: canvas.queue_redraw()

func copy_selected() -> void:
	var sel = selection.get_selected_items() if selection else []
	if not sel.is_empty():
		clipboard_object = sel[0].duplicate(true)

func paste_copied() -> void:
	if clipboard_object.is_empty(): return
	var new_obj = clipboard_object.duplicate(true)
	var pos = canvas.hovered_tile if canvas else Vector2i(0, 0)
	new_obj["position"] = [pos.x, pos.y]
	new_obj["instance_id"] = "%s_copy_%d" % [new_obj.get("instance_id", "obj"), int(Time.get_unix_time_from_system() * 1000) % 10000]
	if not current_world_data.has("objects"):
		current_world_data["objects"] = []
	current_world_data["objects"].append(new_obj)
	_on_map_modified()

func duplicate_selected() -> void:
	copy_selected()
	paste_copied()

func delete_selected() -> void:
	if not selection: return
	var sel = selection.get_selected_items()
	if sel.is_empty() or not current_world_data.has("objects"): return
	for item in sel:
		current_world_data["objects"].erase(item)
	selection.clear_selection()
	_on_map_modified()

func reset_world_to_default() -> void:
	_on_reset_to_default()

func validate() -> Dictionary:
	var issues = VALIDATOR_SCRIPT.validate_world(current_world_data)
	var errs: Array[String] = []
	for i in issues:
		if i.severity == VALIDATOR_SCRIPT.Severity.ERROR:
			errs.append(i.message)
	return {
		"valid": errs.is_empty(),
		"errors": errs,
		"issues": issues
	}

func focus_asset_for_placement(asset_id: String) -> void:
	var clean_id = asset_id.trim_prefix("tile.").trim_prefix("prop.").trim_prefix("building.")
	if palette and palette.has_method("select_asset"):
		palette.select_asset(clean_id)
	else:
		_on_palette_asset_selected({ "id": clean_id })
	_set_tool(WorldCanvas.ToolMode.BRUSH)


## Public programmatic and UI authoring entry point for creating new Worlds (Phase 36)
func create_new_world(world_id: String, display_name: String = "", width: int = 32, height: int = 24, bg_tile: String = "grass") -> Dictionary:
	var clean_id = world_id.strip_edges().to_lower().replace(" ", "_").trim_prefix("world.")
	if clean_id == "": clean_id = "custom_world_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	var title = display_name if display_name != "" else clean_id.capitalize().replace("_", " ")
	
	var new_data = SERIALIZER_SCRIPT.create_empty_world(width, height, clean_id, title)
	new_data["id"] = clean_id
	new_data["npc_spawns"] = []
	
	if new_data.has("tiles") and typeof(new_data["tiles"]) == TYPE_ARRAY:
		for t in new_data["tiles"]:
			if typeof(t) == TYPE_DICTIONARY:
				t["type"] = bg_tile
				
	if editor_service and editor_service.data_service:
		editor_service.data_service.create_entity("world." + clean_id, new_data)
		
	if not _available_worlds.has(clean_id):
		_available_worlds.append(clean_id)
	_populate_world_dropdown()
	_load_world(clean_id)
	panel_dirtied.emit()
	return new_data

## Places an NPC spawn point on the world map
func place_npc(npc_id: String, grid_pos: Vector2i, facing: String = "down") -> void:
	var clean_npc = npc_id.trim_prefix("npc.")
	if not current_world_data.has("npc_spawns"):
		current_world_data["npc_spawns"] = []
		
	var spawns: Array = current_world_data["npc_spawns"].duplicate(true)
	var found = false
	for s in spawns:
		if typeof(s) == TYPE_DICTIONARY and str(s.get("npc_id", "")) == clean_npc:
			s["position"] = [grid_pos.x, grid_pos.y]
			s["facing"] = facing
			found = true
			break
	if not found:
		spawns.append({
			"npc_id": clean_npc,
			"position": [grid_pos.x, grid_pos.y],
			"facing": facing
		})
	current_world_data["npc_spawns"] = spawns
		
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("world." + current_world_id, "npc_spawns", spawns)
		
	if canvas:
		canvas.queue_redraw()
	panel_dirtied.emit()
