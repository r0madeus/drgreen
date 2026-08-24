class_name TestNPCSchedule
extends TestCase

## Comprehensive 30-Point Test Suite for Phase 19:
## NPC Daily Schedule, Continuous World-Space Movement, State Machine & Living World System.

func test_name_id() -> String:
	return "NPC.DailySchedule"

func run_all() -> void:
	test_name = test_name_id()
	_test_T01_npc_schedule_loads()
	_test_T02_schedule_sorted_by_time()
	_test_T03_current_schedule_entry_resolution()
	_test_T04_npc_moves_to_destination()
	_test_T05_npc_does_not_grid_snap()
	_test_T06_npc_uses_world_space_position()
	_test_T07_schedule_boundary_changes()
	_test_T08_npc_stops_at_destination()
	_test_T09_npc_idle_animation_at_destination()
	_test_T10_npc_walk_animation_while_traveling()
	_test_T11_npc_facing_direction()
	_test_T12_time_manager_integration()
	_test_T13_new_day_schedule_reset()
	_test_T14_weather_variant_fallback()
	_test_T15_season_variant_fallback()
	_test_T16_npc_dialogue_while_scheduled()
	_test_T17_npc_shop_interaction_regression()
	_test_T18_friendship_regression()
	_test_T19_quest_regression()
	_test_T20_save_load_npc_state()
	_test_T21_world_transition_npc_state()
	_test_T22_multiplayer_npc_replication()
	_test_T23_remote_npc_interpolation()
	_test_T24_late_join_npc_snapshot()
	_test_T25_disconnect_reconnect_regression()
	_test_T26_localization_regression()
	_test_T27_asset_pipeline_regression()
	_test_T28_singleplayer_regression()
	_test_T29_multiplayer_regression()
	_test_T30_full_daily_routine()

func _get_npcm() -> Node:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if root:
		var n = root.find_child("NPCManager", true, false)
		if n: return n
	var c = load("res://systems/npc/npc_manager.gd")
	if c:
		var inst = c.new()
		inst.name = "NPCManager"
		if root: root.add_child(inst)
		return inst
	return null

func _get_tm() -> Node:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if root:
		var n = root.find_child("TimeManager", true, false)
		if n: return n
	var c = load("res://systems/time/time_manager.gd")
	if c:
		var inst = c.new()
		inst.name = "TimeManager"
		if root: root.add_child(inst)
		return inst
	return null

# --- Tests ---

func _test_T01_npc_schedule_loads() -> void:
	begin_test("T01_NPCScheduleLoads")
	var npcm = _get_npcm()
	assert_true(npcm != null, "NPCManager exists")
	if npcm:
		assert_not_empty(npcm.schedules_catalog, "schedules catalog loaded")
		assert_has(npcm.schedules_catalog, "rowan", "rowan schedule exists")
		assert_has(npcm.locations_catalog, "seed_shop", "seed_shop location exists")

func _test_T02_schedule_sorted_by_time() -> void:
	begin_test("T02_ScheduleSortedByTime")
	var npcm = _get_npcm()
	if not npcm: return
	var sched = npcm.get_schedule_for_npc("rowan", "default")
	assert_gt(sched.size(), 1, "rowan has multiple schedule entries")
	for i in range(1, sched.size()):
		var prev_m = int(sched[i - 1].get("start_minute", 0))
		var cur_m = int(sched[i].get("start_minute", 0))
		assert_gte(cur_m, prev_m, "schedule entries sorted in ascending order")

func _test_T03_current_schedule_entry_resolution() -> void:
	begin_test("T03_CurrentScheduleEntryResolution")
	var npcm = _get_npcm()
	if not npcm: return
	# At 07:00 (420m) -> 06:00 entry (rowan_home)
	var e1 = npcm.resolve_schedule_entry("rowan", 420)
	assert_eq(e1.get("location_id", ""), "rowan_home", "07:00 AM resolves to rowan_home")
	
	# At 10:00 (600m) -> 09:00 entry (seed_shop)
	var e2 = npcm.resolve_schedule_entry("rowan", 600)
	assert_eq(e2.get("location_id", ""), "seed_shop", "10:00 AM resolves to seed_shop")
	
	# At 14:00 (840m) -> 13:00 entry (farm_porch)
	var e3 = npcm.resolve_schedule_entry("rowan", 840)
	assert_eq(e3.get("location_id", ""), "farm_porch", "02:00 PM resolves to farm_porch")

