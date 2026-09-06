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
const ASSET_IMPORT_DIALOG_SCRIPT = preload("res://editor/world_builder/asset_import_dialog.gd")

signal world_changed(world_id: String)
signal playtest_requested(world_id: String)

var current_world_id: String = "farm"
var current_world_data: Dictionary = {}
var asset_import_dialog: AssetImportDialog

# Top Bar
var world_option: OptionButton
var btn_zoom_reset: Button
var top_w_spin: SpinBox
var top_h_spin: SpinBox

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
var transitions_vbox: VBoxContainer

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
	if palette:
		palette.refresh_assets_list()
		palette._populate_palette()
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
	top_bar.custom_minimum_size = Vector2(0, 36)
	top_bar.z_index = 5
	main_vbox.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 6)
	top_bar.add_child(top_hbox)

	var title_lbl = Label.new()
	title_lbl.text = "🌍 World Editor"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.modulate = Color(0.92, 0.94, 0.98)
	top_hbox.add_child(title_lbl)

	var sep_w = VSeparator.new()
	top_hbox.add_child(sep_w)

	var world_lbl = Label.new()
	world_lbl.text = "World:"
	world_lbl.add_theme_font_size_override("font_size", 12)
	top_hbox.add_child(world_lbl)

	world_option = OptionButton.new()
	world_option.custom_minimum_size = Vector2(125, 26)
	world_option.add_theme_font_size_override("font_size", 12)
	world_option.item_selected.connect(_on_world_selected)
	top_hbox.add_child(world_option)

	var sep_size = VSeparator.new()
	top_hbox.add_child(sep_size)

	var size_lbl = Label.new()
	size_lbl.text = "Size:"
	size_lbl.add_theme_font_size_override("font_size", 12)
	top_hbox.add_child(size_lbl)

	top_w_spin = SpinBox.new()
	top_w_spin.min_value = 8
	top_w_spin.max_value = 512
	top_w_spin.value = 32
	top_w_spin.custom_minimum_size = Vector2(70, 26)
	top_w_spin.tooltip_text = "Map Width in Tiles"
	top_hbox.add_child(top_w_spin)

	var x_lbl = Label.new()
	x_lbl.text = "×"
	x_lbl.add_theme_font_size_override("font_size", 12)
	top_hbox.add_child(x_lbl)

	top_h_spin = SpinBox.new()
	top_h_spin.min_value = 8
	top_h_spin.max_value = 512
	top_h_spin.value = 24
	top_h_spin.custom_minimum_size = Vector2(70, 26)
	top_h_spin.tooltip_text = "Map Height in Tiles"
	top_hbox.add_child(top_h_spin)

	var btn_apply_size = Button.new()
	btn_apply_size.text = "📐 Resize"
	btn_apply_size.tooltip_text = "Apply new map dimensions (expands or shrinks map grid)"
	btn_apply_size.custom_minimum_size = Vector2(0, 26)
	btn_apply_size.add_theme_font_size_override("font_size", 12)
	btn_apply_size.pressed.connect(_on_apply_top_resize)
	top_hbox.add_child(btn_apply_size)

	var preset_opt = OptionButton.new()
	preset_opt.custom_minimum_size = Vector2(100, 26)
	preset_opt.add_theme_font_size_override("font_size", 11)
	preset_opt.add_item("Presets...", 0)
	preset_opt.add_item("32 × 24 (Small)", 1)
	preset_opt.add_item("48 × 36 (Medium)", 2)
	preset_opt.add_item("64 × 48 (Large)", 3)
	preset_opt.add_item("100 × 100 (Huge)", 4)
	preset_opt.item_selected.connect(func(idx):
		match idx:
			1: _set_and_apply_size(32, 24)
			2: _set_and_apply_size(48, 36)
			3: _set_and_apply_size(64, 48)
			4: _set_and_apply_size(100, 100)
		preset_opt.selected = 0
	)
	top_hbox.add_child(preset_opt)

	var sep_v = VSeparator.new()
	top_hbox.add_child(sep_v)

	# --- Viewport Navigation Controls ---
	var btn_zoom_out = Button.new()
	btn_zoom_out.text = "−"
	btn_zoom_out.tooltip_text = "Zoom Out (Wheel Down)"
	btn_zoom_out.custom_minimum_size = Vector2(26, 26)
	btn_zoom_out.add_theme_font_size_override("font_size", 13)
	btn_zoom_out.pressed.connect(func(): if canvas: canvas.zoom_out())
	top_hbox.add_child(btn_zoom_out)

	btn_zoom_reset = Button.new()
	btn_zoom_reset.text = "100%"
	btn_zoom_reset.tooltip_text = "Reset Zoom to 100%"
	btn_zoom_reset.custom_minimum_size = Vector2(44, 26)
	btn_zoom_reset.add_theme_font_size_override("font_size", 12)
	btn_zoom_reset.pressed.connect(func(): if canvas: canvas.reset_zoom())
	top_hbox.add_child(btn_zoom_reset)

	var btn_zoom_in = Button.new()
	btn_zoom_in.text = "+"
	btn_zoom_in.tooltip_text = "Zoom In (Wheel Up)"
	btn_zoom_in.custom_minimum_size = Vector2(26, 26)
	btn_zoom_in.add_theme_font_size_override("font_size", 13)
	btn_zoom_in.pressed.connect(func(): if canvas: canvas.zoom_in())
	top_hbox.add_child(btn_zoom_in)

	var btn_fit = Button.new()
	btn_fit.text = "Fit"
	btn_fit.tooltip_text = "Fit entire map in viewport (Home)"
	btn_fit.custom_minimum_size = Vector2(36, 26)
	btn_fit.add_theme_font_size_override("font_size", 12)
	btn_fit.pressed.connect(func(): if canvas: canvas.fit_to_screen())
	top_hbox.add_child(btn_fit)

	var btn_center = Button.new()
	btn_center.text = "⊙"
	btn_center.tooltip_text = "Center view on map (F)"
	btn_center.custom_minimum_size = Vector2(26, 26)
	btn_center.add_theme_font_size_override("font_size", 13)
	btn_center.pressed.connect(func(): if canvas: canvas.center_map())
	top_hbox.add_child(btn_center)

	var spacer_top = Control.new()
	spacer_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer_top)

	# --- Actions: Undo / Redo / Save / Reset / Playtest ---
	var undo_btn = Button.new()
	undo_btn.text = "↶ Undo"
	undo_btn.tooltip_text = "Undo last action (Ctrl+Z)"
	undo_btn.custom_minimum_size = Vector2(0, 26)
	undo_btn.add_theme_font_size_override("font_size", 12)
	undo_btn.pressed.connect(_on_undo)
	top_hbox.add_child(undo_btn)

	var redo_btn = Button.new()
	redo_btn.text = "↷ Redo"
	redo_btn.tooltip_text = "Redo last action (Ctrl+Y)"
	redo_btn.custom_minimum_size = Vector2(0, 26)
	redo_btn.add_theme_font_size_override("font_size", 12)
	redo_btn.pressed.connect(_on_redo)
	top_hbox.add_child(redo_btn)

	var save_btn = Button.new()
	save_btn.text = "💾 Save"
	save_btn.tooltip_text = "Save world modifications"
	save_btn.custom_minimum_size = Vector2(0, 26)
	save_btn.add_theme_font_size_override("font_size", 12)
	save_btn.pressed.connect(_on_save_overrides)
	top_hbox.add_child(save_btn)

	var reset_btn = Button.new()
	reset_btn.text = "↺ Reset"
	reset_btn.tooltip_text = "Reset world to base defaults"
	reset_btn.custom_minimum_size = Vector2(0, 26)
	reset_btn.add_theme_font_size_override("font_size", 12)
	reset_btn.pressed.connect(_on_reset_to_default)
	top_hbox.add_child(reset_btn)

	var sync_assets_btn = Button.new()
	sync_assets_btn.text = "🔄 Sync Assets"
	sync_assets_btn.tooltip_text = "Scan all asset folders & auto-register new PNG/Audio files"
	sync_assets_btn.custom_minimum_size = Vector2(0, 26)
	sync_assets_btn.add_theme_font_size_override("font_size", 12)
	sync_assets_btn.pressed.connect(_on_sync_assets_pressed)
	top_hbox.add_child(sync_assets_btn)

	var playtest_btn = Button.new()
	playtest_btn.text = "▶ Test World"
	playtest_btn.tooltip_text = "Launch live playtest for this world"
	playtest_btn.custom_minimum_size = Vector2(0, 26)
	playtest_btn.add_theme_font_size_override("font_size", 12)
	playtest_btn.pressed.connect(_on_playtest_pressed)
	top_hbox.add_child(playtest_btn)

	# =========================================================================
	# 2. MAIN 3-ZONE WORKSPACE (Sidebar | Dominant Canvas | Inspector Dock)
	# =========================================================================
	var left_split = HSplitContainer.new()
	left_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_split.clip_contents = true
	main_vbox.add_child(left_split)

	# -------------------------------------------------------------------------
	# 2A. LEFT TOOL SIDEBAR (Compact palette: Tools, Entities, Options)
	# -------------------------------------------------------------------------
	var sidebar_panel = PanelContainer.new()
	sidebar_panel.custom_minimum_size = Vector2(145, 0)
	sidebar_panel.z_index = 5
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
	right_split.clip_contents = true
	left_split.add_child(right_split)

	canvas_container = PanelContainer.new()
	canvas_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_container.clip_contents = true
	right_split.add_child(canvas_container)

	var canvas_vbox = VBoxContainer.new()
	canvas_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_vbox.clip_contents = true
	canvas_container.add_child(canvas_vbox)

	# Minimal Floating Canvas Overlay Bar
	var canvas_top_overlay = HBoxContainer.new()
	canvas_vbox.add_child(canvas_top_overlay)

	grid_toggle = CheckBox.new()
	grid_toggle.text = "Grid"
	grid_toggle.button_pressed = true
	UIConstants.apply_checkbox_style(grid_toggle)
	grid_toggle.toggled.connect(func(v): if canvas: canvas.show_grid_lines = v; canvas.queue_redraw())
	canvas_top_overlay.add_child(grid_toggle)

	collision_toggle = CheckBox.new()
	collision_toggle.text = "Collision"
	UIConstants.apply_checkbox_style(collision_toggle)
	collision_toggle.toggled.connect(func(v): if canvas: canvas.show_collision_debug = v; canvas.queue_redraw())
	canvas_top_overlay.add_child(collision_toggle)

	nav_toggle = CheckBox.new()
	nav_toggle.text = "Navigation"
	UIConstants.apply_checkbox_style(nav_toggle)
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
	canvas.clip_contents = true
	canvas_vbox.add_child(canvas)

	# -------------------------------------------------------------------------
	# 2C. RIGHT TABBED DOCK (Assets | Inspector | Layers)
	# -------------------------------------------------------------------------
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(380, 0)
	right_panel.z_index = 5
	right_split.add_child(right_panel)

	right_dock = TabContainer.new()
	right_dock.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_dock.add_theme_font_size_override("font_size", 14)
	right_panel.add_child(right_dock)

	# Tab 1: Assets Browser
	palette = PALETTE_SCRIPT.new()
	palette.name = "[Asset] Assets"
	palette.asset_selected.connect(_on_palette_asset_selected)
	palette.customize_asset_requested.connect(_on_palette_customize_asset_requested)
	right_dock.add_child(palette)

	# Tab 2: Inspector
	inspector = INSPECTOR_SCRIPT.new()
	inspector.name = "[Inspector] Inspector"
	inspector.property_changed.connect(_on_inspector_property_changed)
	right_dock.add_child(inspector)

	# Tab 3: Layers
	var layer_tab = ScrollContainer.new()
	layer_tab.name = "[Layers]  Layers"
	right_dock.add_child(layer_tab)

	layers_vbox = VBoxContainer.new()
	layers_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer_tab.add_child(layers_vbox)
	_build_layers_tab(layers_vbox)

	# Tab 4: World Settings
	var ws_tab = ScrollContainer.new()
	ws_tab.name = "[Settings] Settings"
	right_dock.add_child(ws_tab)
	var ws_vbox = VBoxContainer.new()
	ws_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ws_vbox.add_theme_constant_override("separation", 8)
	ws_tab.add_child(ws_vbox)
	
	var ws_w_lbl = Label.new()
	ws_w_lbl.text = "Width (Genişlik):"
	ws_w_lbl.add_theme_font_size_override("font_size", 12)
	ws_vbox.add_child(ws_w_lbl)
	var ws_w_spin = SpinBox.new()
	ws_w_spin.min_value = 16
	ws_w_spin.max_value = 4096
	ws_w_spin.value = 32
	ws_w_spin.custom_minimum_size = Vector2(0, 30)
	ws_w_spin.name = "WidthSpin"
	ws_vbox.add_child(ws_w_spin)
	
	var ws_h_lbl = Label.new()
	ws_h_lbl.text = "Height (Yükseklik):"
	ws_h_lbl.add_theme_font_size_override("font_size", 12)
	ws_vbox.add_child(ws_h_lbl)
	var ws_h_spin = SpinBox.new()
	ws_h_spin.min_value = 16
	ws_h_spin.max_value = 4096
	ws_h_spin.value = 24
	ws_h_spin.custom_minimum_size = Vector2(0, 30)
	ws_h_spin.name = "HeightSpin"
	ws_vbox.add_child(ws_h_spin)
	
	var ws_apply_btn = Button.new()
	ws_apply_btn.text = "📐 Apply Resize (Boyutu Uygula)"
	ws_apply_btn.add_theme_font_size_override("font_size", 12)
	ws_apply_btn.custom_minimum_size = Vector2(0, 32)
	ws_apply_btn.pressed.connect(func():
		var nw = int(ws_w_spin.value)
		var nh = int(ws_h_spin.value)
		if canvas:
			canvas.resize_world(nw, nh)
	)
	ws_vbox.add_child(ws_apply_btn)

	# Tab 5: Transitions
	var tr_tab = ScrollContainer.new()
	tr_tab.name = "[Transitions] 🚪 Transitions"
	right_dock.add_child(tr_tab)
	transitions_vbox = VBoxContainer.new()
	transitions_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tr_tab.add_child(transitions_vbox)
	_build_transitions_tab(transitions_vbox)

	# =========================================================================
	# 3. BOTTOM STATUS BAR (Informative, compact badges)
	# =========================================================================
	var bottom_bar = PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 24)
	bottom_bar.z_index = 5
	main_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_bar.add_child(bottom_hbox)

	status_coord_label = Label.new()
	status_coord_label.text = "Coord: (0, 0)"
	status_coord_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_coord_label)

	bottom_hbox.add_spacer(false)

	status_world_label = Label.new()
	status_world_label.text = "World: Farm"
	status_world_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_world_label)

	bottom_hbox.add_spacer(false)

	status_tool_label = Label.new()
	status_tool_label.text = "Tool: Paint"
	status_tool_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_tool_label)

	bottom_hbox.add_spacer(false)

	status_asset_label = Label.new()
	status_asset_label.text = "Asset: grass"
	status_asset_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_asset_label)

	bottom_hbox.add_spacer(false)

	status_zoom_label = Label.new()
	status_zoom_label.text = "Zoom: 100%"
	status_zoom_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_zoom_label)

	bottom_hbox.add_spacer(false)

	status_selection_label = Label.new()
	status_selection_label.text = "Selected: None"
	status_selection_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_selection_label)

	bottom_hbox.add_spacer(false)

	status_changes_label = Label.new()
	status_changes_label.text = "Changes: 0"
	status_changes_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_changes_label)

	bottom_hbox.add_spacer(false)

	validation_status_label = Label.new()
	validation_status_label.text = "Validation: OK"
	validation_status_label.modulate = Color(0.4, 0.9, 0.4)
	validation_status_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(validation_status_label)

	# Graph Dialog Instance
	graph_dialog = GRAPH_DIALOG_SCRIPT.new()
	add_child(graph_dialog)

	# Asset Import Dialog Instance
	asset_import_dialog = ASSET_IMPORT_DIALOG_SCRIPT.new()
	add_child(asset_import_dialog)
	asset_import_dialog.asset_imported.connect(_on_asset_imported)

	# Window Drag and Drop Connection
	call_deferred("_setup_window_file_drop")

	# Connect canvas signals
	canvas.status_updated.connect(_on_canvas_status_updated)
	canvas.map_modified.connect(_on_map_modified)
	canvas.transition_created.connect(_on_transition_created)
	selection.selection_changed.connect(_on_selection_changed)

	_populate_world_dropdown()

