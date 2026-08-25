extends Node

## Central NPC lifecycle, data-driven daily schedule, and placement manager across multi-world scenes.
## Authoritative for schedule evaluation, location anchor resolution, social simulation, and network synchronization.

signal npc_schedule_updated(npc_id: String, location_id: String, activity: String, world_id: String)
signal npc_destination_reached(npc_id: String, location_id: String)

const LOCATIONS_PATH: String = "res://data/npcs/locations.json"
const SCHEDULES_PATH: String = "res://data/npcs/schedules.json"
const SOCIAL_PATH: String = "res://data/npcs/social.json"
const NPC_INSTANCE_SCENE = preload("res://systems/npc/npc_instance.gd")

var npcs_catalog: Dictionary = {} # npc_id -> Dictionary
var locations_catalog: Dictionary = {} # location_id -> Dictionary
var schedules_catalog: Dictionary = {} # npc_id -> Dictionary (variants -> Array)
var relationships_catalog: Dictionary = {} # npc_id -> Dictionary
var preferences_catalog: Dictionary = {}
var milestones_catalog: Dictionary = {}
var active_npc_instances: Dictionary = {} # npc_id -> Node2D

# Current active schedule entry tracked per NPC: npc_id -> Dictionary
var current_npc_schedule_entries: Dictionary = {}

var social_check_timer: float = 0.0
const SOCIAL_CHECK_INTERVAL: float = 1.0

func _init() -> void:
	load_all_npcs()
	load_locations()
	load_schedules()
	load_social_data()

func _ready() -> void:
	load_all_npcs()
	load_locations()
	load_schedules()
	load_social_data()
	EventBus.world_changed.connect(_on_world_changed)
	
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.time_changed.connect(_on_time_changed)
		tm.day_started.connect(func(_d): reset_daily_schedules())
		
	var wm = get_node_or_null("/root/WeatherManager")
	if wm:
		wm.weather_changed.connect(_on_weather_changed)

func _process(delta: float) -> void:
	social_check_timer += delta
	if social_check_timer >= SOCIAL_CHECK_INTERVAL:
		social_check_timer = 0.0
		check_social_interactions()

# ---------- Data Loading ----------

func load_all_npcs() -> void:
	npcs_catalog.clear()
	var files = DirAccess.get_files_at("res://data/npcs/")
	for file_name in files:
		if file_name.ends_with(".json") and file_name not in ["locations.json", "schedules.json", "social.json"]:
			var path = "res://data/npcs/" + file_name
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var text = f.get_as_text()
				f.close()
				var json = JSON.new()
				if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
					var nid = str(json.data.get("id", file_name.trim_suffix(".json")))
					npcs_catalog[nid] = json.data
	print("[NPCManager] Loaded %d NPC catalog profiles." % npcs_catalog.size())

func load_locations() -> void:
	locations_catalog.clear()
	if not FileAccess.file_exists(LOCATIONS_PATH): return
	var f = FileAccess.open(LOCATIONS_PATH, FileAccess.READ)
	if not f: return
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		var d: Dictionary = json.data
		locations_catalog = d.get("locations", {})
	print("[NPCManager] Loaded %d location anchors." % locations_catalog.size())

func load_schedules() -> void:
	schedules_catalog.clear()
	if not FileAccess.file_exists(SCHEDULES_PATH): return
	var f = FileAccess.open(SCHEDULES_PATH, FileAccess.READ)
	if not f: return
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		var d: Dictionary = json.data
		schedules_catalog = d.get("schedules", {})
	print("[NPCManager] Loaded %d NPC schedule routines." % schedules_catalog.size())

