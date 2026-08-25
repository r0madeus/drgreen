extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var node = load("res://tests/qa/playtest_4b_simulation.gd").new()
	root.add_child(node)
	node.run_simulation()
