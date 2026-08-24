extends Node



## Central Local Client State Manager (Autoload Singleton).
## Manages device-specific local preferences, persistence to user://local_settings.json, and hardware/system application.

signal local_state_changed(section: String, key: String, value: Variant)
signal settings_applied()

const LOCAL_SETTINGS_FILE: String = "user://local_settings.json"
const LEGACY_SETTINGS_FILE: String = "user://settings.json"

static var instance = null


var state: LocalState

func _init() -> void:
	instance = self
	state = LocalState.create_default()

func _ready() -> void:
	instance = self
	load_local_state()
	apply_all()

func load_local_state() -> void:
	var path_to_load = LOCAL_SETTINGS_FILE
	var is_legacy = false
	
	if not FileAccess.file_exists(LOCAL_SETTINGS_FILE):
		if FileAccess.file_exists(LEGACY_SETTINGS_FILE):
			path_to_load = LEGACY_SETTINGS_FILE
			is_legacy = true
		else:
			state = LocalState.create_default()
			save_local_state()
			return
			
	var f = FileAccess.open(path_to_load, FileAccess.READ)
	if not f:
		push_warning("[LocalStateManager] Could not open %s, using defaults." % path_to_load)
		state = LocalState.create_default()
		save_local_state()
		return
		
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("[LocalStateManager] Corrupted settings JSON in %s. Recovering to defaults." % path_to_load)
		state = LocalState.create_default()
		save_local_state()
		return
		
	state = LocalState.from_dict(json.data)
	if is_legacy:
		print("[LocalStateManager] Successfully migrated legacy settings.json to local_settings.json")
		save_local_state()

func save_local_state() -> void:
	var f = FileAccess.open(LOCAL_SETTINGS_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(state.to_dict(), "  "))
		f.close()

func get_setting(section: String, key: String, default_val: Variant = null) -> Variant:
	return state.get_value(section, key, default_val) if state else default_val

func set_setting(section: String, key: String, value: Variant, auto_save: bool = true) -> void:
	if not state: return
	state.set_value(section, key, value)
	local_state_changed.emit(section, key, value)
	if auto_save:
		save_local_state()

func apply_all() -> void:
	apply_display()
	apply_audio()
	apply_controls()
	apply_accessibility()
	apply_language()
	settings_applied.emit()

func apply_language() -> void:
	if not state: return
	var lang = str(state.get_value("language", "current_language", "en"))
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.set_locale(lang, false)
	else:
		TranslationServer.set_locale(lang)


func apply_display() -> void:
	if not state: return
	
	# 1. Parse resolution
	var res_str = str(state.get_value("graphics", "resolution", "1152x648"))
	var parts = res_str.split("x")
	var target_w = 1152
	var target_h = 648
	if parts.size() == 2:
		target_w = maxi(640, int(parts[0]))
		target_h = maxi(360, int(parts[1]))
	var target_size = Vector2i(target_w, target_h)
	
	# 2. Window Mode
	var mode_str = str(state.get_value("graphics", "window_mode", "windowed")).to_lower()
	match mode_str:
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"exclusive_fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen_size = DisplayServer.screen_get_size()
			if screen_size.x > 0 and screen_size.y > 0:
				DisplayServer.window_set_size(screen_size)
				DisplayServer.window_set_position(Vector2i.ZERO)
		"windowed", _:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(target_size)
			var screen_size = DisplayServer.screen_get_size()
			if screen_size.x > target_size.x and screen_size.y > target_size.y:
				DisplayServer.window_set_position((screen_size - target_size) / 2)
				
	# 3. VSync
	var vsync_on = bool(state.get_value("graphics", "vsync", true))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_on else DisplayServer.VSYNC_DISABLED)
	
	# 4. FPS Limit (0 = unlimited)
	var fps = int(state.get_value("graphics", "fps_limit", 60))
	Engine.max_fps = fps if fps > 0 else 0
	
	# 5. Camera Zoom
	var cam_zoom = float(state.get_value("graphics", "camera_zoom", 1.0))
	var player = get_tree().root.find_child("Player", true, false)
	if player:
		var cam = player.get_node_or_null("Camera2D") as Camera2D
		if cam: cam.zoom = Vector2(cam_zoom, cam_zoom)


func apply_audio() -> void:
	if not state: return
	var am = get_node_or_null("/root/AudioManager")
	if not am: return
	
	var master_vol = int(state.get_value("audio", "master_volume", 100))
	var music_vol = int(state.get_value("audio", "music_volume", 70))
	var sfx_vol = int(state.get_value("audio", "sfx_volume", 100))
	
	if am.has_method("set_volume"):
		am.set_volume("master", master_vol)
		am.set_volume("music", music_vol)
		am.set_volume("sfx", sfx_vol)

func apply_controls() -> void:
	if not state: return
	var binds = state.controls
	for action in binds.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		else:
			InputMap.action_erase_events(action)
			
		var keys_list = binds[action]
		if typeof(keys_list) == TYPE_ARRAY:
			for key_name in keys_list:
				var ev = _create_input_event(str(key_name))
				if ev: InputMap.action_add_event(action, ev)

func _create_input_event(key_str: String) -> InputEvent:
	var s = key_str.to_lower().strip_edges()
	if s in ["mouseleft", "mouse_left", "lmb", "mouse 1", "button1"]:
		var mb = InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		return mb
	elif s in ["mouseright", "mouse_right", "rmb", "mouse 2", "button2"]:
		var mb = InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_RIGHT
		return mb
	elif s in ["mousemiddle", "mouse_middle", "mmb", "mouse 3", "button3"]:
		var mb = InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_MIDDLE
		return mb
	elif s in ["mousewheelup", "wheelup", "wheel_up", "mouse 4", "button4"]:
		var mb = InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_WHEEL_UP
		return mb
	elif s in ["mousewheeldown", "wheeldown", "wheel_down", "mouse 5", "button5"]:
		var mb = InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_WHEEL_DOWN
		return mb
		
	var code = OS.find_keycode_from_string(key_str)
	if code != KEY_NONE:
		var ev = InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		return ev
	return null

func apply_accessibility() -> void:
	# Applied dynamically in UI and effect spawners
	pass
