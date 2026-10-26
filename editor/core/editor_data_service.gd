class_name EditorDataService
extends RefCounted

## Central Content Data Service for the Botanical Haven In-Game Editor (Phase 33 Enhanced).
## Maintains strict separation between Content Data (res://data/), Mod Overrides (user://mods/),
## User Editor Overrides (user://editor_overrides.json), Backups (user://editor/backups/), and Player Saves.
## Provides multi-layered resolution, change tracking, backups, migration, atomic saving, and reset operations.

signal dirty_state_changed(is_dirty: bool)
signal data_saved()
signal data_reverted()
signal backup_created(backup_path: String)
signal backup_restored(backup_path: String)

const OVERRIDES_FILE_PATH = "user://editor_overrides.json"
const ACTIVE_PROJECT_PATH = "user://editor/active_project.json"
const BACKUPS_DIR = "user://editor/backups/"
const SCHEMA_VERSION: int = 1
const GAME_VERSION: String = "1.0.0"
const MAX_BACKUPS: int = 10

const GAME_PACKAGE_MGR_SCRIPT = preload("res://core/game_package_manager.gd")

var undo_manager: EditorUndoManager = null
var mod_manager: ModManager = null
var game_package: Variant = null

# In-Memory Overrides: stable_id -> { property_key: value }
var _staged_overrides: Dictionary = {}
var _saved_overrides: Dictionary = {}

# Change tracking log: Array of change records
var _change_log: Array[Dictionary] = []

# Cached Base Content Data loaded from res://data/
var _base_worlds: Dictionary = {}
var _base_npcs: Dictionary = {}
var _base_dialogues: Dictionary = {}
var _base_quests: Dictionary = {}
var _base_items: Dictionary = {}
var _base_plants: Dictionary = {}
var _base_tools: Dictionary = {}
var _base_shops: Dictionary = {}
var _base_schedules: Dictionary = {}
var _base_social: Dictionary = {}
var _base_locations: Dictionary = {}
var _base_rules: Dictionary = {}
var _initialized: bool = false

func _init(p_undo_mgr: EditorUndoManager = null, p_mod_mgr: ModManager = null) -> void:
	undo_manager = p_undo_mgr if p_undo_mgr else EditorUndoManager.new()
	mod_manager = p_mod_mgr if p_mod_mgr else ModManager.new()
	_ensure_directories()
	load_all_base_data()
	load_saved_overrides()

func _ensure_directories() -> void:
	if not DirAccess.dir_exists_absolute("user://editor"):
		DirAccess.make_dir_recursive_absolute("user://editor")
	if not DirAccess.dir_exists_absolute(BACKUPS_DIR):
		DirAccess.make_dir_recursive_absolute(BACKUPS_DIR)

func get_active_game_package() -> Variant:
	if not game_package:
		var pm = GAME_PACKAGE_MGR_SCRIPT.get_instance()
		game_package = pm.get_active_game_package() if pm else null
	return game_package

func reload_for_package(pkg: Variant) -> void:
	game_package = pkg
	_base_worlds.clear()
	_base_npcs.clear()
	_base_dialogues.clear()
	_base_quests.clear()
	_base_items.clear()
	_base_plants.clear()
	_base_tools.clear()
	_base_shops.clear()
	_base_schedules.clear()
	_base_social.clear()
	_base_locations.clear()
	_base_rules.clear()
	_initialized = false
	load_all_base_data()

func load_all_base_data() -> void:
	if _initialized: return
	_load_base_plants_and_items()
	_load_base_tools()
	_load_base_quests()
	_load_base_npcs_and_schedules()
	_load_base_dialogues()
	_load_base_shops()
	_load_base_worlds()
	_load_base_rules()
	_initialized = true

# ==============================================================================
# BASE DATA LOADERS
# ==============================================================================

func _load_json_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return {}
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

