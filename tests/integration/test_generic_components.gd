class_name TestGenericComponents
extends TestCase

## Phase 41 — Generic Component & Capability System Suite.
## Tests:
##   - Component Registry & Schema Defaults
##   - Generic Entity Composition & Component Attachment
##   - Dynamic Capability Resolution
##   - Health, Damage & Healing Component Logic
##   - Combat Stats & Modifiers (Flat + Percentage)
##   - State Machine Transitions & Validation
##   - Timer Countdowns & timer.completed Dispatch
##   - Destructibles & Collectible Pickups
##   - Full Entity Component Serialization Round-Trip

var REGISTRY_SCRIPT
var BASE_COMP_SCRIPT
var ENTITY_SCRIPT
var FACTORY_SCRIPT
var RULE_MGR_SCRIPT

func test_name_id() -> String:
	return "GENERIC_COMPONENTS.Phase41Suite"

func _init_scripts() -> void:
	REGISTRY_SCRIPT = ResourceLoader.load("res://core/components/component_registry.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	BASE_COMP_SCRIPT = ResourceLoader.load("res://core/components/base_component.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ENTITY_SCRIPT = ResourceLoader.load("res://core/components/generic_entity.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	FACTORY_SCRIPT = ResourceLoader.load("res://core/components/component_factory.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	RULE_MGR_SCRIPT = ResourceLoader.load("res://core/gameplay/gameplay_rule_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()

	# --- 1. Component Registry & Schemas ---
	_test_01_component_registry_and_schemas()

	# --- 2. Generic Entity Composition ---
	_test_02_generic_entity_composition()

	# --- 3. Capability Resolution ---
	_test_03_capability_resolution()

	# --- 4. Health & Damage Logic ---
	_test_04_health_and_damage_logic()

	# --- 5. Stats & Modifiers (Flat + Percentage) ---
	_test_05_stats_and_modifiers()

	# --- 6. State Machine Transitions ---
	_test_06_state_machine_transitions()

	# --- 7. Timer Countdown & Completion ---
	_test_07_timer_countdown_and_completion()

	# --- 8. Destructibles & Collectibles ---
	_test_08_destructibles_and_collectibles()

	# --- 9. Full Serialization Roundtrip ---
	_test_09_full_serialization_roundtrip()

# ===========================================================================
# 1. Component Registry & Schemas
# ===========================================================================

func _test_01_component_registry_and_schemas() -> void:
	begin_test("01_ComponentRegistryAndSchemas")
	assert_true(REGISTRY_SCRIPT.has_component_type("health"), "Health component registered")
	assert_true(REGISTRY_SCRIPT.has_component_type("combat"), "Combat component registered")
	assert_true(REGISTRY_SCRIPT.has_component_type("inventory"), "Inventory component registered")
	assert_true(REGISTRY_SCRIPT.has_component_type("state_machine"), "State machine registered")
	
	var health_defaults = REGISTRY_SCRIPT.get_default_data("health")
	assert_eq(health_defaults.get("max_health", 0.0), 100.0, "Health default max is 100")

# ===========================================================================
# 2. Generic Entity Composition
# ===========================================================================

func _test_02_generic_entity_composition() -> void:
	begin_test("02_GenericEntityComposition")
	var entity = ENTITY_SCRIPT.new("goblin_01", "Goblin Warrior")
	entity.tags.append("enemy")
	entity.tags.append("monster")
	
	entity.add_component("health", { "max_health": 80.0, "current_health": 80.0 })
	entity.add_component("combat", { "attack_power": 15.0 })
	entity.add_component("inventory", { "slots": 5 })
	
	assert_true(entity.has_component("health"), "Has health component")
	assert_true(entity.has_component("combat"), "Has combat component")
	assert_true(entity.has_component("inventory"), "Has inventory component")
	assert_false(entity.has_component("dialogue"), "Does not have dialogue component")

# ===========================================================================
# 3. Capability Resolution
# ===========================================================================

func _test_03_capability_resolution() -> void:
	begin_test("03_CapabilityResolution")
	var chest = ENTITY_SCRIPT.new("chest_01", "Treasure Chest")
	chest.add_component("interaction", { "event": "open_chest" })
	chest.add_component("inventory", { "slots": 10 })
	
	assert_true(chest.has_capability("interactable"), "Chest has interactable capability")
	assert_true(chest.has_capability("inventory"), "Chest has inventory capability")
	assert_false(chest.has_capability("combat"), "Chest does not have combat capability")
	
	chest.remove_component("inventory")
	assert_false(chest.has_capability("inventory"), "Inventory capability removed when component removed")

# ===========================================================================
# 4. Health & Damage Logic
# ===========================================================================

func _test_04_health_and_damage_logic() -> void:
	begin_test("04_HealthAndDamageLogic")
	var h_data = { "max_health": 100.0, "current_health": 100.0 }
	
	var d_res = FACTORY_SCRIPT.apply_damage(h_data, 30.0, "fire")
	assert_eq(h_data["current_health"], 70.0, "Health decreased to 70")
	assert_false(d_res["died"], "Entity is not dead")
	
	var lethal_res = FACTORY_SCRIPT.apply_damage(h_data, 80.0, "physical")
	assert_eq(h_data["current_health"], 0.0, "Health clamped to 0")
	assert_true(lethal_res["died"], "Entity marked dead on lethal hit")
	
	FACTORY_SCRIPT.apply_heal(h_data, 40.0)
	assert_eq(h_data["current_health"], 40.0, "Health restored to 40")

# ===========================================================================
# 5. Stats & Modifiers
# ===========================================================================

func _test_05_stats_and_modifiers() -> void:
	begin_test("05_StatsAndModifiers")
	var stats_data = {
		"base": { "attack": 10.0, "speed": 100.0 },
		"modifiers": {
			"attack": [
				{ "mod_id": "sword_bonus", "value": 15.0, "is_pct": false }, # Flat +15 -> 25
				{ "mod_id": "berserk_buff", "value": 20.0, "is_pct": true }   # +20% of 25 -> 30
			]
		}
	}
	
	var final_atk = FACTORY_SCRIPT.calculate_stat(stats_data, "attack", 10.0)
	assert_eq(final_atk, 30.0, "Calculated attack is 30.0 ( (10+15) * 1.20 )")

# ===========================================================================
# 6. State Machine Transitions
# ===========================================================================

func _test_06_state_machine_transitions() -> void:
	begin_test("06_StateMachineTransitions")
	var sm_data = {
		"states": ["closed", "opening", "open", "closing"],
		"current_state": "closed"
	}
	
	var t1 = FACTORY_SCRIPT.transition_state(sm_data, "opening")
	assert_true(t1["success"], "Transition to opening succeeded")
	assert_eq(sm_data["current_state"], "opening", "Current state is opening")
	
	var t_invalid = FACTORY_SCRIPT.transition_state(sm_data, "flying")
	assert_false(t_invalid["success"], "Invalid state rejected")
	assert_eq(sm_data["current_state"], "opening", "State remains opening")

# ===========================================================================
# 7. Timer Countdown & Completion
# ===========================================================================

func _test_07_timer_countdown_and_completion() -> void:
	begin_test("07_TimerCountdownAndCompletion")
	var mgr = RULE_MGR_SCRIPT.get_instance()
	mgr.clear_all()
	
	mgr.start_timer("door_auto_close", 3.0)
	assert_true(mgr.is_timer_active("door_auto_close"), "Timer is active")
	
	# Partial tick
	var c1 = mgr.update_timers(1.5)
	assert_eq(c1.size(), 0, "Timer not yet completed after 1.5s")
	
	# Complete tick
	var c2 = mgr.update_timers(2.0)
	assert_eq(c2.size(), 1, "Timer completed after total 3.5s")
	assert_eq(c2[0], "door_auto_close", "Completed timer is door_auto_close")
	assert_false(mgr.is_timer_active("door_auto_close"), "Timer is now inactive")

# ===========================================================================
# 8. Destructibles & Collectibles
# ===========================================================================

func _test_08_destructibles_and_collectibles() -> void:
	begin_test("08_DestructiblesAndCollectibles")
	var dest_data = {
		"durability": 50.0,
		"cracked_threshold": 25.0,
		"drop_item": "ore_iron"
	}
	
	var hit1 = FACTORY_SCRIPT.apply_impact(dest_data, 30.0)
	assert_true(hit1["is_cracked"], "Destructible is cracked at 20 durability")
	assert_false(hit1["is_destroyed"], "Not yet destroyed")
	
	var hit2 = FACTORY_SCRIPT.apply_impact(dest_data, 25.0)
	assert_true(hit2["is_destroyed"], "Destructible destroyed on second hit")
	assert_eq(hit2["drop_item"], "ore_iron", "Drops iron ore upon destruction")

# ===========================================================================
# 9. Full Serialization Roundtrip
# ===========================================================================

func _test_09_full_serialization_roundtrip() -> void:
	begin_test("09_FullSerializationRoundtrip")
	var hero = ENTITY_SCRIPT.new("hero_01", "Brave Knight")
	hero.tags.append("player")
	hero.tags.append("champion")
	hero.properties["team"] = "blue"
	
	hero.add_component("health", { "max_health": 150.0, "current_health": 120.0 })
	hero.add_component("combat", { "attack_power": 35.0 })
	hero.add_component("inventory", { "items": { "potion": 3 } })
	
	var dict_data = hero.to_dict()
	assert_true(dict_data.has("components"), "Serialized dict has components")
	
	var restored = ENTITY_SCRIPT.from_dict(dict_data)
	assert_eq(restored.entity_id, "hero_01", "Restored entity ID matches")
	assert_eq(restored.tags.size(), 2, "Tags restored")
	assert_true(restored.has_component("health"), "Health component restored")
	assert_eq(restored.get_component_data("health")["current_health"], 120.0, "Health data value matches")
	assert_true(restored.has_capability("combat"), "Capabilities dynamically restored")
