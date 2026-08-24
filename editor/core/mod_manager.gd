class_name ModManager
extends RefCounted

## Mod Management Engine for Botanical Haven (Phase 33 Enhanced).
## Manages installed mods, manifest validation, .bhmod package import/export,
## enabled/disabled states, priority-based override ordering, conflict detection, and preview generation.

signal mod_state_changed()

const MODS_BASE_DIR: String = "user://mods/"
const BHMOD_EXTENSION: String = ".bhmod"

class ModDefinition extends RefCounted:
	var id: String = ""
	var name: String = ""
	var version: String = "1.0.0"
	var author: String = "Unknown"
	var description: String = ""
	var game_version: String = "1.0.0"
	var target_game_id: String = "botanical_haven"
	var enabled: bool = true
	var priority: int = 100 # Higher number = loads later / wins conflicts
	var content_version: int = 1
	var dependencies: Array[String] = []
	var overrides: Dictionary = {} # stable_id -> Dictionary of property overrides
	var added_data: Dictionary = {} # stable_id -> Dictionary of new content definitions

	func _init(p_id: String = "", p_name: String = "") -> void:
		id = p_id
		name = p_name if p_name != "" else p_id

	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"version": version,
			"author": author,
			"description": description,
			"game_version": game_version,
			"target_game_id": target_game_id,
			"enabled": enabled,
			"priority": priority,
			"content_version": content_version,
			"dependencies": dependencies,
			"overrides": overrides,
			"added_data": added_data
		}

	static func from_dict(d: Dictionary) -> ModDefinition:
		var m = ModDefinition.new(str(d.get("id", "")), str(d.get("name", "")))
		m.version = str(d.get("version", "1.0.0"))
		m.author = str(d.get("author", "Unknown"))
		m.description = str(d.get("description", ""))
		m.game_version = str(d.get("game_version", "1.0.0"))
		m.target_game_id = str(d.get("target_game_id", "botanical_haven"))
		m.enabled = bool(d.get("enabled", true))
		m.priority = int(d.get("priority", 100))
		m.content_version = int(d.get("content_version", 1))
		var raw_deps = d.get("dependencies", [])
		if raw_deps is Array:
			for dep in raw_deps: m.dependencies.append(str(dep))
		m.overrides = d.get("overrides", {}).duplicate(true)
		m.added_data = d.get("added_data", {}).duplicate(true)
		return m

var _installed_mods: Dictionary = {} # mod_id -> ModDefinition

func _init() -> void:
	_ensure_mods_dir()
	scan_installed_mods()

func _ensure_mods_dir() -> void:
	if not DirAccess.dir_exists_absolute(MODS_BASE_DIR):
		DirAccess.make_dir_recursive_absolute(MODS_BASE_DIR)

func scan_installed_mods() -> void:
	_ensure_mods_dir()
	var dirs = DirAccess.get_directories_at(MODS_BASE_DIR)
	for d in dirs:
		var manifest_path = MODS_BASE_DIR.path_join(d).path_join("manifest.json")
		if FileAccess.file_exists(manifest_path):
			import_mod(manifest_path)

func create_mod(id: String, name: String, author: String = "Local Botanist", version: String = "1.0.0", description: String = "") -> ModDefinition:
	var mod = ModDefinition.new(id, name)
	mod.author = author
	mod.version = version
	mod.description = description
	register_mod(mod)
	return mod

func register_mod(mod_def: ModDefinition) -> void:
	if not mod_def or mod_def.id == "": return
	_installed_mods[mod_def.id] = mod_def
	mod_state_changed.emit()

func unregister_mod(mod_id: String) -> void:
	if _installed_mods.has(mod_id):
		_installed_mods.erase(mod_id)
		mod_state_changed.emit()

func enable_mod(mod_id: String) -> bool:
	if _installed_mods.has(mod_id):
		_installed_mods[mod_id].enabled = true
		mod_state_changed.emit()
		return true
	return false

func disable_mod(mod_id: String) -> bool:
	if _installed_mods.has(mod_id):
		_installed_mods[mod_id].enabled = false
		mod_state_changed.emit()
		return true
	return false

func is_mod_enabled(mod_id: String) -> bool:
	return _installed_mods[mod_id].enabled if _installed_mods.has(mod_id) else false

func set_mod_priority(mod_id: String, priority: int) -> bool:
	if _installed_mods.has(mod_id):
		_installed_mods[mod_id].priority = priority
		mod_state_changed.emit()
		return true
	return false

func get_mod(mod_id: String) -> ModDefinition:
	return _installed_mods.get(mod_id, null)

func get_all_mods() -> Array[ModDefinition]:
	var list: Array[ModDefinition] = []
	for m in _installed_mods.values():
		list.append(m)
	return list

func get_active_mods_sorted() -> Array[ModDefinition]:
	var list: Array[ModDefinition] = []
	for m in _installed_mods.values():
		if m.enabled:
			list.append(m)
	list.sort_custom(func(a, b): return a.priority < b.priority)
	return list

