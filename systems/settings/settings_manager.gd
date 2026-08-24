extends Node

## Central Settings Manager Facade adapting to the decoupled LocalStateManager (Autoload).

signal settings_applied()
signal setting_changed(category: String, key: String, value: Variant)

var settings: Dictionary:
	get:
		var lsm = get_node_or_null("/root/LocalStateManager")
		if lsm and lsm.state:
			return lsm.state.to_dict()
		return SettingsData.get_default_settings()
	set(val):
		var lsm = get_node_or_null("/root/LocalStateManager")
		if lsm:
			lsm.state = LocalState.from_dict(val)

func _ready() -> void:
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		lsm.local_state_changed.connect(_on_local_state_changed)
		lsm.settings_applied.connect(_on_local_settings_applied)
	load_and_apply_settings()

func _on_local_state_changed(section: String, key: String, value: Variant) -> void:
	setting_changed.emit(section, key, value)

func _on_local_settings_applied() -> void:
	settings_applied.emit()

func load_and_apply_settings() -> void:
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		lsm.load_local_state()
		lsm.apply_all()
	apply_all_settings()
	print("[SettingsManager] LocalState loaded and applied successfully.")

func get_setting(category: String, key: String, default_val: Variant = null) -> Variant:
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		return lsm.get_setting(category, key, default_val)
	return default_val

func set_setting(category: String, key: String, value: Variant, auto_save: bool = false) -> void:
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		lsm.set_setting(category, key, value, auto_save)
	setting_changed.emit(category, key, value)

func save_settings() -> bool:
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		lsm.save_local_state()
		return true
	return false

func reset_to_defaults() -> void:
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		lsm.state = LocalState.create_default()
		lsm.save_local_state()
		lsm.apply_all()
	apply_all_settings()


func apply_all_settings() -> void:
	apply_graphics_settings()
	apply_audio_settings()
	apply_controls_settings()
	settings_applied.emit()

func apply_graphics_settings() -> void:
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		lsm.apply_display()
	else:
		var g = settings.get("graphics", {})
		var w_mode = str(g.get("window_mode", "windowed")).to_lower()
		match w_mode:
			"fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			"borderless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			_: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED); DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		var vsync = bool(g.get("vsync", true))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
		var fps = int(g.get("fps_limit", 60))
		Engine.max_fps = fps if fps > 0 else 0


func apply_audio_settings() -> void:
	var a = settings.get("audio", {})
	var am = get_node_or_null("/root/AudioManager")
	if not am: return
	
	var m_muted = bool(a.get("master_muted", false))
	var m_vol = 0.0 if m_muted else (float(a.get("master_volume", 100)) / 100.0)
	am.set_master_volume(m_vol)
	
	var s_muted = bool(a.get("sfx_muted", false))
	var s_vol = 0.0 if s_muted else (float(a.get("sfx_volume", 100)) / 100.0)
	am.set_sfx_volume(s_vol)
	
	var mu_muted = bool(a.get("music_muted", false))
	var mu_vol = 0.0 if mu_muted else (float(a.get("music_volume", 70)) / 100.0)
	am.set_music_volume(mu_vol)

func apply_controls_settings() -> void:
	var c = settings.get("controls", {})
	for action_name in c.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		else:
			InputMap.action_erase_events(action_name)
			
		var keys_arr = c[action_name]
		for k_str in keys_arr:
			var event = _create_key_event(str(k_str))
			if event: InputMap.action_add_event(action_name, event)

func _create_key_event(k_str: String) -> InputEventKey:
	var keycode = OS.find_keycode_from_string(k_str)
	if keycode != KEY_NONE:
		var ev = InputEventKey.new()
		ev.physical_keycode = keycode
		ev.keycode = keycode
		return ev
	return null
