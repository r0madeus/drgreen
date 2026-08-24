class_name BaseComponent
extends RefCounted

## Base Class for all Data-Driven Components in Botanical Haven (Phase 41).
## Encapsulates state, lifecycle hooks, event routing, and serialization.

var comp_type: String = ""
var data: Dictionary = {}
var entity: Variant = null

func _init(p_type: String = "", p_data: Dictionary = {}) -> void:
	comp_type = p_type
	data = p_data.duplicate(true)

func on_create(p_entity: Variant) -> void:
	entity = p_entity

func on_load(p_entity: Variant, p_data: Dictionary) -> void:
	entity = p_entity
	data = p_data.duplicate(true)

func on_ready() -> void:
	pass

func on_event(event_type: String, payload: Dictionary = {}) -> void:
	pass

func on_destroy() -> void:
	entity = null

func get_property(key: String, default_val: Variant = null) -> Variant:
	return data.get(key, default_val)

func set_property(key: String, value: Variant) -> void:
	data[key] = value

func to_dict() -> Dictionary:
	return data.duplicate(true)

static func from_dict(p_type: String, d: Dictionary) -> Variant:
	var comp = (load("res://core/components/base_component.gd") as GDScript).new(p_type, d)
	return comp
