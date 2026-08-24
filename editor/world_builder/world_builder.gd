class_name WorldBuilder
extends Control

## Main Level Editor Phase 3 Developer Suite: Multi-World, Smart Tiling, Validator, Graph.

var palette: AssetPalette
var canvas: WorldCanvas
var inspector: WorldInspector

var world_option: OptionButton
var save_btn: Button
var open_btn: Button
var new_btn: Button
var graph_btn: Button
var validate_btn: Button

var tool_select_btn: Button
var tool_brush_btn: Button
var tool_eraser_btn: Button
var tool_rect_btn: Button
var tool_fill_btn: Button

var toggle_grid_btn: Button
var toggle_collision_btn: Button
var prefab_create_btn: Button

var undo_btn: Button
var redo_btn: Button
var bottom_status_label: Label
var layer_list_vbox: VBoxContainer
var val_panel: ValidationPanel
var graph_dialog: WorldGraphDialog

var close_btn: Button

var history: EditorHistory
var selection: SelectionManager
var current_world_path: String = "res://data/worlds/farm.json"
var world_data: Dictionary = {}

func _ready() -> void:
	history = EditorHistory.new()
	selection = SelectionManager.new()

	palette = find_child("AssetPalette", true, false) as AssetPalette
	canvas = find_child("WorldCanvas", true, false) as WorldCanvas
	inspector = find_child("WorldInspector", true, false) as WorldInspector

	world_option = find_child("WorldOption", true, false) as OptionButton
	save_btn = find_child("SaveButton", true, false) as Button
	open_btn = find_child("OpenButton", true, false) as Button
	new_btn = find_child("NewButton", true, false) as Button
	graph_btn = find_child("GraphButton", true, false) as Button
	validate_btn = find_child("ValidateButton", true, false) as Button
	close_btn = find_child("CloseButton", true, false) as Button

	tool_select_btn = find_child("ToolSelect", true, false) as Button
	tool_brush_btn = find_child("ToolBrush", true, false) as Button
	tool_eraser_btn = find_child("ToolEraser", true, false) as Button
	tool_rect_btn = find_child("ToolRect", true, false) as Button
	tool_fill_btn = find_child("ToolFill", true, false) as Button

	toggle_grid_btn = find_child("ToggleGrid", true, false) as Button
	toggle_collision_btn = find_child("ToggleCollision", true, false) as Button
	prefab_create_btn = find_child("CreatePrefabBtn", true, false) as Button

	undo_btn = find_child("UndoButton", true, false) as Button
	redo_btn = find_child("RedoButton", true, false) as Button
	bottom_status_label = find_child("BottomStatusLabel", true, false) as Label
	layer_list_vbox = find_child("LayerListVBox", true, false) as VBoxContainer
	val_panel = find_child("ValidationPanel", true, false) as ValidationPanel

	graph_dialog = WorldGraphDialog.new()
	add_child(graph_dialog)
	
	_populate_world_dropdown()
	_bind_topbar()
	_load_world(current_world_path)
	
	if canvas:
		canvas.setup(world_data, history, selection, palette)
		canvas.status_updated.connect(_on_canvas_status_updated)
		canvas.map_modified.connect(_on_map_modified)
		
	if selection: selection.selection_changed.connect(_on_selection_changed)
		
	if inspector:
		inspector.property_changed.connect(_on_inspector_property_changed)
		inspector.multi_property_changed.connect(_on_inspector_multi_property_changed)
		inspector.preset_applied.connect(_on_inspector_preset_applied)
		
	if history: history.history_changed.connect(_update_history_buttons)
		
	if val_panel:
		val_panel.issue_selected.connect(func(p): if canvas: canvas.focus_coordinate(p))

	_populate_layer_panel()
	_set_tool(WorldCanvas.ToolMode.BRUSH)

func on_opened() -> void:
	visible = true
	var wl = get_node_or_null("/root/WorldLoader")
	if wl and wl.has_method("get_current_world_id"):
		var wid = wl.get_current_world_id()
		var candidate_path = "res://data/worlds/%s.json" % wid
		if FileAccess.file_exists(candidate_path) and candidate_path != current_world_path:
			_load_world(candidate_path)
			_sync_dropdown_selection(candidate_path)
	if canvas:
		canvas.fit_to_screen()
		canvas.queue_redraw()

func on_closed() -> void:
	visible = false

