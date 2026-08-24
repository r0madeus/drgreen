class_name WorldFixture
extends RefCounted

## Fixture factory for mock world/tile data used in grid & farming tests.

static func make_tile(tile_type: String = "grass") -> Dictionary:
	return {
		"type": tile_type,
		"plant_id": "",
		"growth_stage": 0,
		"watered_today": false,
		"tilled_at": 0,
		"hp": 0
	}

static func make_world_context() -> Dictionary:
	return {
		"world_id": "farm",
		"grid_width": 32,
		"grid_height": 24,
		"tile_size": 16
	}

static func make_transition(from_world: String, to_world: String, spawn: String = "default") -> Dictionary:
	return {
		"from_world": from_world,
		"target_world": to_world,
		"target_spawn": spawn,
		"transition_id": "%s_to_%s" % [from_world, to_world]
	}
