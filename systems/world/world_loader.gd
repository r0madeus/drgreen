extends Node

## Central Runtime World Loader managing data-driven level loading, transitions, and world states.

const DEFAULT_WORLD_ID: String = "farm"

static var instance = null

var current_world_id: String = DEFAULT_WORLD_ID
var current_world_data: Dictionary = {}
var world_states: Dictionary = {} # world_id -> { "plants": [...], "world_objects": [...] }
var is_transitioning: bool = false

signal world_loaded(world_id: String, world_data: Dictionary)
signal world_transition_finished(world_id: String)

func _init() -> void:
	instance = self

func _ready() -> void:
	instance = self
	load_world(DEFAULT_WORLD_ID)

static func get_active_world_id() -> String:
	if instance: return instance.current_world_id
	return DEFAULT_WORLD_ID

static func get_active_world_data() -> Dictionary:
	if instance: return instance.current_world_data
	return {}

func load_world(world_id: String) -> Dictionary:
	var es = EditorService.get_instance() if ClassDB.class_exists("EditorService") else null
	if es and es.data_service:
		var w_obj: Dictionary = es.data_service.get_resolved_object("world." + world_id)
		if w_obj.is_empty():
			w_obj = es.data_service.get_resolved_object(world_id)
		if not w_obj.is_empty() and w_obj.has("width") and w_obj.has("height"):
			current_world_id = world_id
			current_world_data = w_obj
			world_loaded.emit(world_id, current_world_data)
			return current_world_data

	var path = "res://data/worlds/%s.json" % world_id
	if not FileAccess.file_exists(path):
		push_warning("[WorldLoader] World file not found: %s, falling back to farm." % path)
		world_id = DEFAULT_WORLD_ID
		path = "res://data/worlds/farm.json"
		
	var data = WorldSerializer.load_world(path)
	if data.is_empty():
		push_error("[WorldLoader] Failed to load world data from: %s" % path)
		data = WorldSerializer.create_empty_world(32, 24, "farm", "Peaceful Farm")
		
	current_world_id = world_id
	current_world_data = data
	world_loaded.emit(world_id, current_world_data)
	return current_world_data

func transition_to_world(player_id: String, target_world_id: String, target_spawn: Variant = null, animate: bool = true) -> bool:
	return await change_world(player_id, target_world_id, target_spawn, animate)

func change_world(player_id: String, target_world_id: String, target_spawn: Variant = null, animate: bool = true) -> bool:
	if is_transitioning:
		return false
		
	is_transitioning = true
	EventBus.world_transition_started.emit(target_world_id)
	
	var player = get_tree().root.find_child("Player", true, false) as Player
	if player: player.set_movement_locked(true)
		
	_save_current_world_runtime_state()
	
	if animate:
		var tree = get_tree()
		if tree: await tree.create_timer(0.2).timeout
			
	load_world(target_world_id)
	
	var gm = get_tree().root.find_child("GridManager", true, false) as GridManager
	if gm:
		gm.load_from_world_data(current_world_data)
		_restore_world_runtime_state(target_world_id, gm)
		
	var spawn_coord = Vector2i(16, 12)
	if target_spawn != null:
		if target_spawn is Vector2i:
			spawn_coord = target_spawn
		elif target_spawn is Array and target_spawn.size() >= 2:
			spawn_coord = Vector2i(int(target_spawn[0]), int(target_spawn[1]))
		elif target_spawn is String:
			var sp_map = current_world_data.get("spawn_points", {})
			if sp_map.has(target_spawn):
				var p = sp_map[target_spawn]
				spawn_coord = Vector2i(int(p[0]), int(p[1]))
			else:
				var wm = get_node_or_null("/root/WorldManager")
				if wm: spawn_coord = wm.get_spawn_point(target_world_id, str(target_spawn))
	elif current_world_data.has("spawn"):
		var sp_arr = current_world_data["spawn"]
		spawn_coord = Vector2i(int(sp_arr[0]), int(sp_arr[1]))
		
	var spawn_world_pos = gm.grid_to_world(spawn_coord, true) if gm else Vector2(spawn_coord.x * 16 + 8, spawn_coord.y * 16 + 8)
	var psm = get_node_or_null("/root/PlayerRegistry")
	if psm and player_id != "":
		var p_state = psm.get_player_state(player_id) if psm.has_method("get_player_state") else null
		if p_state:
			p_state.current_world = target_world_id
			p_state.position = spawn_world_pos
			p_state.grid_position = spawn_coord

	if player:
		player.grid_position = spawn_coord
		player.position = spawn_world_pos
		player.velocity = Vector2.ZERO
		var cam = player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = int(current_world_data.get("width", 32)) * 16
			cam.limit_bottom = int(current_world_data.get("height", 24)) * 16
			
	EventBus.world_changed.emit(target_world_id, current_world_data)
	
	if animate:
		var tree = get_tree()
		if tree: await tree.create_timer(0.2).timeout
			
	if player: player.set_movement_locked(false)
		
	is_transitioning = false
	world_transition_finished.emit(target_world_id)
	EventBus.world_transition_completed.emit(target_world_id)
	print("[WorldLoader] Successfully transitioned to world: %s at spawn %s" % [target_world_id, spawn_coord])
	return true

