class_name AudioEditorPanel
extends EditorPanel

## Phase 3D — Audio & SFX Authoring Editor
## Configures audio assets mapping (Music, SFX, Ambience, etc.)
## and integrates with EditorDataService and AudioManager.

const AudioDataServiceScript = preload("res://systems/audio/audio_data_service.gd")

var search_edit: LineEdit
var category_option: OptionButton
var audio_list: ItemList
var preview_player: AudioStreamPlayer
var id_edit: LineEdit
var path_edit: LineEdit
var world_option: OptionButton
var type_option: OptionButton

var current_audio_id: String = ""
var current_audio_data: Variant = null

var worlds_cache: Dictionary = {}

func _init() -> void:
	panel_id = "audio"
	display_name_key = "ui.editor.cat_audio"
	icon_asset_id = "icon_audio"

func setup_ui() -> void:
	AudioDataServiceScript.load_catalog()
	
	var main_split = HSplitContainer.new()
	add_child(main_split)
	main_split.set_anchors_preset(PRESET_FULL_RECT)
	
	var left_panel = VBoxContainer.new()
	main_split.add_child(left_panel)
	left_panel.custom_minimum_size.x = 250
	
	var search_hbox = HBoxContainer.new()
	left_panel.add_child(search_hbox)
	
	search_edit = LineEdit.new()
	search_edit.placeholder_text = "Search ID or Path..."
	search_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	search_edit.text_changed.connect(func(t): _refresh_list())
	search_hbox.add_child(search_edit)
	
	category_option = OptionButton.new()
	category_option.add_item("All")
	category_option.add_item("Music")
	category_option.add_item("SFX")
	category_option.add_item("Ambience")
	category_option.add_item("UI")
	category_option.add_item("Event")
	category_option.add_item("Cutscene")
	category_option.add_item("World")
	category_option.item_selected.connect(func(idx): _refresh_list())
	search_hbox.add_child(category_option)
	
	audio_list = ItemList.new()
	audio_list.size_flags_vertical = SIZE_EXPAND_FILL
	audio_list.item_selected.connect(_on_audio_selected)
	left_panel.add_child(audio_list)
	
	var new_btn = Button.new()
	new_btn.text = "Add Definition"
	new_btn.pressed.connect(_on_new_pressed)
	left_panel.add_child(new_btn)
	
	var right_panel = VBoxContainer.new()
	main_split.add_child(right_panel)
	right_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	
	var form = GridContainer.new()
	form.columns = 2
	right_panel.add_child(form)
	
	var lbl_3582 = Label.new()
	lbl_3582.text = "Logical ID:"
	form.add_child(lbl_3582)
	id_edit = LineEdit.new()
	form.add_child(id_edit)
	
	var lbl_9192 = Label.new()
	lbl_9192.text = "Asset Path:"
	form.add_child(lbl_9192)
	var path_hbox = HBoxContainer.new()
	path_edit = LineEdit.new()
	path_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	path_hbox.add_child(path_edit)
	form.add_child(path_hbox)
	
	var lbl_3782 = Label.new()
	lbl_3782.text = "World (optional):"
	form.add_child(lbl_3782)
	world_option = OptionButton.new()
	form.add_child(world_option)
	
	var lbl_4914 = Label.new()
	lbl_4914.text = "Type:"
	form.add_child(lbl_4914)
	type_option = OptionButton.new()
	type_option.add_item("None")
	type_option.add_item("Music")
	type_option.add_item("Ambient")
	form.add_child(type_option)
	
	var actions_hbox = HBoxContainer.new()
	right_panel.add_child(actions_hbox)
	
	var apply_btn = Button.new()
	apply_btn.text = "Apply & Save"
	apply_btn.pressed.connect(_on_apply_pressed)
	actions_hbox.add_child(apply_btn)
	
	var delete_btn = Button.new()
	delete_btn.text = "Delete"
	delete_btn.pressed.connect(_on_delete_pressed)
	actions_hbox.add_child(delete_btn)
	
	var play_btn = Button.new()
	play_btn.text = "Play"
	play_btn.pressed.connect(_on_play_pressed)
	actions_hbox.add_child(play_btn)
	
	var stop_btn = Button.new()
	stop_btn.text = "Stop"
	stop_btn.pressed.connect(_on_stop_pressed)
	actions_hbox.add_child(stop_btn)
	
	var unsupported_lbl = Label.new()
	unsupported_lbl.text = "Note: Fades, Variations, and Priorities are not natively supported by AudioManager."
	unsupported_lbl.modulate = Color(0.7, 0.7, 0.7)
	right_panel.add_child(unsupported_lbl)
	
	preview_player = AudioStreamPlayer.new()
	preview_player.name = "EditorAudioPreview"
	add_child(preview_player)
	
	_load_worlds()
	_refresh_list()

