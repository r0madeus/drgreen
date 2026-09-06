extends Node

## Central Quest and Progression manager tracking objectives, progression and rewards.

signal quest_status_changed(quest_id: String, new_status: String)
signal quest_objective_updated(quest_id: String, current: int, total: int)
signal quest_reward_claimed(quest_id: String, rewards: Dictionary)

const STATUS_LOCKED = "locked"
const STATUS_ACTIVE = "active"
const STATUS_COMPLETED = "completed"
const STATUS_CLAIMED = "claimed"

var quests: Array[Dictionary] = []

func _get_default_or_local_player_id() -> String:
	var psm = get_node_or_null("/root/PlayerRegistry")
	if psm and "local_player_id" in psm and psm.local_player_id != "":
		return psm.local_player_id
	return "player_001"

func _get_player_state(player_id: String) -> PlayerState:
	if player_id == "":
		player_id = _get_default_or_local_player_id()
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var psm = root.get_node_or_null("/root/PlayerRegistry") if root else null
	if not psm or not psm.has_method("get_player_state"): return null
	var ps = psm.get_player_state(player_id)
	if ps and ps.active_quests.is_empty() and ps.completed_quests.is_empty() and not quests.is_empty():
		init_player_quests(player_id)
	return ps

func init_player_quests(player_id: String) -> void:
	if player_id == "": player_id = _get_default_or_local_player_id()
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var psm = root.get_node_or_null("/root/PlayerRegistry") if root else null
	var ps = psm.get_player_state(player_id) if psm and psm.has_method("get_player_state") else null
	if not ps: return
	for q in quests:
		var qid = q.get("id", "")
		var unl = q.get("unlock", {})
		if unl.get("type", "") == "auto":
			if not ps.completed_quests.has(qid) and not ps.active_quests.has(qid):
				var prog_arr: Array = []
				for obj in q.get("objectives", []): prog_arr.append(0)
				ps.active_quests[qid] = { "status": STATUS_ACTIVE, "progress": prog_arr }

func reset_quests(player_id: String = "") -> void:
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var psm = root.get_node_or_null("/root/PlayerRegistry") if root else null
	if not psm: return
	var pids = [player_id] if player_id != "" else psm.players.keys()
	for pid in pids:
		var ps = psm.get_player_state(pid)
		if ps:
			ps.active_quests.clear()
			ps.completed_quests.clear()
			init_player_quests(pid)

func _ready() -> void:
	load_quests()
	_connect_event_bus()
	var psm = get_node_or_null("/root/PlayerRegistry")
	if psm and psm.has_signal("player_registered"):
		psm.player_registered.connect(init_player_quests)
		for pid in psm.players.keys():
			init_player_quests(pid)

func load_quests() -> void:
	quests.clear()
	
	var path = "res://data/quests/base_quests.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				var list = json.data.get("quests", [])
				for q in list:
					quests.append(q)
	print("[QuestManager] Loaded %d Quests." % quests.size())

func _connect_event_bus() -> void:
	var EventBus = get_node_or_null("/root/EventBus")
	if not EventBus: return
	
	EventBus.plant_planted.connect(func(pid, _pos, plant_id): _on_event(pid, "plant", 1, plant_id))
	EventBus.plant_watered.connect(func(pid, _pos): _on_event(pid, "water", 1, "any"))
	EventBus.plant_harvested.connect(func(pid, _pos, plant_id, count): _on_event(pid, "harvest", count, plant_id))
	EventBus.plant_combined.connect(func(pid, a, b, out): _on_event(pid, "combine", 1, out))
	EventBus.synthesis_performed.connect(func(pid, formula_id, result_id, count): _on_event(pid, "synthesis", count, result_id))
	EventBus.plant_discovered.connect(func(pid, plant_id): _on_event(pid, "discover", 1, plant_id))
	
	EventBus.item_sold.connect(func(pid, item_id, count, _gold): _on_event(pid, "sell", count, item_id))
	EventBus.item_bought.connect(func(pid, item_id, count, _price): _on_event(pid, "buy", count, item_id))
	
	EventBus.container_deposited.connect(func(pid, c_id, item_id, count): _on_event(pid, "deposit", count, item_id))
	EventBus.container_withdrawn.connect(func(pid, c_id, item_id, count): _on_event(pid, "withdraw", count, item_id))
	
	EventBus.npc_talked.connect(func(pid, npc_id): _on_event(pid, "talk", 1, npc_id))
	EventBus.dialogue_action_executed.connect(func(pid, npc_id, action_id, _params): _on_event(pid, "dialogue_action", 1, action_id))
	EventBus.friendship_changed.connect(func(pid, npc_id, pts): _on_event(pid, "friendship", pts, npc_id))
	
	EventBus.shared_event_triggered.connect(func(event_id, _params): _on_event("", "world_event", 1, event_id))
	EventBus.world_unlocked.connect(func(world_id, _dname): _on_event("", "unlock_world", 1, world_id))