func _build_tool_sidebar(container: VBoxContainer) -> void:
	var tools_lbl = Label.new()
	tools_lbl.text = "TOOLS"
	tools_lbl.add_theme_font_size_override("font_size", 12)
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
	ent_lbl.add_theme_font_size_override("font_size", 12)
	ent_lbl.modulate = Color(0.7, 0.7, 0.7)
	container.add_child(ent_lbl)

	var spawn_btn = Button.new()
	spawn_btn.text = "📍 Spawn"
	spawn_btn.tooltip_text = "Set player spawn location"
	spawn_btn.custom_minimum_size = Vector2(0, 26)
	spawn_btn.add_theme_font_size_override("font_size", 12)
	spawn_btn.pressed.connect(_on_set_spawn_tool)
	container.add_child(spawn_btn)

	var trans_btn = Button.new()
	trans_btn.text = "🚪 Transition"
	trans_btn.tooltip_text = "Add world exit / portal transition point"
	trans_btn.custom_minimum_size = Vector2(0, 26)
	trans_btn.add_theme_font_size_override("font_size", 12)
	trans_btn.pressed.connect(_on_add_transition)
	container.add_child(trans_btn)

	var npc_btn = Button.new()
	npc_btn.text = "👤 NPC Point"
	npc_btn.tooltip_text = "Place an NPC location anchor"
	npc_btn.custom_minimum_size = Vector2(0, 26)
	npc_btn.add_theme_font_size_override("font_size", 12)
	npc_btn.pressed.connect(_on_add_npc_point)
	container.add_child(npc_btn)

	var graph_btn = Button.new()
	graph_btn.text = "🗺 Graph"
	graph_btn.tooltip_text = "Open world transition map graph"
	graph_btn.custom_minimum_size = Vector2(0, 26)
	graph_btn.add_theme_font_size_override("font_size", 12)
	graph_btn.pressed.connect(_on_open_graph_dialog)
	container.add_child(graph_btn)

	var sep2 = HSeparator.new()
	container.add_child(sep2)

	var opt_lbl = Label.new()
	opt_lbl.text = "LAYER"
	opt_lbl.add_theme_font_size_override("font_size", 12)
	opt_lbl.modulate = Color(0.7, 0.7, 0.7)
	container.add_child(opt_lbl)

	layer_opt = OptionButton.new()
	layer_opt.add_item("GROUND", 0)
	layer_opt.add_item("TERRAIN", 1)
	layer_opt.add_item("OBJECT", 2)
	layer_opt.add_item("DECORATION", 3)
	layer_opt.add_item("NPC", 4)
	layer_opt.custom_minimum_size = Vector2(0, 26)
	layer_opt.add_theme_font_size_override("font_size", 12)
	layer_opt.item_selected.connect(func(idx): if canvas: canvas.active_layer_name = layer_opt.get_item_text(idx))
	container.add_child(layer_opt)

