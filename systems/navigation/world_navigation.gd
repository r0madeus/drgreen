class_name WorldNavigation
extends RefCounted

## Obstacle-aware 2D world-space navigation graph and pathfinding engine.
## Builds navigation topologies directly from GridManager tiles and solid_obstacles.
## Generates smooth, continuous world-space path waypoints with corner-cutting prevention and string-pulling.

var astar: AStar2D = AStar2D.new()
var width: int = 32
var height: int = 24
var tile_size: int = 16
var _point_ids: Dictionary = {} # Vector2i -> int
var _passable_tiles: Dictionary = {} # Vector2i -> bool

func _get_point_id(pos: Vector2i) -> int:
	return pos.y * width + pos.x

func build_graph_from_grid(grid_manager: Node) -> void:
	if not grid_manager: return
	
	astar.clear()
	_point_ids.clear()
	_passable_tiles.clear()
	
	width = int(grid_manager.get("grid_width")) if grid_manager.get("grid_width") != null else 32
	height = int(grid_manager.get("grid_height")) if grid_manager.get("grid_height") != null else 24
	tile_size = int(grid_manager.get("tile_size")) if grid_manager.get("tile_size") != null else 16
	
	# 1. Identify passable cells & register AStar points
	for y in range(height):
		for x in range(width):
			var pos = Vector2i(x, y)
			if _is_tile_passable(pos, grid_manager):
				_passable_tiles[pos] = true
				var pid = _get_point_id(pos)
				_point_ids[pos] = pid
				var world_p = grid_manager.grid_to_world(pos, true) if grid_manager.has_method("grid_to_world") else Vector2(pos.x * 16 + 8, pos.y * 16 + 8)
				astar.add_point(pid, world_p, 1.0)
				
	# 2. Connect neighbors
	for pos in _passable_tiles.keys():
		var pid = _get_point_id(pos)
		
		# Orthogonal connections
		var cardinals = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
		for offset in cardinals:
			var neighbor_pos = pos + offset
			if _passable_tiles.has(neighbor_pos):
				var nid = _get_point_id(neighbor_pos)
				if not astar.are_points_connected(pid, nid):
					astar.connect_points(pid, nid, true)
					
		# Diagonal connections (strictly check adjacent cardinal cells to prevent corner cutting!)
		var diagonals = [
			{ "offset": Vector2i(1, 1), "c1": Vector2i(1, 0), "c2": Vector2i(0, 1) },
			{ "offset": Vector2i(-1, 1), "c1": Vector2i(-1, 0), "c2": Vector2i(0, 1) },
			{ "offset": Vector2i(1, -1), "c1": Vector2i(1, 0), "c2": Vector2i(0, -1) },
			{ "offset": Vector2i(-1, -1), "c1": Vector2i(-1, 0), "c2": Vector2i(0, -1) }
		]
		
		for diag in diagonals:
			var diag_pos = pos + diag["offset"]
			if _passable_tiles.has(diag_pos):
				# Only connect diagonal if both surrounding orthogonal cells are passable
				var check1 = pos + diag["c1"]
				var check2 = pos + diag["c2"]
				if _passable_tiles.has(check1) and _passable_tiles.has(check2):
					var nid = _get_point_id(diag_pos)
					if not astar.are_points_connected(pid, nid):
						astar.connect_points(pid, nid, true)

func _is_tile_passable(pos: Vector2i, grid_manager: Node) -> bool:
	if not grid_manager: return true
	if grid_manager.has_method("is_within_bounds") and not grid_manager.is_within_bounds(pos):
		return false
		
	var solid_obs = grid_manager.get("solid_obstacles")
	if solid_obs is Dictionary and solid_obs.has(pos) and solid_obs[pos]:
		return false
		
	if grid_manager.has_method("get_tile"):
		var tile = grid_manager.get_tile(pos)
		if tile:
			if tile.solid or not tile.walkable or tile.type in ["fence", "water", "void"]:
				return false
			
	return true

