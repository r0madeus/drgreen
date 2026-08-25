extends SceneTree

const AUTOLOADS: Array = [
	["EventBus", "res://core/event_bus.gd"],
	["GameLogger", "res://core/logger.gd"],
	["PlayerRegistry", "res://systems/player/player_registry.gd"],
	["PlantManager", "res://systems/plants/plant_manager.gd"],
	["TraitRegistry", "res://systems/genetics/trait_registry.gd"],
	["InventoryManager", "res://systems/inventory/inventory_manager.gd"],
	["CombinationManager", "res://systems/combination/combination_manager.gd"],
	["TimeManager", "res://systems/time/time_manager.gd"],
	["SaveManager", "res://systems/save/save_manager.gd"],
	["NetworkSynthesis", "res://systems/network/network_synthesis.gd"],
	["WorldManager", "res://systems/world/world_manager.gd"]
]

func _ensure_autoloads() -> void:
	if not root: return
	for item in AUTOLOADS:
		var node_name: String = item[0]
		var script_path: String = item[1]
		if not root.has_node(node_name):
			var sc = load(script_path)
			if sc:
				var inst = sc.new()
				inst.name = node_name
				root.add_child(inst)

func _init() -> void:
	_ensure_autoloads()
	var suites = [
		"res://tests/unit/test_genetics_data.gd",
		"res://tests/unit/test_genetics_engine.gd"
	]
	var total_pass = 0
	var total_fail = 0
	for path in suites:
		var sc = load(path)
		if sc:
			var inst = sc.new()
			if inst.has_method("run_tests"):
				inst.run_tests()
			elif inst.has_method("run_all"):
				inst.run_all()
			print("[%s] -> %d PASS / %d FAIL" % [inst.get_name(), inst.pass_count, inst.fail_count])
			total_pass += inst.pass_count
			total_fail += inst.fail_count
		else:
			print("Failed to load " + path)
			total_fail += 1
	print("TOTAL: %d PASS / %d FAIL" % [total_pass, total_fail])
	quit(1 if total_fail > 0 else 0)
