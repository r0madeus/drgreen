@tool
extends SceneTree

func _init() -> void:
	generate_phase3_worlds()
	quit()

static func generate_phase3_worlds() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/worlds")

	# 1. Update/Create res://data/worlds/farm.json (Version 3)
	var farm_v3 = {
		"version": 3,
		"world_id": "farm",
		"display_name": "Peaceful Farm",
		"width": 32,
		"height": 24,
		"tile_size": 16,
		"spawn": [16, 12],
		"default_layer": "GROUND",
		"layers": [
			{ "name": "GROUND", "visible": true, "locked": false },
			{ "name": "TERRAIN", "visible": true, "locked": false },
			{ "name": "DECORATION", "visible": true, "locked": false },
			{ "name": "OBJECT", "visible": true, "locked": false },
			{ "name": "NPC", "visible": true, "locked": false },
			{ "name": "OVERLAY", "visible": true, "locked": false }
		],
		"tiles": [],
		"objects": [
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
		],
		"transitions": [
			{
				"instance_id": "trans_to_grove",
				"name": "To Botanical Grove",
				"position": [31, 12],
				"target_world": "botanical_grove",
				"target_spawn": [1, 12]
			}
		]
	}

	# Fill standard farm tiles
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
			farm_v3["tiles"].append({
				"x": x,
				"y": y,
				"type": tile_type,
				"layer": "GROUND" if tile_type == "grass" else ("TERRAIN" if tile_type in ["soil", "path"] else "OBJECT"),
				"walkable": walkable,
				"solid": solid,
				"interactable": false
			})

	var f_farm = FileAccess.open("res://data/worlds/farm.json", FileAccess.WRITE)
	if f_farm:
		f_farm.store_string(JSON.stringify(farm_v3, "  "))
		f_farm.close()

	# 2. Generate botanical_grove.json
	var grove_v3 = {
		"version": 3,
		"world_id": "botanical_grove",
		"display_name": "Botanical Grove",
		"width": 32,
		"height": 24,
		"tile_size": 16,
		"spawn": [2, 12],
		"default_layer": "GROUND",
		"layers": farm_v3["layers"],
		"tiles": [],
		"objects": [
			{
				"instance_id": "ancient_tree_center",
				"asset_id": "ancient_tree",
				"name": "Heart of the Grove",
				"position": [16, 10],
				"layer": "DECORATION",
				"properties": { "walkable": false, "solid": true, "interactable": false }
			},
			{
				"instance_id": "grove_pond",
				"asset_id": "pond",
				"name": "Nectar Pond",
				"position": [10, 14],
				"layer": "DECORATION",
				"properties": { "walkable": false, "solid": true, "interactable": false }
			}
		],
		"transitions": [
			{
				"instance_id": "trans_to_farm",
				"name": "Back to Farm",
				"position": [0, 12],
				"target_world": "farm",
				"target_spawn": [30, 12]
			},
			{
				"instance_id": "trans_to_forest",
				"name": "Into the Deep Forest",
				"position": [31, 12],
				"target_world": "forest",
				"target_spawn": [1, 12]
			}
		]
	}
	for y in range(24):
		for x in range(32):
			var t_type = "grass"
			if x == 0 or x == 31 or y == 0 or y == 23:
				t_type = "fence" if (x != 0 and x != 31 or y != 12) else "path"
			elif y == 12 or (x >= 14 and x <= 18 and y >= 8 and y <= 16):
				t_type = "path"
			grove_v3["tiles"].append({
				"x": x,
				"y": y,
				"type": t_type,
				"layer": "GROUND" if t_type == "grass" else "TERRAIN",
				"walkable": t_type != "fence",
				"solid": t_type == "fence",
				"interactable": false
			})
	var f_grove = FileAccess.open("res://data/worlds/botanical_grove.json", FileAccess.WRITE)
	if f_grove:
		f_grove.store_string(JSON.stringify(grove_v3, "  "))
		f_grove.close()

	# 3. Generate forest.json
	var forest_v3 = {
		"version": 3,
		"world_id": "forest",
		"display_name": "Whispering Forest",
		"width": 32,
		"height": 24,
		"tile_size": 16,
		"spawn": [2, 12],
		"default_layer": "GROUND",
		"layers": farm_v3["layers"],
		"tiles": [],
		"objects": [],
		"transitions": [
			{
				"instance_id": "trans_to_grove",
				"name": "To Grove",
				"position": [0, 12],
				"target_world": "botanical_grove",
				"target_spawn": [30, 12]
			},
			{
				"instance_id": "trans_to_town",
				"name": "To Town",
				"position": [31, 12],
				"target_world": "town",
				"target_spawn": [1, 12]
			}
		]
	}
	for y in range(24):
		for x in range(32):
			var t_type = "grass"
			if x == 0 or x == 31 or y == 0 or y == 23:
				t_type = "fence" if (x != 0 and x != 31 or y != 12) else "path"
			elif y == 12:
				t_type = "path"
			forest_v3["tiles"].append({
				"x": x, "y": y, "type": t_type,
				"layer": "GROUND", "walkable": t_type != "fence", "solid": t_type == "fence", "interactable": false
			})
	var f_forest = FileAccess.open("res://data/worlds/forest.json", FileAccess.WRITE)
	if f_forest: f_forest.store_string(JSON.stringify(forest_v3, "  ")); f_forest.close()

	# 4. Generate town.json & laboratory.json
	var town_v3 = {
		"version": 3,
		"world_id": "town",
		"display_name": "Botanist Village",
		"width": 32,
		"height": 24,
		"tile_size": 16,
		"spawn": [2, 12],
		"default_layer": "GROUND",
		"layers": farm_v3["layers"],
		"tiles": [],
		"objects": [],
		"transitions": [
			{ "instance_id": "trans_to_forest", "name": "To Forest", "position": [0, 12], "target_world": "forest", "target_spawn": [30, 12] },
			{ "instance_id": "trans_to_lab", "name": "To Grand Lab", "position": [16, 2], "target_world": "laboratory", "target_spawn": [16, 21] }
		]
	}
	for y in range(24):
		for x in range(32):
			var t_type = "path" if (y == 12 or x == 16 or (x >= 8 and x <= 24 and y >= 6 and y <= 18)) else "grass"
			if (x == 0 or x == 31 or y == 0 or y == 23) and (x != 0 or y != 12) and (x != 16 or y != 0):
				t_type = "fence"
			town_v3["tiles"].append({
				"x": x, "y": y, "type": t_type,
				"layer": "GROUND", "walkable": t_type != "fence", "solid": t_type == "fence", "interactable": false
			})
	var f_town = FileAccess.open("res://data/worlds/town.json", FileAccess.WRITE)
	if f_town: f_town.store_string(JSON.stringify(town_v3, "  ")); f_town.close()

	var lab_v3 = {
		"version": 3,
		"world_id": "laboratory",
		"display_name": "Grand Synthesis Laboratory",
		"width": 32,
		"height": 24,
		"tile_size": 16,
		"spawn": [16, 20],
		"default_layer": "GROUND",
		"layers": farm_v3["layers"],
		"tiles": [],
		"objects": [],
		"transitions": [
			{ "instance_id": "trans_to_town", "name": "To Town Plaza", "position": [16, 23], "target_world": "town", "target_spawn": [16, 3] }
		]
	}
	for y in range(24):
		for x in range(32):
			var t_type = "path"
			if x == 0 or x == 31 or y == 0 or (y == 23 and x != 16):
				t_type = "fence"
			lab_v3["tiles"].append({
				"x": x, "y": y, "type": t_type,
				"layer": "GROUND", "walkable": t_type != "fence", "solid": t_type == "fence", "interactable": false
			})
	var f_lab = FileAccess.open("res://data/worlds/laboratory.json", FileAccess.WRITE)
	if f_lab: f_lab.store_string(JSON.stringify(lab_v3, "  ")); f_lab.close()

	print("[WorldBuilderPhase3Init] Initialized 5 Version 3 World Data files successfully!")
