extends Node

## Host-authoritative Co-op Quest and Progression Network Synchronization Manager.
## Distinguishes between Personal Quests (PlayerState) and Shared Quests (SharedWorldState).
## Prevents duplicate reward claiming, race conditions, and handles late-join snapshots.

signal shared_quest_objective_updated(quest_id: String, objective_index: int, current: int, required: int)
signal shared_quest_completed(quest_id: String)
signal personal_quest_reward_received(quest_id: String, reward_summary: Dictionary)
signal shared_progression_updated(progression_dict: Dictionary)
signal quest_snapshot_applied()
signal quest_error(reason: String)

const MAX_OBJECTIVE_AMOUNT: int = 100

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

func request_advance_objective(obj_type: String, amount: int = 1, target_filter: String = "", context_id: String = "") -> void:
	if is_offline():
		_local_advance_objective(obj_type, amount, target_filter)
		return
	rpc("host_request_advance_objective", get_local_peer_id(), obj_type, amount, target_filter, context_id)

func request_claim_quest_reward(quest_id: String) -> void:
	if is_offline():
		_local_claim_quest_reward(quest_id)
		return
	rpc("host_request_claim_quest_reward", get_local_peer_id(), quest_id)

func request_quest_snapshot() -> void:
	if is_offline():
		return
	rpc("host_request_quest_snapshot", get_local_peer_id())

# ------------------------------------------------------------------------------
# HOST HELPERS
# ------------------------------------------------------------------------------

func _get_player_state(peer_id: int) -> PlayerState:
	var ng = get_node_or_null("/root/NetworkGameplay")
	return ng._get_player_state_for_peer(peer_id) if ng else null

func _get_world_state(world_id: String = "farm") -> SharedWorldState:
	var wm = get_node_or_null("/root/WorldManager")
	return wm.get_shared_world_state(world_id) if wm else null

func _send_error(peer_id: int, reason: String) -> void:
	if peer_id == 1 or is_offline() or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(peer_id):
		quest_error.emit(reason)
		var spawner = EffectSpawner.get_instance()
		var player = get_tree().root.find_child("Player", true, false)
		var pos = player.global_position if player else Vector2(240, 180)
		if spawner: spawner.spawn_floating_text(pos, "❌ " + reason, Color(1.0, 0.4, 0.4))
	else:
		rpc_id(peer_id, "client_receive_quest_error", reason)

# ------------------------------------------------------------------------------
# HOST REQUEST HANDLERS (RPC)
# ------------------------------------------------------------------------------

