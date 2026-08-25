extends SceneTree

func _init() -> void:
	print("--- AUTHORING VERTICAL SLICE ---")
	call_deferred("_run_authoring")

func _run_authoring() -> void:
	# 1. EditorDataService for Core Entities
	var es = load("res://editor/core/editor_service.gd").get_instance()
	var ds = es.data_service
	ds.load_all_base_data()
	
	# A. World
	var w = {
		"id": "deep_forest",
		"name": "Deep Forest",
		"description": "A mystical ancient woods filled with glowing flora.",
		"npcs": ["elder_botanist"]
	}
	ds.set_override("world.deep_forest", w)
	
	# B. NPC
	var npc = {
		"id": "elder_botanist",
		"name": "Elder Botanist",
		"role": "Keeper of the Grove",
		"default_dialogue": "dialogue_luminous",
		"schedule": "schedule.elder_botanist"
	}
	ds.set_override("npc.elder_botanist", npc)
	
	var sched = {
		"id": "elder_botanist",
		"morning": "farm",
		"afternoon": "farm",
		"evening": "deep_forest",
		"night": "deep_forest"
	}
	ds.set_override("schedule.elder_botanist", sched)
	
	# C. Plant
	var plant = {
		"id": "luminous_spore",
		"name": "Luminous Spore",
		"description": "A rare glowing fungus.",
		"growth_time": 2,
		"yield": 3
	}
	ds.set_override("plant.luminous_spore", plant)
	
	# D. Dialogue
	var dialogue = {
		"id": "dialogue_luminous",
		"lines": [
			{"speaker": "elder_botanist", "text": "Ah, a young botanist. Have you heard of the Luminous Spore?"},
			{"speaker": "elder_botanist", "text": "Combine a Blue Flower and a Green Vine. Bring it to me.", "start_quest": "quest_luminous"}
		]
	}
	ds.set_override("dialogue.dialogue_luminous", dialogue)
	
	# E. Quest
	var quest = {
		"id": "quest_luminous",
		"name": "The Luminous Secret",
		"description": "Synthesize a Luminous Spore and return it to the Elder Botanist.",
		"objectives": [
			{"type": "obtain_item", "target": "luminous_spore", "amount": 1}
		],
		"rewards": {
			"gold": 500,
			"event": "play_cutscene_luminous_victory"
		}
	}
	ds.set_override("quest.quest_luminous", quest)
	
	# F. Cutscene
	var cutscene = {
		"id": "cutscene_luminous_victory",
		"duration": 5.0,
		"events": [
			{"time": 0.0, "type": "audio", "path": "res://assets/audio/sfx/discovery.wav"},
			{"time": 1.0, "type": "dialogue", "speaker": "elder_botanist", "text": "Incredible! The Deep Forest is now open to you."}
		]
	}
	ds.set_override("cutscene.cutscene_luminous_victory", cutscene)
	
	# G. Audio assignment (Mocking audio assignment inside world)
	w["metadata"] = {"music": "res://assets/audio/music/forest_theme.ogg"}
	ds.set_override("world.deep_forest", w)
	
	ds.save_active_project()
	print("Saved Editor Data")
	
	# 2. CombinationDataService
	var ComboDS = load("res://systems/combination/combination_data_service.gd")
	ComboDS.ensure_loaded()
	var c_count = ComboDS.get_all_combos().size()
	var combo = {
		"id": "combo_luminous",
		"name": "Luminous Spore Synthesis",
		"input_a": "blue_flower",
		"input_b": "green_vine",
		"output": "luminous_spore",
		"success_rate": 1.0,
		"hidden": true
	}
	ComboDS.update_combo(c_count, combo)
	ComboDS.save_combos()
	print("Saved Combination Data")
	
	# 3. ProgressionDataService
	var ProgDS = load("res://systems/progression/progression_data_service.gd")
	ProgDS.ensure_loaded()
	var unlock = {
		"id": "deep_forest",
		"name": "Deep Forest",
		"description": "Unlocked by completing The Luminous Secret.",
		"unlock_conditions": [
			{"type": "quest_completed", "quest_id": "quest_luminous"}
		],
		"unlocked_by_default": false
	}
	ProgDS.update_unlock("deep_forest", unlock)
	ProgDS.save_unlocks()
	print("Saved Progression Data")
	
	print("--- AUTHORING COMPLETE ---")
	quit(0)
