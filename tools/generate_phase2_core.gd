@tool
extends SceneTree

func _init() -> void:
	generate_phase2()
	quit()

static func generate_phase2() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/prefabs")

	# 1. Generate sample prefab: small_garden.json
	var sample_prefab = {
		"version": 1,
		"name": "Small Garden",
		"id": "small_garden",
		"width": 3,
		"height": 3,
		"tiles": [
			{ "x": 0, "y": 0, "type": "soil", "walkable": true, "solid": false, "interactable": false },
			{ "x": 1, "y": 0, "type": "soil", "walkable": true, "solid": false, "interactable": false },
			{ "x": 2, "y": 0, "type": "soil", "walkable": true, "solid": false, "interactable": false },
			{ "x": 0, "y": 1, "type": "soil", "walkable": true, "solid": false, "interactable": false },
			{ "x": 1, "y": 1, "type": "soil", "walkable": true, "solid": false, "interactable": false },
			{ "x": 2, "y": 1, "type": "soil", "walkable": true, "solid": false, "interactable": false },
			{ "x": 0, "y": 2, "type": "soil", "walkable": true, "solid": false, "interactable": false },
			{ "x": 1, "y": 2, "type": "soil", "walkable": true, "solid": false, "interactable": false },
			{ "x": 2, "y": 2, "type": "soil", "walkable": true, "solid": false, "interactable": false }
		],
		"objects": [
			{ "asset_id": "red_flower", "offset": [1, 1], "layer": "DECORATION", "properties": { "walkable": true, "solid": false, "interactable": true } }
		]
	}
	var f_p = FileAccess.open("res://data/prefabs/small_garden.json", FileAccess.WRITE)
	if f_p:
		f_p.store_string(JSON.stringify(sample_prefab, "  "))
		f_p.close()

	# 2. Update res://editor/world_builder/world_serializer.gd for Version 2 support
	var serializer_code = """class_name WorldSerializer
extends RefCounted

## Handles loading, saving, validation and version migration (v1 -> v2) of world data and prefabs.

const CURRENT_VERSION = 2

static func load_world(filepath: String) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		push_warning("[WorldSerializer] File not found: " + filepath)
		return create_empty_world()
		
	var f = FileAccess.open(filepath, FileAccess.READ)
	if not f:
		push_error("[WorldSerializer] Failed to open: " + filepath)
		return create_empty_world()
		
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_error("[WorldSerializer] Parse error in: " + filepath)
		return create_empty_world()
		
	return migrate_world_data(json.data)

static func save_world(filepath: String, data: Dictionary) -> bool:
	var f = FileAccess.open(filepath, FileAccess.WRITE)
	if not f:
		push_error("[WorldSerializer] Failed to write: " + filepath)
		return false
		
	data["version"] = CURRENT_VERSION
	var text = JSON.stringify(data, "  ")
	f.store_string(text)
	f.close()
	print("[WorldSerializer] World successfully saved (v%d) to: %s" % [CURRENT_VERSION, filepath])
	return true

static func create_empty_world(width: int = 32, height: int = 24) -> Dictionary:
	var tiles = []
	for y in range(height):
		for x in range(width):
			tiles.append({
				"x": x,
				"y": y,
				"type": "grass",
				"layer": "GROUND",
				"walkable": true,
				"solid": false,
				"interactable": false
			})
	return {
		"version": CURRENT_VERSION,
		"name": "New World",
		"width": width,
		"height": height,
		"tile_size": 16,
		"tiles": tiles,
		"objects": [],
		"layers": _get_default_layers()
	}

static func _get_default_layers() -> Array:
	return [
		{ "name": "GROUND", "visible": true, "locked": false },
		{ "name": "TERRAIN", "visible": true, "locked": false },
		{ "name": "DECORATION", "visible": true, "locked": false },
		{ "name": "OBJECT", "visible": true, "locked": false },
		{ "name": "NPC", "visible": true, "locked": false },
		{ "name": "OVERLAY", "visible": true, "locked": false }
	]

static func migrate_world_data(data: Dictionary) -> Dictionary:
	var result = data.duplicate(true)
	var v = int(result.get("version", 1))
	if v < 2:
		result["version"] = 2
		if not result.has("layers"):
			result["layers"] = _get_default_layers()
	if not result.has("width"): result["width"] = 32
	if not result.has("height"): result["height"] = 24
	if not result.has("tile_size"): result["tile_size"] = 16
	if not result.has("tiles"): result["tiles"] = []
	if not result.has("objects"): result["objects"] = []
	return result

static func load_prefab(filepath: String) -> Dictionary:
	if not FileAccess.file_exists(filepath):
		return {}
	var f = FileAccess.open(filepath, FileAccess.READ)
	if not f: return {}
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

static func save_prefab(filepath: String, prefab_data: Dictionary) -> bool:
	var f = FileAccess.open(filepath, FileAccess.WRITE)
	if not f: return false
	f.store_string(JSON.stringify(prefab_data, "  "))
	f.close()
	return true
"""
	var f1 = FileAccess.open("res://editor/world_builder/world_serializer.gd", FileAccess.WRITE)
	if f1: f1.store_string(serializer_code); f1.close()

	# 3. Update res://editor/world_builder/selection_manager.gd for Multi-Selection & Clipboard
	var selection_code = """class_name SelectionManager
extends RefCounted

## Manages single and multi-selection, drag-move deltas, and clipboard for World Builder.

enum SelectionMode { NONE, SINGLE_TILE, SINGLE_OBJECT, MULTI_OBJECT }

signal selection_changed(mode: SelectionMode, selected_items: Array)

var current_mode: SelectionMode = SelectionMode.NONE
var selected_objects: Array[Dictionary] = []
var selected_tile: Dictionary = {}
var clipboard: Array[Dictionary] = []

func select_single_tile(pos: Vector2i, tile_data: Dictionary) -> void:
	clear_selection(false)
	current_mode = SelectionMode.SINGLE_TILE
	selected_tile = { "position": pos, "tile": tile_data }
	selection_changed.emit(current_mode, [selected_tile])

func select_single_object(obj_data: Dictionary) -> void:
	clear_selection(false)
	current_mode = SelectionMode.SINGLE_OBJECT
	selected_objects = [obj_data]
	selection_changed.emit(current_mode, selected_objects)

func toggle_object_selection(obj_data: Dictionary) -> void:
	var idx = -1
	for i in range(selected_objects.size()):
		if selected_objects[i].get("instance_id") == obj_data.get("instance_id"):
			idx = i
			break
			
	if idx >= 0:
		selected_objects.remove_at(idx)
	else:
		selected_objects.append(obj_data)
		
	_update_mode_from_objects()
	selection_changed.emit(current_mode, selected_objects)

func set_multi_selection(objects: Array[Dictionary]) -> void:
	clear_selection(false)
	selected_objects = objects.duplicate()
	_update_mode_from_objects()
	selection_changed.emit(current_mode, selected_objects)

func _update_mode_from_objects() -> void:
	if selected_objects.size() == 0:
		current_mode = SelectionMode.NONE
	elif selected_objects.size() == 1:
		current_mode = SelectionMode.SINGLE_OBJECT
	else:
		current_mode = SelectionMode.MULTI_OBJECT

func clear_selection(notify: bool = true) -> void:
	current_mode = SelectionMode.NONE
	selected_objects.clear()
	selected_tile.clear()
	if notify:
		selection_changed.emit(current_mode, [])

func has_selection() -> bool:
	return current_mode != SelectionMode.NONE

func is_object_selected(instance_id: String) -> bool:
	for o in selected_objects:
		if o.get("instance_id") == instance_id:
			return true
	return false

func copy_to_clipboard() -> int:
	clipboard.clear()
	for o in selected_objects:
		clipboard.append(o.duplicate(true))
	return clipboard.size()
"""
	var f2 = FileAccess.open("res://editor/world_builder/selection_manager.gd", FileAccess.WRITE)
	if f2: f2.store_string(selection_code); f2.close()

	print("[WorldBuilderPhase2Generator] Generated Serializer and SelectionManager!")