func _add_sidebar_tool_btn(container: VBoxContainer, text: String, mode: WorldCanvas.ToolMode, tooltip_msg: String = "") -> Button:
	var btn = Button.new()
	btn.text = text
	btn.tooltip_text = tooltip_msg
	btn.custom_minimum_size = Vector2(0, 26)
	btn.add_theme_font_size_override("font_size", 12)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): _set_tool(mode))
	container.add_child(btn)
	return btn

func _build_layers_tab(container: VBoxContainer) -> void:
	container.add_theme_constant_override("separation", 10)
	var layers = ["GROUND", "TERRAIN", "OBJECT", "DECORATION", "NPC"]
	for l in layers:
		var panel_card = PanelContainer.new()
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		panel_card.add_child(hbox)
		
		var lbl = Label.new()
		lbl.text = "  📁 " + l
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)

		var vis_check = CheckBox.new()
		vis_check.text = "👁 Visible"
		vis_check.add_theme_font_size_override("font_size", 13)
		vis_check.tooltip_text = "Toggle Layer Visibility"
		vis_check.button_pressed = true
		vis_check.toggled.connect(func(v): _set_layer_visible(l, v))
		hbox.add_child(vis_check)

		var lock_check = CheckBox.new()
		lock_check.text = "🔒 Lock"
		lock_check.add_theme_font_size_override("font_size", 13)
		lock_check.tooltip_text = "Lock Layer Against Edits"
		lock_check.button_pressed = false
		lock_check.toggled.connect(func(v): _set_layer_locked(l, v))
		hbox.add_child(lock_check)

		container.add_child(panel_card)

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

