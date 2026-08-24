class_name GamePackageManager
extends RefCounted

## Central Game Package Management & Discovery Service (Phase 38 & 40).
## Discovers, loads, validates, creates, exports, imports, and manages active Game Packages.

const GAME_PACKAGE_SCRIPT = preload("res://core/game_package.gd")

signal active_package_changed(package_id: String, package: Variant)
signal package_installed(package_id: String)
signal package_unloaded(package_id: String)

const RES_GAMES_DIR = "res://games/"
const USER_GAMES_DIR = "user://games/"
const USER_EXPORTS_DIR = "user://exports/"
const DEFAULT_GAME_ID = "botanical_haven"

static var _instance: Variant = null

var _installed_packages: Dictionary = {} # game_id -> GamePackage
var active_game_package: Variant = null

static func get_instance() -> Variant:
	if not _instance:
		_instance = (load("res://core/game_package_manager.gd") as GDScript).new()
	return _instance

func _init() -> void:
	_ensure_directories()
	scan_installed_packages()
	if not load_game_package(DEFAULT_GAME_ID):
		active_game_package = _create_official_botanical_haven_package()
		_installed_packages[DEFAULT_GAME_ID] = active_game_package

func _ensure_directories() -> void:
	if not DirAccess.dir_exists_absolute(USER_GAMES_DIR):
		DirAccess.make_dir_recursive_absolute(USER_GAMES_DIR)
	if not DirAccess.dir_exists_absolute(USER_EXPORTS_DIR):
		DirAccess.make_dir_recursive_absolute(USER_EXPORTS_DIR)

func scan_installed_packages() -> void:
	_installed_packages.clear()
	
	# 1. Scan res://games/
	if DirAccess.dir_exists_absolute(RES_GAMES_DIR):
		var dirs = DirAccess.get_directories_at(RES_GAMES_DIR)
		for d in dirs:
			var path = RES_GAMES_DIR + d + "/game.json"
			var pkg = _load_package_from_file(path)
			if pkg:
				_installed_packages[pkg.game_id] = pkg
				
	# 2. Scan user://games/
	if DirAccess.dir_exists_absolute(USER_GAMES_DIR):
		var dirs = DirAccess.get_directories_at(USER_GAMES_DIR)
		for d in dirs:
			var path = USER_GAMES_DIR + d + "/game.json"
			var pkg = _load_package_from_file(path)
			if pkg:
				_installed_packages[pkg.game_id] = pkg
				
	# Ensure official package is present
	if not _installed_packages.has(DEFAULT_GAME_ID):
		var official = _create_official_botanical_haven_package()
		_installed_packages[DEFAULT_GAME_ID] = official

