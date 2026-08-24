class_name TestNPCVisualAnimation
extends TestCase

## Dedicated 14-Point NPC Visual & Animation Test Suite (Phase 21.6).

func test_name_id() -> String:
	return "NPC.VisualAnimation"

func run_all() -> void:
	test_name = test_name_id()
	_test_T01_animation_state_mapping()
	_test_T02_walk_animation_triggered()
	_test_T03_idle_transition_on_arrival()
	_test_T04_facing_direction_4_way()
	_test_T05_facing_direction_dominant_axis()
	_test_T06_facing_direction_preserved_on_stop()
	_test_T07_activity_specific_animation()
	_test_T08_player_dialogue_animation()
	_test_T09_npc_social_animation()
	_test_T10_missing_animation_fallback()
	_test_T11_animation_restart_prevention()
	_test_T12_world_transition_animation_reset()
	_test_T13_day_reset_animation()
	_test_T14_multiplayer_animation_consistency()

func _test_T01_animation_state_mapping() -> void:
	begin_test("T01_AnimationStateMapping")
	var inst = NPCInstance.new()
	inst.setup({ "id": "rowan", "position": [10, 10] })
	inst.behavior_controller.current_state = "IDLE"
	assert_eq(inst.get_current_animation_name(), "idle", "IDLE maps to idle")
	inst.behavior_controller.current_state = "NAVIGATING"
	assert_eq(inst.get_current_animation_name(), "walk", "NAVIGATING maps to walk")
	inst.behavior_controller.current_state = "WORKING"
	assert_eq(inst.get_current_animation_name(), "work", "WORKING maps to work")
	inst.behavior_controller.current_state = "EATING"
	assert_eq(inst.get_current_animation_name(), "eat", "EATING maps to eat")
	inst.behavior_controller.current_state = "RESTING"
	assert_eq(inst.get_current_animation_name(), "rest", "RESTING maps to rest")
	inst.behavior_controller.current_state = "SLEEPING"
	assert_eq(inst.get_current_animation_name(), "sleep", "SLEEPING maps to sleep")
	inst.behavior_controller.current_state = "PLAYER_INTERACTION"
	assert_eq(inst.get_current_animation_name(), "talk", "PLAYER_INTERACTION maps to talk")
	inst.queue_free()


func _test_T02_walk_animation_triggered() -> void:
	begin_test("T02_WalkAnimationTriggered")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.set_destination("dest", Vector2(200, 100), "walk")
	assert_eq(inst.get_current_animation_name(), "walk", "walk animation active when destination set")
	inst.queue_free()

func _test_T03_idle_transition_on_arrival() -> void:
	begin_test("T03_IdleTransitionOnArrival")
	var inst = NPCInstance.new()
	inst.global_position = Vector2(100, 100)
	inst.teleport_to_location("home", Vector2(100, 100), "home")
	assert_eq(inst.get_current_animation_name(), "idle", "arrival transitions to idle/activity animation")
	assert_eq(inst.velocity, Vector2.ZERO, "velocity zeroed on arrival")
	inst.queue_free()

func _test_T04_facing_direction_4_way() -> void:
	begin_test("T04_FacingDirection4Way")
	var inst = NPCInstance.new()
	inst.facing_direction = Vector2.DOWN
	assert_eq(inst.get_facing_direction_string(), "down", "DOWN resolves to down")
	inst.facing_direction = Vector2.UP
	assert_eq(inst.get_facing_direction_string(), "up", "UP resolves to up")
	inst.facing_direction = Vector2.LEFT
	assert_eq(inst.get_facing_direction_string(), "left", "LEFT resolves to left")
	inst.facing_direction = Vector2.RIGHT
	assert_eq(inst.get_facing_direction_string(), "right", "RIGHT resolves to right")
	inst.queue_free()

