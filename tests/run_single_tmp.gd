extends SceneTree

func _init() -> void:
	call_deferred("_run_single")

func _run_single() -> void:
	EditorRegistry.register_panel("studio", preload("res://editor/ui/panels/game_studio_panel.gd"), "ui.editor.cat_studio", "icon_studio", 5)
	EditorRegistry.register_panel("world", preload("res://editor/ui/panels/world_editor_panel.gd"), "ui.editor.cat_world", "icon_world", 10)
	EditorRegistry.register_panel("npc", preload("res://editor/ui/panels/npc_editor_panel.gd"), "ui.editor.cat_npc", "icon_npc", 20)
	EditorRegistry.register_panel("dialogue", preload("res://editor/ui/panels/dialogue_editor_panel.gd"), "ui.editor.cat_dialogue", "icon_dialogue", 30)
	EditorRegistry.register_panel("quest", preload("res://editor/ui/panels/quest_editor_panel.gd"), "ui.editor.cat_quest", "icon_quest", 40)
	EditorRegistry.register_panel("item", preload("res://editor/ui/panels/item_editor_panel.gd"), "ui.editor.cat_item", "icon_item", 50)
	EditorRegistry.register_panel("assets", preload("res://editor/ui/panels/asset_editor_panel.gd"), "ui.editor.cat_assets", "icon_asset", 55)
	EditorRegistry.register_panel("mods", preload("res://editor/ui/panels/mod_manager_panel.gd"), "ui.editor.cat_mods", "icon_mods", 60)
	EditorRegistry.register_panel("rules", preload("res://editor/ui/panels/gameplay_rules_editor_panel.gd"), "ui.editor.cat_rules", "icon_rules", 65)

	var path = "res://tests/unit/test_tool_system.gd"
	var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if not script:
		print("LOAD_FAIL: " + path)
		quit(1)
		return
	
	var inst = script.new()
	if not inst:
		print("INSTANTIATE_FAIL: " + path)
		quit(1)
		return
	
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

	print("RESULT: %s | %d PASS | %d FAIL" % [tname, p, f])
	quit(1 if f > 0 else 0)
