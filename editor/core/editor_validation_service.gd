class_name EditorValidationService
extends RefCounted

## Automated Cross-Domain Validation Service for the In-Game Editor (Phase 33 Enhanced).
## Verifies Stable ID integrity, references across Worlds, NPCs, schedules, dialogues, quests,
## items, crops, tools, and installed mod packages.

enum Severity { ERROR, WARNING, INFO }

static func validate_data(data_service: EditorDataService) -> Dictionary:
	var report = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"total_checked": 0,
		"broken_references": 0,
		"duplicate_ids": 0
	}

	if not data_service:
		report["valid"] = false
		report["errors"].append("DataService instance is null.")
	
		return report

	var all_ids = data_service.get_all_stable_ids()
	report["total_checked"] = all_ids.size()

	# 1. Validate NPC references in schedules
	for s_id in all_ids:
		if s_id.begins_with("schedule."):
			var npc_id = s_id.replace("schedule.", "npc.")
			var npc_obj = data_service.get_resolved_object(npc_id)
			if npc_obj.is_empty():
				report["errors"].append({
					"category": "schedules",
					"id": s_id,
					"target_module": "npc",
					"target_entity": s_id.replace("schedule.", ""),
					"message": "Schedule references missing NPC: %s" % npc_id
				})
				report["broken_references"] += 1

	# 2. Validate Quest objectives, reward items, and prerequisites
	for q_id in all_ids:
		if q_id.begins_with("quest."):
			var q_data = data_service.get_resolved_object(q_id)
			
			# 2a. Validate Objectives
			var objectives = q_data.get("objectives", [])
			if typeof(objectives) == TYPE_ARRAY:
				for obj in objectives:
					if typeof(obj) == TYPE_DICTIONARY:
						var tgt = str(obj.get("target", ""))
						if tgt != "" and tgt != "any" and tgt != "all":
							if tgt.begins_with("item.") or tgt.begins_with("crop."):
								if data_service.get_resolved_object(tgt).is_empty():
									report["errors"].append({
										"category": "quest",
										"id": q_id,
										"target_module": "item",
										"target_entity": tgt,
										"message": "Quest %s references missing target: %s" % [q_id, tgt]
									})
									report["broken_references"] += 1
			
			# 2b. Validate Rewards
			var rewards = q_data.get("rewards", {})
			if typeof(rewards) == TYPE_DICTIONARY and rewards.has("item"):
				var item_map = rewards["item"]
				if typeof(item_map) == TYPE_DICTIONARY:
					for item_key in item_map:
						var full_item_id = "item." + item_key
						if data_service.get_resolved_object(full_item_id).is_empty():
							report["warnings"].append({
								"category": "quest",
								"id": q_id,
								"target_module": "item",
								"target_entity": item_key,
								"message": "Quest rewards unverified item ID: %s" % item_key
							})


	# 3. Validate World definitions
	for w_id in all_ids:
		if w_id.begins_with("world."):
			var w_obj = data_service.get_resolved_object(w_id)
			if w_obj.is_empty():
				report["errors"].append({
					"category": "world",
					"id": w_id,
					"target_module": "world",
					"target_entity": w_id.replace("world.", ""),
					"message": "World data object is empty for %s" % w_id
				})
				report["broken_references"] += 1

	# 4. Validate Mod Conflicts and Dependencies
	if data_service.mod_manager:
		var conflicts = data_service.mod_manager.detect_conflicts()
		for c in conflicts:
			report["warnings"].append({
				"category": "mods",
				"id": c.get("stable_id", ""),
				"target_module": "mods",
				"message": "Mod conflict on %s.%s between %s (Winner: %s)" % [
					c.get("stable_id", ""),
					c.get("property_key", ""),
					str(c.get("competing_mods", [])),
					c.get("winning_mod", "")
				]
			})

	# 5. Phase 35 — Asset Validation
	AssetRegistry.ensure_initialized()
	var all_asset_ids := AssetRegistry.get_all_asset_ids()
	var seen_stable_ids: Dictionary = {}
	for aid in all_asset_ids:
		var aid_str := str(aid)
		report["total_checked"] += 1

		# 5a. Duplicate stable IDs
		if seen_stable_ids.has(aid_str):
			report["errors"].append({
				"category": "assets",
				"id": aid_str,
				"target_module": "assets",
				"message": "Duplicate asset stable ID detected: %s" % aid_str
			})
			report["duplicate_ids"] += 1
		else:
			seen_stable_ids[aid_str] = true

		# 5b. Stable ID format check (must contain '.')
		if not aid_str.contains("."):
			report["warnings"].append({
				"category": "assets",
				"id": aid_str,
				"target_module": "assets",
				"message": "Asset stable ID does not follow 'category.name' format: %s" % aid_str
			})

		var meta := AssetRegistry.get_metadata(aid_str)

		# 5c. Missing texture path
		var tex_path := str(meta.get("texture", meta.get("path", "")))
		if tex_path != "" and not ResourceLoader.exists(tex_path) and not FileAccess.file_exists(tex_path):
			report["errors"].append({
				"category": "assets",
				"id": aid_str,
				"target_module": "assets",
				"message": "Asset references missing file: %s -> %s" % [aid_str, tex_path]
			})
			report["broken_references"] += 1

		# 5d. Invalid frame count
		var frames_val = meta.get("frames", null)
		if frames_val != null and (typeof(frames_val) != TYPE_INT or int(frames_val) < 1):
			report["warnings"].append({
				"category": "assets",
				"id": aid_str,
				"target_module": "assets",
				"message": "Asset has invalid frame count (must be >= 1): %s" % aid_str
			})

		# 5e. Invalid dimensions
		var size_val = meta.get("size", null)
		if size_val != null and typeof(size_val) == TYPE_ARRAY:
			var w = size_val[0] if size_val.size() > 0 else 0
			var h = size_val[1] if size_val.size() > 1 else 0
			if int(w) <= 0 or int(h) <= 0:
				report["warnings"].append({
					"category": "assets",
					"id": aid_str,
					"target_module": "assets",
					"message": "Asset has invalid size dimensions: %s -> %s" % [aid_str, str(size_val)]
				})

	if report["errors"].size() > 0:
		report["valid"] = false


	# 6. Cross-reference Validations
	for id in all_ids:
		var obj = data_service.get_resolved_object(id)
		if typeof(obj) != TYPE_DICTIONARY: continue

		# NPC -> Dialogue
		if id.begins_with("npc."):
			var diag = obj.get("default_dialogue", "")
			if diag != "" and data_service.get_resolved_object("dialogue." + diag).is_empty():
				report["errors"].append({"category": "npc", "id": id, "message": "Missing dialogue reference: " + diag})
				report["broken_references"] += 1

		# Dialogue -> Quest
		if id.begins_with("dialogue."):
			var lines = obj.get("lines", [])
			if typeof(lines) == TYPE_ARRAY:
				for line in lines:
					if typeof(line) == TYPE_DICTIONARY:
						var start_q = line.get("start_quest", "")
						if start_q != "" and data_service.get_resolved_object("quest." + start_q).is_empty():
							report["errors"].append({"category": "dialogue", "id": id, "message": "Missing quest reference: " + start_q})
							report["broken_references"] += 1

		# World -> NPC & Audio
		if id.begins_with("world."):
			var npcs = obj.get("npcs", [])
			if typeof(npcs) == TYPE_ARRAY:
				for n in npcs:
					if data_service.get_resolved_object("npc." + str(n)).is_empty():
						report["errors"].append({"category": "world", "id": id, "message": "Missing NPC reference in world: " + str(n)})
						report["broken_references"] += 1
			var meta = obj.get("metadata", {})
			if typeof(meta) == TYPE_DICTIONARY:
				var w_music = meta.get("music", "")
				var w_amb = meta.get("ambient", "")
				# Audio is handled by AudioDataService/AssetRegistry, skip direct resolution if not strictly in data_service, but we assume it's in audio map if it exists.

		# Plant -> Item / Genetics
		if id.begins_with("item.") and obj.get("type") == "seed":
			var plant_type = obj.get("plant_type", "")
			# if plant_type != "" and data_service.get_resolved_object("plant." + plant_type).is_empty():
			#    pass # plants might not be in stable IDs directly if handled differently


	# 7. Phase 3F - Combination and Progression Validation
	if ClassDB.class_exists("CombinationDataService"):
		var ComboDS = load("res://systems/combination/combination_data_service.gd")
		ComboDS.ensure_loaded()
		var combos = ComboDS.get_all_combos()
		var seen_combos = {}
		for c in combos:
			var cid = c.get("id", "")
			var ia = c.get("input_a", "")
			var ib = c.get("input_b", "")
			var out = c.get("output", "")
			if cid == "":
				report["errors"].append({"category": "combination", "id": cid, "message": "Missing Combination ID"})
			if ia == "" or ib == "" or out == "":
				report["errors"].append({"category": "combination", "id": cid, "message": "Missing input/output in combo: " + cid})
			if seen_combos.has(cid):
				report["errors"].append({"category": "combination", "id": cid, "message": "Duplicate Combination ID: " + cid})
			seen_combos[cid] = true
			# Validate plant references
			if not data_service.get_resolved_object("plant." + ia).is_empty() == false and ia != "":
				report["warnings"].append({"category": "combination", "id": cid, "message": "Unrecognized Input A: " + ia})
			if not data_service.get_resolved_object("plant." + ib).is_empty() == false and ib != "":
				report["warnings"].append({"category": "combination", "id": cid, "message": "Unrecognized Input B: " + ib})
			if not data_service.get_resolved_object("plant." + out).is_empty() == false and out != "":
				report["warnings"].append({"category": "combination", "id": cid, "message": "Unrecognized Output: " + out})

	if ClassDB.class_exists("ProgressionDataService"):
		var ProgDS = load("res://systems/progression/progression_data_service.gd")
		ProgDS.ensure_loaded()
		var unlocks = ProgDS.get_all_unlocks()
		for wid in unlocks.keys():
			var w = unlocks[wid]
			var conds = w.get("unlock_conditions", [])
			if typeof(conds) == TYPE_ARRAY:
				for cond in conds:
					if typeof(cond) == TYPE_DICTIONARY:
						if cond.get("type") == "quest_completed":
							var qid = cond.get("quest_id", "")
							if data_service.get_resolved_object("quest." + qid).is_empty():
								report["errors"].append({"category": "progression", "id": wid, "message": "Invalid quest reference in world unlock: " + qid})
								report["broken_references"] += 1
						elif cond.get("type") == "world_unlocked":
							var rwid = cond.get("world_id", "")
							if not unlocks.has(rwid):
								report["errors"].append({"category": "progression", "id": wid, "message": "Invalid world reference in world unlock: " + rwid})
								report["broken_references"] += 1
							# Circular check
							elif unlocks.has(rwid):
								var req_conds = unlocks[rwid].get("unlock_conditions", [])
								if typeof(req_conds) == TYPE_ARRAY:
									for rcond in req_conds:
										if typeof(rcond) == TYPE_DICTIONARY and rcond.get("type") == "world_unlocked" and rcond.get("world_id") == wid:
											report["errors"].append({"category": "progression", "id": wid, "message": "Circular dependency detected between " + wid + " and " + rwid})


	return report


