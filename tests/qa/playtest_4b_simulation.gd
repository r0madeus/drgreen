extends Node

var main_node = null
var test_passed = true
var test_errors = []

func _init() -> void:
	pass

func run_simulation() -> void:
	print("[Playtest 4B] Starting physical input simulation...")
	
	var main_scene = load("res://scenes/main.tscn")
	main_node = main_scene.instantiate()
	get_tree().root.add_child(main_node)
	
	for i in range(10): await get_tree().physics_frame
	
	print("[Playtest 4B] STEP 1: Main Menu New Game")
	main_node.start_gameplay(1, true)
	for i in range(30): await get_tree().physics_frame
	
	var player = get_tree().root.find_child("Player", true, false)
	if not player:
		_fail("Player not found in SceneTree!")
		return
		
	print("[Playtest 4B] Nodes in World:")
	var w_scene = main_node.current_world_scene
	if w_scene:
		for c in w_scene.get_children():
			print(" - ", c.name)
		
	var im = get_tree().root.get_node_or_null("InventoryManager")
	var pid = player.player_id if "player_id" in player else ""
	if im:
		im.add_item(pid, "item_mushroom", 1)
		im.add_item(pid, "item_starpetal", 1)
		im.add_item(pid, "hoe_basic", 1)
		im.add_item(pid, "watering_can_basic", 1)
	
	print("[Playtest 4B] STEP 2: Moving Player to NPC (10, 11)")
	player.global_position = Vector2(10 * 32, 11 * 32)
	for i in range(5): await get_tree().physics_frame
	
	print("[Playtest 4B] STEP 3: Simulating 'move_up' then 'interact' input near NPC")
	_press_action("move_up")
	for i in range(5): await get_tree().physics_frame
	_press_action("interact")
	for i in range(15): await get_tree().physics_frame
	
	var dm = get_tree().root.get_node_or_null("DialogueManager")
	if dm and dm.current_dialogue_id != "":
		print("[Playtest 4B] Dialogue opened! Simulating next...")
		_press_action("interact")
		for i in range(15): await get_tree().physics_frame
	else:
		print("[Playtest 4B] WARNING: Dialogue did not open!")
	
	var qm = get_tree().root.get_node_or_null("QuestManager")
	if qm:
		var qstat = qm.get_quest_status("", "quest_luminous")
		var pqstat = qm.get_quest_status("player_001", "quest_luminous")
		if qstat == "active" or pqstat == "active":
			print("[Playtest 4B] SUCCESS: quest_luminous started via interaction")
		else:
			_fail("quest_luminous did not start! Status: " + str(qstat) + " / " + str(pqstat))
			
	print("[Playtest 4B] STEP 4: Simulating Combination UI")
	var cm = get_tree().root.get_node_or_null("CombinationManager")
	if cm:
		var result = cm.combine(pid, "item_mushroom", "item_starpetal")
		if result.get("success", false) and result.get("result") == "seed_luminous_spore":
			print("[Playtest 4B] SUCCESS: Combination produced seed_luminous_spore")
		else:
			_fail("Combination failed or wrong output! Result: " + str(result))
			
	print("[Playtest 4B] STEP 5: Simulating Farming (Plant & Water) at 18, 12")
	player.global_position = Vector2(18 * 32, 13 * 32)
	for i in range(5): await get_tree().physics_frame
	_press_action("move_up")
	for i in range(5): await get_tree().physics_frame
	
	# Till
	if im: im.select_item(pid, "hoe_basic")
	var tilled = player.use_tool_at(Vector2i(18, 12))
	print("[Playtest 4B] Till result: ", tilled)
	for i in range(5): await get_tree().physics_frame
	
	# Plant
	if im: im.select_item(pid, "seed_luminous_spore")
	var planted = player.use_tool_at(Vector2i(18, 12))
	if planted:
		print("[Playtest 4B] SUCCESS: Planted luminous spore")
	else:
		_fail("Could not plant luminous spore")
		
	# Skip growth
	if im: im.add_item(pid, "item_luminous_spore", 1)
	
	print("[Playtest 4B] STEP 6: Returning to NPC & completing quest")
	player.global_position = Vector2(10 * 32, 11 * 32)
	for i in range(5): await get_tree().physics_frame
	
	_press_action("move_up")
	for i in range(5): await get_tree().physics_frame
	_press_action("interact")
	for i in range(15): await get_tree().physics_frame
	if dm and dm.current_dialogue_id != "":
		_press_action("interact")
		for i in range(15): await get_tree().physics_frame
		
	if qm:
		var qstat2 = qm.get_quest_status("", "quest_luminous")
		var pqstat2 = qm.get_quest_status("player_001", "quest_luminous")
		if qstat2 == "completed" or pqstat2 == "completed":
			print("[Playtest 4B] SUCCESS: Quest completed!")
		else:
			_fail("Quest was not completed! Status: " + str(qstat2) + " / " + str(pqstat2))
		
	var pm = get_tree().root.get_node_or_null("ProgressionManager")
	if pm:
		if pm.has_method("check_unlocks"):
			pm.check_unlocks()
		if pm.is_world_unlocked("luminous_grove"):
			print("[Playtest 4B] SUCCESS: World unlocked!")
		else:
			_fail("World luminous_grove did not unlock!")
			
	var sm = get_tree().root.get_node_or_null("SaveManager")
	if sm:
		sm.save_to_slot(1)
		
	print("[Playtest 4B] Done.")
	if test_passed:
		print("RESULT: PLAYTEST PASS")
		get_tree().quit(0)
	else:
		print("RESULT: PLAYTEST FAIL")
		for e in test_errors: print(" - ", e)
		get_tree().quit(1)

func _press_action(action: String) -> void:
	var ev = InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	
	var ev2 = InputEventAction.new()
	ev2.action = action
	ev2.pressed = false
	Input.parse_input_event(ev2)

func _fail(msg: String) -> void:
	test_passed = false
	test_errors.append(msg)
	printerr("[FAIL] " + msg)
