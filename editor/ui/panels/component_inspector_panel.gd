class_name ComponentInspectorPanel
extends Control

## In-Game Generic Component & Capability Inspector (Phase 41).
## Allows visual attachment, removal, and editing of data-driven components on any entity,
## displaying derived capabilities and live runtime state debugging.

const REGISTRY_SCRIPT = preload("res://core/components/component_registry.gd")
const GENERIC_ENTITY_SCRIPT = preload("res://core/components/generic_entity.gd")

var current_entity: Variant = null

# UI Controls
var entity_name_label: Label
var component_tree: Tree
var capabilities_container: HFlowContainer
var comp_property_editor: TextEdit
var add_comp_option: OptionButton
var status_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(400, 500)
	_build_ui()

func _build_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	add_child(vbox)
	
	var hdr = Label.new()
	hdr.text = " Generic Component & Capability Inspector"
	hdr.add_theme_font_size_override("font_size", 14)
	vbox.add_child(hdr)
	
	entity_name_label = Label.new()
	entity_name_label.text = "Selected Entity: None"
	vbox.add_child(entity_name_label)
	
	# Capabilities List
	var cap_hdr = Label.new()
	cap_hdr.text = "Derived Capabilities:"
	vbox.add_child(cap_hdr)
	
	capabilities_container = HFlowContainer.new()
	capabilities_container.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(capabilities_container)
	
	# Component List & Add Bar
	var add_bar = HBoxContainer.new()
	add_comp_option = OptionButton.new()
	add_comp_option.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var all_comps = REGISTRY_SCRIPT.get_all_registered_components()
	for i in range(all_comps.size()):
		add_comp_option.add_item(all_comps[i], i)
	add_bar.add_child(add_comp_option)
	
	var add_btn = Button.new()
	add_btn.text = "+ Add Component"
	add_btn.pressed.connect(_on_add_component_clicked)
	add_bar.add_child(add_btn)
	vbox.add_child(add_bar)
	
	component_tree = Tree.new()
	component_tree.custom_minimum_size = Vector2(0, 150)
	component_tree.size_flags_vertical = SIZE_EXPAND_FILL
	component_tree.item_selected.connect(_on_component_selected)
	vbox.add_child(component_tree)
	
	var prop_lbl = Label.new()
	prop_lbl.text = "Component Data Schema (JSON):"
	vbox.add_child(prop_lbl)
	
	comp_property_editor = TextEdit.new()
	comp_property_editor.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(comp_property_editor)
	
	var apply_btn = Button.new()
	apply_btn.text = "Apply Component Changes"
	apply_btn.pressed.connect(_on_apply_changes_clicked)
	vbox.add_child(apply_btn)
	
	status_label = Label.new()
	status_label.text = ""
	vbox.add_child(status_label)

func inspect_entity(entity: Variant) -> void:
	current_entity = entity
	if not entity:
		entity_name_label.text = "Selected Entity: None"
		component_tree.clear()
		_clear_capabilities()
		comp_property_editor.text = ""
		return
		
	entity_name_label.text = "Selected: %s (%s)" % [str(entity.name), str(entity.entity_id)]
	_refresh_component_tree()
	_refresh_capabilities()

func _refresh_component_tree() -> void:
	component_tree.clear()
	var root = component_tree.create_item()
	component_tree.hide_root = true
	
	if not current_entity: return
	
	for comp_type in current_entity.components.keys():
		var item = component_tree.create_item(root)
		item.set_text(0, " " + str(comp_type))
		item.set_metadata(0, comp_type)

func _refresh_capabilities() -> void:
	_clear_capabilities()
	if not current_entity: return
	
	var caps = current_entity.get_capabilities()
	for c in caps:
		var badge = Label.new()
		badge.text = "[ %s] " % c.capitalize()
		capabilities_container.add_child(badge)

func _clear_capabilities() -> void:
	for child in capabilities_container.get_children():
		child.queue_free()

func _on_component_selected() -> void:
	var sel = component_tree.get_selected()
	if not sel or not current_entity: return
	var ctype = sel.get_metadata(0)
	var data = current_entity.get_component_data(ctype)
	comp_property_editor.text = JSON.stringify(data, "  ")

func _on_add_component_clicked() -> void:
	if not current_entity: return
	var idx = add_comp_option.selected
	var ctype = add_comp_option.get_item_text(idx)
	if ctype != "":
		current_entity.add_component(ctype)
		_refresh_component_tree()
		_refresh_capabilities()
		status_label.text = "Added component '%s'" % ctype

func _on_apply_changes_clicked() -> void:
	var sel = component_tree.get_selected()
	if not sel or not current_entity: return
	var ctype = sel.get_metadata(0)
	var parsed = JSON.parse_string(comp_property_editor.text)
	if parsed is Dictionary:
		var comp = current_entity.get_component(ctype)
		if comp:
			comp.data = parsed
			status_label.text = "Component '%s' updated successfully." % ctype