@rpc("any_peer", "call_local", "reliable")
func host_request_advance_objective(requester_peer: int, obj_type: String, amount: int, target_filter: String, _context_id: String) -> void:
	if not is_host(): return
	var p_state = _get_player_state(requester_peer)
	if not p_state:
		_send_error(requester_peer, "PLAYER_NOT_FOUND")
		return
		
	var qm = get_node_or_null("/root/QuestManager")
	if not qm: return
	
	var all_quests = qm.get_all_quests()
	
	for q in all_quests:
		var qid = str(q.get("id", ""))
		var is_shared = bool(q.get("scope", "personal") == "shared")
		var objectives = q.get("objectives", [])
		
		if is_shared:
			# Shared World Quest Tracking
			var farm_state = _get_world_state("farm")
			if not farm_state: continue
			
			if not farm_state.world_progression.has("quests"):
				farm_state.world_progression["quests"] = {}
			if not farm_state.world_progression["quests"].has(qid):
				var init_prog: Array = []
				for _obj in objectives: init_prog.append(0)
				farm_state.world_progression["quests"][qid] = { "status": "active", "progress": init_prog }
				
			var sq_state = farm_state.world_progression["quests"][qid]
			if str(sq_state.get("status", "")) != "active": continue
			
			var prog = sq_state.get("progress", [])
			var all_done = true
			
			for i in range(objectives.size()):
				var obj = objectives[i]
				var t = str(obj.get("type", ""))
				var tgt = str(obj.get("target", "any"))
				var req = int(obj.get("amount", 1))
				
				var matches_type = (t == obj_type) or (obj_type == "harvest" and t in ["harvest", "harvest_crop", "harvest_greenhouse"])
				var matches_target = (tgt == "any") or (target_filter == "" or target_filter == tgt or target_filter.contains(tgt))
				
				if matches_type and matches_target:
					var cur_val = int(prog[i]) if i < prog.size() else 0
					var next_val = mini(req, cur_val + amount)
					if next_val != cur_val:
						prog[i] = next_val
						rpc("broadcast_shared_quest_objective", qid, i, next_val, req)
						
				if int(prog[i]) < req: all_done = false
				
			if all_done:
				sq_state["status"] = "completed"
				rpc("broadcast_shared_quest_completed", qid)
		else:
			# Personal Quest Tracking on PlayerState
			if not p_state.personal_quests.has(qid):
				var unl = q.get("unlock", {})
				var init_st = "active" if unl.get("type", "") == "auto" else "locked"
				var init_p: Array = []
				for _obj in objectives: init_p.append(0)
				p_state.personal_quests[qid] = { "status": init_st, "progress": init_p }
				
			var pq = p_state.personal_quests[qid]
			if str(pq.get("status", "")) != "active": continue
			
			var prog = pq.get("progress", [])
			var all_done = true
			
			for i in range(objectives.size()):
				var obj = objectives[i]
				var t = str(obj.get("type", ""))
				var tgt = str(obj.get("target", "any"))
				var req = int(obj.get("amount", 1))
				
				var matches_type = (t == obj_type) or (obj_type == "harvest" and t in ["harvest", "harvest_crop", "harvest_greenhouse"])
				var matches_target = (tgt == "any") or (target_filter == "" or target_filter == tgt or target_filter.contains(tgt))
				
				if matches_type and matches_target:
					var cur_val = int(prog[i]) if i < prog.size() else 0
					var next_val = mini(req, cur_val + amount)
					if next_val != cur_val:
						prog[i] = next_val
						if requester_peer == 1:
							qm.advance_objective(p_state.player_id, obj_type, amount, target_filter)
						
				if int(prog[i]) < req: all_done = false
				
			if all_done:
				pq["status"] = "completed"
				if requester_peer == 1:
					qm.complete_quest(p_state.player_id, qid)

@rpc("any_peer", "call_local", "reliable")
func host_request_claim_quest_reward(requester_peer: int, quest_id: String) -> void:
	if not is_host(): return
	var p_state = _get_player_state(requester_peer)
	if not p_state:
		_send_error(requester_peer, "PLAYER_NOT_FOUND")
		return
		
	var qm = get_node_or_null("/root/QuestManager")
	var q = qm.get_quest(quest_id) if qm else {}
	if q.is_empty():
		_send_error(requester_peer, "QUEST_NOT_FOUND")
		return
		
	# Check duplicate claim
	if p_state.has_claimed_reward(quest_id):
		_send_error(requester_peer, "REWARD_ALREADY_CLAIMED")
		return
		
	var is_shared = bool(q.get("scope", "personal") == "shared")
	
	# Verify status
	if is_shared:
		var farm_state = _get_world_state("farm")
		var sq_info = farm_state.world_progression.get("quests", {}).get(quest_id, {})
		if str(sq_info.get("status", "")) not in ["completed", "claimed"]:
			_send_error(requester_peer, "QUEST_NOT_COMPLETED")
			return
	else:
		var pq_info = p_state.personal_quests.get(quest_id, {})
		var st = str(pq_info.get("status", qm.get_quest_status(p_state.player_id if requester_peer != 1 else "player_001", quest_id) if requester_peer == 1 else "locked"))
		if st not in ["completed", "claimed"]:
			_send_error(requester_peer, "QUEST_NOT_COMPLETED")
			return
			
	# Mark claimed on PlayerState
	p_state.mark_reward_claimed(quest_id)
	if p_state.personal_quests.has(quest_id):
		p_state.personal_quests[quest_id]["status"] = "claimed"
		
	var rewards = q.get("rewards", {})
	var granted = RewardManager.grant_rewards(rewards, p_state)
	
	# Check if reward unlocks dependent quests
	_unlock_dependent_quests_for_player(p_state, quest_id)
	
	# Handle shared unlocks if specified
	var unlock_world_id = str(rewards.get("world_unlock", rewards.get("unlock_world", "")))
	if unlock_world_id != "":
		var pm = get_node_or_null("/root/ProgressionManager")
		if pm: pm.unlock_world(unlock_world_id, true)
		
	var summary = {
		"quest_id": quest_id,
		"rewards": granted,
		"title": str(q.get("title", "Quest"))
	}
	
	if requester_peer == 1:
		receive_quest_reward(quest_id, summary)
	elif multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(requester_peer):
		rpc_id(requester_peer, "receive_quest_reward", quest_id, summary)

