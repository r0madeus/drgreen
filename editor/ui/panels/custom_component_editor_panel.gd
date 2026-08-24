class_name CustomComponentEditorPanel
extends Control

## Custom Component Definition & Schema Authoring Studio (Phase 42).
## Allows creators to author custom component schemas, property constraints,
## and capability associations entirely in-game.

const REGISTRY_SCRIPT = preload("res://core/components/component_registry.gd")
const DEF_SCRIPT = preload("res://core/components/custom_component_definition.gd")

var current_def: Variant = null

var comp_list: ItemList
var id_edit: LineEdit
var name_edit: LineEdit
var cat_edit: LineEdit
var desc_edit: TextEdit
var props_tree: Tree
var prop_name_edit: LineEdit
var prop_type_option: OptionButton
var prop_def_edit: LineEdit
var status_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(800, 500)
	_build_ui()

func _build_ui() -> void:
	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root_vbox)
	
	var hdr = Label.new()
	hdr.text = " Custom Component & Schema Authoring Studio"
	hdr.add_theme_font_size_override("font_size", 14)
	root_vbox.add_child(hdr)
	
	var hsplit = HBoxContainer.new()
	hsplit.size_flags_vertical = SIZE_EXPAND_FILL
	root_vbox.add_child(hsplit)
	
	# Left: Component Library
	var left_box = VBoxContainer.new()
	left_box.custom_minimum_size = Vector2(220, 0)
	var lib_hdr = Label.new()
	lib_hdr.text = "Component Library:"
	left_box.add_child(lib_hdr)
	
	comp_list = ItemList.new()
	comp_list.size_flags_vertical = SIZE_EXPAND_FILL
	comp_list.item_selected.connect(_on_comp_selected)
	left_box.add_child(comp_list)
	
	var new_btn = Button.new()
	new_btn.text = "+ New Component"
	new_btn.pressed.connect(_on_new_comp_clicked)
	left_box.add_child(new_btn)
	hsplit.add_child(left_box)
	
	# Center: Component Definition
	var center_box = VBoxContainer.new()
	center_box.size_flags_horizontal = SIZE_EXPAND_FILL
	var def_hdr = Label.new()
	def_hdr.text = "Component Metadata:"
	center_box.add_child(def_hdr)
	
	id_edit = LineEdit.new()
	id_edit.placeholder_text = "Component ID (e.g. hunger)"
	center_box.add_child(id_edit)
	
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Display Name (e.g. Hunger)"
	center_box.add_child(name_edit)
	
	cat_edit = LineEdit.new()
	cat_edit.placeholder_text = "Category (e.g. Survival)"
	center_box.add_child(cat_edit)
	
	desc_edit = TextEdit.new()
	desc_edit.custom_minimum_size = Vector2(0, 80)
	desc_edit.placeholder_text = "Description..."
	center_box.add_child(desc_edit)
	
	var save_btn = Button.new()
	save_btn.text = " Register Component"
	save_btn.pressed.connect(_on_save_comp_clicked)
	center_box.add_child(save_btn)
	hsplit.add_child(center_box)
	
	# Right: Properties Schema Builder
	var right_box = VBoxContainer.new()
	right_box.custom_minimum_size = Vector2(280, 0)
	var prop_hdr = Label.new()
	prop_hdr.text = "Properties Schema:"
	right_box.add_child(prop_hdr)
	
	props_tree = Tree.new()
	props_tree.size_flags_vertical = SIZE_EXPAND_FILL
	right_box.add_child(props_tree)
	
	prop_name_edit = LineEdit.new()
	prop_name_edit.placeholder_text = "Property Name (e.g. current)"
	right_box.add_child(prop_name_edit)
	
	prop_type_option = OptionButton.new()
	prop_type_option.add_item("float", 0)
	prop_type_option.add_item("int", 1)
	prop_type_option.add_item("bool", 2)
	prop_type_option.add_item("string", 3)
	right_box.add_child(prop_type_option)
	
	prop_def_edit = LineEdit.new()
	prop_def_edit.placeholder_text = "Default Value (e.g. 100.0)"
	right_box.add_child(prop_def_edit)
	
	var add_prop_btn = Button.new()
	add_prop_btn.text = "+ Add Property"
	add_prop_btn.pressed.connect(_on_add_property_clicked)
	right_box.add_child(add_prop_btn)
	hsplit.add_child(right_box)
	
	status_label = Label.new()
	status_label.text = ""
	root_vbox.add_child(status_label)
	
	_refresh_library()

func _refresh_library() -> void:
	comp_list.clear()
	var all_comps = REGISTRY_SCRIPT.get_all_registered_components()
	for c in all_comps:
		var is_custom = (REGISTRY_SCRIPT.get_custom_component_definition(c) != null)
		var prefix = "[Scatter] " if is_custom else " "
		comp_list.add_item(prefix + c)

func _on_new_comp_clicked() -> void:
	current_def = DEF_SCRIPT.new("custom_comp_%d" % (int(Time.get_unix_time_from_system()) % 1000), "New Component")
	id_edit.text = current_def.component_id
	name_edit.text = current_def.name
	cat_edit.text = current_def.category
	desc_edit.text = ""
	_refresh_props_tree()
	status_label.text = "Created new component draft."

func _on_comp_selected(idx: int) -> void:
	var txt = comp_list.get_item_text(idx)
	var cid = txt.replace("[Scatter] ", "").replace(" ", "")
	var custom_def = REGISTRY_SCRIPT.get_custom_component_definition(cid)
	if custom_def:
		current_def = custom_def
		id_edit.text = custom_def.component_id
		name_edit.text = custom_def.name
		cat_edit.text = custom_def.category
		desc_edit.text = custom_def.description
		_refresh_props_tree()
	else:
		id_edit.text = cid
		name_edit.text = cid.capitalize()
		cat_edit.text = "Built-in"
		desc_edit.text = "Built-in engine component"
		props_tree.clear()

func _refresh_props_tree() -> void:
	props_tree.clear()
	var root = props_tree.create_item()
	props_tree.hide_root = true
	if not current_def: return
	
	for p in current_def.properties.keys():
		var item = props_tree.create_item(root)
		var p_schema = current_def.properties[p]
		item.set_text(0, "%s (%s = %s)" % [p, str(p_schema.get("type", "")), str(p_schema.get("default", ""))])

func _on_add_property_clicked() -> void:
	if not current_def: return
	var pname = prop_name_edit.text.strip_edges()
	if pname == "": return
	var ptype = prop_type_option.get_item_text(prop_type_option.selected)
	var def_val: Variant = prop_def_edit.text.strip_edges()
	if ptype == "float": def_val = float(def_val) if def_val != "" else 0.0
	elif ptype == "int": def_val = int(def_val) if def_val != "" else 0
	elif ptype == "bool": def_val = (str(def_val).to_lower() == "true")
	
	current_def.add_property(pname, ptype, def_val)
	_refresh_props_tree()
	prop_name_edit.text = ""
	prop_def_edit.text = ""

func _on_save_comp_clicked() -> void:
	if not current_def: return
	current_def.component_id = id_edit.text.strip_edges()
	current_def.name = name_edit.text.strip_edges()
	current_def.category = cat_edit.text.strip_edges()
	current_def.description = desc_edit.text.strip_edges()
	
	REGISTRY_SCRIPT.register_custom_component(current_def)
	_refresh_library()
	status_label.text = "Registered custom component '%s' successfully!" % current_def.component_id
