class_name GameplayTrigger
extends RefCounted

## Generic Gameplay Trigger linking Events, Conditions, and Action Sequences (Phase 39).
## Handles one-shot restrictions, cooldown intervals, priority ranking, and event filtering.

const COND_SCRIPT = preload("res://core/gameplay/gameplay_condition.gd")
const ACT_SCRIPT = preload("res://core/gameplay/gameplay_action.gd")

var trigger_id: String = ""
var name: String = ""
var event_type: String = ""
var condition: Dictionary = {}
var actions: Array = []
var priority: int = 100
var once: bool = false
var cooldown: float = 0.0
var enabled: bool = true

var fire_count: int = 0
var last_fired_time: float = 0.0

func _init(p_id: String = "", p_event: String = "", p_cond: Dictionary = {}, p_actions: Array = []) -> void:
	trigger_id = p_id if p_id != "" else "trig_%d" % int(Time.get_unix_time_from_system())
	name = trigger_id.capitalize()
	event_type = p_event
	condition = p_cond.duplicate(true)
	actions = p_actions.duplicate(true)

func can_fire(event: Variant, context: Dictionary) -> bool:
	if not enabled: return false
	if once and fire_count > 0: return false
	
	if event_type != "" and event != null:
		var et = str(event.get("event_type", "")) if event is Dictionary else (event.event_type if "event_type" in event else "")
		if et != event_type and event_type != "all" and event_type != "*":
			return false
			
	if cooldown > 0.0:
		var now = Time.get_unix_time_from_system()
		if (now - last_fired_time) < cooldown:
			return false
			
	# Merge event data into temporary context for condition evaluation
	var eval_context = context.duplicate(true)
	if event is Dictionary:
		eval_context["event"] = event
	elif event != null and "payload" in event:
		eval_context["event"] = {
			"type": event.event_type,
			"source": event.source,
			"target": event.target,
			"payload": event.payload,
			"context": event.context
		}
		
	return COND_SCRIPT.evaluate(condition, eval_context)

func fire(event: Variant, context: Dictionary) -> Dictionary:
	if not can_fire(event, context):
		return { "fired": false, "reason": "Condition not met or on cooldown" }
		
	var now = Time.get_unix_time_from_system()
	last_fired_time = now
	fire_count += 1
	
	var eval_context = context
	if event is Dictionary:
		eval_context["event"] = event
	elif event != null and "payload" in event:
		eval_context["event"] = {
			"type": event.event_type,
			"source": event.source,
			"target": event.target,
			"payload": event.payload,
			"context": event.context
		}
		
	var results = ACT_SCRIPT.execute_sequence(actions, eval_context)
	return {
		"fired": true,
		"trigger_id": trigger_id,
		"results": results
	}

func to_dict() -> Dictionary:
	return {
		"trigger_id": trigger_id,
		"name": name,
		"event_type": event_type,
		"condition": condition.duplicate(true),
		"actions": actions.duplicate(true),
		"priority": priority,
		"once": once,
		"cooldown": cooldown,
		"enabled": enabled,
		"fire_count": fire_count,
		"last_fired_time": last_fired_time
	}

static func from_dict(d: Dictionary) -> Variant:
	var trig = (load("res://core/gameplay/gameplay_trigger.gd") as GDScript).new(
		str(d.get("trigger_id", d.get("id", ""))),
		str(d.get("event_type", d.get("event", ""))),
		d.get("condition", {}),
		d.get("actions", [])
	)
	trig.name = str(d.get("name", trig.trigger_id.capitalize()))
	trig.priority = int(d.get("priority", 100))
	trig.once = bool(d.get("once", false))
	trig.cooldown = float(d.get("cooldown", 0.0))
	trig.enabled = bool(d.get("enabled", true))
	trig.fire_count = int(d.get("fire_count", 0))
	trig.last_fired_time = float(d.get("last_fired_time", 0.0))
	return trig
