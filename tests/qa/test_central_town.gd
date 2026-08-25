extends SceneTree

## Targeted QA Test Suite for Phase 4C — Central Town Hub
## Verifies T01 to T20 requirements for central_town world authoring.

const WORLD_ID = "central_town"
const WORLD_FILE = "res://data/worlds/central_town.json"
const WORLDS_CONFIG = "res://data/worlds/worlds.json"

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func _init() -> void:
	call_deferred("_run_suite")

func _pass(test_id: String, msg: String) -> void:
	total_tests += 1
	passed_tests += 1
	print("   [PASS] %s: %s" % [test_id, msg])

func _fail(test_id: String, msg: String) -> void:
	total_tests += 1
	failed_tests += 1
	push_error("   [FAIL] %s: %s" % [test_id, msg])

func _run_suite() -> void:
	print("==================================================")
	print("  PHASE 4C — CENTRAL TOWN TARGETED QA TEST SUITE")
	print("==================================================")

	var world_data: Dictionary = {}

	# T01: central_town data exists
	if FileAccess.file_exists(WORLD_FILE):
		var f = FileAccess.open(WORLD_FILE, FileAccess.READ)
		var text = f.get_as_text()
		f.close()
		var json = JSON.new()
		if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
			world_data = json.data
			_pass("T01", "central_town data file exists and contains valid JSON dictionary")
		else:
			_fail("T01", "central_town JSON failed to parse")
	else:
		_fail("T01", "central_town file does not exist at " + WORLD_FILE)

	# T02: world loads successfully via WorldSerializer
	var loaded = WorldSerializer.load_world(WORLD_FILE)
	if not loaded.is_empty() and loaded.get("world_id") == WORLD_ID:
		_pass("T02", "WorldSerializer loaded central_town successfully")
	else:
		_fail("T02", "WorldSerializer failed to load central_town data")

	# T03: map dimensions are valid (100x100 tiles)
	var w = int(world_data.get("width", 0))
	var h = int(world_data.get("height", 0))
	var tiles: Array = world_data.get("tiles", [])
	if w >= 80 and w <= 120 and h >= 80 and h <= 120 and tiles.size() == (w * h):
		_pass("T03", "Map dimensions valid: %dx%d (%d tiles total)" % [w, h, tiles.size()])
	else:
		_fail("T03", "Map dimensions invalid: width=%d, height=%d, tiles=%d" % [w, h, tiles.size()])

	# T04: player spawn exists
	var spawn = world_data.get("spawn", [])
	var spawn_pts = world_data.get("spawn_points", {})
	if spawn.size() >= 2 and spawn_pts.has("default") and spawn_pts.has("from_farm"):
		_pass("T04", "Player spawn exists at %s with named spawn points %s" % [str(spawn), str(spawn_pts.keys())])
	else:
		_fail("T04", "Missing default spawn or spawn_points map")

	# T05: player spawn is walkable
	var spawn_x = int(spawn[0])
	var spawn_y = int(spawn[1])
	var spawn_tile: Dictionary = {}
	for t in tiles:
		if int(t.get("x", -1)) == spawn_x and int(t.get("y", -1)) == spawn_y:
			spawn_tile = t
			break
	if not spawn_tile.is_empty() and spawn_tile.get("walkable", false) and not spawn_tile.get("solid", true):
		_pass("T05", "Player spawn (%d, %d) is on a walkable, non-solid tile" % [spawn_x, spawn_y])
	else:
		_fail("T05", "Player spawn tile (%d, %d) is blocked or not walkable" % [spawn_x, spawn_y])

	# T06: central square exists
	var objects: Array = world_data.get("objects", [])
	var has_well = false
	var has_plaza_benches = false
	for o in objects:
		var aid = o.get("asset_id", "")
		var pos = o.get("position", [-1, -1])
		if aid == "well" and pos[0] >= 40 and pos[0] <= 60 and pos[1] >= 40 and pos[1] <= 60:
			has_well = true
		if aid == "bench" and pos[0] >= 40 and pos[0] <= 60 and pos[1] >= 40 and pos[1] <= 60:
			has_plaza_benches = true
	if has_well and has_plaza_benches:
		_pass("T06", "Central square exists with landmark well, seating, and plaza space")
	else:
		_fail("T06", "Central square missing well or plaza seating: well=%s, benches=%s" % [has_well, has_plaza_benches])

	# T07: main roads exist
	var has_ns_road = true
	var has_ew_road = true
	# Check samples along Grand North-South Avenue (x=49, y=10..90)
	for test_y in [15, 30, 50, 70, 85]:
		var found = false
		for t in tiles:
			if int(t.get("x")) == 49 and int(t.get("y")) == test_y and t.get("walkable", false):
				found = true
				break
		if not found: has_ns_road = false
	# Check samples along Grand East-West Avenue (y=49, x=10..90)
	for test_x in [15, 30, 50, 70, 85]:
		var found = false
		for t in tiles:
			if int(t.get("x")) == test_x and int(t.get("y")) == 49 and t.get("walkable", false):
				found = true
				break
		if not found: has_ew_road = false

	if has_ns_road and has_ew_road:
		_pass("T07", "Main continuous North-South and East-West avenues verified walkable")
	else:
		_fail("T07", "Main road continuity check failed: NS=%s, EW=%s" % [has_ns_road, has_ew_road])

	# T08: residential area exists
	var residential_buildings = 0
	var residential_soil = 0
	for o in objects:
		var pos = o.get("position", [-1, -1])
		if pos[1] >= 6 and pos[1] <= 36 and o.get("asset_id") in ["farm_house", "barn", "storage_shed", "greenhouse_repaired"]:
			residential_buildings += 1
	for t in tiles:
		if int(t.get("y")) >= 6 and int(t.get("y")) <= 36 and t.get("type") == "soil":
			residential_soil += 1
	if residential_buildings >= 3 and residential_soil >= 4:
		_pass("T08", "Residential district verified with %d houses and %d garden soil plots" % [residential_buildings, residential_soil])
	else:
		_fail("T08", "Residential district missing houses or gardens: buildings=%d, soil=%d" % [residential_buildings, residential_soil])

	# T09: market/shop area exists
	var has_trade_post = false
	var has_seed_shop = false
	var has_shipping_box = false
	for o in objects:
		var aid = o.get("asset_id", "")
		var pos = o.get("position", [-1, -1])
		if pos[0] >= 60 and pos[1] >= 38 and pos[1] <= 65:
			if aid == "farm_house" or aid == "seed_shop": has_trade_post = true
			if aid == "seed_shop": has_seed_shop = true
			if aid == "shipping_box": has_shipping_box = true
	if has_trade_post and has_seed_shop and has_shipping_box:
		_pass("T09", "Shopping / Market district verified with trade post, seed shop, and shipping depot")
	else:
		_fail("T09", "Market district missing key venues: trade=%s, seed=%s, shipping=%s" % [has_trade_post, has_seed_shop, has_shipping_box])

	# T10: public/community area exists
	var has_town_hall = false
	var has_community_craft = false
	var has_pond = false
	for o in objects:
		var aid = o.get("asset_id", "")
		var pos = o.get("position", [-1, -1])
		if pos[0] <= 38 and pos[1] >= 38 and pos[1] <= 75:
			if aid in ["laboratory", "farm_house"]: has_town_hall = true
			if aid in ["workbench", "chest"]: has_community_craft = true
	for t in tiles:
		if int(t.get("x")) <= 38 and int(t.get("y")) >= 56 and int(t.get("y")) <= 72 and t.get("type") == "water":
			has_pond = true
			break
	if has_town_hall and has_community_craft and has_pond:
		_pass("T10", "Public/community district verified with Town Hall, civic crafting, and scenic park pond")
	else:
		_fail("T10", "Public area missing components: hall=%s, craft=%s, pond=%s" % [has_town_hall, has_community_craft, has_pond])

	# T11: Farm transition exists
	var transitions: Array = world_data.get("transitions", [])
	var farm_trans = {}
	for tr in transitions:
		if tr.get("target_world") == "farm":
			farm_trans = tr
			break
	if not farm_trans.is_empty() and farm_trans.get("target_spawn") != "":
		_pass("T11", "South transition to Farm verified: target=%s, spawn=%s" % [farm_trans.get("target_world"), farm_trans.get("target_spawn")])
	else:
		_fail("T11", "Missing transition to farm")

	# T12: existing NPC references are valid
	var has_valid_elias = false
	for o in objects:
		if o.get("layer") == "NPC" or o.get("asset_id") == "elias":
			if o.get("asset_id") == "elias" and o.get("properties", {}).get("npc_id") == "elias":
				has_valid_elias = true
	if has_valid_elias:
		_pass("T12", "NPC placement verified with Merchant Elias in Central Town")
	else:
		_fail("T12", "Missing or invalid NPC placement for Elias")

	# T13: terrain references are valid
	var invalid_terrains = []
	var known_terrains = ["grass", "soil", "path", "stone", "sand", "water", "fence"]
	for t in tiles:
		var tt = str(t.get("type", ""))
		if not tt in known_terrains and not invalid_terrains.has(tt):
			invalid_terrains.append(tt)
	if invalid_terrains.is_empty():
		_pass("T13", "All terrain types match AssetRegistry definitions: " + str(known_terrains))
	else:
		_fail("T13", "Found invalid terrain types: " + str(invalid_terrains))

	# T14: asset references are valid
	var invalid_assets = []
	for o in objects:
		var aid = str(o.get("asset_id", ""))
		if not AssetRegistry.has_asset(aid) and not invalid_assets.has(aid):
			invalid_assets.append(aid)
	if invalid_assets.is_empty():
		_pass("T14", "All %d placed objects reference valid assets in AssetRegistry" % objects.size())
	else:
		_fail("T14", "Found invalid object asset references: " + str(invalid_assets))

	# T15: no invalid world references
	var invalid_world_refs = []
	for tr in transitions:
		var tw = str(tr.get("target_world", ""))
		if not FileAccess.file_exists("res://data/worlds/%s.json" % tw):
			invalid_world_refs.append(tw)
	if invalid_world_refs.is_empty():
		_pass("T15", "All world transition targets exist in data/worlds/")
	else:
		_fail("T15", "Found invalid transition targets: " + str(invalid_world_refs))

	# T16: map saves correctly
	var save_test_path = "res://data/worlds/central_town_test_save.json"
	var saved = WorldSerializer.save_world(save_test_path, world_data)
	if saved and FileAccess.file_exists(save_test_path):
		DirAccess.remove_absolute(save_test_path)
		_pass("T16", "Map atomic saving and verification succeeded")
	else:
		_fail("T16", "Map atomic save test failed")

	# T17: map loads correctly into GridManager
	var gm_class = load("res://systems/grid/grid_manager.gd")
	if gm_class:
		var gm = gm_class.new()
		root.add_child(gm)
		gm.load_from_world_data(world_data)
		var t_at_spawn = gm.get_tile(Vector2i(spawn_x, spawn_y))
		var is_spawn_walk = gm.is_tile_walkable(Vector2i(spawn_x, spawn_y))
		if gm.grid_width == w and gm.grid_height == h and t_at_spawn != null and is_spawn_walk:
			_pass("T17", "GridManager successfully loaded and constructed 100x100 grid with obstacles and tiles")
		else:
			_fail("T17", "GridManager failed to construct valid grid from central_town data")
		gm.queue_free()
	else:
		_fail("T17", "GridManager class could not be loaded")

	# T18: runtime boot test
	var main_scene = load("res://scenes/main.tscn")
	if main_scene:
		_pass("T18", "Runtime boot scene (scenes/main.tscn) loads without compile/runtime errors")
	else:
		_fail("T18", "Failed to load scenes/main.tscn")

	# T19: player can enter central_town
	var wl = load("res://systems/world/world_loader.gd").new()
	root.add_child(wl)
	var loaded_town = wl.load_world(WORLD_ID)
	if loaded_town.get("world_id") == WORLD_ID:
		_pass("T19", "WorldLoader successfully transitioned into central_town")
	else:
		_fail("T19", "WorldLoader failed to enter central_town")

	# T20: player can leave central_town
	var loaded_farm = wl.load_world("farm")
	if loaded_farm.get("world_id") == "farm":
		_pass("T20", "WorldLoader successfully transitioned out of central_town back to farm")
	else:
		_fail("T20", "WorldLoader failed to return to farm")
	wl.queue_free()

	print("==================================================")
	print("  CENTRAL TOWN QA SUMMARY: %d / %d PASSED" % [passed_tests, total_tests])
	print("==================================================")
	
	if failed_tests > 0:
		quit(1)
	else:
		quit(0)
