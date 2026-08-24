class_name EngineCompatibilityService
extends RefCounted

## Engine Compatibility, Cross-Platform Hardening & Diagnostics Service (Phase 43).
## Provides normalized path management, mod dependency checking, localization/asset safe fallbacks,
## and error-tolerant diagnostic recovery.

static var _diagnostics: Array[Dictionary] = []

# 1. Cross-Platform Path Normalization
static func normalize_path(path: String) -> String:
	if path == "": return ""
	var clean = path.replace("\\", "/").strip_edges()
	# Strip redundant double slashes (except in protocols like res://, user://)
	if clean.begins_with("res://"):
		return "res://" + clean.trim_prefix("res://").replace("//", "/")
	elif clean.begins_with("user://"):
		return "user://" + clean.trim_prefix("user://").replace("//", "/")
	return clean.replace("//", "/")

# 2. Mod Dependency Validation
static func validate_mod_dependencies(mod_manifest: Dictionary, active_mods: Array) -> Dictionary:
	var deps = mod_manifest.get("dependencies", [])
	var missing: Array[String] = []
	var conflicts: Array[String] = []
	
	var active_ids: Dictionary = {}
	for m in active_mods:
		if m is Dictionary:
			active_ids[str(m.get("mod_id", m.get("id", "")))] = str(m.get("version", "1.0.0"))
		elif m is String:
			active_ids[m] = "1.0.0"
			
	if deps is Array:
		for d in deps:
			var req_id = ""
			if d is Dictionary: req_id = str(d.get("mod_id", d.get("id", "")))
			elif d is String: req_id = str(d)
			
			if req_id != "" and not active_ids.has(req_id):
				missing.append(req_id)
				
	var conf_list = mod_manifest.get("conflicts", [])
	if conf_list is Array:
		for c in conf_list:
			var cid = str(c)
			if active_ids.has(cid):
				conflicts.append(cid)
				
	var is_valid = (missing.is_empty() and conflicts.is_empty())
	if not is_valid:
		log_diagnostic("MOD_DEPENDENCY", "Mod '%s' failed validation. Missing: %s, Conflicts: %s" % [str(mod_manifest.get("mod_id", "unknown")), str(missing), str(conflicts)], "ERROR")
		
	return {
		"valid": is_valid,
		"missing_dependencies": missing,
		"conflicts": conflicts
	}

# 3. Asset & Localization Safe Fallback
static func get_safe_asset(asset_id: String, fallback: String = "res://icon.svg") -> String:
	if asset_id == "" or asset_id == "null":
		return fallback
	return asset_id

static func get_safe_string(loc_key: String, default_text: String = "") -> String:
	if loc_key == "": return default_text
	if default_text != "": return default_text
	return loc_key

# 4. Diagnostic Logging & Error Recovery
static func log_diagnostic(category: String, message: String, severity: String = "WARNING") -> void:
	var entry = {
		"category": category,
		"message": message,
		"severity": severity,
		"timestamp": Time.get_unix_time_from_system()
	}
	_diagnostics.append(entry)
	if _diagnostics.size() > 500:
		_diagnostics.pop_front()

static func get_diagnostics() -> Array[Dictionary]:
	return _diagnostics.duplicate(true)

static func clear_diagnostics() -> void:
	_diagnostics.clear()
