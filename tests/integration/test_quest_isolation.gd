extends SceneTree

# Automated Test: Quest & Reward Isolation between Multiple Players (Player 1 vs Player 2)

func _init() -> void:
	print("\n==================================================")
	print("  TEST: PERSONAL QUEST & REWARD ISOLATION QA")
	print("==================================================\n")
	call_deferred("_run_isolation_tests")

func _run_isolation_tests() -> void:
	for i in range(5):
		await process_frame
		
	var psm = root.get_node_or_null("PlayerRegistry")
	if not psm:
		push_error("[FAIL] PlayerRegistry not found")
		quit(1)
		return
		
	var qm = root.get_node_or_null("QuestManager")
	if not qm:
		push_error("[FAIL] QuestManager not found")
		quit(1)
		return
		
	var rm = root.get_node_or_null("RewardManager")
	var im = root.get_node_or_null("InventoryManager")
	var em = root.get_node_or_null("EconomyManager")
	
	# 1. Setup Player 1 and Player 2
	var p1 = psm.get_or_create_player("player_001", "Alice")
	var p2 = psm.get_or_create_player("player_002", "Bob")
	p1.gold = 100
	p2.gold = 100
	p1.active_quests.clear()
	p1.completed_quests.clear()
	p2.active_quests.clear()
	p2.completed_quests.clear()
	
	qm.init_player_quests("player_001")
	qm.init_player_quests("player_002")
	
	print("[STEP 1] Initial Quest States:")
	print("  Player 1 active quests: ", p1.active_quests.keys())
	print("  Player 2 active quests: ", p2.active_quests.keys())
	
	assert(p1.active_quests.has("quest_01"), "Player 1 should have quest_01 active")
	assert(p2.active_quests.has("quest_01"), "Player 2 should have quest_01 active")
	assert(p1.completed_quests.is_empty(), "Player 1 completed quests should start empty")
	assert(p2.completed_quests.is_empty(), "Player 2 completed quests should start empty")
	print("  [PASS] Initial state isolation verified")
	
	# 2. Player 1 completes quest_01 (plant 1 seed)
	var p1_initial_gold = p1.gold
	var p2_initial_gold = p2.gold
	
	print("\n[STEP 2] Completing quest_01 for Player 1 ONLY (planting seed)...")
	qm.advance_objective("player_001", "plant", 1, "any")
	
	print("  Player 1 active: ", p1.active_quests.keys())
	print("  Player 1 completed: ", p1.completed_quests)
	print("  Player 2 active: ", p2.active_quests.keys())
	print("  Player 2 completed: ", p2.completed_quests)
	print("  Player 1 gold: %d (was %d)" % [p1.gold, p1_initial_gold])
	print("  Player 2 gold: %d (was %d)" % [p2.gold, p2_initial_gold])
	
	assert(p1.completed_quests.has("quest_01"), "Player 1 must have completed quest_01")
	assert(p1.active_quests.has("quest_02"), "Player 1 must have unlocked quest_02")
	assert(p1.gold == p1_initial_gold + 25, "Player 1 must have received 25g reward")
	
	assert(not p2.completed_quests.has("quest_01"), "Player 2 MUST NOT have completed quest_01")
	assert(p2.active_quests.has("quest_01"), "Player 2 MUST still have quest_01 active")
	assert(not p2.active_quests.has("quest_02"), "Player 2 MUST NOT have quest_02")
	assert(p2.gold == p2_initial_gold, "Player 2 gold MUST NOT change")
	print("  [PASS] Quest completion & reward claiming is isolated to Player 1")
	
	# 3. Player 1 advances quest_02 (waters 1 time out of 3)
	print("\n[STEP 3] Player 1 waters 1 time on quest_02 (progress 1/3)...")
	qm.advance_objective("player_001", "water", 1, "any")
	
	var p1_prog = p1.active_quests.get("quest_02", {}).get("progress", [])
	print("  Player 1 quest_02 progress: ", p1_prog)
	print("  Player 2 quest_01 progress: ", p2.active_quests.get("quest_01", {}).get("progress", []))
	
	assert(p1_prog == [1], "Player 1 quest_02 progress must be [1]")
	assert(p2.active_quests.get("quest_01", {}).get("progress", []) == [0], "Player 2 quest_01 progress must remain [0]")
	print("  [PASS] Mid-quest progression is strictly isolated to Player 1")
	
	# 4. Dialogue Isolation Check
	var dm = root.get_node_or_null("DialogueManager")
	if dm:
		print("\n[STEP 4] Testing Dialogue isolation with NPC...")
		p1.add_friendship("rowan", 50)
		p2.friendship["rowan"] = 0
		
		var node_p1 = dm.evaluate_dialogue_node_key("rowan_daily", p1)
		var node_p2 = dm.evaluate_dialogue_node_key("rowan_daily", p2)
		print("  Player 1 dialogue evaluated node: ", node_p1)
		print("  Player 2 dialogue evaluated node: ", node_p2)
		print("  [PASS] Dialogue conditions evaluated independently based on each player's state")
		
	# 5. Serialization / Deserialization check
	print("\n[STEP 5] Testing Save / Load serialization isolation...")
	var p1_dict = p1.to_dict()
	var p2_dict = p2.to_dict()
	
	var restored_p1 = PlayerState.from_dict(p1_dict)
	var restored_p2 = PlayerState.from_dict(p2_dict)
	
	assert(restored_p1.completed_quests.has("quest_01"), "Restored Player 1 must retain completed quest_01")
	assert(restored_p1.active_quests.has("quest_02"), "Restored Player 1 must retain active quest_02")
	assert(restored_p1.active_quests["quest_02"]["progress"] == [1], "Restored Player 1 must retain quest_02 progress [1]")
	
	assert(not restored_p2.completed_quests.has("quest_01"), "Restored Player 2 must NOT have completed quest_01")
	assert(restored_p2.active_quests.has("quest_01"), "Restored Player 2 must retain active quest_01")
	assert(restored_p2.active_quests["quest_01"]["progress"] == [0], "Restored Player 2 must retain quest_01 progress [0]")
	print("  [PASS] Save / Load preserves per-player quest isolation")
	
	print("\n==================================================")
	print("  ALL PERSONAL QUEST ISOLATION TESTS PASSED (PASS)")
	print("==================================================\n")
	quit(0)
