class_name PlayerState
extends RefCounted

## Represents the individual, personal state of a player in single-player or co-op multiplayer.
## Holds inventory, equipment, personal currency, stamina, world position, friendship points,
## heart levels, daily gift/talk records, and claimed milestones.

signal inventory_changed()
signal hotbar_changed()
signal hotbar_slot_selected(slot_index: int, item_id: String)
signal hotbar_cycled(delta: int, new_slot: int)
signal item_selected(item_id: String)
signal tool_selected(tool_id: String)
signal gold_changed(new_gold: int)
signal energy_changed(current: float, max_val: float)
signal player_upgraded(upgrade_id: String)
signal friendship_updated(npc_id: String, new_points: int, heart_level: int)
signal heart_milestone_unlocked(npc_id: String, heart_level: int, rewards: Dictionary)

var player_id: String = "player_001"
var display_name: String = "Botanist"

var current_world: String = "farm"
var position: Vector2 = Vector2.ZERO
var facing_direction = Vector2.DOWN
var grid_position = Vector2i(15, 10)


var hotbar_slots: Array = ["hoe_basic", "watering_can_basic", "axe_basic", "pickaxe_basic", "seed_red_flower", "seed_blue_flower", "seed_yellow_herb", "", "", ""]
var selected_hotbar_slot: int = 0

var inventory: Dictionary = {} # item_id (String) -> quantity (int)
var selected_item_id: String = "hoe_basic"
var equipment: Dictionary = {}
var gold: int = 100
var energy: float = 100.0
var max_energy: float = 100.0
var purchased_upgrades: Array[String] = []

var personal_quests: Dictionary = {} # quest_id -> state
var statistics: Dictionary = {}
var friendship: Dictionary = {} # npc_id (String) -> int (points)
var daily_talked_npcs: Dictionary = {} # npc_id (String) -> bool
var daily_gifted_npcs: Dictionary = {} # npc_id (String) -> bool
var claimed_heart_milestones: Dictionary = {} # npc_id (String) -> Array (levels claimed)
var personal_dialogue_history: Dictionary = {} # npc_id (String) -> Array[String] (node keys seen)
var personal_claimed_rewards: Dictionary = {} # reward_id / quest_id -> bool

func _init(p_id: String = "player_001", p_name: String = "Botanist") -> void:
	player_id = p_id
	display_name = p_name

func init_starter_kit() -> void:
	inventory.clear()
	inventory["hoe_basic"] = 1
	inventory["watering_can_basic"] = 1
	inventory["axe_basic"] = 1
	inventory["pickaxe_basic"] = 1
	inventory["seed_red_flower"] = 5
	inventory["seed_blue_flower"] = 3
	inventory["seed_yellow_herb"] = 4
	inventory["seed_green_vine"] = 2
	inventory["seed_white_lily"] = 2
	
	hotbar_slots = ["hoe_basic", "watering_can_basic", "axe_basic", "pickaxe_basic", "seed_red_flower", "seed_blue_flower", "seed_yellow_herb", "", "", ""]
	selected_hotbar_slot = 0
	selected_item_id = "hoe_basic"
	
	gold = 100
	energy = 100.0
	max_energy = 100.0
	current_world = "farm"
	position = Vector2(240, 160)
	inventory_changed.emit()
	hotbar_changed.emit()

# --- Relationship & Heart API ---

func get_friendship_points(npc_id: String) -> int:
	return int(friendship.get(npc_id, 0))

func get_friendship(npc_id: String) -> int:
	return get_friendship_points(npc_id)

func get_heart_level(npc_id: String) -> int:
	var pts = get_friendship_points(npc_id)
	return clampi(int(floor(float(pts) / 100.0)), 0, 5)

func get_heart_progress(npc_id: String) -> Dictionary:
	var pts = get_friendship_points(npc_id)
	var current_lvl = get_heart_level(npc_id)
	var points_in_level = pts % 100 if current_lvl < 5 else 100
	var next_threshold = (current_lvl + 1) * 100 if current_lvl < 5 else 500
	return {
		"current_level": current_lvl,
		"total_points": pts,
		"points_in_level": points_in_level,
		"next_threshold": next_threshold,
		"is_max": current_lvl >= 5
	}