func load_social_data() -> void:
	relationships_catalog.clear()
	preferences_catalog.clear()
	milestones_catalog.clear()
	
	if FileAccess.file_exists(SOCIAL_PATH):
		var f = FileAccess.open(SOCIAL_PATH, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				relationships_catalog = json.data.get("relationships", {})
			f.close()
			
	if FileAccess.file_exists("res://data/npcs/preferences.json"):
		var f = FileAccess.open("res://data/npcs/preferences.json", FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				preferences_catalog = json.data.get("preferences", {})
			f.close()
			
	if FileAccess.file_exists("res://data/npcs/milestones.json"):
		var f = FileAccess.open("res://data/npcs/milestones.json", FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				milestones_catalog = json.data.get("milestones", {})
			f.close()
	
	print("[NPCManager] Loaded %d NPC social relationship profiles, %d preferences, %d milestones." % [relationships_catalog.size(), preferences_catalog.size(), milestones_catalog.size()])

# ---------- Location & Schedule Resolution ----------

func get_location(location_id: String) -> Dictionary:
	return locations_catalog.get(location_id, {})

func get_location_world_pos(location_id: String) -> Vector2:
	var loc = get_location(location_id)
	if loc.is_empty(): return Vector2(240, 180)
	var pos_arr = loc.get("position", [240.0, 180.0])
	return Vector2(float(pos_arr[0]), float(pos_arr[1]))

func get_location_world_id(location_id: String) -> String:
	var loc = get_location(location_id)
	return str(loc.get("world", "farm"))

func get_schedule_variant_for_condition(npc_id: String) -> String:
	var wm = get_node_or_null("/root/WeatherManager")
	var sm = get_node_or_null("/root/SeasonManager")
	var raw_npc_sched = schedules_catalog.get(npc_id, {})
	
	if wm and wm.is_raining() and raw_npc_sched.has("rain"):
		return "rain"
	if sm and raw_npc_sched.has(sm.get_season_id()):
		return sm.get_season_id()
	return "default"

func get_schedule_for_npc(npc_id: String, variant: String = "") -> Array:
	var raw_npc_sched = schedules_catalog.get(npc_id, {})
	if raw_npc_sched.is_empty(): return []
	
	if variant == "":
		variant = get_schedule_variant_for_condition(npc_id)
		
	var sched: Array = raw_npc_sched.get(variant, raw_npc_sched.get("default", []))
	var sorted = sched.duplicate(true)
	sorted.sort_custom(func(a, b): return int(a.get("start_minute", 0)) < int(b.get("start_minute", 0)))
	return sorted

func resolve_schedule_entry(npc_id: String, minute: int) -> Dictionary:
	var sched = get_schedule_for_npc(npc_id)
	if sched.is_empty(): return {}
	
	var active_entry: Dictionary = sched[0]
	for entry in sched:
		var start_m = int(entry.get("start_minute", 0))
		if minute >= start_m:
			active_entry = entry
		else:
			break
	return active_entry

# ---------- Time & Weather Reactions ----------

func _on_time_changed(minutes: int, _tstr: String = "") -> void:
	for nid in npcs_catalog.keys():
		_evaluate_npc_schedule(nid, minutes)

func _on_weather_changed(_old_w: String, _new_w: String) -> void:
	var tm = get_node_or_null("/root/TimeManager")
	var cur_m = int(tm.get_current_time()) if tm else 360
	for nid in npcs_catalog.keys():
		_evaluate_npc_schedule(nid, cur_m, true)

func _evaluate_npc_schedule(npc_id: String, minutes: int, force_immediate: bool = false) -> void:
	var new_entry = resolve_schedule_entry(npc_id, minutes)
	if new_entry.is_empty(): return
	
	var last_entry = current_npc_schedule_entries.get(npc_id, {})
	var entry_changed = (last_entry.get("location_id", "") != new_entry.get("location_id", "")) or (last_entry.get("activity", "") != new_entry.get("activity", ""))
	
	if entry_changed or force_immediate:
		current_npc_schedule_entries[npc_id] = new_entry
		_apply_schedule_entry(npc_id, new_entry, force_immediate)
		EventBus.npc_schedule_changed.emit(npc_id, new_entry)

func _apply_schedule_entry(npc_id: String, entry: Dictionary, immediate: bool = false) -> void:
	var loc_id = str(entry.get("location_id", ""))
	var target_world = get_location_world_id(loc_id)
	var target_world_pos = get_location_world_pos(loc_id)
	var activity = str(entry.get("activity", "idle"))
	var priority = int(entry.get("priority", 2))
	var fallback_loc = str(entry.get("fallback_location_id", "rowan_home"))
	var facing_arr = entry.get("facing", [0, 1])
	var def_facing = Vector2(float(facing_arr[0]), float(facing_arr[1]))
	
	# Update authoritative SharedWorldState
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		var grid_pos = Vector2i(int(floor(target_world_pos.x / 16.0)), int(floor(target_world_pos.y / 16.0)))
		var s = wm.get_shared_world_state(target_world)
		if s: s.set_npc_position(npc_id, target_world, grid_pos)
		
	var net_npc = get_node_or_null("/root/NetworkNPC")
	if net_npc and not net_npc.is_offline() and net_npc.is_host():
		net_npc.broadcast_npc_movement(target_world, npc_id, Vector2i(int(floor(target_world_pos.x / 16.0)), int(floor(target_world_pos.y / 16.0))))
		
	var wl = get_node_or_null("/root/WorldLoader")
	var cur_world = wl.current_world_id if wl else "farm"
	
	var inst = active_npc_instances.get(npc_id, null)
	if target_world == cur_world:
		if inst and is_instance_valid(inst):
			if immediate:
				if inst.has_method("teleport_to_location"):
					inst.teleport_to_location(loc_id, target_world_pos, activity, def_facing)
			else:
				if inst.get("behavior_controller") != null and inst.behavior_controller.has_method("set_activity"):
					inst.behavior_controller.set_activity(activity, loc_id, target_world_pos, priority, fallback_loc)
				elif inst.has_method("set_destination"):
					inst.set_destination(loc_id, target_world_pos, activity, def_facing)
		else:
			spawn_single_npc(npc_id, target_world, target_world_pos)
	else:
		if inst and is_instance_valid(inst) and not inst.is_in_group("static_scene_npc"):
			inst.queue_free()
			active_npc_instances.erase(npc_id)
		elif inst and is_instance_valid(inst) and inst.is_in_group("static_scene_npc"):
			inst.visible = false
			inst.set_process(false)
			
	npc_schedule_updated.emit(npc_id, loc_id, activity, target_world)

# ---------- Social Interaction Coordination ----------

func check_social_interactions() -> void:
	var keys = active_npc_instances.keys()
	if keys.size() < 2: return
	
	for i in range(keys.size()):
		var id_a = keys[i]
		var inst_a = active_npc_instances[id_a]
		if not is_instance_valid(inst_a) or not inst_a.visible: continue
		var ctrl_a = inst_a.get("behavior_controller")
		if not ctrl_a or not ctrl_a.can_start_social_interaction(): continue
		
		for j in range(i + 1, keys.size()):
			var id_b = keys[j]
			var inst_b = active_npc_instances[id_b]
			if not is_instance_valid(inst_b) or not inst_b.visible: continue
			var ctrl_b = inst_b.get("behavior_controller")
			if not ctrl_b or not ctrl_b.can_start_social_interaction(): continue
			
			var dist = inst_a.global_position.distance_to(inst_b.global_position)
			if dist <= 40.0:
				# Face each other and start social conversation
				if inst_a.has_method("turn_to_face"):
					inst_a.turn_to_face(inst_b.global_position)
				if inst_b.has_method("turn_to_face"):
					inst_b.turn_to_face(inst_a.global_position)
					
				ctrl_a.start_social_interaction(id_b, 4.0)
				ctrl_b.start_social_interaction(id_a, 4.0)
				return

# ---------- World Spawning & Lifecycle ----------

func _on_world_changed(world_id: String, _world_data: Dictionary = {}) -> void:
	spawn_npcs_for_world(world_id)

func spawn_npcs_for_world(world_id: String) -> void:
	for nid in active_npc_instances.keys():
		var inst = active_npc_instances[nid]
		if is_instance_valid(inst) and not inst.is_in_group("static_scene_npc"):
			inst.queue_free()
	active_npc_instances.clear()
	
	var gm = get_tree().root.find_child("GridManager", true, false)
	if not gm: return
	
	var tm = get_node_or_null("/root/TimeManager")
	var cur_minute = int(tm.get_current_time()) if tm else 360
	
	var existing_seed_merchant = get_tree().root.find_child("SeedMerchant", true, false)
	if existing_seed_merchant and is_instance_valid(existing_seed_merchant):
		existing_seed_merchant.add_to_group("static_scene_npc")
		var rowan_entry = resolve_schedule_entry("rowan", cur_minute)
		var rowan_world = get_location_world_id(str(rowan_entry.get("location_id", "seed_shop")))
		
		if world_id == "farm" and (rowan_world == "farm" or rowan_entry.is_empty()):
			active_npc_instances["rowan"] = existing_seed_merchant
			existing_seed_merchant.visible = true
			existing_seed_merchant.set_process(true)
			_evaluate_npc_schedule("rowan", cur_minute, true)
		else:
			existing_seed_merchant.visible = false
			existing_seed_merchant.set_process(false)

	for nid in npcs_catalog.keys():
		if active_npc_instances.has(nid) and is_instance_valid(active_npc_instances[nid]):
			continue
			
		var entry = resolve_schedule_entry(nid, cur_minute)
		var assigned_world = get_location_world_id(str(entry.get("location_id", "")))
		if assigned_world == "" or entry.is_empty():
			assigned_world = str(npcs_catalog[nid].get("world", "farm"))
			
		if assigned_world == world_id:
			var target_pos = get_location_world_pos(str(entry.get("location_id", "")))
			spawn_single_npc(nid, world_id, target_pos)

func spawn_single_npc(nid: String, world_id: String, target_world_pos: Vector2 = Vector2.ZERO) -> void:
	var gm = get_tree().root.find_child("GridManager", true, false)
	if not gm: return
	
	var npc_data = npcs_catalog.get(nid, {}).duplicate(true)
	npc_data["world"] = world_id
	if target_world_pos != Vector2.ZERO:
		npc_data["position"] = [int(floor(target_world_pos.x / 16.0)), int(floor(target_world_pos.y / 16.0))]
		
	var inst = Node2D.new()
	inst.set_script(NPC_INSTANCE_SCENE)
	gm.add_child(inst)
	inst.setup(npc_data)
	if target_world_pos != Vector2.ZERO:
		inst.global_position = target_world_pos
	active_npc_instances[nid] = inst
	
	var tm = get_node_or_null("/root/TimeManager")
	var cur_min = int(tm.get_current_time()) if tm else 360
	_evaluate_npc_schedule(nid, cur_min, true)

func get_npc_data(npc_id: String) -> Dictionary:
	return npcs_catalog.get(npc_id, {})

func get_active_npc_instance(npc_id: String) -> Node2D:
	var inst = active_npc_instances.get(npc_id, null)
	if inst and is_instance_valid(inst):
		return inst
	active_npc_instances.erase(npc_id)
	return null


func get_npc_world(npc_id: String) -> String:
	var tm = get_node_or_null("/root/TimeManager")
	var cur_m = int(tm.get_current_time()) if tm else 360
	var entry = resolve_schedule_entry(npc_id, cur_m)
	if not entry.is_empty():
		return get_location_world_id(str(entry.get("location_id", "")))
	var data = get_npc_data(npc_id)
	return str(data.get("world", "farm"))

func move_npc(npc_id: String, target_world: String, target_pos: Vector2i) -> void:
	var net_npc = get_node_or_null("/root/NetworkNPC")
	if net_npc and not net_npc.is_offline():
		net_npc.broadcast_npc_movement(target_world, npc_id, target_pos)
	else:
		var inst = get_active_npc_instance(npc_id)
		if inst and is_instance_valid(inst):
			var gm = get_tree().root.find_child("GridManager", true, false)
			var w_pos = gm.grid_to_world(target_pos, true) if gm else Vector2(target_pos.x * 16 + 8, target_pos.y * 16 + 8)
			if inst.has_method("set_destination"):
				inst.set_destination("custom", w_pos, "walk")

func reset_daily_schedules() -> void:
	current_npc_schedule_entries.clear()
	var tm = get_node_or_null("/root/TimeManager")
	var cur_m = int(tm.get_current_time()) if tm else 360
	
	for nid in npcs_catalog.keys():
		_evaluate_npc_schedule(nid, cur_m, true)
		var inst = active_npc_instances.get(nid, null)
		if is_instance_valid(inst) and inst.has_method("reset_daily_schedule"):
			inst.reset_daily_schedule()
	print("[NPCManager] Daily NPC schedules reset to morning routines.")

# ---------- Validation & Diagnostics ----------

func validate_schedules() -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	for nid in schedules_catalog.keys():
		var raw_sched = schedules_catalog[nid]
		for variant_key in raw_sched.keys():
			var entries = raw_sched[variant_key]
			for entry in entries:
				var loc_id = str(entry.get("location_id", ""))
				if not locations_catalog.has(loc_id):
					errors.append({ "npc_id": nid, "variant": variant_key, "error": "Unknown location: " + loc_id })
				var act = str(entry.get("activity", ""))
				if act == "":
					errors.append({ "npc_id": nid, "variant": variant_key, "error": "Missing activity" })
	return errors

func get_npc_debug_info(npc_id: String) -> Dictionary:
	var inst = active_npc_instances.get(npc_id, null)
	var entry = current_npc_schedule_entries.get(npc_id, {})
	var loc_id = str(entry.get("location_id", "none"))
	var target_pos = get_location_world_pos(loc_id)
	var cur_pos = inst.global_position if (inst and is_instance_valid(inst)) else Vector2.ZERO
	var dist = cur_pos.distance_to(target_pos) if (inst and is_instance_valid(inst)) else 0.0
	var ctrl = inst.get("behavior_controller") if (inst and is_instance_valid(inst)) else null
	
	return {
		"npc_id": npc_id,
		"world": get_npc_world(npc_id),
		"state": ctrl.current_state if ctrl else (inst.current_state if (inst and "current_state" in inst) else "INACTIVE"),
		"activity": ctrl.current_activity if ctrl else str(entry.get("activity", "none")),
		"location_id": loc_id,
		"position": [cur_pos.x, cur_pos.y],
		"target_position": [target_pos.x, target_pos.y],
		"distance_to_target": dist,
		"facing": [inst.facing_direction.x, inst.facing_direction.y] if (inst and "facing_direction" in inst) else [0, 1],
		"social_partner": ctrl.social_partner_id if ctrl else "",
		"social_cooldown": ctrl.social_cooldown if ctrl else 0.0
	}


# ---------- Social Gifting & Milestones ----------

func _get_player_state(player_id: String):
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var psm = root.get_node_or_null("/root/PlayerRegistry") if root else null
	if psm and psm.has_method("get_player_state"):
		return psm.get_player_state(player_id)
	return null

func can_give_gift(player_id: String, npc_id: String, item_id: String, _override_pstate = null) -> bool:
	var p_state = _override_pstate if _override_pstate else _get_player_state(player_id)
	if not p_state: return false
	if npc_id.is_empty() or item_id.is_empty(): return false
	if bool(p_state.daily_gifted_npcs.get(npc_id, false)): return false
	if not p_state.has_item(item_id, 1): return false
	return true

func get_gift_reaction_type(npc_id: String, item_id: String) -> String:
	var npc_prefs = preferences_catalog.get(npc_id, {})
	if item_id in npc_prefs.get("loved", []): return "loved"
	if item_id in npc_prefs.get("liked", []): return "liked"
	if item_id in npc_prefs.get("disliked", []): return "disliked"
	if item_id in npc_prefs.get("hated", []): return "hated"
	return "neutral"

func give_gift(player_id: String, npc_id: String, item_id: String, _override_pstate = null) -> Dictionary:
	var p_state = _override_pstate if _override_pstate else _get_player_state(player_id)
	if not p_state:
		return { "success": false, "error": "Player state not found" }
		
	if not can_give_gift(player_id, npc_id, item_id, _override_pstate):
		return { "success": false, "error": "Cannot give gift (limit reached or missing item)" }
		
	var reaction = get_gift_reaction_type(npc_id, item_id)
	var pts_map = { "loved": 80, "liked": 45, "neutral": 20, "disliked": -20, "hated": -40 }
	var pts = int(pts_map.get(reaction, 20))
	
	p_state.remove_item(item_id, 1)
	p_state.daily_gifted_npcs[npc_id] = true
	
	var old_hearts = p_state.get_heart_level(npc_id)
	var new_pts = p_state.add_friendship(npc_id, pts, "gift")
	var new_hearts = p_state.get_heart_level(npc_id)
	
	var EventBus = get_node_or_null("/root/EventBus")
	if EventBus: EventBus.friendship_changed.emit(player_id, npc_id, new_pts)
	
	var unlocked_milestones = []
	if new_hearts > old_hearts:
		unlocked_milestones = check_and_grant_heart_milestones(player_id, npc_id, _override_pstate)
		
	return {
		"success": true,
		"reaction": reaction,
		"points_added": pts,
		"new_total": new_pts,
		"new_heart_level": new_hearts,
		"milestones_unlocked": unlocked_milestones
	}

func check_and_grant_heart_milestones(player_id: String, npc_id: String, _override_pstate = null) -> Array[Dictionary]:
	var p_state = _override_pstate if _override_pstate else _get_player_state(player_id)
	if not p_state: return []
	
	var cur_heart = p_state.get_heart_level(npc_id)
	var claimed: Array = p_state.claimed_heart_milestones.get(npc_id, [])
	var newly_claimed: Array[Dictionary] = []
	
	var npc_ms: Array = milestones_catalog.get(npc_id, [])
	
	for ms in npc_ms:
		var req_h = int(ms.get("heart_level", 1))
		if cur_heart >= req_h and req_h not in claimed:
			claimed.append(req_h)
			var rew = ms.get("rewards", {})
			RewardManager.grant_rewards(rew, p_state)
			newly_claimed.append({ "npc_id": npc_id, "heart_level": req_h, "rewards": rew })
			
			var EventBus = get_node_or_null("/root/EventBus")
			if EventBus and EventBus.has_signal("heart_milestone_unlocked"):
				EventBus.heart_milestone_unlocked.emit(player_id, npc_id, req_h, rew)
			
	p_state.claimed_heart_milestones[npc_id] = claimed
	return newly_claimed
