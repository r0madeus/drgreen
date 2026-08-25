extends SceneTree

func _init() -> void:
	call_deferred("_run_all")

func _run_all() -> void:
	EditorRegistry.register_panel("studio", preload("res://editor/ui/panels/game_studio_panel.gd"), "ui.editor.cat_studio", "icon_studio", 5)
	EditorRegistry.register_panel("world", preload("res://editor/ui/panels/world_editor_panel.gd"), "ui.editor.cat_world", "icon_world", 10)
	EditorRegistry.register_panel("npc", preload("res://editor/ui/panels/npc_editor_panel.gd"), "ui.editor.cat_npc", "icon_npc", 20)
	EditorRegistry.register_panel("dialogue", preload("res://editor/ui/panels/dialogue_editor_panel.gd"), "ui.editor.cat_dialogue", "icon_dialogue", 30)
	EditorRegistry.register_panel("quest", preload("res://editor/ui/panels/quest_editor_panel.gd"), "ui.editor.cat_quest", "icon_quest", 40)
	EditorRegistry.register_panel("item", preload("res://editor/ui/panels/item_editor_panel.gd"), "ui.editor.cat_item", "icon_item", 50)
	EditorRegistry.register_panel("assets", preload("res://editor/ui/panels/asset_editor_panel.gd"), "ui.editor.cat_assets", "icon_asset", 55)
	EditorRegistry.register_panel("mods", preload("res://editor/ui/panels/mod_manager_panel.gd"), "ui.editor.cat_mods", "icon_mods", 60)
	EditorRegistry.register_panel("rules", preload("res://editor/ui/panels/gameplay_rules_editor_panel.gd"), "ui.editor.cat_rules", "icon_rules", 65)

	var test_paths = ['res://tests/integration/test_art_pipeline.gd', 'res://tests/integration/test_asset_editor.gd', 'res://tests/integration/test_complete_authoring_workflow.gd', 'res://tests/integration/test_custom_authoring_system.gd', 'res://tests/integration/test_custom_game_mechanics.gd', 'res://tests/integration/test_dialogue_editor.gd', 'res://tests/integration/test_editor_end_to_end.gd', 'res://tests/integration/test_editor_foundation.gd', 'res://tests/integration/test_editor_full_regression.gd', 'res://tests/integration/test_editor_integration.gd', 'res://tests/integration/test_editor_qa.gd', 'res://tests/integration/test_editor_responsive_ui.gd', 'res://tests/integration/test_editor_user_acceptance.gd', 'res://tests/integration/test_editor_ux_hardening.gd', 'res://tests/integration/test_engine_hardening_production.gd', 'res://tests/integration/test_farming_chain.gd', 'res://tests/integration/test_farming_game_feel.gd', 'res://tests/integration/test_game_creation_pipeline.gd', 'res://tests/integration/test_game_package_architecture.gd', 'res://tests/integration/test_gameplay_balance.gd', 'res://tests/integration/test_gameplay_simulation_stress.gd', 'res://tests/integration/test_generic_components.gd', 'res://tests/integration/test_generic_gameplay_system.gd', 'res://tests/integration/test_item_editor.gd', 'res://tests/integration/test_main_menu_boot.gd', 'res://tests/integration/test_movement_regression.gd', 'res://tests/integration/test_multiplayer.gd', 'res://tests/integration/test_multiplayer_menu.gd', 'res://tests/integration/test_npc_behavior_quality.gd', 'res://tests/integration/test_npc_editor.gd', 'res://tests/integration/test_npc_living_world.gd', 'res://tests/integration/test_npc_navigation.gd', 'res://tests/integration/test_npc_schedule.gd', 'res://tests/integration/test_npc_social_progression.gd', 'res://tests/integration/test_npc_visual_animation.gd', 'res://tests/integration/test_quest_editor.gd', 'res://tests/integration/test_quest_isolation.gd', 'res://tests/integration/test_random_actions_stress.gd', 'res://tests/integration/test_save_game_boot_flow.gd', 'res://tests/integration/test_save_load.gd', 'res://tests/integration/test_time_stress.gd', 'res://tests/integration/test_time_system.gd', 'res://tests/integration/test_world_editor.gd', 'res://tests/integration/test_world_editor_input.gd', 'res://tests/integration/test_world_editor_ui.gd', 'res://tests/integration/test_world_transitions.gd', 'res://tests/integration/test_world_transitions_stress.gd', 'res://tests/qa/final_qa_runner.gd', 'res://tests/qa/test_phase_2f_integration.gd', 'res://tests/qa/test_phase_3a_editor_architecture.gd', 'res://tests/qa/test_phase_3b_genetics_editor.gd', 'res://tests/qa/test_runtime_boot.gd', 'res://tests/qa/test_world_editor_real_user.gd', 'res://tests/unit/test_asset_registry.gd', 'res://tests/unit/test_farming_genetics.gd', 'res://tests/unit/test_genetics_data.gd', 'res://tests/unit/test_genetics_engine.gd', 'res://tests/unit/test_localization.gd', 'res://tests/unit/test_network_laboratory_access.gd', 'res://tests/unit/test_player_state.gd', 'res://tests/unit/test_quest_system.gd', 'res://tests/unit/test_tool_system.gd']

	var total_pass = 0
	var total_fail = 0
	var failed_suites = []

	for path in test_paths:
		var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if not script:
			print("FAILED TO LOAD: " + path)
			total_fail += 1
			failed_suites.append({"path": path, "error": "load_failed"})
			continue

		var inst = script.new()
		if not inst:
			print("FAILED TO INSTANTIATE: " + path)
			total_fail += 1
			failed_suites.append({"path": path, "error": "instantiate_failed"})
			continue

		if inst.has_method("run_all"):
			inst.run_all()
		elif inst.has_method("run_tests"):
			inst.run_tests()
		elif inst.has_method("run"):
			inst.run()

		var p = 0
		var f = 0
		if inst.has_method("get_pass_count"): p = inst.get_pass_count()
		elif "pass_count" in inst: p = inst.pass_count

		if inst.has_method("get_fail_count"): f = inst.get_fail_count()
		elif "fail_count" in inst: f = inst.fail_count

		var tname = path
		if inst.has_method("get_name"): tname = inst.get_name()
		elif "test_name" in inst: tname = inst.test_name

		print("[%s] (%s) -> %d PASS / %d FAIL" % [tname, path, p, f])
		total_pass += p
		total_fail += f
		if f > 0:
			failed_suites.append({"path": path, "name": tname, "pass": p, "fail": f})

	print("=============================================================================")
	print("GRAND TOTAL: %d PASS / %d FAIL across %d suites" % [total_pass, total_fail, test_paths.size()])
	print("FAILED SUITES: ", failed_suites)
	print("=============================================================================")
	quit(1 if total_fail > 0 else 0)