func can_gain_talk_friendship(npc_id: String) -> bool:
	return not bool(daily_talked_npcs.get(npc_id, false))

func add_friendship(npc_id: String, points: int = 10, reason: String = "generic") -> int:
	if npc_id.is_empty(): return 0
	
	var old_hearts = get_heart_level(npc_id)
	var pts_to_add = points
	
	if reason == "talk":
		if not can_gain_talk_friendship(npc_id):
			pts_to_add = 0
		else:
			daily_talked_npcs[npc_id] = true
			
	var current_pts = int(friendship.get(npc_id, 0))
	var new_pts = maxi(0, current_pts + pts_to_add)
	friendship[npc_id] = new_pts
	
	var new_hearts = get_heart_level(npc_id)
	friendship_updated.emit(npc_id, new_pts, new_hearts)
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var eb = root.get_node_or_null("/root/EventBus") if root else null
	if eb: eb.friendship_changed.emit(npc_id, new_pts)
	
	if new_hearts > old_hearts:
		check_and_grant_heart_milestones(npc_id)
		
	return new_pts

func reset_daily_social_limits() -> void:
	daily_talked_npcs.clear()
	daily_gifted_npcs.clear()

# --- Gifting API ---

func can_give_gift(npc_id: String, item_id: String) -> bool:
	if npc_id.is_empty() or item_id.is_empty(): return false
	if bool(daily_gifted_npcs.get(npc_id, false)): return false
	if not has_item(item_id, 1): return false
	return true

func get_gift_reaction_type(npc_id: String, item_id: String) -> String:
	var path = "res://data/npcs/preferences.json"
	if not FileAccess.file_exists(path): return "neutral"
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return "neutral"
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY: return "neutral"
	
	var all_prefs = json.data.get("preferences", {})
	var npc_prefs = all_prefs.get(npc_id, {})
	
	if item_id in npc_prefs.get("loved", []): return "loved"
	if item_id in npc_prefs.get("liked", []): return "liked"
	if item_id in npc_prefs.get("disliked", []): return "disliked"
	if item_id in npc_prefs.get("hated", []): return "hated"
	return "neutral"

func give_gift(npc_id: String, item_id: String) -> Dictionary:
	if not can_give_gift(npc_id, item_id):
		return { "success": false, "error": "Cannot give gift (limit reached or missing item)" }
		
	var reaction = get_gift_reaction_type(npc_id, item_id)
	var pts_map = { "loved": 80, "liked": 45, "neutral": 20, "disliked": -20, "hated": -40 }
	var pts = int(pts_map.get(reaction, 20))
	
	remove_item(item_id, 1)
	daily_gifted_npcs[npc_id] = true
	
	var old_hearts = get_heart_level(npc_id)
	var new_pts = add_friendship(npc_id, pts, "gift")
	var new_hearts = get_heart_level(npc_id)
	
	var unlocked_milestones = []
	if new_hearts > old_hearts:
		unlocked_milestones = check_and_grant_heart_milestones(npc_id)
		
	return {
		"success": true,
		"reaction": reaction,
		"points_added": pts,
		"new_total": new_pts,
		"new_heart_level": new_hearts,
		"milestones_unlocked": unlocked_milestones
	}

# --- Heart Milestone Unlocks ---

func check_and_grant_heart_milestones(npc_id: String) -> Array[Dictionary]:
	var cur_heart = get_heart_level(npc_id)
	var claimed: Array = claimed_heart_milestones.get(npc_id, [])
	var newly_claimed: Array[Dictionary] = []
	
	var path = "res://data/npcs/milestones.json"
	if not FileAccess.file_exists(path): return []
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return []
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY: return []
	
	var all_milestones = json.data.get("milestones", {})
	var npc_ms: Array = all_milestones.get(npc_id, [])
	
	for ms in npc_ms:
		var req_h = int(ms.get("heart_level", 1))
		if cur_heart >= req_h and req_h not in claimed:
			claimed.append(req_h)
			var rew = ms.get("rewards", {})
			RewardManager.grant_rewards(rew, self)
			newly_claimed.append({ "npc_id": npc_id, "heart_level": req_h, "rewards": rew })
			heart_milestone_unlocked.emit(npc_id, req_h, rew)
			
	claimed_heart_milestones[npc_id] = claimed
	return newly_claimed

