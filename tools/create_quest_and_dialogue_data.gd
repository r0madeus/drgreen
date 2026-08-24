@tool
extends SceneTree

func _init() -> void:
	create_all()
	quit()

static func create_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/quests")
	DirAccess.make_dir_recursive_absolute("res://data/npcs/dialogues")
	DirAccess.make_dir_recursive_absolute("res://data/unlocks")

	# 1. res://data/quests/base_quests.json
	var quests_data = {
		"quests": [
			{
				"id": "quest_01",
				"title": "First Seeds",
				"description": "Plant your very first seed in the tilled farm soil.",
				"giver": "Rowan",
				"unlock": { "type": "auto" },
				"objectives": [
					{
						"type": "plant",
						"target": "any",
						"amount": 1,
						"current": 0,
						"description": "Plant 1 seed in tilled soil"
					}
				],
				"rewards": { "gold": 25, "unlock": "quest_02" }
			},
			{
				"id": "quest_02",
				"title": "Keep Them Alive",
				"description": "Water your growing crops 3 times to ensure healthy growth.",
				"giver": "Rowan",
				"unlock": { "type": "quest_completed", "quest_id": "quest_01" },
				"objectives": [
					{
						"type": "water",
						"target": "any",
						"amount": 3,
						"current": 0,
						"description": "Water crops 3 times"
					}
				],
				"rewards": { "gold": 25, "unlock": "quest_03" }
			},
			{
				"id": "quest_03",
				"title": "First Harvest",
				"description": "Harvest your first mature plant from the fields.",
				"giver": "Rowan",
				"unlock": { "type": "quest_completed", "quest_id": "quest_02" },
				"objectives": [
					{
						"type": "harvest",
						"target": "any",
						"amount": 1,
						"current": 0,
						"description": "Harvest 1 mature crop"
					}
				],
				"rewards": { "gold": 50, "unlock": "quest_04" }
			},
			{
				"id": "quest_04",
				"title": "First Sale",
				"description": "Sell a harvested crop at Rowan's seed and market stall.",
				"giver": "Rowan",
				"unlock": { "type": "quest_completed", "quest_id": "quest_03" },
				"objectives": [
					{
						"type": "sell",
						"target": "any",
						"amount": 1,
						"current": 0,
						"description": "Sell 1 crop for Gold"
					}
				],
				"rewards": { "gold": 75, "unlock": "quest_05" }
			},
			{
				"id": "quest_05",
				"title": "A New Possibility",
				"description": "Synthesize two different plants in the Lab (C) to discover your first hybrid!",
				"giver": "Rowan",
				"unlock": { "type": "quest_completed", "quest_id": "quest_04" },
				"objectives": [
					{
						"type": "discover",
						"target": "any_hybrid",
						"amount": 1,
						"current": 0,
						"description": "Discover 1 new hybrid species"
					}
				],
				"rewards": { "gold": 100, "unlock": "quest_06" }
			},
			{
				"id": "quest_06",
				"title": "Botanical Research",
				"description": "Discover at least 5 distinct botanical species in your Journal (J).",
				"giver": "Rowan",
				"unlock": { "type": "quest_completed", "quest_id": "quest_05" },
				"objectives": [
					{
						"type": "total_discovered",
						"target": "plants",
						"amount": 5,
						"current": 0,
						"description": "Reach 5 discovered species in Codex"
					}
				],
				"rewards": { "gold": 150, "unlock": "quest_07" }
			},
			{
				"id": "quest_07",
				"title": "Rare Specimen",
				"description": "Synthesize and discover a Rare, Epic or Legendary tier hybrid species.",
				"giver": "Rowan",
				"unlock": { "type": "quest_completed", "quest_id": "quest_06" },
				"objectives": [
					{
						"type": "discover_rarity",
						"target": "rare_or_higher",
						"amount": 1,
						"current": 0,
						"description": "Discover a Rare/Epic/Legendary hybrid"
					}
				],
				"rewards": { "gold": 250 }
			}
		]
	}
	var f1 = FileAccess.open("res://data/quests/base_quests.json", FileAccess.WRITE)
	if f1:
		f1.store_string(JSON.stringify(quests_data, "  "))
		f1.close()

	# 2. res://data/npcs/dialogues/rowan_dialogues.json
	var dialogues_data = {
		"npc_id": "rowan",
		"npc_name": "Rowan the Herbalist",
		"dialogues": {
			"intro": [
				"Ah, welcome to the valley, professor! It's peaceful here, isn't it?",
				"I heard you used to teach biology. These soils are far more intriguing than ordinary earth.",
				"Take some starter seeds from my stall, plant them, and see what botanical wonders emerge!"
			],
			"first_harvest": [
				"Splendid harvest! You can sell extra crops to me for Gold, or keep them for synthesis experiments.",
				"Speaking of experiments... have you tried taking two different crops to your Synthesis Lab (C)?"
			],
			"first_hybrid": [
				"By the Great Oak! You actually synthesized a brand new hybrid species?!",
				"I knew your biology background would bear fruit! What other impossible combinations might exist?"
			],
			"botanical_master": [
				"Your garden has become the finest botanical sanctuary in the entire valley!",
				"I'm honored to supply seeds for a master herbalist like you."
			],
			"default": [
				"Greetings, professor! The soil is rich today. Need any fresh seeds or looking to sell your harvest?"
			]
		}
	}
	var f2 = FileAccess.open("res://data/npcs/dialogues/rowan_dialogues.json", FileAccess.WRITE)
	if f2:
		f2.store_string(JSON.stringify(dialogues_data, "  "))
		f2.close()

	# 3. res://data/unlocks/base_unlocks.json
	var unlocks_data = {
		"unlocks": [
			{ "id": "unlock_lab", "title": "Synthesis Lab", "condition": "auto", "unlocked": true },
			{ "id": "unlock_codex", "title": "Botanical Codex", "condition": "auto", "unlocked": true }
		]
	}
	var f3 = FileAccess.open("res://data/unlocks/base_unlocks.json", FileAccess.WRITE)
	if f3:
		f3.store_string(JSON.stringify(unlocks_data, "  "))
		f3.close()

	print("[QuestDataCreator] Successfully created quest, dialogue and unlock JSON files!")
