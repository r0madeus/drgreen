extends SceneTree

func _init() -> void:
	call_deferred("_run_single")

func _run_single() -> void:
	print("STARTING TEST")
	
	var script = ResourceLoader.load("res://tests/qa/test_phase_3d_audio_editor.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var inst = script.new()
	
	if inst.has_method("run_all"):
		inst.run_all()
	
	var p = 0
	var f = 0
	if inst.has_method("get_pass_count"): p = inst.get_pass_count()
	if inst.has_method("get_fail_count"): f = inst.get_fail_count()
	
	print("RESULT: %d PASS / %d FAIL" % [p, f])
	quit(0)
