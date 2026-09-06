class_name AssetEditorPanel
extends EditorPanel

## Phase 35 — In-Game Asset & Visual Content Editor (Hardened Production Pipeline).
## 3-zone responsive layout:
##   - Left: Category browser, Search, Filters (Modified, Missing, Favorites), Asset list, Missing Assets section
##   - Center: High-res Asset Preview with checkerboard background, Zoom/Fit, Animation playback controls, 4-Way NPC direction buttons, Test In Game
##   - Right: Tabbed Inspector ([General], [Visual], [Animation], [Metadata])
##   - Bottom Actions: Apply, Reset, Create Override, Replace, Import, Reset Category, Reset All, Validate
## All edits stage through EditorDataService — base res:// files are NEVER mutated.

# ---------------------------------------------------------------------------
# Default Category Definitions (dynamically extended by asset_manifest.json)
# ---------------------------------------------------------------------------
const DEFAULT_CATEGORIES := [
	"terrain", "nature", "buildings", "plants", "items", "tools", "npc", "player", "ui", "audio"
]

const CATEGORY_PREFIXES := {
	"terrain": ["tile.", "terrain"],
	"nature": ["prop.", "environment."],
	"buildings": ["building."],
	"plants": ["plant.", "crop."],
	"items": ["item."],
	"tools": ["tool."],
	"npc": ["npc."],
	"player": ["player."],
	"ui": ["ui.", "ui.icon."],
	"audio": ["audio.", "audio.sfx.", "audio.music."]
}

# ---------------------------------------------------------------------------
# UI Node References
# ---------------------------------------------------------------------------
var _main_split: HSplitContainer
var _center_split: HSplitContainer
var _left_panel: PanelContainer
var _center_panel: PanelContainer
var _right_panel: PanelContainer

# Left Zone
var _category_list: ItemList
var _search_field: LineEdit
var _filter_check_modified: CheckBox
var _filter_check_missing: CheckBox
var _filter_check_favorites: CheckBox
var _asset_list: ItemList
var _missing_list: ItemList

# Center Zone
var _preview_texture_rect: TextureRect
var _checker_bg: ColorRect
var _preview_label: Label
var _anim_timer: float = 0.0
var _anim_playing: bool = false
var _anim_frame: int = 0
var _anim_fps: int = 6
var _anim_frames: int = 1
var _anim_loop: bool = true
var _btn_play_anim: Button
var _btn_prev_frame: Button
var _btn_next_frame: Button
var _btn_zoom_in: Button
var _btn_zoom_out: Button
var _btn_zoom_fit: Button
var _zoom_label: Label
var _zoom_level: float = 4.0
var _frame_label: Label
var _direction_group_container: HBoxContainer

# Right Zone (Tabbed Inspector)
var _tab_container: TabContainer
var _icon_cache: Dictionary = {}

# Tab 0: General
var _stable_id_label: Label
var _category_disp_label: Label
var _display_name_field: LineEdit
var _description_field: LineEdit
var _path_label: Label
var _source_label: Label
var _status_badge_label: Label
var _btn_toggle_fav: Button
var _btn_reset_asset: Button

# Tab 1: Visual
var _texture_path_field: LineEdit
var _size_w_spin: SpinBox
var _size_h_spin: SpinBox
var _scale_spin: SpinBox
var _offset_x_spin: SpinBox
var _offset_y_spin: SpinBox
var _pivot_selector: OptionButton
var _flip_h_check: CheckBox
var _flip_v_check: CheckBox
var _filter_mode_selector: OptionButton
var _modulate_picker: ColorPickerButton
var _btn_open_npc_editor: Button
var _btn_open_item_editor: Button
var _btn_open_crop_editor: Button
var _btn_open_tool_editor: Button
var _btn_place_in_world: Button

# Tab 2: Animation
var _anim_selector: OptionButton
var _anim_cols_spin: SpinBox
var _anim_rows_spin: SpinBox
var _anim_fps_spin: SpinBox
var _anim_loop_check: CheckBox
var _anim_direction_opt: OptionButton
var _btn_save_anim: Button

# Tab 3: Metadata
var _meta_type_label: Label
var _meta_tags_field: LineEdit
var _meta_used_by_list: ItemList
var _meta_warning_label: Label
var _btn_save_meta: Button

# Dialogs
var _file_dialog: FileDialog = null
var _save_as_new_dialog: ConfirmationDialog = null
var _save_new_id_field: LineEdit = null
var _save_new_name_field: LineEdit = null
var _import_target_id: String = ""
var _is_replacing_current: bool = false

# State
var _selected_asset_id: String = ""
var _selected_category: String = ""
var _favorites: Dictionary = {}          # asset_id -> true
var _missing_assets: Dictionary = {}     # asset_id -> { expected_type, referenced_by, status }
var _current_preview_texture: Texture2D = null

# NPC / Character Workspace State
var _npc_direction: String = "down"
var _npc_anim_name: String = "idle"

# ---------------------------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------------------------

func _init() -> void:
	super._init("assets", "ui.editor.cat_assets", "icon_asset")

func setup(p_service: Variant) -> void:
	super.setup(p_service)
	_build_ui()
	_build_dialogs()
	_populate_categories()
	_scan_missing_assets()

func open_panel() -> void:
	super.open_panel()
	if not _category_list:
		_build_ui()
		_build_dialogs()
	if _category_list and _category_list.item_count == 0:
		_populate_categories()
		_refresh_asset_list()

func refresh() -> void:
	_refresh_asset_list()
	if _selected_asset_id != "":
		_show_asset(_selected_asset_id)

# ---------------------------------------------------------------------------
# UI CONSTRUCTION
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	name = "AssetEditorPanel"
	theme = UIConstants.get_theme()
	set_anchors_preset(PRESET_FULL_RECT)
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH

	# Root VBox
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_preset(PRESET_FULL_RECT)
	root_vbox.grow_horizontal = GROW_DIRECTION_BOTH
	root_vbox.grow_vertical = GROW_DIRECTION_BOTH
	add_child(root_vbox)

	# --- Top Toolbar ---
	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 8)
	root_vbox.add_child(toolbar)

	var title_lbl := Label.new()
	title_lbl.text = "🎨 Asset & Visual Content Editor"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.modulate = Color(0.92, 0.94, 0.98)
	toolbar.add_child(title_lbl)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(spacer)

	var btn_validate := Button.new()
	btn_validate.text = " Validate Assets"
	btn_validate.tooltip_text = "Run comprehensive asset validation suite"
	btn_validate.pressed.connect(_on_validate_pressed)
	toolbar.add_child(btn_validate)

	var btn_reset_cat := Button.new()
	btn_reset_cat.text = "↺ Reset Category"
	btn_reset_cat.tooltip_text = "Reset overrides in current category"
	btn_reset_cat.pressed.connect(_on_reset_category_pressed)
	toolbar.add_child(btn_reset_cat)

	var btn_reset_all := Button.new()
	btn_reset_all.text = " Reset All Assets"
	btn_reset_all.tooltip_text = "Reset all staged asset overrides"
	btn_reset_all.pressed.connect(_on_reset_all_pressed)
	toolbar.add_child(btn_reset_all)

	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	# --- 3-Zone Split (Left | Center | Right) ---
	_main_split = HSplitContainer.new()
	_main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_split.split_offset = 240
	root_vbox.add_child(_main_split)

	_build_left_panel()
	_build_center_and_right_panels()