func close_world_builder() -> void:
	var main = get_tree().root.find_child("Main", true, false)
	if main and main.has_method("toggle_world_builder"):
		main.toggle_world_builder()
	else:
		on_closed()

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2:
			close_world_builder()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F5:
			_validate_current_world()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S and (event.ctrl_pressed or event.meta_pressed):
			_save_current_world()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_O and (event.ctrl_pressed or event.meta_pressed):
			_load_world(current_world_path)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_B:
			_set_tool(WorldCanvas.ToolMode.BRUSH)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			_set_tool(WorldCanvas.ToolMode.ERASER)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G:
			_set_tool(WorldCanvas.ToolMode.FILL)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_L:
			_set_tool(WorldCanvas.ToolMode.LINE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			_set_tool(WorldCanvas.ToolMode.RECTANGLE)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_V:
			_set_tool(WorldCanvas.ToolMode.SELECT)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_D:
			_set_tool(WorldCanvas.ToolMode.SCATTER)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_N:
			if canvas:
				canvas.show_navigation_debug = not canvas.show_navigation_debug
				canvas.queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_W:
			_validate_current_world()
			get_viewport().set_input_as_handled()

func _populate_world_dropdown() -> void:
	if not world_option: return
	world_option.clear()
	var files = DirAccess.get_files_at("res://data/worlds/")
	for fn in files:
		if fn.ends_with(".json") and fn != "worlds.json" and not fn.ends_with(".tmp"):
			var dname = fn.trim_suffix(".json").replace("_", " ").capitalize()
			world_option.add_item("World: " + dname)
			world_option.set_item_metadata(world_option.item_count - 1, "res://data/worlds/" + fn)
		
	world_option.item_selected.connect(func(idx):
		var path = str(world_option.get_item_metadata(idx))
		_load_world(path)
	)

func _sync_dropdown_selection(path: String) -> void:
	if not world_option: return
	for i in range(world_option.item_count):
		if str(world_option.get_item_metadata(i)) == path:
			world_option.select(i)
			return

func _bind_topbar() -> void:
	if save_btn: save_btn.pressed.connect(_save_current_world)
	if open_btn: open_btn.pressed.connect(func(): _load_world(current_world_path))
	if new_btn: new_btn.pressed.connect(_new_world)
	if graph_btn: graph_btn.pressed.connect(func(): if graph_dialog: graph_dialog.open_graph())
	if validate_btn: validate_btn.pressed.connect(_validate_current_world)
	if close_btn: close_btn.pressed.connect(close_world_builder)
	
	if tool_select_btn: tool_select_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.SELECT))
	if tool_brush_btn: tool_brush_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.BRUSH))
	if tool_eraser_btn: tool_eraser_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.ERASER))
	if tool_rect_btn: tool_rect_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.RECTANGLE))
	if tool_fill_btn: tool_fill_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.FILL))
	
	if toggle_grid_btn: toggle_grid_btn.pressed.connect(_toggle_grid)
	if toggle_collision_btn: toggle_collision_btn.pressed.connect(_toggle_collision)
	if prefab_create_btn: prefab_create_btn.pressed.connect(_create_prefab_from_selection)
	
	if undo_btn: undo_btn.pressed.connect(_undo)
	if redo_btn: redo_btn.pressed.connect(_redo)

func _set_tool(tool_mode: WorldCanvas.ToolMode) -> void:
	if canvas: canvas.current_tool = tool_mode
	if tool_select_btn: tool_select_btn.modulate = Color(1.3, 1.3, 0.8) if tool_mode == WorldCanvas.ToolMode.SELECT else Color.WHITE
	if tool_brush_btn: tool_brush_btn.modulate = Color(1.3, 1.3, 0.8) if tool_mode == WorldCanvas.ToolMode.BRUSH else Color.WHITE
	if tool_eraser_btn: tool_eraser_btn.modulate = Color(1.3, 1.3, 0.8) if tool_mode == WorldCanvas.ToolMode.ERASER else Color.WHITE
	if tool_rect_btn: tool_rect_btn.modulate = Color(1.3, 1.3, 0.8) if tool_mode == WorldCanvas.ToolMode.RECTANGLE else Color.WHITE
	if tool_fill_btn: tool_fill_btn.modulate = Color(1.3, 1.3, 0.8) if tool_mode == WorldCanvas.ToolMode.FILL else Color.WHITE

func _toggle_grid() -> void:
	if canvas:
		canvas.show_grid_lines = not canvas.show_grid_lines
		if toggle_grid_btn: toggle_grid_btn.modulate = Color(1.3, 1.3, 0.8) if canvas.show_grid_lines else Color.WHITE
		canvas.queue_redraw()

