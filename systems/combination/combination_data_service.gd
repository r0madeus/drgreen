class_name CombinationDataService
extends RefCounted

const COMBOS_PATH = "res://data/combinations/base_combos.json"
static var _combos: Array = []
static var _loaded = false

static func ensure_loaded() -> void:
	if _loaded: return
	if FileAccess.file_exists(COMBOS_PATH):
		var json = JSON.new()
		var text = FileAccess.get_file_as_string(COMBOS_PATH)
		if json.parse(text) == OK:
			var res = json.get_data()
			if typeof(res) == TYPE_DICTIONARY and res.has("combinations"):
				_combos = res.get("combinations", [])
	_loaded = true

static func get_all_combos() -> Array:
	ensure_loaded()
	return _combos

static func save_combos() -> void:
	var f = FileAccess.open(COMBOS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"combinations": _combos}, "\t"))
	var cm = Engine.get_main_loop().root.get_node_or_null("CombinationManager")
	if cm and cm.has_method("_load_data"):
		cm._load_data()

static func update_combo(idx: int, data: Dictionary) -> void:
	if idx >= 0 and idx < _combos.size():
		_combos[idx] = data
	else:
		_combos.append(data)

static func remove_combo(idx: int) -> void:
	if idx >= 0 and idx < _combos.size():
		_combos.remove_at(idx)