func _unlock_dependent_quests_for_player(p_state: PlayerState, completed_qid: String) -> void:
	var qm = get_node_or_null("/root/QuestManager")
	if not qm: return
	for q in qm.get_all_quests():
		var qid = str(q.get("id", ""))
		var unl = q.get("unlock", {})
		if unl.get("type", "") == "quest_completed" and unl.get("quest_id", "") == completed_qid:
			if not p_state.personal_quests.has(qid):
				var prog: Array = []
				for _obj in q.get("objectives", []): prog.append(0)
				p_state.personal_quests[qid] = { "status": "active", "progress": prog }
			else:
				if p_state.personal_quests[qid]["status"] == "locked":
					p_state.personal_quests[qid]["status"] = "active"

@rpc("any_peer", "call_local", "reliable")
func host_request_quest_snapshot(requester_peer: int) -> void:
	if not is_host(): return
	var farm_state = _get_world_state("farm")
	var pm = get_node_or_null("/root/ProgressionManager")
	
	var snap = {
		"shared_quests": farm_state.world_progression.get("quests", {}) if farm_state else {},
		"unlocked_worlds": pm.unlocked_worlds.duplicate(true) if pm else { "farm": true, "town": true },
		"shared_events": farm_state.shared_events.duplicate(true) if farm_state else {}
	}
	
	if requester_peer == 1:
		receive_quest_snapshot(snap)
	elif multiplayer.has_multiplayer_peer() and multiplayer.get_peers().has(requester_peer):
		rpc_id(requester_peer, "receive_quest_snapshot", snap)

# ------------------------------------------------------------------------------
# BROADCAST RPC RECEIVERS (ALL PEERS)
# ------------------------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func broadcast_shared_quest_objective(quest_id: String, obj_index: int, current: int, required: int) -> void:
	var farm_state = _get_world_state("farm")
	if farm_state:
		if not farm_state.world_progression.has("quests"):
			farm_state.world_progression["quests"] = {}
		if not farm_state.world_progression["quests"].has(quest_id):
			farm_state.world_progression["quests"][quest_id] = { "status": "active", "progress": [] }
		var p_arr = farm_state.world_progression["quests"][quest_id].get("progress", [])
		while p_arr.size() <= obj_index: p_arr.append(0)
		p_arr[obj_index] = current
		farm_state.world_progression["quests"][quest_id]["progress"] = p_arr
		
	var qm = get_node_or_null("/root/QuestManager")
	if qm: qm.quest_objective_updated.emit(quest_id, current, required)
	shared_quest_objective_updated.emit(quest_id, obj_index, current, required)