func _get_world_spawn_points(world_id: String) -> Array[String]:
	var result: Array[String] = ["default"]
	var path = "res://data/worlds/worlds.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
				var w_dict = json.data.get("worlds", {}).get(world_id, {})
				var sp = w_dict.get("spawn_points", {})
				for k in sp.keys():
					if not result.has(k):
						result.append(k)
			f.close()
	return result

func _build_transitions_tab(container: VBoxContainer) -> void:
	for c in container.get_children():
		c.queue_free()
		
	container.add_theme_constant_override("separation", 12)
		
	var header_lbl = Label.new()
	header_lbl.text = "🚪 MAP TRANSITIONS"
	header_lbl.add_theme_font_size_override("font_size", 14)
	header_lbl.modulate = Color(0.92, 0.94, 0.98)
	container.add_child(header_lbl)
	
	# Section 1: Create New Transition Panel
	var create_panel = PanelContainer.new()
	var create_vbox = VBoxContainer.new()
	create_vbox.add_theme_constant_override("separation", 10)
	create_panel.add_child(create_vbox)
	container.add_child(create_panel)
	
	var create_title = Label.new()
	create_title.text = "➕ New World Transition Connection:"
	create_title.add_theme_font_size_override("font_size", 13)
	create_title.modulate = Color(0.90, 0.92, 0.96)
	create_vbox.add_child(create_title)
	
	# 1A. Source World
	var row_src = HBoxContainer.new()
	var l_src = Label.new(); l_src.text = "From World:"; l_src.custom_minimum_size = Vector2(110, 0); l_src.add_theme_font_size_override("font_size", 13)
	row_src.add_child(l_src)
	var val_src = Label.new(); val_src.text = "🌿 " + current_world_id.capitalize(); val_src.add_theme_font_size_override("font_size", 13); val_src.modulate = Color(0.85, 0.90, 0.95)
	row_src.add_child(val_src)
	create_vbox.add_child(row_src)
	
	# 1B. Target World Selector
	var row_tgt = HBoxContainer.new()
	var l_tgt = Label.new(); l_tgt.text = "To World:"; l_tgt.custom_minimum_size = Vector2(110, 0); l_tgt.add_theme_font_size_override("font_size", 13)
	row_tgt.add_child(l_tgt)
	
	var opt_target_world = OptionButton.new()
	opt_target_world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_target_world.custom_minimum_size = Vector2(0, 34)
	opt_target_world.add_theme_font_size_override("font_size", 13)
	for widx in range(_available_worlds.size()):
		var w_name = _available_worlds[widx]
		opt_target_world.add_item(w_name.capitalize(), widx)
		opt_target_world.set_item_metadata(widx, w_name)
		if (current_world_id in ["central_town", "town"] and w_name == "farm") or (current_world_id != "central_town" and w_name == "central_town"):
			opt_target_world.selected = widx
	row_tgt.add_child(opt_target_world)
	create_vbox.add_child(row_tgt)
	
	# 1C. Target Spawn Point Selector
	var row_sp = HBoxContainer.new()
	var l_sp = Label.new(); l_sp.text = "Target Spawn:"; l_sp.custom_minimum_size = Vector2(110, 0); l_sp.add_theme_font_size_override("font_size", 13)
	row_sp.add_child(l_sp)
	
	var opt_target_spawn = OptionButton.new()
	opt_target_spawn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt_target_spawn.custom_minimum_size = Vector2(0, 34)
	opt_target_spawn.add_theme_font_size_override("font_size", 13)
	row_sp.add_child(opt_target_spawn)
	create_vbox.add_child(row_sp)
	
	var update_sp_dropdown = func():
		opt_target_spawn.clear()
		var sel_idx = opt_target_world.selected
		var target_w = str(opt_target_world.get_item_metadata(sel_idx)) if sel_idx >= 0 else "central_town"
		var spawns = _get_world_spawn_points(target_w)
		for s_idx in range(spawns.size()):
			opt_target_spawn.add_item(spawns[s_idx], s_idx)
		if opt_target_spawn.get_item_count() > 0:
			opt_target_spawn.selected = 0
			
	opt_target_world.item_selected.connect(func(_idx): update_sp_dropdown.call())
	update_sp_dropdown.call()
	
	# 1D. Line Location Selection: Border Buttons
	var l_loc = Label.new(); l_loc.text = "Quick Border Transitions (One-Click):"; l_loc.add_theme_font_size_override("font_size", 13); l_loc.modulate = Color(0.85, 0.85, 0.85)
	create_vbox.add_child(l_loc)
	
	var border_grid = GridContainer.new()
	border_grid.columns = 2
	border_grid.add_theme_constant_override("h_separation", 8)
	border_grid.add_theme_constant_override("v_separation", 8)
	create_vbox.add_child(border_grid)
	
	var get_current_target = func() -> Dictionary:
		var target_w = str(opt_target_world.get_item_metadata(opt_target_world.selected)) if opt_target_world.selected >= 0 else "central_town"
		var sp_name = opt_target_spawn.get_item_text(opt_target_spawn.selected) if opt_target_spawn.selected >= 0 else "default"
		return { "world": target_w, "spawn": sp_name }
		
	var btn_north = Button.new(); btn_north.text = "⬆ North Border Line"; btn_north.custom_minimum_size = Vector2(0, 36); btn_north.add_theme_font_size_override("font_size", 13)
	btn_north.pressed.connect(func(): var t = get_current_target.call(); _add_border_transition_with_target("north", t.world, t.spawn))
	border_grid.add_child(btn_north)
	
	var btn_south = Button.new(); btn_south.text = "⬇ South Border Line"; btn_south.custom_minimum_size = Vector2(0, 36); btn_south.add_theme_font_size_override("font_size", 13)
	btn_south.pressed.connect(func(): var t = get_current_target.call(); _add_border_transition_with_target("south", t.world, t.spawn))
	border_grid.add_child(btn_south)
	
	var btn_west = Button.new(); btn_west.text = "⬅ West Border Line"; btn_west.custom_minimum_size = Vector2(0, 36); btn_west.add_theme_font_size_override("font_size", 13)
	btn_west.pressed.connect(func(): var t = get_current_target.call(); _add_border_transition_with_target("west", t.world, t.spawn))
	border_grid.add_child(btn_west)
	
	var btn_east = Button.new(); btn_east.text = "➡ East Border Line"; btn_east.custom_minimum_size = Vector2(0, 36); btn_east.add_theme_font_size_override("font_size", 13)
	btn_east.pressed.connect(func(): var t = get_current_target.call(); _add_border_transition_with_target("east", t.world, t.spawn))
	border_grid.add_child(btn_east)
	
	var draw_hint = Label.new()
	draw_hint.text = "💡 Tip: Draw custom lines anywhere on the map by dragging with the [🚪 Transition] tool on the left toolbar."
	draw_hint.add_theme_font_size_override("font_size", 12)
	draw_hint.modulate = Color(0.65, 0.85, 1.0)
	draw_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	create_vbox.add_child(draw_hint)
	
	container.add_child(HSeparator.new())
	
	var list_lbl = Label.new()
	list_lbl.text = "ACTIVE TRANSITIONS ON THIS MAP"
	list_lbl.add_theme_font_size_override("font_size", 14)
	list_lbl.modulate = Color(0.85, 0.85, 0.85)
	container.add_child(list_lbl)
	
	var list_container = VBoxContainer.new()
	list_container.name = "TransitionListContainer"
	list_container.add_theme_constant_override("separation", 10)
	container.add_child(list_container)
	_refresh_transitions_list(list_container)

