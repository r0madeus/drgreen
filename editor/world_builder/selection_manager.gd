class_name SelectionManager
extends RefCounted

## Manages single and multi-selection, drag-move deltas, and clipboard for World Builder.

enum SelectionMode { NONE, SINGLE_TILE, SINGLE_OBJECT, MULTI_OBJECT }

signal selection_changed(mode: SelectionMode, selected_items: Array)

var current_mode: SelectionMode = SelectionMode.NONE
var selected_objects: Array = []
var selected_tile: Dictionary = {}
var clipboard: Array = []

func select_single_tile(pos: Vector2i, tile_data: Dictionary) -> void:
	clear_selection(false)
	current_mode = SelectionMode.SINGLE_TILE
	selected_tile = { "position": pos, "tile": tile_data }
	selection_changed.emit(current_mode, [selected_tile])

func set_single_tile(pos: Vector2i, tile_data: Dictionary) -> void:
	select_single_tile(pos, tile_data)

func select_single_object(obj_data: Dictionary) -> void:
	clear_selection(false)
	current_mode = SelectionMode.SINGLE_OBJECT
	selected_objects = [obj_data]
	selection_changed.emit(current_mode, selected_objects)

func set_single_object(obj_data: Dictionary) -> void:
	select_single_object(obj_data)


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

func set_multi_selection(objects: Array) -> void:
	clear_selection(false)
	selected_objects.clear()
	for o in objects:
		selected_objects.append(o)
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

func select_item(item: Dictionary) -> void:
	select_single_object(item)

func is_selected(item: Dictionary) -> bool:
	for o in selected_objects:
		if o.get("instance_id") == item.get("instance_id"):
			return true
	return false

func get_selected_items() -> Array:
	return selected_objects.duplicate()

func move_selected(delta: Vector2i) -> void:
	for o in selected_objects:
		var p = o.get("position", [0, 0])
		o["position"] = [int(p[0]) + delta.x, int(p[1]) + delta.y]