func get_relationship_state(npc_id: String) -> Dictionary:
	var progress = get_heart_progress(npc_id)
	return {
		"npc_id": npc_id,
		"friendship_points": get_friendship_points(npc_id),
		"heart_level": get_heart_level(npc_id),
		"progress": progress,
		"can_talk": can_gain_talk_friendship(npc_id),
		"can_gift": not bool(daily_gifted_npcs.get(npc_id, false)),
		"claimed_milestones": claimed_heart_milestones.get(npc_id, [])
	}

# --- Personal Dialogue & Reward Tracking ---

func has_claimed_reward(reward_id: String) -> bool:
	return bool(personal_claimed_rewards.get(reward_id, false))

func mark_reward_claimed(reward_id: String) -> void:
	personal_claimed_rewards[reward_id] = true

func record_dialogue_seen(npc_id: String, node_key: String) -> void:
	if not personal_dialogue_history.has(npc_id):
		personal_dialogue_history[npc_id] = []
	if not personal_dialogue_history[npc_id].has(node_key):
		personal_dialogue_history[npc_id].append(node_key)

func has_seen_dialogue(npc_id: String, node_key: String) -> bool:
	return personal_dialogue_history.has(npc_id) and personal_dialogue_history[npc_id].has(node_key)

# --- Inventory API ---

func add_item(item_id: String, quantity: int = 1) -> void:
	if quantity <= 0 or item_id == "": return
	inventory[item_id] = inventory.get(item_id, 0) + quantity
	inventory_changed.emit()

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not has_item(item_id, quantity): return false
	inventory[item_id] -= quantity
	if inventory[item_id] <= 0:
		inventory.erase(item_id)
		if selected_item_id == item_id:
			_auto_select_next_item()
	inventory_changed.emit()
	return true

func has_item(item_id: String, quantity: int = 1) -> bool:
	return inventory.get(item_id, 0) >= quantity

func get_item_count(item_id: String) -> int:
	return inventory.get(item_id, 0)

func get_all_items() -> Dictionary:
	return inventory.duplicate()

func select_item(item_id: String) -> void:
	if has_item(item_id) or item_id == "":
		selected_item_id = item_id
		item_selected.emit(selected_item_id)

func get_selected_item() -> String:
	return selected_item_id

func _auto_select_next_item() -> void:
	var keys = inventory.keys()
	if keys.size() > 0:
		selected_item_id = keys[0]
	else:
		selected_item_id = ""
	item_selected.emit(selected_item_id)

# --- Hotbar API ---

func set_hotbar_slot(slot_index: int, item_id: String) -> void:
	if slot_index >= 0 and slot_index < hotbar_slots.size():
		hotbar_slots[slot_index] = item_id
		hotbar_changed.emit()

func get_hotbar_slot(slot_index: int) -> String:
	if slot_index >= 0 and slot_index < hotbar_slots.size():
		return hotbar_slots[slot_index]
	return ""

