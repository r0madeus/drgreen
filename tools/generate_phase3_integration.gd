@tool
extends SceneTree

func _init() -> void:
	integrate_phase3()
	quit()

static func integrate_phase3() -> void:
	# 1. world_serializer.gd (Atomic Safe Save + v3 migration)
	var serializer_code = """class_name WorldSerializer
extends RefCounted

## Handles atomic safe-saving, loading, validation and version migration (v1/v2 -> v3).

const CURRENT_VERSION = 3

static func load_world(filepath: String) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		push_warning("[WorldSerializer] File not found: " + filepath)
		return create_empty_world()
		
	var f = FileAccess.open(filepath, FileAccess.READ)
	if not f:
		push_error("[WorldSerializer] Failed to open: " + filepath)
		return create_empty_world()
		
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("[WorldSerializer] Parse error in: " + filepath)
		return create_empty_world()
		
	return migrate_world_data(json.data)

static func save_world(filepath: String, data: Dictionary) -> bool:
	var temp_path = filepath + ".tmp"
	var f = FileAccess.open(temp_path, FileAccess.WRITE)
	if not f:
		push_error("[WorldSerializer] Failed to open temporary file for atomic write: " + temp_path)
		return false
		
	data["version"] = CURRENT_VERSION
	var text = JSON.stringify(data, "  ")
	f.store_string(text)
	f.close()
	
	# Verify temp file before replacing
	var f_verify = FileAccess.open(temp_path, FileAccess.READ)
	if not f_verify: return false
	var v_text = f_verify.get_as_text()
	f_verify.close()
	var json = JSON.new()
	if json.parse(v_text) != OK:
		push_error("[WorldSerializer] Atomic save verification failed!")
		return false
		
	# Move temp file to actual file
	var dir = DirAccess.open("res://data/worlds/")
	if dir:
		if FileAccess.file_exists(filepath):
			dir.remove(filepath.get_file())
		dir.rename(temp_path.get_file(), filepath.get_file())
		
	print("[WorldSerializer] World successfully atomic saved (v%d) to: %s" % [CURRENT_VERSION, filepath])
	return true

static func create_empty_world(width: int = 32, height: int = 24, world_id: String = "new_world", display_name: String = "New World") -> Dictionary:
	var tiles = []
	for y in range(height):
		for x in range(width):
			tiles.append({
				"x": x,
				"y": y,
				"type": "grass",
				"layer": "GROUND",
				"walkable": true,
				"solid": false,
				"interactable": false
			})
	return {
		"version": CURRENT_VERSION,
		"world_id": world_id,
		"display_name": display_name,
		"width": width,
		"height": height,
		"tile_size": 16,
		"spawn": [int(width * 0.5), int(height * 0.5)],
		"default_layer": "GROUND",
		"layers": _get_default_layers(),
		"tiles": tiles,
		"objects": [],
		"transitions": [],
		"prefabs": []
	}

static func _get_default_layers() -> Array:
	return [
		{ "name": "GROUND", "visible": true, "locked": false },
		{ "name": "TERRAIN", "visible": true, "locked": false },
		{ "name": "DECORATION", "visible": true, "locked": false },
		{ "name": "OBJECT", "visible": true, "locked": false },
		{ "name": "NPC", "visible": true, "locked": false },
		{ "name": "OVERLAY", "visible": true, "locked": false }
	]

static func migrate_world_data(data: Dictionary) -> Dictionary:
	var result = data.duplicate(true)
	var v = int(result.get("version", 1))
	if v < 3:
		result["version"] = 3
		if not result.has("world_id"): result["world_id"] = "world_%d" % Time.get_unix_time_from_system()
		if not result.has("display_name"): result["display_name"] = str(result.get("name", "World"))
		if not result.has("spawn"): result["spawn"] = [16, 12]
		if not result.has("transitions"): result["transitions"] = []
		if not result.has("layers"): result["layers"] = _get_default_layers()
	if not result.has("width"): result["width"] = 32
	if not result.has("height"): result["height"] = 24
	if not result.has("tile_size"): result["tile_size"] = 16
	if not result.has("tiles"): result["tiles"] = []
	if not result.has("objects"): result["objects"] = []
	return result

static func load_prefab(filepath: String) -> Dictionary:
	if not FileAccess.file_exists(filepath): return {}
	var f = FileAccess.open(filepath, FileAccess.READ)
	if not f: return {}
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

static func save_prefab(filepath: String, prefab_data: Dictionary) -> bool:
	var f = FileAccess.open(filepath, FileAccess.WRITE)
	if not f: return false
	f.store_string(JSON.stringify(prefab_data, "  "))
	f.close()
	return true
"""
	var f1 = FileAccess.open("res://editor/world_builder/world_serializer.gd", FileAccess.WRITE)
	if f1: f1.store_string(serializer_code); f1.close()

	print("[Phase3IntegrationGen] Generated WorldSerializer with atomic save & v3 migration!")
