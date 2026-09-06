class_name WorldInspector
extends PanelContainer

## Inspector panel for editing Identity, Transform, Gameplay flags, Interaction Types, and NPC Metadata.

signal property_changed(target_data: Dictionary, prop_name: String, new_val: Variant)
signal multi_property_changed(targets: Array, prop_name: String, new_val: Variant)
signal preset_applied(preset_name: String, targets: Array)

var title_label: Label
var asset_id_label: Label
var instance_id_edit: LineEdit
var pos_x_spin: SpinBox
var pos_y_spin: SpinBox
var layer_opt: OptionButton
var walkable_check: CheckBox
var solid_check: CheckBox
var interactable_check: CheckBox
var interaction_type_opt: OptionButton
var interaction_id_edit: LineEdit
var target_world_edit: LineEdit
var target_spawn_edit: LineEdit
var props_container: VBoxContainer
var empty_label: Label

var current_mode: SelectionManager.SelectionMode = SelectionManager.SelectionMode.NONE
var current_targets: Array = []
var is_updating_ui: bool = false

func _init() -> void:
	_build_ui()

func _ready() -> void:
	_setup_layer_options()
	_setup_interaction_section()
	_bind_events()
	clear_inspector()

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var root_vbox = VBoxContainer.new()
	margin.add_child(root_vbox)

	title_label = Label.new()
	title_label.text = "🔍 Inspector"
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.modulate = Color(0.92, 0.94, 0.98)
	root_vbox.add_child(title_label)

	empty_label = Label.new()
	empty_label.text = "No element selected.\nClick a tile or drag-select objects."
	empty_label.add_theme_font_size_override("font_size", 13)
	empty_label.modulate = Color(0.6, 0.6, 0.6)
	empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_vbox.add_child(empty_label)

	props_container = VBoxContainer.new()
	props_container.visible = false
	props_container.add_theme_constant_override("separation", 8)
	root_vbox.add_child(props_container)

	# Presets grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	props_container.add_child(grid)

	var p_walk = Button.new(); p_walk.text = "Walkable"; p_walk.custom_minimum_size = Vector2(0, 34); p_walk.add_theme_font_size_override("font_size", 13); p_walk.name = "PresetWalkable"; grid.add_child(p_walk)
	var p_sol = Button.new(); p_sol.text = "Solid"; p_sol.custom_minimum_size = Vector2(0, 34); p_sol.add_theme_font_size_override("font_size", 13); p_sol.name = "PresetSolid"; grid.add_child(p_sol)
	var p_int = Button.new(); p_int.text = "Interact"; p_int.custom_minimum_size = Vector2(0, 34); p_int.add_theme_font_size_override("font_size", 13); p_int.name = "PresetInteractable"; grid.add_child(p_int)
	var p_dec = Button.new(); p_dec.text = "Decor"; p_dec.custom_minimum_size = Vector2(0, 34); p_dec.add_theme_font_size_override("font_size", 13); p_dec.name = "PresetDecoration"; grid.add_child(p_dec)

	props_container.add_child(HSeparator.new())

	# Asset ID
	var hbox_asset = HBoxContainer.new()
	var l_asset = Label.new(); l_asset.text = "Asset ID:"; l_asset.custom_minimum_size = Vector2(90, 0); l_asset.add_theme_font_size_override("font_size", 13)
	hbox_asset.add_child(l_asset)
	asset_id_label = Label.new()
	asset_id_label.add_theme_font_size_override("font_size", 13)
	hbox_asset.add_child(asset_id_label)
	props_container.add_child(hbox_asset)

	# Instance ID
	var hbox_inst = HBoxContainer.new()
	var l_inst = Label.new(); l_inst.text = "Instance:"; l_inst.custom_minimum_size = Vector2(90, 0); l_inst.add_theme_font_size_override("font_size", 13)
	hbox_inst.add_child(l_inst)
	instance_id_edit = LineEdit.new()
	instance_id_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	instance_id_edit.custom_minimum_size = Vector2(0, 34)
	instance_id_edit.add_theme_font_size_override("font_size", 13)
	hbox_inst.add_child(instance_id_edit)
	props_container.add_child(hbox_inst)

	# Position
	var hbox_pos = HBoxContainer.new()
	var l_pos = Label.new(); l_pos.text = "Pos (X,Y):"; l_pos.custom_minimum_size = Vector2(90, 0); l_pos.add_theme_font_size_override("font_size", 13)
	hbox_pos.add_child(l_pos)
	pos_x_spin = SpinBox.new(); pos_x_spin.custom_minimum_size = Vector2(0, 34)
	hbox_pos.add_child(pos_x_spin)
	pos_y_spin = SpinBox.new(); pos_y_spin.custom_minimum_size = Vector2(0, 34)
	hbox_pos.add_child(pos_y_spin)
	props_container.add_child(hbox_pos)

	# Layer
	var hbox_layer = HBoxContainer.new()
	var l_layer = Label.new(); l_layer.text = "Layer:"; l_layer.custom_minimum_size = Vector2(90, 0); l_layer.add_theme_font_size_override("font_size", 13)
	hbox_layer.add_child(l_layer)
	layer_opt = OptionButton.new()
	layer_opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layer_opt.custom_minimum_size = Vector2(0, 34)
	layer_opt.add_theme_font_size_override("font_size", 13)
	hbox_layer.add_child(layer_opt)
	props_container.add_child(hbox_layer)

	walkable_check = CheckBox.new(); walkable_check.text = "Walkable"; walkable_check.add_theme_font_size_override("font_size", 13); UIConstants.apply_checkbox_style(walkable_check); props_container.add_child(walkable_check)
	solid_check = CheckBox.new(); solid_check.text = "Solid"; solid_check.add_theme_font_size_override("font_size", 13); UIConstants.apply_checkbox_style(solid_check); props_container.add_child(solid_check)
	interactable_check = CheckBox.new(); interactable_check.text = "Interactable"; interactable_check.add_theme_font_size_override("font_size", 13); UIConstants.apply_checkbox_style(interactable_check); props_container.add_child(interactable_check)

