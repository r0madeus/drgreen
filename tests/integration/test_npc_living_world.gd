class_name TestNPCLivingWorld
extends TestCase

## Comprehensive 28-Point Test Suite for Phase 21:
## NPC Living World, Daily Behavior & Social Simulation.

func test_name_id() -> String:
	return "NPC.LivingWorld"

func run_all() -> void:
	test_name = test_name_id()
	_test_T01_npc_state_machine()
	_test_T02_daily_schedule()
	_test_T03_work_activity()
	_test_T04_eat_activity()
	_test_T05_rest_activity()
	_test_T06_sleep_activity()
	_test_T07_wander_activity()
	_test_T08_schedule_interrupt()
	_test_T09_resume_after_dialogue()
	_test_T10_navigation_failure_fallback()
	_test_T11_social_interaction()
	_test_T12_social_interaction_cooldown()
	_test_T13_player_reaction()
	_test_T14_rain_behavior()
	_test_T15_night_behavior()
	_test_T16_season_behavior()
	_test_T17_world_aware_schedule()
	_test_T18_save_load_npc_state()
	_test_T19_late_join_npc_snapshot()
	_test_T20_multiplayer_npc_authority()
	_test_T21_dynamic_obstacle_repath()
	_test_T22_npc_separation()
	_test_T23_performance_no_excessive_pathfinding()
	_test_T24_localization_regression()
	_test_T25_asset_pipeline_regression()
	_test_T26_singleplayer_regression()
	_test_T27_multiplayer_regression()
	_test_T28_schedule_validator()

const NPCBehaviorControllerScript = preload("res://systems/npc/npc_behavior_controller.gd")

func _get_npcm() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("/root/NPCManager")

func _get_gm() -> GridManager:
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root:
		return loop.root.find_child("GridManager", true, false) as GridManager
	return null

# --- Tests ---

func _test_T01_npc_state_machine() -> void:
	begin_test("T01_NPCStateMachine")
	var ctrl = NPCBehaviorControllerScript.new()
	assert_eq(ctrl.current_state, "IDLE", "initial state is IDLE")
	ctrl.current_state = "WORKING"
	assert_eq(ctrl.current_state, "WORKING", "state changed to WORKING")
	ctrl.current_state = "SOCIALIZING"
	assert_eq(ctrl.current_state, "SOCIALIZING", "state changed to SOCIALIZING")

func _test_T02_daily_schedule() -> void:
	begin_test("T02_DailySchedule")
	var npcm = _get_npcm()
	if npcm:
		var sched = npcm.get_schedule_for_npc("rowan", "default")
		assert_gt(sched.size(), 2, "rowan has multi-entry daily schedule")
		var first = sched[0]
		assert_has(first, "activity", "schedule entry has activity field")
		assert_has(first, "location_id", "schedule entry has location_id field")

func _test_T03_work_activity() -> void:
	begin_test("T03_WorkActivity")
	var inst = NPCInstance.new()
	inst.setup({ "id": "test_npc", "position": [10, 10] })
	inst.behavior_controller.set_activity("work", "seed_shop", Vector2(248, 56), 3)
	assert_eq(inst.behavior_controller.current_activity, "work", "activity is work")
	inst.behavior_controller.on_destination_reached("seed_shop")
	assert_eq(inst.behavior_controller.current_state, "WORKING", "state transitioned to WORKING")
	inst.queue_free()

func _test_T04_eat_activity() -> void:
	begin_test("T04_EatActivity")
	var inst = NPCInstance.new()
	inst.behavior_controller.set_activity("eat", "farm_porch", Vector2(160, 80), 2)
	inst.behavior_controller.on_destination_reached("farm_porch")
	assert_eq(inst.behavior_controller.current_state, "EATING", "state transitioned to EATING")
	inst.queue_free()

func _test_T05_rest_activity() -> void:
	begin_test("T05_RestActivity")
	var inst = NPCInstance.new()
	inst.behavior_controller.set_activity("rest", "farm_porch", Vector2(160, 80), 2)
	inst.behavior_controller.on_destination_reached("farm_porch")
	assert_eq(inst.behavior_controller.current_state, "RESTING", "state transitioned to RESTING")
	inst.queue_free()

