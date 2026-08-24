class_name GameplayEvent
extends RefCounted

## Generic Gameplay Event Data Container (Phase 39).
## Represents an atomic game event across any genre (farming, RPG, simulation, adventure).

var event_id: String = ""
var event_type: String = ""
var source: String = ""
var target: String = ""
var payload: Dictionary = {}
var context: Dictionary = {}
var timestamp: float = 0.0
var authority: String = "local" # "local", "server", "client"
var replication: String = "none" # "none", "all", "others"

func _init(p_type: String = "", p_source: String = "", p_target: String = "", p_payload: Dictionary = {}, p_context: Dictionary = {}) -> void:
	event_id = "evt_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 10000]
	event_type = p_type
	source = p_source
	target = p_target
	payload = p_payload.duplicate(true)
	context = p_context.duplicate(true)
	timestamp = Time.get_unix_time_from_system()

func to_dict() -> Dictionary:
	return {
		"event_id": event_id,
		"event_type": event_type,
		"source": source,
		"target": target,
		"payload": payload.duplicate(true),
		"context": context.duplicate(true),
		"timestamp": timestamp,
		"authority": authority,
		"replication": replication
	}

static func from_dict(d: Dictionary) -> Variant:
	var evt = (load("res://core/gameplay/gameplay_event.gd") as GDScript).new(
		str(d.get("event_type", "")),
		str(d.get("source", "")),
		str(d.get("target", "")),
		d.get("payload", {}),
		d.get("context", {})
	)
	if d.has("event_id"): evt.event_id = str(d["event_id"])
	if d.has("timestamp"): evt.timestamp = float(d["timestamp"])
	if d.has("authority"): evt.authority = str(d["authority"])
	if d.has("replication"): evt.replication = str(d["replication"])
	return evt
