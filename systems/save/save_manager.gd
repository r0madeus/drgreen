extends Node

## Manages saving and loading game state to/from JSON files with Multi-World persistence & Dynamic Slot Management.

const SAVE_FILE_PATH: String = "user://savegame.json"
const SAVE_SLOT_DIR: String = "user://saves"
const INITIAL_SLOT_COUNT: int = 3

signal game_saved(filepath: String)
signal game_loaded(filepath: String)
signal save_error(message: String)
signal slot_deleted(slot_index: int)

var active_slot: int = 1

func _ready() -> void:
	_ensure_save_dir()
	migrate_legacy_saves()

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_SLOT_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_SLOT_DIR)

func get_slot_path(slot_index: int) -> String:
	return get_slot_path_for_game("botanical_haven", slot_index)

func get_slot_path_for_game(game_id: String, slot_index: int) -> String:
	if game_id == "" or game_id == "botanical_haven":
		return "%s/slot_%d.json" % [SAVE_SLOT_DIR, slot_index]
	var custom_dir = "%s/%s" % [SAVE_SLOT_DIR, game_id]
	if not DirAccess.dir_exists_absolute(custom_dir):
		DirAccess.make_dir_recursive_absolute(custom_dir)
	return "%s/slot_%d.json" % [custom_dir, slot_index]

func get_slot_state(slot_index: int) -> String:
	var path = get_slot_path(slot_index)
	if not FileAccess.file_exists(path):
		if slot_index == 1 and FileAccess.file_exists(SAVE_FILE_PATH):
			path = SAVE_FILE_PATH
		else:
			return "EMPTY"
			
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return "CORRUPTED"
	var text = f.get_as_text()
	f.close()
	
	if text.strip_edges() == "":
		return "EMPTY"
		
	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return "CORRUPTED"
		
	return "OCCUPIED"

func has_slot_save(slot_index: int) -> bool:
	return get_slot_state(slot_index) == "OCCUPIED"

func is_slot_corrupted(slot_index: int) -> bool:
	return get_slot_state(slot_index) == "CORRUPTED"

func is_slot_empty(slot_index: int) -> bool:
	return get_slot_state(slot_index) == "EMPTY"

func get_displayed_slot_count() -> int:
	var highest_occupied = 0
	var occupied_count = 0
	for i in range(1, 100):
		if has_slot_save(i):
			highest_occupied = i
			occupied_count += 1
			
	var count = maxi(INITIAL_SLOT_COUNT, highest_occupied)
	var all_occupied = true
	for i in range(1, count + 1):
		if not has_slot_save(i):
			all_occupied = false
			break
			
	if all_occupied:
		count += 1
		
	return maxi(INITIAL_SLOT_COUNT, count)

func has_any_save() -> bool:
	var max_slots = get_displayed_slot_count()
	for i in range(1, max_slots + 1):
		if has_slot_save(i): return true
	return FileAccess.file_exists(SAVE_FILE_PATH) or FileAccess.file_exists("user://savegame_v6.json")

func get_latest_save_slot() -> int:
	var latest_slot = -1
	var latest_ts: float = -1.0
	
	var total_slots = get_displayed_slot_count()
	for i in range(1, total_slots + 1):
		if has_slot_save(i):
			var meta = get_save_slot_metadata(i)
			var ts = float(meta.get("timestamp", 0.0))
			if ts > latest_ts:
				latest_ts = ts
				latest_slot = i
				
	if latest_slot == -1 and has_any_save():
		latest_slot = 1
		
	return latest_slot

func get_active_slot_index() -> int:
	return active_slot

func set_active_slot_index(slot_index: int) -> void:
	active_slot = maxi(1, slot_index)

func migrate_legacy_saves() -> void:
	_ensure_save_dir()
	var slot1_path = get_slot_path(1)
	if not FileAccess.file_exists(slot1_path):
		var legacy_files = ["user://savegame.json", "user://savegame_v6.json"]
		for leg in legacy_files:
			if FileAccess.file_exists(leg):
				var src = FileAccess.open(leg, FileAccess.READ)
				if src:
					var txt = src.get_as_text()
					src.close()
					var dst = FileAccess.open(slot1_path, FileAccess.WRITE)
					if dst:
						dst.store_string(txt)
						dst.close()
						print("[SaveManager] Migrated legacy save %s to %s" % [leg, slot1_path])
						break

