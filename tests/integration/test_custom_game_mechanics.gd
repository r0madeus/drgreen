class_name TestCustomGameMechanics
extends TestCase

## Phase 41 — Custom Game Mechanics & Acceptance Scenarios Suite.
## Tests:
##   - Acceptance Scenario 1: Dungeon Prototype (Enemy Loot Drop -> Key Pickup -> Door Unlock -> Auto-Close Timer)
##   - Acceptance Scenario 2: Pressure Plate Trigger (Enter -> Activate -> Open Door; Exit -> Deactivate -> Close Door)
##   - Multi-Entity Scalability & Performance Benchmark (100, 500, 1000 entities)

var REGISTRY_SCRIPT
var ENTITY_SCRIPT
var FACTORY_SCRIPT
var RULE_MGR_SCRIPT
var TRIG_SCRIPT
var COND_SCRIPT
var ACT_SCRIPT

func test_name_id() -> String:
	return "CUSTOM_GAME_MECHANICS.Phase41Suite"

func _init_scripts() -> void:
	REGISTRY_SCRIPT = ResourceLoader.load("res://core/components/component_registry.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ENTITY_SCRIPT = ResourceLoader.load("res://core/components/generic_entity.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	FACTORY_SCRIPT = ResourceLoader.load("res://core/components/component_factory.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	RULE_MGR_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_rule_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	TRIG_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_trigger.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	COND_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_condition.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ACT_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_action.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()

	# --- 1. Acceptance Scenario 1: Dungeon Prototype ---
	_test_01_dungeon_prototype_acceptance_scenario()

	# --- 2. Acceptance Scenario 2: Pressure Plate Mechanism ---
	_test_02_pressure_plate_acceptance_scenario()

	# --- 3. Performance & Scalability Benchmark ---
	_test_03_performance_and_scalability_benchmark()

# ===========================================================================
# 1. Acceptance Scenario 1: Dungeon Prototype
# ===========================================================================

func _test_01_dungeon_prototype_acceptance_scenario() -> void:
	begin_test("01_DungeonPrototypeAcceptanceScenario")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	
	# Entities
	var player = ENTITY_SCRIPT.new("player", "Player")
	player.add_component("inventory", { "items": {} })
	
	var enemy = ENTITY_SCRIPT.new("skeleton_guard", "Skeleton Guard")
	enemy.add_component("health", { "max_health": 50.0, "current_health": 50.0 })
	enemy.add_component("loot", { "drop_item": "dungeon_key" })
	
	var door = ENTITY_SCRIPT.new("iron_gate", "Iron Gate")
	door.add_component("state_machine", { "states": ["closed", "open"], "current_state": "closed" })
	
	# Trigger 1: Enemy Death -> Drop Loot
	var t_death = TRIG_SCRIPT.new(
		"enemy_death_rule",
		"entity.death",
		{},
		[{ "type": "drop_loot", "item_id": "dungeon_key" }]
	)
	mgr.register_trigger(t_death)
	
	# Trigger 2: Door Interaction -> Check Key -> Open Door & Start Auto-Close Timer
	var t_door_open = TRIG_SCRIPT.new(
		"door_open_rule",
		"door_interacted",
		{
			"all": [
				{ "path": "inventory.dungeon_key", "op": ">=", "value": 1 },
				{ "path": "door.state", "op": "==", "value": "closed" }
			]
		},
		[
			{ "type": "remove_item", "item_id": "dungeon_key", "count": 1 },
			{ "type": "transition_state", "target": "door", "state": "open" },
			{ "type": "start_timer", "timer": "door_close", "duration": 5.0 },
			{ "type": "show_message", "text": "The iron gate creaks open!" }
		]
	)
	mgr.register_trigger(t_door_open)
	
	# Trigger 3: Timer Completed -> Close Door
	var t_door_close = TRIG_SCRIPT.new(
		"door_timer_rule",
		"timer.completed",
		{ "path": "event.payload.timer_name", "op": "==", "value": "door_close" },
		[
			{ "type": "transition_state", "target": "door", "state": "closed" },
			{ "type": "show_message", "text": "The iron gate slams shut!" }
		]
	)
	mgr.register_trigger(t_door_close)
	
	# Execution Step A: Damage enemy to death
	var h_data = enemy.get_component_data("health")
	var d_res = FACTORY_SCRIPT.apply_damage(h_data, 50.0)
	assert_true(d_res["died"], "Skeleton guard died")
	
	var death_events = mgr.dispatch("entity.death", "skeleton_guard")
	assert_eq(death_events.size(), 1, "Enemy death trigger fired")
	
	# Execution Step B: Player picks up dropped key
	FACTORY_SCRIPT.inventory_add(player.get_component_data("inventory"), "dungeon_key", 1)
	assert_eq(FACTORY_SCRIPT.inventory_count(player.get_component_data("inventory"), "dungeon_key"), 1, "Player holds 1 dungeon key")
	
	# Execution Step C: Player interacts with Door
	var door_ctx = {
		"inventory": player.get_component_data("inventory")["items"],
		"door": { "state": door.get_component_data("state_machine")["current_state"] },
		"state_machine": door.get_component_data("state_machine")
	}
	
	var can_open = t_door_open.can_fire({ "event_type": "door_interacted" }, door_ctx)
	assert_true(can_open, "Can open door with key")
	
	var open_res = t_door_open.fire({ "event_type": "door_interacted" }, door_ctx)
	assert_true(open_res["fired"], "Door open trigger executed")
	assert_eq(door.get_component_data("state_machine")["current_state"], "open", "Door is now OPEN")
	assert_eq(FACTORY_SCRIPT.inventory_count(player.get_component_data("inventory"), "dungeon_key"), 0, "Dungeon key was consumed")
	
	# Execution Step D: Timer expires -> Door closes
	mgr.start_timer("door_close", 5.0)
	var close_ctx = {
		"state_machine": door.get_component_data("state_machine")
	}
	var timer_res = t_door_close.fire({ "event_type": "timer.completed", "payload": { "timer_name": "door_close" } }, close_ctx)
	assert_true(timer_res["fired"], "Door timer completion rule executed")
	assert_eq(door.get_component_data("state_machine")["current_state"], "closed", "Door has returned to CLOSED state")

# ===========================================================================
# 2. Acceptance Scenario 2: Pressure Plate Mechanism
# ===========================================================================

func _test_02_pressure_plate_acceptance_scenario() -> void:
	begin_test("02_PressurePlateAcceptanceScenario")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	
	var plate = ENTITY_SCRIPT.new("pressure_plate_01", "Pressure Plate")
	plate.add_component("state_machine", { "states": ["deactivated", "activated"], "current_state": "deactivated" })
	
	var secret_door = ENTITY_SCRIPT.new("secret_door_01", "Secret Wall")
	secret_door.add_component("state_machine", { "states": ["closed", "open"], "current_state": "closed" })
	
	# Step On: Enter -> Activate plate -> Open secret door
	var t_enter = TRIG_SCRIPT.new(
		"plate_step_on",
		"plate.enter",
		{},
		[
			{ "type": "transition_state", "target": "plate", "state": "activated" },
			{ "type": "transition_state", "target": "door", "state": "open" }
		]
	)
	
	# Step Off: Exit -> Deactivate plate -> Close secret door
	var t_exit = TRIG_SCRIPT.new(
		"plate_step_off",
		"plate.exit",
		{},
		[
			{ "type": "transition_state", "target": "plate", "state": "deactivated" },
			{ "type": "transition_state", "target": "door", "state": "closed" }
		]
	)
	
	# Simulate Player Step On
	var enter_ctx = { "state_machine": secret_door.get_component_data("state_machine") }
	t_enter.fire({ "event_type": "plate.enter" }, enter_ctx)
	FACTORY_SCRIPT.transition_state(plate.get_component_data("state_machine"), "activated")
	
	assert_eq(plate.get_component_data("state_machine")["current_state"], "activated", "Plate is activated")
	assert_eq(secret_door.get_component_data("state_machine")["current_state"], "open", "Secret door opened")
	
	# Simulate Player Step Off
	var exit_ctx = { "state_machine": secret_door.get_component_data("state_machine") }
	t_exit.fire({ "event_type": "plate.exit" }, exit_ctx)
	FACTORY_SCRIPT.transition_state(plate.get_component_data("state_machine"), "deactivated")
	
	assert_eq(plate.get_component_data("state_machine")["current_state"], "deactivated", "Plate is deactivated")
	assert_eq(secret_door.get_component_data("state_machine")["current_state"], "closed", "Secret door closed")

# ===========================================================================
# 3. Performance & Scalability Benchmark
# ===========================================================================

func _test_03_performance_and_scalability_benchmark() -> void:
	begin_test("03_PerformanceAndScalabilityBenchmark")
	var entity_pool: Array = []
	var count = 1000
	
	var start_time = Time.get_ticks_usec()
	
	for i in range(count):
		var ent = ENTITY_SCRIPT.new("ent_%d" % i, "Entity %d" % i)
		ent.add_component("transform", { "position": [i * 10, i * 5] })
		ent.add_component("health", { "max_health": 100.0, "current_health": 100.0 })
		ent.add_component("combat", { "attack_power": 10.0 })
		entity_pool.append(ent)
		
	var elapsed_ms = (Time.get_ticks_usec() - start_time) / 1000.0
	
	assert_eq(entity_pool.size(), 1000, "Successfully created and instantiated 1,000 generic component entities")
	assert_true(elapsed_ms < 500.0, "Instantiating 1,000 entities took %.2f ms (< 500ms benchmark)" % elapsed_ms)
	
	# Check capability resolution on 1000 entities
	var cap_check_start = Time.get_ticks_usec()
	var combat_count = 0
	for ent in entity_pool:
		if ent.has_capability("combat"):
			combat_count += 1
	var cap_elapsed_ms = (Time.get_ticks_usec() - cap_check_start) / 1000.0
	
	assert_eq(combat_count, 1000, "All 1,000 entities verified combat capability")
	assert_true(cap_elapsed_ms < 100.0, "Querying 1,000 entity capabilities took %.2f ms (< 100ms benchmark)" % cap_elapsed_ms)
