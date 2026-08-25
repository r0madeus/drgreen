extends SceneTree

## Procedural World Authoring Script for Phase 4C — Central Town Hub
## Generates a 100x100 explorable world with Central Square, Main Avenues, Market, Residential, Community, and Green Spaces.

func _init() -> void:
	call_deferred("_run_authoring")

func _run_authoring() -> void:
	print("==================================================")
	print("  PHASE 4C — CENTRAL TOWN WORLD AUTHORING")
	print("==================================================")
	
	var width = 100
	var height = 100
	var tile_size = 16
	var world_id = "central_town"
	var display_name = "Central Town"
	
	# 1. Initialize grid tiles (100x100 default to grass)
	var tiles: Array = []
	var tile_lookup: Dictionary = {} # Vector2i -> int index in tiles
	
	for y in range(height):
		for x in range(width):
			var t = {
				"x": int(x),
				"y": int(y),
				"type": "grass",
				"layer": "GROUND",
				"walkable": true,
				"solid": false,
				"interactable": false,
				"variant": "single",
				"connection_mask": 0
			}
			tile_lookup[Vector2i(x, y)] = tiles.size()
			tiles.append(t)
			
	var set_tile = func(x: int, y: int, type: String, layer: String = "GROUND", walkable: bool = true, solid: bool = false, interactable: bool = false):
		if x < 0 or x >= width or y < 0 or y >= height: return
		var idx = tile_lookup.get(Vector2i(x, y), -1)
		if idx >= 0:
			tiles[idx]["type"] = type
			tiles[idx]["layer"] = layer
			tiles[idx]["walkable"] = walkable
			tiles[idx]["solid"] = solid
			tiles[idx]["interactable"] = interactable

	var fill_rect = func(x1: int, y1: int, x2: int, y2: int, type: String, layer: String = "GROUND", walkable: bool = true, solid: bool = false):
		for y in range(mini(y1, y2), maxi(y1, y2) + 1):
			for x in range(mini(x1, x2), maxi(x1, x2) + 1):
				set_tile.call(x, y, type, layer, walkable, solid)

	print("1. Constructing Perimeter Fences and Town Entrances...")
	# Perimeter fences with North (48..51) and South (48..51) road openings
	for x in range(width):
		if not (x >= 48 and x <= 51):
			set_tile.call(x, 0, "fence", "OBJECT", false, true)
			set_tile.call(x, height - 1, "fence", "OBJECT", false, true)
	for y in range(height):
		set_tile.call(0, y, "fence", "OBJECT", false, true)
		set_tile.call(width - 1, y, "fence", "OBJECT", false, true)

	print("2. Constructing Grand Main Avenues...")
	# Grand North-South Avenue (x=48..51, y=0..99)
	for y in range(height):
		set_tile.call(48, y, "path")
		set_tile.call(49, y, "stone")
		set_tile.call(50, y, "stone")
		set_tile.call(51, y, "path")

	# Grand East-West Avenue (y=48..51, x=2..97)
	for x in range(2, width - 2):
		set_tile.call(x, 48, "path")
		set_tile.call(x, 49, "stone")
		set_tile.call(x, 50, "stone")
		set_tile.call(x, 51, "path")

	print("3. Constructing Central Town Square (x: 40..60, y: 40..60)...")
	# Plaza floor paving
	fill_rect.call(42, 42, 58, 58, "stone")
	# Decorative border
	for x in range(41, 60):
		set_tile.call(x, 41, "path")
		set_tile.call(x, 59, "path")
	for y in range(41, 60):
		set_tile.call(41, y, "path")
		set_tile.call(59, y, "path")
	# Decorative sand accents in plaza corners
	fill_rect.call(43, 43, 45, 45, "sand")
	fill_rect.call(55, 43, 57, 45, "sand")
	fill_rect.call(43, 55, 45, 57, "sand")
	fill_rect.call(55, 55, 57, 57, "sand")

	print("4. Constructing Shopping & Market District (x: 62..92, y: 38..65)...")
	fill_rect.call(64, 42, 88, 58, "path")
	fill_rect.call(66, 44, 86, 56, "sand")
	fill_rect.call(68, 46, 84, 54, "stone")
	# Connecting path to East-West Avenue
	fill_rect.call(58, 48, 64, 51, "stone")

	print("5. Constructing Community & Public District (x: 8..38, y: 38..75)...")
	# Town Hall courtyard
	fill_rect.call(14, 40, 26, 52, "stone")
	fill_rect.call(12, 38, 28, 54, "path")
	# Connecting path to Central Square
	fill_rect.call(28, 48, 42, 51, "stone")
	
	# Scenic Public Park & Pond (x: 14..32, y: 56..72)
	fill_rect.call(14, 56, 32, 72, "path")
	fill_rect.call(16, 58, 30, 70, "sand")
	# Natural pond
	fill_rect.call(18, 60, 28, 68, "water", "GROUND", false, true)
	# Path connecting Town Hall to Park
	fill_rect.call(19, 52, 21, 58, "path")

	print("6. Constructing Residential District (x: 10..90, y: 6..36)...")
	# Main Residential Cross-Boulevard (y: 20..22, x: 12..88)
	fill_rect.call(12, 20, 88, 22, "path")
	fill_rect.call(48, 20, 51, 22, "stone")

	# Northwest Villa & Gardens (x: 16..30, y: 8..20)
	fill_rect.call(20, 14, 24, 20, "path")
	fill_rect.call(16, 8, 28, 8, "fence", "OBJECT", false, true)
	fill_rect.call(16, 8, 16, 20, "fence", "OBJECT", false, true)
	fill_rect.call(28, 8, 28, 20, "fence", "OBJECT", false, true)
	fill_rect.call(16, 20, 19, 20, "fence", "OBJECT", false, true)
	fill_rect.call(25, 20, 28, 20, "fence", "OBJECT", false, true)
	# Garden soil patch
	fill_rect.call(17, 14, 19, 18, "soil", "TERRAIN", true, false)

	# North-Central Town House & Gardens (x: 44..56, y: 8..18)
	fill_rect.call(48, 10, 52, 18, "stone")
	fill_rect.call(44, 12, 46, 16, "soil", "TERRAIN", true, false)
	fill_rect.call(54, 12, 56, 16, "soil", "TERRAIN", true, false)

	# Northeast Barn & Farmstead (x: 70..88, y: 8..26)
	fill_rect.call(72, 14, 84, 20, "path")
	fill_rect.call(70, 8, 88, 8, "fence", "OBJECT", false, true)
	fill_rect.call(70, 8, 70, 24, "fence", "OBJECT", false, true)
	fill_rect.call(88, 8, 88, 24, "fence", "OBJECT", false, true)
	fill_rect.call(70, 24, 76, 24, "fence", "OBJECT", false, true)
	fill_rect.call(80, 24, 88, 24, "fence", "OBJECT", false, true)

	# East Greenhouse Conservatory (x: 70..84, y: 28..36)
	fill_rect.call(74, 28, 78, 36, "path")
	fill_rect.call(68, 30, 72, 34, "soil", "TERRAIN", true, false)

	# South Entrance Plaza (x: 42..58, y: 82..98)
	fill_rect.call(44, 84, 56, 96, "path")
	fill_rect.call(47, 86, 53, 94, "stone")

	print("7. Placing Town Objects, Buildings, Props and NPCs...")
	var objects: Array = []
	var add_obj = func(asset_id: String, inst_id: String, name: String, x: int, y: int, layer: String = "OBJECT", props: Dictionary = {}):
		var p = props.duplicate(true)
		if not p.has("solid"): p["solid"] = (layer != "DECORATION" and asset_id != "signpost" and asset_id != "flower_patch")
		if not p.has("walkable"): p["walkable"] = not p["solid"]
		if not p.has("interactable"): p["interactable"] = false
		objects.append({
			"asset_id": asset_id,
			"instance_id": inst_id,
			"name": name,
			"layer": layer,
			"position": [int(x), int(y)],
			"properties": p
		})

	# --- CENTRAL SQUARE OBJECTS ---
	add_obj.call("well", "town_square_well", "Town Square Well", 50, 50, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "resource", "interaction_id": "water_source" })
	add_obj.call("bench", "square_bench_nw", "Plaza Garden Bench", 46, 46, "OBJECT", { "solid": true })
	add_obj.call("bench", "square_bench_ne", "Plaza Garden Bench", 54, 46, "OBJECT", { "solid": true })
	add_obj.call("bench", "square_bench_sw", "Plaza Garden Bench", 46, 54, "OBJECT", { "solid": true })
	add_obj.call("bench", "square_bench_se", "Plaza Garden Bench", 54, 54, "OBJECT", { "solid": true })
	add_obj.call("flower_patch", "flower_square_nw", "Plaza Flower Bed", 44, 44, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "flower_square_ne", "Plaza Flower Bed", 56, 44, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "flower_square_sw", "Plaza Flower Bed", 44, 56, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "flower_square_se", "Plaza Flower Bed", 56, 56, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("signpost", "town_square_bulletin", "Town Square Notice Board", 50, 58, "OBJECT", { "solid": false, "walkable": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "town_square_notice" })

	# --- SHOPPING & MARKET DISTRICT OBJECTS ---
	add_obj.call("farm_house", "elias_trade_post", "Elias's Village Trade Post", 70, 44, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "shop", "shop_id": "elias_general_shop" })
	add_obj.call("seed_shop", "market_seed_shop", "Central Seed & Crop Stall", 80, 44, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "shop", "shop_id": "rowan_seed_shop" })
	add_obj.call("shipping_box", "market_shipping_box", "Town Crop Shipping Bin", 75, 54, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "shop", "shop_id": "shipping_bin" })
	add_obj.call("storage_shed", "market_storage_shed", "Market Supply Warehouse", 84, 54, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "container", "container_id": "market_storage" })
	add_obj.call("workbench", "market_craft_table", "Artisan Workbench", 66, 54, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "custom" })
	add_obj.call("signpost", "market_signpost", "Market District Directory", 68, 48, "OBJECT", { "solid": false, "walkable": true, "interactable": true })
	add_obj.call("bench", "market_bench", "Market Rest Bench", 78, 54, "OBJECT", { "solid": true })
	add_obj.call("flower_patch", "market_flower_1", "Market Planter", 64, 48, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "market_flower_2", "Market Planter", 82, 48, "DECORATION", { "solid": false, "walkable": true })
	# NPC Elias in Market
	add_obj.call("elias", "npc_elias", "Merchant Elias", 72, 48, "NPC", { "solid": true, "walkable": false, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "elias", "npc_id": "elias" })

	# --- RESIDENTIAL DISTRICT OBJECTS ---
	add_obj.call("farm_house", "villa_residence", "Botanist Villa", 22, 12, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "villa_door" })
	add_obj.call("farm_house", "elias_home_building", "Elias's Town Home", 50, 10, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "elias_home_door" })
	add_obj.call("barn", "town_barn", "Community Cattle Barn", 74, 12, "OBJECT", { "solid": true, "interactable": false })
	add_obj.call("storage_shed", "cottage_shed", "Village Cottage", 82, 12, "OBJECT", { "solid": true, "interactable": true })
	add_obj.call("greenhouse_repaired", "town_conservatory", "Botanical Conservatory Dome", 76, 30, "OBJECT", { "solid": true, "interactable": true })
	add_obj.call("bench", "res_bench_1", "Garden Bench", 48, 16, "OBJECT", { "solid": true })
	add_obj.call("bench", "res_bench_2", "Garden Bench", 26, 16, "OBJECT", { "solid": true })
	add_obj.call("bush", "res_bush_1", "Berry Bush", 17, 13, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("bush", "res_bush_2", "Berry Bush", 27, 13, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "res_flower_1", "Cottage Garden", 24, 16, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "res_flower_2", "Cottage Garden", 46, 16, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "res_flower_3", "Cottage Garden", 54, 16, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "res_flower_4", "Cottage Garden", 70, 16, "DECORATION", { "solid": false, "walkable": true })

	# --- COMMUNITY & PUBLIC DISTRICT OBJECTS ---
	add_obj.call("laboratory", "town_hall_building", "Grand Central Town Hall", 20, 44, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "town_hall_door" })
	add_obj.call("signpost", "town_hall_bulletin", "Town Hall Civic Notice", 20, 50, "OBJECT", { "solid": false, "walkable": true, "interactable": true })
	add_obj.call("chest", "community_chest", "Public Storage Chest", 14, 52, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "container", "container_id": "community_chest" })
	add_obj.call("workbench", "community_workbench", "Public Crafting Station", 15, 52, "OBJECT", { "solid": true, "interactable": true, "interaction_type": "custom" })
	add_obj.call("bench", "park_bench_north", "Park Pond Bench", 16, 60, "OBJECT", { "solid": true })
	add_obj.call("bench", "park_bench_south", "Park Pond Bench", 28, 60, "OBJECT", { "solid": true })
	add_obj.call("bench", "park_bench_east", "Park Promenade Bench", 22, 68, "OBJECT", { "solid": true })
	add_obj.call("ancient_tree", "park_ancient_tree_1", "Grand Park Elder Tree", 14, 62, "OBJECT", { "solid": true })
	add_obj.call("ancient_tree", "park_ancient_tree_2", "Grand Park Elder Tree", 30, 62, "OBJECT", { "solid": true })
	add_obj.call("tree", "park_oak_tree_1", "Park Oak", 14, 68, "OBJECT", { "solid": true })
	add_obj.call("rock", "park_granite_boulder_1", "Granite Landmark", 17, 58, "OBJECT", { "solid": true })
	add_obj.call("rock_small", "park_granite_boulder_2", "Granite Rock", 27, 58, "OBJECT", { "solid": true })
	add_obj.call("flower_patch", "park_flower_1", "Park Wildflowers", 18, 67, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "park_flower_2", "Park Wildflowers", 26, 67, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("mushroom", "park_mushroom", "Wild Park Mushroom", 22, 58, "DECORATION", { "solid": false, "walkable": true, "interactable": true })

	# --- SOUTH ENTRANCE PLAZA OBJECTS ---
	add_obj.call("signpost", "town_welcome_sign", "Welcome to Central Town", 52, 90, "OBJECT", { "solid": false, "walkable": true, "interactable": true, "dialogue_id": "sign_welcome_town" })
	add_obj.call("rock", "gate_monolith_w", "Entrance Gateway Pillar", 46, 94, "OBJECT", { "solid": true })
	add_obj.call("rock", "gate_monolith_e", "Entrance Gateway Pillar", 53, 94, "OBJECT", { "solid": true })
	add_obj.call("flower_patch", "gate_flower_w", "Entrance Floral Display", 45, 92, "DECORATION", { "solid": false, "walkable": true })
	add_obj.call("flower_patch", "gate_flower_e", "Entrance Floral Display", 54, 92, "DECORATION", { "solid": false, "walkable": true })

	# --- GREEN SPACES & WOODLAND PERIMETER TREES ---
	var tree_coords = [
		[6, 6], [8, 10], [10, 6], [6, 14], [92, 6], [94, 10], [90, 6], [94, 14],
		[6, 88], [8, 92], [10, 88], [6, 84], [92, 88], [94, 92], [90, 88], [94, 84],
		[36, 6], [38, 10], [62, 6], [64, 10], [36, 92], [38, 88], [62, 92], [64, 88],
		[6, 32], [6, 38], [94, 32], [94, 38], [6, 78], [94, 78]
	]
	for i in range(tree_coords.size()):
		var tc = tree_coords[i]
		var aid = "ancient_tree" if (i % 3 == 0) else "tree"
		add_obj.call(aid, "woodland_tree_%d" % i, "Woodland Tree", tc[0], tc[1], "OBJECT", { "solid": true })

	print("8. Setting World Transitions and Spawn Points...")
	var transitions = [
		{
			"instance_id": "town_to_farm",
			"name": "Road Back to Farm",
			"position": [50, 99],
			"required_progression": "",
			"target_spawn": "farm_from_town",
			"target_world": "farm",
			"transition_id": "town_to_farm"
		},
		{
			"instance_id": "town_to_forest",
			"name": "Trail to Whispering Forest",
			"position": [50, 0],
			"required_progression": "",
			"target_spawn": "forest_from_town",
			"target_world": "forest",
			"transition_id": "town_to_forest"
		}
	]

	var spawn_points = {
		"default": [50, 90],
		"from_farm": [50, 92],
		"central_town_from_farm": [50, 92],
		"from_forest": [50, 6],
		"central_town_from_forest": [50, 6],
		"town_from_farm": [50, 92],
		"town_from_forest": [50, 6],
		"town_square": [50, 52],
		"market": [72, 50],
		"residential": [50, 20],
		"community": [20, 52]
	}

	var world_data = {
		"version": 3,
		"world_id": world_id,
		"display_name": display_name,
		"width": width,
		"height": height,
		"tile_size": tile_size,
		"spawn": [50, 90],
		"spawn_points": spawn_points,
		"default_layer": "GROUND",
		"layers": WorldSerializer._get_default_layers(),
		"tiles": tiles,
		"objects": objects,
		"transitions": transitions,
		"prefabs": []
	}

	print("9. Validating and Saving World with WorldSerializer...")
	var target_path = "res://data/worlds/central_town.json"
	var save_ok = WorldSerializer.save_world(target_path, world_data)
	if not save_ok:
		push_error("Failed to save central_town world to " + target_path)
		quit(1)
		return

	print("Central Town World successfully authored and saved to: " + target_path)
	print("Stats: Dimensions: %dx%d | Tiles: %d | Objects: %d | Transitions: %d" % [width, height, tiles.size(), objects.size(), transitions.size()])
	quit(0)
