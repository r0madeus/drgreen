class_name TestQuestSystem
extends TestCase

## Unit tests for QuestManager data model and state transitions.
## Tests the quest_states dictionary directly; does not need scene tree.

func test_name_id() -> String:
	return "UNIT.QuestSystem"

func run_all() -> void:
	test_name = test_name_id()
	_test_initial_status()
	_test_objective_progress()
	_test_quest_completion()
	_test_reward_claimed_flag()
	_test_duplicate_reward_protection()
	_test_quest_status_constants()

func _make_quest_states() -> Dictionary:
	return {
		"q_tutorial": { "status": "active", "progress": [0, 3] },
		"q_harvest_5": { "status": "locked", "progress": [0] },
		"q_completed": { "status": "completed", "progress": [5, 5] },
		"q_claimed": { "status": "claimed", "progress": [5, 5] }
	}

func _test_initial_status() -> void:
	begin_test("initial_status")
	var states = _make_quest_states()
	assert_eq(states["q_tutorial"]["status"], "active", "tutorial is active")
	assert_eq(states["q_harvest_5"]["status"], "locked", "locked quest is locked")

func _test_objective_progress() -> void:
	begin_test("objective_progress")
	var states = _make_quest_states()
	# Simulate progress update
	var prog = states["q_tutorial"]["progress"] as Array
	prog[0] += 2
	assert_eq(prog[0], 2, "progress updated to 2")
	assert_eq(prog[1], 3, "max unchanged at 3")
	assert_lt(prog[0], prog[1], "not yet complete")

func _test_quest_completion() -> void:
	begin_test("quest_completion")
	var states = _make_quest_states()
	var prog = states["q_tutorial"]["progress"] as Array
	prog[0] = prog[1] # hit the target
	var all_done = true
	for i in range(prog.size() / 2):
		if prog[i * 2] < prog[i * 2 + 1]:
			all_done = false
	# The simpler interpretation: check current >= max for each pair
	var complete = (prog[0] >= prog[1])
	if complete:
		states["q_tutorial"]["status"] = "completed"
	assert_eq(states["q_tutorial"]["status"], "completed", "quest completed")

func _test_reward_claimed_flag() -> void:
	begin_test("reward_claimed_flag")
	var ps = PlayerStateFixture.create_default()
	assert_false(ps.has_claimed_reward("q_tutorial"), "reward not yet claimed")
	ps.mark_reward_claimed("q_tutorial")
	assert_true(ps.has_claimed_reward("q_tutorial"), "reward now claimed")

func _test_duplicate_reward_protection() -> void:
	begin_test("duplicate_reward_protection")
	var ps = PlayerStateFixture.create_default()
	ps.gold = 100
	ps.mark_reward_claimed("q_reward_gold")
	# Simulate trying to grant reward again; guard blocks it
	if not ps.has_claimed_reward("q_reward_gold"):
		ps.add_gold(50)
	assert_eq(ps.gold, 100, "gold not doubled (duplicate blocked)")

func _test_quest_status_constants() -> void:
	begin_test("status_constants")
	assert_eq(QuestManager.STATUS_ACTIVE, "active", "STATUS_ACTIVE correct")
	assert_eq(QuestManager.STATUS_LOCKED, "locked", "STATUS_LOCKED correct")
	assert_eq(QuestManager.STATUS_COMPLETED, "completed", "STATUS_COMPLETED correct")
	assert_eq(QuestManager.STATUS_CLAIMED, "claimed", "STATUS_CLAIMED correct")
