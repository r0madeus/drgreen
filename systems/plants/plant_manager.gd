extends Node

## Manages plant database, JSON loading, growth calculations and harvest yields.

const PLANTS_DATA_PATH = "res://data/plants/base_plants.json"

var plants_database: Dictionary = {} # id -> Dictionary

func _ready() -> void:
	load_plants_database()

func load_plants_database() -> bool:
	plants_database.clear()
	if not FileAccess.file_exists(PLANTS_DATA_PATH):
		push_error("Plant database file not found: " + PLANTS_DATA_PATH)
		return false
		
	var file = FileAccess.open(PLANTS_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open plant database: " + PLANTS_DATA_PATH)
		return false
		
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("JSON Parse Error in " + PLANTS_DATA_PATH + ": " + json.get_error_message())
		return false
		
	var data = json.data
	if typeof(data) == TYPE_DICTIONARY and data.has("plants"):
		for plant in data["plants"]:
			if plant.has("id"):
				plants_database[plant["id"]] = plant
				
	print("[PlantManager] Successfully loaded %d plant species." % plants_database.size())
	return true

func has_plant(id: String) -> bool:
	return plants_database.has(id)

func get_plant(id: String) -> Dictionary:
	return plants_database.get(id, {})

func get_all_plant_ids() -> Array:
	return plants_database.keys()

func get_max_stages(plant_id: String) -> int:
	var plant = get_plant(plant_id)
	if plant.is_empty():
		return 3
	return plant.get("growth", {}).get("stages", 3)

func calculate_growth(plant_id: String, current_stage: int, days_in_stage: int) -> Dictionary:
	var plant = get_plant(plant_id)
	if plant.is_empty():
		return {"new_stage": current_stage, "days_in_stage": days_in_stage, "is_mature": false}
		
	var growth_info = plant.get("growth", {})
	var max_stages: int = growth_info.get("stages", 4)
	var days_per_stage: Array = growth_info.get("days_per_stage", [1, 1, 1])
	
	# Last stage index is max_stages - 1 (0-indexed: 0=seed, 1=sprout, 2=growing, 3=mature)
	var mature_stage = max_stages - 1
	if current_stage >= mature_stage:
		return {"new_stage": mature_stage, "days_in_stage": days_in_stage, "is_mature": true}
		
	var required_days = 1
	if current_stage < days_per_stage.size():
		required_days = int(days_per_stage[current_stage])
		
	var next_days = days_in_stage + 1
	var next_stage = current_stage
	
	if next_days >= required_days:
		next_stage += 1
		next_days = 0
		
	var is_mature = (next_stage >= mature_stage)
	return {
		"new_stage": next_stage,
		"days_in_stage": next_days,
		"is_mature": is_mature
	}

func get_harvest_yield(plant_id: String) -> int:
	var plant = get_plant(plant_id)
	if plant.is_empty():
		return 1
	var harvest_info = plant.get("harvest", {})
	var yield_range = harvest_info.get("yield", [1, 2])
	var min_yield = int(yield_range[0])
	var max_yield = int(yield_range[1])
	return randi_range(min_yield, max_yield)

func is_greenhouse_only(plant_id: String) -> bool:
	var plant = get_plant(plant_id)
	return bool(plant.get("greenhouse_only", false))
