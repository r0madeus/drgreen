class_name GridTileData
extends RefCounted

## Represents the state and properties of a single tile on the grid.

# Tile types: "soil", "path", "blocked"
var type: String = "soil"

# Tile states: "empty", "planted", "watered", "mature"
var state: String = "empty"

var plant_id: String = ""
var growth_stage: int = 0
var days_in_stage: int = 0
var watered_today: bool = false
var grid_position: Vector2i = Vector2i.ZERO
var genetic_identity: String = ""
var genetic_profile: Dictionary = {}

var walkable: bool = true
var solid: bool = false
var interactable: bool = false

func _init(p_pos: Vector2i = Vector2i.ZERO, p_type: String = "soil") -> void:
	grid_position = p_pos
	type = p_type
	state = "empty"
	walkable = (p_type != "blocked" and p_type != "fence")
	solid = (p_type == "blocked" or p_type == "fence")
	interactable = false

func is_walkable() -> bool:
	return walkable and not solid and type != "blocked" and type != "fence"


func to_dict() -> Dictionary:
	return {
		"type": type,
		"state": state,
		"plant_id": plant_id,
		"growth_stage": growth_stage,
		"days_in_stage": days_in_stage,
		"watered_today": watered_today,
		"genetic_identity": genetic_identity,
		"genetic_profile": genetic_profile,
		"position": [grid_position.x, grid_position.y]
	}

func from_dict(data: Dictionary) -> void:
	type = data.get("type", "soil")
	state = data.get("state", "empty")
	plant_id = data.get("plant_id", "")
	growth_stage = data.get("growth_stage", 0)
	days_in_stage = data.get("days_in_stage", 0)
	watered_today = data.get("watered_today", false)
	genetic_identity = data.get("genetic_identity", "")
	genetic_profile = data.get("genetic_profile", {})
	if data.has("position"):
		var pos_arr = data["position"]
		grid_position = Vector2i(pos_arr[0], pos_arr[1])
