class_name WorldCanvas
extends Control

## Central 2D viewport with drag-move, multi-select box, camera framing, smart autotiling, Scatter Brush, Navigation & Reachability Debug.

enum ToolMode { SELECT, BRUSH, ERASER, RECTANGLE, FILL, LINE, SCATTER, TRANSITION }

signal hover_coord_changed(coord: Vector2i)
signal map_modified()
signal status_updated(info: Dictionary)

var current_tool: ToolMode = ToolMode.BRUSH
var show_grid_lines: bool = true
var show_collision_debug: bool = false
var show_coordinates: bool = false
var show_autotile_debug: bool = false
var show_navigation_debug: bool = false
var show_lighting_debug: bool = false
var zoom_level: float = 1.5
var pan_offset: Vector2 = Vector2(40, 40)

var world_data: Dictionary = {}
var hovered_tile: Vector2i = Vector2i(-1, -1)
var is_middle_panning: bool = false
var pan_start_pos: Vector2 = Vector2.ZERO

var rect_drag_start: Vector2i = Vector2i(-1, -1)
var is_rect_dragging: bool = false

var line_drag_start: Vector2i = Vector2i(-1, -1)
var is_line_dragging: bool = false

var is_dragging_objects: bool = false
var drag_start_coord: Vector2i = Vector2i(-1, -1)
var is_box_selecting: bool = false
var box_select_start: Vector2i = Vector2i(-1, -1)
var box_select_end: Vector2i = Vector2i(-1, -1)

var history: EditorHistory
var selection: SelectionManager
var palette: AssetPalette
var active_layer_name: String = "TERRAIN"

# Continuous brush batch tracking
var is_brush_painting: bool = false
var current_stroke_previous_tiles: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_unhandled_input(true)
	custom_minimum_size = Vector2(600, 500)

func setup(p_data: Dictionary, p_history: EditorHistory, p_selection: SelectionManager, p_palette: AssetPalette) -> void:
	world_data = p_data
	history = p_history
	selection = p_selection
	palette = p_palette
	queue_redraw()

func resize_world(nw: int, nh: int) -> void:
	if world_data.is_empty(): return
	var ow = int(world_data.get("width", 32))
	var oh = int(world_data.get("height", 24))
	if nw == ow and nh == oh: return
	
	if history:
		history.commit_action("Resize World", self, "_apply_resize", [nw, nh, world_data.get("tiles", [])], [ow, oh, world_data.get("tiles", []).duplicate(true)])
	_apply_resize(nw, nh, world_data.get("tiles", []))

func _apply_resize(nw: int, nh: int, old_tiles: Array) -> void:
	world_data["width"] = nw
	world_data["height"] = nh
	var new_tiles = []
	for t in old_tiles:
		if int(t.get("x", 0)) < nw and int(t.get("y", 0)) < nh:
			new_tiles.append(t.duplicate(true))
	world_data["tiles"] = new_tiles
	map_modified.emit()
	queue_redraw()

func set_tool_mode(mode: ToolMode) -> void:
	current_tool = mode
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not visible: return
	_handle_canvas_mouse_event(event)

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_DELETE or event.keycode == KEY_BACKSPACE:
			delete_selection(); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_C and (event.ctrl_pressed or event.meta_pressed):
			copy_selection(); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_V and (event.ctrl_pressed or event.meta_pressed):
			paste_clipboard(hovered_tile if _is_valid_coord(hovered_tile) else Vector2i(10, 10)); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_D and (event.ctrl_pressed or event.meta_pressed):
			duplicate_selection(); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_A and (event.ctrl_pressed or event.meta_pressed):
			select_all_in_layer(active_layer_name); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_F:
			focus_selection(); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_HOME:
			fit_to_screen(); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_1:
			set_tool_mode(ToolMode.SELECT); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_2:
			set_tool_mode(ToolMode.BRUSH); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_3:
			set_tool_mode(ToolMode.ERASER); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_4:
			set_tool_mode(ToolMode.FILL); if get_viewport(): get_viewport().set_input_as_handled(); return
		elif event.keycode == KEY_5:
			set_tool_mode(ToolMode.RECTANGLE); if get_viewport(): get_viewport().set_input_as_handled(); return

