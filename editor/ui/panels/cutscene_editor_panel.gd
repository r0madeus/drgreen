class_name CutsceneEditorPanel
extends EditorPanel

const CutsceneManagerScript = preload("res://systems/cutscene/cutscene_manager.gd")
const CutscenePlayerScript = preload("res://systems/cutscene/cutscene_player.gd")

signal cutscene_selected(cid: String)
signal preview_requested(cid: String)

var current_cutscene_id: String = ""
var current_cutscene_data: Dictionary = {}
var selected_event_index: int = -1
var selected_track_index: int = -1

var cutscene_list: ItemList
var id_edit: LineEdit
var name_edit: LineEdit
var duration_spin: SpinBox
var timeline_container: VBoxContainer
var tracks_container: VBoxContainer
var event_inspector: VBoxContainer

var cutscene_manager: Node = null

func _init() -> void:
	panel_id = "cutscene"
	display_name_key = "ui.editor.cat_cutscene"
	icon_asset_id = "icon_cutscene"

func setup_ui() -> void:
	var main_split = HSplitContainer.new()
	add_child(main_split)
	main_split.set_anchors_preset(PRESET_FULL_RECT)
	
	var left_panel = VBoxContainer.new()
	main_split.add_child(left_panel)
	left_panel.custom_minimum_size.x = 200
	
	var top_left = HBoxContainer.new()
	left_panel.add_child(top_left)
	var new_btn = Button.new()
	new_btn.text = "New"
	new_btn.pressed.connect(_on_new_pressed)
	top_left.add_child(new_btn)
	
	cutscene_list = ItemList.new()
	cutscene_list.size_flags_vertical = SIZE_EXPAND_FILL
	cutscene_list.item_selected.connect(_on_cutscene_selected)
	left_panel.add_child(cutscene_list)
	
	var right_split = VSplitContainer.new()
	main_split.add_child(right_split)
	right_split.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var top_editor = VBoxContainer.new()
	right_split.add_child(top_editor)
	
	var header_hbox = HBoxContainer.new()
	top_editor.add_child(header_hbox)
	id_edit = LineEdit.new()
	id_edit.text_changed.connect(func(t): current_cutscene_data["id"] = t)
	header_hbox.add_child(id_edit)
	name_edit = LineEdit.new()
	name_edit.text_changed.connect(func(t): current_cutscene_data["display_name"] = t)
	header_hbox.add_child(name_edit)
	duration_spin = SpinBox.new()
	duration_spin.max_value = 600
	duration_spin.step = 0.1
	duration_spin.value_changed.connect(func(v): current_cutscene_data["duration"] = v)
	header_hbox.add_child(duration_spin)
	
	var save_btn = Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save_pressed)
	header_hbox.add_child(save_btn)
	
	var preview_btn = Button.new()
	preview_btn.text = "Preview"
	preview_btn.pressed.connect(_on_preview_pressed)
	header_hbox.add_child(preview_btn)
	
	timeline_container = VBoxContainer.new()
	top_editor.add_child(timeline_container)
	timeline_container.size_flags_vertical = SIZE_EXPAND_FILL
	
	tracks_container = VBoxContainer.new()
	timeline_container.add_child(tracks_container)
	
	var inspector_panel = PanelContainer.new()
	right_split.add_child(inspector_panel)
	inspector_panel.custom_minimum_size.y = 150
	event_inspector = VBoxContainer.new()
	inspector_panel.add_child(event_inspector)
	
	if not cutscene_manager:
		cutscene_manager = CutsceneManagerScript.new()
		add_child(cutscene_manager)
	cutscene_manager.catalog_updated.connect(_refresh_list)
	_refresh_list()

func _refresh_list() -> void:
	if not cutscene_list: return
	cutscene_list.clear()
	for cid in cutscene_manager.cutscene_catalog:
		var disp = cutscene_manager.cutscene_catalog[cid].get("display_name", cid)
		cutscene_list.add_item(disp)
		cutscene_list.set_item_metadata(cutscene_list.item_count - 1, cid)

func _on_new_pressed() -> void:
	var cid = "cutscene_%d" % (cutscene_manager.cutscene_catalog.size() + 1)
	var data = cutscene_manager.create_new_cutscene(cid)
	_load_cutscene(cid)

func _on_cutscene_selected(idx: int) -> void:
	var cid = cutscene_list.get_item_metadata(idx)
	_load_cutscene(cid)

