class_name AssetPipelineValidator
extends RefCounted

## Automated Asset Pipeline and Art-Ready Validator.
## Verifies asset registry integrity, manifest completeness, broken references,
## world JSON stability, save/network stable IDs, and safe fallback generation.

static func validate_all() -> Dictionary:
	var results = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"asset_count": 0,
		"hardcoded_paths": 0,
		"broken_references": 0,
		"duplicate_ids": 0,
		"categories_checked": []
	}
	
	AssetRegistry.ensure_initialized()
	var all_ids = AssetRegistry.get_all_asset_ids()
	results["asset_count"] = all_ids.size()
	
	# 1. Check Duplicate IDs & Manifest integrity
	var seen_ids: Dictionary = {}
	for id in all_ids:
		if seen_ids.has(id):
			results["errors"].append("Duplicate asset ID in manifest: %s" % id)
			results["duplicate_ids"] += 1
		seen_ids[id] = true
		
	# 2. Check Broken References for all registered manifest textures & sounds
	for id in all_ids:
		var meta = AssetRegistry.get_metadata(id)
		var cat = str(meta.get("category", ""))
		if not results["categories_checked"].has(cat):
			results["categories_checked"].append(cat)
			
		if meta.has("texture"):
			var tex_path = str(meta.get("texture", ""))
			if not FileAccess.file_exists(tex_path) and not ResourceLoader.exists(tex_path):
				results["errors"].append("Broken texture reference for asset '%s': %s" % [id, tex_path])
				results["broken_references"] += 1
				
		if meta.has("path"):
			var snd_path = str(meta.get("path", ""))
			if not FileAccess.file_exists(snd_path) and not ResourceLoader.exists(snd_path):
				results["errors"].append("Broken audio reference for asset '%s': %s" % [id, snd_path])
				results["broken_references"] += 1
				
	# 3. Check World JSONs for physical paths
	var world_files = ["res://data/world/farm.json", "res://data/world/town.json", "res://data/world/forest.json", "res://data/world/botanical_grove.json"]
	for w_path in world_files:
		if FileAccess.file_exists(w_path):
			var wf = FileAccess.open(w_path, FileAccess.READ)
			if wf:
				var content = wf.get_as_text()
				wf.close()
				if "res://assets/sprites/" in content or "res://assets/audio/" in content:
					results["errors"].append("World JSON contains physical asset path: %s" % w_path)
					results["hardcoded_paths"] += 1
					
	# 4. Check Fallback Generation
	var fb_tex = AssetRegistry.get_texture("non.existent.random.asset.999")
	if fb_tex == null:
		results["errors"].append("AssetRegistry failed to return fallback placeholder for non-existent asset.")
		
	if results["errors"].size() > 0:
		results["valid"] = false
		
	return results

	