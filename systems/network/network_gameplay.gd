extends Node

## Authoritative Co-op Gameplay Synchronization Manager (Autoload Singleton).
## Handles Host-authoritative validation for Farming actions (Plant -> Water -> Grow -> Harvest),
## multi-world snapshot replication, and conflict resolution.

signal plant_synced(world_id: String, pos: Vector2i, plant_id: String)
signal water_synced(world_id: String, pos: Vector2i)
signal harvest_synced(world_id: String, pos: Vector2i, crop_id: String, count: int)
signal snapshot_applied(world_id: String)
signal gameplay_error(reason: String)

const MAX_INTERACTION_DISTANCE_SQ: float = 36.0 # Max ~6 tiles range check

func is_host() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_host() if nm else true

func is_offline() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_offline() if nm else true

func get_local_peer_id() -> int:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.get_local_peer_id() if nm else 1

# ==============================================================================
# CLIENT REQUEST APIS
# ==============================================================================

func request_plant(world_id: String, grid_pos: Vector2i, seed_id: String) -> void:
	if is_offline():
		_execute_local_plant(world_id, grid_pos, seed_id)
		return
	rpc("client_request_plant", get_local_peer_id(), world_id, grid_pos.x, grid_pos.y, seed_id)

func request_water(world_id: String, grid_pos: Vector2i) -> void:
	if is_offline():
		_execute_local_water(world_id, grid_pos)
		return
	rpc("client_request_water", get_local_peer_id(), world_id, grid_pos.x, grid_pos.y)

func request_harvest(world_id: String, grid_pos: Vector2i) -> void:
	if is_offline():
		_execute_local_harvest(world_id, grid_pos)
		return
	rpc("client_request_harvest", get_local_peer_id(), world_id, grid_pos.x, grid_pos.y)

func _get_active_grid_manager() -> GridManager:
	var tree = get_tree()
	if tree and tree.current_scene:
		return tree.current_scene.find_child("GridManager", true, false) as GridManager
	elif tree and tree.root:
		return tree.root.find_child("GridManager", true, false) as GridManager
	return null

func request_hoe(world_id: String, grid_pos: Vector2i, item_id: String = "hoe_basic") -> void:

	if is_offline():
		_execute_local_hoe(world_id, grid_pos, item_id)
		return
	rpc("client_request_hoe", get_local_peer_id(), world_id, grid_pos.x, grid_pos.y, item_id)

func request_axe(world_id: String, grid_pos: Vector2i, item_id: String = "axe_basic") -> void:
	if is_offline():
		_execute_local_axe(world_id, grid_pos, item_id)
		return
	rpc("client_request_axe", get_local_peer_id(), world_id, grid_pos.x, grid_pos.y, item_id)

func request_pickaxe(world_id: String, grid_pos: Vector2i, item_id: String = "pickaxe_basic") -> void:
	if is_offline():
		_execute_local_pickaxe(world_id, grid_pos, item_id)
		return
	rpc("client_request_pickaxe", get_local_peer_id(), world_id, grid_pos.x, grid_pos.y, item_id)

func _execute_local_hoe(world_id: String, grid_pos: Vector2i, _item_id: String) -> void:
	var gm = _get_active_grid_manager()
	if gm and gm.can_till_here(grid_pos):
		gm.till_tile(grid_pos)

func _execute_local_axe(world_id: String, grid_pos: Vector2i, _item_id: String) -> void:
	var gm = _get_active_grid_manager()
	if gm and gm.can_chop_here(grid_pos):
		var psm = get_node_or_null("/root/PlayerStateManager")
		var p_state = psm.get_active_player_state() if psm else null
		var drop = gm.chop_tile(grid_pos)
		if not drop.is_empty() and p_state:
			p_state.add_item(drop.get("item_id", "wood"), drop.get("count", 2))

func _execute_local_pickaxe(world_id: String, grid_pos: Vector2i, _item_id: String) -> void:
	var gm = _get_active_grid_manager()
	if gm and gm.can_mine_here(grid_pos):
		var psm = get_node_or_null("/root/PlayerStateManager")
		var p_state = psm.get_active_player_state() if psm else null
		var drop = gm.mine_tile(grid_pos)
		if not drop.is_empty() and p_state:
			p_state.add_item(drop.get("item_id", "stone"), drop.get("count", 2))

func request_world_snapshot(world_id: String) -> void:
	if is_offline(): return
	rpc("client_request_snapshot", get_local_peer_id(), world_id)


