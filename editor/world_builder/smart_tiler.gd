class_name SmartTiler
extends RefCounted

## High-performance O(1) Bitmask-based Auto-Tiling & Smart Placement Engine.

const MASK_NORTH = 1
const MASK_EAST  = 2
const MASK_SOUTH = 4
const MASK_WEST  = 8

const BITMASK_TO_VARIANT: Dictionary = {
	0: "single",
	1: "end_s",
	2: "end_w",
	3: "corner_ne",
	4: "end_n",
	5: "vertical",
	6: "corner_se",
	7: "t_west",
	8: "end_e",
	9: "corner_nw",
	10: "horizontal",
	11: "t_south",
	12: "corner_sw",
	13: "t_east",
	14: "t_north",
	15: "cross"
}

static var _terrain_defs_cache: Dictionary = {}

static func get_terrain_definitions() -> Dictionary:
	if not _terrain_defs_cache.is_empty():
		return _terrain_defs_cache
		
	var path = "res://data/terrain/terrain_definitions.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				_terrain_defs_cache = json.data.get("terrains", {})
	return _terrain_defs_cache

static func is_smart_type(tile_type: String) -> bool:
	var defs = get_terrain_definitions()
	if defs.has(tile_type):
		return bool(defs[tile_type].get("autotile_enabled", false))
	return tile_type in ["path", "fence", "soil", "water"]

static func calculate_connection_mask(world_data: Dictionary, pos: Vector2i, tile_type: String) -> int:
	var mask = 0
	if _has_matching_type(world_data, pos + Vector2i.UP, tile_type):    mask |= MASK_NORTH
	if _has_matching_type(world_data, pos + Vector2i.RIGHT, tile_type): mask |= MASK_EAST
	if _has_matching_type(world_data, pos + Vector2i.DOWN, tile_type):  mask |= MASK_SOUTH
	if _has_matching_type(world_data, pos + Vector2i.LEFT, tile_type):  mask |= MASK_WEST
	return mask

static func calculate_variant_from_mask(mask: int, tile_type: String = "") -> String:
	var defs = get_terrain_definitions()
	if defs.has(tile_type) and defs[tile_type].has("bitmask_variants"):
		var custom_variants = defs[tile_type]["bitmask_variants"]
		var mask_str = str(mask)
		if custom_variants.has(mask_str):
			return custom_variants[mask_str]
	return BITMASK_TO_VARIANT.get(mask, "single")

static func calculate_variant(world_data: Dictionary, pos: Vector2i, tile_type: String) -> String:
	var mask = calculate_connection_mask(world_data, pos, tile_type)
	return calculate_variant_from_mask(mask, tile_type)

static func get_deterministic_variation(pos: Vector2i, tile_type: String, max_variants: int = 3) -> int:
	if max_variants <= 1: return 0
	# Deterministic prime hash
	var h = (pos.x * 73856093 ^ pos.y * 19349663) & 0x7FFFFFFF
	return h % max_variants

static func update_tile_and_neighbors(world_data: Dictionary, pos: Vector2i) -> Array[Vector2i]:
	var updated: Array[Vector2i] = []
	var coords = [pos, pos + Vector2i.UP, pos + Vector2i.DOWN, pos + Vector2i.LEFT, pos + Vector2i.RIGHT]
	
	for p in coords:
		var tile = _get_tile(world_data, p)
		if not tile.is_empty():
			var t_type = str(tile.get("type", ""))
			if is_smart_type(t_type):
				var mask = calculate_connection_mask(world_data, p, t_type)
				tile["connection_mask"] = mask
				tile["variant"] = calculate_variant_from_mask(mask, t_type)
				updated.append(p)
	return updated

static func _has_matching_type(world_data: Dictionary, pos: Vector2i, tile_type: String) -> bool:
	var tile = _get_tile(world_data, pos)
	var t = str(tile.get("type", ""))
	if t == tile_type: return true
	# Soil and tilled fields match
	if tile_type == "soil" and t in ["soil", "tilled", "watered"]: return true
	return false

static func _get_tile(world_data: Dictionary, pos: Vector2i) -> Dictionary:
	for t in world_data.get("tiles", []):
		if int(t.get("x", -999)) == pos.x and int(t.get("y", -999)) == pos.y:
			return t
	return {}