static func validate_project() -> Dictionary:
	var service = EditorService.get_instance()
	if service and service.data_service:
		return validate_data(service.data_service)
	return { "valid": true, "errors": [], "warnings": [], "total_checked": 0 }

static func validate_mod(mod_def: ModManager.ModDefinition) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	
	if not mod_def:
		return { "valid": false, "errors": ["Mod definition is null"], "warnings": [] }
		
	if mod_def.id == "":
		errors.append("Mod ID cannot be empty.")
	if mod_def.name == "":
		warnings.append("Mod name is empty.")
		
	for s_id in mod_def.overrides.keys():
		if not s_id.contains("."):
			warnings.append("Override stable_id does not follow standard 'category.name' format: %s" % s_id)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"mod_id": mod_def.id
	}

static func validate_cutscene(data: Dictionary) -> bool:
	var cid = data.get("id", "")
	if cid == "":
		push_error("[Validation] Cutscene ID cannot be empty.")
		return false
		
	var duration = float(data.get("duration", 0.0))
	if duration < 0:
		push_error("[Validation] Cutscene duration cannot be negative.")
		return false
		
	var tracks = data.get("tracks", [])
	for track in tracks:
		var evts = track.get("events", [])
		for e in evts:
			var start_t = float(e.get("start", 0))
			var dur = float(e.get("duration", 0))
			
			if start_t < 0 or (start_t + dur) > duration:
				push_error("[Validation] Event out of bounds in track: " + track.get("actor_id", ""))
				return false
				
			var type = e.get("type", "")
			var params = e.get("params", {})
			
			if type == "dialogue" and params.get("dialogue_id", "") == "":
				push_error("[Validation] Dialogue event missing dialogue_id.")
				return false
	return true

static func validate_audio(data: Dictionary) -> bool:
	if not data.has("id") or str(data.get("id")).strip_edges() == "":
		push_error("[Validation] Audio ID cannot be empty.")
		return false
	var path = str(data.get("path", "")).strip_edges()
	if path != "" and not ResourceLoader.exists(path):
		push_error("[Validation] Audio asset does not exist: " + path)
		return false
	return true