func _handle_canvas_mouse_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_level = clampf(zoom_level + 0.15, 0.5, 3.5); _emit_status(); queue_redraw(); accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_level = clampf(zoom_level - 0.15, 0.5, 3.5); _emit_status(); queue_redraw(); accept_event()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_middle_panning = event.pressed
			if is_middle_panning: pan_start_pos = event.position - pan_offset
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var coord = _pixel_to_coord(event.position)
			if _is_valid_coord(coord):
				_erase_at(coord)
				queue_redraw()
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var coord = _pixel_to_coord(event.position)
			if event.pressed:
				if _is_valid_coord(coord):
					match current_tool:
						ToolMode.SELECT: _handle_select_press(coord, event.shift_pressed or event.ctrl_pressed)
						ToolMode.BRUSH:
							is_brush_painting = true
							current_stroke_previous_tiles.clear()
							_paint_tile(coord)
						ToolMode.SCATTER:
							_scatter_objects_around(coord, 2, 0.4)
						ToolMode.TRANSITION:
							_create_transition_point(coord)
						ToolMode.ERASER:
							is_brush_painting = true
							current_stroke_previous_tiles.clear()
							_erase_at(coord)
						ToolMode.RECTANGLE:
							is_rect_dragging = true
							rect_drag_start = coord
						ToolMode.LINE:
							is_line_dragging = true
							line_drag_start = coord
						ToolMode.FILL:
							_flood_fill(coord)
			else:
				if is_brush_painting:
					is_brush_painting = false
					_record_brush_stroke_undo()
				if is_rect_dragging and _is_valid_coord(rect_drag_start) and _is_valid_coord(coord):
					_paint_rect(rect_drag_start, coord)
					is_rect_dragging = false
					rect_drag_start = Vector2i(-1, -1)
				if is_line_dragging and _is_valid_coord(line_drag_start) and _is_valid_coord(coord):
					_paint_line(line_drag_start, coord)
					is_line_dragging = false
					line_drag_start = Vector2i(-1, -1)
				if is_box_selecting: _finalize_box_select()
				if is_dragging_objects: _finalize_drag_move(coord)
			queue_redraw()
			accept_event()

	elif event is InputEventMouseMotion:
		if is_middle_panning:
			pan_offset = event.position - pan_start_pos
			queue_redraw()
			accept_event()
		else:
			var prev_hover = hovered_tile
			hovered_tile = _pixel_to_coord(event.position)
			if hovered_tile != prev_hover:
				hover_coord_changed.emit(hovered_tile)
				_emit_status()
				if is_brush_painting and _is_valid_coord(hovered_tile):
					if current_tool == ToolMode.BRUSH: _paint_tile(hovered_tile)
					elif current_tool == ToolMode.ERASER: _erase_at(hovered_tile)
				if is_box_selecting: box_select_end = hovered_tile
				queue_redraw()


func _handle_select_press(coord: Vector2i, is_multi: bool) -> void:
	var obj = _get_object_at(coord)
	if not obj.is_empty():
		if selection and selection.selected_objects.has(obj):
			is_dragging_objects = true
			drag_start_coord = coord
			return
		if is_multi:
			if selection: selection.toggle_object_selection(obj)
		else:
			if selection: selection.set_single_object(obj)
		is_dragging_objects = true
		drag_start_coord = coord
	else:
		var tile = _get_tile_at(coord)
		if not tile.is_empty() and not is_multi:
			if selection: selection.set_single_tile(coord, tile)
		else:
			is_box_selecting = true
			box_select_start = coord
			box_select_end = coord
			if not is_multi and selection: selection.clear_selection()

func _finalize_box_select() -> void:
	is_box_selecting = false
	if not _is_valid_coord(box_select_start) or not _is_valid_coord(box_select_end): return
	var min_x = mini(box_select_start.x, box_select_end.x); var max_x = maxi(box_select_start.x, box_select_end.x)
	var min_y = mini(box_select_start.y, box_select_end.y); var max_y = maxi(box_select_start.y, box_select_end.y)
	var selected: Array[Dictionary] = []
	for o in world_data.get("objects", []):
		if not _is_layer_visible(o.get("layer", "OBJECT")): continue
		var p = o.get("position", [-1, -1])
		if p[0] >= min_x and p[0] <= max_x and p[1] >= min_y and p[1] <= max_y:
			selected.append(o)
	if selection: selection.set_multi_selection(selected)

