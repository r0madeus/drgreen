class_name GridManager
extends Node2D

## Data-driven Grid Manager: loads maps dynamically from WorldLoader JSON and handles farming loop.

const TILE_SIZE: int = 16
const DEFAULT_GRID_WIDTH: int = 32
const DEFAULT_GRID_HEIGHT: int = 24

var grid_width: int = 32
var grid_height: int = 24
var tile_size: int = 16

var tiles: Dictionary = {} # Vector2i -> GridTileData
var plant_instances: Dictionary = {} # Vector2i -> PlantInstance
var solid_obstacles: Dictionary = {} # Vector2i -> bool
var interactables: Dictionary = {} # Vector2i -> Dictionary
var dynamic_object_nodes: Array[Node] = []
const WORLD_NAVIGATION_SCENE = preload("res://systems/navigation/world_navigation.gd")
var navigation = WORLD_NAVIGATION_SCENE.new()

const PLANT_INSTANCE_SCENE = preload("res://systems/plants/plant_instance.tscn")

signal grid_initialized()
signal tile_updated(pos: Vector2i, tile: GridTileData)
signal plant_harvested(pos: Vector2i, item_id: String, count: int)

func _ready() -> void:
	var wl = get_node_or_null("/root/WorldLoader")
	if wl and "current_world_data" in wl and not wl.current_world_data.is_empty():
		load_from_world_data(wl.current_world_data)
	else:
		initialize_grid()

func initialize_grid() -> void:
	var wl = get_node_or_null("/root/WorldLoader")
	if wl and "current_world_data" in wl and not wl.current_world_data.is_empty():
		load_from_world_data(wl.current_world_data)
		return
		
	grid_width = DEFAULT_GRID_WIDTH
	grid_height = DEFAULT_GRID_HEIGHT
	_clear_all_instances()
	
	for y in range(grid_height):
		for x in range(grid_width):
			var pos = Vector2i(x, y)
			var tile_type = "grass"
			if x == 0 or x == grid_width - 1 or y == 0 or y == grid_height - 1: tile_type = "fence"
			elif (x == 15 or x == 16) or (y == 11 or y == 12): tile_type = "path"
			elif (x >= 4 and x <= 12 and y >= 3 and y <= 8) or (x >= 19 and x <= 27 and y >= 3 and y <= 8) or (x >= 4 and x <= 12 and y >= 15 and y <= 20) or (x >= 19 and x <= 27 and y >= 15 and y <= 20): tile_type = "soil"
			elif (x == 3 or x == 13 or x == 18 or x == 28) and ((y >= 2 and y <= 9) or (y >= 14 and y <= 21)): tile_type = "path"
			elif (y == 2 or y == 9 or y == 14 or y == 21) and ((x >= 3 and x <= 13) or (x >= 18 and x <= 28)): tile_type = "path"
			else: tile_type = "grass"
			
			var tile = GridTileData.new(pos, tile_type)
			tiles[pos] = tile
			if tile_type == "fence":
				solid_obstacles[pos] = true
				
	if navigation: navigation.build_graph_from_grid(self)
	grid_initialized.emit()


func load_from_world_data(world_dict: Dictionary) -> void:
	grid_width = int(world_dict.get("width", 32))
	grid_height = int(world_dict.get("height", 24))
	tile_size = int(world_dict.get("tile_size", 16))
	
	_clear_all_instances()
	
	for t in world_dict.get("tiles", []):
		var pos = Vector2i(int(t.get("x", 0)), int(t.get("y", 0)))
		var tile_type = str(t.get("type", "grass"))
		var tile = GridTileData.new(pos, tile_type)
		tile.walkable = bool(t.get("walkable", tile_type != "fence"))
		tile.solid = bool(t.get("solid", tile_type == "fence"))
		tile.interactable = bool(t.get("interactable", false))
		tiles[pos] = tile
		if tile.solid or not tile.walkable:
			solid_obstacles[pos] = true
			
	for o in world_dict.get("objects", []):
		var p = o.get("position", [0, 0])
		var pos = Vector2i(int(p[0]), int(p[1]))
		var overrides = o.get("properties", {})
		var asset_id = o.get("asset_id", "")
		var props = AssetDefinitionManager.resolve_instance_properties(asset_id, overrides)
		if props.get("solid", true):
			solid_obstacles[pos] = true
		if props.get("interactable", false):
			interactables[pos] = o
		_spawn_world_object_node(o, pos)
		
	if navigation: navigation.build_graph_from_grid(self)
	grid_initialized.emit()

