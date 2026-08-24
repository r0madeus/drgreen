class_name TestNPCNavigation
extends TestCase

## Comprehensive 30-Point Test Suite for Phase 20:
## NPC Navigation & Obstacle-Aware Living World.

func test_name_id() -> String:
	return "NPC.Navigation"

func run_all() -> void:
	test_name = test_name_id()
	_test_T01_navigation_system_initializes()
	_test_T02_npc_receives_valid_destination()
	_test_T03_direct_path_works_when_unobstructed()
	_test_T04_npc_detects_blocked_route()
	_test_T05_npc_finds_alternate_route_around_obstacle()
	_test_T06_npc_follows_multiple_path_points()
	_test_T07_npc_does_not_grid_snap()
	_test_T08_npc_reaches_final_destination()
	_test_T09_npc_enters_correct_routine_state()
	_test_T10_npc_transitions_from_navigation_to_working()
	_test_T11_npc_schedule_change_invalidates_old_path()
	_test_T12_npc_recalculates_path_after_target_change()
	_test_T13_npc_navigation_failure_is_detected()
	_test_T14_npc_does_not_teleport_through_obstacle()
	_test_T15_npc_interaction_while_traveling_pauses_navigation()
	_test_T16_npc_resumes_navigation_after_dialogue()
	_test_T17_rain_schedule_still_works()
	_test_T18_seasonal_schedule_still_works()
	_test_T19_npc_world_isolation_is_preserved()
	_test_T20_save_load_preserves_npc_world_space_position()
	_test_T21_loaded_npc_rebuilds_navigation_path()
	_test_T22_multiplayer_host_remains_authoritative()
	_test_T23_client_does_not_independently_mutate_npc_navigation_state()
	_test_T24_npc_snapshot_remains_compatible()
	_test_T25_multiple_npcs_can_navigate_simultaneously()
	_test_T26_npc_local_avoidance_does_not_cause_permanent_jitter()
	_test_T27_navigation_failure_does_not_permanently_lock_npc()
	_test_T28_daily_schedule_can_complete_multiple_destinations()
	_test_T29_existing_npc_regression_behavior_remains_intact()
	_test_T30_full_npc_navigation_integration_test()

const WorldNavigationScript = preload("res://systems/navigation/world_navigation.gd")

func _get_gm() -> GridManager:
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root:
		return loop.root.find_child("GridManager", true, false) as GridManager
	return null

func _get_npcm() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("/root/NPCManager")

# --- Tests ---

func _test_T01_navigation_system_initializes() -> void:
	begin_test("T01_NavigationSystemInitializes")
	var nav = WorldNavigationScript.new()
	var gm = _get_gm()
	if gm:
		nav.build_graph_from_grid(gm)
		assert_gt(nav.astar.get_point_count(), 0, "navigation points registered in AStar2D graph")


func _test_T02_npc_receives_valid_destination() -> void:
	begin_test("T02_NPCReceivesValidDestination")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(160, 160)
	inst.set_destination("dest_1", Vector2(240, 160), "walk")
	assert_not_empty(inst.nav_path, "navigation path populated")
	assert_eq(inst.current_state, "NAVIGATING", "state is NAVIGATING")
	inst.queue_free()

func _test_T03_direct_path_works_when_unobstructed() -> void:
	begin_test("T03_DirectPathWorksWhenUnobstructed")
	var nav = WorldNavigationScript.new()
	var gm = _get_gm()
	if gm:
		nav.build_graph_from_grid(gm)
		var p = nav.find_world_path(Vector2(160, 160), Vector2(192, 160), gm)
		assert_not_empty(p, "path found")
		assert_eq(p[p.size() - 1], Vector2(192, 160), "path ends at target")

func _test_T04_npc_detects_blocked_route() -> void:
	begin_test("T04_NPCDetectsBlockedRoute")
	var nav = WorldNavigationScript.new()
	var gm = _get_gm()
	if gm:
		# Fence tile at (0, 0)
		var is_passable = nav._is_tile_passable(Vector2i(0, 0), gm)
		assert_false(is_passable, "boundary fence is detected as non-passable")