func get_save_slot_metadata(slot_index: int) -> Dictionary:
	var state = get_slot_state(slot_index)
	var path = get_slot_path(slot_index)
	
	if state == "EMPTY":
		return {
			"exists": false,
			"corrupted": false,
			"slot_index": slot_index,
			"slot_name": "Save Slot %d" % slot_index,
			"filepath": path
		}
	elif state == "CORRUPTED":
		return {
			"exists": true,
			"corrupted": true,
			"slot_index": slot_index,
			"slot_name": "Save Slot %d" % slot_index,
			"filepath": path,
			"error": "Corrupted save data JSON"
		}
		
	var f = FileAccess.open(path, FileAccess.READ)
	if not f and slot_index == 1 and FileAccess.file_exists(SAVE_FILE_PATH):
		f = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		path = SAVE_FILE_PATH
		
	if not f:
		return {
			"exists": true,
			"corrupted": true,
			"slot_index": slot_index,
			"slot_name": "Save Slot %d" % slot_index,
			"filepath": path,
			"error": "Failed to open save file"
		}
		
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {
			"exists": true,
			"corrupted": true,
			"slot_index": slot_index,
			"slot_name": "Save Slot %d" % slot_index,
			"filepath": path,
			"error": "Corrupted JSON payload"
		}
		
	var d: Dictionary = json.data
	var day_num = int(d.get("day", 1))
	var season_dict = d.get("season", {})
	var season_name = str(season_dict.get("season", season_dict.get("current_season", "Spring"))).capitalize()
	var raw_world = str(d.get("current_world", "farm"))
	var world_display = "Peaceful Farm"
	match raw_world:
		"town": world_display = "Botanist Village"
		"botanical_grove": world_display = "Botanical Grove"
		"whispering_forest": world_display = "Whispering Forest"
		_: world_display = raw_world.replace("_", " ").capitalize()
		
	var gold = int(d.get("economy", {}).get("gold", 100))
	var p_dict = d.get("players", {}).get("player_001", {})
	var p_name = str(p_dict.get("display_name", "Botanist"))
	if p_dict.has("gold"): gold = int(p_dict.get("gold", gold))
	
	var ts = int(d.get("timestamp", 0))
	var last_played_str = "Unknown"
	if ts > 0:
		var dt = Time.get_datetime_dict_from_unix_time(ts)
		last_played_str = "%04d-%02d-%02d %02d:%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute]
		
	var quests_dict = d.get("quests", {})
	var completed_q_count = 0
	for qk in quests_dict.keys():
		if quests_dict[qk].get("status", "") in ["completed", "claimed"]: completed_q_count += 1
		
	var disc_count = d.get("discoveries", {}).get("discovered_combinations", []).size()
	
	return {
		"exists": true,
		"corrupted": false,
		"slot_index": slot_index,
		"slot_name": "Save Slot %d" % slot_index,
		"filepath": path,
		"timestamp": ts,
		"last_played_str": last_played_str,
		"day": day_num,
		"season": season_name,
		"current_world": world_display,
		"raw_world": raw_world,
		"player_name": p_name,
		"gold": gold,
		"quests_completed": completed_q_count,
		"discoveries_count": disc_count,
		"summary": "Day %d — %s • %s • %d Gold" % [day_num, season_name, world_display, gold]
	}

func get_all_slots_metadata() -> Array:
	var arr = []
	var total_slots = get_displayed_slot_count()
	for i in range(1, total_slots + 1):
		arr.append(get_save_slot_metadata(i))
	return arr

func save_to_slot(slot_index: int) -> bool:
	active_slot = maxi(1, slot_index)
	return save_game(slot_index)

func load_from_slot(slot_index: int) -> bool:
	active_slot = maxi(1, slot_index)
	return load_game(slot_index)

func delete_slot(slot_index: int) -> bool:
	var path = get_slot_path(slot_index)
	var deleted = false
	if FileAccess.file_exists(path):
		var err = DirAccess.remove_absolute(path)
		if err == OK:
			deleted = true
			print("[SaveManager] Deleted save slot %d at: %s" % [slot_index, path])
	if slot_index == 1 and FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		deleted = true
	slot_deleted.emit(slot_index)
	return deleted

