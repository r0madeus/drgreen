extends Node

## Host-authoritative NPC, Dialogue Actions & Shared World Events Synchronization Manager.
##
## Separates:
## - Shared World State (NPC presence, positions, schedules, shared world progression/events)
## - Player State (personal friendship, personal dialogue progression/choices, personal quest rewards)
## Dialogue UI remains strictly local to the interacting client.

signal npc_interacted(world_id: String, npc_id: String, peer_id: int)
signal npc_moved(world_id: String, npc_id: String, pos: Vector2i)
signal npc_schedule_changed(world_id: String, npc_id: String, schedule_state: String, target_world: String, target_pos: Vector2i)
signal shared_npc_event_applied(world_id: String, event_id: String, event_data: Dictionary)
signal personal_reward_received(reward_data: Dictionary)
signal npc_snapshot_applied(world_id: String)
signal npc_error(reason: String)

const MAX_INTERACTION_DISTANCE_SQ: float = 36.0 # Max ~6 tiles range

func is_host() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_host() if nm else true

func is_offline() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_offline() if nm else true

func get_local_peer_id() -> int:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.get_local_peer_id() if nm else 1

# ------------------------------------------------------------------------------
# CLIENT REQUEST APIS
# ------------------------------------------------------------------------------

func request_npc_interaction(world_id: String, npc_id: String) -> void:
	if is_offline():
		_local_interact_npc(world_id, npc_id)
		return
	rpc("host_request_interaction", get_local_peer_id(), world_id, npc_id)

func request_dialogue_action(world_id: String, npc_id: String, action_id: String, action_params: Dictionary = {}) -> void:
	if is_offline():
		_local_dialogue_action(world_id, npc_id, action_id, action_params)
		return
	rpc("host_request_dialogue_action", get_local_peer_id(), world_id, npc_id, action_id, action_params)

func request_npc_event(world_id: String, event_id: String, event_data: Dictionary = {}) -> void:
	if is_offline():
		_local_npc_event(world_id, event_id, event_data)
		return
	rpc("host_request_npc_event", get_local_peer_id(), world_id, event_id, event_data)

func request_npc_snapshot(world_id: String) -> void:
	if is_offline(): return
	rpc("host_request_npc_snapshot", get_local_peer_id(), world_id)

func broadcast_npc_movement(world_id: String, npc_id: String, new_pos: Vector2i) -> void:
	if is_offline():
		_local_move_npc(world_id, npc_id, new_pos)
		return
	if is_host():
		var wm = get_node_or_null("/root/WorldManager")
		if wm:
			wm.get_shared_world_state(world_id).set_npc_position(npc_id, world_id, new_pos)
		rpc("broadcast_npc_moved", world_id, npc_id, new_pos.x, new_pos.y)

# ------------------------------------------------------------------------------
# HOST REQUEST HANDLERS (RPC)
# ------------------------------------------------------------------------------

func _get_player_state(peer_id: int) -> PlayerState:
	var ng = get_node_or_null("/root/NetworkGameplay")
	return ng._get_player_state_for_peer(peer_id) if ng else null

func _get_world_state(world_id: String) -> SharedWorldState:
	var wm = get_node_or_null("/root/WorldManager")
	return wm.get_shared_world_state(world_id) if wm else null

func _send_error(peer_id: int, reason: String) -> void:
	if peer_id == 1 or is_offline() or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(peer_id):
		npc_error.emit(reason)
		var spawner = EffectSpawner.get_instance()
		var player = get_tree().root.find_child("Player", true, false)
		var pos = player.global_position if player else Vector2(240, 180)
		if spawner: spawner.spawn_floating_text(pos, "❌ " + reason, Color(1.0, 0.4, 0.4))
	else:
		rpc_id(peer_id, "client_receive_npc_error", reason)

@rpc("any_peer", "call_local", "reliable")
func host_request_interaction(requester_peer: int, world_id: String, npc_id: String) -> void:
	if not is_host(): return
	var p_state = _get_player_state(requester_peer)
	if not p_state:
		_send_error(requester_peer, "PLAYER_NOT_FOUND")
		return
		
	var nm_mgr = get_node_or_null("/root/NPCManager")
	var npc_data = nm_mgr.get_npc_data(npc_id) if nm_mgr else {}
	if npc_data.is_empty():
		_send_error(requester_peer, "NPC_NOT_FOUND")
		return
		
	# Increase friendship on interaction
	p_state.add_friendship(npc_id, 5)
	EventBus.friendship_changed.emit(player_id, npc_id, p_state.get_friendship(npc_id))
	
	if requester_peer == 1:
		client_confirm_interaction(world_id, npc_id, npc_data)
	elif multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(requester_peer):
		rpc_id(requester_peer, "client_confirm_interaction", world_id, npc_id, npc_data)

