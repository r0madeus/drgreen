class_name WorldDefinition
extends RefCounted

## Data container representing a defined multi-world region.

var id: String = "farm"
var display_name: String = "Peaceful Farm"
var scene_path: String = "res://scenes/farm.tscn"
var map_data_path: String = "res://data/worlds/farm.json"
var width: int = 32
var height: int = 24
var enabled: bool = true
var spawn_points: Dictionary = {}
var connections: Dictionary = {}
var metadata: Dictionary = {}

static func from_dict(p_id: String, d: Dictionary) -> WorldDefinition:
	var def = WorldDefinition.new()
	def.id = str(d.get("id", p_id))
	def.display_name = str(d.get("display_name", def.id.capitalize()))
	def.scene_path = str(d.get("scene", "res://scenes/farm.tscn"))
	def.map_data_path = str(d.get("map_data", "res://data/worlds/%s.json" % def.id))
	def.width = int(d.get("width", 32))
	def.height = int(d.get("height", 24))
	def.enabled = bool(d.get("enabled", true))
	def.spawn_points = d.get("spawn_points", { "default": [16, 12] })
	def.connections = d.get("connections", {})
	def.metadata = d.get("metadata", {})
	return def