func create_new_save(slot_idx: int) -> bool:
	active_slot = maxi(1, slot_idx)
	_ensure_save_dir()
	
	# Construct default clean state
	var default_data = {
		"version": SaveData.CURRENT_VERSION,
		"game_id": "botanical_haven",
		"game_version": "1.0.0",
		"active_mods": [],
		"gameplay_state": {},
		"timestamp": int(Time.get_unix_time_from_system()),
		"day": 1,
		"time": {
			"day": 1,
			"time_minutes": 360.0,
			"phase": "morning",
			"time_scale": 1.0,
			"is_paused": false
		},
		"current_world": "farm",
		"player": {
			"position": [16, 12],
			"facing": [0, 1],
			"position_space": "grid"
		},
		"players": {
			"player_001": {
				"player_id": "player_001",
				"display_name": "Botanist",
				"current_world": "farm",
				"position": [16, 12],
				"facing_direction": [0, 1],
				"inventory": {
					"seed_red_flower": 3,
					"seed_blue_flower": 2,
					"tool_hoe": 1,
					"tool_watering_can": 1
				},
				"selected_item_id": "tool_hoe",
				"gold": 100,
				"energy": 100.0,
				"max_energy": 100.0
			}
		},
		"inventory": {
			"items": {
				"seed_red_flower": 3,
				"seed_blue_flower": 2,
				"tool_hoe": 1,
				"tool_watering_can": 1
			},
			"selected": "tool_hoe"
		},
		"grid": {},
		"worlds": {},
		"world_states": {},
		"discoveries": {
			"discovered_combinations": []
		},
		"economy": {
			"gold": 100,
			"total_earned": 0,
			"total_spent": 0
		},
		"quests": {},
		"npc_state": {},
		"world": {
			"greenhouse": {}
		},
		"season": {
			"season": "spring",
			"day_of_season": 1,
			"year": 1
		},
		"weather": {
			"current_weather": "sunny",
			"forecast": "sunny"
		},
		"progression": {
			"unlocked_worlds": { "farm": true, "town": true },
			"visited_worlds": { "farm": true }
		}
	}
	
	var path = get_slot_path(active_slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		var err_msg = "Failed to create new save file at: " + path
		push_error(err_msg)
		save_error.emit(err_msg)
		return false
		
	var json_str = JSON.stringify(default_data, "\t")
	file.store_string(json_str)
	file.close()
	print("[SaveManager] Atomic new save created at: %s" % path)
	game_saved.emit(path)
	return true

func new_game(slot_idx: int = 1) -> bool:
	active_slot = maxi(1, slot_idx)
	create_new_save(active_slot)
	
	var psm = get_node_or_null("/root/PlayerStateManager")
	if psm and psm.has_method("reset_state"):
		psm.reset_state()
		var p_state = psm.get_active_player_state()
		if p_state and p_state.has_method("init_starter_kit"):
			p_state.init_starter_kit()
		
	var im = get_node_or_null("/root/InventoryManager")
	if im and im.has_method("reset_inventory"):
		im.reset_inventory()
		
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.current_day = 1
		tm.current_time_minutes = 360.0
		tm.is_paused = false
		if tm.has_method("_update_phase"):
			tm._update_phase(false)
		
	var sm_mgr = get_node_or_null("/root/SeasonManager")
	if sm_mgr and sm_mgr.has_method("update_from_day"):
		sm_mgr.update_from_day(1, true)
		
	var qm = get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("reset_quests"):
		qm.reset_quests()
		
	var econ = get_node_or_null("/root/EconomyManager")
	if econ and econ.has_method("set_gold"):
		econ.set_gold(100)
		
	var wl = get_node_or_null("/root/WorldLoader")
	if wl:
		wl.world_states.clear()
		wl.load_world("farm")
		
	print("[SaveManager] New game initialized for slot %d" % active_slot)
	return true

func save_game(target = null) -> bool:
	_ensure_save_dir()
	
	var filepath: String = ""
	if target is int and target > 0:
		active_slot = target
		filepath = get_slot_path(target)
	elif target is String and target != "":
		filepath = target
	else:
		filepath = get_slot_path(active_slot)
		
	var save = SaveData.new()
	save.timestamp = int(Time.get_unix_time_from_system())
	
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		if tm.has_method("get_current_day"):
			save.day = tm.get_current_day()
		elif tm.has_method("get_day"):
			save.day = tm.get_day()
		elif "current_day" in tm:
			save.day = tm.current_day
		else:
			save.day = 1
		save.time = tm.get_time_state() if tm.has_method("get_time_state") else {}
		
	var cm = get_node_or_null("/root/CombinationManager")
	if cm and cm.has_method("get_discovery_state"):
		save.discoveries = cm.get_discovery_state()
		
	var psm = get_node_or_null("/root/PlayerStateManager")
	if psm:
		save.players = psm.get_all_player_states_dict()
		var p_act = psm.get_active_player_state()
		if p_act:
			save.player = {
				"position": [p_act.grid_position.x, p_act.grid_position.y],
				"facing": [p_act.facing_direction.x, p_act.facing_direction.y],
				"position_space": "grid"
			}
			save.inventory = {
				"items": p_act.inventory.duplicate(true),
				"selected": p_act.selected_item_id
			}
			
	var wl = get_node_or_null("/root/WorldLoader")
	var wm = get_node_or_null("/root/WorldManager")
	var current_w = "farm"
	if wl:
		wl._save_current_world_runtime_state()
		save.world_states = wl.world_states.duplicate(true)
		save.worlds = save.world_states
		current_w = wl.get_current_world_id()
	elif wm:
		current_w = wm.get_current_world()
		
	save.current_world = current_w
	
	var econ = get_node_or_null("/root/EconomyManager")
	if econ and econ.has_method("get_economy_state"):
		save.economy = econ.get_economy_state()
	elif econ:
		save.economy = { "gold": econ.get_gold() }
		
	var qm = get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("get_quest_state"):
		save.quests = qm.get_quest_state()
		
	var npcm = get_node_or_null("/root/NPCManager")
	if npcm and npcm.has_method("get_npc_state"):
		save.npc_state = npcm.get_npc_state()
		
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	if gm_mgr and gm_mgr.has_method("get_greenhouse_state"):
		save.world["greenhouse"] = gm_mgr.get_greenhouse_state()
		
	var sm_mgr = get_node_or_null("/root/SeasonManager")
	if sm_mgr and sm_mgr.has_method("get_season_state"):
		save.season = sm_mgr.get_season_state()
		
	var wm_mgr = get_node_or_null("/root/WeatherManager")
	if wm_mgr and wm_mgr.has_method("get_weather_state"):
		save.weather = wm_mgr.get_weather_state()
		
	var pm = get_node_or_null("/root/ProgressionManager")
	if pm:
		save.progression = {
			"unlocked_worlds": pm.unlocked_worlds.duplicate(true),
			"visited_worlds": pm.visited_worlds.duplicate(true)
		}
		
	var save_dict = save.to_dict()
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if not file:
		var err_msg = "Failed to open save file for writing: " + filepath
		push_error(err_msg)
		save_error.emit(err_msg)
		return false
		
	var json_str = JSON.stringify(save_dict, "\t")
	file.store_string(json_str)
	file.close()
	
	print("[SaveManager] Game saved successfully to: " + filepath)
	game_saved.emit(filepath)
	return true

func load_game(target = null) -> bool:
	var filepath: String = ""
	if target is int and target > 0:
		active_slot = target
		filepath = get_slot_path(target)
	elif target is String and target != "":
		filepath = target
	else:
		filepath = get_slot_path(active_slot)

	if not FileAccess.file_exists(filepath):
		if active_slot == 1 and FileAccess.file_exists(SAVE_FILE_PATH):
			filepath = SAVE_FILE_PATH
		else:
			var msg = "No save file found at: " + filepath
			print("[SaveManager] " + msg)
			save_error.emit(msg)
			return false
		
	var file = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		var err_msg = "Failed to open save file for reading: " + filepath
		push_error(err_msg)
		save_error.emit(err_msg)
		return false
		
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_err = json.parse(content)
	if parse_err != OK:
		var err_msg = "Corrupted save file JSON: " + json.get_error_message()
		push_error(err_msg)
		save_error.emit(err_msg)
		return false
		
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		var err_msg = "Invalid save data structure: root must be dictionary"
		push_error(err_msg)
		save_error.emit(err_msg)
		return false
		
	var save = SaveData.from_dict(data)
	
	# 1. Time
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		if save.time is Dictionary and not save.time.is_empty():
			tm.load_time_state(save.time)
		else:
			tm.set_day(save.day)
			
	# 2. Discoveries
	var cm = get_node_or_null("/root/CombinationManager")
	if cm and cm.has_method("load_discovery_state"):
		cm.load_discovery_state(save.discoveries)
		
	# 3. Player States Restoration
	var psm = get_node_or_null("/root/PlayerStateManager")
	if psm and not save.players.is_empty():
		psm.players.clear()
		for pid in save.players.keys():
			var p_dict = save.players[pid]
			psm.players[pid] = PlayerState.from_dict(p_dict)
		psm.active_player_changed.emit(psm.active_player_id)
		
	# 3b. Inventory & Economy Forwarding
	var im = get_node_or_null("/root/InventoryManager")
	if im:
		im.inventory_updated.emit()
		im.item_selected.emit(im.selected_item_id)
		
	# 4. Multi-World & Grid restoration
	var wl = get_node_or_null("/root/WorldLoader")
	var wm = get_node_or_null("/root/WorldManager")
	var target_w = save.current_world if save.current_world != "" else "farm"
	var saved_position = save.player.get("position", [16, 12])
	var player_pos = saved_position
	if str(save.player.get("position_space", "grid")) == "world":
		var saved_world_pos = Vector2(float(saved_position[0]), float(saved_position[1]))
		var load_grid = get_tree().root.find_child("GridManager", true, false) as GridManager
		player_pos = load_grid.world_to_grid(saved_world_pos) if load_grid else Vector2i(int(floor(saved_world_pos.x / 16.0)), int(floor(saved_world_pos.y / 16.0)))
	
	if wm and not save.world_states.is_empty():
		for wid in save.world_states.keys():
			var s_dict = save.world_states[wid]
			wm.shared_world_states[wid] = SharedWorldState.from_dict(wid, s_dict)
			
	if wm:
		wm.current_world_id = target_w
		
	if wl:
		wl.current_world_id = target_w
		wl.world_states = save.world_states.duplicate(true)
		wl.change_world(target_w, player_pos, false)
		
	# 5. Player Facing & Position
	var player = get_tree().root.find_child("Player", true, false)
	var gm_ref = get_tree().root.find_child("GridManager", true, false)
	if player and gm_ref:
		var pos_arr = save.player.get("position", [16, 12])
		var facing_arr = save.player.get("facing", [0, 1])
		var is_world_position = str(save.player.get("position_space", "grid")) == "world"
		var world_pos = Vector2(float(pos_arr[0]), float(pos_arr[1])) if is_world_position else gm_ref.grid_to_world(Vector2i(int(pos_arr[0]), int(pos_arr[1])), true)
		var facing_dir = Vector2i(facing_arr[0], facing_arr[1])
		player.grid_position = gm_ref.world_to_grid(world_pos)
		player.facing_direction = facing_dir
		player.position = world_pos
		player.velocity = Vector2.ZERO
		if player.animation_handler:
			player.animation_handler.set_direction(facing_dir)
			
	# 6. Economy
	var econ = get_node_or_null("/root/EconomyManager")
	if econ and econ.has_method("load_economy_state"):
		econ.load_economy_state(save.economy)
	elif econ:
		var saved_gold = int(save.economy.get("gold", 100))
		econ.set_gold(saved_gold)
		
	# 7. Quest state
	var qm = get_node_or_null("/root/QuestManager")
	if qm and qm.has_method("load_quest_state"):
		qm.load_quest_state(save.quests)
		
	# 7b. NPC state refresh
	var npcm = get_node_or_null("/root/NPCManager")
	if npcm:
		var tm_ref = get_node_or_null("/root/TimeManager")
		var cur_m = int(tm_ref.get_current_time()) if tm_ref else 360
		for nid in npcm.npcs_catalog.keys():
			npcm._evaluate_npc_schedule(nid, cur_m, true)
		
	# 8. World state (Greenhouse)
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	if gm_mgr and gm_mgr.has_method("load_greenhouse_state"):
		var gh_data = save.world.get("greenhouse", {})
		gm_mgr.load_greenhouse_state(gh_data)
		
	# 9. Season & Time state
	var sm_mgr = get_node_or_null("/root/SeasonManager")
	if sm_mgr and sm_mgr.has_method("load_season_state"):
		sm_mgr.load_season_state(save.season)
		
	# 10. Weather state
	var wm_mgr = get_node_or_null("/root/WeatherManager")
	if wm_mgr and wm_mgr.has_method("load_weather_state"):
		wm_mgr.load_weather_state(save.weather)
		
	# 11. Progression state
	var pm = get_node_or_null("/root/ProgressionManager")
	if pm and not save.progression.is_empty():
		pm.unlocked_worlds = save.progression.get("unlocked_worlds", { "farm": true, "town": true }).duplicate(true)
		pm.visited_worlds = save.progression.get("visited_worlds", { "farm": true }).duplicate(true)
			
	print("[SaveManager] Game loaded successfully from: " + filepath)
	game_loaded.emit(filepath)
	return true