func _load_worlds() -> void:
	worlds_cache.clear()
	world_option.clear()
	world_option.add_item("None")
	var f = FileAccess.open("res://data/worlds/worlds.json", FileAccess.READ)
	if f:
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			worlds_cache = json.data.get("worlds", {})
			for w_id in worlds_cache:
				world_option.add_item(w_id)
				world_option.set_item_metadata(world_option.item_count - 1, w_id)

func _refresh_list() -> void:
	if not audio_list: return
	audio_list.clear()
	
	var filter = search_edit.text.to_lower()
	var cat_idx = category_option.selected
	var cat_name = category_option.get_item_text(cat_idx).to_lower()
	
	# Combine mapped definitions
	var overrides = AudioDataServiceScript.get_all_overrides()
	var all_items = overrides.keys()
	
	# Also include world music/ambient definitions for easy editing
	for w_id in worlds_cache:
		var meta = worlds_cache[w_id].get("metadata", {})
		if meta.has("music"):
			all_items.append("world_music:" + w_id)
		if meta.has("ambient"):
			all_items.append("world_ambient:" + w_id)
	
	# Deduplicate
	var unique_items = []
	for i in all_items:
		if not i in unique_items: unique_items.append(i)
	
	for sound_id in unique_items:
		if filter != "" and filter not in sound_id.to_lower(): continue
		
		# Basic categorization logic
		if cat_name != "all":
			if cat_name == "music" and not ("music" in sound_id.to_lower() or "bgm" in sound_id.to_lower()): continue
			if cat_name == "sfx" and "music" in sound_id.to_lower(): continue
			if cat_name == "ui" and not "ui" in sound_id.to_lower(): continue
			if cat_name == "world" and not "world_" in sound_id.to_lower(): continue
		
		audio_list.add_item(sound_id)
		audio_list.set_item_metadata(audio_list.item_count - 1, sound_id)

func _on_audio_selected(idx: int) -> void:
	_on_stop_pressed()
	current_audio_id = audio_list.get_item_metadata(idx)
	id_edit.text = current_audio_id
	
	if current_audio_id.begins_with("world_music:"):
		var wid = current_audio_id.replace("world_music:", "")
		var meta = worlds_cache.get(wid, {}).get("metadata", {})
		path_edit.text = meta.get("music", "")
		_set_option_meta(world_option, wid)
		type_option.selected = 1
	elif current_audio_id.begins_with("world_ambient:"):
		var wid = current_audio_id.replace("world_ambient:", "")
		var meta = worlds_cache.get(wid, {}).get("metadata", {})
		path_edit.text = meta.get("ambient", "")
		_set_option_meta(world_option, wid)
		type_option.selected = 2
	else:
		world_option.selected = 0
		type_option.selected = 0
		var data = AudioDataServiceScript.get_override(current_audio_id)
		path_edit.text = data if data is String else data.get("path", "")

func _set_option_meta(opt: OptionButton, val: String) -> void:
	for i in range(opt.item_count):
		if opt.get_item_metadata(i) == val:
			opt.selected = i
			return
	opt.selected = 0

func _on_new_pressed() -> void:
	_on_stop_pressed()
	current_audio_id = "new_audio_" + str(randi() % 1000)
	id_edit.text = current_audio_id
	path_edit.text = ""
	world_option.selected = 0
	type_option.selected = 0

