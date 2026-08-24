class_name WorldSerializer
extends RefCounted

## Handles atomic safe-saving, loading, validation and version migration (v1/v2 -> v3) with integer coordinate normalization.

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
		
	var migrated = migrate_world_data(json.data)
	return normalize_world_data(migrated)

static func save_world(filepath: String, data: Dictionary) -> bool:
	var norm_data = normalize_world_data(data)
	norm_data["version"] = CURRENT_VERSION
	
	var temp_path = filepath + ".tmp"
	var f = FileAccess.open(temp_path, FileAccess.WRITE)
	if not f:
		push_error("[WorldSerializer] Failed to open temporary file for atomic write: " + temp_path)
		return false
		
	var text = JSON.stringify(norm_data, "  ")
	f.store_string(text)
	f.flush()
	f.close()
	
	# Verify temp file before replacing
	var f_verify = FileAccess.open(temp_path, FileAccess.READ)
	if not f_verify:
		push_error("[WorldSerializer] Failed to read temporary file for verification: " + temp_path)
		if FileAccess.file_exists(temp_path): DirAccess.remove_absolute(temp_path)
		return false
		
	var v_text = f_verify.get_as_text()
	f_verify.close()
	var json = JSON.new()
	if json.parse(v_text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("[WorldSerializer] Atomic save JSON verification failed for: " + temp_path)
		if FileAccess.file_exists(temp_path): DirAccess.remove_absolute(temp_path)
		return false
		
	# Safely replace target file
	if FileAccess.file_exists(filepath):
		DirAccess.remove_absolute(filepath)
		
	var err = DirAccess.rename_absolute(temp_path, filepath)
	if err != OK:
		push_error("[WorldSerializer] Atomic replace rename failed with error code: %d" % err)
		if FileAccess.file_exists(temp_path): DirAccess.remove_absolute(temp_path)
		return false
		
	# Final verification that the target file exists and is readable
	if not FileAccess.file_exists(filepath):
		push_error("[WorldSerializer] Target file missing after save: " + filepath)
		return false
		
	print("[WorldSerializer] World successfully atomic saved (v%d) to: %s" % [CURRENT_VERSION, filepath])
	return true

static func normalize_world_data(data: Dictionary) -> Dictionary:
	var result = data.duplicate(true)
	
	result["width"] = int(result.get("width", 32))
	result["height"] = int(result.get("height", 24))
	result["tile_size"] = int(result.get("tile_size", 16))
	
	# Normalize spawn coordinates
	var sp = result.get("spawn", [16, 12])
	if sp is Array and sp.size() >= 2:
		result["spawn"] = [int(sp[0]), int(sp[1])]
	else:
		result["spawn"] = [16, 12]
		
	# Normalize tiles
	var raw_tiles = result.get("tiles", [])
	var norm_tiles: Array = []
	for t in raw_tiles:
		if t is Dictionary:
			var nt = t.duplicate(true)
			nt["x"] = int(nt.get("x", 0))
			nt["y"] = int(nt.get("y", 0))
			nt["type"] = str(nt.get("type", "grass"))
			nt["layer"] = str(nt.get("layer", "GROUND"))
			nt["walkable"] = bool(nt.get("walkable", true))
			nt["solid"] = bool(nt.get("solid", false))
			nt["interactable"] = bool(nt.get("interactable", false))
			if nt.has("variant"): nt["variant"] = str(nt["variant"])
			if nt.has("connection_mask"): nt["connection_mask"] = int(nt["connection_mask"])
			norm_tiles.append(nt)
	result["tiles"] = norm_tiles
	
	# Normalize objects
	var raw_objects = result.get("objects", [])
	var norm_objects: Array = []
	for o in raw_objects:
		if o is Dictionary:
			var no = o.duplicate(true)
			var pos = no.get("position", [0, 0])
			if pos is Array and pos.size() >= 2:
				no["position"] = [int(pos[0]), int(pos[1])]
			else:
				no["position"] = [0, 0]
			no["asset_id"] = str(no.get("asset_id", ""))
			no["instance_id"] = str(no.get("instance_id", ""))
			no["layer"] = str(no.get("layer", "OBJECT"))
			
			if not no.has("properties") or typeof(no["properties"]) != TYPE_DICTIONARY:
				no["properties"] = {}
			var props = no["properties"]
			props["walkable"] = bool(props.get("walkable", false))
			props["solid"] = bool(props.get("solid", true))
			props["interactable"] = bool(props.get("interactable", false))
			norm_objects.append(no)
	result["objects"] = norm_objects
	
	# Normalize transitions
	var raw_transitions = result.get("transitions", [])
	var norm_transitions: Array = []
	for tr in raw_transitions:
		if tr is Dictionary:
			var ntr = tr.duplicate(true)
			var pos = ntr.get("position", [0, 0])
			if pos is Array and pos.size() >= 2:
				ntr["position"] = [int(pos[0]), int(pos[1])]
			else:
				ntr["position"] = [0, 0]
			ntr["target_world"] = str(ntr.get("target_world", ""))
			ntr["target_spawn"] = str(ntr.get("target_spawn", "default"))
			norm_transitions.append(ntr)
	result["transitions"] = norm_transitions
	
	return result

static func create_empty_world(width: int = 32, height: int = 24, world_id: String = "new_world", display_name: String = "New World") -> Dictionary:
	var tiles = []
	for y in range(height):
		for x in range(width):
			tiles.append({
				"x": int(x),
				"y": int(y),
				"type": "grass",
				"layer": "GROUND",
				"walkable": true,
				"solid": false,
				"interactable": false,
				"variant": "single",
				"connection_mask": 0
			})
	return {
		"version": CURRENT_VERSION,
		"world_id": world_id,
		"display_name": display_name,
		"width": int(width),
		"height": int(height),
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

