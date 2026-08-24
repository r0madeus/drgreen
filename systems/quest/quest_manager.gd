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
var quest_states: Dictionary = {} # quest_id -> { "status": String, "progress": [int] }

func _ready() -> void:
	load_quests()
	_connect_event_bus()

func load_quests() -> void:
	quests.clear()
	quest_states.clear()
	
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
					var qid = q.get("id", "")
					var unl = q.get("unlock", {})
					var init_status = STATUS_ACTIVE if unl.get("type", "") == "auto" else STATUS_LOCKED
					var prog_arr: Array = []
					for obj in q.get("objectives", []): prog_arr.append(0)
					quest_states[qid] = { "status": init_status, "progress": prog_arr }
	print("[QuestManager] Loaded %d Quests." % quests.size())

func _connect_event_bus() -> void:
	EventBus.plant_planted.connect(func(_pos, plant_id): _on_event("plant", 1, plant_id))
	EventBus.plant_watered.connect(func(_pos): _on_event("water", 1, "any"))
	EventBus.plant_harvested.connect(func(_pos, plant_id, count): _on_event("harvest", count, plant_id))
	EventBus.plant_combined.connect(func(a, b, out): _on_event("combine", 1, out))
	EventBus.synthesis_performed.connect(func(formula_id, result_id, count): _on_event("synthesis", count, result_id))
	EventBus.plant_discovered.connect(func(plant_id): _on_event("discover", 1, plant_id))
	EventBus.item_sold.connect(func(item_id, count, _gold): _on_event("sell", count, item_id))
	EventBus.item_bought.connect(func(item_id, count, _price): _on_event("buy", count, item_id))
	EventBus.container_deposited.connect(func(c_id, item_id, count): _on_event("deposit", count, item_id))
	EventBus.container_withdrawn.connect(func(c_id, item_id, count): _on_event("withdraw", count, item_id))
	EventBus.npc_talked.connect(func(npc_id): _on_event("talk", 1, npc_id))
	EventBus.dialogue_action_executed.connect(func(npc_id, action_id, _params): _on_event("dialogue_action", 1, action_id))
	EventBus.friendship_changed.connect(func(npc_id, pts): _on_event("friendship", pts, npc_id))
	EventBus.shared_event_triggered.connect(func(event_id, _params): _on_event("world_event", 1, event_id))
	EventBus.world_unlocked.connect(func(world_id, _dname): _on_event("unlock_world", 1, world_id))

func _on_event(obj_type: String, amount: int = 1, target: String = "") -> void:
	var net_q = get_node_or_null("/root/NetworkQuests")
	if net_q and not net_q.is_offline():
		net_q.request_advance_objective(obj_type, amount, target)
	else:
		advance_objective(obj_type, amount, target)


func get_quest(quest_id: String) -> Dictionary:
	for q in quests:
		if q.get("id", "") == quest_id: return q
	return {}

func get_all_quests() -> Array:
	return quests.duplicate(true)

func get_quest_status(quest_id: String) -> String:
	return quest_states.get(quest_id, {}).get("status", STATUS_LOCKED)

func get_quest_progress(quest_id: String) -> Array:
	return quest_states.get(quest_id, {}).get("progress", [])

func get_active_quests() -> Array:
	var list = []
	for q in quests:
		if get_quest_status(q.get("id", "")) == STATUS_ACTIVE: list.append(q)
	return list

func get_completed_quests() -> Array:
	var list = []
	for q in quests:
		var st = get_quest_status(q.get("id", ""))
		if st == STATUS_COMPLETED or st == STATUS_CLAIMED: list.append(q)
	return list

func advance_objective(obj_type: String, amount: int = 1, target_filter: String = "") -> void:
	for q in quests:
		var qid = q.get("id", "")
		if get_quest_status(qid) != STATUS_ACTIVE: continue
			
		var objectives = q.get("objectives", [])
		var progress = quest_states[qid]["progress"]
		var all_complete = true
		
		for i in range(objectives.size()):
			var obj = objectives[i]
			var t = str(obj.get("type", ""))
			var tgt = str(obj.get("target", "any"))
			var req = int(obj.get("amount", 1))
			
			var matches_type = (t == obj_type) or (obj_type == "harvest" and t in ["harvest", "harvest_crop", "harvest_greenhouse"])
			var matches_target = (tgt == "any") or (target_filter == "" or target_filter == tgt or target_filter.contains(tgt))
			
			if matches_type and matches_target:
				progress[i] = mini(req, int(progress[i]) + amount)
				quest_objective_updated.emit(qid, progress[i], req)
				
			if int(progress[i]) < req: all_complete = false
				
		if all_complete:
			complete_quest(qid)

func complete_quest(quest_id: String) -> void:
	if not quest_states.has(quest_id): return
	if quest_states[quest_id]["status"] == STATUS_ACTIVE:
		quest_states[quest_id]["status"] = STATUS_COMPLETED
		quest_status_changed.emit(quest_id, STATUS_COMPLETED)
		EventBus.quest_completed.emit(quest_id)
		
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("quest_complete")
		var spawner = EffectSpawner.get_instance()
		var player = get_tree().root.find_child("Player", true, false)
		var pos = player.global_position if player else Vector2(240, 180)
		if spawner:
			var q = get_quest(quest_id)
			spawner.spawn_floating_text(pos, "📜 Quest Completed: %s" % q.get("title", "Quest"), Color(0.4, 1.0, 0.4))

func claim_reward(quest_id: String, target_pstate: PlayerState = null) -> bool:
	if not quest_states.has(quest_id): return false
	if quest_states[quest_id]["status"] != STATUS_COMPLETED: return false
		
	quest_states[quest_id]["status"] = STATUS_CLAIMED
	quest_status_changed.emit(quest_id, STATUS_CLAIMED)
	EventBus.quest_claimed.emit(quest_id)
	
	var q = get_quest(quest_id)
	var rewards = q.get("rewards", {})
	RewardManager.grant_rewards(rewards, target_pstate)
	quest_reward_claimed.emit(quest_id, rewards)
	_unlock_dependent_quests(quest_id)
	return true


func _unlock_dependent_quests(completed_quest_id: String) -> void:
	for q in quests:
		var qid = q.get("id", "")
		if get_quest_status(qid) == STATUS_LOCKED:
			var unl = q.get("unlock", {})
			if unl.get("type", "") == "quest_completed" and unl.get("quest_id", "") == completed_quest_id:
				quest_states[qid]["status"] = STATUS_ACTIVE
				quest_status_changed.emit(qid, STATUS_ACTIVE)

# --- State Persistence ---
func get_quest_state() -> Dictionary:
	return { "quest_states": quest_states.duplicate(true) }

func load_quest_state(data: Dictionary) -> void:
	if data.has("quest_states"):
		quest_states = data["quest_states"].duplicate(true)
	elif data.has("states"):
		quest_states = data["states"].duplicate(true)