func validate_manifest(d: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	
	var id = str(d.get("id", "")).strip_edges()
	if id == "":
		errors.append("Missing required field: id")
	elif not id.is_valid_filename():
		errors.append("Invalid mod id format (must be valid filename/slug): %s" % id)
		
	var name = str(d.get("name", "")).strip_edges()
	if name == "":
		warnings.append("Missing recommended field: name (defaulting to id)")
		
	var version = str(d.get("version", "")).strip_edges()
	if version == "":
		warnings.append("Missing version field (defaulting to 1.0.0)")
		
	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"id": id,
		"name": name if name != "" else id,
		"version": version if version != "" else "1.0.0"
	}

func export_mod(mod_id: String, target_dir: String = MODS_BASE_DIR) -> Dictionary:
	var mod = get_mod(mod_id)
	if not mod:
		return { "success": false, "error": "Mod not found: %s" % mod_id }
		
	var mod_folder = target_dir.path_join(mod.id)
	if not DirAccess.dir_exists_absolute(mod_folder):
		DirAccess.make_dir_recursive_absolute(mod_folder)
		
	var manifest_path = mod_folder.path_join("manifest.json")
	var f = FileAccess.open(manifest_path, FileAccess.WRITE)
	if not f:
		return { "success": false, "error": "Failed to write manifest at %s" % manifest_path }
		
	var json_text = JSON.stringify(mod.to_dict(), "\t")
	f.store_string(json_text)
	f.close()
	
	return { "success": true, "path": manifest_path, "folder": mod_folder }

func export_mod_package(mod_id: String, target_dir: String = MODS_BASE_DIR) -> Dictionary:
	var mod = get_mod(mod_id)
	if not mod:
		return { "success": false, "error": "Mod not found: %s" % mod_id }

	var package_data = {
		"package_format": "BHMOD",
		"format_version": 1,
		"exported_at": Time.get_unix_time_from_system(),
		"manifest": mod.to_dict()
	}

	var pkg_path = target_dir.path_join(mod.id + BHMOD_EXTENSION)
	var f = FileAccess.open(pkg_path, FileAccess.WRITE)
	if not f:
		return export_mod(mod_id, target_dir)

	f.store_string(JSON.stringify(package_data, "\t"))
	f.close()

	return { "success": true, "path": pkg_path, "package": true }

func import_mod_package(source: Variant) -> Dictionary:
	return import_mod(source)

func import_mod(source: Variant) -> Dictionary:
	var d: Dictionary = {}
	if source is Dictionary:
		d = source
	elif source is String:
		var path = str(source)
		if not FileAccess.file_exists(path):
			return { "success": false, "error": "Mod file not found at %s" % path }
		var f = FileAccess.open(path, FileAccess.READ)
		if not f:
			return { "success": false, "error": "Failed to read mod file" }
		var text = f.get_as_text()
		f.close()
		var json = JSON.new()
		if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
			return { "success": false, "error": "Corrupted or invalid JSON manifest/package" }
		
		var raw_dict: Dictionary = json.data
		if raw_dict.has("package_format") and raw_dict.has("manifest"):
			d = raw_dict["manifest"]
		else:
			d = raw_dict
	else:
		return { "success": false, "error": "Invalid source type for mod import" }
		
	var val = validate_manifest(d)
	if not val.valid:
		return { "success": false, "error": "Manifest validation failed", "details": val.errors }
		
	var mod = ModDefinition.from_dict(d)
	register_mod(mod)
	return { "success": true, "mod": mod, "warnings": val.warnings }

func generate_mod_preview(mod: ModDefinition) -> Dictionary:
	if not mod: return {}
	var preview = {
		"id": mod.id,
		"name": mod.name,
		"version": mod.version,
		"author": mod.author,
		"changed_worlds": 0,
		"changed_npcs": 0,
		"changed_dialogues": 0,
		"changed_quests": 0,
		"changed_items": 0,
		"total_overrides": mod.overrides.size() + mod.added_data.size()
	}
	for s_id in mod.overrides.keys():
		if str(s_id).begins_with("world."): preview["changed_worlds"] += 1
		elif str(s_id).begins_with("npc."): preview["changed_npcs"] += 1
		elif str(s_id).begins_with("dialogue."): preview["changed_dialogues"] += 1
		elif str(s_id).begins_with("quest."): preview["changed_quests"] += 1
		elif str(s_id).begins_with("item."): preview["changed_items"] += 1
	return preview

func detect_conflicts() -> Array[Dictionary]:
	var conflicts: Array[Dictionary] = []
	var active_mods = get_active_mods_sorted()
	var seen_properties: Dictionary = {} # "stable_id:property_key" -> [mod_id, ...]

	for m in active_mods:
		for s_id in m.overrides.keys():
			var props = m.overrides[s_id]
			if props is Dictionary:
				for p_k in props.keys():
					var key = "%s:%s" % [s_id, p_k]
					if seen_properties.has(key):
						seen_properties[key].append(m.id)
					else:
						seen_properties[key] = [m.id]

	for k in seen_properties.keys():
		var mods = seen_properties[k]
		if mods.size() > 1:
			var parts = k.split(":")
			conflicts.append({
				"stable_id": parts[0],
				"property_key": parts[1] if parts.size() > 1 else "",
				"competing_mods": mods,
				"winning_mod": mods.back()
			})

	return conflicts