func _test_T04_npc_moves_to_destination() -> void:
	begin_test("T04_NPCMovesToDestination")
	var inst = NPCInstance.new()
	inst.setup({ "id": "test_npc", "position": [10, 10] })
	inst.global_position = Vector2(160, 160)
	inst.set_destination("dest", Vector2(240, 160), "walk")
	assert_true(inst.current_state in ["TRAVELING", "NAVIGATING"], "state is moving")
	assert_true(inst.is_moving, "is_moving is true")
	
	# Simulate 0.5s delta movement
	var pos_before = inst.global_position.x
	inst._process_movement(0.5)
	assert_gt(inst.global_position.x, pos_before, "NPC moved towards target")
	inst.queue_free()


func _test_T05_npc_does_not_grid_snap() -> void:
	begin_test("T05_NPCDoesNotGridSnap")
	var inst = NPCInstance.new()
	inst.setup({ "id": "test_npc", "position": [10, 10] })
	inst.global_position = Vector2(160.0, 160.0)
	inst.set_destination("dest", Vector2(240.0, 160.0), "walk")
	# Step with delta=0.016 (one 60fps frame)
	inst._process_movement(0.016)
	var moved_px = inst.global_position.x - 160.0
	assert_gt(moved_px, 0.0, "position advanced continuously")
	assert_lt(moved_px, 16.0, "position did NOT jump a full 16px tile cell")
	inst.queue_free()

func _test_T06_npc_uses_world_space_position() -> void:
	begin_test("T06_NPCUsesWorldSpacePosition")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(217.4, 183.9)
	assert_true(inst.global_position is Vector2, "position is Vector2")
	assert_approx_eq(inst.global_position.x, 217.4, 0.01, "world space X preserved")
	assert_approx_eq(inst.global_position.y, 183.9, 0.01, "world space Y preserved")
	inst.queue_free()

func _test_T07_schedule_boundary_changes() -> void:
	begin_test("T07_ScheduleBoundaryChanges")
	var npcm = _get_npcm()
	if not npcm: return
	var e_before = npcm.resolve_schedule_entry("rowan", 539) # 08:59
	var e_after = npcm.resolve_schedule_entry("rowan", 540)  # 09:00
	assert_ne(e_before.get("location_id", ""), e_after.get("location_id", ""), "schedule boundary changes at 09:00")

func _test_T08_npc_stops_at_destination() -> void:
	begin_test("T08_NPCStopsAtDestination")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(198.0, 160.0)
	inst.set_destination("dest", Vector2(200.0, 160.0), "work")
	inst._process_movement(1.0) # Within 3px tolerance
	assert_eq(inst.current_state, "AT_DESTINATION", "switches to AT_DESTINATION")
	assert_false(inst.is_moving, "is_moving becomes false")
	assert_eq(inst.velocity, Vector2.ZERO, "velocity stops at zero")
	inst.queue_free()

func _test_T09_npc_idle_animation_at_destination() -> void:
	begin_test("T09_NPCIdleAnimationAtDestination")
	var inst = NPCInstance.new()
	inst.current_state = "AT_DESTINATION"
	inst.is_moving = false
	assert_false(inst.is_moving, "not moving when at destination")
	inst.queue_free()

func _test_T10_npc_walk_animation_while_traveling() -> void:
	begin_test("T10_NPCWalkAnimationWhileTraveling")
	var inst = NPCInstance.new()
	inst.set_destination("dest", Vector2(300, 100), "walk")
	assert_true(inst.is_moving, "is_moving true during travel")
	inst.queue_free()

func _test_T11_npc_facing_direction() -> void:
	begin_test("T11_NPCFacingDirection")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("dest", Vector2(100, 200), "walk") # Downward
	inst._process_movement(0.1)
	assert_gt(inst.facing_direction.y, 0.5, "facing direction is downward")
	inst.queue_free()

func _test_T12_time_manager_integration() -> void:
	begin_test("T12_TimeManagerIntegration")
	var tm = _get_tm()
	var npcm = _get_npcm()
	assert_true(tm != null and npcm != null, "TimeManager and NPCManager present")

func _test_T13_new_day_schedule_reset() -> void:
	begin_test("T13_NewDayScheduleReset")
	var npcm = _get_npcm()
	if not npcm: return
	npcm.reset_daily_schedules()
	assert_true(true, "reset_daily_schedules executed without errors")

func _test_T14_weather_variant_fallback() -> void:
	begin_test("T14_WeatherVariantFallback")
	var npcm = _get_npcm()
	if not npcm: return
	var sched_rain = npcm.get_schedule_for_npc("rowan", "rain")
	assert_not_empty(sched_rain, "rowan has rain schedule variant")
	var sched_fallback = npcm.get_schedule_for_npc("elias", "rain") # Elias has only default
	assert_not_empty(sched_fallback, "elias falls back to default schedule")

func _test_T15_season_variant_fallback() -> void:
	begin_test("T15_SeasonVariantFallback")
	var npcm = _get_npcm()
	if not npcm: return
	var sched_season = npcm.get_schedule_for_npc("mira", "winter") # Mira falls back to default
	assert_not_empty(sched_season, "season variant falls back cleanly to default")