func find_world_path(from_pos: Vector2, to_pos: Vector2, grid_manager: Node) -> Array[Vector2]:
	if not grid_manager:
		return [to_pos]
		
	var from_grid = grid_manager.world_to_grid(from_pos) if grid_manager.has_method("world_to_grid") else Vector2i(int(floor(from_pos.x / 16.0)), int(floor(from_pos.y / 16.0)))
	var to_grid = grid_manager.world_to_grid(to_pos) if grid_manager.has_method("world_to_grid") else Vector2i(int(floor(to_pos.x / 16.0)), int(floor(to_pos.y / 16.0)))
	
	# If target tile is solid, try to find closest adjacent walkable tile
	if not _is_tile_passable(to_grid, grid_manager):
		to_grid = find_closest_passable_grid_pos(to_grid, grid_manager)
		to_pos = grid_manager.grid_to_world(to_grid, true) if grid_manager.has_method("grid_to_world") else Vector2(to_grid.x * 16 + 8, to_grid.y * 16 + 8)
		
	if not _is_tile_passable(from_grid, grid_manager):
		from_grid = find_closest_passable_grid_pos(from_grid, grid_manager)
		
	# If start and destination are identical
	if from_grid == to_grid:
		return [to_pos]
		
	# Check fast direct line-of-sight
	if has_line_of_sight(from_pos, to_pos, grid_manager):
		return [to_pos]
		
	var start_id = _get_point_id(from_grid)
	var end_id = _get_point_id(to_grid)
	
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return []
		
	var raw_points = astar.get_point_path(start_id, end_id)
	if raw_points.is_empty():
		return []
		
	var path: Array[Vector2] = []
	for p in raw_points:
		path.append(p)
		
	if not path.is_empty():
		path[0] = from_pos
		path[path.size() - 1] = to_pos
		
	# Apply line-of-sight string pulling (smooth path)
	var smoothed = smooth_path(path, grid_manager)
	return smoothed

func has_line_of_sight(from_pos: Vector2, to_pos: Vector2, grid_manager: Node) -> bool:
	if not grid_manager: return true
	
	var dist = from_pos.distance_to(to_pos)
	if dist < 1.0: return true
	
	var step_size = 4.0 # Sample every 4 pixels along the segment
	var num_steps = int(ceil(dist / step_size))
	var dir = (to_pos - from_pos).normalized()
	
	for i in range(1, num_steps):
		var check_p = from_pos + dir * (i * step_size)
		var check_grid = grid_manager.world_to_grid(check_p) if grid_manager.has_method("world_to_grid") else Vector2i(int(floor(check_p.x / 16.0)), int(floor(check_p.y / 16.0)))
		if not _is_tile_passable(check_grid, grid_manager):
			return false
			
	return true

func smooth_path(input_path: Array[Vector2], grid_manager: Node) -> Array[Vector2]:
	if input_path.size() <= 2:
		return input_path
		
	var smoothed: Array[Vector2] = [input_path[0]]
	var current_idx = 0
	
	while current_idx < input_path.size() - 1:
		var furthest_idx = current_idx + 1
		for check_idx in range(input_path.size() - 1, current_idx, -1):
			if has_line_of_sight(input_path[current_idx], input_path[check_idx], grid_manager):
				furthest_idx = check_idx
				break
		smoothed.append(input_path[furthest_idx])
		current_idx = furthest_idx
		
	return smoothed

func find_closest_passable_grid_pos(pos: Vector2i, grid_manager: Node) -> Vector2i:
	if _is_tile_passable(pos, grid_manager):
		return pos
		
	for radius in range(1, 6):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if abs(dx) == radius or abs(dy) == radius:
					var test_p = pos + Vector2i(dx, dy)
					if _is_tile_passable(test_p, grid_manager):
						return test_p
						
	return pos