func _finalize_drag_move(end_coord: Vector2i) -> void:
	is_dragging_objects = false
	if not _is_valid_coord(drag_start_coord) or not _is_valid_coord(end_coord) or drag_start_coord == end_coord: return
	if not selection or selection.selected_objects.is_empty(): return
	var delta = end_coord - drag_start_coord
	var moved = false
	for o in selection.selected_objects:
		var o_layer = o.get("layer", "OBJECT")
		if _is_layer_locked(o_layer):
			_emit_locked_warning(o_layer)
			continue
		var p = o.get("position", [0, 0])
		var new_p = Vector2i(int(p[0]) + delta.x, int(p[1]) + delta.y)
		if _is_valid_coord(new_p):
			o["position"] = [int(new_p.x), int(new_p.y)]
			moved = true
	if moved:
		map_modified.emit()


func _pixel_to_coord(pixel_pos: Vector2) -> Vector2i:
	var local = pixel_pos - pan_offset
	var ts = 16.0 * zoom_level
	if ts <= 0: return Vector2i(-1, -1)
	return Vector2i(int(floor(local.x / ts)), int(floor(local.y / ts)))

func paint_tile_at(pos: Vector2i, tile_type: String = "") -> void:
	if tile_type != "" and palette:
		palette.selected_asset_id = tile_type
	_paint_tile(pos)

func get_tile_type_at(pos: Vector2i) -> String:
	var t = _get_tile_at(pos)
	return str(t.get("type", "grass"))

func _paint_tile(pos: Vector2i) -> void:

	if not _is_valid_coord(pos) or not palette: return
	var asset = palette.selected_asset
	if asset.is_empty(): return
	var asset_type = asset.get("type", "tile")
	
	# Check lock on the EXACT layer targeted by this asset
	var target_layer = asset.get("layer", "GROUND" if asset_type in ["tile", "terrain"] else "OBJECT")
	if _is_layer_locked(target_layer):
		_emit_locked_warning(target_layer)
		return
		
	if asset_type in ["tile", "terrain"]:
		var t_id = asset.get("id", "grass")
		for t in world_data.get("tiles", []):
			if int(t.get("x", -999)) == pos.x and int(t.get("y", -999)) == pos.y:
				if not current_stroke_previous_tiles.has(pos): current_stroke_previous_tiles[pos] = t.duplicate(true)
				t["x"] = int(pos.x)
				t["y"] = int(pos.y)
				t["type"] = t_id
				t["walkable"] = bool(asset.get("walkable", true))
				t["solid"] = bool(asset.get("solid", false))
				t["interactable"] = bool(asset.get("interactable", false))
				t["layer"] = target_layer
				break
		SmartTiler.update_tile_and_neighbors(world_data, pos)
	elif asset_type in ["object", "plant", "transition"]:
		var aid = asset.get("id", "chest")
		_remove_object_at(pos)
		var obj = {
			"instance_id": _generate_unique_id(aid),
			"asset_id": aid,
			"name": asset.get("name", aid.capitalize()),
			"position": [int(pos.x), int(pos.y)],
			"layer": target_layer,
			"properties": {
				"walkable": bool(asset.get("walkable", false)),
				"solid": bool(asset.get("solid", true)),
				"interactable": bool(asset.get("interactable", true)),
				"interaction_type": asset.get("interaction_type", "none"),
				"interaction_id": asset.get("interaction_id", ""),
				"target_world": asset.get("target_world", "town"),
				"target_spawn": asset.get("target_spawn", "from_farm"),
				"direction": asset.get("direction", "north")
			}
		}
		world_data.get("objects", []).append(obj)
	elif asset_type == "prefab":
		_place_prefab(asset.get("prefab_data", {}), pos)
	map_modified.emit()
	queue_redraw()

func _emit_locked_warning(layer_name: String) -> void:
	status_updated.emit({
		"x": hovered_tile.x, "y": hovered_tile.y,
		"zoom": int(zoom_level * 100.0), "layer": active_layer_name,
		"selected_count": selection.selected_objects.size() if selection else 0,
		"warning": " Layer '%s' is locked! Unlock it in the Layers panel." % layer_name
	})