func _on_apply_pressed() -> void:
	var new_id = id_edit.text.strip_edges()
	var new_path = path_edit.text.strip_edges()
	
	if not EditorValidationService.validate_audio({"id": new_id, "path": new_path}):
		print("[AudioEditor] Validation failed.")
		return
	
	var prev_state = {}
	if current_audio_id.begins_with("world_"):
		prev_state = {"type": "world", "id": current_audio_id, "path": AudioDataServiceScript.get_override(current_audio_id)}
	else:
		prev_state = {"type": "override", "id": current_audio_id, "path": AudioDataServiceScript.get_override(current_audio_id)}
	
	var new_state = {"type": "override", "id": new_id, "path": new_path}
	if world_option.selected > 0:
		var wid = world_option.get_item_metadata(world_option.selected)
		if type_option.selected == 1:
			new_state = {"type": "world_music", "world": wid, "path": new_path}
		elif type_option.selected == 2:
			new_state = {"type": "world_ambient", "world": wid, "path": new_path}
	
	var action = EditorUndoManager.EditorAction.new("Assign Audio", new_id, "audio", prev_state, new_state, _apply_state)
	EditorService.get_instance().undo_manager.push_action(action)
	
	_apply_state(new_id, "audio", new_state)

func _on_delete_pressed() -> void:
	var prev_state = {"type": "override", "id": current_audio_id, "path": AudioDataServiceScript.get_override(current_audio_id)}
	var new_state = {"type": "delete", "id": current_audio_id}
	var action = EditorUndoManager.EditorAction.new("Delete Audio", current_audio_id, "audio", prev_state, new_state, _apply_state)
	EditorService.get_instance().undo_manager.push_action(action)
	_apply_state(current_audio_id, "audio", new_state)

func _apply_state(_id: String, _prop: String, state: Variant) -> void:

	var stype = state.get("type", "")
	print("[DEBUG_APPLY] type: ", stype, " state: ", state)

	if stype == "override":
		AudioDataServiceScript.set_override(state.get("id"), state.get("path"))
		AudioDataServiceScript.save_catalog()
		AudioDataServiceScript.apply_to_runtime()
	elif stype == "delete":
		AudioDataServiceScript.remove_override(state.get("id"))
		AudioDataServiceScript.save_catalog()
		AudioDataServiceScript.apply_to_runtime()
	elif stype == "world_music" or stype == "world_ambient":
		var wid = state.get("world")
		var wpath = state.get("path")
		var file = "res://data/worlds/worlds.json"
		var f = FileAccess.open(file, FileAccess.READ)
		if f:
			var content = f.get_as_text()
			var json = JSON.new()
			if json.parse(content) == OK:
				var wdata = json.data
				if wdata.has("worlds") and wdata["worlds"].has(wid):
					if not wdata["worlds"][wid].has("metadata"):
						wdata["worlds"][wid]["metadata"] = {}
					if stype == "world_music":
						wdata["worlds"][wid]["metadata"]["music"] = wpath
					else:
						wdata["worlds"][wid]["metadata"]["ambient"] = wpath
					var wf = FileAccess.open(file, FileAccess.WRITE)
					wf.store_string(JSON.stringify(wdata, "\t"))
					_load_worlds()
	_refresh_list()

func _on_play_pressed() -> void:
	var path = path_edit.text.strip_edges()
	if path == "" or not ResourceLoader.exists(path):
		# Try asking AudioManager for the path if it's an alias
		var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
		var am = root.get_node_or_null("/root/AudioManager") if root else null
		if am and am.has_method("get_sound_stream"):
			var stream = am.get_sound_stream(path)
			if stream:
				preview_player.stream = stream
				preview_player.play()
		return
	var s = ResourceLoader.load(path) as AudioStream
	if s:
		preview_player.stream = s
		preview_player.play()

func _on_stop_pressed() -> void:
	if preview_player.playing:
		preview_player.stop()

func _exit_tree() -> void:
	_on_stop_pressed()
