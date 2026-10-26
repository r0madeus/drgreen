extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[Author4A] Starting Vertical Slice Authoring...")
	var editor_service = preload("res://editor/core/editor_service.gd").get_instance()
	if not editor_service:
		editor_service = preload("res://editor/core/editor_service.gd").new()
	var ds = editor_service.data_service
	
	print("[Author4A] Creating Audio...")
	ds.create_entity("audio.sfx_quest_complete", {
		"id": "sfx_quest_complete",
		"path": "res://assets/audio/sfx/ui_select.wav",
		"volume": 0.0
	})
	
	print("[Author4A] Creating Cutscene...")
	ds.create_entity("cutscene.cutscene_luminous", {
		"id": "cutscene_luminous",
		"duration": 2.0,
		"tracks": [
			{
				"actor_id": "player",
				"events": [
					{
						"start": 0.0,
						"duration": 2.0,
						"type": "wait",
						"params": {}
					}
				]
			}
		]
	})
	
	print("[Author4A] Creating Quest...")
	ds.create_entity("quest.quest_luminous", {
		"id": "quest_luminous",
		"title": "The Luminous Spore",
		"description": "Create a Luminous Spore via combination.",
		"stages": {
			"0": {
				"type": "obtain_item",
				"item_id": "item_luminous_spore",
				"amount": 1
			}
		},
		"rewards": {
			"gold": 100,
			"trigger_cutscene": "cutscene_luminous",
			"play_audio": "sfx_quest_complete"
		}
	})
	
	print("[Author4A] Creating Dialogue...")
	ds.create_entity("dialogue.dialogue_luminous", {
		"id": "dialogue_luminous",
		"lines": [
			{
				"speaker": "Luminous Botanist",
				"text": "Please craft a Luminous Spore for me.",
				"start_quest": "quest_luminous"
			}
		]
	})
	
	print("[Author4A] Creating NPC...")
	ds.create_entity("npc.npc_luminous_botanist", {
		"id": "npc_luminous_botanist",
		"name": "Luminous Botanist",
		"role": "Quest Giver",
		"default_dialogue": "dialogue_luminous",
		"spawn_world": "farm",
		"spawn_coords": [10, 10]
	})
	ds.create_entity("schedule.npc_luminous_botanist", {
		"npc_id": "npc_luminous_botanist",
		"schedule": [
			{"time": 6.0, "action": "move_to", "target": "luminous_grove", "coords": [10, 10]}
		]
	})
	
	print("[Author4A] Creating Plant and Item...")
	ds.create_entity("plant.luminous_spore", {
		"id": "luminous_spore",
		"name": "Luminous Spore",
		"growth_days": 1,
		"harvest_yield": "item_luminous_spore",
		"phases": ["seed", "sprout", "mature"]
	})
	ds.create_entity("item.item_luminous_spore", {
		"id": "item_luminous_spore",
		"name": "Luminous Spore Produce",
		"type": "resource",
		"value": 50
	})
	ds.create_entity("item.seed_luminous_spore", {
		"id": "seed_luminous_spore",
		"name": "Luminous Spore Seed",
		"type": "seed",
		"plant_type": "luminous_spore",
		"value": 10
	})
	
	# Inputs for combination
	ds.create_entity("plant.mushroom", {
		"id": "mushroom", "name": "Mushroom", "growth_days": 1, "harvest_yield": "item_mushroom", "phases": ["seed", "mature"]
	})
	ds.create_entity("item.seed_mushroom", {
		"id": "seed_mushroom", "name": "Mushroom Spores", "type": "seed", "plant_type": "mushroom", "value": 5
	})
	ds.create_entity("plant.starpetal", {
		"id": "starpetal", "name": "Starpetal", "growth_days": 1, "harvest_yield": "item_starpetal", "phases": ["seed", "mature"]
	})
	ds.create_entity("item.seed_starpetal", {
		"id": "seed_starpetal", "name": "Starpetal Seed", "type": "seed", "plant_type": "starpetal", "value": 5
	})
	
	print("[Author4A] Creating Combination...")
	var ComboDS = load("res://systems/combination/combination_data_service.gd")
	ComboDS.ensure_loaded()
	# Reuse the existing slot so re-running the script does not duplicate the combo
	var luminous_idx := -1
	var all_combos: Array = ComboDS.get_all_combos()
	for i in all_combos.size():
		if str(all_combos[i].get("id", "")) == "combo_luminous":
			luminous_idx = i
			break
	ComboDS.update_combo(luminous_idx, {
		"id": "combo_luminous",
		"input_a": "mushroom",
		"input_b": "starpetal",
		"output": "luminous_spore",
		"duration": 1.0,
		"hidden": false
	})
	ComboDS.save_combos()
	
	print("[Author4A] Creating World...")
	ds.create_entity("world.luminous_grove", {
		"id": "luminous_grove",
		"display_name": "Luminous Grove",
		"scene": "res://scenes/farm.tscn",
		"map_data": "res://data/worlds/farm.json",
		"enabled": true,
		"width": 32.0,
		"height": 32.0,
		"spawn_points": {
			"default": [15, 15]
		},
		"metadata": {
			"music": "sfx_quest_complete"
		}
	})
	
	print("[Author4A] Creating Progression/Unlock...")
	var ProgDS = load("res://systems/progression/progression_data_service.gd")
	ProgDS.ensure_loaded()
	ProgDS.update_unlock("luminous_grove", {
		"world_id": "luminous_grove",
		"unlock_conditions": [
			{
				"type": "quest_completed",
				"quest_id": "quest_luminous"
			}
		]
	})
	ProgDS.save_unlocks()
	
	print("[Author4A] Validating Data...")
	var ValidationService = load("res://editor/core/editor_validation_service.gd")
	var report = ValidationService.validate_data(ds)
	if not report["valid"]:
		print("[Author4A] Validation failed! Errors: ", report["errors"])
	else:
		print("[Author4A] Validation passed!")
		
	print("[Author4A] Saving Project...")
	ds.save_overrides()
	print("[Author4A] Done.")
	quit(0)
