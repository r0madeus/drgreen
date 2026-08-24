class_name TestGenericGameplaySystem
extends TestCase

## Phase 39 — Generic Gameplay / Event / Action System Suite.
## Tests:
##   - GameplayEvent Data Contract & Network Authority
##   - Universal Condition Evaluator & Operators
##   - Compound Condition Logic (AND / OR / NOT)
##   - Built-in Gameplay Actions Execution
##   - Action Sequences & Conditional Branching
##   - Trigger Event Filtering & Priority Dispatch
##   - Trigger Cooldown & One-Shot Constraints
##   - RuleManager Global Flags & Variable State
##   - Sandboxed Simulator Dry-Runs & State Isolation
##   - Multi-Layer Editor & Mod Resolution for Rules
##   - SaveData Gameplay State Persistence
##   - Complete Non-Botanical-Haven RPG Dungeon Scenario

var EVENT_SCRIPT
var COND_SCRIPT
var ACT_SCRIPT
var TRIG_SCRIPT
var RULE_MGR_SCRIPT
var SIM_SCRIPT
var DATA_SERVICE_SCRIPT
var MOD_MGR_SCRIPT
var SAVE_DATA_SCRIPT

func test_name_id() -> String:
	return "GENERIC_GAMEPLAY_SYSTEM.Phase39Suite"

