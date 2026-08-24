class_name AssetDefinitionManager
extends Node

const DEFINITIONS_PATH = "res://data/assets/definitions.json"
static var definitions: Dictionary = {}
static var _initialized: bool = false

static func ensure_initialized() -> void:
	if _initialized: return
	if FileAccess.file_exists(DEFINITIONS_PATH):
		var f = FileAccess.open(DEFINITIONS_PATH, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				definitions = json.data
	_initialized = true

static func get_definition(asset_id: String) -> Dictionary:
	ensure_initialized()
	return definitions.get(asset_id, {})

static func set_definition(asset_id: String, def: Dictionary) -> void:
	ensure_initialized()
	definitions[asset_id] = def
	_save_definitions()

static func _save_definitions() -> void:
	if not DirAccess.dir_exists_absolute("res://data/assets/"):
		DirAccess.make_dir_recursive_absolute("res://data/assets/")
	var f = FileAccess.open(DEFINITIONS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(definitions, "  "))

static func get_all_definitions() -> Dictionary:
	ensure_initialized()
	return definitions.duplicate(true)

static func get_definitions_by_type(type_name: String) -> Array:
	ensure_initialized()
	var res = []
	for k in definitions.keys():
		var def = definitions[k]
		if def.get("identity", {}).get("type", "") == type_name:
			res.append(def)
	return res

static func resolve_instance_properties(asset_id: String, instance_overrides: Dictionary) -> Dictionary:
	var def = get_definition(asset_id)
	if def.is_empty():
		return instance_overrides.duplicate(true)
		
	var resolved = {}
	var comps = def.get("components", {})
	
	resolved["display_name"] = def.get("identity", {}).get("display_name", asset_id)
	resolved["tags"] = def.get("identity", {}).get("tags", [])
	resolved["asset_type"] = def.get("identity", {}).get("type", "object")
	
	if comps.has("visual"):
		for k in comps["visual"].keys(): resolved[k] = comps["visual"][k]
		
	if comps.has("collision"):
		resolved["solid"] = comps["collision"].get("solid", true)
		resolved["collision_shapes"] = comps["collision"].get("shapes", [])
		
	if comps.has("navigation"):
		resolved["walkable"] = comps["navigation"].get("walkable", false)
		resolved["movement_cost"] = comps["navigation"].get("movement_cost", 1.0)
		resolved["navigation_type"] = comps["navigation"].get("type", "blocked")
		
	if comps.has("lighting"):
		resolved["emits_light"] = comps["lighting"].get("enabled", false)
		resolved["light_color"] = comps["lighting"].get("color", "#FFFFFF")
		resolved["light_intensity"] = comps["lighting"].get("intensity", 1.0)
		resolved["light_radius"] = comps["lighting"].get("radius", 64)
		resolved["cast_shadows"] = comps["lighting"].get("cast_shadows", false)
		
	if comps.has("interaction"):
		resolved["interactable"] = comps["interaction"].get("enabled", false)
		resolved["interaction_type"] = comps["interaction"].get("type", "none")
		resolved["interaction_range"] = comps["interaction"].get("range", 1)
		
	if comps.has("placement"):
		resolved["allowed_terrain"] = comps["placement"].get("allowed_terrain", [])
		
	if def.has("custom_properties"):
		for k in def["custom_properties"].keys(): resolved[k] = def["custom_properties"][k]
		
	for k in instance_overrides.keys():
		resolved[k] = instance_overrides[k]
		
	return resolved
