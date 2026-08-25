extends SceneTree

func _init() -> void:
	call_deferred("_run_single")

func _run_single() -> void:
	var script = ResourceLoader.load("res://tests/qa/test_phase_3e_editor_final.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var inst = script.new()
	inst.run_all()
	var p = inst.get_pass_count()
	var f = inst.get_fail_count()
	print("RESULT: %d PASS / %d FAIL" % [p, f])
	quit(0)