# --- LEFT ZONE: Category Browser, Search, Filters, Asset List ---
func _build_left_panel() -> void:
	_left_panel = PanelContainer.new()
	_left_panel.custom_minimum_size = Vector2(220, 0)
	_main_split.add_child(_left_panel)

	var left_vbox := VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", 4)
	_left_panel.add_child(left_vbox)

	var cat_lbl := Label.new()
	cat_lbl.text = "CATEGORIES"
	cat_lbl.add_theme_font_size_override("font_size", 11)
	cat_lbl.modulate = Color(0.7, 0.7, 0.7)
	left_vbox.add_child(cat_lbl)

	_category_list = ItemList.new()
	_category_list.custom_minimum_size = Vector2(0, 130)
	_category_list.item_selected.connect(_on_category_selected)
	left_vbox.add_child(_category_list)

	var sep := HSeparator.new()
	left_vbox.add_child(sep)

	# Search field
	_search_field = LineEdit.new()
	_search_field.placeholder_text = " Search assets..."
	_search_field.text_changed.connect(_on_search_changed)
	left_vbox.add_child(_search_field)

	# Filter checkboxes
	var filter_hbox := HBoxContainer.new()
	filter_hbox.add_theme_constant_override("separation", 6)
	left_vbox.add_child(filter_hbox)

	_filter_check_modified = CheckBox.new()
	_filter_check_modified.text = "Modified"
	UIConstants.apply_checkbox_style(_filter_check_modified)
	_filter_check_modified.toggled.connect(_on_filter_changed)
	filter_hbox.add_child(_filter_check_modified)

	_filter_check_missing = CheckBox.new()
	_filter_check_missing.text = "Missing"
	UIConstants.apply_checkbox_style(_filter_check_missing)
	_filter_check_missing.toggled.connect(_on_filter_changed)
	filter_hbox.add_child(_filter_check_missing)

	_filter_check_favorites = CheckBox.new()
	_filter_check_favorites.text = "Favs"
	UIConstants.apply_checkbox_style(_filter_check_favorites)
	_filter_check_favorites.toggled.connect(_on_filter_changed)
	filter_hbox.add_child(_filter_check_favorites)

	# Asset List
	var asset_lbl := Label.new()
	asset_lbl.text = "ASSET CATALOG"
	asset_lbl.add_theme_font_size_override("font_size", 11)
	asset_lbl.modulate = Color(0.7, 0.7, 0.7)
	left_vbox.add_child(asset_lbl)

	_asset_list = ItemList.new()
	_asset_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_asset_list.item_selected.connect(_on_asset_selected)
	left_vbox.add_child(_asset_list)

	# Missing Assets Section
	var miss_lbl := Label.new()
	miss_lbl.text = " MISSING ASSETS"
	miss_lbl.add_theme_font_size_override("font_size", 11)
	miss_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.3))
	left_vbox.add_child(miss_lbl)

	_missing_list = ItemList.new()
	_missing_list.custom_minimum_size = Vector2(0, 75)
	_missing_list.item_selected.connect(_on_missing_selected)
	left_vbox.add_child(_missing_list)

# --- CENTER & RIGHT ZONES ---
func _build_center_and_right_panels() -> void:
	_center_split = HSplitContainer.new()
	_center_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_split.split_offset = -300
	_main_split.add_child(_center_split)

	_build_center_panel()
	_build_right_panel()

# --- CENTER ZONE: Asset Preview, Animation Controls, Character Controls ---
func _build_center_panel() -> void:
	_center_panel = PanelContainer.new()
	_center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_center_split.add_child(_center_panel)

	var center_vbox := VBoxContainer.new()
	center_vbox.add_theme_constant_override("separation", 6)
	_center_panel.add_child(center_vbox)

	# Asset ID Header
	_preview_label = Label.new()
	_preview_label.text = "Select an asset to view"
	_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_label.add_theme_font_size_override("font_size", 13)
	_preview_label.modulate = Color(0.85, 0.95, 1.0)
	center_vbox.add_child(_preview_label)

	# Zoom & Fit Toolbar
	var zoom_hbox := HBoxContainer.new()
	zoom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	zoom_hbox.add_theme_constant_override("separation", 6)
	center_vbox.add_child(zoom_hbox)

	_btn_zoom_out = Button.new()
	_btn_zoom_out.text = " - "
	_btn_zoom_out.custom_minimum_size = Vector2(30, 24)
	_btn_zoom_out.tooltip_text = "Zoom Out"
	_btn_zoom_out.pressed.connect(_on_zoom_out)
	zoom_hbox.add_child(_btn_zoom_out)

	_zoom_label = Label.new()
	_zoom_label.text = "400%"
	_zoom_label.custom_minimum_size = Vector2(50, 0)
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_hbox.add_child(_zoom_label)

	_btn_zoom_in = Button.new()
	_btn_zoom_in.text = " + "
	_btn_zoom_in.custom_minimum_size = Vector2(30, 24)
	_btn_zoom_in.tooltip_text = "Zoom In"
	_btn_zoom_in.pressed.connect(_on_zoom_in)
	zoom_hbox.add_child(_btn_zoom_in)

	_btn_zoom_fit = Button.new()
	_btn_zoom_fit.text = "Fit"
	_btn_zoom_fit.custom_minimum_size = Vector2(40, 24)
	_btn_zoom_fit.tooltip_text = "Reset Zoom to Fit"
	_btn_zoom_fit.pressed.connect(_on_zoom_fit)
	zoom_hbox.add_child(_btn_zoom_fit)

	# Preview Canvas Container (with checkerboard effect)
	var preview_bg := PanelContainer.new()
	preview_bg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_bg.clip_contents = true
	preview_bg.gui_input.connect(_on_preview_gui_input)
	center_vbox.add_child(preview_bg)

	_checker_bg = ColorRect.new()
	_checker_bg.set_anchors_preset(PRESET_FULL_RECT)
	_checker_bg.color = Color(0.12, 0.14, 0.16, 0.95)
	_checker_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_bg.add_child(_checker_bg)

	var center_box := CenterContainer.new()
	center_box.set_anchors_preset(PRESET_FULL_RECT)
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_bg.add_child(center_box)

	_preview_texture_rect = TextureRect.new()
	_preview_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	center_box.add_child(_preview_texture_rect)

	# Playback & Frame Stepping Controls
	var playback_hbox := HBoxContainer.new()
	playback_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	playback_hbox.add_theme_constant_override("separation", 6)
	center_vbox.add_child(playback_hbox)

	_btn_prev_frame = Button.new()
	_btn_prev_frame.text = ""
	_btn_prev_frame.custom_minimum_size = Vector2(34, 26)
	_btn_prev_frame.tooltip_text = "Previous Frame"
	_btn_prev_frame.pressed.connect(_on_prev_frame)
	playback_hbox.add_child(_btn_prev_frame)

	_btn_play_anim = Button.new()
	_btn_play_anim.text = " Play"
	_btn_play_anim.custom_minimum_size = Vector2(75, 26)
	_btn_play_anim.toggle_mode = true
	_btn_play_anim.toggled.connect(_on_play_toggled)
	playback_hbox.add_child(_btn_play_anim)

	_btn_next_frame = Button.new()
	_btn_next_frame.text = ""
	_btn_next_frame.custom_minimum_size = Vector2(34, 26)
	_btn_next_frame.tooltip_text = "Next Frame"
	_btn_next_frame.pressed.connect(_on_next_frame)
	playback_hbox.add_child(_btn_next_frame)

	_frame_label = Label.new()
	_frame_label.text = "Frame 1/1"
	_frame_label.custom_minimum_size = Vector2(85, 0)
	_frame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	playback_hbox.add_child(_frame_label)

	# 4-Directional Selector for NPC / Character sprites
	_direction_group_container = HBoxContainer.new()
	_direction_group_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_direction_group_container.add_theme_constant_override("separation", 6)
	center_vbox.add_child(_direction_group_container)

	var dir_buttons = [
		{"label": " Up", "dir": "up"},
		{"label": " Left", "dir": "left"},
		{"label": " Down", "dir": "down"},
		{"label": " Right", "dir": "right"}
	]
	for d_info in dir_buttons:
		var btn := Button.new()
		btn.text = d_info["label"]
		btn.custom_minimum_size = Vector2(65, 26)
		var d_val: String = d_info["dir"]
		btn.pressed.connect(func(): _on_direction_pressed(d_val))
		_direction_group_container.add_child(btn)

	# Test In Game & Playtest
	var test_hbox := HBoxContainer.new()
	test_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	test_hbox.add_theme_constant_override("separation", 8)
	center_vbox.add_child(test_hbox)

	var btn_test := Button.new()
	btn_test.text = " Test In Game"
	btn_test.tooltip_text = "Launch live game preview with this asset loaded"
	btn_test.pressed.connect(_on_test_in_game)
	test_hbox.add_child(btn_test)