func _setup_layer_options() -> void:
	if not layer_opt: return
	layer_opt.clear()
	for l in ["GROUND", "TERRAIN", "DECORATION", "OBJECT", "NPC", "OVERLAY"]:
		layer_opt.add_item(l)

func _setup_interaction_section() -> void:
	if not props_container: return
	var sep = HSeparator.new()
	props_container.add_child(sep)
	
	var int_title = Label.new()
	int_title.text = " Interaction & Events"
	int_title.add_theme_font_size_override("font_size", 13)
	int_title.modulate = Color(0.90, 0.92, 0.96)
	props_container.add_child(int_title)
	
	# Interaction Type
	var hbox_type = HBoxContainer.new()
	var lbl_type = Label.new(); lbl_type.text = "Type:"
	lbl_type.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_type.add_child(lbl_type)
	interaction_type_opt = OptionButton.new()
	for t in ["none", "container", "dialogue", "shop", "quest", "world_transition", "resource", "custom"]:
		interaction_type_opt.add_item(t.capitalize())
	interaction_type_opt.item_selected.connect(func(idx): _on_field_changed("interaction_type", interaction_type_opt.get_item_text(idx).to_lower().replace(" ", "_")))
	hbox_type.add_child(interaction_type_opt)
	props_container.add_child(hbox_type)
	
	# Target World / ID
	var hbox_id = HBoxContainer.new()
	var lbl_id = Label.new(); lbl_id.text = "ID / World:"
	lbl_id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_id.add_child(lbl_id)
	interaction_id_edit = LineEdit.new()
	interaction_id_edit.custom_minimum_size = Vector2(100, 24)
	interaction_id_edit.text_submitted.connect(func(t):
		_on_field_changed("interaction_id", t)
		_on_field_changed("target_world", t)
	)
	hbox_id.add_child(interaction_id_edit)
	props_container.add_child(hbox_id)

func _bind_events() -> void:
	if instance_id_edit: instance_id_edit.text_submitted.connect(func(t): _on_field_changed("instance_id", t))
	if pos_x_spin: pos_x_spin.value_changed.connect(func(v): _on_field_changed("pos_x", int(v)))
	if pos_y_spin: pos_y_spin.value_changed.connect(func(v): _on_field_changed("pos_y", int(v)))
	if layer_opt: layer_opt.item_selected.connect(func(idx): _on_field_changed("layer", layer_opt.get_item_text(idx)))
	if walkable_check: walkable_check.toggled.connect(func(b): _on_field_changed("walkable", b))
	if solid_check: solid_check.toggled.connect(func(b): _on_field_changed("solid", b))
	if interactable_check: interactable_check.toggled.connect(func(b): _on_field_changed("interactable", b))

	var p_walk = find_child("PresetWalkable", true, false) as Button
	if p_walk: p_walk.pressed.connect(func(): apply_preset("WALKABLE"))
	var p_sol = find_child("PresetSolid", true, false) as Button
	if p_sol: p_sol.pressed.connect(func(): apply_preset("SOLID"))
	var p_int = find_child("PresetInteractable", true, false) as Button
	if p_int: p_int.pressed.connect(func(): apply_preset("INTERACTABLE"))
	var p_dec = find_child("PresetDecoration", true, false) as Button
	if p_dec: p_dec.pressed.connect(func(): apply_preset("DECORATION"))

