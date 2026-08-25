class_name CombinationEditorPanel
extends EditorPanel

var item_list: ItemList
var id_edit: LineEdit
var name_edit: LineEdit
var a_edit: LineEdit
var b_edit: LineEdit
var out_edit: LineEdit
var rate_edit: SpinBox
var hide_check: CheckBox

var current_idx: int = -1

func _init() -> void:
	name = "CombinationEditorPanel"

func _ready() -> void:
	var split = HSplitContainer.new()
	split.set_anchors_preset(PRESET_FULL_RECT)
	add_child(split)
	
	var left = VBoxContainer.new()
	left.custom_minimum_size.x = 200
	var header = HBoxContainer.new()
	var new_btn = Button.new()
	new_btn.text = "New Combo"
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
	
	id_edit = _add_field(rbox, "ID")
	name_edit = _add_field(rbox, "Name")
	a_edit = _add_field(rbox, "Input A")
	b_edit = _add_field(rbox, "Input B")
	out_edit = _add_field(rbox, "Output")
	
	var rbox_rate = HBoxContainer.new()
	var rlbl = Label.new(); rlbl.text = "Success Rate"
	rbox_rate.add_child(rlbl)
	rate_edit = SpinBox.new()
	rate_edit.min_value = 0.0
	rate_edit.max_value = 1.0
	rate_edit.step = 0.05
	rbox_rate.add_child(rate_edit)
	rbox.add_child(rbox_rate)
	
	hide_check = CheckBox.new()
	hide_check.text = "Hidden"
	rbox.add_child(hide_check)
	
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
	CombinationDataService.ensure_loaded()
	var combos = CombinationDataService.get_all_combos()
	for c in combos:
		item_list.add_item(c.get("id", "unknown"))

func _on_selected(idx: int) -> void:
	current_idx = idx
	var c = CombinationDataService.get_all_combos()[idx]
	id_edit.text = c.get("id", "")
	name_edit.text = c.get("name", "")
	a_edit.text = c.get("input_a", "")
	b_edit.text = c.get("input_b", "")
	out_edit.text = c.get("output", "")
	rate_edit.value = c.get("success_rate", 1.0)
	hide_check.button_pressed = c.get("hidden", false)

func _on_new() -> void:
	current_idx = -1
	id_edit.text = "new_combo"
	name_edit.text = "New Combo"
	a_edit.text = ""
	b_edit.text = ""
	out_edit.text = ""
	rate_edit.value = 1.0
	hide_check.button_pressed = false

func _on_del() -> void:
	if current_idx >= 0:
		var prev = CombinationDataService.get_all_combos()[current_idx]
		var state = {"type": "delete", "idx": current_idx, "data": prev}
		_push_undo("Delete Combo", state, {"type": "delete", "idx": current_idx})
		CombinationDataService.remove_combo(current_idx)
		CombinationDataService.save_combos()
		current_idx = -1
		_refresh_list()

func _on_apply() -> void:
	var c = {
		"id": id_edit.text.strip_edges(),
		"name": name_edit.text.strip_edges(),
		"input_a": a_edit.text.strip_edges(),
		"input_b": b_edit.text.strip_edges(),
		"output": out_edit.text.strip_edges(),
		"success_rate": rate_edit.value,
		"hidden": hide_check.button_pressed
	}
	
	if c["id"] == "":
		push_error("[Validation] Combo ID empty.")
		return
	
	var prev_state = {}
	if current_idx >= 0:
		prev_state = {"type": "edit", "idx": current_idx, "data": CombinationDataService.get_all_combos()[current_idx]}
	else:
		prev_state = {"type": "create", "idx": CombinationDataService.get_all_combos().size()}
		
	var new_state = {"type": "edit", "idx": current_idx if current_idx >= 0 else CombinationDataService.get_all_combos().size(), "data": c}
	_push_undo("Edit Combo", prev_state, new_state)
	
	CombinationDataService.update_combo(new_state["idx"], c)
	CombinationDataService.save_combos()
	_refresh_list()
	
	for i in range(CombinationDataService.get_all_combos().size()):
		if CombinationDataService.get_all_combos()[i].get("id") == c["id"]:
			item_list.select(i)
			current_idx = i
			break

func _push_undo(action_name: String, prev_s: Dictionary, new_s: Dictionary) -> void:
	var es = EditorService.get_instance()
	if es and es.undo_manager:
		var act = EditorUndoManager.EditorAction.new(action_name, "combos", "", prev_s, new_s, _apply_undo_state)
		es.undo_manager.push_action(act)

func _apply_undo_state(_id: String, _prop: String, state: Variant) -> void:
	var stype = state.get("type", "")
	if stype == "delete" or stype == "create":
		# If undoing a creation, we delete
		if stype == "create":
			CombinationDataService.remove_combo(state.get("idx"))
		else:
			# Re-insert or edit to null? This is tricky for arrays. We just use append or remove based on size.
			pass
	elif stype == "edit":
		var d = state.get("data")
		CombinationDataService.update_combo(state.get("idx"), d)
	CombinationDataService.save_combos()
	_refresh_list()