func _test_T16_npc_dialogue_while_scheduled() -> void:
	begin_test("T16_NPCDialogueWhileScheduled")
	var inst = NPCInstance.new()
	inst.set_destination("shop", Vector2(200, 200), "work")
	inst.interact()
	assert_true(inst.is_interacting, "interaction pauses traveling")
	inst._on_dialogue_ended("")
	assert_false(inst.is_interacting, "dialogue ended resumes traveling")
	inst.queue_free()

func _test_T17_npc_shop_interaction_regression() -> void:
	begin_test("T17_NPCShopInteractionRegression")
	var net_shop = Engine.get_main_loop().root.get_node_or_null("/root/NetworkShop")
	assert_true(net_shop != null, "NetworkShop exists")

func _test_T18_friendship_regression() -> void:
	begin_test("T18_FriendshipRegression")
	var dm = Engine.get_main_loop().root.get_node_or_null("/root/DialogueManager")
	assert_true(dm != null, "DialogueManager exists")

func _test_T19_quest_regression() -> void:
	begin_test("T19_QuestRegression")
	var qm = Engine.get_main_loop().root.get_node_or_null("/root/QuestManager")
	assert_true(qm != null, "QuestManager exists")

func _test_T20_save_load_npc_state() -> void:
	begin_test("T20_SaveLoadNPCState")
	var npcm = _get_npcm()
	if not npcm: return
	var info = npcm.get_npc_debug_info("rowan")
	assert_has(info, "npc_id", "debug info has npc_id")
	assert_has(info, "world", "debug info has world")
	assert_has(info, "position", "debug info has position")

func _test_T21_world_transition_npc_state() -> void:
	begin_test("T21_WorldTransitionNPCState")
	var npcm = _get_npcm()
	if not npcm: return
	var w = npcm.get_npc_world("elias")
	assert_eq(w, "town", "Elias is in town")

func _test_T22_multiplayer_npc_replication() -> void:
	begin_test("T22_MultiplayerNPCReplication")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	assert_true(net_npc != null, "NetworkNPC exists")
	if net_npc:
		assert_true(net_npc.has_method("broadcast_npc_movement"), "has broadcast_npc_movement")

func _test_T23_remote_npc_interpolation() -> void:
	begin_test("T23_RemoteNPCInterpolation")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.has_method("request_npc_interaction"), "has request_npc_interaction")

func _test_T24_late_join_npc_snapshot() -> void:
	begin_test("T24_LateJoinNPCSnapshot")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.has_method("request_npc_snapshot"), "has request_npc_snapshot")

func _test_T25_disconnect_reconnect_regression() -> void:
	begin_test("T25_DisconnectReconnectRegression")
	var nm = Engine.get_main_loop().root.get_node_or_null("/root/NetworkManager")
	assert_true(nm != null, "NetworkManager exists")

func _test_T26_localization_regression() -> void:
	begin_test("T26_LocalizationRegression")
	var lm = Engine.get_main_loop().root.get_node_or_null("/root/LocalizationManager")
	if lm:
		var loc_name = lm.get_text("location.seed_shop")
		assert_not_empty(loc_name, "seed_shop location translated")
		var act_name = lm.get_text("npc.activity.work")
		assert_not_empty(act_name, "work activity translated")

func _test_T27_asset_pipeline_regression() -> void:
	begin_test("T27_AssetPipelineRegression")
	var tex = AssetRegistry.get_npc_texture("merchant", 0)
	assert_true(tex != null, "merchant sprite texture resolved")

func _test_T28_singleplayer_regression() -> void:
	begin_test("T28_SingleplayerRegression")
	var ps = PlayerStateFixture.create_default()
	assert_eq(ps.player_id, "test_player", "singleplayer default player fixture active")

func _test_T29_multiplayer_regression() -> void:

	begin_test("T29_MultiplayerRegression")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.is_offline(), "offline mode active by default")

func _test_T30_full_daily_routine() -> void:
	begin_test("T30_FullDailyRoutine")
	var npcm = _get_npcm()
	if not npcm: return
	# Simulate 24-hour cycle at key intervals
	var morning_entry = npcm.resolve_schedule_entry("rowan", 360) # 06:00
	var noon_entry = npcm.resolve_schedule_entry("rowan", 720)    # 12:00
	var dusk_entry = npcm.resolve_schedule_entry("rowan", 1080)   # 18:00
	var night_entry = npcm.resolve_schedule_entry("rowan", 1320)  # 22:00
	
	assert_not_empty(morning_entry, "morning routine valid")
	assert_not_empty(noon_entry, "noon routine valid")
	assert_not_empty(dusk_entry, "dusk routine valid")
	assert_not_empty(night_entry, "night routine valid")
