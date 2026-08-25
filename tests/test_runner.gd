class_name TestRunner
extends RefCounted

## Central Test Runner for Botanical Haven regression suite.
## Usage (via runtime_eval / MCP):
##   var runner = TestRunner.new()
##   runner.run_all()

const GROUPS := ["UNIT", "SAVE_LOAD", "WORLD", "MOVEMENT", "FARMING", "MULTIPLAYER", "LOCALIZATION", "ASSET", "INTEGRATION"]

var _all_results: Array[Dictionary] = []
var _total_pass: int = 0
var _total_fail: int = 0

func run_all() -> Dictionary:
	_all_results.clear()
	_total_pass = 0
	_total_fail = 0

		# Ensure EditorRegistry has all default panels registered
	EditorRegistry.register_panel("world", preload("res://editor/ui/panels/world_editor_panel.gd"), "ui.editor.cat_world", "icon_world", 10)
	EditorRegistry.register_panel("npc", preload("res://editor/ui/panels/npc_editor_panel.gd"), "ui.editor.cat_npc", "icon_npc", 20)
	EditorRegistry.register_panel("dialogue", preload("res://editor/ui/panels/dialogue_editor_panel.gd"), "ui.editor.cat_dialogue", "icon_dialogue", 30)
	EditorRegistry.register_panel("quest", preload("res://editor/ui/panels/quest_editor_panel.gd"), "ui.editor.cat_quest", "icon_quest", 40)
	EditorRegistry.register_panel("item", preload("res://editor/ui/panels/item_editor_panel.gd"), "ui.editor.cat_item", "icon_item", 50)
	EditorRegistry.register_panel("assets", preload("res://editor/ui/panels/asset_editor_panel.gd"), "ui.editor.cat_assets", "icon_asset", 55)
	EditorRegistry.register_panel("mods", preload("res://editor/ui/panels/mod_manager_panel.gd"), "ui.editor.cat_mods", "icon_mods", 60)
	EditorService.get_instance().reset_all()

	print("\n========================================")
	print("   BOTANICAL HAVEN REGRESSION SUITE")
	print("========================================\n")

	# --- UNIT TESTS ---
	_run_path("res://tests/unit/test_player_state.gd")
	_run_path("res://tests/unit/test_tool_system.gd")
	_run_path("res://tests/unit/test_quest_system.gd")
	_run_path("res://tests/unit/test_localization.gd")
	_run_path("res://tests/unit/test_asset_registry.gd")

	# --- INTEGRATION & REGRESSION TESTS ---
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var main = root.find_child("Main", true, false) if (root and not Engine.is_editor_hint()) else null
	if main and main.has_method("start_gameplay"):
		main.start_gameplay(1, false)

	_run_path("res://tests/integration/test_save_load.gd")
	_run_path("res://tests/integration/test_world_transitions.gd")
	_run_path("res://tests/integration/test_movement_regression.gd")
	_run_path("res://tests/integration/test_farming_chain.gd")
	_run_path("res://tests/integration/test_multiplayer.gd")
	_run_path("res://tests/integration/test_time_system.gd")
	_run_path("res://tests/integration/test_npc_schedule.gd")
	_run_path("res://tests/integration/test_npc_navigation.gd")
	_run_path("res://tests/integration/test_npc_living_world.gd")
	_run_path("res://tests/integration/test_npc_behavior_quality.gd")
	_run_path("res://tests/integration/test_npc_visual_animation.gd")
	_run_path("res://tests/integration/test_npc_social_progression.gd")
	_run_path("res://tests/integration/test_gameplay_balance.gd")
	_run_path("res://tests/integration/test_farming_game_feel.gd")
	_run_path("res://tests/integration/test_art_pipeline.gd")
	_run_path("res://tests/integration/test_editor_foundation.gd")
	_run_path("res://tests/integration/test_main_menu_boot.gd")
	_run_path("res://tests/integration/test_multiplayer_menu.gd")
	_run_path("res://tests/integration/test_world_editor.gd")
	_run_path("res://tests/integration/test_npc_editor.gd")
	_run_path("res://tests/integration/test_dialogue_editor.gd")
	_run_path("res://tests/integration/test_quest_editor.gd")
	_run_path("res://tests/integration/test_item_editor.gd")
	_run_path("res://tests/integration/test_world_editor_input.gd")
	_run_path("res://tests/integration/test_world_editor_ui.gd")
	_run_path("res://tests/integration/test_editor_integration.gd")

	_run_path("res://tests/integration/test_editor_qa.gd")
	_run_path("res://tests/integration/test_editor_responsive_ui.gd")
	_run_path("res://tests/integration/test_editor_end_to_end.gd")
	_run_path("res://tests/integration/test_asset_editor.gd")
	_run_path("res://tests/integration/test_editor_full_regression.gd")
	_run_path("res://tests/integration/test_editor_user_acceptance.gd")
	_run_path("res://tests/unit/test_genetics_data.gd")
	_run_path("res://tests/unit/test_genetics_engine.gd")
	_run_path("res://tests/qa/test_phase_3b_genetics_editor.gd")

	if main and main.has_method("return_to_main_menu"):
		main.return_to_main_menu()

	_print_summary()













	return _get_report()

