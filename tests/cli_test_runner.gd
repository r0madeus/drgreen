extends SceneTree

## Headless CLI Test Runner for Botanical Haven integration suites.

func _init() -> void:
	print("=============================================================================")
	print("BOTANICAL HAVEN — HEADLESS CLI TEST RUNNER")
	print("=============================================================================")
	
	EditorRegistry.register_panel("studio", preload("res://editor/ui/panels/game_studio_panel.gd"), "ui.editor.cat_studio", "icon_studio", 5)
	EditorRegistry.register_panel("world", preload("res://editor/ui/panels/world_editor_panel.gd"), "ui.editor.cat_world", "icon_world", 10)
	EditorRegistry.register_panel("npc", preload("res://editor/ui/panels/npc_editor_panel.gd"), "ui.editor.cat_npc", "icon_npc", 20)
	EditorRegistry.register_panel("dialogue", preload("res://editor/ui/panels/dialogue_editor_panel.gd"), "ui.editor.cat_dialogue", "icon_dialogue", 30)
	EditorRegistry.register_panel("quest", preload("res://editor/ui/panels/quest_editor_panel.gd"), "ui.editor.cat_quest", "icon_quest", 40)
	EditorRegistry.register_panel("item", preload("res://editor/ui/panels/item_editor_panel.gd"), "ui.editor.cat_item", "icon_item", 50)
	EditorRegistry.register_panel("assets", preload("res://editor/ui/panels/asset_editor_panel.gd"), "ui.editor.cat_assets", "icon_asset", 55)
	EditorRegistry.register_panel("mods", preload("res://editor/ui/panels/mod_manager_panel.gd"), "ui.editor.cat_mods", "icon_mods", 60)
	EditorRegistry.register_panel("rules", preload("res://editor/ui/panels/gameplay_rules_editor_panel.gd"), "ui.editor.cat_rules", "icon_rules", 65)

	var suites = [
		"res://tests/integration/test_editor_foundation.gd",
		"res://tests/integration/test_world_editor.gd",
		"res://tests/integration/test_npc_editor.gd",
		"res://tests/integration/test_dialogue_editor.gd",
		"res://tests/integration/test_quest_editor.gd",
		"res://tests/integration/test_item_editor.gd",
		"res://tests/integration/test_editor_integration.gd",
		"res://tests/integration/test_editor_qa.gd",
		"res://tests/integration/test_editor_responsive_ui.gd",
		"res://tests/integration/test_editor_end_to_end.gd",
		"res://tests/integration/test_asset_editor.gd",
		"res://tests/integration/test_complete_authoring_workflow.gd",
		"res://tests/integration/test_editor_ux_hardening.gd",
		"res://tests/integration/test_game_package_architecture.gd",
		"res://tests/integration/test_generic_gameplay_system.gd",
		"res://tests/integration/test_game_creation_pipeline.gd",
		"res://tests/integration/test_generic_components.gd",
		"res://tests/integration/test_custom_game_mechanics.gd",
		"res://tests/integration/test_custom_authoring_system.gd",
		"res://tests/integration/test_engine_hardening_production.gd",
		"res://tests/integration/test_gameplay_simulation_stress.gd",
		"res://tests/integration/test_time_stress.gd",
		"res://tests/integration/test_world_transitions_stress.gd",
		"res://tests/integration/test_random_actions_stress.gd",
		"res://tests/integration/test_save_game_boot_flow.gd",
	]

	var total_pass = 0
	var total_fail = 0

	for path in suites:
		var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script:
			var test = script.new()
			test.run_all()
			print("[%s] -> %d PASS / %d FAIL" % [test.test_name, test.get_pass_count(), test.get_fail_count()])
			total_pass += test.get_pass_count()
			total_fail += test.get_fail_count()
		else:
			print("ERROR: Could not load test script: %s" % path)
			total_fail += 1

	print("-----------------------------------------------------------------------------")
	print("ALL_25_SUITES_TOTAL: %d PASS / %d FAIL" % [total_pass, total_fail])
	print("=============================================================================")
	
	quit(1 if total_fail > 0 else 0)
