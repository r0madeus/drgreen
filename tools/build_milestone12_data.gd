@tool
extends SceneTree

func _init() -> void:
	build_data()
	quit()

static func build_data() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/world")
	DirAccess.make_dir_recursive_absolute("res://data/quests")
	DirAccess.make_dir_recursive_absolute("res://assets/audio/sfx")

	# 1. res://data/world/seasons.json
	var seasons_data = {
		"days_per_season": 7,
		"seasons": [
			{ "id": "spring", "name": "Spring", "icon": "🌱", "banner": "🌱 Spring Begins!", "tint": [1.0, 1.05, 0.98, 1.0] },
			{ "id": "summer", "name": "Summer", "icon": "☀️", "banner": "☀️ Summer Begins!", "tint": [1.05, 1.05, 0.9, 1.0] },
			{ "id": "autumn", "name": "Autumn", "icon": "🍂", "banner": "🍂 Autumn Begins!", "tint": [1.1, 0.95, 0.8, 1.0] },
			{ "id": "winter", "name": "Winter", "icon": "❄️", "banner": "❄️ Winter Begins!", "tint": [0.85, 0.95, 1.15, 1.0] }
		]
	}
	var f_s = FileAccess.open("res://data/world/seasons.json", FileAccess.WRITE)
	if f_s:
		f_s.store_string(JSON.stringify(seasons_data, "  "))
		f_s.close()

	# 2. res://data/world/weather.json
	var weather_data = {
		"types": [
			{ "id": "clear", "name": "Clear", "icon": "☀️" },
			{ "id": "rain", "name": "Rain", "icon": "🌧️", "auto_water_outdoor": true },
			{ "id": "snow", "name": "Snow", "icon": "❄️", "freeze_outdoor": true }
		],
		"probabilities": {
			"spring": { "clear": 0.65, "rain": 0.35, "snow": 0.0 },
			"summer": { "clear": 0.80, "rain": 0.20, "snow": 0.0 },
			"autumn": { "clear": 0.55, "rain": 0.45, "snow": 0.0 },
			"winter": { "clear": 0.40, "rain": 0.0, "snow": 0.60 }
		}
	}
	var f_w = FileAccess.open("res://data/world/weather.json", FileAccess.WRITE)
	if f_w:
		f_w.store_string(JSON.stringify(weather_data, "  "))
		f_w.close()

	# 3. Expand res://data/quests/base_quests.json
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

	var new_seasonal_quests = [
		{
			"id": "quest_11",
			"title": "First Signs of Spring",
			"description": "Plant and harvest any healthy crop during the bountiful Spring season.",
			"giver": "Rowan",
			"unlock": { "type": "quest_completed", "quest_id": "quest_01" },
			"objectives": [
				{
					"type": "harvest_crop",
					"target": "any",
					"amount": 1,
					"current": 0,
					"description": "Harvest 1 crop during Spring"
				}
			],
			"rewards": { "gold": 75 }
		},
		{
			"id": "quest_12",
			"title": "Winter Sanctuary",
			"description": "Harvest a thriving exotic plant from the Greenhouse while the outdoor farm is covered in winter frost.",
			"giver": "Rowan",
			"unlock": { "type": "quest_completed", "quest_id": "quest_10" },
			"objectives": [
				{
					"type": "harvest_greenhouse",
					"target": "any",
					"amount": 1,
					"current": 0,
					"description": "Harvest 1 Greenhouse crop during Winter"
				}
			],
			"rewards": { "gold": 250 }
		}
	]

	for nq in new_seasonal_quests:
		if not existing_q_ids.has(nq["id"]):
			existing_quests.append(nq)

	var f_q = FileAccess.open(quests_path, FileAccess.WRITE)
	if f_q:
		f_q.store_string(JSON.stringify({ "quests": existing_quests }, "  "))
		f_q.close()

	print("[Milestone12DataBuilder] seasons.json, weather.json and base_quests.json written successfully!")
