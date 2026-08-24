extends Node

## Manages Discovery Journal queries, calculating progress from PlantManager and CombinationManager.

const STARTER_PLANTS: Array[String] = [
	"red_flower", "blue_flower", "yellow_herb", "green_vine", "white_lily"
]

signal journal_updated()

func _ready() -> void:
	var cm = get_node_or_null("/root/CombinationManager")
	if cm:
		cm.discovery_unlocked.connect(func(_id, _out): journal_updated.emit())

func is_plant_discovered(plant_id: String) -> bool:
	# Starter plants are known to the biologist from the start
	if plant_id in STARTER_PLANTS:
		return true
		
	# Check SharedWorldState
	var wm = get_node_or_null("/root/WorldManager")
	if wm and wm.has_method("get_active_world_state"):
		var state = wm.get_active_world_state()
		if state and state.has_method("is_plant_discovered") and state.is_plant_discovered(plant_id):
			return true
		
	# Check if discovered via combination
	var cm = get_node_or_null("/root/CombinationManager")
	if cm:
		var combos = cm.get_all_combos()
		for combo in combos:
			if combo.get("output", "") == plant_id:
				if cm.is_combo_discovered(combo.get("id", "")):
					return true
					
	# Check if in inventory
	var im = get_node_or_null("/root/InventoryManager")
	if im:
		if im.get_item_count(plant_id) > 0 or im.get_item_count("seed_" + plant_id) > 0:
			return true
			
	return false

func is_combo_discovered(combo_id: String) -> bool:
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		var state = wm.get_active_world_state()
		if state and state.is_combination_discovered(combo_id):
			return true
	var cm = get_node_or_null("/root/CombinationManager")
	if cm:
		return cm.is_combo_discovered(combo_id)
	return false


func get_all_plants_status() -> Array:
	var result: Array = []
	var pm = get_node_or_null("/root/PlantManager")
	if not pm:
		return result
		
	for plant_id in pm.get_all_plant_ids():
		var pdata = pm.get_plant(plant_id)
		var discovered = is_plant_discovered(plant_id)
		result.append({
			"id": plant_id,
			"name": pdata.get("name", plant_id) if discovered else "Unknown Species",
			"raw_name": pdata.get("name", plant_id),
			"discovered": discovered,
			"data": pdata if discovered else {}
		})
	return result

func get_all_combos_status() -> Array:
	var result: Array = []
	var cm = get_node_or_null("/root/CombinationManager")
	var pm = get_node_or_null("/root/PlantManager")
	if not cm:
		return result
		
	for combo in cm.get_all_combos():
		var combo_id = combo.get("id", "")
		var discovered = cm.is_combo_discovered(combo_id)
		var out_id = combo.get("output", "")
		var out_name = combo.get("name", out_id)
		if pm and pm.has_plant(out_id):
			out_name = pm.get_plant(out_id).get("name", out_name)
			
		result.append({
			"id": combo_id,
			"input_a": combo.get("input_a", ""),
			"input_b": combo.get("input_b", ""),
			"output": out_id,
			"output_name": out_name,
			"discovered": discovered,
			"raw_combo": combo
		})
	return result

func get_discovered_plants_count() -> int:
	var count = 0
	var pm = get_node_or_null("/root/PlantManager")
	if pm:
		for pid in pm.get_all_plant_ids():
			if is_plant_discovered(pid):
				count += 1
	return count

func get_discovered_plant_count() -> int:
	return get_discovered_plants_count()


func get_total_plants_count() -> int:
	var pm = get_node_or_null("/root/PlantManager")
	return pm.get_all_plant_ids().size() if pm else 0

func get_discovered_combos_count() -> int:
	var cm = get_node_or_null("/root/CombinationManager")
	return cm.get_discovered_combinations().size() if cm else 0

func get_total_combos_count() -> int:
	var cm = get_node_or_null("/root/CombinationManager")
	return cm.get_all_combos().size() if cm else 0