func inspect(mode: SelectionManager.SelectionMode, items: Array) -> void:
	visible = true
	current_mode = mode
	current_targets = items
	if mode == SelectionManager.SelectionMode.NONE or items.is_empty():
		clear_inspector()
		return
		
	is_updating_ui = true

	if empty_label: empty_label.visible = false
	if props_container: props_container.visible = true
	
	if mode == SelectionManager.SelectionMode.SINGLE_TILE:
		var data = items[0]
		var pos = data.get("position", Vector2i.ZERO)
		var tile = data.get("tile", {})
		if title_label: title_label.text = " Tile Inspector"
		if asset_id_label: asset_id_label.text = str(tile.get("type", "grass"))
		if instance_id_edit: instance_id_edit.text = "tile_%d_%d" % [pos.x, pos.y]; instance_id_edit.editable = false
		if pos_x_spin: pos_x_spin.value = pos.x; pos_x_spin.editable = false
		if pos_y_spin: pos_y_spin.value = pos.y; pos_y_spin.editable = false
		_select_layer_option(tile.get("layer", "GROUND"))
		if walkable_check: walkable_check.button_pressed = bool(tile.get("walkable", true))
		if solid_check: solid_check.button_pressed = bool(tile.get("solid", false))
		if interactable_check: interactable_check.button_pressed = bool(tile.get("interactable", false))
		if interaction_id_edit: interaction_id_edit.text = ""
		
	elif mode == SelectionManager.SelectionMode.SINGLE_OBJECT:
		var data = items[0]
		var pos_arr = data.get("position", [0, 0])

		var overrides = data.get('properties', {})
		var asset_id = data.get('asset_id', '')
		var props = overrides
		if ClassDB.class_exists('AssetDefinitionManager'):
			props = AssetDefinitionManager.resolve_instance_properties(asset_id, overrides)
			
		var indicate_override = func(chk: CheckBox, p_name: String, def_val: bool, label_text: String):
			if not chk: return
			chk.button_pressed = bool(props.get(p_name, def_val))
			if overrides.has(p_name):
				chk.text = label_text + ' [Override]'
				chk.modulate = Color(1.0, 0.8, 0.2)
			else:
				chk.text = label_text
				chk.modulate = Color.WHITE

		indicate_override.call(walkable_check, 'walkable', false, 'Walkable')
		indicate_override.call(solid_check, 'solid', true, 'Solid')
		indicate_override.call(interactable_check, 'interactable', true, 'Interactable')
		
		# Interaction reflection
		var itype = str(props.get("interaction_type", "none"))
		_select_interaction_type(itype)
		var iid = str(props.get("interaction_id", props.get("target_world", props.get("dialogue_id", ""))))
		if interaction_id_edit: interaction_id_edit.text = iid
		
	elif mode == SelectionManager.SelectionMode.MULTI_OBJECT:
		if title_label: title_label.text = " Multi-Selection (%d items)" % items.size()
		if asset_id_label: asset_id_label.text = "Multiple Objects"
		if instance_id_edit: instance_id_edit.text = "(Multiple)"; instance_id_edit.editable = false
		if pos_x_spin: pos_x_spin.value = 0; pos_x_spin.editable = false
		if pos_y_spin: pos_y_spin.value = 0; pos_y_spin.editable = false
		
	is_updating_ui = false

func _select_interaction_type(itype: String) -> void:
	if not interaction_type_opt: return
	for i in range(interaction_type_opt.item_count):
		if interaction_type_opt.get_item_text(i).to_lower().replace(" ", "_") == itype:
			interaction_type_opt.select(i)
			return

func apply_preset(preset: String) -> void:
	if current_targets.is_empty(): return
	match preset:
		"WALKABLE":
			if walkable_check: walkable_check.button_pressed = true
			if solid_check: solid_check.button_pressed = false
			if interactable_check: interactable_check.button_pressed = false
		"SOLID":
			if walkable_check: walkable_check.button_pressed = false
			if solid_check: solid_check.button_pressed = true
			if interactable_check: interactable_check.button_pressed = false
		"INTERACTABLE":
			if walkable_check: walkable_check.button_pressed = false
			if solid_check: solid_check.button_pressed = true
			if interactable_check: interactable_check.button_pressed = true
		"DECORATION":
			if walkable_check: walkable_check.button_pressed = true
			if solid_check: solid_check.button_pressed = false
			if interactable_check: interactable_check.button_pressed = false
			_select_layer_option("DECORATION")
	preset_applied.emit(preset, current_targets)

func clear_inspector() -> void:
	current_targets.clear()
	current_mode = SelectionManager.SelectionMode.NONE
	if title_label: title_label.text = "Inspector"
	if empty_label: empty_label.visible = true
	if props_container: props_container.visible = false

func clear_inspection() -> void:
	clear_inspector()

func inspect_selection(items: Array) -> void:
	if items.is_empty():
		clear_inspector()
	elif items.size() == 1:
		inspect(SelectionManager.SelectionMode.SINGLE_OBJECT, items)
	else:
		inspect(SelectionManager.SelectionMode.MULTI_OBJECT, items)


func _select_layer_option(layer_name: String) -> void:
	if not layer_opt: return
	for i in range(layer_opt.item_count):
		if layer_opt.get_item_text(i) == layer_name:
			layer_opt.select(i); return

func _on_field_changed(field: String, val: Variant) -> void:
	if is_updating_ui or current_targets.is_empty(): return
	if current_mode == SelectionManager.SelectionMode.MULTI_OBJECT:
		multi_property_changed.emit(current_targets, field, val)
	else:
		property_changed.emit(current_targets[0], field, val)

