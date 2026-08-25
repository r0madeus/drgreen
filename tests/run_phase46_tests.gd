extends SceneTree

func _init() -> void:
	call_deferred("_run_it")

func _run_it() -> void:
	EditorRegistry.register_panel("studio", preload("res://editor/ui/panels/game_studio_panel.gd"), "ui.editor.cat_studio", "icon_studio", 5)
	EditorRegistry.register_panel("world", preload("res://editor/ui/panels/world_editor_panel.gd"), "ui.editor.cat_world", "icon_world", 10)
	EditorRegistry.register_panel("npc", preload("res://editor/ui/panels/npc_editor_panel.gd"), "ui.editor.cat_npc", "icon_npc", 20)
	EditorRegistry.register_panel("dialogue", preload("res://editor/ui/panels/dialogue_editor_panel.gd"), "ui.editor.cat_dialogue", "icon_dialogue", 30)
	EditorRegistry.register_panel("quest", preload("res://editor/ui/panels/quest_editor_panel.gd"), "ui.editor.cat_quest", "icon_quest", 40)
	EditorRegistry.register_panel("item", preload("res://editor/ui/panels/item_editor_panel.gd"), "ui.editor.cat_item", "icon_item", 50)
	EditorRegistry.register_panel("assets", preload("res://editor/ui/panels/asset_editor_panel.gd"), "ui.editor.cat_assets", "icon_asset", 55)
	EditorRegistry.register_panel("mods", preload("res://editor/ui/panels/mod_manager_panel.gd"), "ui.editor.cat_mods", "icon_mods", 60)
	EditorRegistry.register_panel("rules", preload("res://editor/ui/panels/gameplay_rules_editor_panel.gd"), "ui.editor.cat_rules", "icon_rules", 65)

	var paths = [
		"res://tests/integration/test_editor_full_regression.gd",
		"res://tests/integration/test_editor_user_acceptance.gd"
	]
	
	var total_pass = 0
	var total_fail = 0

	for path in paths:
		var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script:
			var test = script.new()
			test.run_all()
			print("[%s] -> %d PASS / %d FAIL" % [test.test_name, test.get_pass_count(), test.get_fail_count()])
			total_pass += test.get_pass_count()
			total_fail += test.get_fail_count()
		else:
			print("Could not load: " + path)
			total_fail += 1

	print("SUBTOTAL: %d PASS / %d FAIL" % [total_pass, total_fail])
	quit(1 if total_fail > 0 else 0)
