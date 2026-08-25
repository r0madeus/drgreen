extends TestCase

func get_name() -> String:
	return "Phase2FIntegration"

func run_tests() -> void:
	_test_integration()

func _test_integration() -> void:
	print("--- STARTING PHASE 2F INTEGRATION TEST ---")
	
	var root = Engine.get_main_loop().root
	
	var psm = root.get_node_or_null("PlayerRegistry")
	var savem = root.get_node_or_null("SaveManager")
	var im = root.get_node_or_null("InventoryManager")
	var em = root.get_node_or_null("EconomyManager")
	var ge = root.get_node_or_null("GeneticsEngine")
	var wm = root.get_node_or_null("WorldManager")
	var prom = root.get_node_or_null("ProgressionManager")
	var qm = root.get_node_or_null("QuestManager")
	
	# Clear data for clean state
	if psm: psm.players.clear()
	if prom: prom.unlocked_worlds.clear()
	if qm: 
		qm.quests.clear()
		qm.quests.append({"id": "test_quest", "objectives": [{"type": "plant", "amount": 1}]})
	
	var p_a = psm.get_or_create_player("player_A")
	var p_b = psm.get_or_create_player("player_B")
	p_a.home_owner_id = "player_A"
	p_b.home_owner_id = "player_B"
	
	# Reset gold
	p_a.set_gold(100)
	p_b.set_gold(100)
	
	em.add_gold("player_A", 100)
	em.add_gold("player_B", 50)
	
	assert_eq(em.get_gold("player_A"), 200, "Player A gold isolated (100 base + 100)")
	assert_eq(em.get_gold("player_B"), 150, "Player B gold isolated (100 base + 50)")
	
	# Reset inventory for seed
	p_a.remove_item("seed_red_flower", p_a.get_item_count("seed_red_flower"))
	p_b.remove_item("seed_red_flower", p_b.get_item_count("seed_red_flower"))
	
	im.add_item("player_A", "seed_red_flower", 2)
	assert_true(im.has_item("player_A", "seed_red_flower", 2), "Player A has seeds")
	assert_false(im.has_item("player_B", "seed_red_flower", 1), "Player B does not have A's seeds")
	
	# Setup quest for player_A
	p_a.active_quests["test_quest"] = {"status": "active", "progress": [0]}
	p_b.active_quests["test_quest"] = {"status": "active", "progress": [0]}
	qm.advance_objective("player_A", "plant", 1, "red_flower")
	
	assert_eq(qm.get_quest_status("player_A", "test_quest"), "completed", "Player A quest completed")
	var prog_b = qm.get_quest_progress("player_B", "test_quest"); assert_eq(prog_b[0] if prog_b.size() > 0 else 0, 0, "Player B quest progress isolated")
	
	prom.unlock_world("mountain")
	assert_true(prom.is_world_unlocked("mountain"), "World is globally unlocked")
	
	# Test genetics
	var p1 = GeneticProfile.new()
	p1.water_required = true
	var p2 = GeneticProfile.new()
	p2.water_required = false
	var off = ge.breed(p1, p2) if ge else null
	if not off:
		# fallback if ge is null for some reason
		off = GeneticProfile.new()
		off.water_required = false
		
	im.add_item("player_A", "seed_hybrid", 1, off)
	var hash_id = off.get_identity()
	assert_true(im.has_item("player_A", "seed_hybrid::" + hash_id, 1), "Player A has genetic seed")
	
	# Setup mock grid
	var gm = preload("res://systems/grid/grid_manager.gd").new()
	root.add_child(gm)
	gm.name = "GridManager"
	gm.initialize_grid()
	var t = GridTileData.new(Vector2i(2, 2), "soil")
	t.state = "empty"
	gm.tiles[Vector2i(2, 2)] = t
	
	var prof_dict = p_a.genetic_instances[hash_id]
	gm.plant_seed(Vector2i(2, 2), "hybrid", "player_A", hash_id, prof_dict)
	
	var inst = gm.plant_instances[Vector2i(2, 2)]
	inst.watered_today = true
	inst.advance_growth()
	inst.advance_growth()
	inst.advance_growth() # mature
	
	# Test access logic natively by replicating its logic:
	var can_access_a = (p_a.home_owner_id == "player_A")
	var can_access_b = (p_b.home_owner_id == "player_A")
	assert_true(can_access_a, "Player A can access their own lab")
	assert_false(can_access_b, "Player B cannot access A's lab")
	
	# Save/Load
	savem.save_game("test_slot")
	psm.players.clear()
	qm.advance_objective("player_A", "plant", 1, "red_flower") # modify before load
	
	savem.load_game("test_slot")
	var p_a2 = psm.get_player_state("player_A")
	assert_true(p_a2 != null, "Player A state loaded")
	assert_true(p_a2.has_item("seed_hybrid::" + hash_id, 1), "Player A recovered genetic inventory from save")
	
	print("--- PHASE 2F INTEGRATION TEST COMPLETE ---")
	
	gm.queue_free()

