class_name ProgressionDataService
extends RefCounted

const UNLOCKS_PATH = "res://data/progression/world_unlocks.json"
static var _unlocks: Dictionary = {}
static var _loaded = false

static func ensure_loaded() -> void:
	if _loaded: return
	if FileAccess.file_exists(UNLOCKS_PATH):
		var json = JSON.new()
		var text = FileAccess.get_file_as_string(UNLOCKS_PATH)
		if json.parse(text) == OK:
			var res = json.get_data()
			if typeof(res) == TYPE_DICTIONARY and res.has("worlds"):
				_unlocks = res.get("worlds", {})
	_loaded = true

static func get_all_unlocks() -> Dictionary:
	ensure_loaded()
	return _unlocks

static func save_unlocks() -> void:
	var f = FileAccess.open(UNLOCKS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"worlds": _unlocks}, "\t"))
	var pm = Engine.get_main_loop().root.get_node_or_null("ProgressionManager")
	if pm and pm.has_method("_load_data"):
		pm._load_data()

static func update_unlock(id: String, data: Dictionary) -> void:
	_unlocks[id] = data

static func remove_unlock(id: String) -> void:
	_unlocks.erase(id)
