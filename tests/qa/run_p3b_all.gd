extends SceneTree

func _init() -> void:
	call_deferred("_run_it")

func _run_it() -> void:
	var total_pass = 0
	var total_fail = 0
	var paths = [
		"res://tests/unit/test_genetics_data.gd",
		"res://tests/unit/test_genetics_engine.gd",
		"res://tests/qa/test_phase_3b_genetics_editor.gd"
	]
	
	for p in paths:
		var sc = load(p)
		if sc:
			var inst = sc.new()
			if inst.has_method("run_all"):
				inst.run_all()
			elif inst.has_method("run_tests"):
				inst.run_tests()
			
			var p_count = 0
			var f_count = 0
			if inst.has_method("get_pass_count"): p_count = inst.get_pass_count()
			elif "pass_count" in inst: p_count = inst.pass_count
			
			if inst.has_method("get_fail_count"): f_count = inst.get_fail_count()
			elif "fail_count" in inst: f_count = inst.fail_count
			
			print(p, " -> PASS: ", p_count, " FAIL: ", f_count)
			total_pass += p_count
			total_fail += f_count
	
	print("TOTAL PASS: ", total_pass)
	print("TOTAL FAIL: ", total_fail)
	quit(0 if total_fail == 0 else 1)