func _load_base_plants_and_items() -> void:
	var pkg = get_active_game_package()
	var plants_dir = pkg.content_paths.get("plants", "res://data/plants/") if pkg else "res://data/plants/"
	var base_plants_file = plants_dir + "base_plants.json"
	var d = _load_json_dict(base_plants_file)
	var plant_list = d.get("plants", [])
	for p in plant_list:
		var pid = str(p.get("id", ""))
		if pid != "":
			_base_plants["crop." + pid] = p
			_base_items["item.seed_" + pid] = { "id": "seed_" + pid, "name": p.get("name", pid) + " Seed", "type": "seed" }
			_base_items["item.plant_" + pid] = { "id": "plant_" + pid, "name": p.get("name", pid), "type": "crop" }

func _load_base_tools() -> void:
	var pkg = get_active_game_package()
	var tools_dir = pkg.content_paths.get("tools", "res://data/tools/") if pkg else "res://data/tools/"
	var tools_file = tools_dir + "tools.json"
	var d = _load_json_dict(tools_file)
	var tools_map = d.get("tools", {})
	for tid in tools_map:
		_base_tools["tool." + tid] = tools_map[tid]

func _load_base_quests() -> void:
	var pkg = get_active_game_package()
	var quests_dir = pkg.content_paths.get("quests", "res://data/quests/") if pkg else "res://data/quests/"
	var quests_file = quests_dir + "base_quests.json"
	var d = _load_json_dict(quests_file)
	var q_list = d.get("quests", [])
	for q in q_list:
		var qid = str(q.get("id", ""))
		if qid != "":
			_base_quests["quest." + qid] = q

func _load_base_npcs_and_schedules() -> void:
	var pkg = get_active_game_package()
	var npcs_dir = pkg.content_paths.get("npcs", "res://data/npcs/") if pkg else "res://data/npcs/"
	
	var sched_data = _load_json_dict(npcs_dir + "schedules.json")
	var sched_map = sched_data.get("schedules", {})
	var social_data = _load_json_dict(npcs_dir + "social.json")
	var rel_map = social_data.get("relationships", {})
	var locs_data = _load_json_dict(npcs_dir + "locations.json")
	var locs_map = locs_data.get("locations", {})
	
	for lid in locs_map:
		_base_locations["location." + lid] = locs_map[lid]

	if DirAccess.dir_exists_absolute(npcs_dir):
		var files = DirAccess.get_files_at(npcs_dir)
		for file_name in files:
			if file_name.ends_with(".json") and file_name not in ["locations.json", "schedules.json", "social.json", "preferences.json", "relationships_config.json", "milestones.json"]:
				var n = file_name.get_basename()
				var path = npcs_dir + file_name
				var d = _load_json_dict(path)
				if not d.is_empty():
					_base_npcs["npc." + n] = d
				else:
					_base_npcs["npc." + n] = {
						"id": n,
						"name": n.capitalize(),
						"display_name": n.capitalize(),
						"world": pkg.starting_world if pkg else "farm",
						"role": "villager",
						"interactable": true
					}
					
				if sched_map.has(n):
					_base_schedules["schedule." + n] = sched_map[n]
				elif d.has("schedule"):
					_base_schedules["schedule." + n] = d["schedule"]
					
				if rel_map.has(n):
					_base_social["social." + n] = rel_map[n]

func _load_base_dialogues() -> void:
	var pkg = get_active_game_package()
	var diag_dir = pkg.content_paths.get("dialogue", "res://data/dialogue/") if pkg else "res://data/dialogue/"
	if DirAccess.dir_exists_absolute(diag_dir):
		var files = DirAccess.get_files_at(diag_dir)
		for file_name in files:
			if file_name.ends_with(".json"):
				var did = file_name.get_basename()
				var path = diag_dir + file_name
				var d = _load_json_dict(path)
				if not d.is_empty():
					_base_dialogues["dialogue." + did] = d

