extends SceneTree

const AUTOLOADS: Array = [
	["EventBus", "res://core/event_bus.gd"],
	["GameLogger", "res://core/logger.gd"],
	["PlayerStateManager", "res://systems/player/player_state_manager.gd"],
	["PlantManager", "res://systems/plants/plant_manager.gd"],
	["InventoryManager", "res://systems/inventory/inventory_manager.gd"],
	["CombinationManager", "res://systems/combination/combination_manager.gd"],
	["TimeManager", "res://systems/time/time_manager.gd"],
	["SaveManager", "res://systems/save/save_manager.gd"],
	["JournalManager", "res://systems/journal/journal_manager.gd"],
	["AudioManager", "res://core/audio_manager.gd"],
	["EconomyManager", "res://systems/economy/economy_manager.gd"],
	["QuestManager", "res://systems/quest/quest_manager.gd"],
	["DialogueManager", "res://systems/dialogue/dialogue_manager.gd"],
	["GreenhouseManager", "res://systems/greenhouse/greenhouse_manager.gd"],
	["SeasonManager", "res://systems/seasons/season_manager.gd"],
	["WeatherManager", "res://systems/weather/weather_manager.gd"],
	["WorldLoader", "res://systems/world/world_loader.gd"],
	["WorldManager", "res://systems/world/world_manager.gd"],
	["NPCManager", "res://systems/npc/npc_manager.gd"],
	["ShopManager", "res://systems/shop/shop_manager.gd"],
	["LocalStateManager", "res://systems/local/local_state_manager.gd"],
	["LocalizationManager", "res://systems/localization/localization_manager.gd"],
	["SettingsManager", "res://systems/settings/settings_manager.gd"],
	["ProgressionManager", "res://systems/progression/progression_manager.gd"],
	["NetworkManager", "res://systems/network/network_manager.gd"],
	["NetworkGameplay", "res://systems/network/network_gameplay.gd"],
	["NetworkContainers", "res://systems/network/network_containers.gd"],
	["NetworkShop", "res://systems/network/network_shop.gd"],
	["NetworkSynthesis", "res://systems/network/network_synthesis.gd"],
	["NetworkNPC", "res://systems/network/network_npc.gd"],
	["NetworkQuests", "res://systems/network/network_quests.gd"]
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
	print("[RunTests] Starting Botanical Haven Test Suite...")
	_ensure_autoloads()
	
	# Instantiate main scene into tree if needed
	var main_scene = load("res://scenes/main.tscn")
	var main_inst = null
	if main_scene and root and not root.has_node("Main"):
		main_inst = main_scene.instantiate()
		root.add_child(main_inst)
		if main_inst.has_method("start_gameplay"):
			main_inst.start_gameplay(1, false)

	var runner_script = load("res://tests/test_runner.gd")
	if not runner_script:
		printerr("[RunTests] Failed to load res://tests/test_runner.gd")
		quit(1)
		return
	var runner = runner_script.new()
	var report = runner.run_all()
	print("\n--- DETAILED FAILURE BREAKDOWN ---")
	for suite in report.get("suites", []):
		if suite.get("fail", 0) > 0:
			print("SUITE FAILED: ", suite.get("suite"), " (", suite.get("pass"), " PASS, ", suite.get("fail"), " FAIL)")
			for r in suite.get("results", []):
				if r.get("status") != "PASS":
					print("  * [", r.get("test"), "] ", r.get("assertion"))
	print("----------------------------------\n")
	print("[RunTests] Final Summary: ", report.get("total_pass", 0), " PASS / ", report.get("total_fail", 0), " FAIL")
	if report.get("all_passed", false):
		print("[RunTests] SUCCESS: All tests passed.")
		quit(0)
	else:
		print("[RunTests] FAILURE: Some tests failed.")
		quit(1)
