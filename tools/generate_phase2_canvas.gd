@tool
extends SceneTree

func _init() -> void:
	generate_core()
	quit()

static func generate_core() -> void:
	# 1. world_canvas.gd
	var canvas_code = """class_name WorldCanvas
extends Control

## Central 2D viewport with drag-move, multi-select box, camera framing, copy/paste and layer filtering.

enum ToolMode { SELECT, BRUSH, ERASER, RECTANGLE, FILL }

signal hover_coord_changed(coord: Vector2i)
signal map_modified()
signal status_updated(info: Dictionary)

var current_tool: ToolMode = ToolMode.BRUSH
var show_grid_lines: bool = true
var show_collision_debug: bool = false
var show_coordinates: bool = false
var zoom_level: float = 1.5
var pan_offset: Vector2 = Vector2(40, 40)

var world_data: Dictionary = {}
var hovered_tile: Vector2i = Vector2i(-1, -1)
var is_middle_panning: bool = false
var pan_start_pos: Vector2 = Vector2.ZERO

var rect_drag_start: Vector2i = Vector2i(-1, -1)
var is_rect_dragging: bool = false

# Phase 2: Drag Move & Multi-select Box
var is_dragging_objects: bool = false
var drag_start_coord: Vector2i = Vector2i(-1, -1)
var is_box_selecting: bool = false
var box_select_start: Vector2i = Vector2i(-1, -1)
var box_select_end: Vector2i = Vector2i(-1, -1)

var history: EditorHistory
var selection: SelectionManager
var palette: AssetPalette
var active_layer_name: String = "TERRAIN"

func _ready() -> void:
	set_process_unhandled_input(true)
	custom_minimum_size = Vector2(600, 500)

func setup(p_data: Dictionary, p_history: EditorHistory, p_selection: SelectionManager, p_palette: AssetPalette) -> void:
	world_data = p_data
	history = p_history
	selection = p_selection
	palette = p_palette
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	# Keyboard Shortcuts
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			delete_selection()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_C and (event.ctrl_pressed or event.meta_pressed):
			copy_selection()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_V and (event.ctrl_pressed or event.meta_pressed):
			paste_clipboard(hovered_tile if _is_valid_coord(hovered_tile) else Vector2i(10, 10))
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_D and (event.ctrl_pressed or event.meta_pressed):
			duplicate_selection()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_A and (event.ctrl_pressed or event.meta_pressed):
			select_all_in_layer(active_layer_name)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_F:
			focus_selection()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_HOME:
			fit_to_screen()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_1:
			zoom_level = 1.0
			queue_redraw()
			get_viewport().set_input_as_handled()
			return

	# Mouse Controls
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			var step = 0.05 if (event.ctrl_pressed or event.meta_pressed) else 0.15
			zoom_level = clampf(zoom_level + step, 0.5, 3.5)
			_emit_status()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			var step = 0.05 if (event.ctrl_pressed or event.meta_pressed) else 0.15
			zoom_level = clampf(zoom_level - step, 0.5, 3.5)
			_emit_status()
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_middle_panning = event.pressed
			pan_start_pos = event.position
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_left_click_down(hovered_tile, event.shift_pressed)
			else:
				_on_left_click_up(hovered_tile)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_on_right_click(hovered_tile)
			get_viewport().set_input_as_handled()
			
	elif event is InputEventMouseMotion:
		if is_middle_panning:
			pan_offset += event.relative
			queue_redraw()
		else:
			var mouse_pos = event.position
			var local_pos = (mouse_pos - pan_offset) / zoom_level
			var tile_coord = Vector2i(int(floor(local_pos.x / 16.0)), int(floor(local_pos.y / 16.0)))
			
			if tile_coord != hovered_tile:
				hovered_tile = tile_coord
				hover_coord_changed.emit(hovered_tile)
				_emit_status()
				
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
					if current_tool == ToolMode.BRUSH:
						_paint_tile(hovered_tile)
					elif current_tool == ToolMode.ERASER:
						_erase_at(hovered_tile)
					elif is_box_selecting:
						box_select_end = hovered_tile
				queue_redraw()

func _on_left_click_down(pos: Vector2i, is_shift: bool) -> void:
	if not _is_valid_coord(pos):
		return
		
	match current_tool:
		ToolMode.SELECT:
			var obj = _get_object_at(pos)
			if not obj.is_empty():
				if is_shift and selection:
					selection.toggle_object_selection(obj)
				else:
					if selection and not selection.is_object_selected(obj.get("instance_id", "")):
						selection.select_single_object(obj)
					is_dragging_objects = true
					drag_start_coord = pos
			else:
				if is_shift:
					is_box_selecting = true
					box_select_start = pos
					box_select_end = pos
				else:
					var t = _get_tile_at(pos)
					if selection: selection.select_single_tile(pos, t)
					is_box_selecting = true
					box_select_start = pos
					box_select_end = pos
		ToolMode.BRUSH:
			_paint_tile(pos)
		ToolMode.ERASER:
			_erase_at(pos)
		ToolMode.RECTANGLE:
			rect_drag_start = pos
			is_rect_dragging = true
		ToolMode.FILL:
			_flood_fill(pos)
			
	_emit_status()
	queue_redraw()

func _on_left_click_up(pos: Vector2i) -> void:
	if is_rect_dragging and current_tool == ToolMode.RECTANGLE:
		is_rect_dragging = false
		_paint_rect(rect_drag_start, pos)
		rect_drag_start = Vector2i(-1, -1)
	elif is_box_selecting:
		is_box_selecting = false
		_commit_box_selection(box_select_start, box_select_end)
		box_select_start = Vector2i(-1, -1)
	elif is_dragging_objects:
		is_dragging_objects = false
		var delta = pos - drag_start_coord
		if delta != Vector2i.ZERO:
			_commit_drag_move(delta)
		drag_start_coord = Vector2i(-1, -1)
		
	_emit_status()
	queue_redraw()

func _commit_drag_move(delta: Vector2i) -> void:
	if not selection or selection.selected_objects.is_empty():
		return
		
	var moved_records = []
	for o in selection.selected_objects:
		var p = o.get("position", [0, 0])
		var old_p = [p[0], p[1]]
		var new_p = [p[0] + delta.x, p[1] + delta.y]
		o["position"] = new_p
		moved_records.append({ "object": o, "old_pos": old_p, "new_pos": new_p })
		
	if history:
		history.push_action({
			"type": "MULTI_OBJECT_MOVE",
			"records": moved_records
		})
		
	map_modified.emit()

func _commit_box_selection(p_start: Vector2i, p_end: Vector2i) -> void:
	var min_x = mini(p_start.x, p_end.x)
	var max_x = maxi(p_start.x, p_end.x)
	var min_y = mini(p_start.y, p_end.y)
	var max_y = maxi(p_start.y, p_end.y)
	
	var found: Array[Dictionary] = []
	for o in world_data.get("objects", []):
		var p = o.get("position", [-1, -1])
		if p[0] >= min_x and p[0] <= max_x and p[1] >= min_y and p[1] <= max_y:
			found.append(o)
			
	if selection:
		selection.set_multi_selection(found)

func _on_right_click(pos: Vector2i) -> void:
	if not _is_valid_coord(pos):
		return
	_erase_at(pos)
	queue_redraw()

func _paint_tile(pos: Vector2i) -> void:
	if not _is_valid_coord(pos) or not palette:
		return
	var asset = palette.selected_asset
	if asset.is_empty():
		return
		
	var asset_type = asset.get("type", "tile")
	var target_layer = asset.get("layer", active_layer_name)
	if _is_layer_locked(target_layer):
		print("[WorldCanvas] Cannot paint: Layer %s is locked!" % target_layer)
		return
		
	if asset_type == "tile":
		var old_tile = _get_tile_at(pos).duplicate(true)
		var new_type = asset["id"]
		var walkable = bool(asset.get("walkable", true))
		var solid = bool(asset.get("solid", false))
		var interactable = bool(asset.get("interactable", false))
		
		for t in world_data.get("tiles", []):
			if t["x"] == pos.x and t["y"] == pos.y:
				t["type"] = new_type
				t["walkable"] = walkable
				t["solid"] = solid
				t["interactable"] = interactable
				t["layer"] = target_layer
				break
				
		if history:
			history.push_action({
				"type": "TILE_PAINT",
				"pos": pos,
				"old_tile": old_tile,
				"new_type": new_type
			})
			
	elif asset_type == "object" or asset_type == "plant" or asset_type == "npc":
		var inst_id = _generate_unique_id(asset["id"])
		_remove_object_at(pos)
		
		var obj = {
			"instance_id": inst_id,
			"asset_id": asset["id"],
			"name": asset.get("name", asset["id"]),
			"position": [pos.x, pos.y],
			"layer": target_layer,
			"properties": {
				"walkable": asset.get("walkable", false),
				"solid": asset.get("solid", true),
				"interactable": asset.get("interactable", true)
			}
		}
		world_data.get("objects", []).append(obj)
		
		if history:
			history.push_action({
				"type": "OBJECT_PLACE",
				"object": obj
			})
			
	elif asset_type == "prefab":
		_place_prefab(asset.get("prefab_data", {}), pos)
		
	map_modified.emit()
	queue_redraw()

func _place_prefab(p_data: Dictionary, base_pos: Vector2i) -> void:
	if p_data.is_empty():
		return
		
	for t in p_data.get("tiles", []):
		var target_p = base_pos + Vector2i(int(t.get("x", 0)), int(t.get("y", 0)))
		if _is_valid_coord(target_p):
			for world_t in world_data.get("tiles", []):
				if world_t["x"] == target_p.x and world_t["y"] == target_p.y:
					world_t["type"] = t.get("type", "soil")
					world_t["walkable"] = t.get("walkable", true)
					world_t["solid"] = t.get("solid", false)
					break
					
	for o in p_data.get("objects", []):
		var off = o.get("offset", [0, 0])
		var target_p = base_pos + Vector2i(off[0], off[1])
		if _is_valid_coord(target_p):
			var aid = o.get("asset_id", "red_flower")
			var obj = {
				"instance_id": _generate_unique_id(aid),
				"asset_id": aid,
				"name": aid.capitalize(),
				"position": [target_p.x, target_p.y],
				"layer": o.get("layer", "DECORATION"),
				"properties": o.get("properties", { "walkable": true, "solid": false, "interactable": true })
			}
			world_data.get("objects", []).append(obj)

func _generate_unique_id(prefix: String) -> String:
	var count = 1
	var existing = {}
	for o in world_data.get("objects", []):
		existing[o.get("instance_id", "")] = true
	var candidate = "%s_%02d" % [prefix, count]
	while existing.has(candidate):
		count += 1
		candidate = "%s_%02d" % [prefix, count]
	return candidate

func _paint_rect(p_start: Vector2i, p_end: Vector2i) -> void:
	var min_x = mini(p_start.x, p_end.x)
	var max_x = maxi(p_start.x, p_end.x)
	var min_y = mini(p_start.y, p_end.y)
	var max_y = maxi(p_start.y, p_end.y)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			_paint_tile(Vector2i(x, y))

func _flood_fill(start_pos: Vector2i) -> void:
	if not _is_valid_coord(start_pos) or not palette:
		return
	var target_type = _get_tile_at(start_pos).get("type", "")
	var new_type = palette.selected_asset.get("id", "")
	if target_type == new_type or new_type == "":
		return
		
	var queue: Array[Vector2i] = [start_pos]
	var visited: Dictionary = {}
	while queue.size() > 0:
		var p = queue.pop_front()
		if not _is_valid_coord(p) or visited.has(p):
			continue
		visited[p] = true
		if _get_tile_at(p).get("type", "") == target_type:
			_paint_tile(p)
			queue.append(p + Vector2i.RIGHT)
			queue.append(p + Vector2i.LEFT)
			queue.append(p + Vector2i.UP)
			queue.append(p + Vector2i.DOWN)

func _erase_at(pos: Vector2i) -> void:
	if not _is_valid_coord(pos):
		return
	if _remove_object_at(pos):
		map_modified.emit()
		return
	for t in world_data.get("tiles", []):
		if t["x"] == pos.x and t["y"] == pos.y:
			t["type"] = "grass"
			t["walkable"] = true
			t["solid"] = false
			t["interactable"] = false
			break
	map_modified.emit()

func copy_selection() -> void:
	if selection:
		var count = selection.copy_to_clipboard()
		print("[WorldCanvas] Copied %d objects to clipboard" % count)

func paste_clipboard(target_pos: Vector2i) -> void:
	if not selection or selection.clipboard.is_empty():
		return
		
	# Calculate reference top-left of clipboard
	var min_p = Vector2i(999, 999)
	for o in selection.clipboard:
		var p = o.get("position", [0, 0])
		min_p.x = mini(min_p.x, p[0])
		min_p.y = mini(min_p.y, p[1])
		
	var pasted_objects = []
	for o in selection.clipboard:
		var old_p = o.get("position", [0, 0])
		var offset = Vector2i(old_p[0] - min_p.x, old_p[1] - min_p.y)
		var new_pos = target_pos + offset
		
		if _is_valid_coord(new_pos):
			var new_obj = o.duplicate(true)
			var aid = new_obj.get("asset_id", "obj")
			new_obj["instance_id"] = _generate_unique_id(aid)
			new_obj["position"] = [new_pos.x, new_pos.y]
			world_data.get("objects", []).append(new_obj)
			pasted_objects.append(new_obj)
			
	if pasted_objects.size() > 0:
		selection.set_multi_selection(pasted_objects)
		if history:
			history.push_action({
				"type": "PASTE_OBJECTS",
				"objects": pasted_objects
			})
		map_modified.emit()
		queue_redraw()

func duplicate_selection() -> void:
	if not selection or selection.selected_objects.is_empty():
		return
	copy_selection()
	var first_p = selection.selected_objects[0].get("position", [0, 0])
	paste_clipboard(Vector2i(first_p[0] + 1, first_p[1] + 1))

func delete_selection() -> void:
	if not selection or not selection.has_selection():
		return
		
	if selection.current_mode == SelectionManager.SelectionMode.SINGLE_TILE:
		var pos = selection.selected_tile.get("position", Vector2i(-1, -1))
		if _is_valid_coord(pos):
			_erase_at(pos)
			selection.clear_selection()
	else:
		var deleted = []
		for o in selection.selected_objects:
			deleted.append(o.duplicate(true))
			_remove_object_by_id(o.get("instance_id", ""))
		if history:
			history.push_action({
				"type": "DELETE_OBJECTS",
				"objects": deleted
			})
		selection.clear_selection()
		map_modified.emit()
		queue_redraw()

func select_all_in_layer(layer_name: String) -> void:
	var found: Array[Dictionary] = []
	for o in world_data.get("objects", []):
		if o.get("layer", "OBJECT") == layer_name:
			found.append(o)
	if selection:
		selection.set_multi_selection(found)
		queue_redraw()

func focus_selection() -> void:
	if not selection or selection.selected_objects.is_empty():
		return
	var p = selection.selected_objects[0].get("position", [16, 12])
	var ts = 16.0 * zoom_level
	var target_pixel = Vector2(p[0] * ts, p[1] * ts)
	pan_offset = (size * 0.5) - target_pixel
	queue_redraw()

func fit_to_screen() -> void:
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	var avail_w = size.x - 40.0
	var avail_h = size.y - 40.0
	var z_w = avail_w / (w * 16.0)
	var z_h = avail_h / (h * 16.0)
	zoom_level = clampf(minf(z_w, z_h), 0.5, 3.5)
	pan_offset = Vector2(20, 20)
	queue_redraw()

func _remove_object_by_id(inst_id: String) -> bool:
	var objs = world_data.get("objects", [])
	for i in range(objs.size() - 1, -1, -1):
		if objs[i].get("instance_id", "") == inst_id:
			objs.remove_at(i)
			return true
	return false

func _remove_object_at(pos: Vector2i) -> bool:
	var objs = world_data.get("objects", [])
	for i in range(objs.size() - 1, -1, -1):
		var p = objs[i].get("position", [-1, -1])
		if p[0] == pos.x and p[1] == pos.y:
			objs.remove_at(i)
			return true
	return false

func _get_tile_at(pos: Vector2i) -> Dictionary:
	for t in world_data.get("tiles", []):
		if t["x"] == pos.x and t["y"] == pos.y:
			return t
	return {}

func _get_object_at(pos: Vector2i) -> Dictionary:
	for o in world_data.get("objects", []):
		var p = o.get("position", [-1, -1])
		if p[0] == pos.x and p[1] == pos.y:
			return o
	return {}

func _is_layer_locked(layer_name: String) -> bool:
	for l in world_data.get("layers", []):
		if l.get("name") == layer_name:
			return bool(l.get("locked", false))
	return false

func _is_layer_visible(layer_name: String) -> bool:
	for l in world_data.get("layers", []):
		if l.get("name") == layer_name:
			return bool(l.get("visible", true))
	return true

func _is_valid_coord(pos: Vector2i) -> bool:
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	return pos.x >= 0 and pos.x < w and pos.y >= 0 and pos.y < h

func _emit_status() -> void:
	var sel_count = selection.selected_objects.size() if selection else 0
	status_updated.emit({
		"x": hovered_tile.x,
		"y": hovered_tile.y,
		"zoom": int(zoom_level * 100.0),
		"layer": active_layer_name,
		"selected_count": sel_count
	})

func _draw() -> void:
	if world_data.is_empty():
		return
		
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	var ts = 16.0 * zoom_level
	
	# Draw Background
	draw_rect(Rect2(pan_offset, Vector2(w * ts, h * ts)), Color(0.12, 0.12, 0.12, 1.0))
	
	# Draw Tiles
	for t in world_data.get("tiles", []):
		var t_layer = t.get("layer", "GROUND")
		if not _is_layer_visible(t_layer):
			continue
			
		var rx = pan_offset.x + t["x"] * ts
		var ry = pan_offset.y + t["y"] * ts
		var rect = Rect2(rx, ry, ts, ts)
		var t_type = t.get("type", "grass")
		
		var col = Color(0.31, 0.47, 0.18)
		if t_type == "soil": col = Color(0.35, 0.18, 0.05)
		elif t_type == "path": col = Color(0.72, 0.64, 0.53)
		elif t_type == "fence": col = Color(0.44, 0.28, 0.15)
		elif t_type == "water": col = Color(0.25, 0.50, 0.85)
		
		draw_rect(rect, col)
		var tex = AssetRegistry.get_tile_texture(t_type) if t_type in ["grass", "soil", "path", "fence"] else null
		if tex:
			draw_texture_rect(tex, rect, false)
			
	# Draw Objects
	for o in world_data.get("objects", []):
		var o_layer = o.get("layer", "OBJECT")
		if not _is_layer_visible(o_layer):
			continue
			
		var p = o.get("position", [0, 0])
		var rx = pan_offset.x + p[0] * ts
		var ry = pan_offset.y + p[1] * ts
		var rect = Rect2(rx, ry, ts, ts)
		
		var aid = o.get("asset_id", "")
		var tex = _resolve_obj_texture(aid)
		if tex:
			draw_texture_rect(tex, rect, false)
		else:
			draw_rect(rect, Color(0.9, 0.6, 0.2, 0.8))
			draw_rect(rect.grow(-2), Color(1.0, 0.8, 0.4, 0.9))
			
	# Collision Debug Overlay
	if show_collision_debug:
		for t in world_data.get("tiles", []):
			var rx = pan_offset.x + t["x"] * ts
			var ry = pan_offset.y + t["y"] * ts
			var rect = Rect2(rx, ry, ts, ts)
			if t.get("solid", false):
				draw_rect(rect, Color(1.0, 0.2, 0.2, 0.35))
			elif t.get("interactable", false):
				draw_rect(rect, Color(1.0, 0.9, 0.2, 0.35))
			else:
				draw_rect(rect, Color(0.2, 1.0, 0.2, 0.20))
				
	# Grid Lines
	if show_grid_lines:
		for x in range(w + 1):
			draw_line(pan_offset + Vector2(x * ts, 0), pan_offset + Vector2(x * ts, h * ts), Color(0.0, 0.0, 0.0, 0.25), 1.0)
		for y in range(h + 1):
			draw_line(pan_offset + Vector2(0, y * ts), pan_offset + Vector2(w * ts, y * ts), Color(0.0, 0.0, 0.0, 0.25), 1.0)
			
	# Rubber-band Selection Box
	if is_box_selecting and _is_valid_coord(box_select_start) and _is_valid_coord(box_select_end):
		var min_x = mini(box_select_start.x, box_select_end.x)
		var max_x = maxi(box_select_start.x, box_select_end.x)
		var min_y = mini(box_select_start.y, box_select_end.y)
		var max_y = maxi(box_select_start.y, box_select_end.y)
		var box_rect = Rect2(pan_offset.x + min_x * ts, pan_offset.y + min_y * ts, (max_x - min_x + 1) * ts, (max_y - min_y + 1) * ts)
		draw_rect(box_rect, Color(0.3, 0.7, 1.0, 0.2))
		draw_rect(box_rect, Color(0.3, 0.7, 1.0, 0.8), false, 1.5)

	# Hover Highlight
	if _is_valid_coord(hovered_tile):
		var hx = pan_offset.x + hovered_tile.x * ts
		var hy = pan_offset.y + hovered_tile.y * ts
		draw_rect(Rect2(hx, hy, ts, ts), Color(1.0, 1.0, 0.3, 0.4), false, 2.0)
		
	# Multi-Selection Highlights & Gizmo
	if selection and selection.has_selection():
		if selection.current_mode == SelectionManager.SelectionMode.SINGLE_TILE:
			var pos = selection.selected_tile.get("position", Vector2i(-1, -1))
			if _is_valid_coord(pos):
				draw_rect(Rect2(pan_offset.x + pos.x * ts, pan_offset.y + pos.y * ts, ts, ts), Color(0.3, 0.8, 1.0, 0.9), false, 2.5)
		else:
			for o in selection.selected_objects:
				var p = o.get("position", [-1, -1])
				if p[0] >= 0:
					var rect = Rect2(pan_offset.x + p[0] * ts, pan_offset.y + p[1] * ts, ts, ts)
					draw_rect(rect, Color(0.2, 0.9, 1.0, 0.3))
					draw_rect(rect, Color(0.2, 0.9, 1.0, 0.9), false, 2.0)
					
			# Move Gizmo Icon on primary selected
			if selection.selected_objects.size() > 0:
				var p0 = selection.selected_objects[0].get("position", [0, 0])
				var center = pan_offset + Vector2(p0[0] * ts + ts * 0.5, p0[1] * ts + ts * 0.5)
				draw_line(center - Vector2(6, 0), center + Vector2(6, 0), Color.YELLOW, 2.0)
				draw_line(center - Vector2(0, 6), center + Vector2(0, 6), Color.YELLOW, 2.0)

func _resolve_obj_texture(asset_id: String) -> Texture2D:
	var path_env = "res://assets/sprites/environment/%s.png" % asset_id
	if ResourceLoader.exists(path_env): return ResourceLoader.load(path_env)
	var path_npc = "res://assets/sprites/npc/%s_idle_0.png" % asset_id
	if ResourceLoader.exists(path_npc): return ResourceLoader.load(path_npc)
	var path_plant = "res://assets/sprites/plants/%s_stage_3.png" % asset_id
	if ResourceLoader.exists(path_plant): return ResourceLoader.load(path_plant)
	return null
"""
	var f1 = FileAccess.open("res://editor/world_builder/world_canvas.gd", FileAccess.WRITE)
	if f1: f1.store_string(canvas_code); f1.close()

	print("[WorldBuilderCoreGenerator] Generated updated world_canvas.gd!")
