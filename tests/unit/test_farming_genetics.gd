extends TestCase

func get_name() -> String:
	return "FarmingGenetics"

func run_tests() -> void:
	_setup_test()
	_test_t01_genetic_seed_planting()
	_test_t08_growth_speed()
	_test_t09_water_required()
	_test_t05_productivity_distribution()
	_test_t10_legacy_plant_compatibility()


var test_prof: GeneticProfile
var test_hash: String

func _setup_test() -> void:
	# Mock dependencies
	var root = Engine.get_main_loop().root
	
	if not root.has_node("AudioManager"):
		var am = Node.new()
		am.name = "AudioManager"
		am.set_script(GDScript.new())
		am.get_script().source_code = """
extends Node
func play_sfx(_a, _b=0, _c=0): pass
func play_music(_a): pass
func stop_music(): pass
"""
		am.get_script().reload()
		root.add_child(am)
		
	if not root.has_node("EventBus"):
		var eb = Node.new()
		eb.name = "EventBus"
		eb.set_script(GDScript.new())
		eb.get_script().source_code = """
extends Node
signal plant_planted(p, pos, c)
signal plant_watered(p, pos)
signal plant_harvested(p, pos, c, y)
signal tile_changed(pos, data)
signal tool_used(t, pos)
signal resource_collected(i, c)
signal resource_destroyed(n, pos)
signal soil_tilled(pos)
"""
		eb.get_script().reload()
		root.add_child(eb)

	# Clean Singletons
	var pm = root.get_node_or_null("PlantManager")
	if pm:
		pm.plants_database.clear()
		pm.plants_database["red_flower"] = {
			"id": "red_flower",
			"harvest": { "yield": [1, 2] },
			"growth": { "stages": 3, "days_per_stage": [1, 1, 1] }
		}
	
	var tr = root.get_node_or_null("TraitRegistry")
	if not tr:
		tr = Node.new()
		tr.name = "TraitRegistry"
		tr.set_script(preload("res://systems/genetics/trait_registry.gd"))
		root.add_child(tr)
		
	var wm = root.get_node_or_null("WorldManager")
	if not wm:
		wm = Node.new()
		wm.name = "WorldManager"
		wm.set_script(preload("res://systems/world/world_manager.gd"))
		root.add_child(wm)
		wm._initialize_worlds()

	# Create a genetic profile
	test_prof = GeneticProfile.new()
	test_prof.water_required = false
	test_prof.growth_speed = "fast"
	test_prof.productivity = 3
	test_hash = test_prof.get_identity()

func _test_t01_genetic_seed_planting() -> void:
	# Add seed to PlayerState
	var ps = PlayerState.new()
	ps.player_id = "player_A"
	ps.add_item("seed_red_flower", 1, test_prof)
	assert_true(ps.has_item("seed_red_flower::" + test_hash, 1), "Player should have genetic seed")
	
	# Setup GridManager
	var gm = preload("res://systems/grid/grid_manager.gd").new()
	gm.initialize_grid()
	var tile = GridTileData.new(Vector2i(2, 2), "soil")
	gm.tiles[Vector2i(2, 2)] = tile
	
	# Extract exact profile data
	var prof_dict = ps.genetic_instances[test_hash]
	var removed = ps.remove_item("seed_red_flower::" + test_hash, 1)
	assert_true(removed, "Seed removed from inventory")
	
	gm.plant_seed(Vector2i(2, 2), "red_flower", "player_A", test_hash, prof_dict)
	
	assert_eq(tile.plant_id, "red_flower", "Planted base crop")
	assert_eq(tile.genetic_identity, test_hash, "Tile holds genetic identity")
	assert_eq(str(tile.genetic_profile.get("growth_speed", "")), "fast", "Tile holds genetic profile")

func _test_t08_growth_speed() -> void:
	var pm = Engine.get_main_loop().root.get_node_or_null("PlantManager")
	var fast_res = pm.calculate_growth("red_flower", 0, 1, test_prof.to_dict())
	assert_eq(fast_res.get("new_stage", 0), 1, "Fast growth requires 0 days (1-1), so 1 day matures it")

func _test_t09_water_required() -> void:
	# Bypass water check
	var gm = preload("res://systems/grid/grid_manager.gd").new()
	Engine.get_main_loop().root.add_child(gm) # for _spawn_plant_instance
	gm.initialize_grid()
	var t = GridTileData.new(Vector2i(2, 2), "soil"); t.state = "empty"; gm.tiles[Vector2i(2, 2)] = t
	
	gm.plant_seed(Vector2i(2, 2), "red_flower", "player_A", test_hash, test_prof.to_dict())
	var inst = gm.plant_instances[Vector2i(2, 2)]
	
	inst.watered_today = false
	var advanced = inst.advance_growth()
	assert_true(advanced, "Crop grew despite no water because water_required=false")
	gm.queue_free()

func _test_t05_productivity_distribution() -> void:
	var pm = Engine.get_main_loop().root.get_node_or_null("PlantManager")
	var counts = {1:0, 2:0, 3:0}
	var iters = 1000
	for i in range(iters):
		var y = pm.get_harvest_yield("red_flower", test_prof.to_dict())
		counts[y] += 1
		
	# Prod level 3: 30% 1, 40% 2, 30% 3
	var p1 = float(counts[1])/iters
	var p2 = float(counts[2])/iters
	var p3 = float(counts[3])/iters
	assert_true(abs(p1 - 0.3) < 0.05, "Level 3 Productivity 1-yield probability approx 30%%")
	assert_true(abs(p2 - 0.4) < 0.05, "Level 3 Productivity 2-yield probability approx 40%%")
	assert_true(abs(p3 - 0.3) < 0.05, "Level 3 Productivity 3-yield probability approx 30%%")

func _test_t10_legacy_plant_compatibility() -> void:
	var gm = preload("res://systems/grid/grid_manager.gd").new()
	Engine.get_main_loop().root.add_child(gm)
	gm.initialize_grid()
	var t = GridTileData.new(Vector2i(2, 2), "soil"); t.state = "empty"; gm.tiles[Vector2i(2, 2)] = t
	gm.plant_seed(Vector2i(2, 2), "red_flower", "player_A") # No genetic data
	
	var inst = gm.plant_instances[Vector2i(2, 2)]
	inst.watered_today = false
	var advanced = inst.advance_growth()
	assert_false(advanced, "Legacy crop with no genetic data still requires water")
	gm.queue_free()