func find_path(from_pos: Vector2, to_pos: Vector2) -> Array[Vector2]:
	if not navigation: navigation = WORLD_NAVIGATION_SCENE.new()
	return navigation.find_world_path(from_pos, to_pos, self)


func is_world_position_walkable(world_pos: Vector2) -> bool:
	var g_pos = world_to_grid(world_pos)
	if not is_within_bounds(g_pos): return false
	if solid_obstacles.has(g_pos) and solid_obstacles[g_pos]: return false
	var t = get_tile(g_pos)
	return (t == null or (t.walkable and not t.solid))

func _clear_all_instances() -> void:

	for inst in plant_instances.values():
		if is_instance_valid(inst): inst.queue_free()
	plant_instances.clear()
	
	for node in dynamic_object_nodes:
		if is_instance_valid(node): node.queue_free()
	dynamic_object_nodes.clear()
	
	tiles.clear()
	solid_obstacles.clear()
	interactables.clear()

func _spawn_world_object_node(obj_data: Dictionary, grid_pos: Vector2i) -> void:
	var aid = str(obj_data.get("asset_id", ""))
	if aid in ["merchant", "greenhouse_ruined", "greenhouse_repaired", "wooden_gate"]:
		return
		
	var tex = _resolve_asset_texture(aid)
	if tex:
		var sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.position = grid_to_world(grid_pos, true)
		sprite.z_index = int(obj_data.get("properties", {}).get("z_index", 0))
		add_child(sprite)
		dynamic_object_nodes.append(sprite)

func _resolve_asset_texture(asset_id: String) -> Texture2D:
	return AssetRegistry.get_asset_texture(asset_id)


func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height

func is_tile_walkable(pos: Vector2i) -> bool:
	if not is_within_bounds(pos):
		return false
	if solid_obstacles.get(pos, false):
		return false
	var wl = get_node_or_null("/root/WorldLoader")
	var cur_w = wl.current_world_id if wl else "farm"
	if pos == Vector2i(15, 3) and cur_w == "farm":
		return false
	var tile: GridTileData = tiles.get(pos)
	if tile == null:
		return false
	return tile.is_walkable()

func is_tile_interactable(pos: Vector2i) -> bool:
	if interactables.has(pos):
		return true
	var tile: GridTileData = tiles.get(pos)
	return tile != null and (tile.type == "soil" or tile.plant_id != "" or tile.interactable)

func get_tile(pos: Vector2i) -> GridTileData:
	return tiles.get(pos)

func set_tile_type(pos: Vector2i, type: String) -> void:
	if not is_within_bounds(pos):
		return
	var tile: GridTileData = tiles.get(pos)
	if tile:
		tile.type = type
		tile_updated.emit(pos, tile)
		var bus = get_node_or_null("/root/EventBus")
		if bus: bus.tile_changed.emit(pos, tile.to_dict())

func can_till_here(pos: Vector2i) -> bool:
	if not is_within_bounds(pos):
		return false
	var tile = get_tile(pos)
	if not tile or tile.solid or not tile.walkable:
		return false
	return (tile.type in ["grass", "ground", "dirt", "path", "soil"]) and tile.plant_id == ""

func till_tile(pos: Vector2i) -> bool:
	if not can_till_here(pos):
		return false
	var tile = get_tile(pos)
	tile.type = "soil"
	tile.state = "empty"
	tile.plant_id = ""
	tile.walkable = true
	tile.solid = false
	tile_updated.emit(pos, tile)
	var bus = get_node_or_null("/root/EventBus")
	if bus: bus.tile_changed.emit(pos, tile.to_dict())
	return true


var interactables_hp: Dictionary = {}
var interactable_sprites: Dictionary = {}

func can_chop_here(pos: Vector2i) -> bool:
	if not is_within_bounds(pos): return false
	if interactables.has(pos):
		var obj = interactables[pos]
		var aid = str(obj.get("asset_id", "")).to_lower()
		return aid.contains("tree") or aid.contains("stump") or aid.contains("wood") or aid.contains("log") or aid.contains("branch")
	return false

func chop_tile(pos: Vector2i, power: int = 1) -> Dictionary:
	return hit_resource(pos, power, "axe")

func can_mine_here(pos: Vector2i) -> bool:
	if not is_within_bounds(pos): return false
	if interactables.has(pos):
		var obj = interactables[pos]
		var aid = str(obj.get("asset_id", "")).to_lower()
		return aid.contains("rock") or aid.contains("stone") or aid.contains("ore") or aid.contains("boulder")
	return false

func mine_tile(pos: Vector2i, power: int = 1) -> Dictionary:
	return hit_resource(pos, power, "pickaxe")

