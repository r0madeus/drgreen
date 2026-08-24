class_name GenericEntity
extends RefCounted

## Generic Data-Driven Component Entity (Phase 41).
## Eliminates hardcoded entity branching (e.g. if type == "enemy") in favor of
## dynamic component aggregation and capability resolution.

const REGISTRY_SCRIPT = preload("res://core/components/component_registry.gd")
const BASE_COMP_SCRIPT = preload("res://core/components/base_component.gd")

var entity_id: String = ""
var name: String = ""
var tags: Array[String] = []
var properties: Dictionary = {}
var components: Dictionary = {} # comp_type -> BaseComponent

func _init(p_id: String = "", p_name: String = "") -> void:
	entity_id = p_id if p_id != "" else "entity_%d" % int(Time.get_unix_time_from_system())
	name = p_name if p_name != "" else entity_id.capitalize()

func add_component(comp_type: String, initial_data: Dictionary = {}) -> Variant:
	if comp_type == "": return null
	
	var default_data = REGISTRY_SCRIPT.get_default_data(comp_type)
	default_data.merge(initial_data, true)
	
	var comp = (load("res://core/components/base_component.gd") as GDScript).new(comp_type, default_data)
	comp.on_create(self)
	components[comp_type] = comp
	return comp

func get_component(comp_type: String) -> Variant:
	return components.get(comp_type, null)

func get_component_data(comp_type: String) -> Dictionary:
	var c = get_component(comp_type)
	if c and "data" in c:
		return c.data
	return {}

func has_component(comp_type: String) -> bool:
	return components.has(comp_type)

func remove_component(comp_type: String) -> bool:
	if components.has(comp_type):
		var c = components[comp_type]
		c.on_destroy()
		components.erase(comp_type)
		return true
	return false

func get_capabilities() -> Array[String]:
	return REGISTRY_SCRIPT.get_capabilities_for_components(components.keys())

func has_capability(capability: String) -> bool:
	var caps = get_capabilities()
	return caps.has(capability)

func dispatch_event(event_type: String, payload: Dictionary = {}) -> void:
	for comp in components.values():
		comp.on_event(event_type, payload)

func to_dict() -> Dictionary:
	var comps_data: Dictionary = {}
	for k in components.keys():
		comps_data[k] = components[k].to_dict()
		
	return {
		"entity_id": entity_id,
		"name": name,
		"tags": tags.duplicate(),
		"properties": properties.duplicate(true),
		"components": comps_data
	}

static func from_dict(d: Dictionary) -> Variant:
	var ent = (load("res://core/components/generic_entity.gd") as GDScript).new(
		str(d.get("entity_id", d.get("id", ""))),
		str(d.get("name", ""))
	)
	
	var raw_tags = d.get("tags", [])
	if raw_tags is Array:
		for t in raw_tags:
			ent.tags.append(str(t))
			
	ent.properties = d.get("properties", {}).duplicate(true)
	
	var comps_dict = d.get("components", {})
	if comps_dict is Dictionary:
		for comp_type in comps_dict.keys():
			ent.add_component(comp_type, comps_dict[comp_type])
			
	return ent
