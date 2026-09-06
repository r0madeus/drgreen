class_name AssetImportDialog
extends Window

## Smart Drag-and-Drop Asset Importer Dialog.
## Detects dimensions, parses naming rules, copies file to target category folder, and registers into AssetRegistry.

signal asset_imported(asset_info: Dictionary)

var preview_rect: TextureRect
var dim_label: Label
var path_label: Label
var name_edit: LineEdit
var category_opt: OptionButton
var solid_check: CheckBox
var walkable_check: CheckBox
var interact_check: CheckBox
var light_check: CheckBox

var current_file_path: String = ""
var detected_w: int = 16
var detected_h: int = 16

const CATEGORIES = [
	{ "label": "🌿 Nature / Decor", "folder": "environment", "prefix": "prop.", "layer": "DECORATION", "type": "object", "solid": true, "walkable": false },
	{ "label": "🟫 Terrain / Tiles", "folder": "tiles", "prefix": "tile.", "layer": "GROUND", "type": "tile", "solid": false, "walkable": true },
	{ "label": "🏠 Buildings / Structures", "folder": "environment", "prefix": "building.", "layer": "OBJECT", "type": "object", "solid": true, "walkable": false },
	{ "label": "🎒 Items / Tools", "folder": "items", "prefix": "item.", "layer": "OBJECT", "type": "item", "solid": false, "walkable": true },
	{ "label": "👤 NPC / Characters", "folder": "npc", "prefix": "npc.", "layer": "NPC", "type": "npc", "solid": true, "walkable": false },
	{ "label": "🌱 Plants / Crops", "folder": "plants", "prefix": "plant.", "layer": "DECORATION", "type": "plant", "solid": false, "walkable": true }
]

func _ready() -> void:
	title = "📥 Import New Asset (Varlık İçe Aktar)"
	size = Vector2i(540, 480)
	exclusive = false
	visible = false
	close_requested.connect(hide)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)
	
	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(root_vbox)
	
	var top_title = Label.new()
	top_title.text = "✨ Smart Asset Importer & Registration"
	top_title.add_theme_font_size_override("font_size", 14)
	top_title.modulate = Color(0.2, 0.9, 1.0)
	root_vbox.add_child(top_title)
	
	# Middle HBox (Left: Preview, Right: Form)
	var middle_hbox = HBoxContainer.new()
	middle_hbox.add_theme_constant_override("separation", 14)
	middle_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(middle_hbox)
	
	# Left: Preview Box
	var preview_panel = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(160, 160)
	middle_hbox.add_child(preview_panel)
	
	var prev_vbox = VBoxContainer.new()
	prev_vbox.add_theme_constant_override("separation", 6)
	prev_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_panel.add_child(prev_vbox)
	
	preview_rect = TextureRect.new()
	preview_rect.custom_minimum_size = Vector2(128, 128)
	preview_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prev_vbox.add_child(preview_rect)
	
	dim_label = Label.new()
	dim_label.text = "Size: 16x16 px"
	dim_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dim_label.add_theme_font_size_override("font_size", 12)
	dim_label.modulate = Color(1.0, 0.85, 0.3)
	prev_vbox.add_child(dim_label)
	
	# Right: Form
	var form_vbox = VBoxContainer.new()
	form_vbox.add_theme_constant_override("separation", 8)
	form_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle_hbox.add_child(form_vbox)
	
	# File Source
	path_label = Label.new()
	path_label.text = "File: (none)"
	path_label.add_theme_font_size_override("font_size", 11)
	path_label.modulate = Color(0.7, 0.7, 0.7)
	path_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	form_vbox.add_child(path_label)
	
	# Name Edit
	var name_lbl = Label.new(); name_lbl.text = "Display Name:"; name_lbl.add_theme_font_size_override("font_size", 12)
	form_vbox.add_child(name_lbl)
	name_edit = LineEdit.new()
	name_edit.custom_minimum_size = Vector2(0, 32)
	name_edit.add_theme_font_size_override("font_size", 12)
	form_vbox.add_child(name_edit)
	
	# Category Option
	var cat_lbl = Label.new(); cat_lbl.text = "Target Category:"; cat_lbl.add_theme_font_size_override("font_size", 12)
	form_vbox.add_child(cat_lbl)
	category_opt = OptionButton.new()
	category_opt.custom_minimum_size = Vector2(0, 32)
	category_opt.add_theme_font_size_override("font_size", 12)
	for i in range(CATEGORIES.size()):
		category_opt.add_item(CATEGORIES[i]["label"], i)
	category_opt.item_selected.connect(_on_category_changed)
	form_vbox.add_child(category_opt)
	
	# Checkboxes
	var check_grid = GridContainer.new()
	check_grid.columns = 2
	check_grid.add_theme_constant_override("h_separation", 10)
	check_grid.add_theme_constant_override("v_separation", 6)
	form_vbox.add_child(check_grid)
	
	solid_check = CheckBox.new(); solid_check.text = "Solid (Blocks Player)"; solid_check.add_theme_font_size_override("font_size", 12); UIConstants.apply_checkbox_style(solid_check); check_grid.add_child(solid_check)
	walkable_check = CheckBox.new(); walkable_check.text = "Walkable (Passable)"; walkable_check.add_theme_font_size_override("font_size", 12); UIConstants.apply_checkbox_style(walkable_check); check_grid.add_child(walkable_check)
	interact_check = CheckBox.new(); interact_check.text = "Interactable"; interact_check.add_theme_font_size_override("font_size", 12); UIConstants.apply_checkbox_style(interact_check); check_grid.add_child(interact_check)
	light_check = CheckBox.new(); light_check.text = "Emits Light"; light_check.add_theme_font_size_override("font_size", 12); UIConstants.apply_checkbox_style(light_check); check_grid.add_child(light_check)
	
	root_vbox.add_child(HSeparator.new())
	
	# Bottom Action Buttons
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 12)
	root_vbox.add_child(btn_hbox)
	
	btn_hbox.add_spacer(false)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "❌ Cancel"
	cancel_btn.custom_minimum_size = Vector2(100, 36)
	cancel_btn.add_theme_font_size_override("font_size", 12)
	cancel_btn.pressed.connect(hide)
	btn_hbox.add_child(cancel_btn)
	
	var import_btn = Button.new()
	import_btn.text = "📥 Import & Use (İçeri Aktar)"
	import_btn.custom_minimum_size = Vector2(160, 36)
	import_btn.add_theme_font_size_override("font_size", 12)
	import_btn.modulate = Color(0.4, 1.0, 0.6)
	import_btn.pressed.connect(_on_import_confirmed)
	btn_hbox.add_child(import_btn)