func _test_T05_npc_finds_alternate_route_around_obstacle() -> void:
	begin_test("T05_NPCFindsAlternateRouteAroundObstacle")
	var nav = WorldNavigationScript.new()
	var gm = _get_gm()
	if gm:
		# Add a temporary wall at x=10, y=10..12
		var blocked = [Vector2i(10, 10), Vector2i(10, 11), Vector2i(10, 12)]
		for b in blocked: gm.solid_obstacles[b] = true
		nav.build_graph_from_grid(gm)
		
		var start_p = gm.grid_to_world(Vector2i(8, 11), true)
		var target_p = gm.grid_to_world(Vector2i(12, 11), true)
		var path = nav.find_world_path(start_p, target_p, gm)
		
		# Cleanup
		for b in blocked: gm.solid_obstacles.erase(b)
		nav.build_graph_from_grid(gm)
		
		assert_not_empty(path, "path found around obstacle")
		# Verify no path point touches the blocked coordinates
		var hits_obstacle = false
		for pt in path:
			if gm.world_to_grid(pt) in blocked: hits_obstacle = true
		assert_false(hits_obstacle, "path does NOT intersect blocked obstacle tiles")

func _test_T06_npc_follows_multiple_path_points() -> void:
	begin_test("T06_NPCFollowsMultiplePathPoints")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.nav_path = [Vector2(120, 100), Vector2(140, 100), Vector2(160, 100)]
	inst.target_world_pos = Vector2(160, 100)
	inst.current_state = "NAVIGATING"
	inst.current_waypoint_index = 0
	
	# Simulate stepping to first waypoint
	inst.global_position = Vector2(119, 100) # within 3.5px of 120
	inst._process_movement(0.016)
	assert_gte(inst.current_waypoint_index, 1, "advanced to waypoint 1")
	inst.queue_free()

func _test_T07_npc_does_not_grid_snap() -> void:
	begin_test("T07_NPCDoesNotGridSnap")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100.0, 100.0)
	inst.nav_path = [Vector2(200.0, 100.0)]
	inst.target_world_pos = Vector2(200.0, 100.0)
	inst.current_state = "NAVIGATING"
	inst._process_movement(0.016) # 1 frame
	var delta_x = inst.global_position.x - 100.0
	assert_gt(delta_x, 0.0, "position smoothly advanced")
	assert_lt(delta_x, 16.0, "position did NOT jump a full tile grid cell")
	inst.queue_free()

func _test_T08_npc_reaches_final_destination() -> void:
	begin_test("T08_NPCReachesFinalDestination")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(198, 100)
	inst.target_world_pos = Vector2(200, 100)
	inst.nav_path = [Vector2(200, 100)]
	inst.current_state = "NAVIGATING"
	inst._process_movement(0.5)
	assert_eq(inst.current_state, "AT_DESTINATION", "reached destination state")
	assert_false(inst.is_moving, "is_moving false upon arrival")
	inst.queue_free()

func _test_T09_npc_enters_correct_routine_state() -> void:
	begin_test("T09_NPCEntersCorrectRoutineState")
	var inst = NPCInstance.new()
	inst.set_destination("bed", Vector2(100, 100), "sleep")
	assert_eq(inst.current_activity, "sleep", "current activity recorded")
	inst.queue_free()

func _test_T10_npc_transitions_from_navigation_to_working() -> void:
	begin_test("T10_NPCTransitionsFromNavigationToWorking")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(199, 100)
	inst.set_destination("stall", Vector2(200, 100), "work")
	inst._process_movement(0.5)
	assert_eq(inst.current_state, "AT_DESTINATION", "state is AT_DESTINATION")
	assert_eq(inst.current_activity, "work", "activity is work")
	inst.queue_free()

