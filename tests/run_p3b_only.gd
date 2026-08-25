extends SceneTree

func _init() -> void:
	var main_scene = load("res://scenes/main.tscn")
	if main_scene and root and not root.has_node("Main"):
		var main_inst = main_scene.instantiate()
		root.add_child(main_inst)
		if main_inst.has_method("start_gameplay"):
			main_inst.start_gameplay(1, false)

	var sc = load("res://tests/qa/test_phase_3b_genetics_editor.gd")
	if sc:
		var inst = sc.new()
		inst.run_all()
		print("P3B -> %d PASS / %d FAIL" % [inst.pass_count, inst.fail_count])
		quit(1 if inst.fail_count > 0 else 0)
	else:
		print("Failed to load res://tests/qa/test_phase_3b_genetics_editor.gd")
		quit(1)
