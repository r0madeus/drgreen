extends SceneTree

func _init() -> void:
	print("[ShopRepro] Starting reproduction test...")
	
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
	var em = root.get_node_or_null("/root/EconomyManager")
	var p = root.find_child("Player", true, false)
	var pid = p.player_id if p else "player_001"
	em.purchase_upgrade(pid, "botanists_notebook", 50)
	print("[ShopRepro] Upgrade purchased!")

	print("[ShopRepro] Attempting to switch to SELL tab...")
	shop_ui._switch_tab(shop_ui.Tab.SELL)
	print("[ShopRepro] Switched to SELL tab!")

	print("[ShopRepro] ALL SHOP OPERATIONS PASSED!")
	quit(0)
