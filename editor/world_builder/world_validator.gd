class_name WorldValidator
extends RefCounted

## Performs 10-point static analysis and BFS walkability validation on World Data.
const CURRENT_VERSION = 3

static func _get_obj_props(o: Dictionary) -> Dictionary:
	var overrides = o.get("properties", {})
	if ClassDB.class_exists("AssetDefinitionManager"):
		return AssetDefinitionManager.resolve_instance_properties(o.get("asset_id", ""), overrides)
	return overrides

enum Severity { ERROR, WARNING, INFO }

static func validate_world(world_data: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	var tiles = world_data.get("tiles", [])
	var objects = world_data.get("objects", [])
	var transitions = world_data.get("transitions", []).duplicate(true)
	for o in objects:
		var p = _get_obj_props(o)
		if p.get("interaction_type") == "world_transition":
			transitions.append({
				"name": p.get("interaction_id", "transition"),
				"target_world": p.get("target_world", ""),
				"target_spawn": p.get("interaction_id", "default"),
				"position": o.get("position", [-1, -1])
			})
	var spawn = world_data.get("spawn", [16, 12])
	var spawn_pos = Vector2i(spawn[0], spawn[1])

	# 1. PLAYER SPAWN VALIDATION
	if spawn_pos.x < 0 or spawn_pos.x >= w or spawn_pos.y < 0 or spawn_pos.y >= h:
		results.append({ "severity": Severity.ERROR, "code": "SPAWN_OUT_OF_BOUNDS", "message": "Player spawn (%d, %d) is outside map bounds!" % [spawn_pos.x, spawn_pos.y], "pos": spawn_pos })
	else:
		var spawn_tile = _get_tile(tiles, spawn_pos)
		if spawn_tile.get("solid", false) or not spawn_tile.get("walkable", true):
			results.append({ "severity": Severity.ERROR, "code": "SPAWN_BLOCKED", "message": "Player spawn (%d, %d) is on non-walkable tile!" % [spawn_pos.x, spawn_pos.y], "pos": spawn_pos })

	# 2. OBJECT OVERLAPS
	var solid_positions: Dictionary = {}
	for o in objects:
		var p = o.get("position", [-1, -1])
		var pos = Vector2i(p[0], p[1])
		var is_solid = _get_obj_props(o).get("solid", true)
		if is_solid:
			if solid_positions.has(pos):
				results.append({ "severity": Severity.ERROR, "code": "SOLID_OVERLAP", "message": "Solid object '%s' overlaps '%s' at (%d, %d)!" % [o.get("instance_id"), solid_positions[pos], pos.x, pos.y], "pos": pos })
			else:
				solid_positions[pos] = o.get("instance_id")

	# 3. NPC WALKABILITY & INTERACTABILITY
	for o in objects:
		if o.get("layer") == "NPC":
			var p = o.get("position", [-1, -1])
			var pos = Vector2i(p[0], p[1])
			# Check adjacent walkable tile for player to talk
			var has_access = _has_adjacent_walkable(tiles, objects, pos, w, h)
			if not has_access:
				results.append({ "severity": Severity.WARNING, "code": "NPC_UNREACHABLE", "message": "NPC '%s' has no adjacent walkable tiles for interaction!" % o.get("name", o.get("instance_id")), "pos": pos })

	# 4. TRANSITION INTEGRITY
	for tr in transitions:
		var p = tr.get("position", [-1, -1])
		var pos = Vector2i(p[0], p[1])
		var target_w = tr.get("target_world", "")
		if target_w == "" or not FileAccess.file_exists("res://data/worlds/%s.json" % target_w):
			results.append({ "severity": Severity.ERROR, "code": "INVALID_TRANSITION_TARGET", "message": "Transition '%s' targets non-existent world '%s'!" % [tr.get("name", "Transition"), target_w], "pos": pos })
		var has_walkable = _has_adjacent_walkable(tiles, objects, pos, w, h) or _is_tile_passable(tiles, objects, pos)
		if not has_walkable:
			results.append({ "severity": Severity.WARNING, "code": "TRANSITION_BLOCKED", "message": "Transition '%s' at (%d, %d) is blocked!" % [tr.get("name"), pos.x, pos.y], "pos": pos })

	# 5. ASSET EXISTENCE CHECK
	for o in objects:
		var aid = o.get("asset_id", "")
		if not _check_asset_exists(aid):
			results.append({ "severity": Severity.ERROR, "code": "MISSING_ASSET", "message": "Object '%s' references missing asset '%s'!" % [o.get("instance_id"), aid], "pos": Vector2i(o.get("position", [0, 0])[0], o.get("position", [0, 0])[1]) })

	# 6. MAP BOUNDS CHECK
	for o in objects:
		var p = o.get("position", [-1, -1])
		if p[0] < 0 or p[0] >= w or p[1] < 0 or p[1] >= h:
			results.append({ "severity": Severity.ERROR, "code": "OBJECT_OUT_OF_BOUNDS", "message": "Object '%s' at (%d, %d) is outside map!" % [o.get("instance_id"), p[0], p[1]], "pos": Vector2i(p[0], p[1]) })

	# 7. BFS WALKABILITY / REACHABILITY FROM SPAWN
	if results.size() == 0 or _has_no_spawn_errors(results):
		var reachable = _compute_reachable_bfs(tiles, objects, spawn_pos, w, h)
		for tr in transitions:
			var p = tr.get("position", [-1, -1])
			var pos = Vector2i(p[0], p[1])
			if not reachable.has(pos) and not _is_any_adjacent_reachable(reachable, pos):
				results.append({ "severity": Severity.WARNING, "code": "TRANSITION_UNREACHABLE", "message": "Cannot reach transition '%s' from Player Spawn!" % tr.get("name"), "pos": pos })

	# 8. INFO SUMMARY
	results.append({
		"severity": Severity.INFO,
		"code": "MAP_STATS",
		"message": "Map: %dx%d | Tiles: %d | Objects: %d | Transitions: %d" % [w, h, tiles.size(), objects.size(), transitions.size()],
		"pos": spawn_pos
	})

	return results

static func _has_no_spawn_errors(results: Array[Dictionary]) -> bool:
	for r in results:
		if r.get("code") == "SPAWN_BLOCKED" or r.get("code") == "SPAWN_OUT_OF_BOUNDS":
			return false
	return true

static func _compute_reachable_bfs(tiles: Array, objects: Array, start: Vector2i, w: int, h: int) -> Dictionary:
	var reachable: Dictionary = {}
	var queue: Array[Vector2i] = [start]
	reachable[start] = true

	while queue.size() > 0:
		var cur = queue.pop_front()
		var neighbors = [cur + Vector2i.UP, cur + Vector2i.DOWN, cur + Vector2i.LEFT, cur + Vector2i.RIGHT]
		for n in neighbors:
			if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h and not reachable.has(n):
				if _is_tile_passable(tiles, objects, n):
					reachable[n] = true
					queue.append(n)
	return reachable

static func _is_tile_passable(tiles: Array, objects: Array, pos: Vector2i) -> bool:
	var t = _get_tile(tiles, pos)
	if t.get("solid", false) or not t.get("walkable", true):
		return false
	for o in objects:
		var p = o.get("position", [-1, -1])
		if p[0] == pos.x and p[1] == pos.y:
			if _get_obj_props(o).get("solid", true):
				return false
	return true

static func _has_adjacent_walkable(tiles: Array, objects: Array, pos: Vector2i, w: int, h: int) -> bool:
	var neighbors = [pos + Vector2i.UP, pos + Vector2i.DOWN, pos + Vector2i.LEFT, pos + Vector2i.RIGHT]
	for n in neighbors:
		if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h:
			if _is_tile_passable(tiles, objects, n):
				return true
	return false

static func _is_any_adjacent_reachable(reachable: Dictionary, pos: Vector2i) -> bool:
	var neighbors = [pos + Vector2i.UP, pos + Vector2i.DOWN, pos + Vector2i.LEFT, pos + Vector2i.RIGHT]
	for n in neighbors:
		if reachable.has(n):
			return true
	return false

static func _get_tile(tiles: Array, pos: Vector2i) -> Dictionary:
	for t in tiles:
		if t["x"] == pos.x and t["y"] == pos.y:
			return t
	return {}

static func _check_asset_exists(aid: String) -> bool:
	return AssetRegistry.has_asset(aid)


## Validates the holistic World Connection Graph across all connected world maps.
static func validate_world_graph(world_ids: Array = ["farm", "town", "forest", "botanical_grove"]) -> Dictionary:
	var loaded_worlds: Dictionary = {}
	var errors: Array[String] = []
	var checks: Dictionary = {}
	
	# T01 - T04: Check all world files exist
	for wid in world_ids:
		var path = "res://data/worlds/%s.json" % wid
		var exists = FileAccess.file_exists(path)
		checks["world_exists_" + wid] = exists
		if not exists:
			errors.append("World file missing: %s" % path)
		else:
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var json = JSON.new()
				if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
					loaded_worlds[wid] = json.data
				f.close()

	# Helper to find transition
	var find_transition = func(from_w: String, to_w: String) -> Dictionary:
		if not loaded_worlds.has(from_w): return {}
		for tr in loaded_worlds[from_w].get("transitions", []):
			if tr.get("target_world", "") == to_w: return tr
		return {}

	# Helper to check spawn exists
	var check_spawn_exists = func(target_w: String, spawn_id: String) -> bool:
		if not loaded_worlds.has(target_w): return false
		var tw_data: Dictionary = loaded_worlds[target_w]
		var sp_map: Dictionary = tw_data.get("spawn_points", {})
		if sp_map.has(spawn_id): return true
		if spawn_id == "default" and tw_data.has("spawn"): return true
		for k in sp_map.keys():
			if k.ends_with(spawn_id) or spawn_id.ends_with(k): return true
		return false

	# T05 - T10: Directed World Connection Pair Checks
	var pairs = [
		["farm", "town", "T05_farm_to_town"],
		["town", "farm", "T06_town_to_farm"],
		["town", "forest", "T07_town_to_forest"],
		["forest", "town", "T08_forest_to_town"],
		["farm", "botanical_grove", "T09_farm_to_grove"],
		["botanical_grove", "farm", "T10_grove_to_farm"],
		["forest", "botanical_grove", "T10b_forest_to_grove"],
		["botanical_grove", "forest", "T10c_grove_to_forest"]
	]

	
	for pair in pairs:
		var from_w = pair[0]
		var to_w = pair[1]
		var key = pair[2]
		var tr = find_transition.call(from_w, to_w)
		var valid = not tr.is_empty()
		if valid:
			var tgt_sp = str(tr.get("target_spawn", "default"))
			var sp_ok = check_spawn_exists.call(to_w, tgt_sp)
			checks[key] = sp_ok
			if not sp_ok:
				errors.append("Transition from %s to %s specifies missing spawn: %s" % [from_w, to_w, tgt_sp])
		else:
			checks[key] = false
			errors.append("Missing transition from %s to %s" % [from_w, to_w])

	# T11 - T15: Holistic Integrity Checks
	var all_spawns_exist = true
	var no_duplicate_ids = true
	var no_dangling_worlds = true
	var no_invalid_coords = true
	var no_broken_prog = true

	var global_ids: Dictionary = {}

	for wid in loaded_worlds.keys():
		var w_data: Dictionary = loaded_worlds[wid]
		var w_w = int(w_data.get("width", 32))
		var w_h = int(w_data.get("height", 24))
		
		# Check spawn coords
		for sp_k in w_data.get("spawn_points", {}).keys():
			var p = w_data["spawn_points"][sp_k]
			if p[0] < 0 or p[0] >= w_w or p[1] < 0 or p[1] >= w_h:
				no_invalid_coords = false
				errors.append("Spawn %s in %s has out of bounds coords [%d, %d]" % [sp_k, wid, p[0], p[1]])
				
		var all_trs = w_data.get("transitions", []).duplicate(true)
		for o in w_data.get("objects", []):
			var p = _get_obj_props(o)
			if p.get("interaction_type") == "world_transition":
				all_trs.append({
					"instance_id": p.get("interaction_id", "transition"),
					"transition_id": p.get("interaction_id", "transition"),
					"target_world": p.get("target_world", ""),
					"target_spawn": p.get("interaction_id", "default")
				})
		
		for tr in all_trs:
			var tr_id = str(tr.get("instance_id", tr.get("transition_id", "")))
			if tr_id != "":
				if global_ids.has(wid + ":" + tr_id):
					no_duplicate_ids = false
					errors.append("Duplicate transition ID in %s: %s" % [wid, tr_id])
				global_ids[wid + ":" + tr_id] = true
				
			var tw = str(tr.get("target_world", ""))
			if not loaded_worlds.has(tw) and not FileAccess.file_exists("res://data/worlds/%s.json" % tw):
				no_dangling_worlds = false
				errors.append("Transition %s references dangling world: %s" % [tr_id, tw])
				
			var tsp = str(tr.get("target_spawn", "default"))
			if not check_spawn_exists.call(tw, tsp):
				all_spawns_exist = false
				
			var req_p = str(tr.get("required_progression", ""))
			if req_p != "" and req_p not in ["town", "forest", "botanical_grove", "farm", "quest_01", "quest_02"]:
				no_broken_prog = false

	checks["T11_all_target_spawns_exist"] = all_spawns_exist
	checks["T12_no_duplicate_transition_ids"] = no_duplicate_ids
	checks["T13_no_dangling_world_refs"] = no_dangling_worlds
	checks["T14_no_invalid_spawn_coords"] = no_invalid_coords
	checks["T15_no_broken_progression_refs"] = no_broken_prog
	checks["is_valid"] = (errors.size() == 0)
	checks["errors"] = errors
	
	return checks