func _load_cutscene(cid: String) -> void:
	current_cutscene_id = cid
	current_cutscene_data = cutscene_manager.get_cutscene(cid)
	id_edit.text = current_cutscene_data.get("id", "")
	name_edit.text = current_cutscene_data.get("display_name", "")
	duration_spin.value = current_cutscene_data.get("duration", 5.0)
	_refresh_timeline()

func _refresh_timeline() -> void:
	for c in tracks_container.get_children():
		c.queue_free()
	
	var tracks = current_cutscene_data.get("tracks", [])
	for tidx in range(tracks.size()):
		var track = tracks[tidx]
		var row = HBoxContainer.new()
		var header = Label.new()
		header.text = track.get("actor_id", "System")
		header.custom_minimum_size.x = 100
		row.add_child(header)
		
		var content = ColorRect.new()
		content.color = Color(0.2, 0.2, 0.2)
		content.size_flags_horizontal = SIZE_EXPAND_FILL
		content.custom_minimum_size.y = 40
		row.add_child(content)
		
		tracks_container.add_child(row)

func _on_save_pressed() -> void:
	if not EditorValidationService.validate_cutscene(current_cutscene_data):
		print("[CutsceneEditor] Validation failed.")
		return
	cutscene_manager.save_cutscene(current_cutscene_data)

func _on_preview_pressed() -> void:
	preview_requested.emit(current_cutscene_id)
	
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	if root:
		var player = CutscenePlayerScript.new()
		root.add_child(player)
		player.play(current_cutscene_id)
		player.finished.connect(func(cid): player.queue_free())

func add_event(track_index: int, type: String, start_time: float, duration: float, params: Dictionary = {}) -> void:
	var prev = current_cutscene_data.duplicate(true)
	var tracks = current_cutscene_data.get("tracks", [])
	if track_index < 0 or track_index >= tracks.size(): return
	
	var new_event = { "type": type, "start": start_time, "duration": duration, "params": params }
	tracks[track_index]["events"].append(new_event)
	
	var action = EditorUndoManager.EditorAction.new("Add Event", current_cutscene_id, "tracks", prev, current_cutscene_data, _apply_state)
	EditorService.get_instance().undo_manager.push_action(action)
	_refresh_timeline()

func delete_event(track_index: int, event_index: int) -> void:
	var prev = current_cutscene_data.duplicate(true)
	var tracks = current_cutscene_data.get("tracks", [])
	if track_index >= 0 and track_index < tracks.size():
		var evts = tracks[track_index].get("events", [])
		if event_index >= 0 and event_index < evts.size():
			evts.remove_at(event_index)
			var action = EditorUndoManager.EditorAction.new("Delete Event", current_cutscene_id, "tracks", prev, current_cutscene_data, _apply_state)
			EditorService.get_instance().undo_manager.push_action(action)
	_refresh_timeline()

func move_event(track_index: int, event_index: int, new_start: float) -> void:
	var prev = current_cutscene_data.duplicate(true)
	var tracks = current_cutscene_data.get("tracks", [])
	if track_index >= 0 and track_index < tracks.size():
		var evts = tracks[track_index].get("events", [])
		if event_index >= 0 and event_index < evts.size():
			evts[event_index]["start"] = new_start
			var action = EditorUndoManager.EditorAction.new("Move Event", current_cutscene_id, "tracks", prev, current_cutscene_data, _apply_state)
			EditorService.get_instance().undo_manager.push_action(action)
	_refresh_timeline()

func set_event_duration(track_index: int, event_index: int, new_dur: float) -> void:
	var prev = current_cutscene_data.duplicate(true)
	var tracks = current_cutscene_data.get("tracks", [])
	if track_index >= 0 and track_index < tracks.size():
		var evts = tracks[track_index].get("events", [])
		if event_index >= 0 and event_index < evts.size():
			evts[event_index]["duration"] = new_dur
			var action = EditorUndoManager.EditorAction.new("Resize Event", current_cutscene_id, "tracks", prev, current_cutscene_data, _apply_state)
			EditorService.get_instance().undo_manager.push_action(action)
	_refresh_timeline()

func _apply_state(_id: String, _prop: String, state: Variant) -> void:
	current_cutscene_data = state.duplicate(true)
	id_edit.text = current_cutscene_data.get("id", "")
	name_edit.text = current_cutscene_data.get("display_name", "")
	_refresh_timeline()