func _refresh_transitions_ui() -> void:
	if not transitions_vbox: return
	var list_container = transitions_vbox.find_child("TransitionListContainer", true, false) as VBoxContainer
	if list_container:
		_refresh_transitions_list(list_container)

func _refresh_transitions_list(list_container: VBoxContainer) -> void:
	for c in list_container.get_children():
		c.queue_free()
		
	var transitions = current_world_data.get("transitions", [])
	if transitions.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No transitions configured for this map.\nUse the presets above or drag on the map with Transition tool."
		empty_lbl.add_theme_font_size_override("font_size", 13)
		empty_lbl.modulate = Color(0.65, 0.65, 0.65)
		list_container.add_child(empty_lbl)
		return
		
	for i in range(transitions.size()):
		var tr = transitions[i]
		var card = PanelContainer.new()
		var card_vbox = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 8)
		card.add_child(card_vbox)
		
		# Row 1: Name and Delete button
		var row1 = HBoxContainer.new()
		var name_edit = LineEdit.new()
		name_edit.text = str(tr.get("name", "Transition"))
		name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_edit.custom_minimum_size = Vector2(0, 34)
		name_edit.add_theme_font_size_override("font_size", 13)
		name_edit.text_changed.connect(func(new_t):
			tr["name"] = new_t
			_on_map_modified()
			if canvas: canvas.queue_redraw()
		)
		row1.add_child(name_edit)
		
		var del_btn = Button.new()
		del_btn.text = "🗑 Delete"
		del_btn.custom_minimum_size = Vector2(65, 34)
		del_btn.add_theme_font_size_override("font_size", 12)
		del_btn.tooltip_text = "Delete Transition Line"
		del_btn.pressed.connect(func():
			current_world_data["transitions"].remove_at(i)
			_on_map_modified()
			_refresh_transitions_ui()
			if canvas: canvas.queue_redraw()
		)
		row1.add_child(del_btn)
		card_vbox.add_child(row1)
		
		# Row 2: Target World
		var row2 = HBoxContainer.new()
		var w_lbl = Label.new(); w_lbl.text = "Target World:"; w_lbl.custom_minimum_size = Vector2(100, 0); w_lbl.add_theme_font_size_override("font_size", 13)
		row2.add_child(w_lbl)
		
		var target_opt = OptionButton.new()
		target_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_opt.custom_minimum_size = Vector2(0, 34)
		target_opt.add_theme_font_size_override("font_size", 13)
		for widx in range(_available_worlds.size()):
			var w_name = _available_worlds[widx]
			target_opt.add_item(w_name.capitalize(), widx)
			target_opt.set_item_metadata(widx, w_name)
			if w_name == tr.get("target_world", ""):
				target_opt.selected = widx
		row2.add_child(target_opt)
		card_vbox.add_child(row2)
		
		# Row 3: Target Spawn Point (Dropdown)
		var row3 = HBoxContainer.new()
		var sp_lbl = Label.new(); sp_lbl.text = "Target Spawn:"; sp_lbl.custom_minimum_size = Vector2(100, 0); sp_lbl.add_theme_font_size_override("font_size", 13)
		row3.add_child(sp_lbl)
		
		var sp_opt = OptionButton.new()
		sp_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sp_opt.custom_minimum_size = Vector2(0, 34)
		sp_opt.add_theme_font_size_override("font_size", 13)
		row3.add_child(sp_opt)
		card_vbox.add_child(row3)
		
		var refresh_card_spawns = func():
			sp_opt.clear()
			var sel_target = tr.get("target_world", "central_town")
			var spawns = _get_world_spawn_points(sel_target)
			for s_idx in range(spawns.size()):
				sp_opt.add_item(spawns[s_idx], s_idx)
				if spawns[s_idx] == tr.get("target_spawn", "default"):
					sp_opt.selected = s_idx
			if sp_opt.selected < 0 and sp_opt.get_item_count() > 0:
				sp_opt.selected = 0
				
		target_opt.item_selected.connect(func(s_idx):
			tr["target_world"] = str(target_opt.get_item_metadata(s_idx))
			refresh_card_spawns.call()
			tr["target_spawn"] = sp_opt.get_item_text(sp_opt.selected) if sp_opt.selected >= 0 else "default"
			_on_map_modified()
			if canvas: canvas.queue_redraw()
		)
		
		sp_opt.item_selected.connect(func(s_idx):
			tr["target_spawn"] = sp_opt.get_item_text(s_idx)
			_on_map_modified()
			if canvas: canvas.queue_redraw()
		)
		refresh_card_spawns.call()
		
		# Row 4: Line Coordinates
		var p1 = tr.get("start_point", tr.get("from", [0, 0]))
		var p2 = tr.get("end_point", tr.get("to", p1))
		var coord_lbl = Label.new()
		coord_lbl.text = "Line Segment: [%.1f, %.1f] ➔ [%.1f, %.1f]" % [float(p1[0]), float(p1[1]), float(p2[0]), float(p2[1])]
		coord_lbl.add_theme_font_size_override("font_size", 13)
		coord_lbl.modulate = Color(0.2, 0.9, 1.0)
		card_vbox.add_child(coord_lbl)
		
		list_container.add_child(card)

