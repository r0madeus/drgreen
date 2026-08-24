@tool
extends SceneTree

func _init() -> void:
	generate_core()
	quit()

static func generate_core() -> void:
	# 1. smart_tiler.gd
	var tiler_code = """class_name SmartTiler
extends RefCounted

## Handles 4-way orthogonal bitmask calculation and neighbor updates for Paths and Fences.

const SMART_TILE_TYPES = ["path", "fence", "water"]

static func is_smart_type(tile_type: String) -> bool:
	return tile_type in SMART_TILE_TYPES

static func calculate_variant(world_data: Dictionary, pos: Vector2i, tile_type: String) -> String:
	var n = _has_same_type(world_data, pos + Vector2i.UP, tile_type)
	var s = _has_same_type(world_data, pos + Vector2i.DOWN, tile_type)
	var e = _has_same_type(world_data, pos + Vector2i.RIGHT, tile_type)
	var w = _has_same_type(world_data, pos + Vector2i.LEFT, tile_type)
	
	var count = int(n) + int(s) + int(e) + int(w)
	
	if count == 0:
		return "single"
	elif count == 1:
		if n: return "end_s" # opens upward
		elif s: return "end_n"
		elif e: return "end_w"
		else: return "end_e"
	elif count == 2:
		if n and s: return "vertical"
		elif e and w: return "horizontal"
		elif n and e: return "corner_ne"
		elif n and w: return "corner_nw"
		elif s and e: return "corner_se"
		elif s and w: return "corner_sw"
	elif count == 3:
		if not n: return "t_south"
		elif not s: return "t_north"
		elif not e: return "t_west"
		elif not w: return "t_east"
	elif count == 4:
		return "cross"
		
	return "center"

static func update_tile_and_neighbors(world_data: Dictionary, pos: Vector2i) -> Array[Vector2i]:
	var updated_coords: Array[Vector2i] = []
	var targets = [pos, pos + Vector2i.UP, pos + Vector2i.DOWN, pos + Vector2i.LEFT, pos + Vector2i.RIGHT]
	
	for p in targets:
		var tile = _get_tile(world_data, p)
		if not tile.is_empty():
			var t_type = tile.get("type", "")
			if is_smart_type(t_type):
				tile["variant"] = calculate_variant(world_data, p, t_type)
				updated_coords.append(p)
				
	return updated_coords

static func _has_same_type(world_data: Dictionary, pos: Vector2i, tile_type: String) -> bool:
	var tile = _get_tile(world_data, pos)
	return tile.get("type", "") == tile_type

static func _get_tile(world_data: Dictionary, pos: Vector2i) -> Dictionary:
	for t in world_data.get("tiles", []):
		if t["x"] == pos.x and t["y"] == pos.y:
			return t
	return {}
"""
	var f1 = FileAccess.open("res://editor/world_builder/smart_tiler.gd", FileAccess.WRITE)
	if f1: f1.store_string(tiler_code); f1.close()

	# 2. world_validator.gd
	var validator_code = """class_name WorldValidator
extends RefCounted

## Performs 10-point static analysis and BFS walkability validation on World Data.

enum Severity { ERROR, WARNING, INFO }

static func validate_world(world_data: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	var tiles = world_data.get("tiles", [])
	var objects = world_data.get("objects", [])
	var transitions = world_data.get("transitions", [])
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
		var is_solid = o.get("properties", {}).get("solid", true)
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
			if o.get("properties", {}).get("solid", true):
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
	if aid in ["grass", "soil", "path", "fence", "water"]: return true
	var paths = [
		"res://assets/sprites/environment/%s.png" % aid,
		"res://assets/sprites/npc/%s_idle_0.png" % aid,
		"res://assets/sprites/npc/%s.png" % aid,
		"res://assets/sprites/plants/%s_stage_3.png" % aid,
		"res://assets/sprites/items/%s.png" % aid
	]
	for p in paths:
		if FileAccess.file_exists(p): return true
	return false
"""
	var f2 = FileAccess.open("res://editor/world_builder/world_validator.gd", FileAccess.WRITE)
	if f2: f2.store_string(validator_code); f2.close()

	print("[WorldBuilderPhase3CoreGen] Generated SmartTiler & WorldValidator!")
