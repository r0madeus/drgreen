extends SceneTree
func _init() -> void:
	call_deferred("_run_single")
func _run_single() -> void:
	var script = ResourceLoader.load("res://tests/qa/test_phase_3a_editor_architecture.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var inst = script.new()
	if inst.has_method("run_all"):
		inst.run_all()
		var p = inst.get_pass_count() if inst.has_method("get_pass_count") else 0
		var f = inst.get_fail_count() if inst.has_method("get_fail_count") else 0
		print("RESULT: " + str(p) + " PASS / " + str(f) + " FAIL")
	quit(0)