func _add_border_transition(direction: String) -> void:
	var default_target = "central_town"
	if current_world_id in ["central_town", "town"]:
		default_target = "farm"
	elif current_world_id == "forest":
		default_target = "farm"
	_add_border_transition_with_target(direction, default_target, "default")

func _add_border_transition_with_target(direction: String, target_world: String, target_spawn: String) -> void:
	if not current_world_data or current_world_data.is_empty(): return
	if not current_world_data.has("transitions"): current_world_data["transitions"] = []
	
	var w = int(current_world_data.get("width", 32))
	var h = int(current_world_data.get("height", 24))
	
	var p1 = Vector2i(0, 0)
	var p2 = Vector2i(0, 0)
	match direction:
		"north":
			p1 = Vector2i(0, 0)
			p2 = Vector2i(w - 1, 0)
		"south":
			p1 = Vector2i(0, h - 1)
			p2 = Vector2i(w - 1, h - 1)
		"west":
			p1 = Vector2i(0, 0)
			p2 = Vector2i(0, h - 1)
		"east":
			p1 = Vector2i(w - 1, 0)
			p2 = Vector2i(w - 1, h - 1)
			
	var tr_id = "trans_%s_border" % direction
	current_world_data["transitions"] = current_world_data["transitions"].filter(func(t): return t.get("id") != tr_id)
	
	current_world_data["transitions"].append({
		"id": tr_id,
		"name": "To " + target_world.capitalize() + " (" + direction.capitalize() + ")",
		"from": [p1.x, p1.y],
		"to": [p2.x, p2.y],
		"target_world": target_world,
		"target_spawn": target_spawn,
		"direction": direction
	})
	_on_map_modified()
	_refresh_transitions_ui()
	if canvas: canvas.queue_redraw()

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

	_update_dimensions_display()
	_refresh_transitions_ui()
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
		var btn: Button = tool_buttons[m]
		if btn:
			btn.modulate = Color.WHITE
			if m == active_mode:
				btn.add_theme_stylebox_override("normal", UIConstants.create_active_button_stylebox())
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			else:
				btn.remove_theme_stylebox_override("normal")
				btn.remove_theme_color_override("font_color")

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

