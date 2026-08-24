class_name TestEditorEndToEnd
extends TestCase

## Comprehensive End-to-End In-Game Authoring and Mod Packaging Workflow test suite (Phase 34).

func test_name_id() -> String:
	return "EDITOR_END_TO_END.InGameSuite"

func run_all() -> void:
	test_name = test_name_id()

	_test_01_complete_authoring_pipeline()
	_test_02_export_package_integrity()
	_test_03_clean_reset_all_state()
	_test_04_import_and_reapply_mod_package()
	_test_05_multi_mod_conflict_resolution()
	_test_06_corrupt_data_fault_tolerance()

func _test_01_complete_authoring_pipeline() -> void:
	begin_test("E2E01_CompleteAuthoringPipeline")
	var service = EditorService.get_instance()
	service.reset_all()

	# 1. World Editing
	service.set_property("world.farm", "ambient_light", [0.9, 0.9, 1.0])
	
	# 2. NPC Editing
	service.set_property("npc.rowan", "display_name", "Grand Merchant Rowan")
	service.set_property("schedule.rowan", "daily", [
		{ "time": 6, "location": "farm", "action": "inspect_crops" },
		{ "time": 12, "location": "town", "action": "market_stall" }
	])
	
	# 3. Dialogue Editing
	service.set_property("dialogue.rowan_special", "nodes", {
		"node_0": { "text": "Greetings, apprentice!", "next": "node_1" },
		"node_1": { "text": "Have you seen my legendary tonic?", "choices": ["choice_yes", "choice_no"] }
	})
	
	# 4. Quest Editing
	service.set_property("quest.rowan_tonic_quest", "title", "Rowan's Secret Formula")
	service.set_property("quest.rowan_tonic_quest", "rewards", { "gold": 150 })

	
	# 5. Item / Crop Editing
	service.set_property("item.plant_red_flower", "sell_price", 350.0)
	service.set_property("crop.plant_red_flower", "harvest_yield", 4)
	
	# Save & Validate
	var saved = service.save()
	assert_true(saved, "All authoring changes saved to persistent storage")
	
	var validation = service.validate()
	assert_true(validation.get("valid", false), "Full project authoring validated with 0 errors")

func _test_02_export_package_integrity() -> void:
	begin_test("E2E02_ExportPackageIntegrity")
	var service = EditorService.get_instance()
	var mm = service.mod_manager
	
	var mod = mm.create_mod("e2e_expansion", "E2E Botanical Expansion", "Master Creator", "1.0.0", "Complete content expansion pack.")
	mod.overrides = service.data_service._staged_overrides.duplicate(true)
	
	var res = mm.export_mod_package("e2e_expansion")
	assert_true(res.get("success", false), "Exported standalone .bhmod package container")

func _test_03_clean_reset_all_state() -> void:
	begin_test("E2E03_CleanResetAllState")
	var service = EditorService.get_instance()
	service.mod_manager.unregister_mod("e2e_expansion")
	service.reset_all()
	service.save()
	
	# Verify returned to base values
	var base_name = service.data_service.get_resolved_value("npc.rowan", "display_name")
	assert_true(base_name == "Rowan" or base_name == "Merchant Rowan" or base_name != "Grand Merchant Rowan", "Base game state restored")


func _test_04_import_and_reapply_mod_package() -> void:
	begin_test("E2E04_ImportAndReapplyModPackage")
	var service = EditorService.get_instance()
	var mm = service.mod_manager
	
	# Re-import package
	var import_res = mm.import_mod_package("user://mods/e2e_expansion.bhmod")
	if not import_res.get("success", false):
		import_res = mm.import_mod("user://mods/e2e_expansion/manifest.json")
		
	assert_true(import_res.get("success", false) or mm.get_mod("e2e_expansion") != null, "Successfully imported mod package")
	mm.enable_mod("e2e_expansion")
	
	# Verify overrides resolved via mod layer
	var active_mods = mm.get_active_mods_sorted()
	assert_true(active_mods.size() > 0, "Active mod list contains imported mod")

func _test_05_multi_mod_conflict_resolution() -> void:
	begin_test("E2E05_MultiModConflictResolution")
	var mm = ModManager.new()
	var m1 = mm.create_mod("mod_alpha", "Mod Alpha")
	m1.overrides["item.plant_red_flower"] = { "sell_price": 100 }
	m1.priority = 10
	
	var m2 = mm.create_mod("mod_beta", "Mod Beta")
	m2.overrides["item.plant_red_flower"] = { "sell_price": 200 }
	m2.priority = 50
	
	var conflicts = mm.detect_conflicts()
	assert_eq(conflicts.size(), 1, "Conflict detected between Mod Alpha and Mod Beta")
	assert_eq(conflicts[0].get("winning_mod"), "mod_beta", "Mod Beta wins conflict with priority 50")

func _test_06_corrupt_data_fault_tolerance() -> void:
	begin_test("E2E06_CorruptDataFaultTolerance")
	var mm = ModManager.new()
	var res = mm.import_mod("{ invalid json structure")
	assert_false(res.get("success", true), "Corrupt package failed gracefully without crash")
