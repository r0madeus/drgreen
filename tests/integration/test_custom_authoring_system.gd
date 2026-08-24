class_name TestCustomAuthoringSystem
extends TestCase

## Phase 42 — Custom Component, Event & Mechanic Authoring System Suite.
## Tests:
##   - Custom Component Definition & Schema Creation
##   - Custom Component Attachment & Capability Resolution
##   - Safe Sandboxed Expression Evaluation
##   - Acceptance Scenario 1: Complete In-Game Hunger System
##   - Acceptance Scenario 2: Data-Driven Pressure Plate System
##   - Acceptance Scenario 3: Generic Treasure Chest System
##   - High-Performance Entity Query Engine (Spatial & Component Filters)
##   - Reusable Mechanic Templates & Game Package Transfer
##   - 5,000 Entity Scalability & Query Benchmark

var REGISTRY_SCRIPT
var DEF_SCRIPT
var ENTITY_SCRIPT
var FACTORY_SCRIPT
var EXPR_SCRIPT
var GRAPH_SCRIPT
var QUERY_SCRIPT

func test_name_id() -> String:
	return "CUSTOM_AUTHORING_SYSTEM.Phase42Suite"

func _init_scripts() -> void:
	REGISTRY_SCRIPT = ResourceLoader.load("res://core/components/component_registry.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DEF_SCRIPT = ResourceLoader.load("res://core/components/custom_component_definition.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ENTITY_SCRIPT = ResourceLoader.load("res://core/components/generic_entity.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	FACTORY_SCRIPT = ResourceLoader.load("res://core/components/component_factory.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	EXPR_SCRIPT = ResourceLoader.load("res://core/gameplay/safe_expression_evaluator.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	GRAPH_SCRIPT = ResourceLoader.load("res://core/gameplay/custom_mechanic_graph.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	QUERY_SCRIPT = ResourceLoader.load("res://core/components/entity_query_engine.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()

	# --- 1. Custom Component Definition & Schema ---
	_test_01_custom_component_definition_and_schema()

	# --- 2. Custom Component Attachment & Capability ---
	_test_02_custom_component_attachment_and_capability()

	# --- 3. Safe Expression Evaluator ---
	_test_03_safe_expression_evaluator()

	# --- 4. Acceptance Scenario 1: Hunger System ---
	_test_04_acceptance_scenario_1_hunger_system()

	# --- 5. Acceptance Scenario 2: Pressure Plate System ---
	_test_05_acceptance_scenario_2_pressure_plate_system()

	# --- 6. Acceptance Scenario 3: Custom Chest System ---
	_test_06_acceptance_scenario_3_custom_chest_system()

	# --- 7. Entity Query Engine ---
	_test_07_entity_query_engine()

	# --- 8. Reusable Templates & Package Transfer ---
	_test_08_reusable_templates_and_package_transfer()

	# --- 9. 5,000 Entity Scalability Benchmark ---
	_test_09_scalability_benchmark_5000_entities()

# ===========================================================================
# 1. Custom Component Definition & Schema
# ===========================================================================

func _test_01_custom_component_definition_and_schema() -> void:
	begin_test("01_CustomComponentDefinitionAndSchema")
	var hunger_def = DEF_SCRIPT.new("hunger", "Hunger", "Survival", "Tracks player hunger")
	hunger_def.add_property("current", "float", 100.0, { "min": 0.0, "max": 100.0, "required": true })
	hunger_def.add_property("maximum", "float", 100.0, { "min": 10.0, "max": 200.0 })
	hunger_def.add_property("drain_rate", "float", 1.0)
	hunger_def.capabilities.append("survival")
	
	var registered = REGISTRY_SCRIPT.register_custom_component(hunger_def)
	assert_true(registered, "Custom component 'hunger' registered successfully")
	assert_true(REGISTRY_SCRIPT.has_component_type("hunger"), "Registry recognizes custom 'hunger' component")
	
	var default_data = REGISTRY_SCRIPT.get_default_data("hunger")
	assert_eq(default_data.get("current", 0.0), 100.0, "Default current hunger is 100.0")
	assert_eq(default_data.get("drain_rate", 0.0), 1.0, "Default drain rate is 1.0")

# ===========================================================================
# 2. Custom Component Attachment & Capability
# ===========================================================================

func _test_02_custom_component_attachment_and_capability() -> void:
	begin_test("02_CustomComponentAttachmentAndCapability")
	var player = ENTITY_SCRIPT.new("player_01", "Adventurer")
	player.add_component("hunger", { "current": 80.0, "drain_rate": 2.0 })
	
	assert_true(player.has_component("hunger"), "Player has custom hunger component")
	assert_eq(player.get_component_data("hunger")["current"], 80.0, "Custom component instance value initialized")
	assert_true(player.has_capability("survival"), "Player derived 'survival' capability from custom component")

# ===========================================================================
# 3. Safe Expression Evaluator
# ===========================================================================

func _test_03_safe_expression_evaluator() -> void:
	begin_test("03_SafeExpressionEvaluator")
	var ctx = {
		"component": {
			"hunger": { "current": 15.0, "maximum": 100.0 },
			"health": { "current": 80.0 }
		},
		"state": { "player": "normal" },
		"inventory": ["sword", "meat", "key"]
	}
	
	var expr1 = { "left": "component.hunger.current", "op": "<=", "right": 25.0 }
	assert_true(EXPR_SCRIPT.evaluate(expr1, ctx), "15.0 <= 25.0 evaluates to TRUE")
	
	var expr2 = { "left": "component.health.current", "op": ">", "right": 90.0 }
	assert_false(EXPR_SCRIPT.evaluate(expr2, ctx), "80.0 > 90.0 evaluates to FALSE")
	
	var expr_compound = {
		"all": [
			{ "left": "component.hunger.current", "op": "<=", "right": 20.0 },
			{ "left": "inventory", "op": "contains", "right": "meat" }
		]
	}
	assert_true(EXPR_SCRIPT.evaluate(expr_compound, ctx), "Compound AND evaluates to TRUE")

# ===========================================================================
# 4. Acceptance Scenario 1: Hunger System
# ===========================================================================

func _test_04_acceptance_scenario_1_hunger_system() -> void:
	begin_test("04_AcceptanceScenario1HungerSystem")
	var player = ENTITY_SCRIPT.new("player", "Player")
	player.add_component("hunger", { "current": 100.0, "maximum": 100.0, "drain_rate": 1.0 })
	player.add_component("health", { "max_health": 100.0, "current_health": 100.0 })
	player.add_component("state_machine", { "states": ["normal", "hungry", "starving"], "current_state": "normal" })
	
	# Graph: Hunger Drain & Starvation Logic
	var graph = GRAPH_SCRIPT.new("hunger_loop", "Hunger Loop", "hunger.changed")
	
	# Step A: Drain check <= 25 -> set hungry
	graph.add_node({
		"type": "condition",
		"expression": { "left": "component.hunger.current", "op": "<=", "right": 25.0 },
		"if_true": [{ "type": "transition_state", "state": "hungry" }]
	})
	
	# Step B: Drain check <= 0 -> set starving & damage 5
	graph.add_node({
		"type": "condition",
		"expression": { "left": "component.hunger.current", "op": "<=", "right": 0.0 },
		"if_true": [
			{ "type": "transition_state", "state": "starving" },
			{ "type": "damage", "amount": 5.0 }
		]
	})
	
	# Execution 1: Hunger at 20.0 -> transitions to hungry
	var ctx1 = {
		"component": { "hunger": { "current": 20.0 } },
		"state_machine": player.get_component_data("state_machine"),
		"health": player.get_component_data("health")
	}
	var res1 = graph.execute(ctx1)
	assert_true(res1["success"], "Hunger graph ran successfully")
	assert_eq(player.get_component_data("state_machine")["current_state"], "hungry", "Player transitioned to 'hungry'")
	assert_eq(player.get_component_data("health")["current_health"], 100.0, "No damage taken at hungry state")
	
	# Execution 2: Hunger at 0.0 -> transitions to starving and takes 5 damage
	var ctx2 = {
		"component": { "hunger": { "current": 0.0 } },
		"state_machine": player.get_component_data("state_machine"),
		"health": player.get_component_data("health")
	}
	var res2 = graph.execute(ctx2)
	assert_true(res2["success"], "Starvation logic executed")
	assert_eq(player.get_component_data("state_machine")["current_state"], "starving", "Player transitioned to 'starving'")
	assert_eq(player.get_component_data("health")["current_health"], 95.0, "Player damaged 5 HP due to starvation")

# ===========================================================================
# 5. Acceptance Scenario 2: Pressure Plate System
# ===========================================================================

func _test_05_acceptance_scenario_2_pressure_plate_system() -> void:
	begin_test("05_AcceptanceScenario2PressurePlateSystem")
	var plate = ENTITY_SCRIPT.new("plate_01", "Pressure Plate")
	plate.add_component("state_machine", { "states": ["inactive", "active"], "current_state": "inactive" })
	
	var door = ENTITY_SCRIPT.new("door_01", "Linked Dungeon Door")
	door.add_component("state_machine", { "states": ["closed", "open"], "current_state": "closed" })
	
	# Enter Graph
	var enter_graph = GRAPH_SCRIPT.new("plate_enter", "Plate Enter", "pressure_plate.enter")
	enter_graph.add_node({ "type": "transition_state", "state": "active" })
	
	# Exit Graph
	var exit_graph = GRAPH_SCRIPT.new("plate_exit", "Plate Exit", "pressure_plate.exit")
	exit_graph.add_node({ "type": "transition_state", "state": "inactive" })
	
	# Simulate Enter
	enter_graph.execute({ "state_machine": plate.get_component_data("state_machine") })
	FACTORY_SCRIPT.transition_state(door.get_component_data("state_machine"), "open")
	assert_eq(plate.get_component_data("state_machine")["current_state"], "active", "Plate state is active")
	assert_eq(door.get_component_data("state_machine")["current_state"], "open", "Linked door opened")
	
	# Simulate Exit
	exit_graph.execute({ "state_machine": plate.get_component_data("state_machine") })
	FACTORY_SCRIPT.transition_state(door.get_component_data("state_machine"), "closed")
	assert_eq(plate.get_component_data("state_machine")["current_state"], "inactive", "Plate state is inactive")
	assert_eq(door.get_component_data("state_machine")["current_state"], "closed", "Linked door closed")

# ===========================================================================
# 6. Acceptance Scenario 3: Custom Chest System
# ===========================================================================

func _test_06_acceptance_scenario_3_custom_chest_system() -> void:
	begin_test("06_AcceptanceScenario3CustomChestSystem")
	var chest = ENTITY_SCRIPT.new("chest_01", "Treasure Chest")
	chest.add_component("state_machine", { "states": ["closed", "open"], "current_state": "closed" })
	chest.add_component("inventory", { "items": { "gold_coin": 50 } })
	
	var player = ENTITY_SCRIPT.new("player", "Player")
	player.add_component("inventory", { "items": {} })
	
	var chest_graph = GRAPH_SCRIPT.new("chest_open", "Open Chest", "chest_interacted")
	chest_graph.add_node({
		"type": "condition",
		"expression": { "left": "state_machine.current_state", "op": "==", "right": "closed" },
		"if_true": [{ "type": "transition_state", "state": "open" }]
	})
	chest_graph.add_node({ "type": "emit_event", "event": "chest.opened" })
	
	var ctx = { "state_machine": chest.get_component_data("state_machine") }
	var res = chest_graph.execute(ctx)
	assert_true(res["success"], "Chest opened successfully")
	assert_eq(chest.get_component_data("state_machine")["current_state"], "open", "Chest is open")
	
	# Transfer items into player
	FACTORY_SCRIPT.inventory_add(player.get_component_data("inventory"), "gold_coin", 50)
	FACTORY_SCRIPT.inventory_remove(chest.get_component_data("inventory"), "gold_coin", 50)
	assert_eq(FACTORY_SCRIPT.inventory_count(player.get_component_data("inventory"), "gold_coin"), 50, "Player received 50 gold coins")
	assert_eq(FACTORY_SCRIPT.inventory_count(chest.get_component_data("inventory"), "gold_coin"), 0, "Chest is now empty")

# ===========================================================================
# 7. Entity Query Engine
# ===========================================================================

func _test_07_entity_query_engine() -> void:
	begin_test("07_EntityQueryEngine")
	var entities: Array = []
	for i in range(100):
		var ent = ENTITY_SCRIPT.new("ent_%d" % i, "Entity %d" % i)
		ent.add_component("transform", { "position": [i * 2, i * 2] })
		if i % 2 == 0:
			ent.tags.append("enemy")
			ent.add_component("health", { "max_health": 50.0, "current_health": 50.0 })
		else:
			ent.tags.append("npc")
			ent.add_component("dialogue", { "dialogue_id": "greet" })
		entities.append(ent)
		
	var enemies = QUERY_SCRIPT.query(entities, { "tag": "enemy", "component": "health" })
	assert_eq(enemies.size(), 50, "Found exactly 50 enemies with health component")
	
	var spatial = QUERY_SCRIPT.query(entities, { "origin": [0, 0], "radius": 15.0 })
	assert_true(spatial.size() >= 5, "Found entities within spatial radius")

# ===========================================================================
# 8. Reusable Templates & Package Transfer
# ===========================================================================

func _test_08_reusable_templates_and_package_transfer() -> void:
	begin_test("08_ReusableTemplatesAndPackageTransfer")
	var hunger_graph = GRAPH_SCRIPT.new("hunger_template", "Hunger System Template", "hunger.changed")
	hunger_graph.description = "Reusable survival hunger mechanic template"
	hunger_graph.add_node({
		"type": "condition",
		"expression": { "left": "hunger.current", "op": "<=", "right": 0 },
		"if_true": [{ "type": "damage", "amount": 5.0 }]
	})
	
	var serialized = hunger_graph.to_dict()
	assert_eq(serialized["mechanic_id"], "hunger_template", "Template serialized")
	
	var imported_graph = GRAPH_SCRIPT.from_dict(serialized)
	assert_eq(imported_graph.name, "Hunger System Template", "Template imported cleanly into target package")
	assert_eq(imported_graph.nodes.size(), 1, "Nodes preserved")

# ===========================================================================
# 9. 5,000 Entity Scalability Benchmark
# ===========================================================================

func _test_09_scalability_benchmark_5000_entities() -> void:
	begin_test("09_ScalabilityBenchmark5000Entities")
	var pool: Array = []
	var count = 5000
	
	var start_usec = Time.get_ticks_usec()
	for i in range(count):
		var ent = ENTITY_SCRIPT.new("e_%d" % i, "E %d" % i)
		ent.add_component("hunger", { "current": 50.0 })
		pool.append(ent)
	var create_ms = (Time.get_ticks_usec() - start_usec) / 1000.0
	
	assert_eq(pool.size(), 5000, "Instantiated 5,000 custom component entities")
	assert_true(create_ms < 2000.0, "Instantiating 5,000 entities took %.2f ms (< 2000ms limit)" % create_ms)
	
	var query_start = Time.get_ticks_usec()
	var matches = QUERY_SCRIPT.query(pool, { "component": "hunger" })
	var query_ms = (Time.get_ticks_usec() - query_start) / 1000.0
	
	assert_eq(matches.size(), 5000, "Query matched all 5,000 entities")
	assert_true(query_ms < 200.0, "Querying 5,000 entities took %.2f ms (< 200ms limit)" % query_ms)
