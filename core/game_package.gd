class_name GamePackage
extends RefCounted

## Generic Game Package Data Contract for the Botanical Haven Engine (Phase 38).
## Encapsulates metadata, content paths, starting world, player setup, and game rules for any game running on the engine.

var game_id: String = "botanical_haven"
var name: String = "Botanical Haven"
var version: String = "1.0.0"
var author: String = "Botanical Team"
var description: String = "A peaceful farming and social simulation adventure."
var engine_version: String = "4.7.0"
var starting_world: String = "farm"
var player_definition: Dictionary = {
	"speed": 150.0,
	"max_energy": 100.0,
	"inventory_capacity": 24,
	"default_tools": ["hoe", "watering_can", "pickaxe", "axe"]
}
var content_paths: Dictionary = {
	"worlds": "res://data/worlds/",
	"npcs": "res://data/npcs/",
	"dialogue": "res://data/dialogue/",
	"quests": "res://data/quests/",
	"plants": "res://data/plants/",
	"tools": "res://data/tools/",
	"shops": "res://data/shops/",
	"assets": "res://assets/"
}
var game_rules: Dictionary = {
	"day_length_seconds": 720.0,
	"stamina_depletion_enabled": true,
	"starting_gold": 500,
	"seasons_enabled": true
}
var dependencies: Array = []
var custom_data: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"game_id": game_id,
		"name": name,
		"version": version,
		"author": author,
		"description": description,
		"engine_version": engine_version,
		"starting_world": starting_world,
		"player_definition": player_definition.duplicate(true),
		"content_paths": content_paths.duplicate(true),
		"game_rules": game_rules.duplicate(true),
		"dependencies": dependencies.duplicate(true),
		"custom_data": custom_data.duplicate(true)
	}

static func from_dict(d: Dictionary) -> Variant:
	var pkg = GamePackage.new()
	if d.has("game_id"): pkg.game_id = str(d["game_id"])
	elif d.has("id"): pkg.game_id = str(d["id"])
	if d.has("name"): pkg.name = str(d["name"])
	elif d.has("display_name"): pkg.name = str(d["display_name"])
	if d.has("version"): pkg.version = str(d["version"])
	if d.has("author"): pkg.author = str(d["author"])
	if d.has("description"): pkg.description = str(d["description"])
	if d.has("engine_version"): pkg.engine_version = str(d["engine_version"])
	if d.has("starting_world"): pkg.starting_world = str(d["starting_world"])
	if d.has("player_definition") and typeof(d["player_definition"]) == TYPE_DICTIONARY:
		pkg.player_definition = d["player_definition"].duplicate(true)
	if d.has("content_paths") and typeof(d["content_paths"]) == TYPE_DICTIONARY:
		pkg.content_paths = d["content_paths"].duplicate(true)
	if d.has("game_rules") and typeof(d["game_rules"]) == TYPE_DICTIONARY:
		pkg.game_rules = d["game_rules"].duplicate(true)
	if d.has("dependencies") and typeof(d["dependencies"]) == TYPE_ARRAY:
		pkg.dependencies = d["dependencies"].duplicate(true)
	if d.has("custom_data") and typeof(d["custom_data"]) == TYPE_DICTIONARY:
		pkg.custom_data = d["custom_data"].duplicate(true)
	return pkg

func validate() -> Dictionary:
	var report = {
		"valid": true,
		"errors": [],
		"warnings": []
	}
	
	if game_id.strip_edges() == "":
		report["valid"] = false
		report["errors"].append("Game ID cannot be empty.")
	elif not game_id.is_valid_identifier():
		report["valid"] = false
		report["errors"].append("Game ID '%s' is not a valid identifier." % game_id)
		
	if name.strip_edges() == "":
		report["warnings"].append("Game display name is empty.")
	if starting_world.strip_edges() == "":
		report["valid"] = false
		report["errors"].append("Starting world cannot be empty.")
		
	return report