func _scatter_objects_around(center: Vector2i, radius: int = 2, density: float = 0.35) -> void:
	if not palette or palette.selected_asset.is_empty(): return
	var asset = palette.selected_asset
	var target_layer = asset.get("layer", "DECORATION")
	if _is_layer_locked(target_layer):
		_emit_locked_warning(target_layer)
		return
	var aid = asset.get("id", "red_flower")
	if not world_data.has("objects"):
		world_data["objects"] = []
	var placed_objects: Array[Dictionary] = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var p = center + Vector2i(dx, dy)
			if _is_valid_coord(p) and (dx * dx + dy * dy <= radius * radius):
				var h = ((p.x * 73856093) ^ (p.y * 19349663)) & 0x7FFFFFFF
				var roll = float(h % 100) / 100.0
				if (roll < density or (dx == 0 and dy == 0)) and _get_object_at(p).is_empty():
					var tile = _get_tile_at(p)
					if tile.get("walkable", true) and not tile.get("solid", false):
						var obj = {
							"instance_id": _generate_unique_id(aid),
							"asset_id": aid,
							"name": asset.get("name", aid.capitalize()),
							"position": [int(p.x), int(p.y)],
							"layer": target_layer,
							"properties": {
								"walkable": bool(asset.get("walkable", true)),
								"solid": bool(asset.get("solid", false)),
								"interactable": bool(asset.get("interactable", false))
							}
						}
						world_data["objects"].append(obj)
						placed_objects.append(obj)
	if placed_objects.size() > 0 and history:
		history.push_action({ "type": "PASTE_OBJECTS", "objects": placed_objects })
	map_modified.emit()
	queue_redraw()

func _paint_rect(p_start: Vector2i, p_end: Vector2i) -> void:
	var min_x = mini(p_start.x, p_end.x); var max_x = maxi(p_start.x, p_end.x)
	var min_y = mini(p_start.y, p_end.y); var max_y = maxi(p_start.y, p_end.y)
	current_stroke_previous_tiles.clear()
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			_paint_tile(Vector2i(x, y))
	_record_brush_stroke_undo()

func _paint_line(p_start: Vector2i, p_end: Vector2i) -> void:
	var coords = _get_line_coords(p_start, p_end)
	current_stroke_previous_tiles.clear()
	for p in coords: _paint_tile(p)
	_record_brush_stroke_undo()