func _on_palette_customize_asset_requested(asset_id: String, _asset_info: Dictionary) -> void:
	var shell_cls = load("res://editor/ui/editor_shell.gd")
	if shell_cls and shell_cls.has_method("open_asset_in_editor"):
		shell_cls.open_asset_in_editor(asset_id)

func _on_set_spawn_tool() -> void:
	_set_tool(WorldCanvas.ToolMode.SELECT)
	if canvas and current_world_data:
		var p = canvas.hovered_tile
		current_world_data["spawn"] = [p.x, p.y]
		_on_map_modified()

func _on_add_transition() -> void:
	_set_tool(WorldCanvas.ToolMode.TRANSITION)
	if right_dock and right_dock.get_parent():
		var p2 = right_dock.get_parent() as Control
		p2.visible = true
	if right_dock:
		for i in range(right_dock.get_tab_count()):
			if "Transitions" in right_dock.get_tab_title(i):
				right_dock.current_tab = i
				break
	_refresh_transitions_ui()

func _on_transition_created(_tr: Dictionary) -> void:
	if right_dock and right_dock.get_parent():
		var p2 = right_dock.get_parent() as Control
		p2.visible = true
	if right_dock:
		for i in range(right_dock.get_tab_count()):
			if "Transitions" in right_dock.get_tab_title(i):
				right_dock.current_tab = i
				break
	_refresh_transitions_ui()

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

