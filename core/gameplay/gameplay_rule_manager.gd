class_name GameplayRuleManager
extends RefCounted

## Central Gameplay Rule Management & Event Bus Service (Phase 39).
## Authoritative for global flags, game variables, trigger dispatching, priority sorting, and state persistence.

signal event_dispatched(event: Variant)
signal trigger_fired(trigger_id: String, results: Array)
signal flag_changed(flag_name: String, new_value: Variant)
signal variable_changed(var_name: String, new_value: Variant)

const EVENT_SCRIPT = preload("res://core/gameplay/gameplay_event.gd")
const TRIG_SCRIPT = preload("res://core/gameplay/gameplay_trigger.gd")

static var _instance: Variant = null

var triggers: Dictionary = {} # trigger_id -> GameplayTrigger
var flags: Dictionary = {} # flag_name -> Variant
var variables: Dictionary = {} # var_name -> Variant
var timers: Dictionary = {} # timer_name -> Dictionary { duration, remaining, active }
var counters: Dictionary = {} # counter_name -> int
var event_history: Array = []
var max_history: int = 50

static func get_instance() -> Variant:
	if not _instance:
		_instance = (load("res://core/gameplay/gameplay_rule_manager.gd") as GDScript).new()
	return _instance

func register_trigger(trig: Variant) -> void:
	if trig and "trigger_id" in trig:
		triggers[trig.trigger_id] = trig

func unregister_trigger(trig_id: String) -> bool:
	return triggers.erase(trig_id)

func get_trigger(trig_id: String) -> Variant:
	return triggers.get(trig_id, null)

func get_all_triggers() -> Array:
	return triggers.values()

func dispatch_event(event: Variant) -> Array[Dictionary]:
	if not event: return []
	
	event_history.append(event)
	if event_history.size() > max_history:
		event_history.pop_front()
		
	event_dispatched.emit(event)
	
	var context = get_execution_context()
	var sorted_trigs: Array = []
	for t in triggers.values():
		if t.enabled:
			sorted_trigs.append(t)
			
	sorted_trigs.sort_custom(func(a, b): return a.priority > b.priority)
	
	var all_results: Array[Dictionary] = []
	for t in sorted_trigs:
		if t.can_fire(event, context):
			var res = t.fire(event, context)
			all_results.append(res)
			trigger_fired.emit(t.trigger_id, res.get("results", []))
			
			# Check if any action chained another event
			for action_res in res.get("results", []):
				var chained_evt = action_res.get("data", {}).get("dispatched_event", "")
				if chained_evt != "":
					var chained_payload = action_res.get("data", {}).get("payload", {})
					var new_evt = EVENT_SCRIPT.new(chained_evt, t.trigger_id, "", chained_payload)
					var sub_res = dispatch_event(new_evt)
					all_results.append_array(sub_res)
					
	return all_results

func dispatch(event_type: String, source: String = "", target: String = "", payload: Dictionary = {}, p_context: Dictionary = {}) -> Array[Dictionary]:
	var evt = EVENT_SCRIPT.new(event_type, source, target, payload, p_context)
	return dispatch_event(evt)

func set_flag(flag_name: String, value: Variant = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)

func get_flag(flag_name: String, default_val: Variant = false) -> Variant:
	return flags.get(flag_name, default_val)

func clear_flag(flag_name: String) -> void:
	if flags.has(flag_name):
		flags.erase(flag_name)
		flag_changed.emit(flag_name, false)

func set_variable(var_name: String, value: Variant) -> void:
	variables[var_name] = value
	variable_changed.emit(var_name, value)

func get_variable(var_name: String, default_val: Variant = null) -> Variant:
	return variables.get(var_name, default_val)

func start_timer(timer_name: String, duration: float) -> void:
	timers[timer_name] = {
		"duration": duration,
		"remaining": duration,
		"active": true
	}

func stop_timer(timer_name: String) -> void:
	if timers.has(timer_name):
		timers[timer_name]["active"] = false

func is_timer_active(timer_name: String) -> bool:
	return timers.has(timer_name) and timers[timer_name].get("active", false)

func update_timers(delta: float) -> Array[String]:
	var completed: Array[String] = []
	for tname in timers.keys():
		var t = timers[tname]
		if t.get("active", false):
			var rem = float(t.get("remaining", 0.0)) - delta
			if rem <= 0.0:
				t["remaining"] = 0.0
				t["active"] = false
				completed.append(tname)
				dispatch("timer.completed", tname, "", { "timer_name": tname })
			else:
				t["remaining"] = rem
	return completed

func set_counter(counter_name: String, val: int) -> void:
	counters[counter_name] = val

func get_counter(counter_name: String, default_val: int = 0) -> int:
	return int(counters.get(counter_name, default_val))

func increment_counter(counter_name: String, delta: int = 1) -> int:
	var cur = get_counter(counter_name, 0)
	counters[counter_name] = cur + delta
	return cur + delta

func get_execution_context() -> Dictionary:
	return {
		"flags": flags,
		"variables": variables,
		"timers": timers,
		"counters": counters,
		"timestamp": Time.get_unix_time_from_system()
	}

func get_state() -> Dictionary:
	var trig_states: Dictionary = {}
	for tid in triggers:
		var t = triggers[tid]
		trig_states[tid] = {
			"fire_count": t.fire_count,
			"last_fired_time": t.last_fired_time,
			"enabled": t.enabled
		}
	return {
		"flags": flags.duplicate(true),
		"variables": variables.duplicate(true),
		"trigger_states": trig_states
	}

func set_state(state: Dictionary) -> void:
	flags = state.get("flags", {}).duplicate(true)
	variables = state.get("variables", {}).duplicate(true)
	var trig_states = state.get("trigger_states", {})
	for tid in trig_states:
		if triggers.has(tid):
			var t = triggers[tid]
			var ts = trig_states[tid]
			t.fire_count = int(ts.get("fire_count", 0))
			t.last_fired_time = float(ts.get("last_fired_time", 0.0))
			t.enabled = bool(ts.get("enabled", true))

func clear_all() -> void:
	triggers.clear()
	flags.clear()
	variables.clear()
	event_history.clear()