func _load_base_shops() -> void:
	var pkg = get_active_game_package()
	var shops_dir = pkg.content_paths.get("shops", "res://data/shops/") if pkg else "res://data/shops/"
	if DirAccess.dir_exists_absolute(shops_dir):
		var files = DirAccess.get_files_at(shops_dir)
		for file_name in files:
			if file_name.ends_with(".json"):
				var sname = file_name.get_basename()
				var path = shops_dir + file_name
				var d = _load_json_dict(path)
				if not d.is_empty():
					_base_shops["shop." + sname] = d

func _load_base_rules() -> void:
	var pkg = get_active_game_package()
	var rules_dir = pkg.content_paths.get("rules", "res://data/rules/") if pkg else "res://data/rules/"
	if DirAccess.dir_exists_absolute(rules_dir):
		var files = DirAccess.get_files_at(rules_dir)
		for file_name in files:
			if file_name.ends_with(".json"):
				var rid = file_name.get_basename()
				var path = rules_dir + file_name
				var d = _load_json_dict(path)
				if not d.is_empty():
					_base_rules["rule." + rid] = d

func _load_base_worlds() -> void:
	var pkg = get_active_game_package()
	var worlds_dir = pkg.content_paths.get("worlds", "res://data/worlds/") if pkg else "res://data/worlds/"
	if DirAccess.dir_exists_absolute(worlds_dir):
		var files = DirAccess.get_files_at(worlds_dir)
		for file_name in files:
			if file_name.ends_with(".json") and file_name != "worlds.json":
				var w = file_name.get_basename()
				var path = worlds_dir + file_name
				var d = _load_json_dict(path)
				if not d.is_empty():
					_base_worlds["world." + w] = d
					
	# Fallback minimal world if package has no worlds on disk
	if _base_worlds.is_empty() and pkg:
		_base_worlds["world." + pkg.starting_world] = {
			"id": pkg.starting_world,
			"display_name": pkg.starting_world.capitalize(),
			"width": 32,
			"height": 24,
			"tiles": [],
			"spawn": [16, 12]
		}

# ==============================================================================
# MULTI-LAYER RESOLUTION API
# ==============================================================================

func get_all_stable_ids(category_prefix: String = "") -> Array[String]:
	var id_set: Dictionary = {}
	var sources = [
		_base_worlds, _base_npcs, _base_dialogues, _base_quests,
		_base_items, _base_plants, _base_tools, _base_shops, _base_schedules, _base_rules,
		_base_social, _base_locations,
		_staged_overrides
	]
	
	if mod_manager:
		for mod in mod_manager.get_active_mods_sorted():
			for m_id in mod.overrides.keys(): id_set[m_id] = true
			for a_id in mod.added_data.keys(): id_set[a_id] = true

	for src in sources:
		for k in src.keys():
			if category_prefix == "" or str(k).begins_with(category_prefix):
				id_set[k] = true

	var sorted_ids: Array[String] = []
	for k in id_set.keys():
		sorted_ids.append(str(k))
	sorted_ids.sort()
	return sorted_ids

func get_base_value(stable_id: String, property_key: String) -> Variant:
	var base_dict = _find_base_dict(stable_id)
	if base_dict.has(property_key):
		return base_dict[property_key]
	return null

func get_resolved_value(stable_id: String, property_key: String) -> Variant:
	# 1. User staged in-memory overrides (Highest Priority)
	if _staged_overrides.has(stable_id) and _staged_overrides[stable_id].has(property_key):
		return _staged_overrides[stable_id][property_key]

	# 2. Active mod overrides in priority order
	if mod_manager:
		var active_mods = mod_manager.get_active_mods_sorted()
		for i in range(active_mods.size() - 1, -1, -1):
			var mod = active_mods[i]
			if mod.overrides.has(stable_id) and mod.overrides[stable_id].has(property_key):
				return mod.overrides[stable_id][property_key]
			if mod.added_data.has(stable_id) and mod.added_data[stable_id].has(property_key):
				return mod.added_data[stable_id][property_key]

	# 3. Base data (Read-Only)
	return get_base_value(stable_id, property_key)