func check_transition_trigger(pos: Vector2i) -> Dictionary:
	for tr in current_world_data.get("transitions", []):
		var p = tr.get("position", [-1, -1])
		if int(p[0]) == pos.x and int(p[1]) == pos.y:
			return tr
			
	var gm = get_tree().root.find_child("GridManager", true, false)
	if gm and gm.interactables.has(pos):
		var obj = gm.interactables[pos]
		var props = AssetDefinitionManager.resolve_instance_properties(obj.get("asset_id", ""), obj.get("properties", {}))
		if props.get("interaction_type") == "world_transition":
			return {
				"target_world": props.get("target_world", ""),
				"target_spawn": props.get("interaction_id", "default"),
				"name": props.get("interaction_id", ""),
				"position": [pos.x, pos.y]
			}
			
	return {}

func get_current_world_id() -> String:
	return current_world_id

func get_current_world_data() -> Dictionary:
	return current_world_data

func get_current_world_display_name() -> String:
	return str(current_world_data.get("display_name", current_world_id.capitalize()))

func get_world_state(world_id: String) -> Dictionary:
	return world_states.get(world_id, {})

func set_world_state(world_id: String, state: Dictionary) -> void:
	world_states[world_id] = state

func _save_current_world_runtime_state() -> void:
	var gm = get_tree().root.find_child("GridManager", true, false) as GridManager
	if not gm: return
	
	var plants_arr: Array = []
	var modified_tiles: Dictionary = {}
	var wm = get_node_or_null("/root/WorldManager")
	var sw_state = wm.get_shared_world_state(current_world_id) if wm else null
	if sw_state: sw_state.plants.clear()
	
	for pos in gm.tiles.keys():
		var tile: GridTileData = gm.tiles[pos]
		if tile.type == "soil" or tile.watered_today:
			modified_tiles[pos] = {
				"type": tile.type,
				"watered_today": tile.watered_today,
				"state": tile.state
			}
			if sw_state:
				sw_state.modified_tiles[pos] = modified_tiles[pos]
				
		if tile.plant_id != "":
			var inst = gm.plant_instances.get(pos)
			var stage = inst.growth_stage if inst else tile.growth_stage
			var days = inst.days_in_stage if inst else tile.days_in_stage
			var watered = inst.watered_today if inst else tile.watered_today
			plants_arr.append({
				"position": [pos.x, pos.y],
				"plant_id": tile.plant_id,
				"growth_stage": stage,
				"days_in_stage": days,
				"watered_today": watered
			})
			if sw_state:
				sw_state.add_or_update_plant(pos, tile.plant_id, stage, days, watered)
				
	world_states[current_world_id] = {
		"plants": plants_arr,
		"modified_tiles": modified_tiles,
		"interactables_hp": gm.interactables_hp.duplicate(),
		"interactables_keys": gm.interactables.keys()
	}

func _restore_world_runtime_state(world_id: String, gm: GridManager) -> void:
	var wm = get_node_or_null("/root/WorldManager")
	var sw_state = wm.get_shared_world_state(world_id) if wm else null
	
	var state = world_states.get(world_id, {})
	
	# 1. Restore Modified Tiles (tilled soil, watered status)
	var mod_tiles = {}
	if sw_state and sw_state.modified_tiles.size() > 0:
		mod_tiles = sw_state.modified_tiles
	else:
		mod_tiles = state.get("modified_tiles", {})
		
	for pos in mod_tiles.keys():
		if gm.tiles.has(pos):
			var t_info = mod_tiles[pos]
			var tile: GridTileData = gm.tiles[pos]
			tile.type = str(t_info.get("type", "soil"))
			tile.watered_today = bool(t_info.get("watered_today", false))
			tile.state = str(t_info.get("state", "empty"))
			gm.tile_updated.emit(pos, tile)
			
	# 2. Restore Plants
	var plants_arr = []
	if sw_state and sw_state.plants.size() > 0:
		plants_arr = sw_state.get_all_plants()
	else:
		plants_arr = state.get("plants", [])
		
	for p_data in plants_arr:
		var pos_arr = p_data.get("position", [0, 0])
		var pos = Vector2i(int(pos_arr[0]), int(pos_arr[1]))
		var plant_id = p_data.get("plant_id", "")
		var stage = int(p_data.get("growth_stage", 0))
		var days = int(p_data.get("days_in_stage", 0))
		var watered = bool(p_data.get("watered_today", false))
		
		if gm.tiles.has(pos):
			var tile = gm.tiles[pos]
			tile.plant_id = plant_id
			tile.growth_stage = stage
			tile.days_in_stage = days
			tile.watered_today = watered
			gm._spawn_plant_instance(pos, plant_id, stage, days, watered)
			if sw_state:
				sw_state.add_or_update_plant(pos, plant_id, stage, days, watered)
				
	# 3. Restore Destroyed / Damaged Interactables
	if state.has("interactables_keys"):
		var saved_keys = state["interactables_keys"]
		for pos in gm.interactables.keys():
			if not saved_keys.has(pos):
				gm.interactables.erase(pos)
				gm.solid_obstacles.erase(pos)
				if gm.interactable_sprites.has(pos):
					var spr = gm.interactable_sprites[pos]
					if is_instance_valid(spr): spr.queue_free()
					gm.interactable_sprites.erase(pos)
					
	if state.has("interactables_hp"):
		gm.interactables_hp = state["interactables_hp"].duplicate()
