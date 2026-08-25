extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var suites = [
		"res://tests/unit/test_farming_genetics.gd"
	]
	var total_pass = 0
	var total_fail = 0
	for path in suites:
		var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if script:
			var test = script.new()
			if test.has_method("run_tests"):
				test.run_tests()
			elif test.has_method("run_all"):
				test.run_all()
			
			if test.has_method("get_pass_count"):
				var p = test.get_pass_count()
				var f = test.get_fail_count()
				print("[%s] -> %d PASS / %d FAIL" % [test.get_name() if test.has_method("get_name") else path, p, f])
				total_pass += p
				total_fail += f
		else:
			print("ERROR: Could not load test script: %s" % path)
			total_fail += 1

	print("TOTAL: %d PASS / %d FAIL" % [total_pass, total_fail])
	quit(1 if total_fail > 0 else 0)