@rpc("any_peer", "call_local", "reliable")
func host_request_dialogue_action(requester_peer: int, world_id: String, npc_id: String, action_id: String, action_params: Dictionary) -> void:
	if not is_host(): return
	var p_state = _get_player_state(requester_peer)
	var w_state = _get_world_state(world_id)
	if not p_state or not w_state: return
	
	EventBus.dialogue_action_executed.emit("", npc_id, action_id, action_params)
	
	match action_id:
		"open_shop":
			var shop_id = str(action_params.get("shop_id", ""))
			if shop_id == "":
				var nm_mgr = get_node_or_null("/root/NPCManager")
				var ndata = nm_mgr.get_npc_data(npc_id) if nm_mgr else {}
				shop_id = str(ndata.get("shop_id", ""))
			if requester_peer == 1:
				client_receive_open_shop(shop_id)
			elif multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(requester_peer):
				rpc_id(requester_peer, "client_receive_open_shop", shop_id)
				
		"personal_reward":
			var reward_id = str(action_params.get("reward_id", "dialogue_reward_" + npc_id))
			if p_state.has_claimed_reward(reward_id):
				_send_error(requester_peer, "REWARD_ALREADY_CLAIMED")
				return
			p_state.mark_reward_claimed(reward_id)
			var gold_amt = int(action_params.get("gold", 0))
			if gold_amt > 0: p_state.add_gold(gold_amt)
			var items = action_params.get("items", [])
			for itm in items:
				p_state.add_item(str(itm.get("item_id", "")), int(itm.get("count", 1)))
			p_state.add_friendship(npc_id, int(action_params.get("friendship", 10)))
			EventBus.friendship_changed.emit(player_id, npc_id, p_state.get_friendship(npc_id))
			
			var reward_summary = { "reward_id": reward_id, "gold": gold_amt, "items": items, "npc_id": npc_id }
			if requester_peer == 1:
				receive_personal_reward(reward_summary)
			elif multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(requester_peer):
				rpc_id(requester_peer, "receive_personal_reward", reward_summary)
				
		"shared_event", "world_event":
			var event_id = str(action_params.get("event_id", ""))
			if event_id == "": return
			if w_state.is_event_applied(event_id):
				_send_error(requester_peer, "EVENT_ALREADY_APPLIED")
				return
			w_state.apply_event(event_id, action_params)
			_execute_shared_event_consequences(world_id, event_id, action_params)
			EventBus.shared_event_triggered.emit(event_id, action_params)
			rpc("broadcast_shared_npc_event", world_id, event_id, action_params)

			
		"unlock_world":
			var target_world_id = str(action_params.get("target_world", ""))
			var event_id = "unlock_world:" + target_world_id
			if w_state.is_event_applied(event_id):
				_send_error(requester_peer, "ALREADY_UNLOCKED")
				return
			w_state.apply_event(event_id, action_params)
			var pm = get_node_or_null("/root/ProgressionManager")
			if pm: pm.unlock_world(target_world_id, true)
			rpc("broadcast_shared_npc_event", world_id, event_id, action_params)

@rpc("any_peer", "call_local", "reliable")
func host_request_npc_event(requester_peer: int, world_id: String, event_id: String, event_data: Dictionary) -> void:
	if not is_host(): return
	var w_state = _get_world_state(world_id)
	if not w_state: return
	
	if w_state.is_event_applied(event_id):
		_send_error(requester_peer, "EVENT_ALREADY_APPLIED")
		return
		
	w_state.apply_event(event_id, event_data)
	_execute_shared_event_consequences(world_id, event_id, event_data)
	rpc("broadcast_shared_npc_event", world_id, event_id, event_data)

func _execute_shared_event_consequences(world_id: String, event_id: String, event_data: Dictionary) -> void:
	if event_id.contains("unlock_greenhouse") or event_id.contains("repair_greenhouse"):
		var stage = int(event_data.get("stage", 1))
		var gh = get_node_or_null("/root/GreenhouseManager")
		if gh and gh.has_method("repair_stage"): gh.repair_stage(stage)
	elif event_id.contains("unlock_world") or event_data.has("unlock_world"):
		var wid = str(event_data.get("unlock_world", event_data.get("target_world", "")))
		var pm = get_node_or_null("/root/ProgressionManager")
		if pm and wid != "": pm.unlock_world(wid, true)