func _get_line_coords(p0: Vector2i, p1: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	var x0 = p0.x; var y0 = p0.y; var x1 = p1.x; var y1 = p1.y
	var dx = absi(x1 - x0); var dy = -absi(y1 - y0)
	var sx = 1 if x0 < x1 else -1; var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1: break
		var e2 = 2 * err
		if e2 >= dy: err += dy; x0 += sx
		if e2 <= dx: err += dx; y0 += sy
	return points

func _flood_fill(start_pos: Vector2i) -> void:
	if not _is_valid_coord(start_pos) or not palette: return
	var target_type = _get_tile_at(start_pos).get("type", "")
	var new_type = palette.selected_asset.get("id", "")
	if target_type == new_type or new_type == "": return
	current_stroke_previous_tiles.clear()
	var queue: Array[Vector2i] = [start_pos]
	var visited: Dictionary = {}
	while queue.size() > 0:
		var p = queue.pop_front()
		if not _is_valid_coord(p) or visited.has(p): continue
		visited[p] = true
		if _get_tile_at(p).get("type", "") == target_type:
			_paint_tile(p)
			queue.append(p + Vector2i.RIGHT); queue.append(p + Vector2i.LEFT)
			queue.append(p + Vector2i.UP); queue.append(p + Vector2i.DOWN)
	_record_brush_stroke_undo()

func _erase_at(pos: Vector2i) -> void:
	if not _is_valid_coord(pos): return
	var obj = _get_object_at(pos)
	if not obj.is_empty():
		var o_layer = obj.get("layer", "OBJECT")
		if _is_layer_locked(o_layer):
			_emit_locked_warning(o_layer)
			return
		_remove_object_at(pos)
		map_modified.emit()
		return
		
	for t in world_data.get("tiles", []):
		if int(t.get("x", -999)) == pos.x and int(t.get("y", -999)) == pos.y:
			var t_layer = t.get("layer", "GROUND")
			if _is_layer_locked(t_layer):
				_emit_locked_warning(t_layer)
				return
			if not current_stroke_previous_tiles.has(pos): current_stroke_previous_tiles[pos] = t.duplicate(true)
			t["x"] = int(pos.x)
			t["y"] = int(pos.y)
			t["type"] = "grass"
			t["walkable"] = true
			t["solid"] = false
			t["interactable"] = false
			t["variant"] = "single"
			t["connection_mask"] = 0
			break
	SmartTiler.update_tile_and_neighbors(world_data, pos)
	map_modified.emit()

func _record_brush_stroke_undo() -> void:
	if history and not current_stroke_previous_tiles.is_empty():
		var new_tiles_state: Dictionary = {}
		for pos in current_stroke_previous_tiles.keys():
			var t = _get_tile_at(pos)
			if not t.is_empty(): new_tiles_state[pos] = t.duplicate(true)
		history.push_action({
			"type": "PAINT_STROKE",
			"old_tiles": current_stroke_previous_tiles.duplicate(true),
			"new_tiles": new_tiles_state
		})
	current_stroke_previous_tiles.clear()

func _place_prefab(p_data: Dictionary, base_pos: Vector2i) -> void:
	if p_data.is_empty(): return
	for t in p_data.get("tiles", []):
		var target_p = base_pos + Vector2i(int(t.get("x", 0)), int(t.get("y", 0)))
		if _is_valid_coord(target_p):
			var target_layer = t.get("layer", "GROUND")
			if _is_layer_locked(target_layer): continue
			for world_t in world_data.get("tiles", []):
				if int(world_t["x"]) == target_p.x and int(world_t["y"]) == target_p.y:
					world_t["type"] = t.get("type", "soil")
					world_t["walkable"] = bool(t.get("walkable", true))
					world_t["solid"] = bool(t.get("solid", false))
					break
			SmartTiler.update_tile_and_neighbors(world_data, target_p)

func _generate_unique_id(prefix: String) -> String:
	var count = 1
	var existing = {}
	for o in world_data.get("objects", []): existing[o.get("instance_id", "")] = true
	var candidate = "%s_%02d" % [prefix, count]
	while existing.has(candidate):
		count += 1
		candidate = "%s_%02d" % [prefix, count]
	return candidate

func copy_selection() -> void:
	if selection: selection.copy_to_clipboard()

func paste_clipboard(target_pos: Vector2i) -> void:
	if not selection or selection.clipboard.is_empty(): return
	var min_p = Vector2i(999, 999)
	for o in selection.clipboard:
		var p = o.get("position", [0, 0])
		min_p.x = mini(min_p.x, int(p[0])); min_p.y = mini(min_p.y, int(p[1]))
	var pasted = []
	for o in selection.clipboard:
		var o_layer = o.get("layer", "OBJECT")
		if _is_layer_locked(o_layer):
			_emit_locked_warning(o_layer)
			continue
		var old_p = o.get("position", [0, 0])
		var new_pos = target_pos + Vector2i(int(old_p[0]) - min_p.x, int(old_p[1]) - min_p.y)
		if _is_valid_coord(new_pos):
			var new_obj = o.duplicate(true)
			new_obj["instance_id"] = _generate_unique_id(new_obj.get("asset_id", "obj"))
			new_obj["position"] = [int(new_pos.x), int(new_pos.y)]
			world_data.get("objects", []).append(new_obj)
			pasted.append(new_obj)
	if pasted.size() > 0 and history: history.push_action({ "type": "PASTE_OBJECTS", "objects": pasted })
	map_modified.emit()
	queue_redraw()

func duplicate_selection() -> void:
	if not selection or selection.selected_objects.is_empty(): return
	copy_selection()
	var first_p = selection.selected_objects[0].get("position", [0, 0])
	paste_clipboard(Vector2i(int(first_p[0]) + 1, int(first_p[1]) + 1))

func delete_selection() -> void:
	if not selection or not selection.has_selection(): return
	if selection.current_mode == SelectionManager.SelectionMode.SINGLE_TILE:
		var pos = selection.selected_tile.get("position", Vector2i(-1, -1))
		var tile = selection.selected_tile.get("tile", {})
		var t_layer = tile.get("layer", "GROUND")
		if _is_layer_locked(t_layer):
			_emit_locked_warning(t_layer)
			return
		if _is_valid_coord(pos): _erase_at(pos); selection.clear_selection()
	else:
		var deleted = []
		for o in selection.selected_objects:
			var o_layer = o.get("layer", "OBJECT")
			if _is_layer_locked(o_layer):
				_emit_locked_warning(o_layer)
				continue
			deleted.append(o.duplicate(true))
			_remove_object_by_id(o.get("instance_id", ""))
		if deleted.size() > 0:
			if history: history.push_action({ "type": "DELETE_OBJECTS", "objects": deleted })
			selection.clear_selection()
			map_modified.emit()
			queue_redraw()

func select_all_in_layer(layer_name: String) -> void:
	var found: Array[Dictionary] = []
	for o in world_data.get("objects", []):
		if o.get("layer", "OBJECT") == layer_name: found.append(o)
	if selection: selection.set_multi_selection(found); queue_redraw()

func focus_selection() -> void:
	if not selection or selection.selected_objects.is_empty(): return
	var p = selection.selected_objects[0].get("position", [16, 12])
	var ts = 16.0 * zoom_level
	pan_offset = (size * 0.5) - Vector2(int(p[0]) * ts, int(p[1]) * ts)
	queue_redraw()

func _create_transition_point(coord: Vector2i) -> void:
	if world_data.is_empty(): return
	if not world_data.has("objects"): world_data["objects"] = []
	var new_obj = {
		"position": [coord.x, coord.y],
		"asset_id": "invisible_block",
		"layer": "OBJECT",
		"properties": {
			"interaction_type": "world_transition",
			"target_world": "town",
			"interaction_id": "town_from_farm",
			"walkable": true,
			"solid": false,
			"interactable": true
		}
	}
	world_data["objects"].append(new_obj)
	map_modified.emit()
	queue_redraw()
	if selection:
		selection.select_single_object(new_obj)

func focus_coordinate(coord: Vector2i) -> void:
	var ts = 16.0 * zoom_level
	pan_offset = (size * 0.5) - Vector2(coord.x * ts, coord.y * ts)
	queue_redraw()

func fit_to_screen() -> void:
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	var z_w = (size.x - 40.0) / (w * 16.0)
	var z_h = (size.y - 40.0) / (h * 16.0)
	zoom_level = clampf(minf(z_w, z_h), 0.5, 3.5)
	pan_offset = Vector2(20, 20)
	queue_redraw()

func _remove_object_by_id(inst_id: String) -> bool:
	var objs = world_data.get("objects", [])
	for i in range(objs.size() - 1, -1, -1):
		if objs[i].get("instance_id", "") == inst_id:
			objs.remove_at(i); return true
	return false

func _remove_object_at(pos: Vector2i) -> bool:
	var objs = world_data.get("objects", [])
	for i in range(objs.size() - 1, -1, -1):
		var p = objs[i].get("position", [-1, -1])
		if int(p[0]) == pos.x and int(p[1]) == pos.y:
			objs.remove_at(i); return true
	return false

func _get_tile_at(pos: Vector2i) -> Dictionary:
	for t in world_data.get("tiles", []):
		if int(t.get("x", -999)) == pos.x and int(t.get("y", -999)) == pos.y: return t
	return {}

func _get_object_at(pos: Vector2i) -> Dictionary:
	for o in world_data.get("objects", []):
		var p = o.get("position", [-1, -1])
		if int(p[0]) == pos.x and int(p[1]) == pos.y: return o
	return {}

func _is_layer_locked(layer_name: String) -> bool:
	for l in world_data.get("layers", []):
		if l.get("name") == layer_name: return bool(l.get("locked", false))
	return false

func _is_layer_visible(layer_name: String) -> bool:
	for l in world_data.get("layers", []):
		if l.get("name") == layer_name: return bool(l.get("visible", true))
	return true

func _is_valid_coord(pos: Vector2i) -> bool:
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	return pos.x >= 0 and pos.x < w and pos.y >= 0 and pos.y < h

func _emit_status() -> void:
	var sel_count = selection.selected_objects.size() if selection else 0
	status_updated.emit({
		"x": hovered_tile.x, "y": hovered_tile.y,
		"zoom": int(zoom_level * 100.0), "layer": active_layer_name,
		"selected_count": sel_count
	})

func _draw() -> void:
	if world_data.is_empty(): return
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	var ts = 16.0 * zoom_level
	
	draw_rect(Rect2(pan_offset, Vector2(w * ts, h * ts)), Color(0.12, 0.12, 0.12, 1.0))
	
	# Draw Tiles
	for t in world_data.get("tiles", []):
		var t_layer = t.get("layer", "GROUND")
		if not _is_layer_visible(t_layer): continue
		var rx = pan_offset.x + int(t["x"]) * ts
		var ry = pan_offset.y + int(t["y"]) * ts
		var rect = Rect2(rx, ry, ts, ts)
		var t_type = str(t.get("type", "grass"))
		
		var col = Color(0.31, 0.47, 0.18)
		if t_type == "soil": col = Color(0.35, 0.18, 0.05)
		elif t_type == "path": col = Color(0.72, 0.64, 0.53)
		elif t_type == "fence": col = Color(0.44, 0.28, 0.15)
		elif t_type == "water": col = Color(0.25, 0.50, 0.85)
		elif t_type == "sand": col = Color(0.85, 0.78, 0.45)
		elif t_type == "stone": col = Color(0.55, 0.55, 0.60)
		draw_rect(rect, col)
		
		var tex = AssetRegistry.get_tile_texture(t_type) if t_type in ["grass", "soil", "path", "fence"] else AssetRegistry.get_asset_texture(t_type, "tile")
		if tex: draw_texture_rect(tex, rect, false)
			
	# Draw Objects
	for o in world_data.get("objects", []):
		var o_layer = o.get("layer", "OBJECT")
		if not _is_layer_visible(o_layer): continue
		var p = o.get("position", [0, 0])
		var rx = pan_offset.x + int(p[0]) * ts
		var ry = pan_offset.y + int(p[1]) * ts
		var rect = Rect2(rx, ry, ts, ts)
		var aid = str(o.get("asset_id", ""))
		var tex = AssetRegistry.get_asset_texture(aid, str(o.get("type", "object")))
		if tex:
			draw_texture_rect(tex, rect, false)
		else:
			var ph = AssetRegistry.get_fallback_placeholder_texture(aid)
			if ph:
				draw_texture_rect(ph, rect, false)
			else:
				draw_rect(rect, Color(0.9, 0.6, 0.2, 0.8))
				draw_rect(rect.grow(-2), Color(1.0, 0.8, 0.4, 0.9))

	# Collision Debug Overlay

	if show_collision_debug:
		for t in world_data.get('tiles', []):
			var rect = Rect2(pan_offset.x + int(t['x']) * ts, pan_offset.y + int(t['y']) * ts, ts, ts)
			if t.get('solid', false): draw_rect(rect, Color(1.0, 0.2, 0.2, 0.35))
			elif t.get('interactable', false): draw_rect(rect, Color(1.0, 0.9, 0.2, 0.35))
			else: draw_rect(rect, Color(0.2, 1.0, 0.2, 0.20))
		for o in world_data.get('objects', []):
			var props = o.get('properties', {})
			if ClassDB.class_exists('AssetDefinitionManager'): props = AssetDefinitionManager.resolve_instance_properties(o.get('asset_id', ''), props)
			var p = o.get('position', [0, 0])
			var rect = Rect2(pan_offset.x + int(p[0]) * ts, pan_offset.y + int(p[1]) * ts, ts, ts)
			if props.get('solid', false): draw_rect(rect, Color(1.0, 0.2, 0.2, 0.5))

	# Navigation / Reachability Debug Overlay

	if show_navigation_debug:
		for t in world_data.get('tiles', []):
			var rect = Rect2(pan_offset.x + int(t['x']) * ts, pan_offset.y + int(t['y']) * ts, ts, ts)
			if t.get('solid', false): draw_rect(rect, Color(1.0, 0.1, 0.1, 0.30))
			elif t.get('walkable', true): draw_rect(rect, Color(0.2, 0.9, 0.2, 0.18))
		for o in world_data.get('objects', []):
			var props = o.get('properties', {})
			if ClassDB.class_exists('AssetDefinitionManager'): props = AssetDefinitionManager.resolve_instance_properties(o.get('asset_id', ''), props)
			var p = o.get('position', [0, 0])
			var rect = Rect2(pan_offset.x + int(p[0]) * ts, pan_offset.y + int(p[1]) * ts, ts, ts)
			if props.get('interactable', false):
				draw_rect(rect, Color(1.0, 0.85, 0.2, 0.4))
				draw_circle(rect.get_center(), 3.0, Color(1.0, 0.85, 0.2))
			if props.get('solid', false) or not props.get('walkable', true):
				draw_rect(rect, Color(1.0, 0.1, 0.1, 0.4))


	# Lighting Debug Overlay
	if show_lighting_debug:
		for o in world_data.get('objects', []):
			var overrides = o.get('properties', {})
			var props = overrides
			if ClassDB.class_exists('AssetDefinitionManager'):
				props = AssetDefinitionManager.resolve_instance_properties(o.get('asset_id', ''), overrides)
			if props.get('emits_light', false):
				var p = o.get('position', [0, 0])
				var center = pan_offset + Vector2(int(p[0]) * ts + ts * 0.5, int(p[1]) * ts + ts * 0.5)
				var radius = float(props.get('light_radius', 64)) * zoom_level
				var col_hex = props.get('light_color', '#FFFFFF')
				var col = Color(col_hex)
				col.a = 0.2
				draw_circle(center, radius, col)
				col.a = 0.8
				draw_arc(center, radius, 0, TAU, 32, col, 2.0)


	# Autotile Debug Overlay (Connection Mask & Directions)
	if show_autotile_debug:
		for t in world_data.get("tiles", []):
			var t_type = str(t.get("type", ""))
			if SmartTiler.is_smart_type(t_type):
				var pos = Vector2i(int(t["x"]), int(t["y"]))
				var mask = SmartTiler.calculate_connection_mask(world_data, pos, t_type)
				var center = pan_offset + Vector2(pos.x * ts + ts * 0.5, pos.y * ts + ts * 0.5)
				var mask_col = Color(1.0, 0.8, 0.2, 0.9)
				if mask & SmartTiler.MASK_NORTH: draw_line(center, center - Vector2(0, ts * 0.4), mask_col, 2.0)
				if mask & SmartTiler.MASK_EAST:  draw_line(center, center + Vector2(ts * 0.4, 0), mask_col, 2.0)
				if mask & SmartTiler.MASK_SOUTH: draw_line(center, center + Vector2(0, ts * 0.4), mask_col, 2.0)
				if mask & SmartTiler.MASK_WEST:  draw_line(center, center - Vector2(ts * 0.4, 0), mask_col, 2.0)
				draw_circle(center, 2.5, Color.WHITE)

	# Grid Lines
	if show_grid_lines:
		for x in range(w + 1): draw_line(pan_offset + Vector2(x * ts, 0), pan_offset + Vector2(x * ts, h * ts), Color(0.0, 0.0, 0.0, 0.25), 1.0)
		for y in range(h + 1): draw_line(pan_offset + Vector2(0, y * ts), pan_offset + Vector2(w * ts, y * ts), Color(0.0, 0.0, 0.0, 0.25), 1.0)

	# Line Drag Preview
	if is_line_dragging and _is_valid_coord(line_drag_start) and _is_valid_coord(hovered_tile):
		var coords = _get_line_coords(line_drag_start, hovered_tile)
		for p in coords: draw_rect(Rect2(pan_offset.x + p.x * ts, pan_offset.y + p.y * ts, ts, ts), Color(0.2, 0.8, 1.0, 0.4))

	# Hover Ghost Preview
	if _is_valid_coord(hovered_tile) and palette and not palette.selected_asset.is_empty():
		var hx = pan_offset.x + hovered_tile.x * ts
		var hy = pan_offset.y + hovered_tile.y * ts
		var hrect = Rect2(hx, hy, ts, ts)
		draw_rect(hrect, Color(1.0, 1.0, 0.3, 0.35))
		draw_rect(hrect, Color(1.0, 1.0, 0.3, 0.9), false, 2.0)
		
	# Multi-Selection Highlights
	if selection and selection.has_selection():
		if selection.current_mode == SelectionManager.SelectionMode.SINGLE_TILE:
			var pos = selection.selected_tile.get("position", Vector2i(-1, -1))
			if _is_valid_coord(pos): draw_rect(Rect2(pan_offset.x + pos.x * ts, pan_offset.y + pos.y * ts, ts, ts), Color(0.3, 0.8, 1.0, 0.9), false, 2.5)
		else:
			for o in selection.selected_objects:
				var p = o.get("position", [-1, -1])
				if int(p[0]) >= 0:
					var rect = Rect2(pan_offset.x + int(p[0]) * ts, pan_offset.y + int(p[1]) * ts, ts, ts)
					draw_rect(rect, Color(0.2, 0.9, 1.0, 0.3))
					draw_rect(rect, Color(0.2, 0.9, 1.0, 0.9), false, 2.0)

func _resolve_obj_texture(asset_id: String) -> Texture2D:
	return AssetRegistry.get_asset_texture(asset_id)



