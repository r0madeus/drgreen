@tool
extends SceneTree

func _init() -> void:
	enhance_ui_scripts()
	quit()

static func enhance_ui_scripts() -> void:
	# 1. asset_palette.gd
	var palette_code = """class_name AssetPalette
extends PanelContainer

## Left-side Asset Palette displaying categorized game assets and prefabs for painting.

signal asset_selected(asset_info: Dictionary)

var search_edit: LineEdit
var tab_container: TabContainer

var categories: Dictionary = {
	"Terrain": [
		{ "id": "grass", "name": "Grass", "type": "tile", "layer": "GROUND", "walkable": true, "solid": false, "interactable": false },
		{ "id": "soil", "name": "Tillable Soil", "type": "tile", "layer": "TERRAIN", "walkable": true, "solid": false, "interactable": false },
		{ "id": "path", "name": "Stone Path", "type": "tile", "layer": "GROUND", "walkable": true, "solid": false, "interactable": false },
		{ "id": "fence", "name": "Wooden Fence", "type": "tile", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": false },
		{ "id": "water", "name": "Pond Water", "type": "tile", "layer": "GROUND", "walkable": false, "solid": true, "interactable": false }
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
	],
	"Prefabs": []
}

var selected_asset: Dictionary = {}

func _ready() -> void:
	search_edit = find_child("SearchEdit", true, false) as LineEdit
	tab_container = find_child("TabContainer", true, false) as TabContainer
	if search_edit:
		search_edit.text_changed.connect(func(_t): _populate_palette())
	refresh_prefabs_list()
	_populate_palette()

func refresh_prefabs_list() -> void:
	categories["Prefabs"] = []
	var dir = DirAccess.open("res://data/prefabs/")
	if dir:
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if not dir.current_is_dir() and fname.ends_with(".json"):
				var data = WorldSerializer.load_prefab("res://data/prefabs/" + fname)
				if not data.is_empty():
					categories["Prefabs"].append({
						"id": data.get("id", fname.get_basename()),
						"name": data.get("name", fname.get_basename()),
						"type": "prefab",
						"layer": "OBJECT",
						"prefab_data": data
					})
			fname = dir.get_next()
		dir.list_dir_end()

func _populate_palette() -> void:
	if not tab_container:
		return
		
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
	elif type == "prefab":
		var path_p = "res://assets/sprites/ui/icon_lab.png"
		if ResourceLoader.exists(path_p): return ResourceLoader.load(path_p)
	return null

func _on_asset_clicked(item: Dictionary, _btn: Button) -> void:
	selected_asset = item
	asset_selected.emit(item)
"""
	var f1 = FileAccess.open("res://editor/world_builder/asset_palette.gd", FileAccess.WRITE)
	if f1: f1.store_string(palette_code); f1.close()

	# 2. world_inspector.gd with Multi-Selection & Quick Presets
	var inspector_code = """class_name WorldInspector
extends PanelContainer

## Right-side Inspector panel allowing single & multi-property editing and quick presets.

signal property_changed(target_data: Dictionary, prop_name: String, new_val: Variant)
signal multi_property_changed(targets: Array, prop_name: String, new_val: Variant)
signal preset_applied(preset_name: String, targets: Array)

var title_label: Label
var asset_id_label: Label
var instance_id_edit: LineEdit
var pos_x_spin: SpinBox
var pos_y_spin: SpinBox
var layer_opt: OptionButton
var walkable_check: CheckBox
var solid_check: CheckBox
var interactable_check: CheckBox
var props_container: VBoxContainer
var empty_label: Label

var current_mode: SelectionManager.SelectionMode = SelectionManager.SelectionMode.NONE
var current_targets: Array = []
var is_updating_ui: bool = false

func _ready() -> void:
	title_label = find_child("TitleLabel", true, false) as Label
	asset_id_label = find_child("AssetIdValue", true, false) as Label
	instance_id_edit = find_child("InstanceEdit", true, false) as LineEdit
	pos_x_spin = find_child("XSpin", true, false) as SpinBox
	pos_y_spin = find_child("YSpin", true, false) as SpinBox
	layer_opt = find_child("LayerOption", true, false) as OptionButton
	walkable_check = find_child("WalkableCheck", true, false) as CheckBox
	solid_check = find_child("SolidCheck", true, false) as CheckBox
	interactable_check = find_child("InteractableCheck", true, false) as CheckBox
	props_container = find_child("PropsContainer", true, false) as VBoxContainer
	empty_label = find_child("EmptyLabel", true, false) as Label

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

	# Quick Presets Buttons
	var p_walk = find_child("PresetWalkable", true, false) as Button
	if p_walk: p_walk.pressed.connect(func(): apply_preset("WALKABLE"))
	var p_sol = find_child("PresetSolid", true, false) as Button
	if p_sol: p_sol.pressed.connect(func(): apply_preset("SOLID"))
	var p_int = find_child("PresetInteractable", true, false) as Button
	if p_int: p_int.pressed.connect(func(): apply_preset("INTERACTABLE"))
	var p_dec = find_child("PresetDecoration", true, false) as Button
	if p_dec: p_dec.pressed.connect(func(): apply_preset("DECORATION"))

func inspect(mode: SelectionManager.SelectionMode, items: Array) -> void:
	current_mode = mode
	current_targets = items
	
	if mode == SelectionManager.SelectionMode.NONE or items.is_empty():
		clear_inspector()
		return
		
	is_updating_ui = true
	if empty_label: empty_label.visible = false
	if props_container: props_container.visible = true
	
	if mode == SelectionManager.SelectionMode.SINGLE_TILE:
		var data = items[0]
		var pos = data.get("position", Vector2i.ZERO)
		var tile = data.get("tile", {})
		if title_label: title_label.text = "🏷️ Tile Inspector"
		if asset_id_label: asset_id_label.text = str(tile.get("type", "grass"))
		if instance_id_edit: instance_id_edit.text = "tile_%d_%d" % [pos.x, pos.y]; instance_id_edit.editable = false
		if pos_x_spin: pos_x_spin.value = pos.x; pos_x_spin.editable = false
		if pos_y_spin: pos_y_spin.value = pos.y; pos_y_spin.editable = false
		_select_layer_option(tile.get("layer", "GROUND"))
		if walkable_check: walkable_check.button_pressed = bool(tile.get("walkable", true))
		if solid_check: solid_check.button_pressed = bool(tile.get("solid", false))
		if interactable_check: interactable_check.button_pressed = bool(tile.get("interactable", false))
		
	elif mode == SelectionManager.SelectionMode.SINGLE_OBJECT:
		var data = items[0]
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
		
	elif mode == SelectionManager.SelectionMode.MULTI_OBJECT:
		if title_label: title_label.text = "📦 Multi-Selection (%d items)" % items.size()
		if asset_id_label: asset_id_label.text = "Multiple Objects"
		if instance_id_edit: instance_id_edit.text = "(Multiple)"; instance_id_edit.editable = false
		if pos_x_spin: pos_x_spin.value = 0; pos_x_spin.editable = false
		if pos_y_spin: pos_y_spin.value = 0; pos_y_spin.editable = false
		
		# Check common layer / flags
		var first_layer = items[0].get("layer", "OBJECT")
		var all_same_layer = true
		for o in items:
			if o.get("layer", "OBJECT") != first_layer:
				all_same_layer = false
				break
		if all_same_layer: _select_layer_option(first_layer)
		
	is_updating_ui = false

func apply_preset(preset: String) -> void:
	if current_targets.is_empty():
		return
		
	match preset:
		"WALKABLE":
			if walkable_check: walkable_check.button_pressed = true
			if solid_check: solid_check.button_pressed = false
			if interactable_check: interactable_check.button_pressed = false
		"SOLID":
			if walkable_check: walkable_check.button_pressed = false
			if solid_check: solid_check.button_pressed = true
			if interactable_check: interactable_check.button_pressed = false
		"INTERACTABLE":
			if walkable_check: walkable_check.button_pressed = false
			if solid_check: solid_check.button_pressed = true
			if interactable_check: interactable_check.button_pressed = true
		"DECORATION":
			if walkable_check: walkable_check.button_pressed = true
			if solid_check: solid_check.button_pressed = false
			if interactable_check: interactable_check.button_pressed = false
			_select_layer_option("DECORATION")
			
	preset_applied.emit(preset, current_targets)

func clear_inspector() -> void:
	current_targets.clear()
	current_mode = SelectionManager.SelectionMode.NONE
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
	if is_updating_ui or current_targets.is_empty():
		return
	if current_mode == SelectionManager.SelectionMode.MULTI_OBJECT:
		multi_property_changed.emit(current_targets, field, val)
	else:
		property_changed.emit(current_targets[0], field, val)
"""
	var f2 = FileAccess.open("res://editor/world_builder/world_inspector.gd", FileAccess.WRITE)
	if f2: f2.store_string(inspector_code); f2.close()

	print("[WorldBuilderUIEnhancer] Generated updated AssetPalette & WorldInspector!")