func _set_and_apply_size(w: int, h: int) -> void:
	if top_w_spin: top_w_spin.value = w
	if top_h_spin: top_h_spin.value = h
	_on_apply_top_resize()

func _on_apply_top_resize() -> void:
	if not top_w_spin or not top_h_spin or not canvas: return
	var nw = int(top_w_spin.value)
	var nh = int(top_h_spin.value)
	canvas.resize_world(nw, nh)
	if current_world_data:
		current_world_data["width"] = nw
		current_world_data["height"] = nh
	_on_map_modified()
	_update_dimensions_display()

func _update_dimensions_display() -> void:
	var w = int(current_world_data.get("width", 32))
	var h = int(current_world_data.get("height", 24))
	if top_w_spin: top_w_spin.set_value_no_signal(w)
	if top_h_spin: top_h_spin.set_value_no_signal(h)
	if right_dock:
		var w_spin = right_dock.find_child("WidthSpin", true, false)
		var h_spin = right_dock.find_child("HeightSpin", true, false)
		if w_spin: w_spin.set_value_no_signal(w)
		if h_spin: h_spin.set_value_no_signal(h)

func _on_save_overrides() -> void:
	if current_world_data and current_world_id != "":
		var path = "res://data/worlds/%s.json" % current_world_id
		SERIALIZER_SCRIPT.save_world(path, current_world_data)
		_update_worlds_json_dimensions(current_world_id, int(current_world_data.get("width", 32)), int(current_world_data.get("height", 24)))
	if editor_service:
		editor_service.save_changes()

func _update_worlds_json_dimensions(wid: String, w: int, h: int) -> void:
	var path = "res://data/worlds/worlds.json"
	if not FileAccess.file_exists(path): return
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return
	var json = JSON.new()
	if json.parse(f.get_as_text()) != OK: return
	f.close()
	var dict = json.data
	if typeof(dict) == TYPE_DICTIONARY and dict.has("worlds"):
		var w_entry = dict["worlds"].get(wid, {})
		if not w_entry.is_empty():
			w_entry["width"] = float(w)
			w_entry["height"] = float(h)
			var fw = FileAccess.open(path, FileAccess.WRITE)
			if fw:
				fw.store_string(JSON.stringify(dict, "\t"))
				fw.close()

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

func _setup_window_file_drop() -> void:
	var win = get_window()
	if win:
		if not win.files_dropped.is_connected(_on_window_files_dropped):
			win.files_dropped.connect(_on_window_files_dropped)

func _on_window_files_dropped(files: PackedStringArray) -> void:
	if files.is_empty(): return
	for fpath in files:
		if fpath.ends_with(".png") or fpath.ends_with(".jpg"):
			if asset_import_dialog:
				asset_import_dialog.open_with_file(fpath)
				break

func _on_sync_assets_pressed() -> void:
	var stats = AssetRegistry.scan_and_sync_all_assets()
	if palette:
		palette.refresh_assets_list()
		palette._populate_palette()
	if validation_status_label:
		validation_status_label.text = "Synced %d assets (+%d new)" % [int(stats.get("scanned", 0)), int(stats.get("new_assets", 0))]
		validation_status_label.modulate = Color(0.4, 1.0, 0.6)

func _on_asset_imported(asset_meta: Dictionary) -> void:
	if palette:
		palette.refresh_assets_list()
		palette._populate_palette()
		# Switch to the imported asset's tab
		var cat = str(asset_meta.get("category", ""))
		if right_dock:
			right_dock.current_tab = 0 # Asset Palette
	if validation_status_label:
		validation_status_label.text = "Imported: " + str(asset_meta.get("name", "Asset"))
		validation_status_label.modulate = Color(0.4, 1.0, 0.6)

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