func hit_resource(pos: Vector2i, power: int, tool_type: String) -> Dictionary:
	if not interactables.has(pos): return {}
	var obj = interactables[pos]
	var aid = str(obj.get("asset_id", "")).to_lower()
	
	# Determine resource definition ID
	var node_id = "prop." + aid
	if aid.begins_with("prop.") or aid.begins_with("resource."):
		node_id = aid
	elif aid in ["rock", "rock_small", "tree", "tree_stump", "fallen_branch"]:
		node_id = "prop." + aid
	elif aid in ["copper_ore", "iron_ore"]:
		node_id = "resource." + aid
		
	var r_def = ToolUseManager.get_resource_def(node_id)
	var req_tool = str(r_def.get("required_tool", "axe" if can_chop_here(pos) else "pickaxe"))
	var req_power = int(r_def.get("required_power", 1))
	var max_hp = int(r_def.get("max_health", 2))
	
	if tool_type != req_tool:
		return { "success": false, "reason": "wrong_tool" }
	if power < req_power:
		return { "success": false, "reason": "insufficient_power" }
		
	if not interactables_hp.has(pos):
		interactables_hp[pos] = max_hp
		
	interactables_hp[pos] -= power
	var remaining_hp = interactables_hp[pos]
	
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		bus.resource_hit.emit(node_id, pos, power, maxi(0, remaining_hp))
		
	if remaining_hp <= 0:
		# Destroyed!
		interactables_hp.erase(pos)
		interactables.erase(pos)
		solid_obstacles.erase(pos)
		
		if interactable_sprites.has(pos):
			var spr = interactable_sprites[pos]
			if is_instance_valid(spr): spr.queue_free()
			interactable_sprites.erase(pos)
			
		var drops_list = r_def.get("drops", [])
		var collected_drops: Array = []
		for d in drops_list:
			var item_id = str(d.get("item_id", "wood" if tool_type == "axe" else "stone"))
			var min_c = int(d.get("min", 1))
			var max_c = int(d.get("max", 2))
			var chance = float(d.get("chance", 1.0))
			if randf() <= chance:
				var c = randi_range(min_c, max_c)
				collected_drops.append({ "item_id": item_id, "count": c })
				if bus: bus.resource_collected.emit(item_id, c)
				
		if collected_drops.is_empty():
			var default_item = "wood" if tool_type == "axe" else "stone"
			collected_drops.append({ "item_id": default_item, "count": 2 })
			if bus: bus.resource_collected.emit(default_item, 2)
			
		if bus:
			bus.resource_destroyed.emit(node_id, pos)
			
		return {
			"success": true,
			"destroyed": true,
			"node_id": node_id,
			"drops": collected_drops,
			"sfx": r_def.get("destroy_sfx", "farming.harvest"),
			"effect": r_def.get("destroy_effect", "effect.farming.harvest")
		}
	else:
		return {
			"success": true,
			"destroyed": false,
			"node_id": node_id,
			"remaining_hp": remaining_hp,
			"sfx": r_def.get("hit_sfx", "ui.select"),
			"effect": r_def.get("hit_effect", "effect.farming.plant")
		}


func can_plant_here(pos: Vector2i) -> bool:

	if not is_within_bounds(pos):
		return false
	var tile = get_tile(pos)
	return tile != null and tile.type == "soil" and tile.state == "empty"

func plant_seed(pos: Vector2i, plant_id: String) -> bool:
	if not can_plant_here(pos):
		return false
		
	var pm = get_node_or_null("/root/PlantManager")
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	if pm and pm.is_greenhouse_only(plant_id):
		if not (gm_mgr and gm_mgr.is_greenhouse_tile(pos)):
			var spawner = EffectSpawner.get_instance()
			var world_pos = grid_to_world(pos, true)
			if spawner: spawner.spawn_floating_text(world_pos, "⚠️ Requires Greenhouse Soil!", Color(1.0, 0.4, 0.4))
			return false
		
	var tile = get_tile(pos)
	tile.plant_id = plant_id
	tile.growth_stage = 0
	tile.days_in_stage = 0
	tile.watered_today = false
	tile.state = "planted"
	
	_spawn_plant_instance(pos, plant_id, 0, 0, false)
	
	tile_updated.emit(pos, tile)
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		bus.tile_changed.emit(pos, tile.to_dict())
		bus.plant_planted.emit(pos, plant_id)
	return true