func _init_scripts() -> void:
	EVENT_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_event.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	COND_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_condition.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ACT_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_action.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	TRIG_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_trigger.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	RULE_MGR_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_rule_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	SIM_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_simulator.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DATA_SERVICE_SCRIPT = ResourceLoader.load("res://editor/core/editor_data_service.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	MOD_MGR_SCRIPT = ResourceLoader.load("res://editor/core/mod_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	SAVE_DATA_SCRIPT = ResourceLoader.load("res://systems/save/save_data.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()

	# --- 1. Gameplay Event Data Contract ---
	_test_01_gameplay_event_data_contract()

	# --- 2. Condition Operators ---
	_test_02_condition_operators()

	# --- 3. Condition Logical Combinators (AND / OR / NOT) ---
	_test_03_condition_logical_combinators()

	# --- 4. Action Execution Builtins ---
	_test_04_action_execution_builtins()

	# --- 5. Action Sequence & Branching ---
	_test_05_action_sequence_and_branching()

	# --- 6. Trigger Event Evaluation & Dispatch ---
	_test_06_trigger_event_evaluation_and_dispatch()

	# --- 7. Trigger Cooldown & Priority ---
	_test_07_trigger_cooldown_and_priority()

	# --- 8. Rule Manager Global State ---
	_test_08_rule_manager_global_state()

	# --- 9. Simulator Sandboxed Isolation ---
	_test_09_simulator_sandboxed_isolation()

	# --- 10. Multi-Layer Editor & Mod Resolution for Rules ---
	_test_10_editor_and_mod_rule_resolution()

	# --- 11. Save / Load Gameplay State Persistence ---
	_test_11_save_load_gameplay_state_persistence()

	# --- 12. Complete Non-Botanical-Haven RPG Scenario ---
	_test_12_complete_non_botanical_rpg_scenario()

# ===========================================================================
# 1. Gameplay Event Data Contract
# ===========================================================================

func _test_01_gameplay_event_data_contract() -> void:
	begin_test("01_GameplayEventDataContract")
	var evt = EVENT_SCRIPT.new("player_entered_world", "player", "world.dungeon", { "floor": 1 }, { "difficulty": "hard" })
	
	assert_eq(evt.event_type, "player_entered_world", "Event type matches")
	assert_eq(evt.source, "player", "Source matches")
	assert_eq(evt.target, "world.dungeon", "Target matches")
	assert_eq(evt.payload.get("floor", 0), 1, "Payload stored correctly")
	assert_eq(evt.authority, "local", "Default authority is local")
	
	var d = evt.to_dict()
	assert_true(d is Dictionary, "to_dict returns dictionary")
	
	var restored = EVENT_SCRIPT.from_dict(d)
	assert_eq(restored.event_type, "player_entered_world", "Restored event matches")
	assert_eq(restored.target, "world.dungeon", "Restored target matches")

# ===========================================================================
# 2. Condition Operators
# ===========================================================================

func _test_02_condition_operators() -> void:
	begin_test("02_ConditionOperators")
	var ctx = {
		"gold": 250,
		"player": { "level": 5, "name": "Aria" },
		"inventory": ["key_iron", "potion_health"],
		"flags": { "boss_defeated": true }
	}
	
	# Equals / Not Equals
	assert_true(COND_SCRIPT.evaluate({ "path": "player.level", "op": "==", "value": 5 }, ctx), "Level == 5")
	assert_true(COND_SCRIPT.evaluate({ "path": "player.name", "op": "!=", "value": "Bob" }, ctx), "Name != Bob")
	
	# Numeric Comparisons
	assert_true(COND_SCRIPT.evaluate({ "path": "gold", "op": ">", "value": 200 }, ctx), "Gold > 200")
	assert_true(COND_SCRIPT.evaluate({ "path": "gold", "op": "<=", "value": 250 }, ctx), "Gold <= 250")
	assert_false(COND_SCRIPT.evaluate({ "path": "gold", "op": ">", "value": 500 }, ctx), "Gold > 500 is false")
	
	# Contains / In Range
	assert_true(COND_SCRIPT.evaluate({ "path": "inventory", "op": "contains", "value": "key_iron" }, ctx), "Inventory contains key_iron")
	assert_false(COND_SCRIPT.evaluate({ "path": "inventory", "op": "contains", "value": "key_gold" }, ctx), "Inventory lacks key_gold")
	assert_true(COND_SCRIPT.evaluate({ "path": "gold", "op": "in_range", "value": [200, 300] }, ctx), "Gold in range [200, 300]")
	
	# Exists / Flags
	assert_true(COND_SCRIPT.evaluate({ "path": "flags.boss_defeated", "op": "==", "value": true }, ctx), "Flag boss_defeated is true")
	assert_true(COND_SCRIPT.evaluate({ "path": "flags.nonexistent", "op": "not_exists" }, ctx), "Nonexistent flag not_exists")

# ===========================================================================
# 3. Condition Logical Combinators (AND / OR / NOT)
# ===========================================================================

func _test_03_condition_logical_combinators() -> void:
	begin_test("03_ConditionLogicalCombinators")
	var ctx = {
		"gold": 150,
		"reputation": 80,
		"flags": { "is_vip": false }
	}
	
	# AND (All must pass)
	var and_cond = {
		"all": [
			{ "path": "gold", "op": ">=", "value": 100 },
			{ "path": "reputation", "op": ">=", "value": 50 }
		]
	}
	assert_true(COND_SCRIPT.evaluate(and_cond, ctx), "AND condition passes when all true")
	
	# OR (Any can pass)
	var or_cond = {
		"any": [
			{ "path": "flags.is_vip", "op": "==", "value": true },
			{ "path": "reputation", "op": ">=", "value": 75 }
		]
	}
	assert_true(COND_SCRIPT.evaluate(or_cond, ctx), "OR condition passes when reputation is high")
	
	# NOT (Inversion)
	var not_cond = {
		"not": { "path": "flags.is_vip", "op": "==", "value": true }
	}
	assert_true(COND_SCRIPT.evaluate(not_cond, ctx), "NOT condition passes when is_vip is false")

# ===========================================================================
# 4. Action Execution Builtins
# ===========================================================================

func _test_04_action_execution_builtins() -> void:
	begin_test("04_ActionExecutionBuiltins")
	var ctx = { "gold": 100, "inventory": {}, "flags": {}, "variables": {} }
	
	# Currency
	ACT_SCRIPT.execute({ "type": "add_gold", "amount": 50 }, ctx)
	assert_eq(ctx["gold"], 150, "Gold increased by 50")
	ACT_SCRIPT.execute({ "type": "remove_gold", "amount": 30 }, ctx)
	assert_eq(ctx["gold"], 120, "Gold decreased by 30")
	
	# Inventory
	ACT_SCRIPT.execute({ "type": "add_item", "item_id": "ruby", "count": 2 }, ctx)
	assert_eq(ctx["inventory"]["ruby"], 2, "Added 2 rubies")
	ACT_SCRIPT.execute({ "type": "remove_item", "item_id": "ruby", "count": 1 }, ctx)
	assert_eq(ctx["inventory"]["ruby"], 1, "Removed 1 ruby")
	
	# Flags & Variables
	ACT_SCRIPT.execute({ "type": "set_flag", "flag": "puzzle_solved", "value": true }, ctx)
	assert_true(ctx["flags"]["puzzle_solved"], "Flag puzzle_solved set")
	ACT_SCRIPT.execute({ "type": "set_var", "name": "score", "value": 10 }, ctx)
	ACT_SCRIPT.execute({ "type": "modify_var", "name": "score", "delta": 5 }, ctx)
	assert_eq(ctx["variables"]["score"], 15.0, "Variable score modified to 15")

# ===========================================================================
# 5. Action Sequence & Branching
# ===========================================================================

func _test_05_action_sequence_and_branching() -> void:
	begin_test("05_ActionSequenceAndBranching")
	var ctx = {
		"gold": 300,
		"flags": {},
		"inventory": {}
	}
	
	var seq = [
		{ "type": "set_flag", "flag": "shop_visited", "value": true },
		{
			"type": "branch",
			"condition": { "path": "gold", "op": ">=", "value": 200 },
			"if_true": [
				{ "type": "remove_gold", "amount": 200 },
				{ "type": "add_item", "item_id": "magic_scroll", "count": 1 }
			],
			"if_false": [
				{ "type": "show_message", "text": "Not enough gold!" }
			]
		}
	]
	
	var results = ACT_SCRIPT.execute_sequence(seq, ctx)
	assert_eq(results.size(), 2, "Executed 2 top-level sequence actions")
	assert_true(ctx["flags"]["shop_visited"], "shop_visited flag set")
	assert_eq(ctx["gold"], 100, "Gold deducted by branch true")
	assert_eq(ctx["inventory"]["magic_scroll"], 1, "Item added by branch true")

# ===========================================================================
# 6. Trigger Event Evaluation & Dispatch
# ===========================================================================

func _test_06_trigger_event_evaluation_and_dispatch() -> void:
	begin_test("06_TriggerEventEvaluationAndDispatch")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	
	var trig = TRIG_SCRIPT.new(
		"dungeon_welcome_trig",
		"player_entered_world",
		{ "path": "event.target", "op": "==", "value": "world.dungeon" },
		[
			{ "type": "set_flag", "flag": "entered_dungeon", "value": true },
			{ "type": "add_gold", "amount": 50 }
		]
	)
	mgr.register_trigger(trig)
	
	# Matching event with passing condition
	var res_match = mgr.dispatch("player_entered_world", "player", "world.dungeon")
	assert_eq(res_match.size(), 1, "Trigger fired on matching event")
	assert_true(mgr.get_flag("entered_dungeon"), "Flag entered_dungeon set")
	
	# Non-matching event
	var res_nonmatch = mgr.dispatch("player_entered_world", "player", "world.town")
	assert_eq(res_nonmatch.size(), 0, "Trigger skipped on non-matching target")

# ===========================================================================
# 7. Trigger Cooldown & Priority
# ===========================================================================

func _test_07_trigger_cooldown_and_priority() -> void:
	begin_test("07_TriggerCooldownAndPriority")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	
	var once_trig = TRIG_SCRIPT.new("one_time_gift", "interact", {}, [{ "type": "add_gold", "amount": 100 }])
	once_trig.once = true
	mgr.register_trigger(once_trig)
	
	# 1st fire succeeds
	var r1 = mgr.dispatch("interact")
	assert_eq(r1.size(), 1, "1st fire succeeded")
	
	# 2nd fire rejected due to once constraint
	var r2 = mgr.dispatch("interact")
	assert_eq(r2.size(), 0, "2nd fire rejected for once=true")
	
	# Priority test
	var prio_log: Array[String] = []
	var t_low = TRIG_SCRIPT.new("low_prio", "custom_prio_test", {}, [{ "type": "log", "text": "LOW" }])
	t_low.priority = 10
	var t_high = TRIG_SCRIPT.new("high_prio", "custom_prio_test", {}, [{ "type": "log", "text": "HIGH" }])
	t_high.priority = 200
	
	mgr.register_trigger(t_low)
	mgr.register_trigger(t_high)
	
	var p_res = mgr.dispatch("custom_prio_test")
	assert_eq(p_res.size(), 2, "Both priority triggers fired")
	assert_eq(p_res[0]["trigger_id"], "high_prio", "Higher priority trigger fired first")
	assert_eq(p_res[1]["trigger_id"], "low_prio", "Lower priority trigger fired second")

# ===========================================================================
# 8. Rule Manager Global State
# ===========================================================================

func _test_08_rule_manager_global_state() -> void:
	begin_test("08_RuleManagerGlobalState")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	
	mgr.set_flag("lever_a_pulled", true)
	mgr.set_variable("dungeon_depth", 3)
	
	assert_true(mgr.get_flag("lever_a_pulled"), "Flag lever_a_pulled is true")
	assert_eq(mgr.get_variable("dungeon_depth"), 3, "Variable dungeon_depth is 3")
	
	mgr.clear_flag("lever_a_pulled")
	assert_false(mgr.get_flag("lever_a_pulled", false), "Flag cleared")

# ===========================================================================
# 9. Simulator Sandboxed Isolation
# ===========================================================================

func _test_09_simulator_sandboxed_isolation() -> void:
	begin_test("09_SimulatorSandboxedIsolation")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	mgr.set_flag("real_flag", "PROTECTED")
	
	var trig_data = {
		"id": "sim_chest_test",
		"event_type": "open_chest",
		"condition": { "path": "gold", "op": ">=", "value": 50 },
		"actions": [
			{ "type": "remove_gold", "amount": 50 },
			{ "type": "set_flag", "flag": "sim_flag", "value": "MODIFIED_IN_SIM" }
		]
	}
	
	var mock_evt = { "event_type": "open_chest" }
	var mock_ctx = { "gold": 100, "flags": {} }
	
	var sim_res = SIM_SCRIPT.simulate(trig_data, mock_evt, mock_ctx)
	assert_true(sim_res["success"], "Simulation succeeded")
	assert_true(sim_res["condition_passed"], "Simulation condition passed")
	assert_eq(sim_res["resulting_context"]["gold"], 50, "Mock context gold modified to 50")
	assert_eq(sim_res["resulting_context"]["flags"]["sim_flag"], "MODIFIED_IN_SIM", "Mock context flag set")
	
	# Verify Real Rule Manager state was NOT touched
	assert_eq(mgr.get_flag("real_flag"), "PROTECTED", "Real state remains untouched and isolated")
	assert_false(mgr.flags.has("sim_flag"), "Sim flag never leaked into real state")

# ===========================================================================
# 10. Multi-Layer Editor & Mod Resolution for Rules
# ===========================================================================

func _test_10_editor_and_mod_rule_resolution() -> void:
	begin_test("10_EditorAndModRuleResolution")
	var undo_mgr = EditorUndoManager.new()
	var mod_mgr = MOD_MGR_SCRIPT.new()
	var ds = DATA_SERVICE_SCRIPT.new(undo_mgr, mod_mgr)
	
	# Layer 3: Base Package Rule
	ds._base_rules["rule.forest_entrance"] = {
		"id": "forest_entrance",
		"event_type": "player_entered_world",
		"priority": 50,
		"actions": [{ "type": "show_message", "text": "Base Forest Message" }]
	}
	
	var base_act = ds.get_resolved_object("rule.forest_entrance")
	assert_eq(int(base_act.get("priority", 0)), 50, "Base package rule priority is 50")
	
	# Layer 2: Mod override
	var mod = mod_mgr.create_mod("forest_overhaul", "Forest Overhaul", "Modder", "1.0.0")
	mod.overrides["rule.forest_entrance"] = { "priority": 150 }
	var mod_obj = ds.get_resolved_object("rule.forest_entrance")
	assert_eq(int(mod_obj.get("priority", 0)), 150, "Mod override priority takes precedence over base")
	
	# Layer 1: Staged override
	ds.set_staged_override("rule.forest_entrance", "priority", 999)
	var staged_obj = ds.get_resolved_object("rule.forest_entrance")
	assert_eq(int(staged_obj.get("priority", 0)), 999, "User staged override takes highest precedence")
	
	ds.reset_all_modifications()

# ===========================================================================
# 11. Save / Load Gameplay State Persistence
# ===========================================================================

func _test_11_save_load_gameplay_state_persistence() -> void:
	begin_test("11_SaveLoadGameplayStatePersistence")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	mgr.set_flag("door_1_unlocked", true)
	mgr.set_variable("secret_level", 4)
	
	var state_to_save = mgr.get_state()
	
	var sd = SAVE_DATA_SCRIPT.new()
	sd.game_id = "botanical_haven"
	sd.gameplay_state = state_to_save
	
	var sd_dict = sd.to_dict()
	assert_true(sd_dict.has("gameplay_state"), "SaveData dictionary includes gameplay_state")
	
	var restored_sd = SAVE_DATA_SCRIPT.from_dict(sd_dict)
	assert_true(restored_sd.gameplay_state.get("flags", {}).get("door_1_unlocked", false), "Flag restored from SaveData")
	assert_eq(restored_sd.gameplay_state.get("variables", {}).get("secret_level", 0), 4, "Variable restored from SaveData")
	
	# Restore into RuleManager
	mgr.clear_all()
	mgr.set_state(restored_sd.gameplay_state)
	assert_true(mgr.get_flag("door_1_unlocked"), "RuleManager state fully restored")
	assert_eq(mgr.get_variable("secret_level"), 4, "RuleManager variable fully restored")

# ===========================================================================
# 12. Complete Non-Botanical-Haven RPG Scenario
# ===========================================================================

func _test_12_complete_non_botanical_rpg_scenario() -> void:
	begin_test("12_CompleteNonBotanicalRpgScenario")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	
	# Setup isolated custom RPG state
	var custom_rpg_context = {
		"gold": 50,
		"inventory": { "dungeon_key": 1 },
		"flags": { "chest_opened": false }
	}
	
	# Define chest unlock trigger with key requirement and branching
	var chest_trig = TRIG_SCRIPT.new(
		"ancient_chest_unlock",
		"interact_chest",
		{
			"all": [
				{ "path": "inventory.dungeon_key", "op": ">=", "value": 1 },
				{ "path": "flags.chest_opened", "op": "==", "value": false }
			]
		},
		[
			{ "type": "remove_item", "item_id": "dungeon_key", "count": 1 },
			{ "type": "add_item", "item_id": "legendary_sword", "count": 1 },
			{ "type": "add_gold", "amount": 500 },
			{ "type": "set_flag", "flag": "chest_opened", "value": true },
			{ "type": "show_message", "text": "You unlocked the Ancient Chest and found the Legendary Sword!" }
		]
	)
	
	var can_open = chest_trig.can_fire({ "event_type": "interact_chest" }, custom_rpg_context)
	assert_true(can_open, "Can open chest with dungeon_key and chest_opened=false")
	
	var fire_res = chest_trig.fire({ "event_type": "interact_chest" }, custom_rpg_context)
	assert_true(fire_res["fired"], "Chest unlock trigger executed")
	
	# Verify resulting state:
	assert_eq(custom_rpg_context["inventory"]["dungeon_key"], 0, "Dungeon key consumed")
	assert_eq(custom_rpg_context["inventory"]["legendary_sword"], 1, "Legendary sword granted")
	assert_eq(custom_rpg_context["gold"], 550, "Gold increased from 50 to 550")
	assert_true(custom_rpg_context["flags"]["chest_opened"], "chest_opened flag set to true")
	
	# Verify attempting to interact again fails because chest_opened is now true
	var can_open_again = chest_trig.can_fire({ "event_type": "interact_chest" }, custom_rpg_context)
	assert_false(can_open_again, "Cannot open chest a second time")
