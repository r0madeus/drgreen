class_name ComponentRegistry
extends RefCounted

## Central Schema & Capability Registry for Built-in and Custom Components (Phase 41 & 42).
## Manages both engine-native schemas and user-defined custom component definitions.

const CUSTOM_DEF_SCRIPT = preload("res://core/components/custom_component_definition.gd")

static var _schemas: Dictionary = {
	"transform": {
		"defaults": { "position": [0, 0], "rotation": 0.0, "scale": [1, 1] },
		"capabilities": ["transform"]
	},
	"visual": {
		"defaults": { "sprite": "", "color": "#ffffff", "layer": 0 },
		"capabilities": ["renderable"]
	},
	"collision": {
		"defaults": { "shape": "box", "size": [16, 16], "solid": true },
		"capabilities": ["collidable"]
	},
	"interaction": {
		"defaults": { "event": "interacted", "range": 1.5, "on_enter": false, "on_exit": false },
		"capabilities": ["interactable"]
	},
	"health": {
		"defaults": { "max_health": 100.0, "current_health": 100.0, "regeneration": 0.0 },
		"capabilities": ["health", "damageable"]
	},
	"combat": {
		"defaults": { "attack_power": 10.0, "attack_range": 1.5, "cooldown": 1.0, "damage_type": "physical" },
		"capabilities": ["combat", "attacker"]
	},
	"inventory": {
		"defaults": { "slots": 20, "items": {} },
		"capabilities": ["inventory", "container"]
	},
	"equipment": {
		"defaults": { "weapon": "", "armor": "", "accessory": "" },
		"capabilities": ["equipment"]
	},
	"movement": {
		"defaults": { "speed": 100.0, "mode": "walk" },
		"capabilities": ["movement"]
	},
	"ai": {
		"defaults": { "behavior": "idle", "target": "", "aggro_range": 5.0 },
		"capabilities": ["ai", "autonomous"]
	},
	"loot": {
		"defaults": { "drop_table": [], "drop_chance": 1.0 },
		"capabilities": ["loot"]
	},
	"state_machine": {
		"defaults": { "states": ["idle", "active"], "current_state": "idle", "transitions": {} },
		"capabilities": ["stateful"]
	},
	"timer": {
		"defaults": { "timers": {} },
		"capabilities": ["timed"]
	},
	"counter": {
		"defaults": { "counters": {} },
		"capabilities": ["countable"]
	},
	"stats": {
		"defaults": { "base": {}, "modifiers": {} },
		"capabilities": ["stats"]
	},
	"spawner": {
		"defaults": { "spawn_type": "", "interval": 5.0, "max_count": 5 },
		"capabilities": ["spawner"]
	},
	"destructible": {
		"defaults": { "durability": 50.0, "drop_item": "", "cracked_threshold": 25.0 },
		"capabilities": ["destructible"]
	},
	"collectible": {
		"defaults": { "item_id": "", "amount": 1, "auto_pickup": true },
		"capabilities": ["collectible"]
	},
	"dialogue": {
		"defaults": { "dialogue_id": "" },
		"capabilities": ["conversational"]
	},
	"schedule": {
		"defaults": { "routine": [] },
		"capabilities": ["scheduled"]
	},
	"relationship": {
		"defaults": { "hearts": 0, "likes": [], "dislikes": [] },
		"capabilities": ["social"]
	}
}

static var _custom_definitions: Dictionary = {} # comp_id -> CustomComponentDefinition

static func has_component_type(comp_id: String) -> bool:
	return _schemas.has(comp_id) or _custom_definitions.has(comp_id)

static func get_default_data(comp_id: String) -> Dictionary:
	if _schemas.has(comp_id):
		return _schemas[comp_id]["defaults"].duplicate(true)
	if _custom_definitions.has(comp_id):
		return _custom_definitions[comp_id].get_default_instance_data()
	return {}

static func register_custom_component(definition: Variant) -> bool:
	if definition and "component_id" in definition and definition.component_id != "":
		_custom_definitions[definition.component_id] = definition
		return true
	return false

static func unregister_custom_component(comp_id: String) -> bool:
	return _custom_definitions.erase(comp_id)

static func unregister_all_custom_components() -> void:
	_custom_definitions.clear()

static func reset_to_builtin() -> void:
	_custom_definitions.clear()


static func get_custom_component_definition(comp_id: String) -> Variant:
	return _custom_definitions.get(comp_id, null)

static func get_all_custom_components() -> Array:
	return _custom_definitions.values()

static func get_capabilities_for_component(comp_id: String) -> Array[String]:
	if _schemas.has(comp_id):
		var caps: Array[String] = []
		for c in _schemas[comp_id]["capabilities"]:
			caps.append(str(c))
		return caps
	if _custom_definitions.has(comp_id):
		return _custom_definitions[comp_id].capabilities.duplicate()
	return []

static func get_capabilities_for_components(comp_ids: Array) -> Array[String]:
	var result: Dictionary = {}
	for cid in comp_ids:
		var caps = get_capabilities_for_component(str(cid))
		for c in caps:
			result[c] = true
	var list: Array[String] = []
	for k in result.keys():
		list.append(str(k))
	return list

static func get_all_registered_components() -> Array[String]:
	var list: Array[String] = []
	for k in _schemas.keys():
		list.append(str(k))
	for k in _custom_definitions.keys():
		if not list.has(k):
			list.append(str(k))
	return list

static func validate_component_data(comp_id: String, data: Dictionary) -> Dictionary:
	if _custom_definitions.has(comp_id):
		return _custom_definitions[comp_id].validate_instance_data(data)
	if not _schemas.has(comp_id):
		return { "valid": false, "errors": ["Unknown component type: '%s'" % comp_id] }
	return { "valid": true, "errors": [] }