# --- RIGHT ZONE: Tabbed Property Inspector & Action Bar ---
func _build_right_panel() -> void:
	_right_panel = PanelContainer.new()
	_right_panel.custom_minimum_size = Vector2(280, 0)
	_center_split.add_child(_right_panel)

	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 6)
	_right_panel.add_child(right_vbox)

	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.tab_changed.connect(_on_inspector_tab_changed)
	right_vbox.add_child(_tab_container)

	_build_tab_general()
	_build_tab_visual()
	_build_tab_animation()
	_build_tab_metadata()

	# Bottom Action Buttons
	var actions_grid := GridContainer.new()
	actions_grid.columns = 2
	actions_grid.add_theme_constant_override("h_separation", 6)
	actions_grid.add_theme_constant_override("v_separation", 6)
	right_vbox.add_child(actions_grid)

	var btn_overwrite := Button.new()
	btn_overwrite.text = "💾 Overwrite Asset"
	btn_overwrite.tooltip_text = "Overwrite existing asset properties and save to manifest"
	btn_overwrite.custom_minimum_size = Vector2(0, 32)
	btn_overwrite.add_theme_font_size_override("font_size", 12)
	btn_overwrite.modulate = Color(0.4, 1.0, 0.6)
	btn_overwrite.pressed.connect(_on_overwrite_asset)
	actions_grid.add_child(btn_overwrite)

	var btn_save_new := Button.new()
	btn_save_new.text = "➕ Save as New Asset..."
	btn_save_new.tooltip_text = "Save modified asset under a new ID and display name"
	btn_save_new.custom_minimum_size = Vector2(0, 32)
	btn_save_new.add_theme_font_size_override("font_size", 12)
	btn_save_new.modulate = Color(0.3, 0.9, 1.0)
	btn_save_new.pressed.connect(_on_save_as_new_pressed)
	actions_grid.add_child(btn_save_new)

	var btn_replace := Button.new()
	btn_replace.text = "🔄 Replace Image"
	btn_replace.tooltip_text = "Replace visual asset for this ID"
	btn_replace.custom_minimum_size = Vector2(0, 30)
	btn_replace.add_theme_font_size_override("font_size", 12)
	btn_replace.pressed.connect(_on_replace_asset)
	actions_grid.add_child(btn_replace)

	var btn_revert := Button.new()
	btn_revert.text = "↺ Reset Asset"
	btn_revert.tooltip_text = "Reset this asset to default"
	btn_revert.custom_minimum_size = Vector2(0, 30)
	btn_revert.add_theme_font_size_override("font_size", 12)
	btn_revert.pressed.connect(_on_reset_asset)
	actions_grid.add_child(btn_revert)

# --- TAB 0: General ---
func _build_tab_general() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "General"
	_tab_container.add_child(scroll)

	var tab := VBoxContainer.new()
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_theme_constant_override("separation", 6)
	scroll.add_child(tab)

	tab.add_child(_make_section_label("Stable ID"))
	_stable_id_label = Label.new()
	_stable_id_label.text = "(none)"
	_stable_id_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stable_id_label.modulate = Color(1.0, 0.9, 0.4)
	tab.add_child(_stable_id_label)

	tab.add_child(_make_section_label("Category"))
	_category_disp_label = Label.new()
	_category_disp_label.text = "(none)"
	tab.add_child(_category_disp_label)

	tab.add_child(_make_section_label("Display Name"))
	_display_name_field = LineEdit.new()
	_display_name_field.placeholder_text = "Asset display name..."
	_display_name_field.text_submitted.connect(func(v): _on_field_changed("display_name", v))
	tab.add_child(_display_name_field)

	tab.add_child(_make_section_label("Description"))
	_description_field = LineEdit.new()
	_description_field.placeholder_text = "Asset description..."
	_description_field.text_submitted.connect(func(v): _on_field_changed("description", v))
	tab.add_child(_description_field)

	tab.add_child(_make_section_label("File Source"))
	_path_label = Label.new()
	_path_label.text = "(none)"
	_path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(_path_label)

	tab.add_child(_make_section_label("Override Status"))
	_status_badge_label = Label.new()
	_status_badge_label.text = " Base Game (Unmodified)"
	_status_badge_label.modulate = Color(0.6, 0.8, 0.6)
	tab.add_child(_status_badge_label)

	_btn_toggle_fav = Button.new()
	_btn_toggle_fav.text = " Toggle Favorite"
	_btn_toggle_fav.pressed.connect(_on_toggle_favorite)
	tab.add_child(_btn_toggle_fav)

	_btn_reset_asset = Button.new()
	_btn_reset_asset.text = "↺ Reset This Asset"
	_btn_reset_asset.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_btn_reset_asset.pressed.connect(_on_reset_asset)
	tab.add_child(_btn_reset_asset)

# --- TAB 1: Visual ---
func _build_tab_visual() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Visual"
	_tab_container.add_child(scroll)

	var tab := VBoxContainer.new()
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_theme_constant_override("separation", 6)
	scroll.add_child(tab)

	tab.add_child(_make_section_label("Texture Path"))
	_texture_path_field = LineEdit.new()
	_texture_path_field.placeholder_text = "res://assets/sprites/..."
	_texture_path_field.text_submitted.connect(func(v): _on_field_changed("texture", v))
	tab.add_child(_texture_path_field)

	var size_hbox := HBoxContainer.new()
	tab.add_child(size_hbox)
	size_hbox.add_child(_make_row_label("W:"))
	_size_w_spin = SpinBox.new()
	_size_w_spin.min_value = 1
	_size_w_spin.max_value = 4096
	_size_w_spin.value = 16
	_size_w_spin.value_changed.connect(func(v): _on_field_changed("size_w", int(v)))
	size_hbox.add_child(_size_w_spin)

	size_hbox.add_child(_make_row_label("H:"))
	_size_h_spin = SpinBox.new()
	_size_h_spin.min_value = 1
	_size_h_spin.max_value = 4096
	_size_h_spin.value = 16
	_size_h_spin.value_changed.connect(func(v): _on_field_changed("size_h", int(v)))
	size_hbox.add_child(_size_h_spin)

	tab.add_child(_make_section_label("Scale"))
	_scale_spin = SpinBox.new()
	_scale_spin.min_value = 0.1
	_scale_spin.max_value = 10.0
	_scale_spin.step = 0.1
	_scale_spin.value = 1.0
	_scale_spin.value_changed.connect(_on_scale_changed)
	tab.add_child(_scale_spin)

	var offset_hbox := HBoxContainer.new()
	tab.add_child(offset_hbox)
	offset_hbox.add_child(_make_row_label("Offset X:"))
	_offset_x_spin = SpinBox.new()
	_offset_x_spin.min_value = -500
	_offset_x_spin.max_value = 500
	_offset_x_spin.value = 0
	_offset_x_spin.value_changed.connect(func(v): _on_field_changed("offset_x", v))
	offset_hbox.add_child(_offset_x_spin)

	offset_hbox.add_child(_make_row_label("Y:"))
	_offset_y_spin = SpinBox.new()
	_offset_y_spin.min_value = -500
	_offset_y_spin.max_value = 500
	_offset_y_spin.value = 0
	_offset_y_spin.value_changed.connect(func(v): _on_field_changed("offset_y", v))
	offset_hbox.add_child(_offset_y_spin)

	tab.add_child(_make_section_label("Flip"))
	var flip_hbox := HBoxContainer.new()
	tab.add_child(flip_hbox)

	_flip_h_check = CheckBox.new()
	_flip_h_check.text = "Flip H"
	UIConstants.apply_checkbox_style(_flip_h_check)
	_flip_h_check.toggled.connect(_on_flip_h_changed)
	flip_hbox.add_child(_flip_h_check)

	_flip_v_check = CheckBox.new()
	_flip_v_check.text = "Flip V"
	UIConstants.apply_checkbox_style(_flip_v_check)
	_flip_v_check.toggled.connect(_on_flip_v_changed)
	flip_hbox.add_child(_flip_v_check)

	tab.add_child(_make_section_label("Texture Filtering"))
	_filter_mode_selector = OptionButton.new()
	_filter_mode_selector.add_item("Nearest (Pixel Art)")
	_filter_mode_selector.add_item("Linear (Smooth)")
	_filter_mode_selector.item_selected.connect(_on_filter_mode_selected)
	tab.add_child(_filter_mode_selector)

	tab.add_child(_make_section_label("Modulate Tint"))
	_modulate_picker = ColorPickerButton.new()
	_modulate_picker.color = Color.WHITE
	_modulate_picker.color_changed.connect(_on_modulate_changed)
	tab.add_child(_modulate_picker)

	# Cross-Editor Integration Links
	var cross_lbl := Label.new()
	cross_lbl.text = "CROSS-EDITOR ACTIONS"
	cross_lbl.add_theme_font_size_override("font_size", 11)
	cross_lbl.modulate = Color(0.5, 1.0, 0.7)
	tab.add_child(cross_lbl)

	_btn_open_npc_editor = Button.new()
	_btn_open_npc_editor.text = " Open NPC Editor"
	_btn_open_npc_editor.pressed.connect(_on_open_npc_editor)
	tab.add_child(_btn_open_npc_editor)

	_btn_open_item_editor = Button.new()
	_btn_open_item_editor.text = " Open Item Editor"
	_btn_open_item_editor.pressed.connect(_on_open_item_editor)
	tab.add_child(_btn_open_item_editor)

	_btn_open_crop_editor = Button.new()
	_btn_open_crop_editor.text = " Open Crop Editor"
	_btn_open_crop_editor.pressed.connect(_on_open_crop_editor)
	tab.add_child(_btn_open_crop_editor)

	_btn_open_tool_editor = Button.new()
	_btn_open_tool_editor.text = " Open Tool Editor"
	_btn_open_tool_editor.pressed.connect(_on_open_tool_editor)
	tab.add_child(_btn_open_tool_editor)

	_btn_place_in_world = Button.new()
	_btn_place_in_world.text = " Place in World"
	_btn_place_in_world.pressed.connect(_on_place_in_world)
	tab.add_child(_btn_place_in_world)