func _load_package_from_file(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return null
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		var pkg_script = ResourceLoader.load("res://core/game_package.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
		return pkg_script.from_dict(json.data) if pkg_script else GAME_PACKAGE_SCRIPT.from_dict(json.data)
	return null

func _create_official_botanical_haven_package() -> Variant:
	var pkg = (load("res://core/game_package.gd") as GDScript).new()
	pkg.game_id = "botanical_haven"
	pkg.name = "Botanical Haven"
	pkg.version = "1.0.0"
	pkg.author = "Botanical Team"
	pkg.description = "The official Botanical Haven farming and social adventure game."
	pkg.starting_world = "farm"
	pkg.content_paths = {
		"worlds": "res://data/worlds/",
		"npcs": "res://data/npcs/",
		"dialogue": "res://data/dialogue/",
		"quests": "res://data/quests/",
		"plants": "res://data/plants/",
		"tools": "res://data/tools/",
		"shops": "res://data/shops/",
		"rules": "res://data/rules/",
		"assets": "res://assets/"
	}
	return pkg

func _create_empty_template_package(p_id: String, p_name: String, p_author: String = "Author", p_version: String = "1.0.0", p_desc: String = "") -> Variant:
	var pkg = (load("res://core/game_package.gd") as GDScript).new()
	pkg.game_id = p_id
	pkg.name = p_name if p_name != "" else p_id.capitalize()
	pkg.author = p_author
	pkg.version = p_version
	pkg.description = p_desc if p_desc != "" else "A custom game package built on the Botanical Haven Engine."
	pkg.starting_world = "main"
	pkg.content_paths = {
		"worlds": USER_GAMES_DIR + p_id + "/worlds/",
		"npcs": USER_GAMES_DIR + p_id + "/npcs/",
		"dialogue": USER_GAMES_DIR + p_id + "/dialogue/",
		"quests": USER_GAMES_DIR + p_id + "/quests/",
		"items": USER_GAMES_DIR + p_id + "/items/",
		"plants": USER_GAMES_DIR + p_id + "/plants/",
		"tools": USER_GAMES_DIR + p_id + "/tools/",
		"shops": USER_GAMES_DIR + p_id + "/shops/",
		"rules": USER_GAMES_DIR + p_id + "/rules/",
		"assets": USER_GAMES_DIR + p_id + "/assets/"
	}
	return pkg

func get_active_game_package() -> Variant:
	if not active_game_package:
		active_game_package = _create_official_botanical_haven_package()
	return active_game_package

func get_active_game_id() -> String:
	return get_active_game_package().game_id

func load_game_package(package_id: String) -> bool:
	if package_id == "": return false
	if _installed_packages.has(package_id):
		active_game_package = _installed_packages[package_id]
		active_package_changed.emit(package_id, active_game_package)
		return true
		
	var user_path = USER_GAMES_DIR + package_id + "/game.json"
	var pkg = _load_package_from_file(user_path)
	if not pkg:
		var res_path = RES_GAMES_DIR + package_id + "/game.json"
		pkg = _load_package_from_file(res_path)
		
	if pkg:
		_installed_packages[package_id] = pkg
		active_game_package = pkg
		active_package_changed.emit(package_id, active_game_package)
		return true
		
	return false

func unload_game_package() -> void:
	if active_game_package:
		var old_id = active_game_package.game_id
		active_game_package = null
		package_unloaded.emit(old_id)

func reload_active_game_package() -> bool:
	var cur_id = get_active_game_id()
	unload_game_package()
	return load_game_package(cur_id)

func get_available_game_packages() -> Array:
	return _installed_packages.values()

func is_game_package_installed(package_id: String) -> bool:
	return _installed_packages.has(package_id)

func create_game_package(game_id: String, display_name: String, template_type: String = "empty", author: String = "Author", version: String = "1.0.0", description: String = "") -> Variant:
	var clean_id = game_id.strip_edges().to_lower().replace(" ", "_")
	if clean_id == "": clean_id = "custom_game_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	
	var pkg = _create_empty_template_package(clean_id, display_name, author, version, description)
	_installed_packages[clean_id] = pkg
	
	var pkg_dir = USER_GAMES_DIR + clean_id + "/"
	DirAccess.make_dir_recursive_absolute(pkg_dir)
	for sub in ["worlds", "npcs", "dialogue", "quests", "items", "plants", "tools", "shops", "rules", "assets"]:
		DirAccess.make_dir_recursive_absolute(pkg_dir + sub + "/")
		
	var f = FileAccess.open(pkg_dir + "game.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(pkg.to_dict(), "  "))
		f.close()
		
	package_installed.emit(clean_id)
	return pkg

func export_game_package(game_id: String, target_dir: String = USER_EXPORTS_DIR) -> String:
	if not _installed_packages.has(game_id):
		load_game_package(game_id)
	var pkg = _installed_packages.get(game_id, null)
	if not pkg: return ""
	
	if not DirAccess.dir_exists_absolute(target_dir):
		DirAccess.make_dir_recursive_absolute(target_dir)
		
	var export_path = target_dir + game_id + ".bhgame"
	var content_data: Dictionary = {
		"worlds": {},
		"npcs": {},
		"dialogue": {},
		"quests": {},
		"items": {},
		"rules": {}
	}
	
	# Gather all JSON files from content paths
	for cat in content_data:
		var dir_path = pkg.content_paths.get(cat, "")
		if dir_path != "" and DirAccess.dir_exists_absolute(dir_path):
			var files = DirAccess.get_files_at(dir_path)
			for fname in files:
				if fname.ends_with(".json"):
					var entry_id = fname.get_basename()
					var f = FileAccess.open(dir_path + fname, FileAccess.READ)
					if f:
						var parsed = JSON.parse_string(f.get_as_text())
						f.close()
						if parsed != null:
							content_data[cat][entry_id] = parsed
							
	var package_bundle = {
		"format": "bhgame",
		"format_version": 1,
		"exported_at": Time.get_unix_time_from_system(),
		"manifest": pkg.to_dict(),
		"content": content_data
	}
	
	var out_file = FileAccess.open(export_path, FileAccess.WRITE)
	if out_file:
		out_file.store_string(JSON.stringify(package_bundle, "  "))
		out_file.close()
		return export_path
		
	return ""

func import_game_package(bhgame_path: String) -> Variant:
	if not FileAccess.file_exists(bhgame_path): return null
	var f = FileAccess.open(bhgame_path, FileAccess.READ)
	if not f: return null
	var text = f.get_as_text()
	f.close()
	
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary): return null
	
	var manifest_data = parsed.get("manifest", {})
	var target_game_id = str(manifest_data.get("game_id", ""))
	if target_game_id == "": return null
	
	var pkg_dir = USER_GAMES_DIR + target_game_id + "/"
	DirAccess.make_dir_recursive_absolute(pkg_dir)
	
	# Write game.json
	var manifest_file = FileAccess.open(pkg_dir + "game.json", FileAccess.WRITE)
	if manifest_file:
		manifest_file.store_string(JSON.stringify(manifest_data, "  "))
		manifest_file.close()
		
	# Unpack content
	var content_data = parsed.get("content", {})
	for cat in content_data:
		var cat_dir = pkg_dir + cat + "/"
		DirAccess.make_dir_recursive_absolute(cat_dir)
		var items = content_data[cat]
		if items is Dictionary:
			for item_id in items:
				var item_file = FileAccess.open(cat_dir + item_id + ".json", FileAccess.WRITE)
				if item_file:
					item_file.store_string(JSON.stringify(items[item_id], "  "))
					item_file.close()
					
	# Reload and register
	var pkg_script = ResourceLoader.load("res://core/game_package.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var loaded_pkg = pkg_script.from_dict(manifest_data) if pkg_script else GAME_PACKAGE_SCRIPT.from_dict(manifest_data)
	
	# Ensure content paths point to user dir
	loaded_pkg.content_paths = {
		"worlds": pkg_dir + "worlds/",
		"npcs": pkg_dir + "npcs/",
		"dialogue": pkg_dir + "dialogue/",
		"quests": pkg_dir + "quests/",
		"items": pkg_dir + "items/",
		"plants": pkg_dir + "plants/",
		"tools": pkg_dir + "tools/",
		"shops": pkg_dir + "shops/",
		"rules": pkg_dir + "rules/",
		"assets": pkg_dir + "assets/"
	}
	
	_installed_packages[target_game_id] = loaded_pkg
	package_installed.emit(target_game_id)
	return loaded_pkg

func duplicate_game_package(source_id: String, new_id: String, new_name: String) -> Variant:
	if not _installed_packages.has(source_id):
		load_game_package(source_id)
	var src_pkg = _installed_packages.get(source_id, null)
	if not src_pkg: return null
	
	var exported_path = export_game_package(source_id)
	if exported_path == "": return null
	
	# Read exported bundle and mutate manifest
	var f = FileAccess.open(exported_path, FileAccess.READ)
	if not f: return null
	var bundle = JSON.parse_string(f.get_as_text())
	f.close()
	
	bundle["manifest"]["game_id"] = new_id
	bundle["manifest"]["name"] = new_name
	
	var temp_clone_path = USER_EXPORTS_DIR + new_id + "_temp.bhgame"
	var out = FileAccess.open(temp_clone_path, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(bundle, "  "))
		out.close()
		var cloned_pkg = import_game_package(temp_clone_path)
		DirAccess.remove_absolute(temp_clone_path)
		return cloned_pkg
		
	return null

func delete_game_package(game_id: String) -> bool:
	if game_id == DEFAULT_GAME_ID or game_id == "": return false
	
	var pkg_dir = USER_GAMES_DIR + game_id + "/"
	if DirAccess.dir_exists_absolute(pkg_dir):
		_recursive_delete_dir(pkg_dir)
		
	_installed_packages.erase(game_id)
	if active_game_package and active_game_package.game_id == game_id:
		load_game_package(DEFAULT_GAME_ID)
		
	package_unloaded.emit(game_id)
	return true

func reset_game_package(game_id: String) -> bool:
	if game_id == "": return false
	# Re-create clean template directories
	var pkg_dir = USER_GAMES_DIR + game_id + "/"
	if DirAccess.dir_exists_absolute(pkg_dir):
		_recursive_delete_dir(pkg_dir)
		create_game_package(game_id, game_id.capitalize())
		return true
	return false

func get_package_summary(game_id: String) -> Dictionary:
	if not _installed_packages.has(game_id):
		load_game_package(game_id)
	var pkg = _installed_packages.get(game_id, null)
	if not pkg: return {}
	
	var counts = {
		"game_id": pkg.game_id,
		"name": pkg.name,
		"version": pkg.version,
		"author": pkg.author,
		"description": pkg.description,
		"worlds": 0,
		"entities": 0,
		"items": 0,
		"dialogues": 0,
		"quests": 0,
		"rules": 0,
		"assets": 0,
		"validation": "VALID"
	}
	
	for cat in ["worlds", "npcs", "items", "dialogue", "quests", "rules"]:
		var p = pkg.content_paths.get(cat, "")
		if p != "" and DirAccess.dir_exists_absolute(p):
			var files = DirAccess.get_files_at(p)
			var json_count = 0
			for f in files:
				if f.ends_with(".json"): json_count += 1
			if cat == "npcs": counts["entities"] = json_count
			elif cat == "dialogue": counts["dialogues"] = json_count
			elif cat == "rules": counts["rules"] = json_count
			elif cat == "worlds": counts["worlds"] = json_count
			elif cat == "items": counts["items"] = json_count
			elif cat == "quests": counts["quests"] = json_count
			
	return counts

func _recursive_delete_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path): return
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." and file_name != "..":
				var full = path + ("/" if not path.ends_with("/") else "") + file_name
				if dir.current_is_dir():
					_recursive_delete_dir(full)
				else:
					DirAccess.remove_absolute(full)
			file_name = dir.get_next()
		dir.list_dir_end()
		DirAccess.remove_absolute(path)

func validate_game_package(pkg: Variant) -> Dictionary:
	if not pkg: return { "valid": false, "errors": ["Package is null"] }
	if pkg.has_method("validate"):
		return pkg.validate()
	return { "valid": true, "errors": [] }
