extends SceneTree

const AUTOLOADS: Array = [
	["EventBus", "res://core/event_bus.gd"],
	["GameLogger", "res://core/logger.gd"],
	["PlayerRegistry", "res://systems/player/player_registry.gd"],
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
	["ProgressionManager", "res://systems/progression/progression_manager.gd"]
]

func _init() -> void:
	print("--- TEST SHOP BUY REPRO START ---")
	for item in AUTOLOADS:
		var node_name: String = item[0]
		var script_path: String = item[1]
		if not root.has_node(node_name):
			var sc = load(script_path)
			if sc:
				var inst = sc.new()
				inst.name = node_name
				root.add_child(inst)
	
	var farm_scene = load("res://scenes/farm.tscn")
	if not farm_scene:
		print("ERROR: Failed to load farm scene")
		quit(1)
		return
		
	var farm = farm_scene.instantiate()
	root.add_child(farm)
	print("Farm scene added to root")
	
	var shop_ui = farm.find_child("ShopUI", true, false)
	if not shop_ui:
		print("ERROR: ShopUI not found in farm")
		quit(1)
		return
		
	print("ShopUI found. Opening shop...")
	shop_ui.open_shop()
	print("ShopUI opened. Current tab: ", shop_ui.current_tab)
	
	print("Attempting to buy seed_red_flower...")
	shop_ui._on_buy_item("seed_red_flower", "Red Flower Seed", 25)
	print("Purchase completed successfully!")
	
	print("Attempting to buy supplies...")
	shop_ui._on_buy_item("fertilizer_growth", "Growth Fertilizer", 30)
	print("Supplies purchase completed successfully!")
	
	print("--- TEST COMPLETED WITH SUCCESS ---")
	quit(0)