# --- TAB 2: Animation ---
func _build_tab_animation() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Animation"
	_tab_container.add_child(scroll)

	var tab := VBoxContainer.new()
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_theme_constant_override("separation", 6)
	scroll.add_child(tab)

	tab.add_child(_make_section_label("Character State Animation"))
	_anim_selector = OptionButton.new()
	for anim in ["idle", "walk", "work", "eat", "rest", "sit", "sleep", "talk"]:
		_anim_selector.add_item(anim)
	_anim_selector.item_selected.connect(_on_npc_anim_selected)
	tab.add_child(_anim_selector)

	tab.add_child(_make_section_label("Sprite Sheet Matrix"))
	var sheet_hbox := HBoxContainer.new()
	tab.add_child(sheet_hbox)

	sheet_hbox.add_child(_make_row_label("Cols:"))
	_anim_cols_spin = SpinBox.new()
	_anim_cols_spin.min_value = 1
	_anim_cols_spin.max_value = 64
	_anim_cols_spin.value = 1
	sheet_hbox.add_child(_anim_cols_spin)

	sheet_hbox.add_child(_make_row_label("Rows:"))
	_anim_rows_spin = SpinBox.new()
	_anim_rows_spin.min_value = 1
	_anim_rows_spin.max_value = 64
	_anim_rows_spin.value = 1
	sheet_hbox.add_child(_anim_rows_spin)

	tab.add_child(_make_section_label("Playback FPS"))
	_anim_fps_spin = SpinBox.new()
	_anim_fps_spin.min_value = 1
	_anim_fps_spin.max_value = 60
	_anim_fps_spin.value = 6
	_anim_fps_spin.value_changed.connect(_on_anim_fps_changed)
	tab.add_child(_anim_fps_spin)

	_anim_loop_check = CheckBox.new()
	_anim_loop_check.text = "Loop Animation"
	UIConstants.apply_checkbox_style(_anim_loop_check)
	_anim_loop_check.button_pressed = true
	tab.add_child(_anim_loop_check)

	tab.add_child(_make_section_label("Playback Mode"))
	_anim_direction_opt = OptionButton.new()
	for d in ["forward", "backward", "ping_pong"]:
		_anim_direction_opt.add_item(d)
	tab.add_child(_anim_direction_opt)

	_btn_save_anim = Button.new()
	_btn_save_anim.text = " Save Animation Override"
	_btn_save_anim.pressed.connect(_on_save_anim_override)
	tab.add_child(_btn_save_anim)

# --- TAB 3: Metadata & Dependencies ---
func _build_tab_metadata() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Metadata"
	_tab_container.add_child(scroll)

	var tab := VBoxContainer.new()
	tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab.add_theme_constant_override("separation", 6)
	scroll.add_child(tab)

	tab.add_child(_make_section_label("Asset Type"))
	_meta_type_label = Label.new()
	_meta_type_label.text = "sprite"
	tab.add_child(_meta_type_label)

	tab.add_child(_make_section_label("Tags (comma-separated)"))
	_meta_tags_field = LineEdit.new()
	_meta_tags_field.placeholder_text = "e.g. character, animated, main"
	tab.add_child(_meta_tags_field)

	tab.add_child(_make_section_label("Dependency Graph (Used By)"))
	_meta_used_by_list = ItemList.new()
	_meta_used_by_list.custom_minimum_size = Vector2(0, 90)
	tab.add_child(_meta_used_by_list)

	_meta_warning_label = Label.new()
	_meta_warning_label.text = "Safe to modify (0 dependencies)"
	_meta_warning_label.modulate = Color(0.6, 0.8, 0.6)
	_meta_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tab.add_child(_meta_warning_label)

	_btn_save_meta = Button.new()
	_btn_save_meta.text = " Save Metadata"
	_btn_save_meta.pressed.connect(_on_save_meta)
	tab.add_child(_btn_save_meta)

# --- Dialogs ---
func _build_dialogs() -> void:
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = ["*.png, *.jpg, *.jpeg, *.webp ; Image Files"]
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)

	_save_as_new_dialog = ConfirmationDialog.new()
	_save_as_new_dialog.title = "➕ Save as New Asset (Yeni Varlık Olarak Kaydet)"
	_save_as_new_dialog.size = Vector2i(450, 200)
	_save_as_new_dialog.confirmed.connect(_on_save_as_new_confirmed)
	add_child(_save_as_new_dialog)

	var d_vbox := VBoxContainer.new()
	d_vbox.add_theme_constant_override("separation", 8)
	_save_as_new_dialog.add_child(d_vbox)

	var id_lbl := Label.new(); id_lbl.text = "New Asset ID (Benzersiz Kimlik):"; id_lbl.add_theme_font_size_override("font_size", 12)
	d_vbox.add_child(id_lbl)
	_save_new_id_field = LineEdit.new()
	_save_new_id_field.custom_minimum_size = Vector2(0, 30)
	_save_new_id_field.placeholder_text = "e.g. prop.statue_mossy or tile.crystal_floor"
	_save_new_id_field.add_theme_font_size_override("font_size", 12)
	d_vbox.add_child(_save_new_id_field)

	var name_lbl := Label.new(); name_lbl.text = "Display Name (Görünen İsim):"; name_lbl.add_theme_font_size_override("font_size", 12)
	d_vbox.add_child(name_lbl)
	_save_new_name_field = LineEdit.new()
	_save_new_name_field.custom_minimum_size = Vector2(0, 30)
	_save_new_name_field.placeholder_text = "e.g. Mossy Stone Statue"
	_save_new_name_field.add_theme_font_size_override("font_size", 12)
	d_vbox.add_child(_save_new_name_field)

# --- Helper Builders ---
func _make_section_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	return lbl

func _make_row_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 11)
	return lbl

# ---------------------------------------------------------------------------
# CATEGORY POPULATION (Manifest-Driven + Defaults)
# ---------------------------------------------------------------------------

func _populate_categories() -> void:
	if not _category_list: return
	_category_list.clear()

	_category_list.add_item("All")
	for cat in DEFAULT_CATEGORIES:
		var display_name = cat.capitalize()
		if cat == "terrain": display_name = "Terrain & Tiles"
		elif cat == "nature": display_name = "Nature & Props"
		elif cat == "plants": display_name = "Plants & Crops"
		elif cat == "items": display_name = "Items & Inventory"
		elif cat == "tools": display_name = "Tools & Equipment"
		elif cat == "npc": display_name = "NPCs & Characters"
		elif cat == "player": display_name = "Player Sprites"
		elif cat == "ui": display_name = "UI Icons & Themes"
		elif cat == "audio": display_name = "Audio & SFX"
		_category_list.add_item(display_name)

	_category_list.select(0)
	_selected_category = ""

# ---------------------------------------------------------------------------
# ASSET LIST POPULATION & FILTERING
# ---------------------------------------------------------------------------

