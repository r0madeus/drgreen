extends Node

## Manages deterministic combination rules, crafting execution and discovery tracking.

const COMBOS_DATA_PATH = "res://data/combinations/base_combos.json"

signal combination_performed(combo_id: String, output_item: String, is_new: bool)
signal discovery_unlocked(combo_id: String, output_item: String)

var combinations_list: Array = []
var discovered_combos: Array = [] # Array of combo IDs (String)

func _ready() -> void:
	load_combinations()

func load_combinations() -> bool:
	combinations_list.clear()
	if not FileAccess.file_exists(COMBOS_DATA_PATH):
		push_error("Combinations file not found: " + COMBOS_DATA_PATH)
		return false
		
	var file = FileAccess.open(COMBOS_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open combinations file: " + COMBOS_DATA_PATH)
		return false
		
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("JSON Parse Error in " + COMBOS_DATA_PATH + ": " + json.get_error_message())
		return false
		
	var data = json.data
	if typeof(data) == TYPE_DICTIONARY and data.has("combinations"):
		for item in data["combinations"]:
			combinations_list.append(item)
			
	print("[CombinationManager] Successfully loaded %d combination formulas." % combinations_list.size())
	return true

func get_all_combos() -> Array:
	return combinations_list.duplicate()

func _normalize_item_id(item_id: String) -> String:
	if item_id.begins_with("seed_"):
		return item_id.trim_prefix("seed_")
	elif item_id.begins_with("item_"):
		return item_id.trim_prefix("item_")
	return item_id

func get_combination(input_a: String, input_b: String) -> Dictionary:
	var norm_a = _normalize_item_id(input_a)
	var norm_b = _normalize_item_id(input_b)
	
	for combo in combinations_list:
		var c_a = combo.get("input_a", "")
		var c_b = combo.get("input_b", "")
		
		# Order-independent matching: (A==c_a and B==c_b) or (A==c_b and B==c_a)
		if (norm_a == c_a and norm_b == c_b) or (norm_a == c_b and norm_b == c_a):
			return combo
			
	return {}

func combine(player_id: String, input_a: String, input_b: String) -> Dictionary:
	return perform_combination(player_id, input_a, input_b)

func perform_combination(player_id: String, input_a: String, input_b: String) -> Dictionary:

	var combo = get_combination(input_a, input_b)
	if combo.is_empty():
		return {
			"success": false,
			"error": "No viable reaction found for these ingredients."
		}
		
	var im = get_node_or_null("/root/InventoryManager")
	if not im:
		return {
			"success": false,
			"error": "InventoryManager not available."
		}
		
	# Check ingredient quantities
	if input_a == input_b:
		if not im.has_item(player_id, input_a, 2):
			return {
				"success": false,
				"error": "Requires at least 2 of " + input_a + "."
			}
	else:
		if not im.has_item(player_id, input_a, 1) or not im.has_item(player_id, input_b, 1):
			return {
				"success": false,
				"error": "Missing required ingredients in inventory."
			}
			
	# Deduct ingredients
	im.remove_item(player_id, input_a, 1)
	im.remove_item(player_id, input_b, 1)
	
	var output_id = combo.get("output", "")
	# Give 1 crop of the new species (and optionally its seed)
	im.add_item(player_id, output_id, 1)
	im.add_item(player_id, "seed_" + output_id, 1) # Also unlock seed so player can plant the discovery
	
	var combo_id = combo.get("id", "")
	var is_new: bool = false
	if not is_combo_discovered(combo_id):
		discovered_combos.append(combo_id)
		is_new = true
		
		var wm = get_node_or_null("/root/WorldManager")
		if wm:
			var sw_state = wm.get_active_world_state()
			if sw_state: sw_state.register_discovery(combo_id, output_id)
			
		discovery_unlocked.emit(combo_id, output_id)
		var bus = get_node_or_null("/root/EventBus")
		if bus:
			bus.combination_discovered.emit(combo_id, output_id)
			bus.plant_discovered.emit(player_id, output_id)

			
	var bus_all = get_node_or_null("/root/EventBus")
	if bus_all:
		bus_all.plant_combined.emit(player_id, input_a, input_b, output_id)
			
	combination_performed.emit(combo_id, output_id, is_new)
	
	return {
		"success": true,
		"combo_id": combo_id,
		"output": output_id,
		"combo": combo,
		"is_new_discovery": is_new
	}

func is_combo_discovered(combo_id: String) -> bool:
	return combo_id in discovered_combos

func get_discovered_combinations() -> Array:
	return discovered_combos.duplicate()

func get_discovery_state() -> Dictionary:
	return {
		"discovered_combos": discovered_combos.duplicate()
	}

func load_discovery_state(data: Dictionary) -> void:
	discovered_combos = data.get("discovered_combos", [])