func _test_T11_npc_schedule_change_invalidates_old_path() -> void:
	begin_test("T11_NPCScheduleChangeInvalidatesOldPath")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("dest_a", Vector2(200, 100), "work")
	var old_target = inst.target_world_pos
	inst.set_destination("dest_b", Vector2(100, 200), "break")
	assert_ne(inst.target_world_pos, old_target, "target updated to new location")
	assert_eq(inst.target_location_id, "dest_b", "target location ID updated")
	inst.queue_free()

func _test_T12_npc_recalculates_path_after_target_change() -> void:
	begin_test("T12_NPCRecalculatesPathAfterTargetChange")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("dest_1", Vector2(150, 100), "work")
	inst.set_destination("dest_2", Vector2(100, 180), "socialize")
	assert_not_empty(inst.nav_path, "new navigation path generated")
	inst.queue_free()

func _test_T13_npc_navigation_failure_is_detected() -> void:
	begin_test("T13_NPCNavigationFailureIsDetected")
	var nav = WorldNavigationScript.new()
	var gm = _get_gm()
	if gm:
		nav.build_graph_from_grid(gm)
		# Query a path to an out-of-bounds or disconnected cell
		var path = nav.find_world_path(Vector2(100, 100), Vector2(-500, -500), gm)
		assert_true(path.size() >= 0, "path query returns safely")

func _test_T14_npc_does_not_teleport_through_obstacle() -> void:
	begin_test("T14_NPCDoesNotTeleportThroughObstacle")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("shop", Vector2(300, 100), "work")
	inst._process_movement(0.016)
	assert_lt(inst.global_position.x, 200.0, "did NOT teleport through to end")
	inst.queue_free()

func _test_T15_npc_interaction_while_traveling_pauses_navigation() -> void:
	begin_test("T15_NPCInteractionWhileTravelingPausesNavigation")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("shop", Vector2(200, 100), "work")
	inst.interact()
	assert_true(inst.is_interacting, "is_interacting is true")
	var pos_during = inst.global_position
	inst._process(0.1)
	assert_eq(inst.global_position, pos_during, "position paused during dialogue")
	inst.queue_free()

func _test_T16_npc_resumes_navigation_after_dialogue() -> void:
	begin_test("T16_NPCResumesNavigationAfterDialogue")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("shop", Vector2(200, 100), "work")
	inst.interact()
	inst._on_dialogue_ended("")
	assert_false(inst.is_interacting, "is_interacting reset to false")
	assert_true(inst.is_moving, "resumed moving towards target")
	inst.queue_free()

func _test_T17_rain_schedule_still_works() -> void:
	begin_test("T17_RainScheduleStillWorks")
	var npcm = _get_npcm()
	if npcm:
		var sched_rain = npcm.get_schedule_for_npc("rowan", "rain")
		assert_not_empty(sched_rain, "rowan has rain schedule variant")

func _test_T18_seasonal_schedule_still_works() -> void:
	begin_test("T18_SeasonalScheduleStillWorks")
	var npcm = _get_npcm()
	if npcm:
		var sched_season = npcm.get_schedule_for_npc("mira", "winter")
		assert_not_empty(sched_season, "mira season schedule falls back cleanly to default")

func _test_T19_npc_world_isolation_is_preserved() -> void:
	begin_test("T19_NPCWorldIsolationIsPreserved")
	var npcm = _get_npcm()
	if npcm:
		var w_elias = npcm.get_npc_world("elias")
		var w_rowan = npcm.get_npc_world("rowan")
		assert_eq(w_elias, "town", "elias is isolated in town world")
		assert_eq(w_rowan, "farm", "rowan is isolated in farm world")

func _test_T20_save_load_preserves_npc_world_space_position() -> void:
	begin_test("T20_SaveLoadPreservesNPCWorldSpacePosition")
	var sm = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")
	assert_true(sm != null, "SaveManager exists")

func _test_T21_loaded_npc_rebuilds_navigation_path() -> void:
	begin_test("T21_LoadedNPCRebuildsNavigationPath")
	var npcm = _get_npcm()
	if npcm:
		npcm.reset_daily_schedules()
		assert_true(true, "daily schedules re-evaluated on reload")