@rpc("any_peer", "call_local", "reliable")
func host_request_npc_snapshot(requester_peer: int, world_id: String) -> void:
	if not is_host(): return
	var w_state = _get_world_state(world_id)
	if not w_state: return
	
	var snap = {
		"world_id": world_id,
		"npc_positions": w_state.get_all_npc_positions(),
		"shared_events": w_state.shared_events.duplicate(true)
	}
	
	if requester_peer == 1:
		receive_npc_snapshot(world_id, snap)
	elif multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(requester_peer):
		rpc_id(requester_peer, "receive_npc_snapshot", world_id, snap)


# ------------------------------------------------------------------------------
# BROADCAST RPC RECEIVERS (EXECUTED ON ALL PEERS)
# ------------------------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func broadcast_npc_moved(world_id: String, npc_id: String, pos_x: int, pos_y: int) -> void:
	var pos = Vector2i(pos_x, pos_y)
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		wm.get_shared_world_state(world_id).set_npc_position(npc_id, world_id, pos)
		
	var cur_w = wm.get_current_world() if wm else "farm"
	if cur_w == world_id:
		var nm_mgr = get_node_or_null("/root/NPCManager")
		var inst = nm_mgr.get_active_npc_instance(npc_id) if nm_mgr else null
		if inst and is_instance_valid(inst):
			inst.grid_position = pos
			if inst.has_method("_update_position_from_grid"):
				inst._update_position_from_grid()
			elif inst.has_method("_update_position"):
				inst._update_position()

			
	npc_moved.emit(world_id, npc_id, pos)

@rpc("authority", "call_local", "reliable")
func broadcast_npc_schedule(world_id: String, npc_id: String, schedule_state: String, target_world: String, target_pos_arr: Array) -> void:
	var pos = Vector2i(int(target_pos_arr[0]), int(target_pos_arr[1]))
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		wm.get_shared_world_state(target_world).set_npc_position(npc_id, target_world, pos, schedule_state)
		
	var cur_w = wm.get_current_world() if wm else "farm"
	var nm_mgr = get_node_or_null("/root/NPCManager")
	if nm_mgr:
		nm_mgr.spawn_npcs_for_world(cur_w)
		
	npc_schedule_changed.emit(world_id, npc_id, schedule_state, target_world, pos)

@rpc("authority", "call_local", "reliable")
func broadcast_shared_npc_event(world_id: String, event_id: String, event_data: Dictionary) -> void:
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		wm.get_shared_world_state(world_id).apply_event(event_id, event_data)
	_execute_shared_event_consequences(world_id, event_id, event_data)
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("quest_complete")
	
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		var banner_txt = str(event_data.get("banner_text", "🌟 WORLD EVENT: " + event_id.replace(":", " ").capitalize()))
		spawner.spawn_floating_text(pos, banner_txt, Color(1.0, 0.8, 0.2))
		
	shared_npc_event_applied.emit(world_id, event_id, event_data)

@rpc("authority", "call_remote", "reliable")
func receive_npc_snapshot(world_id: String, snapshot: Dictionary) -> void:
	print("[NetworkNPC] Received authoritative NPC snapshot for " + world_id)
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		var state = wm.get_shared_world_state(world_id)
		var positions = snapshot.get("npc_positions", {})
		for nid in positions.keys():
			var pinfo = positions[nid]
			var pos_arr = pinfo.get("position", [0, 0])
			state.set_npc_position(nid, str(pinfo.get("world_id", world_id)), Vector2i(int(pos_arr[0]), int(pos_arr[1])), str(pinfo.get("schedule_state", "default")))
		var events = snapshot.get("shared_events", {})
		for eid in events.keys():
			state.shared_events[eid] = events[eid]
			
	var cur_w = wm.get_current_world() if wm else "farm"
	if cur_w == world_id:
		var nm_mgr = get_node_or_null("/root/NPCManager")
		if nm_mgr: nm_mgr.spawn_npcs_for_world(cur_w)
		
	npc_snapshot_applied.emit(world_id)

@rpc("authority", "call_local", "reliable")
func receive_personal_reward(reward_summary: Dictionary) -> void:
	var psm = get_node_or_null("/root/PlayerRegistry")
	var peer_id = multiplayer.get_remote_sender_id()
	var p_state = _get_player_state(peer_id)
	if p_state:
		var rid = str(reward_summary.get("reward_id", ""))
		if rid != "": p_state.mark_reward_claimed(rid)
		
	# UI Feedback
	var gold = int(reward_summary.get("gold", 0))
	var items = reward_summary.get("items", [])
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		var txt = "🎁 PERSONAL REWARD!"
		if gold > 0: txt += "\n+ " + str(gold) + " Gold"
		for itm in items:
			var dname = str(itm.get("item_id", "")).replace("_", " ").capitalize()
			txt += "\n+ " + str(int(itm.get("count", 1))) + " " + dname
		spawner.spawn_floating_text(pos, txt, Color(1.0, 0.9, 0.2))
		
	personal_reward_received.emit(reward_summary)