func _toggle_collision() -> void:
	if canvas:
		canvas.show_collision_debug = not canvas.show_collision_debug
		if toggle_collision_btn: toggle_collision_btn.modulate = Color(1.3, 1.3, 0.8) if canvas.show_collision_debug else Color.WHITE
		canvas.queue_redraw()

func _validate_current_world() -> void:
	var results = WorldValidator.validate_world(world_data)
	if val_panel: val_panel.display_results(results)

func _load_world(path: String) -> void:
	world_data = WorldSerializer.load_world(path)
	current_world_path = path
	if canvas: canvas.setup(world_data, history, selection, palette)
	if history: history.clear()
	if selection: selection.clear_selection()
	_populate_layer_panel()
	_sync_dropdown_selection(path)
	if bottom_status_label:
		bottom_status_label.text = "Loaded '%s' (v%d)" % [world_data.get("display_name", path.get_file()), world_data.get("version", 3)]

func _save_current_world() -> void:
	var ok = WorldSerializer.save_world(current_world_path, world_data)
	if bottom_status_label:
		if ok:
			bottom_status_label.text = " Saved (v%d) to %s" % [world_data.get("version", 3), current_world_path]
		else:
			bottom_status_label.text = " Failed to save world!"

func _new_world() -> void:
	world_data = WorldSerializer.create_empty_world(32, 24, "custom_map", "Custom Level")
	if canvas: canvas.setup(world_data, history, selection, palette)
	if history: history.clear()
	if selection: selection.clear_selection()
	_populate_layer_panel()
	if bottom_status_label:
		bottom_status_label.text = "Created New Custom Level"


func _create_prefab_from_selection() -> void:
	if not selection or selection.selected_objects.is_empty(): return
	var min_p = Vector2i(999, 999)
	for o in selection.selected_objects:
		var p = o.get("position", [0, 0])
		min_p.x = mini(min_p.x, p[0]); min_p.y = mini(min_p.y, p[1])
		
	var objs = []
	for o in selection.selected_objects:
		var p = o.get("position", [0, 0])
		objs.append({
			"asset_id": o.get("asset_id", "obj"),
			"offset": [p[0] - min_p.x, p[1] - min_p.y],
			"layer": o.get("layer", "OBJECT"),
			"properties": o.get("properties", {}).duplicate(true)
		})
		
	var timestamp = Time.get_unix_time_from_system()
	var prefab_name = "Custom Preset %d" % timestamp
	var prefab_id = "prefab_%d" % timestamp
	var p_data = { "version": 1, "name": prefab_name, "id": prefab_id, "objects": objs }
	WorldSerializer.save_prefab("res://data/prefabs/%s.json" % prefab_id, p_data)
	if palette: palette.refresh_prefabs_list(); palette._populate_palette()

func _populate_layer_panel() -> void:
	if not layer_list_vbox: return
	for c in layer_list_vbox.get_children(): c.queue_free()
	var layers = world_data.get("layers", [])
	for l in layers:
		var lname = str(l.get("name", "LAYER"))
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		
		var vis_btn = Button.new()
		vis_btn.text = "" if l.get("visible", true) else ""
		vis_btn.custom_minimum_size = Vector2(24, 24)
		vis_btn.pressed.connect(func():
			l["visible"] = not l.get("visible", true)
			vis_btn.text = "" if l["visible"] else ""
			if canvas: canvas.queue_redraw()
		)
		hbox.add_child(vis_btn)
		
		var lock_btn = Button.new()
		lock_btn.text = "" if l.get("locked", false) else ""
		lock_btn.custom_minimum_size = Vector2(24, 24)
		lock_btn.pressed.connect(func():
			l["locked"] = not l.get("locked", false)
			lock_btn.text = "" if l["locked"] else ""
		)
		hbox.add_child(lock_btn)
		
		var act_btn = Button.new()
		act_btn.text = lname
		act_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		act_btn.pressed.connect(func():
			if canvas: canvas.active_layer_name = lname
			_highlight_active_layer(lname)
		)
		hbox.add_child(act_btn)
		layer_list_vbox.add_child(hbox)
	_highlight_active_layer(canvas.active_layer_name if canvas else "TERRAIN")

func _highlight_active_layer(active_name: String) -> void:
	if not layer_list_vbox: return
	for hbox in layer_list_vbox.get_children():
		if hbox is HBoxContainer and hbox.get_child_count() >= 3:
			var btn = hbox.get_child(2) as Button
			if btn: btn.modulate = Color(1.3, 1.3, 0.8) if btn.text == active_name else Color.WHITE

func _undo() -> void:
	if not history or not history.can_undo(): return
	var action = history.undo()
	_apply_history_action(action, true)

