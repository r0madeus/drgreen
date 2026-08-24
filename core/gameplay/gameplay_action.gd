class_name GameplayAction
extends RefCounted

## Universal Data-Driven Gameplay Action & Sequence Executor (Phase 39).
## Executes atomic actions, handles variable manipulation, conditional branching, and event chaining.

const COND_SCRIPT = preload("res://core/gameplay/gameplay_condition.gd")
const FACTORY_SCRIPT = preload("res://core/components/component_factory.gd")

static func execute(action: Variant, context: Dictionary) -> Dictionary:
	if not (action is Dictionary): return { "success": false, "error": "Invalid action format" }
	
	var atype = str(action.get("type", action.get("action", ""))).to_lower()
	var result = {
		"type": atype,
		"success": true,
		"data": {},
		"output": ""
	}
	
	match atype:
		# 1. State & Flags
		"set_flag":
			var flag = str(action.get("flag", action.get("name", "")))
			var val = action.get("value", true)
			if not context.has("flags"): context["flags"] = {}
			context["flags"][flag] = val
			result["output"] = "Flag '%s' set to %s" % [flag, str(val)]
			
		"clear_flag":
			var flag = str(action.get("flag", action.get("name", "")))
			if context.has("flags") and context["flags"] is Dictionary:
				context["flags"].erase(flag)
			result["output"] = "Flag '%s' cleared" % flag
			
		"set_variable", "set_var":
			var vname = str(action.get("name", action.get("key", "")))
			var val = action.get("value", null)
			if not context.has("variables"): context["variables"] = {}
			context["variables"][vname] = val
			result["output"] = "Variable '%s' set to %s" % [vname, str(val)]
			
		"modify_variable", "modify_var", "add_var":
			var vname = str(action.get("name", action.get("key", "")))
			var delta = float(action.get("delta", action.get("amount", 1.0)))
			if not context.has("variables"): context["variables"] = {}
			var cur = float(context["variables"].get(vname, 0.0))
			context["variables"][vname] = cur + delta
			result["output"] = "Variable '%s' modified to %f" % [vname, cur + delta]

		# 2. Inventory & Items
		"add_item":
			var iid = str(action.get("item_id", action.get("item", "")))
			var count = int(action.get("count", action.get("amount", 1)))
			if not context.has("inventory"): context["inventory"] = {}
			var cur_c = int(context["inventory"].get(iid, 0))
			context["inventory"][iid] = cur_c + count
			result["output"] = "Added %d of %s" % [count, iid]
			
		"remove_item":
			var iid = str(action.get("item_id", action.get("item", "")))
			var count = int(action.get("count", action.get("amount", 1)))
			if not context.has("inventory"): context["inventory"] = {}
			var cur_c = int(context["inventory"].get(iid, 0))
			context["inventory"][iid] = max(0, cur_c - count)
			result["output"] = "Removed %d of %s" % [count, iid]

		# 3. Currency / Gold
		"add_currency", "add_gold":
			var amt = int(action.get("amount", action.get("gold", 100)))
			var cur_g = int(context.get("gold", context.get("currency", 0)))
			context["gold"] = cur_g + amt
			result["output"] = "Added %d currency (Total: %d)" % [amt, cur_g + amt]
			
		"remove_currency", "remove_gold":
			var amt = int(action.get("amount", action.get("gold", 100)))
			var cur_g = int(context.get("gold", context.get("currency", 0)))
			context["gold"] = max(0, cur_g - amt)
			result["output"] = "Removed %d currency (Total: %d)" % [amt, max(0, cur_g - amt)]

		# 4. Message & Feedback
		"show_message", "message", "log":
			var msg = str(action.get("text", action.get("message", "")))
			result["output"] = "Message: '%s'" % msg
			
		# 5. World & Travel
		"change_world", "teleport":
			var target_w = str(action.get("world", action.get("world_id", "")))
			context["current_world"] = target_w
			result["output"] = "World changed to '%s'" % target_w

		# 6. Dialogue & Quests
		"start_dialogue":
			var did = str(action.get("dialogue_id", action.get("dialogue", "")))
			context["active_dialogue"] = did
			result["output"] = "Dialogue started: '%s'" % did
			
		"start_quest":
			var qid = str(action.get("quest_id", action.get("quest", "")))
			if not context.has("quests"): context["quests"] = {}
			context["quests"][qid] = "active"
			result["output"] = "Quest started: '%s'" % qid
			
		"complete_quest":
			var qid = str(action.get("quest_id", action.get("quest", "")))
			if not context.has("quests"): context["quests"] = {}
			context["quests"][qid] = "completed"
			result["output"] = "Quest completed: '%s'" % qid

		# 7. Conditional Branching
		"branch", "if":
			var cond = action.get("condition", {})
			var passed = COND_SCRIPT.evaluate(cond, context)
			var sub_actions = action.get("if_true", []) if passed else action.get("if_false", [])
			if sub_actions is Array:
				var branch_results = execute_sequence(sub_actions, context)
				result["data"]["branch_passed"] = passed
				result["data"]["sub_results"] = branch_results
				result["output"] = "Branch %s -> %d actions executed" % ["TRUE" if passed else "FALSE", branch_results.size()]

		# 8. Event Triggering / Chaining
		"call_event", "dispatch_event":
			var etype = str(action.get("event_type", action.get("event", "")))
			var epayload = action.get("payload", {})
			result["output"] = "Dispatched event '%s'" % etype
			result["data"]["dispatched_event"] = etype
			result["data"]["payload"] = epayload

		# 9. Generic Component & Mechanic Actions (Phase 41)
		"damage_entity", "damage":
			var tgt = str(action.get("target", ""))
			var amt = float(action.get("amount", action.get("damage", 10.0)))
			var dtype = str(action.get("damage_type", "physical"))
			if not context.has("health"): context["health"] = {}
			var hres = FACTORY_SCRIPT.apply_damage(context["health"], amt, dtype)
			result["output"] = "Damaged target by %.1f (Remaining: %.1f)" % [amt, hres.get("new_health", 0.0)]
			result["data"] = hres
			
		"heal_entity", "heal":
			var amt = float(action.get("amount", 20.0))
			if not context.has("health"): context["health"] = {}
			var hres = FACTORY_SCRIPT.apply_heal(context["health"], amt)
			result["output"] = "Healed by %.1f (Current: %.1f)" % [amt, hres.get("new_health", 0.0)]
			result["data"] = hres

		"start_timer":
			var tname = str(action.get("timer", action.get("name", "timer_1")))
			var dur = float(action.get("duration", action.get("seconds", 5.0)))
			if not context.has("timers"): context["timers"] = {}
			FACTORY_SCRIPT.start_timer(context, tname, dur)
			result["output"] = "Timer '%s' started for %.1fs" % [tname, dur]

		"transition_state", "set_state":
			var target_st = str(action.get("state", action.get("target_state", "active")))
			if not context.has("state_machine"): context["state_machine"] = { "current_state": "idle" }
			var sres = FACTORY_SCRIPT.transition_state(context["state_machine"], target_st)
			result["output"] = "State transitioned from '%s' to '%s'" % [sres.get("from", ""), sres.get("to", "")]
			result["data"] = sres

		"increment_counter", "add_counter":
			var cname = str(action.get("counter", action.get("name", "counter_1")))
			var delta = int(action.get("delta", action.get("amount", 1)))
			if not context.has("counters"): context["counters"] = {}
			var cur_c = int(context["counters"].get(cname, 0))
			context["counters"][cname] = cur_c + delta
			result["output"] = "Counter '%s' updated to %d" % [cname, cur_c + delta]

		"drop_loot", "spawn_loot":
			var iid = str(action.get("item_id", action.get("item", "dungeon_key")))
			var count = int(action.get("count", 1))
			result["output"] = "Dropped loot: %d of %s" % [count, iid]
			result["data"] = { "dropped_item": iid, "count": count }

		_:
			result["output"] = "Executed action '%s'" % atype
			
	return result

static func execute_sequence(actions: Array, context: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for act in actions:
		var res = execute(act, context)
		results.append(res)
		if not res.get("success", true):
			if act.get("stop_on_failure", false):
				break
	return results