func get_resolved_object(stable_id: String) -> Dictionary:
	var result: Dictionary = _find_base_dict(stable_id).duplicate(true)

	if mod_manager:
		for mod in mod_manager.get_active_mods_sorted():
			if mod.added_data.has(stable_id):
				result.merge(mod.added_data[stable_id], true)
			if mod.overrides.has(stable_id):
				result.merge(mod.overrides[stable_id], true)

	if _staged_overrides.has(stable_id):
		result.merge(_staged_overrides[stable_id], true)

	return result

func has_override(stable_id: String, property_key: String = "") -> bool:
	if not _staged_overrides.has(stable_id): return false
	if property_key == "": return not _staged_overrides[stable_id].is_empty()
	return _staged_overrides[stable_id].has(property_key)

func _find_base_dict(stable_id: String) -> Dictionary:
	if _base_plants.has(stable_id): return _base_plants[stable_id]
	if _base_items.has(stable_id): return _base_items[stable_id]
	if _base_tools.has(stable_id): return _base_tools[stable_id]
	if _base_quests.has(stable_id): return _base_quests[stable_id]
	if _base_npcs.has(stable_id): return _base_npcs[stable_id]
	if _base_schedules.has(stable_id): return _base_schedules[stable_id]
	if _base_social.has(stable_id): return _base_social[stable_id]
	if _base_locations.has(stable_id): return _base_locations[stable_id]
	if _base_dialogues.has(stable_id): return _base_dialogues[stable_id]
	if _base_shops.has(stable_id): return _base_shops[stable_id]
	if _base_worlds.has(stable_id): return _base_worlds[stable_id]
	if _base_rules.has(stable_id): return _base_rules[stable_id]
	return {}

# ==============================================================================
# MUTATIONS & CHANGE TRACKING
# ==============================================================================

func set_staged_override(stable_id: String, property_key: String, new_val: Variant, record_undo: bool = true) -> void:
	var old_val = get_resolved_value(stable_id, property_key)
	if old_val == new_val: return

	if record_undo and undo_manager:
		var action = EditorUndoManager.EditorAction.new(
			"Edit %s.%s" % [stable_id, property_key],
			stable_id,
			property_key,
			old_val,
			new_val,
			Callable(self, "_apply_undo_override")
		)
		undo_manager.push_action(action)

	if not _staged_overrides.has(stable_id):
		_staged_overrides[stable_id] = {}
	_staged_overrides[stable_id][property_key] = new_val

	_change_log.append({
		"stable_id": stable_id,
		"property_key": property_key,
		"old_value": old_val,
		"new_value": new_val,
		"timestamp": Time.get_unix_time_from_system()
	})

	dirty_state_changed.emit(is_dirty())

func _apply_undo_override(stable_id: String, property_key: String, val: Variant) -> void:
	if not _staged_overrides.has(stable_id):
		_staged_overrides[stable_id] = {}
	_staged_overrides[stable_id][property_key] = val
	dirty_state_changed.emit(is_dirty())

func restore_default(stable_id: String, property_key: String = "", record_undo: bool = true) -> void:
	if not _staged_overrides.has(stable_id): return

	if property_key != "":
		var old_val = _staged_overrides[stable_id].get(property_key, null)
		var base_val = get_base_value(stable_id, property_key)
		if record_undo and undo_manager:
			var action = EditorUndoManager.EditorAction.new(
				"Restore %s.%s" % [stable_id, property_key],
				stable_id,
				property_key,
				old_val,
				base_val,
				Callable(self, "_apply_undo_override")
			)
			undo_manager.push_action(action)
		_staged_overrides[stable_id].erase(property_key)
		if property_key == "texture":
			AssetRegistry.remove_texture_override(stable_id)
		if _staged_overrides[stable_id].is_empty():
			_staged_overrides.erase(stable_id)
	else:
		_staged_overrides.erase(stable_id)
		AssetRegistry.remove_texture_override(stable_id)

	dirty_state_changed.emit(is_dirty())

