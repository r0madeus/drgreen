@tool
extends SceneTree

func _init() -> void:
	generate_all()
	quit()

static func generate_all() -> void:
	# 1. world_serializer.gd
	var serializer_code = """class_name WorldSerializer
extends RefCounted

## Handles loading, saving, validation and version migration of world data files.

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
		
	var text = JSON.stringify(data, "  ")
	f.store_string(text)
	f.close()
	print("[WorldSerializer] World successfully saved to: " + filepath)
	return true

static func create_empty_world(width: int = 32, height: int = 24) -> Dictionary:
	var tiles = []
	for y in range(height):
		for x in range(width):
			tiles.append({
				"x": x,
				"y": y,
				"type": "grass",
				"layer": "TERRAIN",
				"walkable": true,
				"solid": false,
				"interactable": false
			})
	return {
		"version": 1,
		"name": "New World",
		"width": width,
		"height": height,
		"tile_size": 16,
		"tiles": tiles,
		"objects": []
	}

static func migrate_world_data(data: Dictionary) -> Dictionary:
	var result = data.duplicate(true)
	if not result.has("version"): result["version"] = 1
	if not result.has("width"): result["width"] = 32
	if not result.has("height"): result["height"] = 24
	if not result.has("tile_size"): result["tile_size"] = 16
	if not result.has("tiles"): result["tiles"] = []
	if not result.has("objects"): result["objects"] = []
	return result
"""
	var f1 = FileAccess.open("res://editor/world_builder/world_serializer.gd", FileAccess.WRITE)
	if f1: f1.store_string(serializer_code); f1.close()

	# 2. editor_history.gd
	var history_code = """class_name EditorHistory
extends RefCounted

## Undo/Redo action manager for the World Builder.

signal history_changed()

var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
const MAX_HISTORY = 100

func push_action(action: Dictionary) -> void:
	undo_stack.append(action)
	if undo_stack.size() > MAX_HISTORY:
		undo_stack.pop_front()
	redo_stack.clear()
	history_changed.emit()

func can_undo() -> bool:
	return undo_stack.size() > 0

func can_redo() -> bool:
	return redo_stack.size() > 0

func undo() -> Dictionary:
	if not can_undo():
		return {}
	var action = undo_stack.pop_back()
	redo_stack.append(action)
	history_changed.emit()
	return action

func redo() -> Dictionary:
	if not can_redo():
		return {}
	var action = redo_stack.pop_back()
	undo_stack.append(action)
	history_changed.emit()
	return action

func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()
	history_changed.emit()
"""
	var f2 = FileAccess.open("res://editor/world_builder/editor_history.gd", FileAccess.WRITE)
	if f2: f2.store_string(history_code); f2.close()

	# 3. selection_manager.gd
	var selection_code = """class_name SelectionManager
extends RefCounted

## Manages active tile or object selection in the World Builder.

enum SelectionType { NONE, TILE, OBJECT }

signal selection_changed(type: SelectionType, data: Dictionary)

var current_type: SelectionType = SelectionType.NONE
var selected_data: Dictionary = {}

func select_tile(pos: Vector2i, tile_data: Dictionary) -> void:
	current_type = SelectionType.TILE
	selected_data = {
		"position": pos,
		"tile": tile_data
	}
	selection_changed.emit(current_type, selected_data)

func select_object(obj_data: Dictionary) -> void:
	current_type = SelectionType.OBJECT
	selected_data = obj_data
	selection_changed.emit(current_type, selected_data)

func clear_selection() -> void:
	current_type = SelectionType.NONE
	selected_data.clear()
	selection_changed.emit(current_type, selected_data)

func has_selection() -> bool:
	return current_type != SelectionType.NONE
"""
	var f3 = FileAccess.open("res://editor/world_builder/selection_manager.gd", FileAccess.WRITE)
	if f3: f3.store_string(selection_code); f3.close()

	# 4. asset_palette.gd
	var palette_code = """class_name AssetPalette
extends PanelContainer

## Left-side Asset Palette displaying categorized game assets for painting.

signal asset_selected(asset_info: Dictionary)

@onready var search_edit: LineEdit = $MarginContainer/VBoxContainer/SearchEdit
@onready var tab_container: TabContainer = $MarginContainer/VBoxContainer/TabContainer

var categories: Dictionary = {
	"Terrain": [
		{ "id": "grass", "name": "Grass", "type": "tile", "layer": "TERRAIN", "walkable": true, "solid": false, "interactable": false },
		{ "id": "soil", "name": "Tillable Soil", "type": "tile", "layer": "TERRAIN", "walkable": true, "solid": false, "interactable": false },
		{ "id": "path", "name": "Stone Path", "type": "tile", "layer": "TERRAIN", "walkable": true, "solid": false, "interactable": false },
		{ "id": "fence", "name": "Wooden Fence", "type": "tile", "layer": "TERRAIN", "walkable": false, "solid": true, "interactable": false },
		{ "id": "water", "name": "Pond Water", "type": "tile", "layer": "TERRAIN", "walkable": false, "solid": true, "interactable": false }
	],
	"Nature": [
		{ "id": "ancient_tree", "name": "Ancient Mossy Tree", "type": "object", "layer": "DECORATION", "walkable": false, "solid": true, "interactable": false },
		{ "id": "pond", "name": "Botanical Pond", "type": "object", "layer": "DECORATION", "walkable": false, "solid": true, "interactable": false },
		{ "id": "wooden_gate", "name": "Wooden Arch Gate", "type": "object", "layer": "OBJECT", "walkable": true, "solid": false, "interactable": true }
	],
	"Plants": [
		{ "id": "red_flower", "name": "Red Flower", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "blue_flower", "name": "Blue Flower", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "yellow_herb", "name": "Yellow Herb", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "green_vine", "name": "Green Vine", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "white_lily", "name": "White Lily", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "moon_orchid", "name": "Moon Orchid", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "glass_fern", "name": "Glass Fern", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "star_moss", "name": "Star Moss", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true }
	],
	"Objects": [
		{ "id": "chest", "name": "Storage Chest", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true },
		{ "id": "bench", "name": "Garden Bench", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": false },
		{ "id": "signpost", "name": "Wooden Signpost", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true }
	],
	"Buildings": [
		{ "id": "greenhouse_ruined", "name": "Ruined Greenhouse", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true },
		{ "id": "greenhouse_repaired", "name": "Repaired Greenhouse", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true },
		{ "id": "market_stall", "name": "Rowan Market Stall", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true }
	],
	"NPC": [
		{ "id": "merchant", "name": "Rowan (Merchant NPC)", "type": "object", "layer": "NPC", "walkable": false, "solid": true, "interactable": true },
		{ "id": "player_start", "name": "Player Spawn Point", "type": "object", "layer": "NPC", "walkable": true, "solid": false, "interactable": false }
	]
}

var selected_asset: Dictionary = {}

func _ready() -> void:
	if search_edit:
		search_edit.text_changed.connect(func(_t): _populate_palette())
	_populate_palette()

func _populate_palette() -> void:
	if not tab_container:
		return
		
	# Clear existing tabs
	for child in tab_container.get_children():
		child.queue_free()
		
	var filter = search_edit.text.to_lower() if search_edit else ""
	
	for cat_name in categories.keys():
		var scroll = ScrollContainer.new()
		scroll.name = cat_name
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var grid = GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(grid)
		
		var items = categories[cat_name]
		for item in items:
			var iname = str(item.get("name", item["id"]))
			if filter != "" and not iname.to_lower().contains(filter) and not str(item["id"]).to_lower().contains(filter):
				continue
				
			var btn = Button.new()
			btn.text = iname
			btn.custom_minimum_size = Vector2(100, 36)
			btn.add_theme_font_size_override("font_size", 10)
			btn.clip_text = true
			
			var tex = _resolve_asset_icon(item["id"], item.get("type", "tile"))
			if tex:
				btn.icon = tex
				btn.expand_icon = true
				
			btn.pressed.connect(func(): _on_asset_clicked(item, btn))
			grid.add_child(btn)
			
		tab_container.add_child(scroll)
		
	# Select first item by default if none selected
	if selected_asset.is_empty() and categories["Terrain"].size() > 0:
		selected_asset = categories["Terrain"][0]

func _resolve_asset_icon(asset_id: String, type: String) -> Texture2D:
	if type == "tile":
		var path = "res://assets/sprites/tiles/%s.png" % asset_id
		if ResourceLoader.exists(path): return ResourceLoader.load(path)
	elif type == "plant":
		var path = "res://assets/sprites/plants/%s_stage_3.png" % asset_id
		if ResourceLoader.exists(path): return ResourceLoader.load(path)
	elif type == "object" or type == "npc":
		var path_env = "res://assets/sprites/environment/%s.png" % asset_id
		if ResourceLoader.exists(path_env): return ResourceLoader.load(path_env)
		var path_npc = "res://assets/sprites/npc/%s_idle_0.png" % asset_id
		if ResourceLoader.exists(path_npc): return ResourceLoader.load(path_npc)
		var path_item = "res://assets/sprites/items/%s.png" % asset_id
		if ResourceLoader.exists(path_item): return ResourceLoader.load(path_item)
	return null

func _on_asset_clicked(item: Dictionary, _btn: Button) -> void:
	selected_asset = item
	asset_selected.emit(item)
"""
	var f4 = FileAccess.open("res://editor/world_builder/asset_palette.gd", FileAccess.WRITE)
	if f4: f4.store_string(palette_code); f4.close()

	# 5. world_inspector.gd
	var inspector_code = """class_name WorldInspector
extends PanelContainer

## Right-side Inspector panel allowing real-time property inspection and editing.

signal property_changed(target_data: Dictionary, prop_name: String, new_val: Variant)

@onready var title_label: Label = $MarginContainer/VBoxContainer/Header/TitleLabel
@onready var asset_id_label: Label = $MarginContainer/VBoxContainer/PropsContainer/AssetIdHBox/AssetIdValue
@onready var instance_id_edit: LineEdit = $MarginContainer/VBoxContainer/PropsContainer/InstanceHBox/InstanceEdit
@onready var pos_x_spin: SpinBox = $MarginContainer/VBoxContainer/PropsContainer/PosHBox/XSpin
@onready var pos_y_spin: SpinBox = $MarginContainer/VBoxContainer/PropsContainer/PosHBox/YSpin
@onready var layer_opt: OptionButton = $MarginContainer/VBoxContainer/PropsContainer/LayerHBox/LayerOption
@onready var walkable_check: CheckBox = $MarginContainer/VBoxContainer/PropsContainer/WalkableCheck
@onready var solid_check: CheckBox = $MarginContainer/VBoxContainer/PropsContainer/SolidCheck
@onready var interactable_check: CheckBox = $MarginContainer/VBoxContainer/PropsContainer/InteractableCheck
@onready var props_container: VBoxContainer = $MarginContainer/VBoxContainer/PropsContainer
@onready var empty_label: Label = $MarginContainer/VBoxContainer/EmptyLabel

var current_target: Dictionary = {}
var is_updating_ui: bool = false

func _ready() -> void:
	_setup_layer_options()
	_bind_events()
	clear_inspector()

func _setup_layer_options() -> void:
	if not layer_opt:
		return
	layer_opt.clear()
	var layers = ["GROUND", "TERRAIN", "DECORATION", "OBJECT", "NPC", "OVERLAY"]
	for l in layers:
		layer_opt.add_item(l)

func _bind_events() -> void:
	if instance_id_edit:
		instance_id_edit.text_submitted.connect(func(t): _on_field_changed("instance_id", t))
	if pos_x_spin:
		pos_x_spin.value_changed.connect(func(v): _on_field_changed("pos_x", int(v)))
	if pos_y_spin:
		pos_y_spin.value_changed.connect(func(v): _on_field_changed("pos_y", int(v)))
	if layer_opt:
		layer_opt.item_selected.connect(func(idx): _on_field_changed("layer", layer_opt.get_item_text(idx)))
	if walkable_check:
		walkable_check.toggled.connect(func(b): _on_field_changed("walkable", b))
	if solid_check:
		solid_check.toggled.connect(func(b): _on_field_changed("solid", b))
	if interactable_check:
		interactable_check.toggled.connect(func(b): _on_field_changed("interactable", b))

func inspect(type: SelectionManager.SelectionType, data: Dictionary) -> void:
	current_target = data
	if type == SelectionManager.SelectionType.NONE or data.is_empty():
		clear_inspector()
		return
		
	is_updating_ui = true
	if empty_label: empty_label.visible = false
	if props_container: props_container.visible = true
	
	if type == SelectionManager.SelectionType.TILE:
		var pos = data.get("position", Vector2i.ZERO)
		var tile = data.get("tile", {})
		if title_label: title_label.text = "🏷️ Tile Inspector"
		if asset_id_label: asset_id_label.text = str(tile.get("type", "grass"))
		if instance_id_edit: instance_id_edit.text = "tile_%d_%d" % [pos.x, pos.y]; instance_id_edit.editable = false
		if pos_x_spin: pos_x_spin.value = pos.x; pos_x_spin.editable = false
		if pos_y_spin: pos_y_spin.value = pos.y; pos_y_spin.editable = false
		_select_layer_option(tile.get("layer", "TERRAIN"))
		if walkable_check: walkable_check.button_pressed = bool(tile.get("walkable", true))
		if solid_check: solid_check.button_pressed = bool(tile.get("solid", false))
		if interactable_check: interactable_check.button_pressed = bool(tile.get("interactable", false))
	elif type == SelectionManager.SelectionType.OBJECT:
		var pos_arr = data.get("position", [0, 0])
		var props = data.get("properties", {})
		if title_label: title_label.text = "📦 Object Inspector"
		if asset_id_label: asset_id_label.text = str(data.get("asset_id", "object"))
		if instance_id_edit: instance_id_edit.text = str(data.get("instance_id", "obj")); instance_id_edit.editable = true
		if pos_x_spin: pos_x_spin.value = pos_arr[0]; pos_x_spin.editable = true
		if pos_y_spin: pos_y_spin.value = pos_arr[1]; pos_y_spin.editable = true
		_select_layer_option(data.get("layer", "OBJECT"))
		if walkable_check: walkable_check.button_pressed = bool(props.get("walkable", false))
		if solid_check: solid_check.button_pressed = bool(props.get("solid", true))
		if interactable_check: interactable_check.button_pressed = bool(props.get("interactable", true))
		
	is_updating_ui = false

func clear_inspector() -> void:
	current_target.clear()
	if title_label: title_label.text = "Inspector"
	if empty_label: empty_label.visible = true
	if props_container: props_container.visible = false

func _select_layer_option(layer_name: String) -> void:
	if not layer_opt: return
	for i in range(layer_opt.item_count):
		if layer_opt.get_item_text(i) == layer_name:
			layer_opt.select(i)
			return

func _on_field_changed(field: String, val: Variant) -> void:
	if is_updating_ui or current_target.is_empty():
		return
	property_changed.emit(current_target, field, val)
"""
	var f5 = FileAccess.open("res://editor/world_builder/world_inspector.gd", FileAccess.WRITE)
	if f5: f5.store_string(inspector_code); f5.close()

	# 6. world_canvas.gd
	var canvas_code = """class_name WorldCanvas
extends Control

## Central 2D viewport rendering the map grid, objects, cursor highlights, and tool actions.

enum ToolMode { SELECT, BRUSH, ERASER, RECTANGLE, FILL }

signal hover_coord_changed(coord: Vector2i)
signal map_modified()

var current_tool: ToolMode = ToolMode.BRUSH
var show_grid_lines: bool = true
var show_collision_debug: bool = false
var zoom_level: float = 1.5
var pan_offset: Vector2 = Vector2(40, 40)

var world_data: Dictionary = {}
var hovered_tile: Vector2i = Vector2i(-1, -1)
var is_middle_panning: bool = false
var pan_start_pos: Vector2 = Vector2.ZERO

var rect_drag_start: Vector2i = Vector2i(-1, -1)
var is_rect_dragging: bool = false

var history: EditorHistory
var selection: SelectionManager
var palette: AssetPalette

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
		
	# Mouse Wheel Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom_level = clampf(zoom_level + 0.1, 0.5, 3.5)
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom_level = clampf(zoom_level - 0.1, 0.5, 3.5)
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			is_middle_panning = event.pressed
			pan_start_pos = event.position
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_left_click_down(hovered_tile)
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
				if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_tool == ToolMode.BRUSH:
					_paint_tile(hovered_tile)
				elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and current_tool == ToolMode.ERASER:
					_erase_at(hovered_tile)
				queue_redraw()

func _on_left_click_down(pos: Vector2i) -> void:
	if not _is_valid_coord(pos):
		return
		
	match current_tool:
		ToolMode.SELECT:
			# Check object first, then tile
			var obj = _get_object_at(pos)
			if not obj.is_empty():
				if selection: selection.select_object(obj)
			else:
				var t = _get_tile_at(pos)
				if selection: selection.select_tile(pos, t)
		ToolMode.BRUSH:
			_paint_tile(pos)
		ToolMode.ERASER:
			_erase_at(pos)
		ToolMode.RECTANGLE:
			rect_drag_start = pos
			is_rect_dragging = true
		ToolMode.FILL:
			_flood_fill(pos)
	queue_redraw()

func _on_left_click_up(pos: Vector2i) -> void:
	if is_rect_dragging and current_tool == ToolMode.RECTANGLE:
		is_rect_dragging = false
		_paint_rect(rect_drag_start, pos)
		rect_drag_start = Vector2i(-1, -1)
		queue_redraw()

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
	if asset_type == "tile":
		var old_tile = _get_tile_at(pos).duplicate(true)
		var new_type = asset["id"]
		var walkable = bool(asset.get("walkable", true))
		var solid = bool(asset.get("solid", false))
		var interactable = bool(asset.get("interactable", false))
		
		# Set tile
		for t in world_data.get("tiles", []):
			if t["x"] == pos.x and t["y"] == pos.y:
				t["type"] = new_type
				t["walkable"] = walkable
				t["solid"] = solid
				t["interactable"] = interactable
				break
				
		if history:
			history.push_action({
				"type": "TILE_PAINT",
				"pos": pos,
				"old_tile": old_tile,
				"new_type": new_type
			})
	elif asset_type == "object" or asset_type == "plant" or asset_type == "npc":
		# Add object instance
		var inst_id = "%s_%d_%d" % [asset["id"], pos.x, pos.y]
		# Remove existing object at pos if any
		_remove_object_at(pos)
		
		var obj = {
			"instance_id": inst_id,
			"asset_id": asset["id"],
			"name": asset.get("name", asset["id"]),
			"position": [pos.x, pos.y],
			"layer": asset.get("layer", "OBJECT"),
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
			
	map_modified.emit()
	queue_redraw()

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
	# 1. If object exists, delete object
	if _remove_object_at(pos):
		map_modified.emit()
		return
		
	# 2. Reset tile to grass
	for t in world_data.get("tiles", []):
		if t["x"] == pos.x and t["y"] == pos.y:
			t["type"] = "grass"
			t["walkable"] = true
			t["solid"] = false
			t["interactable"] = false
			break
	map_modified.emit()

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

func _remove_object_at(pos: Vector2i) -> bool:
	var objs = world_data.get("objects", [])
	for i in range(objs.size() - 1, -1, -1):
		var p = objs[i].get("position", [-1, -1])
		if p[0] == pos.x and p[1] == pos.y:
			objs.remove_at(i)
			return true
	return false

func _is_valid_coord(pos: Vector2i) -> bool:
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	return pos.x >= 0 and pos.x < w and pos.y >= 0 and pos.y < h

func _draw() -> void:
	if world_data.is_empty():
		return
		
	var w = int(world_data.get("width", 32))
	var h = int(world_data.get("height", 24))
	var ts = 16.0 * zoom_level
	
	# Draw Background
	draw_rect(Rect2(pan_offset, Vector2(w * ts, h * ts)), Color(0.1, 0.1, 0.1, 1.0))
	
	# Draw Tiles
	for t in world_data.get("tiles", []):
		var rx = pan_offset.x + t["x"] * ts
		var ry = pan_offset.y + t["y"] * ts
		var rect = Rect2(rx, ry, ts, ts)
		var t_type = t.get("type", "grass")
		
		var col = Color(0.31, 0.47, 0.18) # grass
		if t_type == "soil": col = Color(0.35, 0.18, 0.05)
		elif t_type == "path": col = Color(0.72, 0.64, 0.53)
		elif t_type == "fence": col = Color(0.44, 0.28, 0.15)
		elif t_type == "water": col = Color(0.25, 0.50, 0.85)
		
		draw_rect(rect, col)
		
		# Custom sprite texture if available
		var tex = AssetRegistry.get_tile_texture(t_type) if t_type in ["grass", "soil", "path", "fence"] else null
		if tex:
			draw_texture_rect(tex, rect, false)
			
	# Draw Objects
	for o in world_data.get("objects", []):
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
				draw_rect(rect, Color(1.0, 0.2, 0.2, 0.35)) # Solid Red
			elif t.get("interactable", false):
				draw_rect(rect, Color(1.0, 0.9, 0.2, 0.35)) # Interactable Yellow
			else:
				draw_rect(rect, Color(0.2, 1.0, 0.2, 0.20)) # Walkable Green
				
	# Grid Lines
	if show_grid_lines:
		for x in range(w + 1):
			var p1 = pan_offset + Vector2(x * ts, 0)
			var p2 = pan_offset + Vector2(x * ts, h * ts)
			draw_line(p1, p2, Color(0.0, 0.0, 0.0, 0.25), 1.0)
		for y in range(h + 1):
			var p1 = pan_offset + Vector2(0, y * ts)
			var p2 = pan_offset + Vector2(w * ts, y * ts)
			draw_line(p1, p2, Color(0.0, 0.0, 0.0, 0.25), 1.0)
			
	# Hover Highlight
	if _is_valid_coord(hovered_tile):
		var hx = pan_offset.x + hovered_tile.x * ts
		var hy = pan_offset.y + hovered_tile.y * ts
		draw_rect(Rect2(hx, hy, ts, ts), Color(1.0, 1.0, 0.3, 0.4), false, 2.0)
		
	# Selection Highlight
	if selection and selection.has_selection():
		var sel_pos = Vector2i(-1, -1)
		if selection.current_type == SelectionManager.SelectionType.TILE:
			sel_pos = selection.selected_data.get("position", Vector2i(-1, -1))
		elif selection.current_type == SelectionManager.SelectionType.OBJECT:
			var p = selection.selected_data.get("position", [-1, -1])
			sel_pos = Vector2i(p[0], p[1])
			
		if _is_valid_coord(sel_pos):
			var sx = pan_offset.x + sel_pos.x * ts
			var sy = pan_offset.y + sel_pos.y * ts
			draw_rect(Rect2(sx, sy, ts, ts), Color(0.3, 0.8, 1.0, 0.9), false, 3.0)

func _resolve_obj_texture(asset_id: String) -> Texture2D:
	var path_env = "res://assets/sprites/environment/%s.png" % asset_id
	if ResourceLoader.exists(path_env): return ResourceLoader.load(path_env)
	var path_npc = "res://assets/sprites/npc/%s_idle_0.png" % asset_id
	if ResourceLoader.exists(path_npc): return ResourceLoader.load(path_npc)
	var path_plant = "res://assets/sprites/plants/%s_stage_3.png" % asset_id
	if ResourceLoader.exists(path_plant): return ResourceLoader.load(path_plant)
	return null
"""
	var f6 = FileAccess.open("res://editor/world_builder/world_canvas.gd", FileAccess.WRITE)
	if f6: f6.store_string(canvas_code); f6.close()

	# 7. world_builder.gd
	var main_code = """class_name WorldBuilder
extends Control

## Main Level Editor / World Builder developer suite coordinator.

@onready var palette: AssetPalette = $HSplit/LeftPanel/AssetPalette
@onready var canvas: WorldCanvas = $HSplit/CenterArea/WorldCanvas
@onready var inspector: WorldInspector = $HSplit/RightPanel/WorldInspector

@onready var save_btn: Button = $TopBar/MarginContainer/HBox/SaveButton
@onready var open_btn: Button = $TopBar/MarginContainer/HBox/OpenButton
@onready var new_btn: Button = $TopBar/MarginContainer/HBox/NewButton

@onready var tool_select_btn: Button = $TopBar/MarginContainer/HBox/ToolSelect
@onready var tool_brush_btn: Button = $TopBar/MarginContainer/HBox/ToolBrush
@onready var tool_eraser_btn: Button = $TopBar/MarginContainer/HBox/ToolEraser
@onready var tool_rect_btn: Button = $TopBar/MarginContainer/HBox/ToolRect
@onready var tool_fill_btn: Button = $TopBar/MarginContainer/HBox/ToolFill

@onready var toggle_grid_btn: Button = $TopBar/MarginContainer/HBox/ToggleGrid
@onready var toggle_collision_btn: Button = $TopBar/MarginContainer/HBox/ToggleCollision

@onready var undo_btn: Button = $TopBar/MarginContainer/HBox/UndoButton
@onready var redo_btn: Button = $TopBar/MarginContainer/HBox/RedoButton
@onready var status_label: Label = $TopBar/MarginContainer/HBox/StatusLabel

var history: EditorHistory
var selection: SelectionManager
var current_world_path: String = "res://data/worlds/farm.json"
var world_data: Dictionary = {}

func _ready() -> void:
	history = EditorHistory.new()
	selection = SelectionManager.new()
	
	_bind_topbar()
	_load_world(current_world_path)
	
	if canvas:
		canvas.setup(world_data, history, selection, palette)
		canvas.hover_coord_changed.connect(_on_hover_coord_changed)
		canvas.map_modified.connect(_on_map_modified)
		
	if selection:
		selection.selection_changed.connect(func(t, d): if inspector: inspector.inspect(t, d))
		
	if inspector:
		inspector.property_changed.connect(_on_inspector_property_changed)
		
	if history:
		history.history_changed.connect(_update_history_buttons)
		
	_set_tool(WorldCanvas.ToolMode.BRUSH)

func _bind_topbar() -> void:
	if save_btn: save_btn.pressed.connect(_save_current_world)
	if open_btn: open_btn.pressed.connect(func(): _load_world("res://data/worlds/farm.json"))
	if new_btn: new_btn.pressed.connect(_new_world)
	
	if tool_select_btn: tool_select_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.SELECT))
	if tool_brush_btn: tool_brush_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.BRUSH))
	if tool_eraser_btn: tool_eraser_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.ERASER))
	if tool_rect_btn: tool_rect_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.RECTANGLE))
	if tool_fill_btn: tool_fill_btn.pressed.connect(func(): _set_tool(WorldCanvas.ToolMode.FILL))
	
	if toggle_grid_btn: toggle_grid_btn.pressed.connect(_toggle_grid)
	if toggle_collision_btn: toggle_collision_btn.pressed.connect(_toggle_collision)
	
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
		if toggle_grid_btn:
			toggle_grid_btn.modulate = Color(1.3, 1.3, 0.8) if canvas.show_grid_lines else Color.WHITE
		canvas.queue_redraw()

func _toggle_collision() -> void:
	if canvas:
		canvas.show_collision_debug = not canvas.show_collision_debug
		if toggle_collision_btn:
			toggle_collision_btn.modulate = Color(1.3, 1.3, 0.8) if canvas.show_collision_debug else Color.WHITE
		canvas.queue_redraw()

func _load_world(path: String) -> void:
	world_data = WorldSerializer.load_world(path)
	current_world_path = path
	if canvas:
		canvas.setup(world_data, history, selection, palette)
	if history: history.clear()
	if selection: selection.clear_selection()
	if status_label: status_label.text = "Loaded: %s (%dx%d)" % [world_data.get("name", "World"), world_data.get("width", 32), world_data.get("height", 24)]

func _save_current_world() -> void:
	WorldSerializer.save_world(current_world_path, world_data)
	if status_label: status_label.text = "💾 Saved to %s" % current_world_path

func _new_world() -> void:
	world_data = WorldSerializer.create_empty_world(32, 24)
	if canvas:
		canvas.setup(world_data, history, selection, palette)
	if history: history.clear()
	if selection: selection.clear_selection()
	if status_label: status_label.text = "Created New 32x24 World"

func _undo() -> void:
	if not history or not history.can_undo():
		return
	var action = history.undo()
	_apply_history_action(action, true)

func _redo() -> void:
	if not history or not history.can_redo():
		return
	var action = history.redo()
	_apply_history_action(action, false)

func _apply_history_action(action: Dictionary, is_undo: bool) -> void:
	var atype = action.get("type", "")
	if atype == "TILE_PAINT":
		var pos = action["pos"]
		var tile_to_set = action["old_tile"] if is_undo else { "type": action["new_type"] }
		for t in world_data.get("tiles", []):
			if t["x"] == pos.x and t["y"] == pos.y:
				t["type"] = tile_to_set.get("type", "grass")
				break
	if canvas: canvas.queue_redraw()

func _update_history_buttons() -> void:
	if undo_btn: undo_btn.disabled = not (history and history.can_undo())
	if redo_btn: redo_btn.disabled = not (history and history.can_redo())

func _on_hover_coord_changed(pos: Vector2i) -> void:
	if status_label:
		status_label.text = "Tile: (%d, %d) | Tool: %s" % [pos.x, pos.y, WorldCanvas.ToolMode.keys()[canvas.current_tool]]

func _on_map_modified() -> void:
	if canvas: canvas.queue_redraw()

func _on_inspector_property_changed(target: Dictionary, field: String, val: Variant) -> void:
	if target.has("properties"):
		target["properties"][field] = val
	elif target.has("tile"):
		target["tile"][field] = val
	if canvas: canvas.queue_redraw()
"""
	var f7 = FileAccess.open("res://editor/world_builder/world_builder.gd", FileAccess.WRITE)
	if f7: f7.store_string(main_code); f7.close()

	print("[WorldBuilderCodeGenerator] Generated all 7 GDScript classes!")
