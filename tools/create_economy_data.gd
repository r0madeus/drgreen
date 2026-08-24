@tool
extends SceneTree

func _init() -> void:
	create_data()
	quit()

static func create_data() -> void:
	# Ensure folders exist
	DirAccess.make_dir_recursive_absolute("res://data/economy")
	DirAccess.make_dir_recursive_absolute("res://data/npcs")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/npc")
	
	# 1. res://data/economy/economy_config.json
	var econ_cfg = {
		"starting_gold": 100,
		"currency_name": "Gold",
		"currency_symbol": "G"
	}
	var f1 = FileAccess.open("res://data/economy/economy_config.json", FileAccess.WRITE)
	if f1:
		f1.store_string(JSON.stringify(econ_cfg, "  "))
		f1.close()
		
	# 2. res://data/npcs/seed_merchant.json
	var merchant_data = {
		"npc_id": "seed_merchant",
		"name": "Rowan",
		"title": "Seed Merchant",
		"greeting": "Welcome to my seed stall! I've got fresh seeds from across the valley.",
		"shop_items": [
			{ "item_id": "seed_red_flower", "price": 25, "stock": -1 },
			{ "item_id": "seed_blue_flower", "price": 30, "stock": -1 },
			{ "item_id": "seed_yellow_herb", "price": 20, "stock": -1 },
			{ "item_id": "seed_green_vine", "price": 40, "stock": -1 },
			{ "item_id": "seed_white_lily", "price": 35, "stock": -1 }
		]
	}
	var f2 = FileAccess.open("res://data/npcs/seed_merchant.json", FileAccess.WRITE)
	if f2:
		f2.store_string(JSON.stringify(merchant_data, "  "))
		f2.close()
		
	print("[EconomyDataCreator] Successfully created economy and NPC shop JSON data!")