# ==============================================================================
# HOST AUTHORITATIVE RPC REQUEST HANDLERS
# ==============================================================================

func _get_player_state_for_peer(peer_id: int) -> PlayerState:
	var psm = get_node_or_null("/root/PlayerStateManager")
	if not psm: return null
	if peer_id == 1:
		return psm.get_active_player_state()
		
	var nm = get_node_or_null("/root/NetworkManager")
	if nm and nm.session:
		var ident = nm.session.get_peer(peer_id)
		if ident and psm.players.has(ident.player_id):
			return psm.players[ident.player_id]
			
	var id_pad = "player_%03d" % peer_id
	if psm.players.has(id_pad): return psm.players[id_pad]
	var id_raw = "player_%d" % peer_id
	if psm.players.has(id_raw): return psm.players[id_raw]
	
	return psm.get_active_player_state()

@rpc("any_peer", "call_local", "reliable")
func client_request_plant(requester_peer: int, world_id: String, pos_x: int, pos_y: int, seed_id: String) -> void:
	if not is_host(): return
	
	var pos = Vector2i(pos_x, pos_y)
	var wm = get_node_or_null("/root/WorldManager")
	if not wm: return
	
	var world_state = wm.get_shared_world_state(world_id)
	var player_state = _get_player_state_for_peer(requester_peer)
	if not player_state: return
		
	# 1. Validation Checks
	if world_state.has_plant(pos):
		_send_failure(requester_peer, "ALREADY_PLANTED")
		return
		
	if not player_state.has_item(seed_id, 1):
		_send_failure(requester_peer, "NOT_ENOUGH_ITEMS")
		return
		
	var plant_id = seed_id.trim_prefix("seed_")
	
	# 2. Mutate authoritative state
	player_state.remove_item(seed_id, 1)
	world_state.add_or_update_plant(pos, plant_id, 0, 0, false)
	
	# 3. Broadcast authoritative result to all peers
	rpc("broadcast_plant_created", world_id, pos.x, pos.y, plant_id, 0, 0, false)
	print("[NetworkGameplay] Host approved planting of %s at %s for peer %d" % [plant_id, pos, requester_peer])

@rpc("any_peer", "call_local", "reliable")
func client_request_water(requester_peer: int, world_id: String, pos_x: int, pos_y: int) -> void:
	if not is_host(): return
	
	var pos = Vector2i(pos_x, pos_y)
	var wm = get_node_or_null("/root/WorldManager")
	if not wm: return
	
	var world_state = wm.get_shared_world_state(world_id)
	if not world_state.has_plant(pos):
		# Also valid if soil tile exists
		rpc("broadcast_plant_watered", world_id, pos.x, pos.y)
		return
		
	var p_data = world_state.get_plant(pos)
	if p_data.get("watered_today", false):
		_send_failure(requester_peer, "ALREADY_WATERED")
		return
		
	# Update authoritative plant state
	world_state.add_or_update_plant(pos, p_data.get("plant_id", ""), p_data.get("growth_stage", 0), p_data.get("days_in_stage", 0), true)
	rpc("broadcast_plant_watered", world_id, pos.x, pos.y)
	print("[NetworkGameplay] Host approved watering at %s for peer %d" % [pos, requester_peer])

@rpc("any_peer", "call_local", "reliable")
func client_request_harvest(requester_peer: int, world_id: String, pos_x: int, pos_y: int) -> void:
	if not is_host(): return
	
	var pos = Vector2i(pos_x, pos_y)
	var wm = get_node_or_null("/root/WorldManager")
	if not wm: return
	
	var world_state = wm.get_shared_world_state(world_id)
	if not world_state.has_plant(pos):
		_send_failure(requester_peer, "PLANT_NOT_FOUND")
		return
		
	var p_data = world_state.get_plant(pos)
	var plant_id = p_data.get("plant_id", "")
	var stage = p_data.get("growth_stage", 0)
	
	# Check maturity (stage >= 2)
	if stage < 2:
		_send_failure(requester_peer, "NOT_MATURE")
		return
		
	# Atomically remove from authoritative world and reward requesting player
	world_state.remove_plant(pos)
	
	var yield_count = 1
	var pm = get_node_or_null("/root/PlantManager")
	if pm: yield_count = pm.get_harvest_yield(plant_id)
	
	var player_state = _get_player_state_for_peer(requester_peer)
	if player_state:
		player_state.add_item(plant_id, yield_count)
	
	rpc("broadcast_plant_harvested", world_id, pos.x, pos.y, requester_peer, plant_id, yield_count)
	print("[NetworkGameplay] Host approved harvest of %s at %s for peer %d (+%d)" % [plant_id, pos, requester_peer, yield_count])