func reset_section(category_prefix: String) -> void:
	var to_erase: Array[String] = []
	for k in _staged_overrides.keys():
		if str(k).begins_with(category_prefix):
			to_erase.append(str(k))
	for k in to_erase:
		_staged_overrides.erase(k)
	dirty_state_changed.emit(is_dirty())

func discard_all_overrides() -> void:
	_staged_overrides.clear()
	_change_log.clear()
	if undo_manager:
		undo_manager.clear()
	dirty_state_changed.emit(is_dirty())

func reset_all_modifications() -> void:
	_staged_overrides.clear()
	_saved_overrides.clear()
	_change_log.clear()
	if FileAccess.file_exists(OVERRIDES_FILE_PATH):
		DirAccess.remove_absolute(OVERRIDES_FILE_PATH)
	if undo_manager: undo_manager.clear()
	AssetRegistry.clear_texture_overrides()
	dirty_state_changed.emit(is_dirty())

func get_pending_reset_diff(target_id_or_prefix: String = "") -> Dictionary:
	var affected: Dictionary = {}
	for s_id in _staged_overrides.keys():
		if target_id_or_prefix == "" or s_id == target_id_or_prefix or str(s_id).begins_with(target_id_or_prefix):
			affected[s_id] = _staged_overrides[s_id].duplicate(true)
	return {
		"target": target_id_or_prefix if target_id_or_prefix != "" else "ALL",
		"affected_count": affected.size(),
		"items": affected
	}

func get_diff_summary() -> Dictionary:
	var summary = {
		"worlds": 0,
		"npcs": 0,
		"dialogues": 0,
		"quests": 0,
		"items": 0,
		"crops": 0,
		"tools": 0,
		"total_overrides": 0
	}
	for s_id in _staged_overrides.keys():
		summary["total_overrides"] += 1
		if str(s_id).begins_with("world."): summary["worlds"] += 1
		elif str(s_id).begins_with("npc."): summary["npcs"] += 1
		elif str(s_id).begins_with("dialogue."): summary["dialogues"] += 1
		elif str(s_id).begins_with("quest."): summary["quests"] += 1
		elif str(s_id).begins_with("item."): summary["items"] += 1
		elif str(s_id).begins_with("crop."): summary["crops"] += 1
		elif str(s_id).begins_with("tool."): summary["tools"] += 1
	return summary

func get_change_count() -> int:
	var count = 0
	for s_id in _staged_overrides.keys():
		count += _staged_overrides[s_id].size()
	return count

func get_change_log() -> Array[Dictionary]:
	return _change_log.duplicate(true)

# ==============================================================================
# PERSISTENCE, BACKUPS & SCHEMA MIGRATION
# ==============================================================================

func is_dirty() -> bool:
	return _staged_overrides != _saved_overrides

func migrate_overrides(data: Dictionary) -> Dictionary:
	var version = int(data.get("schema_version", 1))
	var overrides = data.get("overrides", {}).duplicate(true)
	# Future schema migrations go here
	return overrides

func create_backup() -> String:
	_ensure_directories()
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var backup_file = BACKUPS_DIR.path_join("backup_%s.json" % timestamp)
	
	var data_to_backup = {
		"schema_version": SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"overrides": _staged_overrides
	}
	
	var f = FileAccess.open(backup_file, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data_to_backup, "\t"))
		f.close()
		_rotate_backups()
		backup_created.emit(backup_file)
		return backup_file
	return ""

func list_backups() -> Array[String]:
	_ensure_directories()
	var list: Array[String] = []
	var files = DirAccess.get_files_at(BACKUPS_DIR)
	for fname in files:
		if fname.ends_with(".json") and fname.begins_with("backup_"):
			list.append(BACKUPS_DIR.path_join(fname))
	list.sort()
	list.reverse()
	return list

func _rotate_backups() -> void:
	var backups = list_backups()
	while backups.size() > MAX_BACKUPS:
		var oldest = backups.pop_back()
		DirAccess.remove_absolute(oldest)

