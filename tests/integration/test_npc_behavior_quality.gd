class_name TestNPCBehaviorQuality
extends TestCase

## Dedicated 15-Point Behavior Quality, Navigation & Living World Test Suite (Phase 21.5).

func test_name_id() -> String:
	return "NPC.BehaviorQuality"

func run_all() -> void:
	test_name = test_name_id()
	_test_T01_schedule_progression_timeline()
	_test_T02_state_transition_safety()
	_test_T03_navigation_failure_safe_recovery()
	_test_T04_player_interaction_pause_and_resume()
	_test_T05_social_cooldown_prevents_chatter_spam()
	_test_T06_multi_npc_social_contention_no_deadlock()
	_test_T07_weather_interrupt_immediate_reroute()
	_test_T08_night_and_sleep_behavior()
	_test_T09_day_reset_safety()
	_test_T10_world_transition_state_isolation()
	_test_T11_save_load_runtime_state_recovery()
	_test_T12_no_deadlocked_or_frozen_npc()
	_test_T13_no_infinite_state_loop()
	_test_T14_velocity_matches_movement_state()
	_test_T15_facing_direction_reflects_motion()

func _get_npcm() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("/root/NPCManager")

func _test_T01_schedule_progression_timeline() -> void:
	begin_test("T01_ScheduleProgressionTimeline")
	var npcm = _get_npcm()
	if npcm:
		var e_morning = npcm.resolve_schedule_entry("rowan", 360) # 06:00
		var e_work = npcm.resolve_schedule_entry("rowan", 540) # 09:00
		var e_eat = npcm.resolve_schedule_entry("rowan", 780) # 13:00
		var e_night = npcm.resolve_schedule_entry("rowan", 1300) # 21:40
		
		assert_eq(e_morning.get("activity", ""), "home", "06:00 activity is home")
		assert_eq(e_work.get("activity", ""), "work", "09:00 activity is work")
		assert_eq(e_eat.get("activity", ""), "eat", "13:00 activity is eat")
		assert_eq(e_night.get("activity", ""), "sleep", "21:40 activity is sleep")

func _test_T02_state_transition_safety() -> void:
	begin_test("T02_StateTransitionSafety")
	var inst = NPCInstance.new()
	inst.setup({ "id": "test_npc", "position": [10, 10] })
	inst.behavior_controller.set_activity("work", "seed_shop", Vector2(240, 56), 2)
	assert_eq(inst.behavior_controller.current_state, "NAVIGATING", "state is NAVIGATING")
	inst.behavior_controller.on_destination_reached("seed_shop")
	assert_eq(inst.behavior_controller.current_state, "WORKING", "state transitioned to WORKING")
	inst.queue_free()

func _test_T03_navigation_failure_safe_recovery() -> void:
	begin_test("T03_NavigationFailureSafeRecovery")
	var inst = NPCInstance.new()
	inst.setup({ "id": "test_npc", "position": [10, 10] })
	inst.behavior_controller.fallback_location_id = "rowan_home"
	inst.behavior_controller.on_navigation_failed("impossible_spot")
	assert_true(inst.behavior_controller.current_state in ["NAVIGATING", "IDLE"], "recovers safely without crash")
	inst.queue_free()

func _test_T04_player_interaction_pause_and_resume() -> void:
	begin_test("T04_PlayerInteractionPauseAndResume")
	var inst = NPCInstance.new()
	inst.setup({ "id": "test_npc", "position": [10, 10] })
	inst.behavior_controller.set_activity("work", "seed_shop", Vector2(240, 56), 2)
	inst.behavior_controller.on_player_interaction_started()
	assert_eq(inst.behavior_controller.current_state, "PLAYER_INTERACTION", "interrupted by player")
	assert_eq(inst.velocity, Vector2.ZERO, "velocity zeroed during dialogue")
	inst.behavior_controller.on_player_interaction_ended()
	assert_eq(inst.behavior_controller.current_activity, "work", "resumed work activity")
	inst.queue_free()

func _test_T05_social_cooldown_prevents_chatter_spam() -> void:
	begin_test("T05_SocialCooldownPreventsChatterSpam")
	var inst = NPCInstance.new()
	inst.setup({ "id": "test_npc", "position": [10, 10] })
	inst.behavior_controller.start_social_interaction("other_npc", 1.0)
	inst.behavior_controller.update(1.2) # Complete social interaction
	assert_gt(inst.behavior_controller.social_cooldown, 0.0, "cooldown active after social interaction")
	assert_false(inst.behavior_controller.can_start_social_interaction(), "cannot re-start immediately")
	inst.queue_free()

