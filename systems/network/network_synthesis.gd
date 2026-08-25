extends Node
## Host-authoritative synthesis (combination) synchronization.
## Synthesis result is PLAYER-OWNED (inventory). Formula discovery is SHARED-WORLD.
## Two players can use the lab concurrently; each gets their own result.

signal synthesis_completed(combo_id: String, output_item: String, is_new_discovery: bool)
signal formula_discovered_shared(world_id: String, combo_id: String, output_item: String)
signal synthesis_error(reason: String)

func is_host() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_host() if nm else true

func is_offline() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_offline() if nm else true

func get_local_peer_id() -> int:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.get_local_peer_id() if nm else 1

# ---------------------------------------------------------------
# CLIENT API
# ---------------------------------------------------------------

func request_synthesis(world_id: String, input_a: String, input_b: String) -> void:
	if is_offline():
		_local_synthesis(world_id, input_a, input_b)
		return
	rpc("host_synthesis", get_local_peer_id(), world_id, input_a, input_b)

# ---------------------------------------------------------------
# HOST HELPERS
# ---------------------------------------------------------------

func _get_world_state(world_id: String) -> SharedWorldState:
	var wm = get_node_or_null("/root/WorldManager")
	return wm.get_shared_world_state(world_id) if wm else null

func _get_player_state(peer_id: int) -> PlayerState:
	var ng = get_node_or_null("/root/NetworkGameplay")
	return ng._get_player_state_for_peer(peer_id) if ng else null

func _send_error(peer_id: int, reason: String) -> void:
	if peer_id == 1 or is_offline() or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(peer_id):
		synthesis_error.emit(reason)
		var spawner = EffectSpawner.get_instance()
		var player = get_tree().root.find_child("Player", true, false)
		var pos2 = player.global_position if player else Vector2(240, 180)
		if spawner: spawner.spawn_floating_text(pos2, "❌ %s" % reason, Color(1.0, 0.4, 0.4))
	else:
		rpc_id(peer_id, "client_receive_synthesis_error", reason)

# ---------------------------------------------------------------
# HOST RPC HANDLER
# ---------------------------------------------------------------

@rpc("any_peer", "call_local", "reliable")
func host_synthesis(requester_peer: int, world_id: String, input_a: String, input_b: String) -> void:
	if not is_host(): return
	var player_state = _get_player_state(requester_peer)
	if not player_state:
		_send_error(requester_peer, "INVALID_PLAYER")
		return
	

		
	var owner_id = ""
	var parts = world_id.split(":")
	if parts.size() > 1:
		owner_id = parts[1]
		
	if owner_id != "" and player_state.player_id != owner_id:
		_send_error(requester_peer, "ACCESS_DENIED")
		return
	
	var ws = _get_world_state(world_id)
	if not ws:
		_send_error(requester_peer, "INVALID_WORLD")
		return
	

	
	# Look up formula
	var cm = get_node_or_null("/root/CombinationManager")
	if not cm:
		_send_error(requester_peer, "SYSTEM_ERROR")
		return
	
	var combo = cm.get_combination(input_a, input_b)
	if combo.is_empty():
		_send_error(requester_peer, "NO_FORMULA_FOUND")
		return
	
	# Ingredient check (on player state)
	var norm_a = input_a.trim_prefix("seed_")
	var norm_b = input_b.trim_prefix("seed_")
	if norm_a == norm_b:
		if not player_state.has_item(input_a, 2):
			_send_error(requester_peer, "NOT_ENOUGH_ITEMS")
			return
	else:
		if not player_state.has_item(input_a, 1) or not player_state.has_item(input_b, 1):
			_send_error(requester_peer, "NOT_ENOUGH_ITEMS")
			return
	
	# Atomic: deduct ingredients, add output
	var output_id = str(combo.get("output", ""))
	var combo_id = str(combo.get("id", ""))
	
	var prof_a = _get_or_create_profile(player_state, input_a)
	var prof_b = _get_or_create_profile(player_state, input_b)
	var engine = GeneticsEngine.new()
	var offspring = engine.breed(prof_a, prof_b)
	
	player_state.remove_item(input_a, 1)
	player_state.remove_item(input_b, 1)
	player_state.add_item(output_id, 1)
	player_state.add_item("seed_" + output_id, 1, offspring)
	
	# Check if new discovery for SharedWorldState
	var is_new = not ws.is_combination_discovered(combo_id)
	if is_new:
		ws.register_discovery(combo_id, output_id)
		# Broadcast discovery to all peers so Journal updates
		rpc("client_receive_formula_discovery", world_id, combo_id, output_id)
	
	# Send result only to requester
	if requester_peer == 1 or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(requester_peer):
		client_receive_synthesis_result(combo_id, output_id, is_new)
	else:
		rpc_id(requester_peer, "client_receive_synthesis_result", combo_id, output_id, is_new)
	
	print("[NetSynthesis] Peer %d synthesized %s + %s -> %s (new=%s)" % [requester_peer, input_a, input_b, output_id, is_new])