@rpc("any_peer", "call_local", "reliable")
func client_request_snapshot(requester_peer: int, world_id: String) -> void:
	if not is_host(): return
	var wm = get_node_or_null("/root/WorldManager")
	if not wm: return
	
	var world_state = wm.get_shared_world_state(world_id)
	var snapshot_arr = world_state.get_all_plants()
	if requester_peer == 1 or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(requester_peer):
		receive_world_snapshot(world_id, snapshot_arr)
	else:
		rpc_id(requester_peer, "receive_world_snapshot", world_id, snapshot_arr)


# ==============================================================================
# BROADCAST RPC RECEIVERS (EXECUTED ON ALL PEERS)
# ==============================================================================

@rpc("authority", "call_local", "reliable")
func broadcast_plant_created(world_id: String, pos_x: int, pos_y: int, plant_id: String, stage: int, days: int, watered: bool) -> void:
	var pos = Vector2i(pos_x, pos_y)
	var wm = get_node_or_null("/root/WorldManager")
	var cur_world = wm.get_current_world() if wm else "farm"
	
	# Update local shared state cache
	if wm:
		var state = wm.get_shared_world_state(world_id)
		state.add_or_update_plant(pos, plant_id, stage, days, watered)
		
	# Update active scene if currently in this world
	if cur_world == world_id:
		var tree = get_tree()
		var gm = tree.current_scene.find_child("GridManager", true, false) if (tree and tree.current_scene) else null
		if gm:
			var tile = gm.get_tile(pos)
			if tile:
				tile.plant_id = plant_id
				tile.growth_stage = stage
				tile.days_in_stage = days
				tile.watered_today = watered
				tile.state = "planted"
				gm._spawn_plant_instance(pos, plant_id, stage, days, watered)
				gm.tile_updated.emit(pos, tile)
				
		# Local visual and sound effects
		var am = get_node_or_null("/root/AudioManager")
		var spawner = EffectSpawner.get_instance()
		if am: am.play_sfx("plant")
		if spawner and gm:
			var world_pos = gm.grid_to_world(pos, true)
			spawner.spawn_planting_effect(world_pos)
			spawner.spawn_floating_text(world_pos, "🌱 Planted", Color(0.6, 1.0, 0.5))
			
	plant_synced.emit(world_id, pos, plant_id)

@rpc("authority", "call_local", "reliable")
func broadcast_plant_watered(world_id: String, pos_x: int, pos_y: int) -> void:
	var pos = Vector2i(pos_x, pos_y)
	var wm = get_node_or_null("/root/WorldManager")
	var cur_world = wm.get_current_world() if wm else "farm"
	
	if wm:
		var state = wm.get_shared_world_state(world_id)
		var p_data = state.get_plant(pos)
		if not p_data.is_empty():
			state.add_or_update_plant(pos, p_data.get("plant_id", ""), p_data.get("growth_stage", 0), p_data.get("days_in_stage", 0), true)
			
	if cur_world == world_id:
		var tree = get_tree()
		var gm = tree.current_scene.find_child("GridManager", true, false) if (tree and tree.current_scene) else null
		if gm:
			var tile = gm.get_tile(pos)
			if tile:
				tile.watered_today = true
				if gm.plant_instances.has(pos):
					gm.plant_instances[pos].set_watered(true)
				gm.tile_updated.emit(pos, tile)
				
		var am = get_node_or_null("/root/AudioManager")
		var spawner = EffectSpawner.get_instance()
		if am: am.play_sfx("water")
		if spawner and gm:
			var world_pos = gm.grid_to_world(pos, true)
			spawner.spawn_watering_effect(world_pos)
			spawner.spawn_floating_text(world_pos, "💧 Watered", Color(0.4, 0.8, 1.0))
			
	water_synced.emit(world_id, pos)