func open_with_file(file_path: String) -> void:
	current_file_path = file_path
	var fname = file_path.get_file()
	var base = fname.get_basename()
	
	if path_label: path_label.text = "Source: " + fname
	
	# Load image texture and detect dimensions
	var img = Image.load_from_file(file_path)
	if img and not img.is_empty():
		detected_w = img.get_width()
		detected_h = img.get_height()
		var itex = ImageTexture.create_from_image(img)
		if preview_rect: preview_rect.texture = itex
		if dim_label: dim_label.text = "Size: %dx%d px" % [detected_w, detected_h]
	else:
		detected_w = 16
		detected_h = 16
		if dim_label: dim_label.text = "Size: 16x16 px"
		
	# Parse defaults
	var parsed = AssetRegistry.parse_asset_filename(base, "environment")
	if name_edit: name_edit.text = parsed["display_name"]
	if solid_check: solid_check.button_pressed = parsed["solid"]
	if walkable_check: walkable_check.button_pressed = parsed["walkable"]
	if interact_check: interact_check.button_pressed = parsed["interactable"]
	if light_check: light_check.button_pressed = parsed["emits_light"]
	
	# Select category
	if category_opt:
		match parsed["category"]:
			"terrain": category_opt.selected = 1
			"building": category_opt.selected = 2
			"item": category_opt.selected = 3
			"npc": category_opt.selected = 4
			"plant": category_opt.selected = 5
			_: category_opt.selected = 0
			
	popup_centered()

func _on_category_changed(idx: int) -> void:
	if idx >= 0 and idx < CATEGORIES.size():
		var cat_data = CATEGORIES[idx]
		solid_check.button_pressed = cat_data["solid"]
		walkable_check.button_pressed = cat_data["walkable"]

func _on_import_confirmed() -> void:
	if current_file_path == "": return
	
	var sel_idx = category_opt.selected if category_opt else 0
	var cat_data = CATEGORIES[clampi(sel_idx, 0, CATEGORIES.size() - 1)]
	
	var target_folder = "res://assets/sprites/%s/" % cat_data["folder"]
	if not DirAccess.dir_exists_absolute(target_folder):
		DirAccess.make_dir_recursive_absolute(target_folder)
		
	var clean_name = name_edit.text.to_lower().replace(" ", "_").validate_node_name()
	if clean_name == "":
		clean_name = current_file_path.get_file().get_basename().to_lower()
		
	var target_file = target_folder + clean_name + ".png"
	
	# Copy source file to destination
	var src_f = FileAccess.open(current_file_path, FileAccess.READ)
	if src_f:
		var buffer = src_f.get_buffer(src_f.get_length())
		src_f.close()
		var dst_f = FileAccess.open(target_file, FileAccess.WRITE)
		if dst_f:
			dst_f.store_buffer(buffer)
			dst_f.close()
			
	# Trigger complete scan and manifest update
	AssetRegistry.scan_and_sync_all_assets()
	
	# Explicitly store configured properties in manifest
	var asset_id = cat_data["prefix"] + clean_name
	var meta = {
		"id": clean_name,
		"asset_id": asset_id,
		"name": name_edit.text if name_edit.text != "" else clean_name.capitalize(),
		"category": cat_data["folder"],
		"type": cat_data["type"],
		"layer": cat_data["layer"],
		"texture": target_file,
		"size": [detected_w, detected_h],
		"solid": solid_check.button_pressed,
		"walkable": walkable_check.button_pressed,
		"interactable": interact_check.button_pressed,
		"emits_light": light_check.button_pressed
	}
	AssetRegistry._manifest[asset_id] = meta
	AssetRegistry.save_manifest()
	
	hide()
	asset_imported.emit(meta)
