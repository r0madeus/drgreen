class_name TestEngineHardeningProduction
extends TestCase

## Phase 43 — Engine Hardening, Cross-System Compatibility & Production Readiness Suite.
## Tests:
##   - Save/Load Hardening, Semantic IDs & Corruption Recovery
##   - Mod Dependency, Version & Conflict Validation
##   - Mod Safe Unload & Zero Stale References
##   - Multiplayer Custom State & Event Replication & Handshake
##   - Asset & Localization Safe Fallback
##   - Cross-Platform Path Normalization (Windows / Linux / Android)
##   - Error Recovery & Graceful Diagnostic Logging
##   - End-to-End Complete Production Authoring Lifecycle

var COMPAT_SCRIPT
var NET_SYNC_SCRIPT
var REGISTRY_SCRIPT
var DEF_SCRIPT
var ENTITY_SCRIPT
var FACTORY_SCRIPT
var GRAPH_SCRIPT
var SAVE_MGR_SCRIPT

func test_name_id() -> String:
	return "ENGINE_HARDENING.Phase43Suite"

func _init_scripts() -> void:
	COMPAT_SCRIPT = ResourceLoader.load("res://core/engine_compatibility_service.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	NET_SYNC_SCRIPT = ResourceLoader.load("res://systems/network/network_authoring_synchronizer.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	REGISTRY_SCRIPT = ResourceLoader.load("res://core/components/component_registry.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DEF_SCRIPT = ResourceLoader.load("res://core/components/custom_component_definition.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ENTITY_SCRIPT = ResourceLoader.load("res://core/components/generic_entity.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	FACTORY_SCRIPT = ResourceLoader.load("res://core/components/component_factory.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	GRAPH_SCRIPT = ResourceLoader.load("res://core/gameplay/custom_mechanic_graph.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	SAVE_MGR_SCRIPT = ResourceLoader.load("res://systems/save/save_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()

	# --- 1. Save/Load Hardening & Corruption Resilience ---
	_test_01_save_load_hardening_and_corruption_resilience()

	# --- 2. Mod Dependency & Version Validation ---
	_test_02_mod_dependency_and_version_validation()

	# --- 3. Mod Safe Unload & Zero Stale References ---
	_test_03_mod_safe_unload_and_zero_stale_references()

	# --- 4. Multiplayer Replication & Handshake ---
	_test_04_multiplayer_replication_and_handshake()

	# --- 5. Asset & Localization Safe Fallbacks ---
	_test_05_asset_and_localization_safe_fallbacks()

	# --- 6. Cross-Platform Path Normalization ---
	_test_06_cross_platform_path_normalization()

	# --- 7. Error Recovery & Graceful Diagnostics ---
	_test_07_error_recovery_and_graceful_diagnostics()

	# --- 8. End-to-End Production Lifecycle ---
	_test_08_end_to_end_production_lifecycle()

# ===========================================================================
# 1. Save/Load Hardening & Corruption Resilience
# ===========================================================================

func _test_01_save_load_hardening_and_corruption_resilience() -> void:
	begin_test("01_SaveLoadHardeningAndCorruptionResilience")
	var ent = ENTITY_SCRIPT.new("npc_miner_01", "Goran Miner")
	ent.add_component("health", { "max_health": 120.0, "current_health": 95.0 })
	ent.add_component("state_machine", { "states": ["idle", "mining"], "current_state": "mining" })
	
	var serialized = ent.to_dict()
	assert_true(serialized.has("entity_id"), "Serialized dict has semantic ID")
	assert_false(str(serialized).contains("res://"), "Serialized dict avoids hardcoded res:// paths")
	
	# Test Deserialization
	var restored = ENTITY_SCRIPT.from_dict(serialized)
	assert_eq(restored.entity_id, "npc_miner_01", "Entity restored with identical semantic ID")
	assert_eq(restored.get_component_data("state_machine")["current_state"], "mining", "State machine state restored")
	
	# Test Corrupted Data Tolerance
	var corrupted_dict = { "entity_id": "bad_ent", "components": "INVALID_TYPE_STRING" }
	var safe_fallback = ENTITY_SCRIPT.from_dict(corrupted_dict)
	assert_true(safe_fallback != null, "Corrupted component data does not crash deserializer")
	assert_eq(safe_fallback.entity_id, "bad_ent", "Basic entity shell preserved")

# ===========================================================================
# 2. Mod Dependency & Version Validation
# ===========================================================================

func _test_02_mod_dependency_and_version_validation() -> void:
	begin_test("02_ModDependencyAndVersionValidation")
	var active_mods = [
		{ "mod_id": "core_lib", "version": "1.0.0" },
		{ "mod_id": "texture_pack", "version": "2.0.0" }
	]
	
	var valid_manifest = {
		"mod_id": "survival_expansion",
		"dependencies": ["core_lib"]
	}
	var res1 = COMPAT_SCRIPT.validate_mod_dependencies(valid_manifest, active_mods)
	assert_true(res1["valid"], "Valid mod dependencies passed validation")
	
	var missing_manifest = {
		"mod_id": "magic_spells",
		"dependencies": ["mana_system_mod"]
	}
	var res2 = COMPAT_SCRIPT.validate_mod_dependencies(missing_manifest, active_mods)
	assert_false(res2["valid"], "Missing dependency caught without crash")
	assert_eq(res2["missing_dependencies"][0], "mana_system_mod", "Identified missing dependency correctly")

# ===========================================================================
# 3. Mod Safe Unload & Zero Stale References
# ===========================================================================

func _test_03_mod_safe_unload_and_zero_stale_references() -> void:
	begin_test("03_ModSafeUnloadAndZeroStaleReferences")
	var temp_comp = DEF_SCRIPT.new("temp_mod_comp", "Temp Mod Component")
	REGISTRY_SCRIPT.register_custom_component(temp_comp)
	assert_true(REGISTRY_SCRIPT.has_component_type("temp_mod_comp"), "Temporary mod component registered")
	
	# Safe Unload
	REGISTRY_SCRIPT.unregister_custom_component("temp_mod_comp")
	assert_false(REGISTRY_SCRIPT.has_component_type("temp_mod_comp"), "Component cleanly unregistered on mod unload")
	
	# Verify base components unaffected
	assert_true(REGISTRY_SCRIPT.has_component_type("health"), "Base engine components remain intact")
	assert_true(REGISTRY_SCRIPT.has_component_type("transform"), "Base transform remains intact")

# ===========================================================================
# 4. Multiplayer Replication & Handshake
# ===========================================================================

func _test_04_multiplayer_replication_and_handshake() -> void:
	begin_test("04_MultiplayerReplicationAndHandshake")
	var server_hero = ENTITY_SCRIPT.new("player_net", "Network Player")
	server_hero.add_component("health", { "current_health": 100.0 })
	server_hero.add_component("state_machine", { "current_state": "idle" })
	
	var client_hero = ENTITY_SCRIPT.new("player_net", "Network Player")
	client_hero.add_component("health", { "current_health": 100.0 })
	client_hero.add_component("state_machine", { "current_state": "idle" })
	
	# Packet Replication
	var state_packet = NET_SYNC_SCRIPT.pack_component_state("player_net", "health", { "current_health": 75.0 })
	NET_SYNC_SCRIPT.apply_packet_to_entity(state_packet, client_hero)
	assert_eq(client_hero.get_component_data("health")["current_health"], 75.0, "Health state replicated to client")
	
	var trans_packet = NET_SYNC_SCRIPT.pack_state_transition("player_net", "idle", "casting")
	NET_SYNC_SCRIPT.apply_packet_to_entity(trans_packet, client_hero)
	assert_eq(client_hero.get_component_data("state_machine")["current_state"], "casting", "State transition replicated to client")
	
	# Handshake
	var valid_hs = NET_SYNC_SCRIPT.validate_handshake({ "game_id": "dungeon_quest", "version": "1.0.0" }, { "game_id": "dungeon_quest", "version": "1.0.0" })
	assert_true(valid_hs["compatible"], "Identical game packages match in handshake")
	
	var invalid_hs = NET_SYNC_SCRIPT.validate_handshake({ "game_id": "botanical_haven", "version": "1.0.0" }, { "game_id": "sci_fi_game", "version": "1.0.0" })
	assert_false(invalid_hs["compatible"], "Mismatched game package rejected in handshake")

# ===========================================================================
# 5. Asset & Localization Safe Fallbacks
# ===========================================================================

func _test_05_asset_and_localization_safe_fallbacks() -> void:
	begin_test("05_AssetAndLocalizationSafeFallbacks")
	var safe_asset = COMPAT_SCRIPT.get_safe_asset("", "res://icon.svg")
	assert_eq(safe_asset, "res://icon.svg", "Missing asset ID returns safe fallback icon")
	
	var safe_loc = COMPAT_SCRIPT.get_safe_string("missing.dialogue.key", "Hello traveler!")
	assert_eq(safe_loc, "Hello traveler!", "Missing localization key returns fallback text")

# ===========================================================================
# 6. Cross-Platform Path Normalization
# ===========================================================================

func _test_06_cross_platform_path_normalization() -> void:
	begin_test("06_CrossPlatformPathNormalization")
	var win_path = "user://saves\\slot_01\\game_data.json"
	var norm_path = COMPAT_SCRIPT.normalize_path(win_path)
	assert_eq(norm_path, "user://saves/slot_01/game_data.json", "Backslashes normalized to forward slashes")
	
	var double_slash = "res://assets//textures//tiles.png"
	var norm_res = COMPAT_SCRIPT.normalize_path(double_slash)
	assert_eq(norm_res, "res://assets/textures/tiles.png", "Redundant slashes sanitized")

# ===========================================================================
# 7. Error Recovery & Graceful Diagnostics
# ===========================================================================

func _test_07_error_recovery_and_graceful_diagnostics() -> void:
	begin_test("07_ErrorRecoveryAndGracefulDiagnostics")
	COMPAT_SCRIPT.clear_diagnostics()
	
	COMPAT_SCRIPT.log_diagnostic("TEST_SUBSYSTEM", "Recovered from missing asset gracefully", "WARNING")
	var logs = COMPAT_SCRIPT.get_diagnostics()
	assert_eq(logs.size(), 1, "Diagnostic recorded in memory buffer")
	assert_eq(logs[0]["severity"], "WARNING", "Severity is WARNING")

# ===========================================================================
# 8. End-to-End Production Lifecycle
# ===========================================================================

func _test_08_end_to_end_production_lifecycle() -> void:
	begin_test("08_EndToEndProductionLifecycle")
	# 1. Custom Component
	var stamina_def = DEF_SCRIPT.new("stamina", "Stamina", "Attributes")
	stamina_def.add_property("current", "float", 100.0)
	REGISTRY_SCRIPT.register_custom_component(stamina_def)
	
	# 2. Custom Entity
	var runner = ENTITY_SCRIPT.new("runner_01", "Speed Runner")
	runner.add_component("stamina", { "current": 85.0 })
	runner.add_component("state_machine", { "states": ["idle", "sprinting"], "current_state": "sprinting" })
	
	# 3. Mechanic Execution
	var sprint_graph = GRAPH_SCRIPT.new("sprint_drain", "Sprint Drain", "sprint.tick")
	sprint_graph.add_node({
		"type": "condition",
		"expression": { "left": "state_machine.current_state", "op": "==", "right": "sprinting" },
		"if_true": [{ "type": "modify_property", "path": "stamina.current", "delta": -5.0 }]
	})
	
	var run_ctx = {
		"state_machine": runner.get_component_data("state_machine"),
		"stamina": runner.get_component_data("stamina")
	}
	sprint_graph.execute(run_ctx)
	assert_eq(runner.get_component_data("stamina")["current"], 80.0, "Stamina drained from 85 to 80")
	
	# 4. Cleanup and verify clean state
	REGISTRY_SCRIPT.unregister_custom_component("stamina")
	assert_false(REGISTRY_SCRIPT.has_component_type("stamina"), "Clean teardown completed")
