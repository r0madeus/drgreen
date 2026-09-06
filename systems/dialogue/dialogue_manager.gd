extends Node

## Generalized Dialogue Manager loading all NPC dialogue trees from JSON.
## Evaluates data-driven conditions (heart levels, weather, season, quests, unlocks) deterministically.

signal dialogue_started(dialogue_id: String, speaker_name: String, lines: Array, portrait: Texture2D)
signal line_changed(line_text: String, line_index: int, total_lines: int)
signal dialogue_ended(dialogue_id: String)


var dialogue_catalog: Dictionary = {}
var session_player_id: String = ""

var current_dialogue_id: String = ""
var current_npc_id: String = ""
var current_lines: Array = []
var current_line_index: int = 0
var current_node_action: String = ""
var is_dialogue_active: bool = false

func _ready() -> void:
	load_all_dialogues()

func load_all_dialogues() -> void:
	dialogue_catalog.clear()
	var files = DirAccess.get_files_at("res://data/dialogue/")
	for file_name in files:
		if file_name.ends_with(".json"):
			var path = "res://data/dialogue/" + file_name
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var text = f.get_as_text()
				f.close()
				var json = JSON.new()
				if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
					var did = str(json.data.get("npc_id", file_name.trim_suffix(".json")))
					dialogue_catalog[did] = json.data
	print("[DialogueManager] Loaded %d Dialogue scripts." % dialogue_catalog.size())

func start_dialogue(arg1: String, arg2: String = "", arg3: String = "", arg4: String = "") -> void:
	var player_id = ""
	var dialogue_id = ""
	var speaker_name = ""
	var npc_id = ""
	
	var psm = get_node_or_null("/root/PlayerRegistry")
	var default_pid = psm.local_player_id if (psm and "local_player_id" in psm and psm.local_player_id != "") else "player_001"
	
	if psm and psm.has_method("has_player") and psm.has_player(arg1):
		player_id = arg1
		dialogue_id = arg2
		speaker_name = arg3
		npc_id = arg4
	elif dialogue_catalog.has(arg1) or (arg2 == "" and arg3 == "") or arg1.begins_with("dialogue_") or arg1 in ["rowan", "elias", "mira"]:
		player_id = default_pid
		dialogue_id = arg1
		speaker_name = arg2
		npc_id = arg3 if arg3 != "" else arg1
	else:
		player_id = arg1 if arg1 != "" else default_pid
		dialogue_id = arg2
		speaker_name = arg3
		npc_id = arg4

	if dialogue_id == "" and npc_id != "":
		dialogue_id = npc_id

	session_player_id = player_id
	var data = dialogue_catalog.get(dialogue_id, {})
	if data.is_empty():
		data = dialogue_catalog.get(npc_id, {})
		
	var nid = npc_id if npc_id != "" else (str(data.get("npc_id", dialogue_id)))
	var name_key = data.get("npc_name_key", "")
	var dname = speaker_name
	if dname == "":
		if name_key != "": dname = tr(name_key)
		else: dname = data.get("npc_name", dialogue_id.capitalize())
		
	var p_state = psm.get_player_state(player_id) if psm and psm.has_method("get_player_state") else null
	if not p_state and psm and psm.has_method("get_player_state"):
		p_state = psm.get_player_state(default_pid)
	
	var node_key = evaluate_dialogue_node_key(dialogue_id, p_state)
	var nodes = data.get("nodes", {})
	var node = nodes.get(node_key, nodes.get("default", { "lines": ["Greetings!"] }))
	
	current_dialogue_id = dialogue_id
	current_npc_id = nid
	
	var raw_lines = node.get("lines", ["Greetings!"])
	var line_keys = node.get("lines_keys", [])
	current_lines = []
	if line_keys.size() > 0:
		for k in line_keys:
			current_lines.append(tr(k))
	else:
		for l in raw_lines:
			current_lines.append(tr(l))
			
	current_node_action = str(node.get("action", ""))
	current_line_index = 0
	is_dialogue_active = true
	
	var portrait_tex = AssetRegistry.get_npc_portrait(current_npc_id)
		
	if p_state:
		p_state.record_dialogue_seen(current_npc_id, node_key)
		p_state.add_friendship(current_npc_id, 5, "talk")
		
	dialogue_started.emit(dialogue_id, dname, current_lines, portrait_tex)
	if current_lines.size() > 0:
		line_changed.emit(current_lines[0], 0, current_lines.size())
		
	EventBus.npc_talked.emit(session_player_id, current_npc_id)