func _redo() -> void:
	if not history or not history.can_redo(): return
	var action = history.redo()
	_apply_history_action(action, false)

func _apply_history_action(action: Dictionary, is_undo: bool) -> void:
	var atype = action.get("type", "")
	if atype == "PAINT_STROKE":
		var tiles_to_set = action.get("old_tiles", action.get("tiles", {})) if is_undo else action.get("new_tiles", {})
		for pos in tiles_to_set.keys():
			var prev_t = tiles_to_set[pos]
			for t in world_data.get("tiles", []):
				if t["x"] == pos.x and t["y"] == pos.y:
					t["type"] = prev_t.get("type", "grass")
					t["walkable"] = prev_t.get("walkable", true)
					t["solid"] = prev_t.get("solid", false)
					t["interactable"] = prev_t.get("interactable", false)
					t["variant"] = prev_t.get("variant", "single")
					t["connection_mask"] = prev_t.get("connection_mask", 0)
					break
			SmartTiler.update_tile_and_neighbors(world_data, pos)
	elif atype == "OBJECT_PLACE":
		var obj = action.get("object", {})
		var objs = world_data.get("objects", [])
		if is_undo:
			for i in range(objs.size() - 1, -1, -1):
				if objs[i].get("instance_id") == obj.get("instance_id"):
					objs.remove_at(i); break
		else: objs.append(obj)
	elif atype == "PASTE_OBJECTS":
		var p_objs = action.get("objects", []); var objs = world_data.get("objects", [])
		if is_undo:
			for po in p_objs:
				for i in range(objs.size() - 1, -1, -1):
					if objs[i].get("instance_id") == po.get("instance_id"):
						objs.remove_at(i); break
		else:
			for po in p_objs: objs.append(po)
	elif atype == "DELETE_OBJECTS":
		var d_objs = action.get("objects", []); var objs = world_data.get("objects", [])
		if is_undo:
			for do_item in d_objs: objs.append(do_item)
		else:
			for do_item in d_objs:
				for i in range(objs.size() - 1, -1, -1):
					if objs[i].get("instance_id") == do_item.get("instance_id"):
						objs.remove_at(i); break
	elif atype == "MULTI_OBJECT_MOVE":
		var records = action.get("records", [])
		for r in records:
			var obj = r["object"]
			var target_pos = r["old_pos"] if is_undo else r["new_pos"]
			obj["position"] = [target_pos[0], target_pos[1]]
	if canvas: canvas.queue_redraw()

func _update_history_buttons() -> void:
	if undo_btn: undo_btn.disabled = not (history and history.can_undo())
	if redo_btn: redo_btn.disabled = not (history and history.can_redo())

func _on_selection_changed(mode: SelectionManager.SelectionMode, items: Array) -> void:
	if inspector: inspector.inspect(mode, items)

func _on_canvas_status_updated(info: Dictionary) -> void:
	if bottom_status_label:
		if info.has("warning") and not str(info["warning"]).is_empty():
			bottom_status_label.text = str(info["warning"])
		else:
			bottom_status_label.text = "X: %d  Y: %d | Zoom: %d%% | Layer: %s | Selected: %d" % [
				info.get("x", 0), info.get("y", 0), info.get("zoom", 100), info.get("layer", "TERRAIN"), info.get("selected_count", 0)
			]


func _on_map_modified() -> void:
	if canvas: canvas.queue_redraw()

func _on_inspector_property_changed(target: Dictionary, field: String, val: Variant) -> void:
	if target.has("properties"): target["properties"][field] = val
	elif target.has("tile"): target["tile"][field] = val
	if canvas: canvas.queue_redraw()

func _on_inspector_multi_property_changed(targets: Array, field: String, val: Variant) -> void:
	for t in targets:
		if t.has("properties"): t["properties"][field] = val
		elif t.has("tile"): t["tile"][field] = val
	if canvas: canvas.queue_redraw()

func _on_inspector_preset_applied(preset: String, targets: Array) -> void:
	for t in targets:
		var props = t.get("properties", {})
		match preset:
			"WALKABLE": props["walkable"] = true; props["solid"] = false; props["interactable"] = false
			"SOLID": props["walkable"] = false; props["solid"] = true; props["interactable"] = false
			"INTERACTABLE": props["walkable"] = false; props["solid"] = true; props["interactable"] = true
			"DECORATION": props["walkable"] = true; props["solid"] = false; props["interactable"] = false; t["layer"] = "DECORATION"
	if canvas: canvas.queue_redraw()