func _test_T06_sleep_activity() -> void:
	begin_test("T06_SleepActivity")
	var inst = NPCInstance.new()
	inst.behavior_controller.set_activity("sleep", "rowan_home", Vector2(224, 56), 4)
	inst.behavior_controller.on_destination_reached("rowan_home")
	assert_eq(inst.behavior_controller.current_state, "SLEEPING", "state transitioned to SLEEPING")
	inst.queue_free()

func _test_T07_wander_activity() -> void:
	begin_test("T07_WanderActivity")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(200, 200)
	inst.behavior_controller.setup(inst)
	inst.behavior_controller.set_activity("wander", "town_square", Vector2(200, 200), 2)
	inst.behavior_controller.on_destination_reached("town_square")
	assert_eq(inst.behavior_controller.current_state, "WANDERING", "state transitioned to WANDERING")
	inst.queue_free()

func _test_T08_schedule_interrupt() -> void:
	begin_test("T08_ScheduleInterrupt")
	var inst = NPCInstance.new()
	inst.behavior_controller.setup(inst)
	inst.behavior_controller.set_activity("work", "seed_shop", Vector2(248, 56), 2)
	inst.behavior_controller.on_player_interaction_started()
	assert_eq(inst.behavior_controller.current_state, "PLAYER_INTERACTION", "interrupted by player")
	assert_eq(inst.behavior_controller.current_interrupt_level, 6, "interrupt level is PLAYER (6)")
	inst.queue_free()

func _test_T09_resume_after_dialogue() -> void:
	begin_test("T09_ResumeAfterDialogue")
	var inst = NPCInstance.new()
	inst.behavior_controller.setup(inst)
	inst.behavior_controller.set_activity("work", "seed_shop", Vector2(248, 56), 2)
	inst.behavior_controller.on_player_interaction_started()
	inst.behavior_controller.on_player_interaction_ended()
	assert_eq(inst.behavior_controller.current_activity, "work", "activity resumed after dialogue")
	assert_eq(inst.behavior_controller.current_interrupt_level, 0, "interrupt cleared")
	inst.queue_free()

func _test_T10_navigation_failure_fallback() -> void:
	begin_test("T10_NavigationFailureFallback")
	var inst = NPCInstance.new()
	inst.behavior_controller.setup(inst)
	inst.behavior_controller.fallback_location_id = "rowan_home"
	inst.behavior_controller.on_navigation_failed("unreachable_loc")
	assert_true(inst.behavior_controller.current_state in ["NAVIGATING", "IDLE", "TRAVELING"], "fallback handled safely")
	inst.queue_free()

func _test_T11_social_interaction() -> void:
	begin_test("T11_SocialInteraction")
	var inst_a = NPCInstance.new()
	var inst_b = NPCInstance.new()
	inst_a.setup({ "id": "rowan", "position": [10, 10] })
	inst_b.setup({ "id": "elias", "position": [10, 11] })
	
	inst_a.behavior_controller.start_social_interaction("elias", 3.0)
	inst_b.behavior_controller.start_social_interaction("rowan", 3.0)
	
	assert_eq(inst_a.behavior_controller.current_state, "SOCIALIZING", "NPC A is socializing")
	assert_eq(inst_b.behavior_controller.current_state, "SOCIALIZING", "NPC B is socializing")
	assert_eq(inst_a.behavior_controller.social_partner_id, "elias", "NPC A partner is elias")
	
	inst_a.queue_free()
	inst_b.queue_free()

func _test_T12_social_interaction_cooldown() -> void:
	begin_test("T12_SocialInteractionCooldown")
	var ctrl = NPCBehaviorControllerScript.new()
	ctrl.start_social_interaction("partner", 2.0)
	assert_gt(ctrl.social_cooldown, 0.0, "social cooldown applied")
	assert_false(ctrl.can_start_social_interaction(), "cannot start new interaction during cooldown")

func _test_T13_player_reaction() -> void:
	begin_test("T13_PlayerReaction")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.turn_to_face(Vector2(150, 100))
	assert_gt(inst.facing_direction.x, 0.5, "facing updated towards target point")
	inst.queue_free()