func evaluate_dialogue_node_key(dialogue_id: String, p_state: PlayerState = null) -> String:
	var data = dialogue_catalog.get(dialogue_id, {})
	if data.is_empty(): return "default"
	
	var nodes: Dictionary = data.get("nodes", {})
	if nodes.is_empty(): return "default"
	
	var nid = str(data.get("npc_id", dialogue_id))
	var best_node_key = "default"
	var best_priority = -1
	
	for key in nodes.keys():
		var node = nodes[key]
		if not (node is Dictionary): continue
		var priority = int(node.get("priority", 0 if key == "default" else 1))
		var conditions: Array = node.get("conditions", [])
		
		if _check_node_conditions(conditions, nid, p_state):
			if priority > best_priority:
				best_priority = priority
				best_node_key = key
				
	return best_node_key

func _check_node_conditions(conditions: Array, npc_id: String, p_state: PlayerState) -> bool:
	if conditions.is_empty(): return true
	
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var qm = root.get_node_or_null("/root/QuestManager") if root else null
	var wm = root.get_node_or_null("/root/WeatherManager") if root else null
	var sm = root.get_node_or_null("/root/SeasonManager") if root else null
	var _tm = root.get_node_or_null("/root/TimeManager") if root else null
	var pm = root.get_node_or_null("/root/ProgressionManager") if root else null
	var jm = root.get_node_or_null("/root/JournalManager") if root else null
	
	for cond in conditions:
		if not (cond is Dictionary): continue
		var ctype = str(cond.get("type", ""))
		
		match ctype:
			"heart_level":
				var req_h = int(cond.get("min", cond.get("value", 1)))
				var cur_h = p_state.get_heart_level(npc_id) if p_state else 0
				if cur_h < req_h: return false
			"friendship", "min_friendship":
				var req_pts = int(cond.get("min", cond.get("value", 50)))
				var cur_pts = p_state.get_friendship_points(npc_id) if p_state else 0
				if cur_pts < req_pts: return false
			"weather":
				var req_w = str(cond.get("is", cond.get("value", "rain")))
				var cur_w = wm.current_weather if wm else "clear"
				if cur_w != req_w: return false
			"season":
				var req_s = str(cond.get("is", cond.get("value", "spring")))
				var cur_s = sm.get_season_id() if sm else "spring"
				if cur_s != req_s: return false
			"quest_completed":
				var req_qid = str(cond.get("quest_id", ""))
				if not qm or qm.get_quest_status(p_state.player_id if p_state else "", req_qid) not in [QuestManager.STATUS_COMPLETED, QuestManager.STATUS_CLAIMED]:
					return false
			"quest_active":
				var req_qid = str(cond.get("quest_id", ""))
				if not qm or qm.get_quest_status(p_state.player_id if p_state else "", req_qid) != QuestManager.STATUS_ACTIVE:
					return false
			"world_unlocked":
				var req_wid = str(cond.get("world_id", ""))
				if not pm or not pm.is_world_unlocked(req_wid):
					return false
			"plants_discovered":
				var req_cnt = int(cond.get("count", 1))
				var cur_cnt = jm.get_discovered_plant_count() if jm else 0
				if cur_cnt < req_cnt: return false
			"dialogue_seen":
				var req_node = str(cond.get("node_key", ""))
				if not p_state or not p_state.has_seen_dialogue(npc_id, req_node):
					return false
					
	return true

func advance_dialogue() -> bool:
	if not is_dialogue_active: return false
	current_line_index += 1
	if current_line_index < current_lines.size():
		line_changed.emit(current_lines[current_line_index], current_line_index, current_lines.size())
		var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
		var am = root.get_node_or_null("/root/AudioManager") if root else null
		if am: am.play_sfx("dialogue_next")
		return true
	else:
		end_dialogue()
		return false

func end_dialogue() -> void:
	if not is_dialogue_active: return
	is_dialogue_active = false
	var finished_id = current_dialogue_id
	var finished_npc = current_npc_id
	var act = current_node_action
	
	current_dialogue_id = ""
	current_npc_id = ""
	current_lines.clear()
	current_line_index = 0
	current_node_action = ""
	
	dialogue_ended.emit(finished_id)
	
	if act != "":
		_execute_node_action(session_player_id, act, finished_npc)

func _execute_node_action(player_id: String, action_str: String, npc_id: String) -> void:
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	match action_str:
		"open_shop":
			var npcm = root.get_node_or_null("/root/NPCManager") if root else null
			var shop_mgr = root.get_node_or_null("/root/ShopManager") if root else null
			var npc_data = npcm.get_npc_data(npc_id) if npcm else {}
			var sid = str(npc_data.get("shop_id", "rowan_seed_shop"))
			if shop_mgr:
				shop_mgr.open_shop(sid)
		"trigger_quest":
			var qm = root.get_node_or_null("/root/QuestManager") if root else null
			# Removed undefined activate_next_available_quest
