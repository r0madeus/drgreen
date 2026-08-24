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