@rpc("authority", "call_local", "reliable")
func broadcast_shared_quest_completed(quest_id: String) -> void:
	var farm_state = _get_world_state("farm")
	if farm_state:
		if not farm_state.world_progression.has("quests"):
			farm_state.world_progression["quests"] = {}
		if not farm_state.world_progression["quests"].has(quest_id):
			farm_state.world_progression["quests"][quest_id] = { "status": "completed", "progress": [] }
		farm_state.world_progression["quests"][quest_id]["status"] = "completed"
		
	var qm = get_node_or_null("/root/QuestManager")
	if qm:
		if qm.quest_states.has(quest_id):
			qm.quest_states[quest_id]["status"] = "completed"
		qm.quest_status_changed.emit(quest_id, "completed")
		EventBus.quest_completed.emit("", quest_id)
		
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("quest_complete")
	
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		spawner.spawn_floating_text(pos, "🌟 CO-OP QUEST COMPLETED: " + quest_id.capitalize() + "!", Color(0.3, 1.0, 0.4))
		
	shared_quest_completed.emit(quest_id)

@rpc("authority", "call_local", "reliable")
func broadcast_shared_progression(progression_dict: Dictionary) -> void:
	var farm_state = _get_world_state("farm")
	if farm_state:
		for k in progression_dict.keys():
			farm_state.world_progression[k] = progression_dict[k]
	shared_progression_updated.emit(progression_dict)

# ------------------------------------------------------------------------------
# CLIENT RPC RECEIVERS (INDIVIDUAL CLIENTS)
# ------------------------------------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func receive_quest_reward(quest_id: String, reward_summary: Dictionary) -> void:
	var qm = get_node_or_null("/root/QuestManager")
	if qm:
		if qm.quest_states.has(quest_id):
			qm.quest_states[quest_id]["status"] = "claimed"
		qm.quest_status_changed.emit(quest_id, "claimed")
		qm.quest_reward_claimed.emit(quest_id, reward_summary.get("rewards", {}))
		EventBus.quest_claimed.emit("", quest_id)
		
	var psm = get_node_or_null("/root/PlayerRegistry")
	var peer_id = multiplayer.get_remote_sender_id()
	var p_state = _get_player_state(peer_id)
	if p_state:
		p_state.mark_reward_claimed(quest_id)
		
	personal_quest_reward_received.emit(quest_id, reward_summary)

@rpc("authority", "call_remote", "reliable")
func receive_quest_snapshot(snapshot: Dictionary) -> void:
	print("[NetworkQuests] Applying authoritative quest & progression snapshot...")
	var farm_state = _get_world_state("farm")
	if farm_state:
		var sq = snapshot.get("shared_quests", {})
		if not farm_state.world_progression.has("quests"):
			farm_state.world_progression["quests"] = {}
		for qid in sq.keys():
			farm_state.world_progression["quests"][qid] = sq[qid]
			
		var events = snapshot.get("shared_events", {})
		for eid in events.keys():
			farm_state.shared_events[eid] = events[eid]
			
	var unl_worlds = snapshot.get("unlocked_worlds", {})
	var pm = get_node_or_null("/root/ProgressionManager")
	if pm:
		for wid in unl_worlds.keys():
			if unl_worlds[wid]: pm.unlock_world(wid, false)
			
	quest_snapshot_applied.emit()

@rpc("authority", "call_remote", "reliable")
func client_receive_quest_error(reason: String) -> void:
	_send_error(1, reason)

# ------------------------------------------------------------------------------
# OFFLINE SINGLEPLAYER FALLBACKS
# ------------------------------------------------------------------------------

func _local_advance_objective(obj_type: String, amount: int, target_filter: String) -> void:
	var qm = get_node_or_null("/root/QuestManager")
	if qm: qm.advance_objective(p_state.player_id, obj_type, amount, target_filter)

func _local_claim_quest_reward(quest_id: String) -> void:
	var qm = get_node_or_null("/root/QuestManager")
	if qm: qm.claim_reward(p_state.player_id, quest_id)