func _refresh_asset_list() -> void:
	if not _asset_list: return
	_asset_list.clear()

	var search_text := _search_field.text.to_lower() if _search_field else ""
	var show_modified := _filter_check_modified.button_pressed if _filter_check_modified else false
	var show_missing := _filter_check_missing.button_pressed if _filter_check_missing else false
	var show_favs := _filter_check_favorites.button_pressed if _filter_check_favorites else false

	AssetRegistry.ensure_initialized()
	var all_ids: Array = AssetRegistry.get_all_asset_ids().duplicate()

	var ds = _get_data_service()
	if ds and ds.has_method("get_all_stable_ids"):
		var ds_ids: Array = ds.get_all_stable_ids()
		for sid in ds_ids:
			var sid_str := str(sid)
			if sid_str.begins_with("custom.") or sid_str.begins_with("tile.") or sid_str.begins_with("prop.") or sid_str.begins_with("building.") or sid_str.begins_with("item.") or sid_str.begins_with("npc."):
				if not all_ids.has(sid_str):
					all_ids.append(sid_str)

	var candidate_ids: Array[String] = []
	for aid in all_ids:
		var aid_str := str(aid)
		if not _id_matches_category(aid_str, _selected_category):
			continue
		if search_text != "" and not aid_str.to_lower().contains(search_text):
			continue
		if show_modified and not _is_modified(aid_str):
			continue
		if show_missing and not _missing_assets.has(aid_str):
			continue
		if show_favs and not _favorites.has(aid_str):
			continue
		candidate_ids.append(aid_str)

	# Sort visual assets first, then audio
	candidate_ids.sort_custom(func(a: String, b: String):
		var a_audio = a.begins_with("audio.") or a.begins_with("effect.")
		var b_audio = b.begins_with("audio.") or b.begins_with("effect.")
		if a_audio != b_audio:
			return not a_audio
		return a < b
	)
	
	for aid in candidate_ids:
		var display := str(aid)
		var icon: Texture2D = null
		if _icon_cache.has(display):
			icon = _icon_cache[display]
		else:
			icon = AssetRegistry.get_asset_texture(display)
			_icon_cache[display] = icon
			
		if icon:
			_asset_list.add_item(display, icon)
		else:
			_asset_list.add_item(display)
		var idx := _asset_list.item_count - 1
		if _is_modified(str(aid)):
			_asset_list.set_item_custom_fg_color(idx, Color(0.5, 1.0, 0.5))
		if _missing_assets.has(str(aid)):
			_asset_list.set_item_custom_fg_color(idx, Color(1.0, 0.45, 0.3))
		if _favorites.has(str(aid)):
			_asset_list.set_item_custom_bg_color(idx, Color(0.25, 0.22, 0.05))
		if str(aid) == _selected_asset_id:
			_asset_list.select(idx)
			_asset_list.ensure_current_is_visible()

func _id_matches_category(asset_id: String, category: String) -> bool:
	if category == "" or category == "All" or category == "all":
		return true
	var internal_key := category.to_lower().replace(" ", "_")
	if "terrain" in internal_key or "tile" in internal_key: internal_key = "terrain"
	elif "nature" in internal_key or "prop" in internal_key: internal_key = "nature"
	elif "building" in internal_key: internal_key = "buildings"
	elif "plant" in internal_key or "crop" in internal_key: internal_key = "plants"
	elif "tool" in internal_key: internal_key = "tools"
	elif "item" in internal_key: internal_key = "items"
	elif "npc" in internal_key or "character" in internal_key: internal_key = "npc"
	elif "player" in internal_key: internal_key = "player"
	elif "ui" in internal_key: internal_key = "ui"
	elif "audio" in internal_key or "sfx" in internal_key or "music" in internal_key: internal_key = "audio"
	
	if CATEGORY_PREFIXES.has(internal_key):
		for prefix in CATEGORY_PREFIXES[internal_key]:
			if asset_id.begins_with(prefix):
				return true
				
	var meta := AssetRegistry.get_metadata(asset_id)
	if meta.has("category"):
		var m_cat = str(meta["category"]).to_lower()
		if m_cat == internal_key: return true
		if internal_key == "terrain" and (m_cat in ["terrain", "tile"] or "gpt" in asset_id): return true
		if internal_key == "nature" and m_cat in ["nature", "environment", "prop"]: return true
		if internal_key == "plants" and m_cat in ["plant", "crop"]: return true
		if internal_key == "buildings" and (m_cat in ["building", "structures"] or "house" in asset_id or "shed" in asset_id or "barn" in asset_id): return true
		if internal_key == "audio" and (m_cat.begins_with("audio") or m_cat in ["sfx", "music"]): return true
	return false

func _is_modified(asset_id: String) -> bool:
	var ds = _get_data_service()
	if ds and ds.has_method("has_override"):
		return ds.has_override(asset_id)
	return false

func _get_data_service() -> Variant:
	if not editor_service: return null
	if "data_service" in editor_service:
		return editor_service.data_service
	return null

# ---------------------------------------------------------------------------
# ASSET SELECTION & INSPECTOR POPULATION
# ---------------------------------------------------------------------------

func _show_asset(asset_id: String) -> void:
	_selected_asset_id = asset_id
	_anim_frame = 0
	_anim_playing = false
	if _btn_play_anim:
		_btn_play_anim.button_pressed = false
		_btn_play_anim.text = " Play"

	if _preview_label:
		_preview_label.text = asset_id

	# Resolve texture
	var tex: Texture2D = null
	if asset_id.begins_with("npc."):
		var parts := asset_id.split(".")
		var npc_name := parts[1] if parts.size() > 1 else ""
		tex = AssetRegistry.get_npc_animation_texture(npc_name, _npc_anim_name, _npc_direction, 0)
	elif asset_id.begins_with("player.") or asset_id == "player":
		var p_dir = Vector2i.DOWN
		if _npc_direction == "up": p_dir = Vector2i.UP
		elif _npc_direction == "left": p_dir = Vector2i.LEFT
		elif _npc_direction == "right": p_dir = Vector2i.RIGHT
		tex = AssetRegistry.get_player_texture(p_dir, 0)
	else:
		tex = AssetRegistry.get_asset_texture(asset_id)

	_current_preview_texture = tex
	if _preview_texture_rect:
		_preview_texture_rect.texture = tex
		_update_zoom_display()

	# Animation metadata
	var meta := AssetRegistry.get_metadata(asset_id)
	var frames_count: int = int(meta.get("frames", 1))
	var fps_val: int = int(meta.get("fps", 6))
	var loop_val: bool = bool(meta.get("loop", true))

	_anim_frames = max(1, frames_count)
	_anim_fps = max(1, fps_val)
	_anim_loop = loop_val

	if _anim_fps_spin: _anim_fps_spin.value = _anim_fps
	if _anim_loop_check: _anim_loop_check.button_pressed = _anim_loop
	_update_frame_label()

	# Populate Tabs
	_populate_general_tab(asset_id, meta)
	_populate_visual_tab(asset_id, meta)
	_populate_animation_tab(asset_id, meta)
	if _tab_container and _tab_container.current_tab == 3:
		_populate_metadata_tab(asset_id, meta)

	# Cross-editor and directional button visibility
	var is_character := asset_id.begins_with("npc.") or asset_id.begins_with("player.") or asset_id == "player"
	if _direction_group_container:
		_direction_group_container.visible = is_character

	if _btn_open_npc_editor: _btn_open_npc_editor.visible = asset_id.begins_with("npc.")
	if _btn_open_item_editor: _btn_open_item_editor.visible = asset_id.begins_with("item.")
	if _btn_open_crop_editor: _btn_open_crop_editor.visible = asset_id.begins_with("crop.") or asset_id.begins_with("plant.")
	if _btn_open_tool_editor: _btn_open_tool_editor.visible = asset_id.begins_with("tool.")
	if _btn_place_in_world:
		_btn_place_in_world.visible = (
			asset_id.begins_with("tile.") or asset_id.begins_with("prop.") or asset_id.begins_with("building.")
		)

func _on_inspector_tab_changed(tab_idx: int) -> void:
	if tab_idx == 3 and _selected_asset_id != "":
		_populate_metadata_tab(_selected_asset_id, AssetRegistry.get_metadata(_selected_asset_id))

func _populate_general_tab(asset_id: String, meta: Dictionary) -> void:
	if _stable_id_label: _stable_id_label.text = asset_id
	if _category_disp_label: _category_disp_label.text = str(meta.get("category", _infer_category(asset_id)))
	if _display_name_field: _display_name_field.text = str(meta.get("name", meta.get("display_name", asset_id.capitalize())))
	if _description_field: _description_field.text = str(meta.get("description", ""))
	if _path_label:
		var tex_path := str(meta.get("texture", meta.get("path", "")))
		_path_label.text = tex_path if tex_path != "" else "(procedural / embedded)"
	if _status_badge_label:
		var modded := _is_modified(asset_id)
		_status_badge_label.text = " Overridden (User Mod)" if modded else " Base Game (Unmodified)"
		_status_badge_label.modulate = Color(0.5, 1.0, 0.5) if modded else Color(0.6, 0.8, 0.6)

