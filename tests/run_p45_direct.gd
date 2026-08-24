extends SceneTree

func _init() -> void:
	var script = preload("res://tests/integration/test_save_game_boot_flow.gd")
	var test = script.new()
	test.run_all()
	print("[RESULT] " + str(test.test_name) + " -> " + str(test.get_pass_count()) + " PASS / " + str(test.get_fail_count()) + " FAIL")
	quit(1 if test.get_fail_count() > 0 else 0)
