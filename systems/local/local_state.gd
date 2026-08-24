class_name LocalState
extends RefCounted

## Decoupled Local Client State model representing device-specific preferences.
## Strictly isolated from PlayerState and SharedWorldState; never serialized in savegame, never replicated over network.

var graphics: Dictionary = {
	"resolution": "1152x648",
	"window_mode": "windowed",
	"vsync": true,
	"fps_limit": 60,
	"ui_scale": 1.0,
	"camera_zoom": 1.0,
	"screen_shake": true,
	"particle_quality": "full",
	"floating_text": true,
	"reduced_motion": false
}

var audio: Dictionary = {
	"master_volume": 100,
	"music_volume": 70,
	"sfx_volume": 100,
	"master_muted": false,
	"music_muted": false,
	"sfx_muted": false
}

var controls: Dictionary = {
	"move_up": ["W", "Up"],
	"move_down": ["S", "Down"],
	"move_left": ["A", "Left"],
	"move_right": ["D", "Right"],
	"use_tool": ["MouseLeft", "C"],
	"interact": ["MouseRight", "E", "Space"],
	"inventory": ["E", "I", "Tab"],
	"journal": ["F", "J"],
	"combination": ["C"],
	"quest": ["F", "Q"],
	"run": ["Shift"],
	"hotbar_next": ["MouseWheelDown"],
	"hotbar_prev": ["MouseWheelUp"],
	"pause": ["Escape"],
	"quick_save": ["F5"],
	"quick_load": ["F9"]
}

var accessibility: Dictionary = {
	"ui_scale": 1.0,
	"text_size": "normal",
	"high_contrast": false,
	"reduced_motion": false,
	"screen_shake": true,
	"particle_reduction": false,
	"floating_text": true,
	"show_tile_highlight": true,
	"show_tool_preview": true
}


var language: Dictionary = {
	"current_language": "en"
}

var camera: Dictionary = {
	"zoom": 1.0,
	"smoothing": true,
	"shake_enabled": true
}

var ui: Dictionary = {
	"open_modals": [],
	"active_tab": "graphics"
}

static func create_default() -> LocalState:
	var script = load("res://systems/local/local_state.gd") as GDScript
	return script.new() as LocalState

func get_value(section: String, key: String, default_val: Variant = null) -> Variant:
	match section:
		"graphics": return graphics.get(key, default_val)
		"audio": return audio.get(key, default_val)
		"controls": return controls.get(key, default_val)
		"accessibility": return accessibility.get(key, default_val)
		"language": return language.get(key, default_val)
		"camera": return camera.get(key, default_val)
		"ui": return ui.get(key, default_val)
		"gameplay": return graphics.get(key, default_val)
	return default_val

func set_value(section: String, key: String, value: Variant) -> void:
	match section:
		"graphics": graphics[key] = value
		"audio": audio[key] = value
		"controls": controls[key] = value
		"accessibility": accessibility[key] = value
		"language": language[key] = value
		"camera": camera[key] = value
		"ui": ui[key] = value
		"gameplay": graphics[key] = value

func to_dict() -> Dictionary:
	return {
		"graphics": graphics.duplicate(true),
		"audio": audio.duplicate(true),
		"controls": controls.duplicate(true),
		"accessibility": accessibility.duplicate(true),
		"language": language.duplicate(true),
		"camera": camera.duplicate(true),
		"ui": ui.duplicate(true)
	}

static func from_dict(data: Dictionary) -> LocalState:
	var script = load("res://systems/local/local_state.gd") as GDScript
	var state = script.new() as LocalState
	if typeof(data) != TYPE_DICTIONARY:
		return state
		
	var g = data.get("graphics", data.get("gameplay", {}))
	if typeof(g) == TYPE_DICTIONARY:
		for k in g.keys(): state.graphics[k] = g[k]
		
	var a = data.get("audio", {})
	if typeof(a) == TYPE_DICTIONARY:
		for k in a.keys(): state.audio[k] = a[k]
		
	var c = data.get("controls", {})
	if typeof(c) == TYPE_DICTIONARY:
		for k in c.keys(): state.controls[k] = c[k]
		
	var acc = data.get("accessibility", {})
	if typeof(acc) == TYPE_DICTIONARY:
		for k in acc.keys(): state.accessibility[k] = acc[k]
		
	var lang = data.get("language", {})
	if typeof(lang) == TYPE_DICTIONARY:
		for k in lang.keys(): state.language[k] = lang[k]
		
	var cam = data.get("camera", {})
	if typeof(cam) == TYPE_DICTIONARY:
		for k in cam.keys(): state.camera[k] = cam[k]
		
	return state