func _on_event(player_id: String, obj_type: String, amount: int = 1, target: String = "") -> void:
	if player_id == "":
		var psm = get_node_or_null("/root/PlayerRegistry")
		if psm:
			for pid in psm.players.keys():
				_advance_objective_for_player(pid, obj_type, amount, target)
	else:
		_advance_objective_for_player(player_id, obj_type, amount, target)

func get_quest(quest_id: String) -> Dictionary:
	for q in quests:
		if q.get("id", "") == quest_id: return q
	return {}

func get_all_quests() -> Array:
	return quests.duplicate(true)

func get_quest_status(arg1: String, arg2: String = "") -> String:
	var player_id = ""
	var quest_id = ""
	if arg2 == "":
		player_id = ""
		quest_id = arg1
	else:
		player_id = arg1
		quest_id = arg2
	var ps = _get_player_state(player_id)
	if not ps: return STATUS_LOCKED
	if ps.completed_quests.has(quest_id): return STATUS_COMPLETED
	if ps.active_quests.has(quest_id): return ps.active_quests[quest_id].get("status", STATUS_ACTIVE)
	return STATUS_LOCKED

func get_quest_progress(arg1: String, arg2: String = "") -> Array:
	var player_id = ""
	var quest_id = ""
	if arg2 == "":
		player_id = ""
		quest_id = arg1
	else:
		player_id = arg1
		quest_id = arg2
	var ps = _get_player_state(player_id)
	if not ps or not ps.active_quests.has(quest_id): return []
	return ps.active_quests[quest_id].get("progress", [])

func get_active_quests(player_id: String = "") -> Array:
	var ps = _get_player_state(player_id)
	return ps.active_quests.keys() if ps else []

func get_completed_quests(player_id: String = "") -> Array:
	var ps = _get_player_state(player_id)
	return ps.completed_quests if ps else []

func advance_objective(arg1: Variant, arg2: Variant = "", arg3: Variant = 1, arg4: Variant = "") -> void:
	var player_id = ""
	var obj_type = ""
	var amount = 1
	var target_filter = ""
	
	if typeof(arg2) == TYPE_INT or typeof(arg2) == TYPE_FLOAT:
		# Called as advance_objective(obj_type, amount, target_filter)
		player_id = ""
		obj_type = str(arg1)
		amount = int(arg2)
		target_filter = str(arg3) if typeof(arg3) == TYPE_STRING else ""
	else:
		# Called as advance_objective(player_id, obj_type, amount, target_filter)
		player_id = str(arg1)
		obj_type = str(arg2)
		amount = int(arg3) if (typeof(arg3) == TYPE_INT or typeof(arg3) == TYPE_FLOAT) else 1
		target_filter = str(arg4)
		
	if obj_type == "": return
	
	if player_id == "":
		var psm = get_node_or_null("/root/PlayerRegistry")
		if psm:
			for pid in psm.players.keys():
				_advance_objective_for_player(pid, obj_type, amount, target_filter)
	else:
		_advance_objective_for_player(player_id, obj_type, amount, target_filter)

