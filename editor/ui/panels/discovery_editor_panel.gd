class_name DiscoveryEditorPanel
extends EditorPanel

var item_list: ItemList
var id_edit: LineEdit
var name_edit: LineEdit
var type_edit: LineEdit
var desc_edit: TextEdit

var current_id: String = ""
var current_type: String = ""

func _init() -> void:
	name = "DiscoveryEditorPanel"

func _ready() -> void:
	var split = HSplitContainer.new()
	split.set_anchors_preset(PRESET_FULL_RECT)
	add_child(split)
	
	var left = VBoxContainer.new()
	left.custom_minimum_size.x = 200
	var header = HBoxContainer.new()
	var l = Label.new(); l.text = "Codex Discoveries"
	header.add_child(l)
	left.add_child(header)
	
	item_list = ItemList.new()
	item_list.size_flags_vertical = SIZE_EXPAND_FILL
	item_list.item_selected.connect(_on_selected)
	left.add_child(item_list)
	split.add_child(left)
	
	var right = ScrollContainer.new()
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	var rbox = VBoxContainer.new()
	right.add_child(rbox)
	
	type_edit = _add_field(rbox, "Type")
	type_edit.editable = false
	id_edit = _add_field(rbox, "Target ID")
	id_edit.editable = false
	name_edit = _add_field(rbox, "Display Name")
	
	var dlbl = Label.new(); dlbl.text = "Description"
	rbox.add_child(dlbl)
	desc_edit = TextEdit.new()
	desc_edit.custom_minimum_size.y = 80
	rbox.add_child(desc_edit)
	
	var apply_btn = Button.new()
	apply_btn.text = "Apply Changes"
	apply_btn.pressed.connect(_on_apply)
	rbox.add_child(apply_btn)
	
	split.add_child(right)
	_refresh_list()

func _add_field(parent: Control, lbl: String) -> LineEdit:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = lbl
	label.custom_minimum_size.x = 100
	hbox.add_child(label)
	var le = LineEdit.new()
	le.size_flags_horizontal = SIZE_EXPAND_FILL
	hbox.add_child(le)
	parent.add_child(hbox)
	return le

func _refresh_list() -> void:
	item_list.clear()
	var es = EditorService.get_instance()
	if es and es.data_service:
		var ids = es.data_service.get_all_stable_ids()
		for id in ids:
			if id.begins_with("plant."):
				item_list.add_item("[Plant] " + id.replace("plant.", ""))
	CombinationDataService.ensure_loaded()
	for c in CombinationDataService.get_all_combos():
		item_list.add_item("[Combo] " + c.get("id", ""))

func _on_selected(idx: int) -> void:
	var txt = item_list.get_item_text(idx)
	if txt.begins_with("[Plant] "):
		current_type = "plant"
		current_id = txt.replace("[Plant] ", "")
		var es = EditorService.get_instance()
		var d = es.data_service.get_resolved_object("plant." + current_id)
		id_edit.text = current_id
		type_edit.text = "Plant"
		name_edit.text = d.get("name", "")
		desc_edit.text = d.get("description", "")
	elif txt.begins_with("[Combo] "):
		current_type = "combo"
		current_id = txt.replace("[Combo] ", "")
		for c in CombinationDataService.get_all_combos():
			if c.get("id") == current_id:
				id_edit.text = current_id
				type_edit.text = "Formula"
				name_edit.text = c.get("name", "")
				desc_edit.text = c.get("description", "")
				break

func _on_apply() -> void:
	var es = EditorService.get_instance()
	if current_type == "plant":
		var d = es.data_service.get_resolved_object("plant." + current_id)
		var new_d = d.duplicate()
		new_d["name"] = name_edit.text.strip_edges()
		new_d["description"] = desc_edit.text.strip_edges()
		es.data_service.set_override("plant." + current_id, new_d)
		es.data_service.save_active_project()
	elif current_type == "combo":
		var idx = -1
		var combos = CombinationDataService.get_all_combos()
		for i in range(combos.size()):
			if combos[i].get("id") == current_id:
				idx = i
				break
		if idx >= 0:
			var new_c = combos[idx].duplicate()
			new_c["name"] = name_edit.text.strip_edges()
			new_c["description"] = desc_edit.text.strip_edges()
			CombinationDataService.update_combo(idx, new_c)
			CombinationDataService.save_combos()