func _run_path(script_path: String) -> void:
	var script = load(script_path)
	if not script:
		push_error("[TestRunner] Failed to load: " + script_path)
		return
	var suite = script.new()
	if suite and suite.has_method("run_all"):
		suite.run_all()
		var results = suite.get_results()
		var suite_name = suite.test_name if suite.test_name != "" else script_path.get_file().trim_suffix(".gd")

		var pass_count = 0
		var fail_count = 0
		var fail_messages: Array[String] = []

		for r in results:
			if r.get("status") == "PASS":
				pass_count += 1
			else:
				fail_count += 1
				fail_messages.append("  âœ— [%s] %s" % [r.get("test", "?"), r.get("assertion", "?")])

		_total_pass += pass_count
		_total_fail += fail_count

		var status_icon = "âœ…" if fail_count == 0 else "âŒ"
		print("%s %s â€” %d PASS / %d FAIL" % [status_icon, suite_name, pass_count, fail_count])
		for msg in fail_messages:
			print(msg)

		_all_results.append({
			"suite": suite_name,
			"pass": pass_count,
			"fail": fail_count,
			"results": results
		})

func _print_summary() -> void:
		# Ensure EditorRegistry has all default panels registered
	EditorRegistry.register_panel("world", preload("res://editor/ui/panels/world_editor_panel.gd"), "ui.editor.cat_world", "icon_world", 10)
	EditorRegistry.register_panel("npc", preload("res://editor/ui/panels/npc_editor_panel.gd"), "ui.editor.cat_npc", "icon_npc", 20)
	EditorRegistry.register_panel("dialogue", preload("res://editor/ui/panels/dialogue_editor_panel.gd"), "ui.editor.cat_dialogue", "icon_dialogue", 30)
	EditorRegistry.register_panel("quest", preload("res://editor/ui/panels/quest_editor_panel.gd"), "ui.editor.cat_quest", "icon_quest", 40)
	EditorRegistry.register_panel("item", preload("res://editor/ui/panels/item_editor_panel.gd"), "ui.editor.cat_item", "icon_item", 50)
	EditorRegistry.register_panel("assets", preload("res://editor/ui/panels/asset_editor_panel.gd"), "ui.editor.cat_assets", "icon_asset", 55)
	EditorRegistry.register_panel("mods", preload("res://editor/ui/panels/mod_manager_panel.gd"), "ui.editor.cat_mods", "icon_mods", 60)

	print("\n========================================")
	print("   FINAL RESULT: %d PASS / %d FAIL" % [_total_pass, _total_fail])
	if _total_fail == 0:
		print("   âœ… ALL TESTS PASSED")
	else:
		print("   âŒ FAILURES DETECTED â€” SEE ABOVE")
	print("========================================\n")

func _get_report() -> Dictionary:
	return {
		"total_pass": _total_pass,
		"total_fail": _total_fail,
		"all_passed": _total_fail == 0,
		"suites": _all_results
	}

func run_group(group_name: String) -> Dictionary:
	match group_name.to_upper():
		"UNIT":
			_run_path("res://tests/unit/test_player_state.gd")
			_run_path("res://tests/unit/test_tool_system.gd")
			_run_path("res://tests/unit/test_quest_system.gd")
			_run_path("res://tests/unit/test_localization.gd")
			_run_path("res://tests/unit/test_asset_registry.gd")
		"SAVE_LOAD":
			_run_path("res://tests/integration/test_save_load.gd")
		"WORLD":
			_run_path("res://tests/integration/test_world_transitions.gd")
		"MOVEMENT":
			_run_path("res://tests/integration/test_movement_regression.gd")
		"FARMING":
			_run_path("res://tests/integration/test_farming_chain.gd")
		"MULTIPLAYER":
			_run_path("res://tests/integration/test_multiplayer.gd")
		_:
			push_warning("[TestRunner] Unknown group: %s" % group_name)
	return _get_report()