@rpc("authority", "call_local", "reliable")
func broadcast_plant_harvested(world_id: String, pos_x: int, pos_y: int, harvester_peer: int, crop_id: String, count: int) -> void:
	var pos = Vector2i(pos_x, pos_y)
	var wm = get_node_or_null("/root/WorldManager")
	var cur_world = wm.get_current_world() if wm else "farm"
	
	if wm:
		var state = wm.get_shared_world_state(world_id)
		state.remove_plant(pos)
		
	if cur_world == world_id:
		var tree = get_tree()
		var gm = tree.current_scene.find_child("GridManager", true, false) if (tree and tree.current_scene) else null
		if gm:
			if gm.plant_instances.has(pos):
				var inst = gm.plant_instances[pos]
				if is_instance_valid(inst): inst.queue_free()
				gm.plant_instances.erase(pos)
			var tile = gm.get_tile(pos)
			if tile:
				tile.plant_id = ""
				tile.growth_stage = 0
				tile.days_in_stage = 0
				tile.watered_today = false
				tile.state = "empty"
				gm.tile_updated.emit(pos, tile)
				
		var am = get_node_or_null("/root/AudioManager")
		var spawner = EffectSpawner.get_instance()
		if am: am.play_sfx("harvest")
		if spawner and gm:
			var world_pos = gm.grid_to_world(pos, true)
			spawner.spawn_harvest_effect(world_pos)
			if harvester_peer == get_local_peer_id():
				var dname = crop_id.replace("_", " ").capitalize()
				spawner.spawn_floating_text(world_pos, "✨ +%d %s" % [count, dname], Color(1.0, 0.9, 0.3))
				
	harvest_synced.emit(world_id, pos, crop_id, count)

@rpc("authority", "call_local", "reliable")
func broadcast_plant_growth(world_id: String, growth_list: Array) -> void:
	var wm = get_node_or_null("/root/WorldManager")
	var cur_world = wm.get_current_world() if wm else "farm"
	var tree = get_tree()
	var gm = tree.current_scene.find_child("GridManager", true, false) if (tree and tree.current_scene) else null
	
	for p_info in growth_list:
		var pos_arr = p_info.get("position", [0, 0])
		var pos = Vector2i(int(pos_arr[0]), int(pos_arr[1]))
		var plant_id = str(p_info.get("plant_id", ""))
		var stage = int(p_info.get("growth_stage", 0))
		var days = int(p_info.get("days_in_stage", 0))
		var watered = bool(p_info.get("watered_today", false))
		
		if wm:
			var state = wm.get_shared_world_state(world_id)
			state.add_or_update_plant(pos, plant_id, stage, days, watered)
			
		if cur_world == world_id and gm:
			var tile = gm.get_tile(pos)
			if tile:
				tile.plant_id = plant_id
				tile.growth_stage = stage
				tile.days_in_stage = days
				tile.watered_today = watered
				tile.state = "mature" if stage >= 2 else ("growing" if stage > 0 else "planted")
				gm._spawn_plant_instance(pos, plant_id, stage, days, watered)
				gm.tile_updated.emit(pos, tile)

@rpc("authority", "call_remote", "reliable")
func receive_world_snapshot(world_id: String, snapshot_plants: Array) -> void:
	print("[NetworkGameplay] Received authoritative world snapshot for %s (%d plants)" % [world_id, snapshot_plants.size()])
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		var state = wm.get_shared_world_state(world_id)
		state.plants.clear()
		for p in snapshot_plants:
			var pos_arr = p.get("position", [0, 0])
			var pos = Vector2i(int(pos_arr[0]), int(pos_arr[1]))
			state.add_or_update_plant(pos, str(p.get("plant_id", "")), int(p.get("growth_stage", 0)), int(p.get("days_in_stage", 0)), bool(p.get("watered_today", false)))
			
	var tree = get_tree()
	var gm = tree.current_scene.find_child("GridManager", true, false) if (tree and tree.current_scene) else null
	if gm and wm and wm.get_current_world() == world_id:
		var wl = get_node_or_null("/root/WorldLoader")
		if wl: wl._restore_world_runtime_state(world_id, gm)
		
	snapshot_applied.emit(world_id)

@rpc("authority", "call_remote", "reliable")
func notify_gameplay_error(reason: String) -> void:
	push_warning("[NetworkGameplay] Action rejected by host: %s" % reason)
	gameplay_error.emit(reason)
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner: spawner.spawn_floating_text(pos, "❌ %s" % reason, Color(1.0, 0.4, 0.4))