func _spawn_plant_instance(pos: Vector2i, plant_id: String, stage: int, days: int, watered: bool) -> void:
	if plant_instances.has(pos):
		var old = plant_instances[pos]
		if is_instance_valid(old): old.queue_free()
		plant_instances.erase(pos)
		
	var inst = PLANT_INSTANCE_SCENE.instantiate() as PlantInstance
	add_child(inst)
	inst.setup(plant_id, pos, stage, watered)
	inst.days_in_stage = days
	plant_instances[pos] = inst

func water_tile(pos: Vector2i) -> bool:
	if not is_within_bounds(pos):
		return false
	var tile = get_tile(pos)
	if not tile or tile.type != "soil":
		return false
		
	tile.watered_today = true
	if plant_instances.has(pos):
		plant_instances[pos].set_watered(true)
		
	tile_updated.emit(pos, tile)
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		bus.tile_changed.emit(pos, tile.to_dict())
		bus.plant_watered.emit(pos)
	return true

func is_tile_harvestable(pos: Vector2i) -> bool:
	if not is_within_bounds(pos):
		return false
	var tile = get_tile(pos)
	if not tile or tile.plant_id == "":
		return false
	if plant_instances.has(pos):
		return plant_instances[pos].is_mature
	return tile.state == "mature"

func harvest_tile(pos: Vector2i, player_id: String = "player_001") -> Dictionary:
	if not is_tile_harvestable(pos):
		return {}
		
	var tile = get_tile(pos)
	var plant_id = tile.plant_id
	var yield_count = 1
	var pm = get_node_or_null("/root/PlantManager")
	if pm: yield_count = pm.get_harvest_yield(plant_id)
		
	var econ = get_node_or_null("/root/EconomyManager")
	if econ and econ.has_upgrade(player_id, "better_tools"): yield_count += 1
		
	if plant_instances.has(pos):
		var inst = plant_instances[pos]
		if is_instance_valid(inst): inst.queue_free()
		plant_instances.erase(pos)
		
	tile.plant_id = ""
	tile.growth_stage = 0
	tile.days_in_stage = 0
	tile.watered_today = false
	tile.state = "empty"
	
	tile_updated.emit(pos, tile)
	plant_harvested.emit(pos, plant_id, yield_count)
	
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	if gm_mgr and gm_mgr.is_greenhouse_tile(pos):
		var qm = get_node_or_null("/root/QuestManager")
		if qm: qm.advance_objective("harvest_greenhouse", yield_count)
	
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		bus.tile_changed.emit(pos, tile.to_dict())
		bus.plant_harvested.emit(pos, plant_id, yield_count)
		
	return { "item_id": plant_id, "yield": yield_count }

func apply_rain_watering() -> void:
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	for pos in tiles.keys():
		var tile: GridTileData = tiles[pos]
		if tile.type == "soil":
			if not (gm_mgr and gm_mgr.is_greenhouse_tile(pos)):
				tile.watered_today = true
				if plant_instances.has(pos): plant_instances[pos].set_watered(true)
				tile_updated.emit(pos, tile)

func advance_day() -> void:
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	var sm_mgr = get_node_or_null("/root/SeasonManager")
	var is_winter_season = sm_mgr.is_winter() if sm_mgr else false
	var g_bonus = gm_mgr.growth_bonus if gm_mgr else 0.25
	
	for pos in tiles.keys():
		var tile: GridTileData = tiles[pos]
		if tile.plant_id != "":
			var inst = plant_instances.get(pos)
			var in_greenhouse = (gm_mgr and gm_mgr.is_greenhouse_tile(pos))
			if tile.watered_today:
				if is_winter_season and not in_greenhouse:
					if inst: inst.set_watered(false)
				else:
					if inst:
						inst.advance_growth()
						if in_greenhouse and randf() < g_bonus:
							inst.advance_growth()
						tile.growth_stage = inst.growth_stage
						tile.state = "mature" if inst.is_mature else "growing"
					else:
						tile.growth_stage += 1
						var max_st = 3
						var pm = get_node_or_null("/root/PlantManager")
						if pm: max_st = pm.get_max_stages(tile.plant_id)
						tile.state = "mature" if tile.growth_stage >= max_st else "growing"
			elif inst:
				inst.set_watered(false)
			tile.watered_today = false
			tile_updated.emit(pos, tile)

		else:
			if tile.watered_today:
				tile.watered_today = false
				tile_updated.emit(pos, tile)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_pos.x / tile_size)), int(floor(world_pos.y / tile_size)))

func grid_to_world(grid_pos: Vector2i, center: bool = true) -> Vector2:
	if center:
		return Vector2(grid_pos.x * tile_size + tile_size * 0.5, grid_pos.y * tile_size + tile_size * 0.5)
	return Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