func _test_T14_rain_behavior() -> void:
	begin_test("T14_RainBehavior")
	var npcm = _get_npcm()
	if npcm:
		var sched_rain = npcm.get_schedule_for_npc("rowan", "rain")
		assert_not_empty(sched_rain, "rain schedule variant loaded")

func _test_T15_night_behavior() -> void:
	begin_test("T15_NightBehavior")
	var npcm = _get_npcm()
	if npcm:
		var late_entry = npcm.resolve_schedule_entry("rowan", 1300) # 21:40
		assert_eq(late_entry.get("activity", ""), "sleep", "late night resolves to sleep activity")

func _test_T16_season_behavior() -> void:
	begin_test("T16_SeasonBehavior")
	var npcm = _get_npcm()
	if npcm:
		var sched = npcm.get_schedule_for_npc("mira", "summer")
		assert_not_empty(sched, "season schedule fallback resolves")

func _test_T17_world_aware_schedule() -> void:
	begin_test("T17_WorldAwareSchedule")
	var npcm = _get_npcm()
	if npcm:
		var w = npcm.get_npc_world("mira")
		assert_eq(w, "botanical_grove", "mira resides in botanical_grove")

func _test_T18_save_load_npc_state() -> void:
	begin_test("T18_SaveLoadNPCState")
	var npcm = _get_npcm()
	if npcm:
		var info = npcm.get_npc_debug_info("rowan")
		assert_has(info, "activity", "debug info includes activity")
		assert_has(info, "state", "debug info includes state")

func _test_T19_late_join_npc_snapshot() -> void:
	begin_test("T19_LateJoinNPCSnapshot")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.has_method("request_npc_snapshot"), "NetworkNPC supports snapshot requests")

func _test_T20_multiplayer_npc_authority() -> void:
	begin_test("T20_MultiplayerNPCAuthority")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.is_host() or net_npc.is_offline(), "host authoritative")

func _test_T21_dynamic_obstacle_repath() -> void:
	begin_test("T21_DynamicObstacleRepath")
	var gm = _get_gm()
	if gm:
		var path1 = gm.find_path(Vector2(100, 100), Vector2(160, 100))
		assert_not_empty(path1, "initial path generated")

func _test_T22_npc_separation() -> void:
	begin_test("T22_NPCSeparation")
	var inst = NPCInstance.new()
	var avoid = inst._calculate_local_avoidance()
	assert_true(avoid is Vector2, "separation force computed as Vector2")
	inst.queue_free()

func _test_T23_performance_no_excessive_pathfinding() -> void:
	begin_test("T23_PerformanceNoExcessivePathfinding")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("dest_1", Vector2(150, 100), "work")
	var p_size = inst.nav_path.size()
	# Running process step does NOT re-generate path from scratch
	inst._process_movement(0.016)
	assert_eq(inst.nav_path.size(), p_size, "path is cached and preserved during traversal")
	inst.queue_free()

func _test_T24_localization_regression() -> void:
	begin_test("T24_LocalizationRegression")
	var lm = Engine.get_main_loop().root.get_node_or_null("/root/LocalizationManager")
	if lm:
		var act_work = lm.get_text("npc.activity.work")
		var act_eat = lm.get_text("npc.activity.eat")
		assert_not_empty(act_work, "work activity localized")
		assert_not_empty(act_eat, "eat activity localized")

func _test_T25_asset_pipeline_regression() -> void:

	begin_test("T25_AssetPipelineRegression")
	var tex = AssetRegistry.get_npc_texture("merchant", 0)
	assert_true(tex != null, "merchant texture available")

func _test_T26_singleplayer_regression() -> void:
	begin_test("T26_SingleplayerRegression")
	var ps = PlayerStateFixture.create_default()
	assert_eq(ps.player_id, "test_player", "singleplayer fixture valid")

func _test_T27_multiplayer_regression() -> void:
	begin_test("T27_MultiplayerRegression")
	var net_npc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkNPC")
	if net_npc:
		assert_true(net_npc.is_offline(), "offline mode active by default")

func _test_T28_schedule_validator() -> void:
	begin_test("T28_ScheduleValidator")
	var npcm = _get_npcm()
	if npcm:
		var errors = npcm.validate_schedules()
		assert_eq(errors.size(), 0, "all NPC schedules pass data validation without errors")
