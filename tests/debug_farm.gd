extends SceneTree

func _init():
	print("--- DEBUG FARM ---")
	var farm_scene = ResourceLoader.load("res://scenes/farm.tscn")
	print("Farm scene: ", farm_scene)
	if farm_scene:
		var inst = farm_scene.instantiate()
		root.add_child(inst)
		print("Instantiated: ", inst)
		print("Children of Farm:")
		for child in inst.get_children():
			print("  - ", child.name, " (", child.get_class(), ", script: ", child.get_script(), ")")
		var p = inst.find_child("Player", true, false)
		print("Player: ", p)
		if p:
			print("Player grid_manager: ", p.grid_manager)
		var gm = inst.find_child("GridManager", true, false)
		print("GridManager: ", gm)
	quit()
