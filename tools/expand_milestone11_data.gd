@tool
extends SceneTree

func _init() -> void:
	expand_all()
	quit()

static func expand_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/world")
	DirAccess.make_dir_recursive_absolute("res://data/plants")
	DirAccess.make_dir_recursive_absolute("res://data/combinations")
	DirAccess.make_dir_recursive_absolute("res://data/quests")
	DirAccess.make_dir_recursive_absolute("res://data/economy")

	# 1. Expand res://data/plants/base_plants.json
	var plants_path = "res://data/plants/base_plants.json"
	var existing_plants = []
	if FileAccess.file_exists(plants_path):
		var f = FileAccess.open(plants_path, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK:
				existing_plants = json.data.get("plants", [])
			f.close()

	# Check if new plants already exist
	var existing_ids = {}
	for p in existing_plants:
		existing_ids[p["id"]] = true

	var new_plants = [
		# 3 Greenhouse Specials
		{
			"id": "moon_orchid",
			"name": "Moon Orchid",
			"type": "greenhouse_plant",
			"rarity": "rare",
			"growth": { "stages": 4, "days_per_stage": [1, 2, 2], "water_daily": true },
			"harvest": { "yield": [1, 2], "item_id": "moon_orchid" },
			"value": { "base_price": 180 },
			"visual": { "color": "#B8C0FF", "accent_color": "#E7C6FF" },
			"greenhouse_only": true
		},
		{
			"id": "glass_fern",
			"name": "Glass Fern",
			"type": "greenhouse_plant",
			"rarity": "rare",
			"growth": { "stages": 4, "days_per_stage": [1, 2, 2], "water_daily": true },
			"harvest": { "yield": [1, 2], "item_id": "glass_fern" },
			"value": { "base_price": 190 },
			"visual": { "color": "#C8E7FF", "accent_color": "#A0C4FF" },
			"greenhouse_only": true
		},
		{
			"id": "star_moss",
			"name": "Star Moss",
			"type": "greenhouse_plant",
			"rarity": "rare",
			"growth": { "stages": 3, "days_per_stage": [1, 2], "water_daily": true },
			"harvest": { "yield": [2, 3], "item_id": "star_moss" },
			"value": { "base_price": 160 },
			"visual": { "color": "#FDFFB6", "accent_color": "#CAFFBF" },
			"greenhouse_only": true
		},
		# 5 New Hybrids
		{
			"id": "lunar_bloom",
			"name": "Lunar Bloom",
			"type": "plant",
			"rarity": "legendary",
			"growth": { "stages": 4, "days_per_stage": [2, 3, 3], "water_daily": true },
			"harvest": { "yield": [1, 1], "item_id": "lunar_bloom" },
			"value": { "base_price": 600 },
			"visual": { "color": "#D0D1FF", "accent_color": "#7073E8" }
		},
		{
			"id": "crystal_fern",
			"name": "Crystal Fern",
			"type": "plant",
			"rarity": "epic",
			"growth": { "stages": 4, "days_per_stage": [2, 2, 2], "water_daily": true },
			"harvest": { "yield": [1, 2], "item_id": "crystal_fern" },
			"value": { "base_price": 320 },
			"visual": { "color": "#9BF6FF", "accent_color": "#A0C4FF" }
		},
		{
			"id": "astral_moss",
			"name": "Astral Moss",
			"type": "plant",
			"rarity": "epic",
			"growth": { "stages": 3, "days_per_stage": [2, 2], "water_daily": true },
			"harvest": { "yield": [2, 3], "item_id": "astral_moss" },
			"value": { "base_price": 340 },
			"visual": { "color": "#5A189A", "accent_color": "#7B2CBF" }
		},
		{
			"id": "twilight_orchid",
			"name": "Twilight Orchid",
			"type": "plant",
			"rarity": "rare",
			"growth": { "stages": 4, "days_per_stage": [1, 2, 2], "water_daily": true },
			"harvest": { "yield": [1, 2], "item_id": "twilight_orchid" },
			"value": { "base_price": 220 },
			"visual": { "color": "#9D4EDD", "accent_color": "#C77DFF" }
		},
		{
			"id": "solar_moss",
			"name": "Solar Moss",
			"type": "plant",
			"rarity": "rare",
			"growth": { "stages": 3, "days_per_stage": [1, 2], "water_daily": true },
			"harvest": { "yield": [2, 3], "item_id": "solar_moss" },
			"value": { "base_price": 210 },
			"visual": { "color": "#FFB703", "accent_color": "#FB8500" }
		}
	]

	for np in new_plants:
		if not existing_ids.has(np["id"]):
			existing_plants.append(np)

	var f_p = FileAccess.open(plants_path, FileAccess.WRITE)
	if f_p:
		f_p.store_string(JSON.stringify({ "plants": existing_plants }, "  "))
		f_p.close()

	# 2. Expand res://data/combinations/base_combos.json
	var combos_path = "res://data/combinations/base_combos.json"
	var existing_combos = []
	if FileAccess.file_exists(combos_path):
		var f = FileAccess.open(combos_path, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK:
				existing_combos = json.data.get("combinations", [])
			f.close()

	var existing_combo_ids = {}
	for c in existing_combos:
		existing_combo_ids[c["id"]] = true

	var new_combos = [
		{ "id": "combo_016", "input_a": "moon_orchid", "input_b": "celestial_lily", "output": "lunar_bloom", "name": "Lunar Bloom", "success_rate": 1.0, "hidden": false },
		{ "id": "combo_017", "input_a": "glass_fern", "input_b": "frost_vine", "output": "crystal_fern", "name": "Crystal Fern", "success_rate": 1.0, "hidden": false },
		{ "id": "combo_018", "input_a": "star_moss", "input_b": "azure_lotus", "output": "astral_moss", "name": "Astral Moss", "success_rate": 1.0, "hidden": false },
		{ "id": "combo_019", "input_a": "moon_orchid", "input_b": "pink_lily", "output": "twilight_orchid", "name": "Twilight Orchid", "success_rate": 1.0, "hidden": false },
		{ "id": "combo_020", "input_a": "star_moss", "input_b": "sun_vine", "output": "solar_moss", "name": "Solar Moss", "success_rate": 1.0, "hidden": false }
	]

	for nc in new_combos:
		if not existing_combo_ids.has(nc["id"]):
			existing_combos.append(nc)

	var f_c = FileAccess.open(combos_path, FileAccess.WRITE)
	if f_c:
		f_c.store_string(JSON.stringify({ "combinations": existing_combos }, "  "))
		f_c.close()

	# 3. res://data/world/greenhouse.json
	var greenhouse_data = {
		"repair_cost": 500,
		"growth_bonus": 0.25,
		"max_stage": 2,
		"default_stage": 0,
		"special_seeds": [
			{ "id": "seed_moon_orchid", "name": "Moon Orchid Seed", "price": 90 },
			{ "id": "seed_glass_fern", "name": "Glass Fern Seed", "price": 95 },
			{ "id": "seed_star_moss", "name": "Star Moss Seed", "price": 80 }
		]
	}
	var f_g = FileAccess.open("res://data/world/greenhouse.json", FileAccess.WRITE)
	if f_g:
		f_g.store_string(JSON.stringify(greenhouse_data, "  "))
		f_g.close()

	# 4. Expand res://data/quests/base_quests.json with Greenhouse quests
	var quests_path = "res://data/quests/base_quests.json"
	var existing_quests = []
	if FileAccess.file_exists(quests_path):
		var f = FileAccess.open(quests_path, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK:
				existing_quests = json.data.get("quests", [])
			f.close()

	var existing_q_ids = {}
	for q in existing_quests:
		existing_q_ids[q["id"]] = true

	var new_quests = [
		{
			"id": "quest_08",
			"title": "The Forgotten Grove",
			"description": "Travel through the eastern gate to explore the lush Botanical Grove.",
			"giver": "Rowan",
			"unlock": { "type": "quest_completed", "quest_id": "quest_07" },
			"objectives": [
				{
					"type": "explore_zone",
					"target": "botanical_grove",
					"amount": 1,
					"current": 0,
					"description": "Explore the Botanical Grove"
				}
			],
			"rewards": { "gold": 50, "unlock": "quest_09" }
		},
		{
			"id": "quest_09",
			"title": "Restoring the Glass",
			"description": "Pay 500 Gold at the greenhouse door in the Grove to repair the structure.",
			"giver": "Rowan",
			"unlock": { "type": "quest_completed", "quest_id": "quest_08" },
			"objectives": [
				{
					"type": "repair_greenhouse",
					"target": "greenhouse",
					"amount": 1,
					"current": 0,
					"description": "Repair the Abandoned Greenhouse"
				}
			],
			"rewards": { "gold": 150, "unlock": "quest_10" }
		},
		{
			"id": "quest_10",
			"title": "Botanical Sanctuary",
			"description": "Plant and harvest your first exotic plant inside the Greenhouse.",
			"giver": "Rowan",
			"unlock": { "type": "quest_completed", "quest_id": "quest_09" },
			"objectives": [
				{
					"type": "harvest_greenhouse",
					"target": "any",
					"amount": 1,
					"current": 0,
					"description": "Harvest 1 Greenhouse crop"
				}
			],
			"rewards": { "gold": 200 }
		}
	]

	for nq in new_quests:
		if not existing_q_ids.has(nq["id"]):
			existing_quests.append(nq)

	var f_q = FileAccess.open(quests_path, FileAccess.WRITE)
	if f_q:
		f_q.store_string(JSON.stringify({ "quests": existing_quests }, "  "))
		f_q.close()

	print("[Milestone11DataExpander] Plants, Combos, Greenhouse & Quest JSON files expanded successfully!")
