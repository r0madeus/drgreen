class_name AudioDataService
extends RefCounted

## Phase 3D — Audio Configuration Service
## Handles persistence of audio assignments, resolving logical audio IDs (e.g., 'dialogue.open')
## to their customized file paths, and injecting them into the runtime AudioManager.

const CONFIG_PATH: String = "res://data/audio/audio_map.json"

static var _audio_map: Dictionary = {}

static func load_catalog() -> void:
	_audio_map.clear()
	var f = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f:
		var content = f.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK and typeof(json.data) == TYPE_DICTIONARY:
			var dict = json.data
			for k in dict:
				if dict[k] is String:
					_audio_map[k] = dict[k]
				elif dict[k] is Dictionary:
					# If we store extended metadata in the future
					_audio_map[k] = dict[k]

static func save_catalog() -> bool:
	DirAccess.make_dir_recursive_absolute("res://data/audio/")
	var f = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if not f: return false
	f.store_string(JSON.stringify(_audio_map, "\t"))
	return true

static func get_all_overrides() -> Dictionary:
	return _audio_map.duplicate(true)

static func get_override(sound_id: String) -> Variant:
	return _audio_map.get(sound_id, null)

static func set_override(sound_id: String, path_or_data: Variant) -> void:
	if typeof(path_or_data) == TYPE_NIL or (typeof(path_or_data) == TYPE_STRING and path_or_data == ""):
		_audio_map.erase(sound_id)
	else:
		_audio_map[sound_id] = path_or_data

static func remove_override(sound_id: String) -> void:
	_audio_map.erase(sound_id)

static func apply_to_runtime() -> void:
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var am = root.get_node_or_null("/root/AudioManager") if root else null
	if not am: return
	
	if am.has_method("clear_sound_overrides"):
		am.clear_sound_overrides()
	
	if am.has_method("register_sound_override"):
		for sound_id in _audio_map:
			var entry = _audio_map[sound_id]
			var path = entry if entry is String else entry.get("path", "")
			if path != "" and ResourceLoader.exists(path):
				var stream = ResourceLoader.load(path) as AudioStream
				if stream:
					am.register_sound_override(sound_id, stream)