func _populate_visual_tab(asset_id: String, meta: Dictionary) -> void:
	var ds = _get_data_service()
	if _texture_path_field:
		var resolved_tex = ds.get_resolved_value(asset_id, "texture") if ds else null
		_texture_path_field.text = str(resolved_tex if resolved_tex != null else meta.get("texture", meta.get("path", "")))

	var size_arr = meta.get("size", [16, 16])
	if typeof(size_arr) == TYPE_ARRAY and size_arr.size() >= 2:
		if _size_w_spin: _size_w_spin.value = int(size_arr[0])
		if _size_h_spin: _size_h_spin.value = int(size_arr[1])

	var scale_val = ds.get_resolved_value(asset_id, "scale") if ds else null
	if _scale_spin: _scale_spin.value = float(scale_val) if scale_val != null else 1.0

	var flip_h_val = ds.get_resolved_value(asset_id, "flip_h") if ds else null
	if _flip_h_check: _flip_h_check.button_pressed = bool(flip_h_val) if flip_h_val != null else false

	var flip_v_val = ds.get_resolved_value(asset_id, "flip_v") if ds else null
	if _flip_v_check: _flip_v_check.button_pressed = bool(flip_v_val) if flip_v_val != null else false

func _populate_animation_tab(asset_id: String, meta: Dictionary) -> void:
	var ds = _get_data_service()
	var anim_override = ds.get_resolved_value(asset_id, "animation") if ds else null
	if typeof(anim_override) == TYPE_DICTIONARY:
		if _anim_cols_spin: _anim_cols_spin.value = int(anim_override.get("columns", 1))
		if _anim_rows_spin: _anim_rows_spin.value = int(anim_override.get("rows", 1))
		if _anim_fps_spin: _anim_fps_spin.value = int(anim_override.get("fps", 6))
		if _anim_loop_check: _anim_loop_check.button_pressed = bool(anim_override.get("loop", true))

func _populate_metadata_tab(asset_id: String, meta: Dictionary) -> void:
	if _meta_type_label: _meta_type_label.text = str(meta.get("type", "texture2d"))
	if _meta_tags_field:
		var tags = meta.get("tags", [])
		if typeof(tags) == TYPE_ARRAY:
			_meta_tags_field.text = ", ".join(tags)
		else:
			_meta_tags_field.text = str(tags)

	if _meta_used_by_list:
		_meta_used_by_list.clear()
		var ds = _get_data_service()
		if ds:
			var used_by := _find_used_by(asset_id, ds)
			for ref_id in used_by:
				_meta_used_by_list.add_item(str(ref_id))
			if _meta_warning_label:
				if used_by.size() > 0:
					_meta_warning_label.text = " Used by %d game entities — modify carefully" % used_by.size()
					_meta_warning_label.modulate = Color(1.0, 0.8, 0.3)
				else:
					_meta_warning_label.text = " Safe to modify (0 dependencies)"
					_meta_warning_label.modulate = Color(0.6, 0.8, 0.6)

func _infer_category(asset_id: String) -> String:
	for cat in CATEGORY_PREFIXES:
		for prefix in CATEGORY_PREFIXES[cat]:
			if asset_id.begins_with(prefix):
				return cat
	return "unknown"

func _find_used_by(asset_id: String, ds: Variant) -> Array:
	var refs: Array[String] = []
	if not ds or not ds.has_method("get_all_stable_ids"):
		return refs

	var search_stem := asset_id
	if search_stem.contains("."):
		var parts = search_stem.split(".")
		search_stem = parts[parts.size() - 1]

	var all_sids: Array = ds.get_all_stable_ids()
	for sid in all_sids:
		if sid == asset_id: continue
		var obj: Dictionary = ds.get_resolved_object(sid)
		if _contains_ref(obj, asset_id, search_stem):
			refs.append(str(sid))
			if refs.size() >= 15:
				break
	return refs

func _contains_ref(val: Variant, aid: String, stem: String) -> bool:
	if typeof(val) == TYPE_STRING:
		var s := str(val)
		return s == aid or s == stem or s.contains(aid)
	elif typeof(val) == TYPE_DICTIONARY:
		for k in val.keys():
			if _contains_ref(val[k], aid, stem): return true
	elif typeof(val) == TYPE_ARRAY:
		for item in val:
			if _contains_ref(item, aid, stem): return true
	return false

# ---------------------------------------------------------------------------
# ANIMATION PLAYBACK & FRAME ADVANCE
# ---------------------------------------------------------------------------

func _update_frame_label() -> void:
	if _frame_label:
		_frame_label.text = "Frame %d/%d" % [_anim_frame + 1, _anim_frames]

func _advance_frame(delta: float) -> void:
	if not _anim_playing: return
	_anim_timer += delta
	var frame_duration := 1.0 / float(max(1, _anim_fps))
	if _anim_timer >= frame_duration:
		_anim_timer = 0.0
		_anim_frame = (_anim_frame + 1) % _anim_frames
		_update_frame_label()
		_refresh_preview_frame()

func _refresh_preview_frame() -> void:
	if _selected_asset_id == "" or not _preview_texture_rect:
		return
	var tex: Texture2D = null
	if _selected_asset_id.begins_with("npc."):
		var parts := _selected_asset_id.split(".")
		var npc_name := parts[1] if parts.size() > 1 else ""
		tex = AssetRegistry.get_npc_animation_texture(npc_name, _npc_anim_name, _npc_direction, _anim_frame)
	elif _selected_asset_id.begins_with("player.") or _selected_asset_id == "player":
		var p_dir = Vector2i.DOWN
		if _npc_direction == "up": p_dir = Vector2i.UP
		elif _npc_direction == "left": p_dir = Vector2i.LEFT
		elif _npc_direction == "right": p_dir = Vector2i.RIGHT
		tex = AssetRegistry.get_player_texture(p_dir, _anim_frame)
	else:
		tex = AssetRegistry.get_asset_texture(_selected_asset_id)

	if tex:
		_preview_texture_rect.texture = tex

func _process(delta: float) -> void:
	_advance_frame(delta)

# ---------------------------------------------------------------------------
# MISSING ASSETS SCANNER
# ---------------------------------------------------------------------------

func _scan_missing_assets() -> void:
	_missing_assets.clear()
	if _missing_list: _missing_list.clear()

	AssetRegistry.ensure_initialized()
	var all_ids: Array = AssetRegistry.get_all_asset_ids()

	for aid in all_ids:
		var aid_str := str(aid)
		if aid_str.begins_with("audio.") or aid_str.begins_with("effect."):
			continue
		var meta := AssetRegistry.get_metadata(aid_str)
		var tex_path := str(meta.get("texture", meta.get("path", "")))

		if tex_path != "" and not ResourceLoader.exists(tex_path) and not FileAccess.file_exists(tex_path):
			_missing_assets[aid_str] = {
				"expected_type": _infer_category(aid_str),
				"referenced_by": [],
				"status": "missing"
			}
			if _missing_list:
				_missing_list.add_item(aid_str)
				var idx := _missing_list.item_count - 1
				_missing_list.set_item_custom_fg_color(idx, Color(1.0, 0.45, 0.3))

# ---------------------------------------------------------------------------
# SIGNAL HANDLERS — Left Panel
# ---------------------------------------------------------------------------

func _on_category_selected(index: int) -> void:
	if index == 0:
		_selected_category = ""
	else:
		_selected_category = _category_list.get_item_text(index)
	_refresh_asset_list()

func _select_category_by_name(cat_name: String) -> void:
	if not _category_list: return
	var target := cat_name.to_lower().replace(" ", "_").replace("&", "").strip_edges()
	for i in range(_category_list.item_count):
		var t := _category_list.get_item_text(i).to_lower().replace(" ", "_").replace("&", "").strip_edges()
		if t == target or target in t or (target == "all" and i == 0):
			_category_list.select(i)
			_on_category_selected(i)
			return

func _on_search_changed(_text: String) -> void:
	_refresh_asset_list()

func _on_filter_changed(_pressed: bool) -> void:
	_refresh_asset_list()

func _on_asset_selected(index: int) -> void:
	if index < 0 or index >= _asset_list.item_count: return
	var asset_id := _asset_list.get_item_text(index)
	_show_asset(asset_id)

