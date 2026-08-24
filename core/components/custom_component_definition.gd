class_name CustomComponentDefinition
extends RefCounted

## Schema Definition for User-Authored Custom Components (Phase 42).
## Enables creators to author custom data schemas, property constraints, and capability mappings
## without modifying engine code.

var component_id: String = ""
var name: String = ""
var category: String = "Custom"
var description: String = ""
var icon: String = "icon_component"
var schema_version: int = 1
var properties: Dictionary = {} # prop_name -> Dictionary (schema metadata)
var capabilities: Array[String] = []

func _init(p_id: String = "", p_name: String = "", p_cat: String = "Custom", p_desc: String = "") -> void:
	component_id = p_id if p_id != "" else "custom_comp_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	name = p_name if p_name != "" else component_id.capitalize()
	category = p_cat
	description = p_desc

func add_property(prop_name: String, prop_type: String = "float", default_val: Variant = 0.0, metadata: Dictionary = {}) -> void:
	if prop_name == "": return
	var schema = {
		"name": prop_name,
		"type": prop_type,
		"default": default_val,
		"display_name": metadata.get("display_name", prop_name.capitalize()),
		"description": metadata.get("description", ""),
		"required": bool(metadata.get("required", false)),
		"editable": bool(metadata.get("editable", true)),
		"min": metadata.get("min", null),
		"max": metadata.get("max", null),
		"step": metadata.get("step", null),
		"enum_values": metadata.get("enum_values", [])
	}
	properties[prop_name] = schema

func remove_property(prop_name: String) -> bool:
	return properties.erase(prop_name)

func get_default_instance_data() -> Dictionary:
	var d: Dictionary = {}
	for p in properties.keys():
		d[p] = properties[p]["default"]
	return d

func validate_instance_data(data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	for p in properties.keys():
		var schema = properties[p]
		if schema.get("required", false) and not data.has(p):
			errors.append("Missing required property '%s'" % p)
	return {
		"valid": errors.is_empty(),
		"errors": errors
	}

func to_dict() -> Dictionary:
	return {
		"component_id": component_id,
		"name": name,
		"category": category,
		"description": description,
		"icon": icon,
		"schema_version": schema_version,
		"properties": properties.duplicate(true),
		"capabilities": capabilities.duplicate()
	}

static func from_dict(d: Dictionary) -> Variant:
	var def = (load("res://core/components/custom_component_definition.gd") as GDScript).new(
		str(d.get("component_id", d.get("id", ""))),
		str(d.get("name", "")),
		str(d.get("category", "Custom")),
		str(d.get("description", ""))
	)
	def.icon = str(d.get("icon", "icon_component"))
	def.schema_version = int(d.get("schema_version", 1))
	def.properties = d.get("properties", {}).duplicate(true)
	
	var raw_caps = d.get("capabilities", [])
	if raw_caps is Array:
		for c in raw_caps:
			def.capabilities.append(str(c))
			
	return def
