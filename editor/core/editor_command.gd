class_name EditorCommand
extends RefCounted

## Reversible Command pattern action for the In-Game Editor.
## Encapsulates stable ID, property keys, previous values, and new values.

var action_id: String = ""
var stable_id: String = ""
var property_key: String = ""
var old_value: Variant = null
var new_value: Variant = null
var timestamp: float = 0.0
var description: String = ""

func _init(p_stable_id: String = "", p_prop: String = "", p_old: Variant = null, p_new: Variant = null, p_desc: String = "") -> void:
	stable_id = p_stable_id
	property_key = p_prop
	old_value = p_old
	new_value = p_new
	description = p_desc
	timestamp = Time.get_unix_time_from_system()
	action_id = "%s:%s:%d" % [stable_id, property_key, int(timestamp * 1000)]

func execute(data_service: Variant) -> void:
	if data_service and data_service.has_method("set_staged_override"):
		data_service.set_staged_override(stable_id, property_key, new_value, false)

func undo(data_service: Variant) -> void:
	if data_service and data_service.has_method("set_staged_override"):
		if old_value != null:
			data_service.set_staged_override(stable_id, property_key, old_value, false)
		elif data_service.has_method("restore_default"):
			data_service.restore_default(stable_id, property_key, false)

func to_dict() -> Dictionary:
	return {
		"action_id": action_id,
		"stable_id": stable_id,
		"property_key": property_key,
		"old_value": old_value,
		"new_value": new_value,
		"timestamp": timestamp,
		"description": description
	}