# ---------------------------------------------------------------
# CLIENT RECEIVERS
# ---------------------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func client_receive_synthesis_result(combo_id: String, output_item: String, is_new_discovery: bool) -> void:
	synthesis_completed.emit(combo_id, output_item, is_new_discovery)
	EventBus.synthesis_performed.emit("", combo_id, output_item, 1)
	EventBus.plant_combined.emit("", combo_id, output_item, output_item)

	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("discovery" if is_new_discovery else "plant")
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos2 = player.global_position if player else Vector2(240, 180)
	var dname = output_item.replace("_", " ").capitalize()
	var msg = "✨ Discovered: %s!" % dname if is_new_discovery else "🧪 +%s" % dname
	if spawner: spawner.spawn_floating_text(pos2, msg, Color(0.7, 0.4, 1.0) if is_new_discovery else Color(0.6, 1.0, 0.8))

@rpc("authority", "call_local", "reliable")
func client_receive_formula_discovery(world_id: String, combo_id: String, output_item: String) -> void:
	var ws = _get_world_state(world_id)
	if ws: ws.register_discovery(combo_id, output_item)
	# Update Journal for all players in this world
	var jm = get_node_or_null("/root/JournalManager")
	if jm and jm.has_method("on_plant_discovered"):
		jm.on_plant_discovered(output_item)
	formula_discovered_shared.emit(world_id, combo_id, output_item)

@rpc("authority", "call_remote", "reliable")
func client_receive_synthesis_error(reason: String) -> void:
	synthesis_error.emit(reason)
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos2 = player.global_position if player else Vector2(240, 180)
	if spawner: spawner.spawn_floating_text(pos2, "❌ %s" % reason, Color(1.0, 0.4, 0.4))

# ---------------------------------------------------------------
# OFFLINE FALLBACK
# ---------------------------------------------------------------

func _local_synthesis(world_id: String, input_a: String, input_b: String) -> void:
	# Offline: delegate to CombinationManager directly (existing single-player logic)
	var cm = get_node_or_null("/root/CombinationManager")
	if not cm: return
	var result = cm.perform_combination(input_a, input_b)
	if result.get("success", false):
		synthesis_completed.emit(result.get("combo_id", ""), result.get("output", ""), result.get("is_new_discovery", false))
	else:
		synthesis_error.emit(result.get("error", "Synthesis failed"))

func _get_or_create_profile(player_state: PlayerState, compound_key: String) -> GeneticProfile:
	var h = PlayerState.get_genetic_hash(compound_key)
	if h != "" and player_state.genetic_instances.has(h):
		return GeneticProfile.from_dict(player_state.genetic_instances[h])
	
	var base_id = PlayerState.get_base_item_id(compound_key)
	var crop_id = base_id.trim_prefix("seed_")
	
	var pm = get_node_or_null("/root/PlantManager")
	var data = pm.get_plant_data(crop_id) if pm else {}
	
	var profile = GeneticProfile.new()
	profile.size = str(data.get("size", "medium"))
	profile.color = str(data.get("color", "white"))
	profile.shape = str(data.get("shape", "flower"))
	profile.productivity = int(data.get("productivity", 1))
	profile.taste_profile = Array(data.get("taste_profile", ["sweet"]), TYPE_STRING, "", null)
	profile.water_required = bool(data.get("water_required", false))
	profile.growth_speed = str(data.get("growth_speed", "medium"))
	
	return profile