func restore_backup(backup_path: String) -> bool:
	if not FileAccess.file_exists(backup_path): return false
	var f = FileAccess.open(backup_path, FileAccess.READ)
	if not f: return false
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false
		
	var d: Dictionary = json.data
	_staged_overrides = migrate_overrides(d)
	dirty_state_changed.emit(is_dirty())
	backup_restored.emit(backup_path)
	return true

func save_overrides(filepath: String = OVERRIDES_FILE_PATH) -> bool:
	create_backup() # Auto-backup on save

	var data_to_save = {
		"schema_version": SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"overrides": _staged_overrides
	}
	var json_str = JSON.stringify(data_to_save, "\t")

	# Atomic write: write to .tmp first, then rename
	var tmp_path = filepath + ".tmp"
	var f = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not f:
		push_error("[EditorDataService] Failed to open temporary file for writing: " + tmp_path)
		return false

	f.store_string(json_str)
	f.close()

	if FileAccess.file_exists(filepath):
		DirAccess.remove_absolute(filepath)
	var err = DirAccess.rename_absolute(tmp_path, filepath)
	if err != OK:
		push_error("[EditorDataService] Failed to rename temp file to: %s (Error %d)" % [filepath, err])
		return false

	_saved_overrides = _staged_overrides.duplicate(true)
	AssetRegistry.sync_with_data_service(self)
	data_saved.emit()
	dirty_state_changed.emit(false)
	return true

func load_saved_overrides(filepath: String = OVERRIDES_FILE_PATH) -> bool:
	if not FileAccess.file_exists(filepath):
		_saved_overrides = {}
		_staged_overrides = {}
		return false

	var f = FileAccess.open(filepath, FileAccess.READ)
	if not f: return false
	var text = f.get_as_text()
	f.close()

	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("[EditorDataService] Corrupted overrides file at: " + filepath)
		return false

	var d: Dictionary = json.data
	_saved_overrides = migrate_overrides(d)
	_staged_overrides = _saved_overrides.duplicate(true)
	AssetRegistry.sync_with_data_service(self)
	data_reverted.emit()
	dirty_state_changed.emit(false)
	return true

func discard_changes() -> void:
	_staged_overrides = _saved_overrides.duplicate(true)
	if undo_manager: undo_manager.clear()
	data_reverted.emit()
	dirty_state_changed.emit(false)


# ==============================================================================
# AUTHORING & ENTITY CREATION API (Phase 36)
# ==============================================================================

func create_world(world_id: String, display_name: String = "", width: int = 32, height: int = 24, background: String = "dirt", spawn_pos: Array = [10, 10]) -> Dictionary:
	var clean_id = world_id.strip_edges().to_lower().replace(" ", "_").trim_prefix("world.")
	if clean_id == "": clean_id = "world_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	
	var w_data = {
		"id": clean_id,
		"display_name": display_name if display_name != "" else clean_id.capitalize().replace("_", " "),
		"width": width,
		"height": height,
		"tile_size": 16,
		"background": background,
		"spawn_point": spawn_pos,
		"tiles": [],
		"layers": {
			"ground": [],
			"decor": [],
			"collision": []
		},
		"entities": []
	}
	
	create_entity("world." + clean_id, w_data)
	return w_data

func create_entity(stable_id: String, initial_data: Dictionary, record_undo: bool = true) -> bool:
	if stable_id == "": return false
	
	var old_val = _staged_overrides.get(stable_id, null)
	if not _staged_overrides.has(stable_id):
		_staged_overrides[stable_id] = {}
		
	for k in initial_data.keys():
		_staged_overrides[stable_id][k] = initial_data[k]
		
	if record_undo and undo_manager:
		var action = EditorUndoManager.EditorAction.new(
			"Create entity %s" % stable_id,
			stable_id,
			"",
			old_val,
			initial_data.duplicate(true),
			Callable(self, "_apply_undo_entity_creation")
		)
		undo_manager.push_action(action)
		
	dirty_state_changed.emit(is_dirty())
	return true