func _advance_objective_for_player(player_id: String, obj_type: String, amount: int = 1, target_filter: String = "") -> void:
	var ps = _get_player_state(player_id)
	if not ps: return
	var EventBus = get_node_or_null("/root/EventBus")
	
	var completed_any = false
	for q_id in ps.active_quests.keys():
		var q = get_quest(q_id)
		if q.is_empty(): continue
		
		var progress = ps.active_quests[q_id].get("progress", [])
		var objectives = q.get("objectives", [])
		var quest_updated = false
		
		for i in range(objectives.size()):
			var obj = objectives[i]
			if obj.get("type", "") == obj_type:
				var req_target = obj.get("target", "")
				if req_target == "" or req_target == target_filter:
					if i < progress.size():
						var req_amount = int(obj.get("amount", 1))
						if progress[i] < req_amount:
							progress[i] = mini(req_amount, progress[i] + amount)
							quest_updated = true
							quest_objective_updated.emit(q_id, progress[i], req_amount)
		
		if quest_updated:
			var all_done = true
			for i in range(objectives.size()):
				if i < progress.size() and progress[i] < int(objectives[i].get("amount", 1)):
					all_done = false
					break
			
			if all_done:
				complete_quest(player_id, q_id)
				completed_any = true

func complete_quest(player_id: String, quest_id: String) -> void:
	
	var ps = _get_player_state(player_id)
	if not ps: return
	if ps.completed_quests.has(quest_id): return
	if ps.active_quests.has(quest_id):
		ps.active_quests[quest_id]["status"] = STATUS_COMPLETED
		ps.completed_quests.append(quest_id)
		ps.active_quests.erase(quest_id)
		
		var EventBus = get_node_or_null("/root/EventBus")
		if EventBus: 
			EventBus.quest_completed.emit(player_id, quest_id)
			quest_status_changed.emit(quest_id, STATUS_COMPLETED)
		
		_unlock_dependent_quests(player_id, quest_id)
		claim_reward(player_id, quest_id)

func claim_reward(arg1: String, arg2: String = "") -> bool:
	var player_id = ""
	var quest_id = ""
	if arg2 == "":
		player_id = ""
		quest_id = arg1
	else:
		player_id = arg1
		quest_id = arg2
	
	var ps = _get_player_state(player_id)
	if not ps: return false
	var pid = ps.player_id if "player_id" in ps else player_id
	
	if not ps.completed_quests.has(quest_id):
		return false
		
	var q = get_quest(quest_id)
	if q.is_empty(): return false
	
	var rewards = q.get("rewards", {})
	RewardManager.grant_rewards(pid, rewards)
	
	var EventBus = get_node_or_null("/root/EventBus")
	if EventBus: EventBus.quest_claimed.emit(pid, quest_id)
	quest_reward_claimed.emit(quest_id, rewards)
	
	return true

func _unlock_dependent_quests(player_id: String, completed_quest_id: String) -> void:
	var ps = _get_player_state(player_id)
	if not ps: return
	
	for q in quests:
		var q_id = q.get("id", "")
		if ps.completed_quests.has(q_id) or ps.active_quests.has(q_id):
			continue
		
		var unl = q.get("unlock", {})
		var reqs = q.get("requirements", {})
		var can_unlock = false
		
		if unl.get("type", "") == "quest_completed" and unl.get("quest_id", "") == completed_quest_id:
			can_unlock = true
		elif completed_quest_id in reqs.get("quests", []):
			var all_reqs_met = true
			for rq in reqs.get("quests", []):
				if not ps.completed_quests.has(rq):
					all_reqs_met = false
					break
			if all_reqs_met:
				can_unlock = true
		
		if can_unlock:
			var progress = []
			progress.resize(q.get("objectives", []).size())
			progress.fill(0)
			
			ps.active_quests[q_id] = {
				"status": STATUS_ACTIVE,
				"progress": progress
			}
			quest_status_changed.emit(q_id, STATUS_ACTIVE)
