@tool
extends SceneTree

func _init() -> void:
	build_all()
	quit()

static func build_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/economy")

	# 1. res://data/economy/base_shop_items.json
	var shop_items = {
		"seeds": [
			# Starter 5 seeds
			{ "id": "seed_red_flower", "plant_id": "red_flower", "name": "Red Flower Seed", "price": 25, "unlock_type": "always", "rarity": "common" },
			{ "id": "seed_blue_flower", "plant_id": "blue_flower", "name": "Blue Flower Seed", "price": 30, "unlock_type": "always", "rarity": "common" },
			{ "id": "seed_yellow_herb", "plant_id": "yellow_herb", "name": "Yellow Herb Seed", "price": 20, "unlock_type": "always", "rarity": "common" },
			{ "id": "seed_green_vine", "plant_id": "green_vine", "name": "Green Vine Seed", "price": 40, "unlock_type": "always", "rarity": "uncommon" },
			{ "id": "seed_white_lily", "plant_id": "white_lily", "name": "White Lily Seed", "price": 35, "unlock_type": "always", "rarity": "uncommon" },
			# 15 Hybrids (Unlocked when discovered)
			{ "id": "seed_purple_flower", "plant_id": "purple_flower", "name": "Purple Flower Seed", "price": 60, "unlock_type": "discovery", "rarity": "rare" },
			{ "id": "seed_orange_herb", "plant_id": "orange_herb", "name": "Orange Herb Seed", "price": 45, "unlock_type": "discovery", "rarity": "uncommon" },
			{ "id": "seed_green_herb", "plant_id": "green_herb", "name": "Green Herb Seed", "price": 45, "unlock_type": "discovery", "rarity": "uncommon" },
			{ "id": "seed_golden_lily", "plant_id": "golden_lily", "name": "Golden Lily Seed", "price": 80, "unlock_type": "discovery", "rarity": "rare" },
			{ "id": "seed_crimson_vine", "plant_id": "crimson_vine", "name": "Crimson Vine Seed", "price": 75, "unlock_type": "discovery", "rarity": "rare" },
			{ "id": "seed_frost_vine", "plant_id": "frost_vine", "name": "Frost Vine Seed", "price": 75, "unlock_type": "discovery", "rarity": "rare" },
			{ "id": "seed_pink_lily", "plant_id": "pink_lily", "name": "Pink Lily Seed", "price": 70, "unlock_type": "discovery", "rarity": "rare" },
			{ "id": "seed_sapphire_lily", "plant_id": "sapphire_lily", "name": "Sapphire Lily Seed", "price": 85, "unlock_type": "discovery", "rarity": "epic" },
			{ "id": "seed_sun_vine", "plant_id": "sun_vine", "name": "Sun Vine Seed", "price": 70, "unlock_type": "discovery", "rarity": "rare" },
			{ "id": "seed_moon_vine", "plant_id": "moon_vine", "name": "Moon Vine Seed", "price": 85, "unlock_type": "discovery", "rarity": "epic" },
			{ "id": "seed_deep_crimson_bloom", "plant_id": "deep_crimson_bloom", "name": "Deep Crimson Bloom Seed", "price": 125, "unlock_type": "discovery", "rarity": "epic" },
			{ "id": "seed_azure_lotus", "plant_id": "azure_lotus", "name": "Azure Lotus Seed", "price": 135, "unlock_type": "discovery", "rarity": "epic" },
			{ "id": "seed_radiant_essence_herb", "plant_id": "radiant_essence_herb", "name": "Radiant Essence Herb Seed", "price": 115, "unlock_type": "discovery", "rarity": "epic" },
			{ "id": "seed_celestial_lily", "plant_id": "celestial_lily", "name": "Celestial Lily Seed", "price": 250, "unlock_type": "discovery", "rarity": "legendary" },
			{ "id": "seed_ancient_evergreen_tendril", "plant_id": "ancient_evergreen_tendril", "name": "Ancient Evergreen Tendril Seed", "price": 150, "unlock_type": "discovery", "rarity": "legendary" }
		],
		"supplies": [
			{
				"id": "fertilizer_growth",
				"name": "Botanical Fertilizer",
				"description": "Rich compost that enriches farm soil.",
				"price": 30,
				"icon": "fertilizer",
				"unlock_type": "always"
			},
			{
				"id": "herbal_tonic",
				"name": "Vitality Tonic",
				"description": "Herbal infusion that invigoratingly refreshes crops.",
				"price": 45,
				"icon": "tonic",
				"unlock_type": "always"
			}
		]
	}
	var f1 = FileAccess.open("res://data/economy/base_shop_items.json", FileAccess.WRITE)
	if f1:
		f1.store_string(JSON.stringify(shop_items, "  "))
		f1.close()

	# 2. res://data/economy/base_upgrades.json
	var upgrades_data = {
		"upgrades": [
			{
				"id": "better_tools",
				"name": "Master Tools",
				"description": "Refined bronze trowel and watering can. Improves farming efficiency and soil hydration.",
				"price": 150,
				"icon": "better_tools",
				"category": "farming",
				"unlock_type": "always"
			},
			{
				"id": "expanded_satchel",
				"name": "Expanded Satchel",
				"description": "Sturdy woven herbalist bag. Expands inventory carrying capacity.",
				"price": 200,
				"icon": "expanded_satchel",
				"category": "inventory",
				"unlock_type": "always"
			},
			{
				"id": "botanists_notebook",
				"name": "Botanist's Notebook",
				"description": "Detailed botanical research ledger. Grants +10% bonus gold when selling rare and hybrid flora.",
				"price": 300,
				"icon": "botanists_notebook",
				"category": "progression",
				"unlock_type": "always"
			}
		]
	}
	var f2 = FileAccess.open("res://data/economy/base_upgrades.json", FileAccess.WRITE)
	if f2:
		f2.store_string(JSON.stringify(upgrades_data, "  "))
		f2.close()

	# 3. res://data/economy/base_prices.json
	var prices_data = {
		"rarity_multipliers": {
			"common": 1.0,
			"uncommon": 1.5,
			"rare": 2.5,
			"epic": 4.0,
			"legendary": 6.0
		},
		"starting_gold": 100,
		"default_sell_ratio": 0.5
	}
	var f3 = FileAccess.open("res://data/economy/base_prices.json", FileAccess.WRITE)
	if f3:
		f3.store_string(JSON.stringify(prices_data, "  "))
		f3.close()

	# 4. res://data/economy/schema.json
	var schema_data = {
		"$schema": "http://json-schema.org/draft-07/schema#",
		"title": "EconomyConfig",
		"type": "object",
		"required": ["seeds", "supplies"],
		"properties": {
			"seeds": { "type": "array" },
			"supplies": { "type": "array" }
		}
	}
	var f4 = FileAccess.open("res://data/economy/schema.json", FileAccess.WRITE)
	if f4:
		f4.store_string(JSON.stringify(schema_data, "  "))
		f4.close()

	print("[EconomyDataBuilder] Successfully generated economy JSON files!")