func _send_failure(peer_id: int, reason: String) -> void:
	if peer_id == 1 or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(peer_id):
		notify_gameplay_error(reason)
	else:
		rpc_id(peer_id, "notify_gameplay_error", reason)


# ==============================================================================
# OFFLINE SINGLE-PLAYER FALLBACKS
# ==============================================================================

func _execute_local_plant(world_id: String, pos: Vector2i, seed_id: String) -> void:
	var im = get_node_or_null("/root/InventoryManager")
	var wm = get_node_or_null("/root/WorldManager")
	var tree = get_tree()
	var gm = tree.current_scene.find_child("GridManager", true, false) if (tree and tree.current_scene) else null
	
	if not im or not gm or not im.has_item(seed_id, 1): return
	var plant_id = seed_id.trim_prefix("seed_")
	
	if im.remove_item(seed_id, 1):
		if gm.plant_seed(pos, plant_id):
			if wm:
				wm.get_shared_world_state(world_id).add_or_update_plant(pos, plant_id, 0, 0, false)
			var am = get_node_or_null("/root/AudioManager")
			var spawner = EffectSpawner.get_instance()
			if am: am.play_sfx("plant")
			if spawner:
				var world_pos = gm.grid_to_world(pos, true)
				spawner.spawn_planting_effect(world_pos)
				spawner.spawn_floating_text(world_pos, "🌱 Planted", Color(0.6, 1.0, 0.5))

func _execute_local_water(world_id: String, pos: Vector2i) -> void:
	var wm = get_node_or_null("/root/WorldManager")
	var tree = get_tree()
	var gm = tree.current_scene.find_child("GridManager", true, false) if (tree and tree.current_scene) else null
	if not gm: return
	
	if gm.water_tile(pos):
		if wm:
			var s = wm.get_shared_world_state(world_id)
			var p = s.get_plant(pos)
			if not p.is_empty():
				s.add_or_update_plant(pos, p.get("plant_id", ""), p.get("growth_stage", 0), p.get("days_in_stage", 0), true)
		var am = get_node_or_null("/root/AudioManager")
		var spawner = EffectSpawner.get_instance()
		if am: am.play_sfx("water")
		if spawner:
			var world_pos = gm.grid_to_world(pos, true)
			spawner.spawn_watering_effect(world_pos)
			spawner.spawn_floating_text(world_pos, "💧 Watered", Color(0.4, 0.8, 1.0))

func _execute_local_harvest(world_id: String, pos: Vector2i) -> void:
	var im = get_node_or_null("/root/InventoryManager")
	var wm = get_node_or_null("/root/WorldManager")
	var tree = get_tree()
	var gm = tree.current_scene.find_child("GridManager", true, false) if (tree and tree.current_scene) else null
	if not gm or not im: return
	
	if gm.is_tile_harvestable(pos):
		var res = gm.harvest_tile(pos)
		if not res.is_empty():
			var crop_id = res.get("item_id", "")
			var count = res.get("yield", 1)
			im.add_item(crop_id, count)
			if wm: wm.get_shared_world_state(world_id).remove_plant(pos)
			var am = get_node_or_null("/root/AudioManager")
			var spawner = EffectSpawner.get_instance()
			if am: am.play_sfx("harvest")
			if spawner:
				var world_pos = gm.grid_to_world(pos, true)
				spawner.spawn_harvest_effect(world_pos)
				var dname = crop_id.replace("_", " ").capitalize()
				spawner.spawn_floating_text(world_pos, "✨ +%d %s" % [count, dname], Color(1.0, 0.9, 0.3))

# ==============================================================================
# TIME & CLOCK SYNCHRONIZATION
# ==============================================================================

func broadcast_time_sync(day: int, time_minutes: float, phase: String) -> void:
	if is_offline(): return
	if is_host():
		rpc("client_receive_time_sync", day, time_minutes, phase)

@rpc("authority", "call_remote", "reliable")
func client_receive_time_sync(day: int, time_minutes: float, _phase: String) -> void:
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.current_day = day
		tm.current_time_minutes = time_minutes
		tm._update_phase(true)

func request_time_sync() -> void:
	if is_offline() or is_host(): return
	rpc_id(1, "host_request_time_sync", get_local_peer_id())

@rpc("any_peer", "call_remote", "reliable")
func host_request_time_sync(requester_peer: int) -> void:
	if not is_host(): return
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		rpc_id(requester_peer, "client_receive_time_sync", tm.current_day, tm.current_time_minutes, tm.current_day_phase)

