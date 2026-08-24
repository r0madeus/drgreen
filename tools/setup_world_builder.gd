@tool
extends SceneTree

func _init() -> void:
	setup_world_builder()
	quit()

static func setup_world_builder() -> void:
	DirAccess.make_dir_recursive_absolute("res://editor/world_builder")
	DirAccess.make_dir_recursive_absolute("res://data/worlds")

	# 1. Generate initial res://data/worlds/farm.json
	var tiles = []
	for y in range(24):
		for x in range(32):
			var tile_type = "grass"
			if x == 0 or x == 31 or y == 0 or y == 23:
				tile_type = "fence"
			elif (x == 15 or x == 16) or (y == 11 or y == 12):
				tile_type = "path"
			elif (x >= 4 and x <= 12 and y >= 3 and y <= 8) or \
				 (x >= 19 and x <= 27 and y >= 3 and y <= 8) or \
				 (x >= 4 and x <= 12 and y >= 15 and y <= 20) or \
				 (x >= 19 and x <= 27 and y >= 15 and y <= 20):
				tile_type = "soil"
			elif (x == 3 or x == 13 or x == 18 or x == 28) and ((y >= 2 and y <= 9) or (y >= 14 and y <= 21)):
				tile_type = "path"
			elif (y == 2 or y == 9 or y == 14 or y == 21) and ((x >= 3 and x <= 13) or (x >= 18 and x <= 28)):
				tile_type = "path"
				
			var walkable = (tile_type != "fence")
			var solid = (tile_type == "fence")
			tiles.append({
				"x": x,
				"y": y,
				"type": tile_type,
				"layer": "TERRAIN",
				"walkable": walkable,
				"solid": solid,
				"interactable": false
			})

	var objects = [
		{
			"instance_id": "merchant_rowan",
			"asset_id": "merchant",
			"name": "Rowan the Herbalist",
			"position": [15, 3],
			"layer": "NPC",
			"properties": { "walkable": false, "solid": true, "interactable": true, "z_index": 1 }
		},
		{
			"instance_id": "greenhouse_structure",
			"asset_id": "greenhouse_ruined",
			"name": "Abandoned Greenhouse",
			"position": [23, 6],
			"layer": "OBJECT",
			"properties": { "walkable": false, "solid": true, "interactable": true, "z_index": 1 }
		},
		{
			"instance_id": "wooden_gate_grove",
			"asset_id": "wooden_gate",
			"name": "Botanical Grove Gate",
			"position": [31, 12],
			"layer": "OBJECT",
			"properties": { "walkable": true, "solid": false, "interactable": true, "z_index": 0 }
		}
	]

	var farm_world = {
		"version": 1,
		"name": "Farm",
		"width": 32,
		"height": 24,
		"tile_size": 16,
		"tiles": tiles,
		"objects": objects
	}

	var f_world = FileAccess.open("res://data/worlds/farm.json", FileAccess.WRITE)
	if f_world:
		f_world.store_string(JSON.stringify(farm_world, "  "))
		f_world.close()

	print("[WorldBuilderSetup] Created res://data/worlds/farm.json successfully!")