func select_hotbar_slot(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < hotbar_slots.size():
		selected_hotbar_slot = slot_index
		var item_id = hotbar_slots[slot_index]
		selected_item_id = item_id
		hotbar_changed.emit()
		item_selected.emit(selected_item_id)
		hotbar_slot_selected.emit(slot_index, item_id)


func cycle_hotbar_slot(delta: int) -> int:
	var total = hotbar_slots.size()
	if total == 0: return 0
	var new_slot = (selected_hotbar_slot + delta) % total
	if new_slot < 0: new_slot += total
	select_hotbar_slot(new_slot)
	hotbar_cycled.emit(delta, new_slot)
	return new_slot

# --- Currency / Energy API ---

func set_gold(amount: int) -> void:
	gold = maxi(0, amount)
	gold_changed.emit(gold)

func get_gold() -> int:
	return gold

func add_gold(amount: int) -> void:
	if amount <= 0: return
	gold += amount
	gold_changed.emit(gold)

func remove_gold(amount: int) -> bool:
	if amount <= 0 or gold < amount: return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func spend_gold(amount: int) -> bool:
	return remove_gold(amount)

func set_energy(amount: float) -> void:
	energy = clampi(amount, 0.0, max_energy)
	energy_changed.emit(energy, max_energy)

func get_energy() -> float:
	return energy

func consume_energy(amount: float) -> bool:
	if energy < amount: return false
	energy = maxf(0.0, energy - amount)
	energy_changed.emit(energy, max_energy)
	return true

func use_energy(amount: float) -> bool:
	return consume_energy(amount)

func restore_energy(amount: float) -> void:
	energy = minf(max_energy, energy + amount)
	energy_changed.emit(energy, max_energy)


# --- Serialization ---

func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"display_name": display_name,
		"current_world": current_world,
		"position": [position.x, position.y],
		"position_space": "world",
		"inventory": inventory.duplicate(true),
		"hotbar_slots": hotbar_slots.duplicate(true),
		"selected_hotbar_slot": selected_hotbar_slot,
		"selected_item_id": selected_item_id,
		"equipment": equipment.duplicate(true),
		"gold": gold,
		"energy": energy,
		"max_energy": max_energy,
		"purchased_upgrades": purchased_upgrades.duplicate(),
		"personal_quests": personal_quests.duplicate(true),
		"statistics": statistics.duplicate(true),
		"friendship": friendship.duplicate(true),
		"daily_talked_npcs": daily_talked_npcs.duplicate(true),
		"daily_gifted_npcs": daily_gifted_npcs.duplicate(true),
		"claimed_heart_milestones": claimed_heart_milestones.duplicate(true),
		"personal_dialogue_history": personal_dialogue_history.duplicate(true),
		"personal_claimed_rewards": personal_claimed_rewards.duplicate(true)
	}

static func from_dict(data: Dictionary) -> PlayerState:
	var state = PlayerState.new(data.get("player_id", "player_001"), data.get("display_name", "Botanist"))
	state.current_world = str(data.get("current_world", "farm"))
	
	var pspace = str(data.get("position_space", "grid"))
	var raw_pos = data.get("position", [16, 12])
	if raw_pos is Array and raw_pos.size() >= 2:
		if pspace == "grid":
			state.position = Vector2(float(raw_pos[0]) * 16.0 + 8.0, float(raw_pos[1]) * 16.0 + 8.0)
		else:
			state.position = Vector2(float(raw_pos[0]), float(raw_pos[1]))
			
	state.inventory = data.get("inventory", {}).duplicate(true)
	state.hotbar_slots = data.get("hotbar_slots", []).duplicate(true)
	state.selected_hotbar_slot = int(data.get("selected_hotbar_slot", 0))
	state.selected_item_id = str(data.get("selected_item_id", ""))
	state.equipment = data.get("equipment", {}).duplicate(true)
	state.gold = int(data.get("gold", 100))
	state.energy = float(data.get("energy", 100.0))
	state.max_energy = float(data.get("max_energy", 100.0))
	state.purchased_upgrades = Array(data.get("purchased_upgrades", []), TYPE_STRING, "", null)
	state.personal_quests = data.get("personal_quests", {}).duplicate(true)
	state.statistics = data.get("statistics", {}).duplicate(true)
	state.friendship = data.get("friendship", {}).duplicate(true)
	state.daily_talked_npcs = data.get("daily_talked_npcs", {}).duplicate(true)
	state.daily_gifted_npcs = data.get("daily_gifted_npcs", {}).duplicate(true)
	state.claimed_heart_milestones = data.get("claimed_heart_milestones", {}).duplicate(true)
	state.personal_dialogue_history = data.get("personal_dialogue_history", {}).duplicate(true)
	state.personal_claimed_rewards = data.get("personal_claimed_rewards", {}).duplicate(true)
	return state
