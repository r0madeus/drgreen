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
	print("[ShopRepro] Starting reproduction test...")
	_ensure_autoloads()
	
	var main_scene = load("res://scenes/main.tscn")
	var main_inst = main_scene.instantiate()
	root.add_child(main_inst)
	main_inst.start_gameplay(1, true)
	print("[ShopRepro] Gameplay started.")
	
	var shop_ui = root.find_child("ShopUI", true, false)
	if not shop_ui:
		print("[ShopRepro] ShopUI NOT FOUND!")
		quit(1)
		return
		
	print("[ShopRepro] ShopUI found. Opening shop...")
	shop_ui.open_shop()
	
	print("[ShopRepro] Attempting to buy seed_red_flower...")
	shop_ui._on_buy_item("seed_red_flower", "Red Flower Seed", 25)
	print("[ShopRepro] Bought seed_red_flower successfully!")
	
	print("[ShopRepro] Attempting to switch to SUPPLIES tab...")
	shop_ui._switch_tab(shop_ui.Tab.SUPPLIES)
	print("[ShopRepro] Attempting to buy fertilizer_growth...")
	shop_ui._on_buy_item("fertilizer_growth", "Growth Fertilizer", 30)
	print("[ShopRepro] Bought supplies successfully!")

	print("[ShopRepro] Attempting to switch to UPGRADES tab...")
	shop_ui._switch_tab(shop_ui.Tab.UPGRADES)
	print("[ShopRepro] Attempting to buy upgrade...")
	var em = root.get_node_or_null("EconomyManager")
	var p = root.find_child("Player", true, false)
	var pid = p.player_id if p else "player_001"
	em.purchase_upgrade(pid, "botanists_notebook", 50)
	print("[ShopRepro] Upgrade purchased!")

	print("[ShopRepro] Attempting to switch to SELL tab...")
	shop_ui._switch_tab(shop_ui.Tab.SELL)
	print("[ShopRepro] Switched to SELL tab!")

	print("[ShopRepro] ALL SHOP OPERATIONS PASSED!")
	quit(0)
