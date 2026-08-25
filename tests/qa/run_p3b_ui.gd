extends SceneTree

func _init() -> void:
	call_deferred("_run_it")

func _run_it() -> void:
	var sc = load("res://tests/qa/test_phase_3b_genetics_editor.gd")
	if sc:
		var inst = sc.new()
		inst.run_all()
		print("P3B UI PASS: ", inst.get_pass_count())
		print("P3B UI FAIL: ", inst.get_fail_count())
		quit(0 if inst.get_fail_count() == 0 else 1)