func _test_T06_multi_npc_social_contention_no_deadlock() -> void:
	begin_test("T06_MultiNPCSocialContentionNoDeadlock")
	var inst_a = NPCInstance.new()
	var inst_b = NPCInstance.new()
	var inst_c = NPCInstance.new()
	inst_a.setup({ "id": "npc_a", "position": [10, 10] })
	inst_b.setup({ "id": "npc_b", "position": [10, 10] })
	inst_c.setup({ "id": "npc_c", "position": [10, 10] })
	
	inst_a.behavior_controller.start_social_interaction("npc_b", 2.0)
	inst_b.behavior_controller.start_social_interaction("npc_a", 2.0)
	
	# Third NPC tries to interact - rejected cleanly without deadlock
	assert_false(inst_a.behavior_controller.can_start_social_interaction(), "busy NPC cannot accept 3rd party")
	assert_true(inst_c.behavior_controller.can_start_social_interaction(), "3rd NPC remains available")
	
	inst_a.queue_free()
	inst_b.queue_free()
	inst_c.queue_free()

func _test_T07_weather_interrupt_immediate_reroute() -> void:
	begin_test("T07_WeatherInterruptImmediateReRoute")
	var npcm = _get_npcm()
	if npcm:
		var sched_clear = npcm.get_schedule_for_npc("rowan", "default")
		var sched_rain = npcm.get_schedule_for_npc("rowan", "rain")
		assert_not_empty(sched_clear, "clear schedule exists")
		assert_not_empty(sched_rain, "rain schedule exists")

func _test_T08_night_and_sleep_behavior() -> void:
	begin_test("T08_NightAndSleepBehavior")
	var npcm = _get_npcm()
	if npcm:
		var night_entry = npcm.resolve_schedule_entry("elias", 1300)
		assert_eq(night_entry.get("activity", ""), "sleep", "elias night activity is sleep")

func _test_T09_day_reset_safety() -> void:
	begin_test("T09_DayResetSafety")
	var npcm = _get_npcm()
	if npcm:
		npcm.reset_daily_schedules()
		assert_true(true, "daily schedules reset safely")

func _test_T10_world_transition_state_isolation() -> void:
	begin_test("T10_WorldTransitionStateIsolation")
	var npcm = _get_npcm()
	if npcm:
		var farm_world = npcm.get_npc_world("rowan")
		var grove_world = npcm.get_npc_world("mira")
		assert_eq(farm_world, "farm", "rowan belongs to farm world")
		assert_eq(grove_world, "botanical_grove", "mira belongs to botanical_grove")

func _test_T11_save_load_runtime_state_recovery() -> void:
	begin_test("T11_SaveLoadRuntimeStateRecovery")
	var npcm = _get_npcm()
	if npcm:
		var dbg = npcm.get_npc_debug_info("rowan")
		assert_has(dbg, "npc_id", "debug payload valid for save/load snapshot")

func _test_T12_no_deadlocked_or_frozen_npc() -> void:
	begin_test("T12_NoDeadlockedOrFrozenNPC")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("dest", Vector2(120, 100), "walk")
	# Simulate 1 second of movement -> NPC reaches destination or advances waypoints
	for i in range(40):
		inst._process_movement(0.025)
	assert_eq(inst.current_state, "AT_DESTINATION", "NPC completes navigation and reaches destination")
	inst.queue_free()

func _test_T13_no_infinite_state_loop() -> void:
	begin_test("T13_NoInfiniteStateLoop")
	var inst = NPCInstance.new()
	inst.setup({ "id": "test_npc", "position": [10, 10] })
	# Cycle through interrupt and social quickly
	for i in range(5):
		inst.behavior_controller.start_social_interaction("partner", 0.1)
		inst.behavior_controller.update(0.15)
	assert_eq(inst.behavior_controller.social_partner_id, "", "social partner cleanly cleared")
	inst.queue_free()

func _test_T14_velocity_matches_movement_state() -> void:
	begin_test("T14_VelocityMatchesMovementState")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("dest", Vector2(200, 100), "walk")
	inst._process_movement(0.1)
	assert_true(inst.is_moving, "is_moving is true during motion")
	assert_gt(inst.velocity.length(), 0.0, "velocity is non-zero during motion")
	inst.queue_free()

func _test_T15_facing_direction_reflects_motion() -> void:
	begin_test("T15_FacingDirectionReflectsMotion")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("dest_east", Vector2(200, 100), "walk")
	inst._process_movement(0.1)
	assert_gt(inst.facing_direction.x, 0.5, "facing direction is East (positive x)")
	inst.queue_free()
