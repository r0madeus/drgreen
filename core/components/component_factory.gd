class_name ComponentFactory
extends RefCounted

## Factory & Logic Helpers for Generic Gameplay Components (Phase 41).

# 1. Health & Damage Logic
static func apply_damage(health_data: Dictionary, amount: float, damage_type: String = "physical") -> Dictionary:
	var cur = float(health_data.get("current_health", 100.0))
	var max_h = float(health_data.get("max_health", 100.0))
	var new_health = max(0.0, cur - amount)
	health_data["current_health"] = new_health
	var died = (new_health <= 0.0 and cur > 0.0)
	return {
		"damage": amount,
		"new_health": new_health,
		"max_health": max_h,
		"damage_type": damage_type,
		"died": died
	}

static func apply_heal(health_data: Dictionary, amount: float) -> Dictionary:
	var cur = float(health_data.get("current_health", 100.0))
	var max_h = float(health_data.get("max_health", 100.0))
	var new_health = min(max_h, cur + amount)
	health_data["current_health"] = new_health
	return {
		"healed": amount,
		"new_health": new_health,
		"max_health": max_h
	}

# 2. Inventory Logic
static func inventory_add(inv_data: Dictionary, item_id: String, count: int = 1) -> bool:
	if not inv_data.has("items"): inv_data["items"] = {}
	var items = inv_data["items"]
	var cur = int(items.get(item_id, 0))
	items[item_id] = cur + count
	return true

static func inventory_remove(inv_data: Dictionary, item_id: String, count: int = 1) -> bool:
	if not inv_data.has("items"): return false
	var items = inv_data["items"]
	var cur = int(items.get(item_id, 0))
	if cur < count: return false
	if cur == count:
		items.erase(item_id)
	else:
		items[item_id] = cur - count
	return true

static func inventory_count(inv_data: Dictionary, item_id: String) -> int:
	if not inv_data.has("items"): return 0
	return int(inv_data["items"].get(item_id, 0))

# 3. State Machine Logic
static func transition_state(state_data: Dictionary, target_state: String) -> Dictionary:
	var cur = str(state_data.get("current_state", "idle"))
	var states: Array = state_data.get("states", ["idle", "active"])
	
	if states.is_empty() or states.has(target_state):
		state_data["current_state"] = target_state
		return { "success": true, "from": cur, "to": target_state }
	return { "success": false, "from": cur, "to": cur, "error": "Invalid state '%s'" % target_state }

# 4. Timer Logic
static func start_timer(timer_data: Dictionary, timer_name: String, duration: float) -> void:
	if not timer_data.has("timers"): timer_data["timers"] = {}
	timer_data["timers"][timer_name] = {
		"duration": duration,
		"remaining": duration,
		"active": true
	}

static func update_timers(timer_data: Dictionary, delta: float) -> Array[String]:
	var completed: Array[String] = []
	if not timer_data.has("timers"): return completed
	
	var timers = timer_data["timers"]
	for tname in timers.keys():
		var t = timers[tname]
		if t.get("active", false):
			var rem = float(t.get("remaining", 0.0)) - delta
			if rem <= 0.0:
				t["remaining"] = 0.0
				t["active"] = false
				completed.append(tname)
			else:
				t["remaining"] = rem
	return completed

# 5. Stats & Modifiers Logic
static func calculate_stat(stats_data: Dictionary, stat_name: String, default_val: float = 10.0) -> float:
	var base_val = float(stats_data.get("base", {}).get(stat_name, default_val))
	var mods = stats_data.get("modifiers", {}).get(stat_name, [])
	
	var flat_sum = 0.0
	var pct_sum = 0.0
	if mods is Array:
		for m in mods:
			if m is Dictionary:
				if m.get("is_pct", false):
					pct_sum += float(m.get("value", 0.0))
				else:
					flat_sum += float(m.get("value", 0.0))
					
	return (base_val + flat_sum) * (1.0 + pct_sum / 100.0)

# 6. Destructible Logic
static func apply_impact(dest_data: Dictionary, damage: float) -> Dictionary:
	var dur = float(dest_data.get("durability", 50.0))
	var cracked_th = float(dest_data.get("cracked_threshold", 25.0))
	var new_dur = max(0.0, dur - damage)
	dest_data["durability"] = new_dur
	
	var is_destroyed = (new_dur <= 0.0)
	var is_cracked = (new_dur <= cracked_th and not is_destroyed)
	return {
		"damage": damage,
		"remaining_durability": new_dur,
		"is_cracked": is_cracked,
		"is_destroyed": is_destroyed,
		"drop_item": str(dest_data.get("drop_item", ""))
	}