func _test_T05_facing_direction_dominant_axis() -> void:
	begin_test("T05_FacingDirectionDominantAxis")
	var inst = NPCInstance.new()
	# Stronger horizontal than vertical
	inst.facing_direction = Vector2(0.8, 0.2).normalized()
	assert_eq(inst.get_facing_direction_string(), "right", "dominant X-axis resolves to right")
	# Stronger vertical than horizontal
	inst.facing_direction = Vector2(-0.2, -0.8).normalized()
	assert_eq(inst.get_facing_direction_string(), "up", "dominant negative Y-axis resolves to up")
	inst.queue_free()

func _test_T06_facing_direction_preserved_on_stop() -> void:
	begin_test("T06_FacingDirectionPreservedOnStop")
	var inst = NPCInstance.new()
	inst.facing_direction = Vector2.RIGHT
	inst._arrive_at_destination()
	assert_eq(inst.get_facing_direction_string(), "right", "facing direction preserved after arrival")
	inst.queue_free()

func _test_T07_activity_specific_animation() -> void:
	begin_test("T07_ActivitySpecificAnimation")
	var inst = NPCInstance.new()
	inst.setup({ "id": "rowan", "position": [10, 10] })
	inst.behavior_controller.set_activity("work", "seed_shop", Vector2(240, 56), 2)
	inst.behavior_controller.on_destination_reached("seed_shop")
	assert_eq(inst.get_current_animation_name(), "work", "work activity resolves to work animation")
	inst.queue_free()

func _test_T08_player_dialogue_animation() -> void:
	begin_test("T08_PlayerDialogueAnimation")
	var inst = NPCInstance.new()
	inst.setup({ "id": "rowan", "position": [10, 10] })
	inst.is_interacting = true
	assert_eq(inst.get_current_animation_name(), "talk", "dialogue sets animation to talk")
	inst.queue_free()

func _test_T09_npc_social_animation() -> void:
	begin_test("T09_NPCSocialAnimation")
	var inst = NPCInstance.new()
	inst.setup({ "id": "rowan", "position": [10, 10] })
	inst.behavior_controller.start_social_interaction("elias", 3.0)
	assert_eq(inst.get_current_animation_name(), "talk", "social interaction maps to talk animation")
	inst.queue_free()

func _test_T10_missing_animation_fallback() -> void:
	begin_test("T10_MissingAnimationFallback")
	var tex = AssetRegistry.get_npc_animation_texture("custom_nonexistent_npc", "dance", "up", 0)
	assert_true(tex != null, "fallback placeholder texture returned without runtime error")

func _test_T11_animation_restart_prevention() -> void:
	begin_test("T11_AnimationRestartPrevention")
	var inst = NPCInstance.new()
	inst.setup({ "id": "rowan", "position": [10, 10] })
	inst._update_visuals()
	var anim1 = inst.current_anim_name
	inst._update_visuals()
	assert_eq(inst.current_anim_name, anim1, "animation remains stable without restarting")
	inst.queue_free()

func _test_T12_world_transition_animation_reset() -> void:
	begin_test("T12_WorldTransitionAnimationReset")
	var inst = NPCInstance.new()
	inst.setup({ "id": "rowan", "position": [10, 10] })
	inst.teleport_to_location("farm_porch", Vector2(160, 80), "rest")
	assert_eq(inst.velocity, Vector2.ZERO, "velocity zeroed after transition")
	inst.queue_free()

func _test_T13_day_reset_animation() -> void:
	begin_test("T13_DayResetAnimation")
	var inst = NPCInstance.new()
	inst.setup({ "id": "rowan", "position": [10, 10] })
	inst.reset_daily_schedule()
	assert_eq(inst.get_current_animation_name(), "idle", "day reset restores idle animation")
	inst.queue_free()

func _test_T14_multiplayer_animation_consistency() -> void:
	begin_test("T14_MultiplayerAnimationConsistency")
	var inst = NPCInstance.new()
	inst.setup({ "id": "rowan", "position": [10, 10] })
	var dbg = inst.get_navigation_debug_info()
	assert_has(dbg, "animation", "debug payload exports animation state")
	assert_has(dbg, "facing", "debug payload exports facing direction")
	inst.queue_free()