func _on_missing_selected(index: int) -> void:
	if index < 0 or index >= _missing_list.item_count: return
	var asset_id := _missing_list.get_item_text(index)
	_show_asset(asset_id)

# ---------------------------------------------------------------------------
# SIGNAL HANDLERS — Center Panel
# ---------------------------------------------------------------------------

func _on_preview_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_on_zoom_in()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_on_zoom_out()
			accept_event()

func _on_zoom_in() -> void:
	_zoom_level = minf(_zoom_level + 1.0, 16.0)
	_update_zoom_display()

func _on_zoom_out() -> void:
	_zoom_level = maxf(_zoom_level - 1.0, 1.0)
	_update_zoom_display()

func _on_zoom_fit() -> void:
	_zoom_level = 4.0
	_update_zoom_display()

func _update_zoom_display() -> void:
	if _zoom_label:
		_zoom_label.text = "%d%%" % int(_zoom_level * 100)
	if _preview_texture_rect:
		var base_sz := Vector2(32, 32)
		if _preview_texture_rect.texture:
			base_sz = _preview_texture_rect.texture.get_size()
		elif _current_preview_texture:
			base_sz = _current_preview_texture.get_size()
		if base_sz.x <= 0: base_sz.x = 32
		if base_sz.y <= 0: base_sz.y = 32
		var scaled_sz := base_sz * _zoom_level
		_preview_texture_rect.custom_minimum_size = scaled_sz
		_preview_texture_rect.size = scaled_sz

func _on_play_toggled(pressed: bool) -> void:
	_anim_playing = pressed
	_anim_timer = 0.0
	if _btn_play_anim:
		_btn_play_anim.text = "⏸ Pause" if pressed else " Play"

func _on_prev_frame() -> void:
	_anim_playing = false
	if _btn_play_anim:
		_btn_play_anim.button_pressed = false
		_btn_play_anim.text = " Play"
	_anim_frame = (_anim_frame - 1 + _anim_frames) % _anim_frames
	_update_frame_label()
	_refresh_preview_frame()

func _on_next_frame() -> void:
	_anim_playing = false
	if _btn_play_anim:
		_btn_play_anim.button_pressed = false
		_btn_play_anim.text = " Play"
	_anim_frame = (_anim_frame + 1) % _anim_frames
	_update_frame_label()
	_refresh_preview_frame()

func _on_direction_pressed(direction: String) -> void:
	_npc_direction = direction
	_anim_frame = 0
	_refresh_preview_frame()

func _on_test_in_game() -> void:
	var ds = _get_data_service()
	if ds:
		AssetRegistry.sync_with_data_service(ds)
	if editor_service and editor_service.has_method("start_test_preview"):
		editor_service.start_test_preview()
	elif editor_service and editor_service.has_method("request_playtest"):
		editor_service.request_playtest(_selected_asset_id)

# ---------------------------------------------------------------------------
# SIGNAL HANDLERS — Right Inspector & Mutations
# ---------------------------------------------------------------------------

func _on_field_changed(key: String, value: Variant) -> void:
	if _selected_asset_id == "": return
	var ds = _get_data_service()
	if ds:
		ds.set_staged_override(_selected_asset_id, key, value)
		if key == "texture" and typeof(value) == TYPE_STRING:
			var tex = AssetRegistry._load_texture_safe(str(value))
			if tex:
				AssetRegistry.register_texture_override(_selected_asset_id, tex)
				if _preview_texture_rect: _preview_texture_rect.texture = tex
		panel_dirtied.emit()

func _on_npc_anim_selected(index: int) -> void:
	var anim_names := ["idle", "walk", "work", "eat", "rest", "sit", "sleep", "talk"]
	if index >= 0 and index < anim_names.size():
		_npc_anim_name = anim_names[index]
	_anim_frame = 0
	_refresh_preview_frame()

func _on_flip_h_changed(pressed: bool) -> void:
	if _preview_texture_rect:
		_preview_texture_rect.flip_h = pressed
	_on_field_changed("flip_h", pressed)

func _on_flip_v_changed(pressed: bool) -> void:
	if _preview_texture_rect:
		_preview_texture_rect.flip_v = pressed
	_on_field_changed("flip_v", pressed)

func _on_scale_changed(value: float) -> void:
	_on_field_changed("scale", value)

func _on_filter_mode_selected(index: int) -> void:
	var mode = CanvasItem.TEXTURE_FILTER_NEAREST if index == 0 else CanvasItem.TEXTURE_FILTER_LINEAR
	if _preview_texture_rect:
		_preview_texture_rect.texture_filter = mode
	_on_field_changed("filter_mode", "nearest" if index == 0 else "linear")

func _on_modulate_changed(color: Color) -> void:
	if _preview_texture_rect:
		_preview_texture_rect.modulate = color
	_on_field_changed("modulate", color.to_html())

func _on_anim_fps_changed(value: float) -> void:
	_anim_fps = max(1, int(value))

func _on_save_anim_override() -> void:
	if _selected_asset_id == "": return
	var ds = _get_data_service()
	if not ds: return
	var anim_data := {
		"frames": int(_anim_cols_spin.value) * int(_anim_rows_spin.value),
		"columns": int(_anim_cols_spin.value),
		"rows": int(_anim_rows_spin.value),
		"fps": _anim_fps,
		"loop": _anim_loop_check.button_pressed,
		"direction": _anim_direction_opt.get_item_text(_anim_direction_opt.selected)
	}
	ds.set_staged_override(_selected_asset_id, "animation", anim_data)
	panel_dirtied.emit()

func _on_save_meta() -> void:
	if _selected_asset_id == "" or not _meta_tags_field: return
	var ds = _get_data_service()
	if not ds: return
	var tags_raw := _meta_tags_field.text.split(",")
	var tags: Array[String] = []
	for t in tags_raw:
		var clean := t.strip_edges()
		if clean != "": tags.append(clean)
	ds.set_staged_override(_selected_asset_id, "tags", tags)
	panel_dirtied.emit()

func _on_toggle_favorite() -> void:
	if _selected_asset_id == "": return
	if _favorites.has(_selected_asset_id):
		_favorites.erase(_selected_asset_id)
	else:
		_favorites[_selected_asset_id] = true
	_refresh_asset_list()

func _on_reset_asset() -> void:
	if _selected_asset_id == "": return
	var ds = _get_data_service()
	if ds and ds.has_method("restore_default"):
		ds.restore_default(_selected_asset_id)
	AssetRegistry.remove_texture_override(_selected_asset_id)
	_show_asset(_selected_asset_id)
	_refresh_asset_list()
	panel_dirtied.emit()

func _on_create_override() -> void:
	_on_overwrite_asset()

func _on_overwrite_asset() -> void:
	if _selected_asset_id == "": return
	
	AssetRegistry.ensure_initialized()
	var meta: Dictionary = AssetRegistry.get_metadata(_selected_asset_id).duplicate(true)
	if _display_name_field and _display_name_field.text != "":
		meta["name"] = _display_name_field.text
		meta["display_name"] = _display_name_field.text
	if _texture_path_field and _texture_path_field.text != "":
		meta["texture"] = _texture_path_field.text
	if _size_w_spin and _size_h_spin:
		meta["size"] = [int(_size_w_spin.value), int(_size_h_spin.value)]
	if _modulate_picker:
		meta["modulate"] = _modulate_picker.color.to_html()
	if _anim_cols_spin and _anim_rows_spin:
		meta["frames"] = int(_anim_cols_spin.value) * int(_anim_rows_spin.value)
		meta["fps"] = int(_anim_fps_spin.value)
		meta["loop"] = _anim_loop_check.button_pressed
	if _meta_tags_field:
		var tags_raw: PackedStringArray = _meta_tags_field.text.split(",")
		var tags_arr: Array[String] = []
		for t in tags_raw:
			var cl := t.strip_edges()
			if cl != "": tags_arr.append(cl)
		meta["tags"] = tags_arr
		
	AssetRegistry._manifest[_selected_asset_id] = meta
	AssetRegistry.save_manifest()
	
	var ds = _get_data_service()
	if ds:
		ds.set_staged_override(_selected_asset_id, "_overwritten", true)
		if _texture_path_field and _texture_path_field.text != "":
			ds.set_staged_override(_selected_asset_id, "texture", _texture_path_field.text)
		if _display_name_field and _display_name_field.text != "":
			ds.set_staged_override(_selected_asset_id, "display_name", _display_name_field.text)
		AssetRegistry.sync_with_data_service(ds)
		
	_refresh_asset_list()
	_show_asset(_selected_asset_id)
	if _status_badge_label:
		_status_badge_label.text = " Overwritten & Saved to Manifest"
		_status_badge_label.modulate = Color(0.4, 1.0, 0.6)
	panel_dirtied.emit()