func _apply_undo_entity_creation(stable_id: String, _prop_key: String, target_val: Variant) -> void:
	if target_val == null or (target_val is Dictionary and target_val.is_empty()):
		_staged_overrides.erase(stable_id)
	elif target_val is Dictionary:
		_staged_overrides[stable_id] = target_val.duplicate(true)
	dirty_state_changed.emit(is_dirty())

func delete_entity(stable_id: String, record_undo: bool = true) -> bool:
	if not _staged_overrides.has(stable_id): return false
	var old_val = _staged_overrides[stable_id].duplicate(true)
	_staged_overrides.erase(stable_id)
	
	if record_undo and undo_manager:
		var action = EditorUndoManager.EditorAction.new(
			"Delete entity %s" % stable_id,
			stable_id,
			"",
			old_val,
			null,
			Callable(self, "_apply_undo_entity_creation")
		)
		undo_manager.push_action(action)
		
	dirty_state_changed.emit(is_dirty())
	return true

## Synchronizes all staged and active mod data with gameplay singletons/managers for Playtest
func apply_to_gameplay_managers() -> void:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if not root: return
	
	# 1. Sync NPCs
	var npc_mgr = root.get_node_or_null("/root/NPCManager")
	if npc_mgr and "npcs_catalog" in npc_mgr:
		for sid in get_all_stable_ids("npc."):
			var n_id = sid.replace("npc.", "")
			var obj = get_resolved_object(sid)
			npc_mgr.npcs_catalog[n_id] = obj
			
	# 2. Sync Quests
	var quest_mgr = root.get_node_or_null("/root/QuestManager")
	if quest_mgr and "quests" in quest_mgr:
		for sid in get_all_stable_ids("quest."):
			var q_id = sid.replace("quest.", "")
			var obj = get_resolved_object(sid)
			var found_idx = -1
			for i in range(quest_mgr.quests.size()):
				if str(quest_mgr.quests[i].get("id", "")) == q_id:
					found_idx = i
					break
			if found_idx >= 0:
				quest_mgr.quests[found_idx] = obj
			else:
				quest_mgr.quests.append(obj)
				
	# 3. Sync Dialogues
	var diag_mgr = root.get_node_or_null("/root/DialogueManager")
	if diag_mgr and "dialogue_catalog" in diag_mgr:
		for sid in get_all_stable_ids("dialogue."):
			var d_id = sid.replace("dialogue.", "")
			var obj = get_resolved_object(sid)
			diag_mgr.dialogue_catalog[d_id] = obj
			
	# 4. Sync Plants / Crops
	var plant_mgr = root.get_node_or_null("/root/PlantManager")
	if plant_mgr and "plants_database" in plant_mgr:
		for sid in get_all_stable_ids("crop."):
			var p_id = sid.replace("crop.", "")
			var obj = get_resolved_object(sid)
			plant_mgr.plants_database[p_id] = obj
			
	# 5. Sync World definitions
	var world_mgr = root.get_node_or_null("/root/WorldManager")
	if world_mgr and "world_definitions" in world_mgr:
		for sid in get_all_stable_ids("world."):
			var w_id = sid.replace("world.", "")
			var obj = get_resolved_object(sid)
			if world_mgr.world_definitions.has(w_id) and world_mgr.world_definitions[w_id] is WorldDefinition:
				var existing_def: WorldDefinition = world_mgr.world_definitions[w_id]
				if obj.has("display_name"): existing_def.display_name = str(obj["display_name"])
				if obj.has("width"): existing_def.width = int(obj["width"])
				if obj.has("height"): existing_def.height = int(obj["height"])
				if obj.has("spawn_points"): existing_def.spawn_points = obj["spawn_points"]
				if obj.has("connections") and not obj["connections"].is_empty(): existing_def.connections = obj["connections"]
			else:
				world_mgr.world_definitions[w_id] = WorldDefinition.from_dict(w_id, obj)
			
	# 6. Sync Visual Textures
	AssetRegistry.sync_with_data_service(self)
