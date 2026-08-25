extends SceneTree

func _init() -> void:
	call_deferred("_run_single")

func _run_single() -> void:
	print("STARTING TEST")
	EditorRegistry.register_panel("cutscene", preload("res://editor/ui/panels/cutscene_editor_panel.gd"), "cutscene", "icon", 10)
	print("PANEL REGISTERED")
	
	var script = ResourceLoader.load("res://tests/qa/test_phase_3c_cutscene_editor.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var inst = script.new()
	print("TEST INSTANCE ADDED")
	
	if inst.has_method("run_all"):
		print("CALLING run_all")
		inst.run_all()
	
	var p = 0
	var f = 0
	if inst.has_method("get_pass_count"): p = inst.get_pass_count()
	elif "pass_count" in inst: p = inst.pass_count
	if inst.has_method("get_fail_count"): f = inst.get_fail_count()
	elif "fail_count" in inst: f = inst.fail_count
	
	print("RESULT: %d PASS / %d FAIL" % [p, f])
	quit(0)
