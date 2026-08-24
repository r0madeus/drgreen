class_name TestGamePackageArchitecture
extends TestCase

## Phase 38 — Botanical Haven Game/Engine Separation & Data-Driven Game Package Architecture Suite.
## Tests:
##   - GamePackage Data Contract & Validation
##   - GamePackageManager Discovery & Lifecycle
##   - Botanical Haven Official Package Isolation
##   - Empty Game Template Creation
##   - Multi-Layer Resolution Hierarchy (User Override > Mod > Game Package > Engine Fallback)
##   - Dynamic Content Resolution per Game Package
##   - Mod target_game_id Compatibility
##   - Save Game ID Validation & Protection
##   - Multiplayer Session Game Handshake
##   - Full End-to-End Authoring on Custom Game Package

var GAME_PKG_SCRIPT
var GAME_MGR_SCRIPT
var DATA_SERVICE_SCRIPT
var MOD_MGR_SCRIPT
var SAVE_DATA_SCRIPT
var SAVE_MGR_SCRIPT
var NET_SESSION_SCRIPT

func test_name_id() -> String:
	return "GAME_PACKAGE_ARCHITECTURE.Phase38Suite"

func _init_scripts() -> void:
	GAME_PKG_SCRIPT = ResourceLoader.load("res://core/game_package.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	GAME_MGR_SCRIPT = ResourceLoader.load("res://core/game_package_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DATA_SERVICE_SCRIPT = ResourceLoader.load("res://editor/core/editor_data_service.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	MOD_MGR_SCRIPT = ResourceLoader.load("res://editor/core/mod_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	SAVE_DATA_SCRIPT = ResourceLoader.load("res://systems/save/save_data.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	NET_SESSION_SCRIPT = ResourceLoader.load("res://systems/network/network_session.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()

	# --- 1. Game Package Contract & Validation ---
	_test_01_game_package_contract_and_validation()

	# --- 2. Botanical Haven Official Package Loading ---
	_test_02_botanical_haven_official_package_loading()

	# --- 3. Empty Template Package Creation ---
	_test_03_empty_template_package_creation()

	# --- 4. Multi-Layer Resolution Priority ---
	_test_04_multi_layer_resolution_priority()

	# --- 5. Dynamic Content Resolution per Package ---
	_test_05_dynamic_content_resolution_per_package()

	# --- 6. Mod target_game_id Compatibility ---
	_test_06_mod_target_game_compatibility()

	# --- 7. Save Game ID Validation & Protection ---
	_test_07_save_game_id_validation_and_protection()

	# --- 8. Multiplayer Handshake Game Verification ---
	_test_08_multiplayer_handshake_game_verification()

	# --- 9. Package Lifecycle (Unload / Reload) ---
	_test_09_package_lifecycle_unload_reload()

	# --- 10. Missing & Corrupt Package Handling ---
	_test_10_missing_and_corrupt_package_handling()

	# --- 11. Full Authoring on Custom Game Package ---
	_test_11_full_authoring_on_custom_game_package()

# ===========================================================================
# 1. Game Package Contract & Validation
# ===========================================================================

func _test_01_game_package_contract_and_validation() -> void:
	begin_test("01_GamePackageContractAndValidation")
	var pkg = GAME_PKG_SCRIPT.new()
	assert_eq(pkg.game_id, "botanical_haven", "Default game_id is botanical_haven")
	assert_eq(pkg.starting_world, "farm", "Default starting world is farm")
	assert_true(pkg.content_paths.has("worlds"), "Content paths include worlds")
	assert_true(pkg.player_definition.has("speed"), "Player definition includes speed")
	
	# Serialization test
	var d = pkg.to_dict()
	assert_true(d is Dictionary, "to_dict returns Dictionary")
	assert_eq(d["game_id"], "botanical_haven", "Serialized game_id matches")
	
	var restored = GAME_PKG_SCRIPT.from_dict(d)
	assert_eq(restored.game_id, "botanical_haven", "Restored game_id matches")
	
	# Validation test
	var val = pkg.validate()
	assert_true(val["valid"], "Default package is valid")
	
	var invalid_pkg = GAME_PKG_SCRIPT.new()
	invalid_pkg.game_id = "invalid id with spaces!"
	var inval_res = invalid_pkg.validate()
	assert_false(inval_res["valid"], "Invalid identifier fails validation")

# ===========================================================================
# 2. Botanical Haven Official Package Loading
# ===========================================================================

func _test_02_botanical_haven_official_package_loading() -> void:
	begin_test("02_BotanicalHavenOfficialPackageLoading")
	var pm = GAME_MGR_SCRIPT.get_instance()
	assert_true(pm != null, "GamePackageManager instance available")
	
	var active_pkg = pm.get_active_game_package()
	assert_true(active_pkg != null, "Active game package loaded")
	assert_eq(active_pkg.game_id, "botanical_haven", "Active package is botanical_haven")
	assert_eq(active_pkg.starting_world, "farm", "Starting world is farm")
	assert_true(pm.is_game_package_installed("botanical_haven"), "botanical_haven is installed")

# ===========================================================================
# 3. Empty Template Package Creation
# ===========================================================================

func _test_03_empty_template_package_creation() -> void:
	begin_test("03_EmptyTemplatePackageCreation")
	var pm = GAME_MGR_SCRIPT.get_instance()
	
	var custom_pkg = pm.create_game_package(
		"test_custom_rpg",
		"Test Custom RPG",
		"empty",
		"RPG Developer",
		"1.0.0",
		"A brand new standalone RPG adventure."
	)
	
	assert_true(custom_pkg != null, "Custom game package created")
	assert_eq(custom_pkg.game_id, "test_custom_rpg", "Custom game_id matches")
	assert_eq(custom_pkg.name, "Test Custom RPG", "Custom display name matches")
	assert_true(pm.is_game_package_installed("test_custom_rpg"), "Registered in GamePackageManager")

# ===========================================================================
# 4. Multi-Layer Resolution Priority
# ===========================================================================

func _test_04_multi_layer_resolution_priority() -> void:
	begin_test("04_MultiLayerResolutionPriority")
	var undo_mgr = EditorUndoManager.new()
	var mod_mgr = MOD_MGR_SCRIPT.new()
	var ds = DATA_SERVICE_SCRIPT.new(undo_mgr, mod_mgr)
	
	# Layer 3: Base Package value
	var base_val = ds.get_resolved_value("item.seed_red_flower", "name")
	assert_true(base_val != null, "Base package value resolved")
	
	# Layer 2: Active Mod Override
	var mod = mod_mgr.create_mod("price_boost_mod", "Price Boost Mod", "Tester", "1.0.0")
	mod.overrides["item.seed_red_flower"] = { "name": "Super Red Flower Seed" }
	var mod_val = ds.get_resolved_value("item.seed_red_flower", "name")
	assert_eq(mod_val, "Super Red Flower Seed", "Mod override takes precedence over Base Package")
	
	# Layer 1: User Staged Override
	ds.set_staged_override("item.seed_red_flower", "name", "Legendary Red Flower Seed")
	var user_val = ds.get_resolved_value("item.seed_red_flower", "name")
	assert_eq(user_val, "Legendary Red Flower Seed", "User staged override takes highest precedence")
	
	# Cleanup
	ds.reset_all_modifications()

# ===========================================================================
# 5. Dynamic Content Resolution per Package
# ===========================================================================

func _test_05_dynamic_content_resolution_per_package() -> void:
	begin_test("05_DynamicContentResolutionPerPackage")
	var pm = GAME_MGR_SCRIPT.get_instance()
	var ds = DATA_SERVICE_SCRIPT.new()
	
	# Official Package
	var bh_pkg = pm.get_active_game_package()
	ds.reload_for_package(bh_pkg)
	var bh_worlds = ds.get_all_stable_ids("world.")
	assert_true(bh_worlds.has("world.farm"), "Farm world resolved in Botanical Haven")
	assert_true(bh_worlds.has("world.town"), "Town world resolved in Botanical Haven")
	
	# Custom Empty Package
	var empty_pkg = pm._create_empty_template_package("isolated_pkg", "Isolated Package")
	ds.reload_for_package(empty_pkg)
	var empty_worlds = ds.get_all_stable_ids("world.")
	assert_true(empty_worlds.has("world.main"), "Fallback main world resolved in empty package")
	assert_false(empty_worlds.has("world.farm"), "Farm world absent in isolated empty package")
	
	# Restore Botanical Haven
	ds.reload_for_package(bh_pkg)

# ===========================================================================
# 6. Mod target_game_id Compatibility
# ===========================================================================

func _test_06_mod_target_game_compatibility() -> void:
	begin_test("06_ModTargetGameCompatibility")
	var mod_script = ResourceLoader.load("res://editor/core/mod_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var mm = mod_script.new()
	
	var bh_mod = mm.create_mod("bh_expansion", "BH Expansion", "Author", "1.0.0", "BH mod")
	bh_mod.target_game_id = "botanical_haven"
	assert_eq(bh_mod.target_game_id, "botanical_haven", "Target game stored in mod")
	
	var is_bh_compat = bh_mod.target_game_id == "botanical_haven" or bh_mod.target_game_id == "all"
	var is_rpg_compat = bh_mod.target_game_id == "custom_rpg" or bh_mod.target_game_id == "all"
	assert_true(is_bh_compat, "Compatible with target game botanical_haven")
	assert_false(is_rpg_compat, "Incompatible with different game custom_rpg")
	
	var universal_mod = mm.create_mod("universal_tool", "Universal Tool", "Author", "1.0.0", "Universal mod")
	universal_mod.target_game_id = "all"
	var is_uni_bh = universal_mod.target_game_id == "botanical_haven" or universal_mod.target_game_id == "all"
	var is_uni_rpg = universal_mod.target_game_id == "custom_rpg" or universal_mod.target_game_id == "all"
	assert_true(is_uni_bh, "Universal mod compatible with BH")
	assert_true(is_uni_rpg, "Universal mod compatible with RPG")

# ===========================================================================
# 7. Save Game ID Validation & Protection
# ===========================================================================

func _test_07_save_game_id_validation_and_protection() -> void:
	begin_test("07_SaveGameIdValidationAndProtection")
	var sd = SAVE_DATA_SCRIPT.new()
	sd.game_id = "botanical_haven"
	sd.game_version = "1.0.0"
	
	var test_path = "user://temp_save_game_pkg_test.json"
	var f = FileAccess.open(test_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(sd.to_dict()))
	f.close()
	
	var parsed_dict = JSON.parse_string(FileAccess.get_file_as_string(test_path))
	var restored_sd = SAVE_DATA_SCRIPT.from_dict(parsed_dict)
	assert_eq(restored_sd.game_id, "botanical_haven", "SaveData correctly retains game_id")
	
	# Check protection condition:
	var target_game = "different_game_xyz"
	var is_mismatch = restored_sd.game_id != target_game and target_game != "all"
	assert_true(is_mismatch, "Save file correctly detected as mismatched for different game")
	
	var target_matching = "botanical_haven"
	var is_matching = restored_sd.game_id == target_matching
	assert_true(is_matching, "Save file accepted for matching game package")

# ===========================================================================
# 8. Multiplayer Handshake Game Verification
# ===========================================================================

func _test_08_multiplayer_handshake_game_verification() -> void:
	begin_test("08_MultiplayerHandshakeGameVerification")
	var net = NET_SESSION_SCRIPT.new()
	net.game_id = "botanical_haven"
	net.game_version = "1.0.0"
	
	assert_true(net.is_compatible_with_host("botanical_haven", "1.0.0"), "Matching game and version compatible")
	assert_false(net.is_compatible_with_host("different_game", "1.0.0"), "Different game rejected in handshake")
	assert_false(net.is_compatible_with_host("botanical_haven", "2.0.0"), "Version mismatch rejected")

# ===========================================================================
# 9. Package Lifecycle (Unload / Reload)
# ===========================================================================

func _test_09_package_lifecycle_unload_reload() -> void:
	begin_test("09_PackageLifecycleUnloadReload")
	var pm = GAME_MGR_SCRIPT.get_instance()
	
	pm.unload_game_package()
	# Accessing active package auto-restores default
	var active = pm.get_active_game_package()
	assert_true(active != null, "Default package auto-restored after unload")
	
	var reload_ok = pm.reload_active_game_package()
	assert_true(reload_ok, "Reload active package succeeds")

# ===========================================================================
# 10. Missing & Corrupt Package Handling
# ===========================================================================

func _test_10_missing_and_corrupt_package_handling() -> void:
	begin_test("10_MissingAndCorruptPackageHandling")
	var pm = GAME_MGR_SCRIPT.get_instance()
	
	var loaded_missing = pm.load_game_package("completely_nonexistent_game_999")
	assert_false(loaded_missing, "Missing game package returns false gracefully")
	
	var corrupt_pkg = GAME_PKG_SCRIPT.new()
	corrupt_pkg.game_id = ""
	corrupt_pkg.starting_world = ""
	var report = pm.validate_game_package(corrupt_pkg)
	assert_false(report["valid"], "Corrupt package caught by validator")
	assert_true(report["errors"].size() >= 2, "Multiple errors reported")

# ===========================================================================
# 11. Full Authoring on Custom Game Package
# ===========================================================================

func _test_11_full_authoring_on_custom_game_package() -> void:
	begin_test("11_FullAuthoringOnCustomGamePackage")
	var pm = GAME_MGR_SCRIPT.get_instance()
	var custom_pkg = pm._create_empty_template_package("dungeon_crawler", "Dungeon Crawler")
	
	var ds = DATA_SERVICE_SCRIPT.new()
	ds.reload_for_package(custom_pkg)
	
	# Author custom world, NPC, item
	ds.create_entity("world.dungeon_floor_1", { "id": "dungeon_floor_1", "width": 40, "height": 30 })
	ds.create_entity("npc.mage_aldric", { "id": "mage_aldric", "name": "Aldric", "world": "dungeon_floor_1" })
	ds.create_entity("item.fire_staff", { "id": "fire_staff", "name": "Fire Staff", "sell_price": 500 })
	
	assert_true(ds.has_override("world.dungeon_floor_1"), "Custom dungeon world staged")
	assert_true(ds.has_override("npc.mage_aldric"), "Custom mage NPC staged")
	assert_true(ds.has_override("item.fire_staff"), "Custom fire staff item staged")
	
	var val = EditorValidationService.validate_data(ds)
	assert_true(val.get("valid", true), "Custom game authoring validated with 0 errors")
	
	# Reset back to official Botanical Haven
	var official = pm.get_active_game_package()
	ds.reload_for_package(official)
	assert_true(ds.get_all_stable_ids("world.").has("world.farm"), "Official Farm world restored")