@rpc("authority", "call_remote", "reliable")
func client_confirm_interaction(world_id: String, npc_id: String, npc_data: Dictionary) -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		var did = str(npc_data.get("dialogue_id", npc_id))
		var dname = str(npc_data.get("display_name", npc_id.capitalize()))
		dm.start_dialogue(did, dname, npc_id)
	npc_interacted.emit(world_id, npc_id, get_local_peer_id())

@rpc("authority", "call_remote", "reliable")
func client_receive_open_shop(shop_id: String) -> void:
	var shop = get_tree().root.find_child("ShopUI", true, false)
	if shop:
		if shop_id != "" and shop.has_method("set_shop_id"):
			shop.set_shop_id(shop_id)
		shop.open_shop()

@rpc("authority", "call_remote", "reliable")
func client_receive_npc_error(reason: String) -> void:
	_send_error(1, reason)

# ------------------------------------------------------------------------------
# OFFLINE SINGLE-PLAYER FALLBACKS
# ------------------------------------------------------------------------------

func _local_interact_npc(world_id: String, npc_id: String) -> void:
	var nm_mgr = get_node_or_null("/root/NPCManager")
	var ndata = nm_mgr.get_npc_data(npc_id) if nm_mgr else {}
	var psm = get_node_or_null("/root/PlayerRegistry")
	var peer_id = multiplayer.get_remote_sender_id()
	var p_state = _get_player_state(peer_id)
	if p_state: p_state.add_friendship(npc_id, 5)
	
	client_confirm_interaction(world_id, npc_id, ndata)

func _local_dialogue_action(world_id: String, npc_id: String, action_id: String, action_params: Dictionary) -> void:
	var psm = get_node_or_null("/root/PlayerRegistry")
	var peer_id = multiplayer.get_remote_sender_id()
	var p_state = _get_player_state(peer_id)
	var wm = get_node_or_null("/root/WorldManager")
	var w_state = wm.get_shared_world_state(world_id) if wm else null
	
	match action_id:
		"open_shop":
			var shop_id = str(action_params.get("shop_id", ""))
			client_receive_open_shop(shop_id)
		"personal_reward":
			if p_state:
				var reward_id = str(action_params.get("reward_id", "dialogue_reward_" + npc_id))
				if not p_state.has_claimed_reward(reward_id):
					p_state.mark_reward_claimed(reward_id)
					var gold_amt = int(action_params.get("gold", 0))
					if gold_amt > 0: p_state.add_gold(gold_amt)
					var items = action_params.get("items", [])
					for itm in items:
						p_state.add_item(str(itm.get("item_id", "")), int(itm.get("count", 1)))
					p_state.add_friendship(npc_id, int(action_params.get("friendship", 10)))
					receive_personal_reward({ "reward_id": reward_id, "gold": gold_amt, "items": items })
		"shared_event", "world_event":
			var event_id = str(action_params.get("event_id", ""))
			if w_state and not w_state.is_event_applied(event_id):
				w_state.apply_event(event_id, action_params)
				_execute_shared_event_consequences(world_id, event_id, action_params)
				shared_npc_event_applied.emit(world_id, event_id, action_params)
		"unlock_world":
			var wid = str(action_params.get("target_world", ""))
			var event_id = "unlock_world:" + wid
			if w_state and not w_state.is_event_applied(event_id):
				w_state.apply_event(event_id, action_params)
				var pm = get_node_or_null("/root/ProgressionManager")
				if pm: pm.unlock_world(wid, true)

func _local_npc_event(world_id: String, event_id: String, event_data: Dictionary) -> void:
	var wm = get_node_or_null("/root/WorldManager")
	var w_state = wm.get_shared_world_state(world_id) if wm else null
	if w_state and not w_state.is_event_applied(event_id):
		w_state.apply_event(event_id, event_data)
		_execute_shared_event_consequences(world_id, event_id, event_data)
		shared_npc_event_applied.emit(world_id, event_id, event_data)

func _local_move_npc(world_id: String, npc_id: String, pos: Vector2i) -> void:
	var wm = get_node_or_null("/root/WorldManager")
	if wm: wm.get_shared_world_state(world_id).set_npc_position(npc_id, world_id, pos)
	var nm_mgr = get_node_or_null("/root/NPCManager")
	var inst = nm_mgr.get_active_npc_instance(npc_id) if nm_mgr else null
	if inst and is_instance_valid(inst):
		inst.grid_position = pos
		inst._update_position()
	npc_moved.emit(world_id, npc_id, pos)
