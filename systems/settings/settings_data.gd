class_name SettingsData
extends RefCounted

## Data structure and default values for all game settings.

const SETTINGS_FILE_PATH: String = "user://settings.json"

static func get_default_settings() -> Dictionary:
	return {
		"graphics": {
			"resolution": "1920x1080",
			"window_mode": "windowed",
			"vsync": true,
			"fps_limit": 60,
			"ui_scale": 1.5,
			"camera_zoom": 1.0,
			"integer_scaling": false
		},
		"audio": {
			"master_volume": 100,
			"music_volume": 70,
			"sfx_volume": 100,
			"master_muted": false,
			"music_muted": false,
			"sfx_muted": false
		},
		"gameplay": {
			"screen_shake": true,
			"particle_effects": "full",
			"floating_text": true,
			"auto_save": true,
			"tooltips": true
		},
		"accessibility": {
			"ui_scale": 1.0,
			"text_size": "normal",
			"high_contrast": false,
			"reduced_motion": false
		},
		"controls": {
			"move_up": ["W", "Up"],
			"move_down": ["S", "Down"],
			"move_left": ["A", "Left"],
			"move_right": ["D", "Right"],
			"use_tool": ["MouseLeft"],
			"interact": ["E", "MouseRight"],
			"inventory": ["I", "Tab", "B"],
			"journal": ["J"],
			"combination": ["C"],
			"quest": ["Q"],
			"pause": ["Escape"],
			"quick_save": ["F5"],
			"quick_load": ["F9"]
		},
		"language": {
			"current_language": "en"
		},
		"developer": {
			"developer_mode": false
		}
	}

static func load_from_disk() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		return get_default_settings()
		
	var f = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not f:
		return get_default_settings()
		
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	var err = json.parse(text)
	if err != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("[SettingsData] Corrupted settings.json detected, recovering with default values.")
		return get_default_settings()
		
	# Merge with defaults to ensure all keys exist
	var merged = get_default_settings()
	var loaded = json.data as Dictionary
	for cat in loaded.keys():
		if merged.has(cat) and typeof(loaded[cat]) == TYPE_DICTIONARY:
			for key in loaded[cat].keys():
				merged[cat][key] = loaded[cat][key]
		else:
			merged[cat] = loaded[cat]
			
	return merged

static func save_to_disk(settings: Dictionary) -> bool:
	var f = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if not f:
		push_error("[SettingsData] Failed to write settings to disk: " + SETTINGS_FILE_PATH)
		return false
	f.store_string(JSON.stringify(settings, "\t"))
	f.close()
	return true