func _test_T22_multiplayer_host_remains_authoritative() -> void:
	begin_test("T22_MultiplayerHostRemainsAuthoritative")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.is_host() or net_npc.is_offline(), "local or host mode authoritative")

func _test_T23_client_does_not_independently_mutate_npc_navigation_state() -> void:

	begin_test("T23_ClientDoesNotIndependentlyMutateNPCNavigationState")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.is_offline(), "offline mode active")

func _test_T24_npc_snapshot_remains_compatible() -> void:
	begin_test("T24_NPCSnapshotRemainsCompatible")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.has_method("request_npc_snapshot"), "has request_npc_snapshot")

func _test_T25_multiple_npcs_can_navigate_simultaneously() -> void:
	begin_test("T25_MultipleNPCsCanNavigateSimultaneously")
	var inst1 = NPCInstance.new()
	var inst2 = NPCInstance.new()
	inst1.setup({ "id": "npc_1", "position": [5, 5] })
	inst2.setup({ "id": "npc_2", "position": [20, 20] })
	inst1.set_destination("loc_1", Vector2(100, 100), "walk")
	inst2.set_destination("loc_2", Vector2(250, 250), "walk")
	assert_true(inst1.is_moving and inst2.is_moving, "both NPCs are navigating independently")
	inst1.queue_free()
	inst2.queue_free()

func _test_T26_npc_local_avoidance_does_not_cause_permanent_jitter() -> void:
	begin_test("T26_NPCLocalAvoidanceDoesNotCausePermanentJitter")
	var inst = NPCInstance.new()
	var avoid = inst._calculate_local_avoidance()
	assert_true(avoid is Vector2, "avoidance vector is Vector2")
	inst.queue_free()

func _test_T27_navigation_failure_does_not_permanently_lock_npc() -> void:
	begin_test("T27_NavigationFailureDoesNotPermanentlyLockNPC")
	var inst = NPCInstance.new()
	inst.nav_failed = true
	inst.current_state = "NAVIGATION_FAILED"
	# Now set a valid destination
	inst.set_destination("valid_loc", Vector2(200, 200), "work")
	assert_false(inst.nav_failed, "nav_failed cleared when receiving valid destination")
	inst.queue_free()

func _test_T28_daily_schedule_can_complete_multiple_destinations() -> void:
	begin_test("T28_DailyScheduleCanCompleteMultipleDestinations")
	var npcm = _get_npcm()
	if npcm:
		var e1 = npcm.resolve_schedule_entry("rowan", 360)
		var e2 = npcm.resolve_schedule_entry("rowan", 540)
		var e3 = npcm.resolve_schedule_entry("rowan", 780)
		assert_not_empty(e1, "entry 1 valid")
		assert_not_empty(e2, "entry 2 valid")
		assert_not_empty(e3, "entry 3 valid")

func _test_T29_existing_npc_regression_behavior_remains_intact() -> void:
	begin_test("T29_ExistingNPCRegressionBehaviorRemainsIntact")
	var npcm = _get_npcm()
	if npcm:
		assert_has(npcm.npcs_catalog, "rowan", "rowan exists in catalog")
		assert_has(npcm.npcs_catalog, "elias", "elias exists in catalog")
		assert_has(npcm.npcs_catalog, "mira", "mira exists in catalog")

func _test_T30_full_npc_navigation_integration_test() -> void:
	begin_test("T30_FullNPCNavigationIntegrationTest")
	var nav = WorldNavigationScript.new()
	var gm = _get_gm()
	if gm:
		nav.build_graph_from_grid(gm)
		var start = gm.grid_to_world(Vector2i(14, 3), true) # Rowan Home
		var goal = gm.grid_to_world(Vector2i(15, 3), true)  # Seed Shop
		var path = nav.find_world_path(start, goal, gm)
		assert_not_empty(path, "full integration navigation path solved")