func _on_save_as_new_pressed() -> void:
	if _selected_asset_id == "": return
	var clean := _selected_asset_id
	var prefix := "prop."
	if clean.contains("."):
		prefix = clean.split(".")[0] + "."
		clean = clean.split(".")[1]
	if _save_new_id_field:
		_save_new_id_field.text = prefix + clean + "_custom"
	var cur_name: String = _display_name_field.text if (_display_name_field and _display_name_field.text != "") else clean.capitalize()
	if _save_new_name_field:
		_save_new_name_field.text = cur_name + " (Custom)"
	if _save_as_new_dialog:
		_save_as_new_dialog.popup_centered()

func _on_save_as_new_confirmed() -> void:
	if not _save_new_id_field: return
	var new_id := _save_new_id_field.text.strip_edges()
	var new_name: String = _save_new_name_field.text.strip_edges() if _save_new_name_field else ""
	if new_id == "": return
	if new_name == "": new_name = new_id.capitalize()
	
	AssetRegistry.ensure_initialized()
	var meta: Dictionary = AssetRegistry.get_metadata(_selected_asset_id).duplicate(true)
	meta["id"] = new_id.split(".")[-1]
	meta["asset_id"] = new_id
	meta["name"] = new_name
	meta["display_name"] = new_name
	if _texture_path_field and _texture_path_field.text != "":
		meta["texture"] = _texture_path_field.text
	if _size_w_spin and _size_h_spin:
		meta["size"] = [int(_size_w_spin.value), int(_size_h_spin.value)]
	if _modulate_picker:
		meta["modulate"] = _modulate_picker.color.to_html()
	if _anim_cols_spin and _anim_rows_spin:
		meta["frames"] = int(_anim_cols_spin.value) * int(_anim_rows_spin.value)
		meta["fps"] = int(_anim_fps_spin.value)
		meta["loop"] = _anim_loop_check.button_pressed
	if _meta_tags_field:
		var tags_raw: PackedStringArray = _meta_tags_field.text.split(",")
		var tags_arr: Array[String] = []
		for t in tags_raw:
			var cl := t.strip_edges()
			if cl != "": tags_arr.append(cl)
		meta["tags"] = tags_arr
		
	AssetRegistry._manifest[new_id] = meta
	AssetRegistry.save_manifest()
	
	var ds = _get_data_service()
	if ds:
		AssetRegistry.sync_with_data_service(ds)
		
	_populate_categories()
	select_and_focus_asset(new_id)
	panel_dirtied.emit()

func select_and_focus_asset(target_id: String) -> void:
	if not _category_list:
		_build_ui()
		_build_dialogs()
	if _category_list and _category_list.item_count == 0:
		_populate_categories()
	
	# Infer category
	var target_cat := "All"
	for cat in DEFAULT_CATEGORIES:
		var p_list: Array = CATEGORY_PREFIXES.get(cat, [])
		for prefix in p_list:
			if target_id.begins_with(prefix):
				target_cat = cat
				break
		if target_cat != "All": break
		
	# Select category in list
	if _category_list:
		for i in range(_category_list.item_count):
			var c_text := _category_list.get_item_text(i).to_lower().replace(" ", "_").replace("&", "").strip_edges()
			var t_clean := target_cat.to_lower().replace(" ", "_").replace("&", "").strip_edges()
			if c_text == t_clean or t_clean in c_text or (target_cat == "All" and i == 0):
				_category_list.select(i)
				_selected_category = "" if target_cat == "All" else _category_list.get_item_text(i)
				break
				
	_selected_asset_id = target_id
	_refresh_asset_list()
	_show_asset(target_id)

# ---------------------------------------------------------------------------
# ASSET IMPORT & REPLACEMENT (REAL PIPELINE)
# ---------------------------------------------------------------------------

func _on_replace_asset() -> void:
	if _selected_asset_id == "": return
	_is_replacing_current = true
	_import_target_id = _selected_asset_id
	if _file_dialog:
		_file_dialog.title = "Select Replacement Image for %s" % _selected_asset_id
		_file_dialog.popup_centered(Vector2i(700, 500))

func _on_import_asset() -> void:
	_is_replacing_current = false
	var prefix = "custom."
	if _selected_category != "" and _selected_category != "All":
		var cat_key = _selected_category.to_lower().replace(" ", "_")
		var p_list = CATEGORY_PREFIXES.get(cat_key, ["custom."])
		prefix = p_list[0]
	_import_target_id = prefix + "asset_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	if _file_dialog:
		_file_dialog.title = "Select Image File to Import"
		_file_dialog.popup_centered(Vector2i(700, 500))

func _on_file_selected(path: String) -> void:
	import_file(path, _import_target_id)

## Programmatic import and replacement entry point for tests and UI dialogs
func import_file(source_path: String, target_stable_id: String = "") -> String:
	if target_stable_id == "":
		target_stable_id = _selected_asset_id if _selected_asset_id != "" else ("custom.asset_%d" % (int(Time.get_unix_time_from_system()) % 10000))
	
	var imported_path := AssetRegistry.import_user_asset(source_path, target_stable_id)
	if imported_path == "":
		push_error("[AssetEditor] Failed to import file: %s" % source_path)
		return ""
		
	var ds = _get_data_service()
	if ds:
		ds.set_staged_override(target_stable_id, "texture", imported_path)
		ds.set_staged_override(target_stable_id, "imported_from", source_path)
		ds.set_staged_override(target_stable_id, "imported_at", Time.get_unix_time_from_system())
		AssetRegistry.sync_with_data_service(ds)
		
	_show_asset(target_stable_id)
	_refresh_asset_list()
	panel_dirtied.emit()
	return imported_path

func replace_selected_texture(new_path: String) -> String:
	if _selected_asset_id == "": return ""
	return import_file(new_path, _selected_asset_id)

# ---------------------------------------------------------------------------
# CROSS-EDITOR NAVIGATION
# ---------------------------------------------------------------------------

func _on_open_npc_editor() -> void:
	if _selected_asset_id.begins_with("npc."):
		var parts := _selected_asset_id.split(".")
		var npc_id := parts[1] if parts.size() > 1 else ""
		if editor_service and editor_service.has_method("navigate_to"):
			editor_service.navigate_to("npc", npc_id)

func _on_open_item_editor() -> void:
	if editor_service and editor_service.has_method("navigate_to"):
		editor_service.navigate_to("item", _selected_asset_id)

func _on_open_crop_editor() -> void:
	if editor_service and editor_service.has_method("navigate_to"):
		editor_service.navigate_to("crop", _selected_asset_id)

func _on_open_tool_editor() -> void:
	if editor_service and editor_service.has_method("navigate_to"):
		editor_service.navigate_to("tool", _selected_asset_id)

func _on_place_in_world() -> void:
	if editor_service and editor_service.has_method("navigate_to"):
		editor_service.navigate_to("world", _selected_asset_id)

# ---------------------------------------------------------------------------
# TOOLBAR ACTIONS
# ---------------------------------------------------------------------------

func _on_validate_pressed() -> void:
	var ds = _get_data_service()
	if not ds: return
	var report := EditorValidationService.validate_data(ds)
	_scan_missing_assets()
	_refresh_asset_list()

func _on_reset_category_pressed() -> void:
	var ds = _get_data_service()
	if not ds or _selected_category == "" or _selected_category == "All": return
	var cat_key := _selected_category.to_lower().replace(" ", "_")
	var prefixes = CATEGORY_PREFIXES.get(cat_key, [])
	for p in prefixes:
		if ds.has_method("reset_section"):
			ds.reset_section(p)
		for sid in ds.get_all_stable_ids():
			if sid.begins_with(p):
				AssetRegistry.remove_texture_override(sid)
	_refresh_asset_list()
	_scan_missing_assets()
	if _selected_asset_id != "":
		_show_asset(_selected_asset_id)
	panel_dirtied.emit()

func _on_reset_all_pressed() -> void:
	var ds = _get_data_service()
	if not ds: return
	ds.reset_all_modifications()
	AssetRegistry.clear_texture_overrides()
	_refresh_asset_list()
	_scan_missing_assets()
	if _selected_asset_id != "":
		_show_asset(_selected_asset_id)
	panel_dirtied.emit()
