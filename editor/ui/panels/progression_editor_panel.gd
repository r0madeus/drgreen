class_name ProgressionEditorPanel
extends EditorPanel

var item_list: ItemList
var id_edit: LineEdit
var name_edit: LineEdit
var desc_edit: TextEdit
var req_edit: TextEdit
var current_id: String = ""

func _init() -> void:
	name = "ProgressionEditorPanel"

func _ready() -> void:
	var split = HSplitContainer.new()
	split.set_anchors_preset(PRESET_FULL_RECT)
	add_child(split)
	
	var left = VBoxContainer.new()
	left.custom_minimum_size.x = 200
	var header = HBoxContainer.new()
	var new_btn = Button.new()
	new_btn.text = "New Unlock"
	new_btn.pressed.connect(_on_new)
	header.add_child(new_btn)
	var del_btn = Button.new()
	del_btn.text = "Delete"
	del_btn.pressed.connect(_on_del)
	header.add_child(del_btn)
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
	
	id_edit = _add_field(rbox, "World ID")
	name_edit = _add_field(rbox, "Name")
	
	var dlbl = Label.new(); dlbl.text = "Description"
	rbox.add_child(dlbl)
	desc_edit = TextEdit.new()
	desc_edit.custom_minimum_size.y = 80
	rbox.add_child(desc_edit)
	
	var rlbl = Label.new(); rlbl.text = "Conditions (JSON)"
	rbox.add_child(rlbl)
	req_edit = TextEdit.new()
	req_edit.custom_minimum_size.y = 120
	rbox.add_child(req_edit)
	
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
	ProgressionDataService.ensure_loaded()
	var keys = ProgressionDataService.get_all_unlocks().keys()
	for k in keys:
		item_list.add_item(k)

func _on_selected(idx: int) -> void:
	current_id = item_list.get_item_text(idx)
	var w = ProgressionDataService.get_all_unlocks()[current_id]
	id_edit.text = w.get("id", current_id)
	name_edit.text = w.get("name", "")
	desc_edit.text = w.get("description", "")
	var conds = w.get("unlock_conditions", [])
	req_edit.text = JSON.stringify(conds, "\t")

func _on_new() -> void:
	current_id = ""
	id_edit.text = "new_world"
	name_edit.text = "New World"
	desc_edit.text = ""
	req_edit.text = "[]"

func _on_del() -> void:
	if current_id != "":
		var prev = ProgressionDataService.get_all_unlocks()[current_id]
		var state = {"type": "override", "id": current_id, "data": null}
		_push_undo("Delete Unlock", state, {"type": "override", "id": current_id, "data": prev})
		ProgressionDataService.remove_unlock(current_id)
		ProgressionDataService.save_unlocks()
		current_id = ""
		_refresh_list()

func _on_apply() -> void:
	var j = JSON.new()
	var conds = []
	if j.parse(req_edit.text.strip_edges()) == OK:
		conds = j.get_data()
	if typeof(conds) != TYPE_ARRAY: conds = []
	
	var nid = id_edit.text.strip_edges()
	if nid == "": return
	
	var c = {
		"id": nid,
		"name": name_edit.text.strip_edges(),
		"description": desc_edit.text.strip_edges(),
		"unlock_conditions": conds,
		"unlocked_by_default": false
	}
	
	var prev_state = {}
	if current_id != "":
		prev_state = {"type": "override", "id": current_id, "data": ProgressionDataService.get_all_unlocks().get(current_id)}
	else:
		prev_state = {"type": "override", "id": nid, "data": null}
		
	var new_state = {"type": "override", "id": nid, "data": c}
	_push_undo("Edit Unlock", prev_state, new_state)
	
	if current_id != "" and current_id != nid:
		ProgressionDataService.remove_unlock(current_id)
	ProgressionDataService.update_unlock(nid, c)
	ProgressionDataService.save_unlocks()
	current_id = nid
	_refresh_list()
	
	for i in range(item_list.get_item_count()):
		if item_list.get_item_text(i) == current_id:
			item_list.select(i)
			break

func _push_undo(action_name: String, prev_s: Dictionary, new_s: Dictionary) -> void:
	var es = EditorService.get_instance()
	if es and es.undo_manager:
		var act = EditorUndoManager.EditorAction.new(action_name, "unlocks", "", prev_s, new_s, _apply_undo_state)
		es.undo_manager.push_action(act)

func _apply_undo_state(_id: String, _prop: String, state: Variant) -> void:
	var id = state.get("id", "")
	var d = state.get("data")
	if typeof(d) == TYPE_NIL:
		ProgressionDataService.remove_unlock(id)
	else:
		ProgressionDataService.update_unlock(id, d)
	ProgressionDataService.save_unlocks()
	_refresh_list()
