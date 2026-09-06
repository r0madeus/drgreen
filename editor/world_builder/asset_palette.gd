class_name AssetPalette
extends PanelContainer

## Left-side Asset Palette with Search, Filter Categories, Nature, Buildings, Interactive & NPC entities.

signal asset_selected(asset_info: Dictionary)
signal customize_asset_requested(asset_id: String, asset_info: Dictionary)

var search_edit: LineEdit
var tab_container: TabContainer
var context_menu: PopupMenu
var _context_asset: Dictionary = {}

var categories: Dictionary = {
	"All": [],
	"Terrain": [
		{ "id": "grass", "name": "Grass", "type": "tile", "layer": "GROUND", "walkable": true, "solid": false, "interactable": false },
		{ "id": "soil", "name": "Tillable Soil", "type": "tile", "layer": "TERRAIN", "walkable": true, "solid": false, "interactable": false },
		{ "id": "path", "name": "Stone Path", "type": "tile", "layer": "GROUND", "walkable": true, "solid": false, "interactable": false },
		{ "id": "fence", "name": "Wooden Fence", "type": "tile", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": false },
		{ "id": "water", "name": "Pond Water", "type": "tile", "layer": "GROUND", "walkable": false, "solid": true, "interactable": false },
		{ "id": "sand", "name": "Golden Sand", "type": "tile", "layer": "GROUND", "walkable": true, "solid": false, "interactable": false },
		{ "id": "stone", "name": "Cobblestone", "type": "tile", "layer": "GROUND", "walkable": true, "solid": false, "interactable": false }
	],
	"Nature": [
		{ "id": "tree", "name": "Oak Tree", "type": "object", "layer": "DECORATION", "walkable": false, "solid": true, "interactable": false },
		{ "id": "ancient_tree", "name": "Ancient Mossy Tree", "type": "object", "layer": "DECORATION", "walkable": false, "solid": true, "interactable": false },
		{ "id": "bush", "name": "Berry Bush", "type": "object", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": false },
		{ "id": "rock", "name": "Granite Boulder", "type": "object", "layer": "DECORATION", "walkable": false, "solid": true, "interactable": false },
		{ "id": "tree_stump", "name": "Tree Stump", "type": "object", "layer": "DECORATION", "walkable": false, "solid": true, "interactable": false },
		{ "id": "fallen_branch", "name": "Fallen Branch", "type": "object", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": false },
		{ "id": "mushroom", "name": "Wild Mushroom", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "pond", "name": "Botanical Pond", "type": "object", "layer": "DECORATION", "walkable": false, "solid": true, "interactable": false },
		{ "id": "red_flower", "name": "Red Flower", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "blue_flower", "name": "Blue Flower", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "yellow_herb", "name": "Yellow Herb", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true },
		{ "id": "moon_orchid", "name": "Moon Orchid", "type": "plant", "layer": "DECORATION", "walkable": true, "solid": false, "interactable": true }
	],
	"Buildings": [
		{ "id": "farm_house", "name": "Player Farmhouse", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "home_door" },
		{ "id": "seed_shop", "name": "Rowan Seed Shop", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "shop", "shop_id": "rowan_seed_shop" },
		{ "id": "laboratory", "name": "Botanical Research Lab", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "lab_door" },
		{ "id": "barn", "name": "Cattle Barn", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": false },
		{ "id": "storage_shed", "name": "Storage Shed", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "container", "container_id": "shed_storage" },
		{ "id": "greenhouse_repaired", "name": "Greenhouse Dome", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "greenhouse_portal" }
	],
	"Interactive": [
		{ "id": "chest", "name": "Storage Chest", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "container", "container_id": "chest_01" },
		{ "id": "signpost", "name": "Wooden Signpost", "type": "object", "layer": "OBJECT", "walkable": true, "solid": false, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "sign_welcome" },
		{ "id": "wooden_gate", "name": "Wooden Arch Gate", "type": "object", "layer": "OBJECT", "walkable": true, "solid": false, "interactable": true, "interaction_type": "custom" },
		{ "id": "well", "name": "Stone Water Well", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "resource", "interaction_id": "water_source" },
		{ "id": "workbench", "name": "Crafting Workbench", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "custom" },
		{ "id": "shipping_box", "name": "Crop Shipping Box", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": true, "interaction_type": "shop", "shop_id": "shipping_bin" },
		{ "id": "bench", "name": "Garden Bench", "type": "object", "layer": "OBJECT", "walkable": false, "solid": true, "interactable": false }
	],
	"NPC": [
		{ "id": "rowan", "name": "Rowan (Merchant NPC)", "type": "object", "layer": "NPC", "walkable": false, "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "rowan", "npc_id": "rowan" },
		{ "id": "mira", "name": "Mira (Researcher NPC)", "type": "object", "layer": "NPC", "walkable": false, "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "mira", "npc_id": "mira" },
		{ "id": "elias", "name": "Elias (Village NPC)", "type": "object", "layer": "NPC", "walkable": false, "solid": true, "interactable": true, "interaction_type": "dialogue", "dialogue_id": "elias", "npc_id": "elias" },
		{ "id": "player_start", "name": "Player Spawn Point", "type": "object", "layer": "NPC", "walkable": true, "solid": false, "interactable": false, "spawn_id": "default" }
	],
	"World Connection": [
		{ "id": "world_exit", "name": "World Exit / Portal", "type": "transition", "layer": "OBJECT", "walkable": true, "solid": false, "interactable": true, "interaction_type": "world_transition", "target_world": "town", "target_spawn": "from_farm", "direction": "north" },
		{ "id": "portal", "name": "Grove Magic Portal", "type": "transition", "layer": "OBJECT", "walkable": true, "solid": false, "interactable": true, "interaction_type": "world_transition", "target_world": "botanical_grove", "target_spawn": "default", "direction": "east" }
	],
	"Prefabs": []
}

var selected_asset: Dictionary = {}
var selected_category: String = "Terrain"

var preview_card: PanelContainer
var preview_icon: TextureRect
var preview_name: Label
var preview_info: Label

var selected_asset_id: String:
	get:
		return selected_asset.get("id", "")
	set(val):
		for cat in categories.values():
			for item in cat:
				if item.get("id", "") == val:
					_select_asset(item)
					return
		selected_asset["id"] = val

func _init() -> void:
	_build_ui()

func _ready() -> void:
	if search_edit:
		search_edit.text_changed.connect(func(_t): _populate_palette())
	refresh_prefabs_list()
	_populate_palette()
	if categories.has("Terrain") and categories["Terrain"].size() > 0:
		_select_asset(categories["Terrain"][0])

func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var root_vbox = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(root_vbox)

	var lbl = Label.new()
	lbl.text = "🎨 Asset Palette"
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.modulate = Color(0.92, 0.94, 0.98)
	root_vbox.add_child(lbl)

	# --- ACTIVE SELECTION CARD ---
	preview_card = PanelContainer.new()
	preview_card.custom_minimum_size = Vector2(0, 52)
	root_vbox.add_child(preview_card)

	var p_margin = MarginContainer.new()
	p_margin.add_theme_constant_override("margin_left", 8)
	p_margin.add_theme_constant_override("margin_top", 8)
	p_margin.add_theme_constant_override("margin_right", 8)
	p_margin.add_theme_constant_override("margin_bottom", 8)
	preview_card.add_child(p_margin)

	var p_hbox = HBoxContainer.new()
	p_hbox.add_theme_constant_override("separation", 12)
	p_margin.add_child(p_hbox)

	preview_icon = TextureRect.new()
	preview_icon.custom_minimum_size = Vector2(40, 40)
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p_hbox.add_child(preview_icon)

	var p_vbox = VBoxContainer.new()
	p_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_vbox.add_theme_constant_override("separation", 2)
	p_hbox.add_child(p_vbox)

	preview_name = Label.new()
	preview_name.text = "No Asset Selected"
	preview_name.add_theme_font_size_override("font_size", 14)
	p_vbox.add_child(preview_name)

	preview_info = Label.new()
	preview_info.text = "Select an asset from the categories below"
	preview_info.add_theme_font_size_override("font_size", 12)
	preview_info.modulate = Color(0.7, 0.7, 0.7)
	p_vbox.add_child(preview_info)

	var search_hbox = HBoxContainer.new()
	search_hbox.add_theme_constant_override("separation", 6)
	root_vbox.add_child(search_hbox)

	search_edit = LineEdit.new()
	search_edit.placeholder_text = "🔍 Search assets..."
	search_edit.custom_minimum_size = Vector2(0, 34)
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.add_theme_font_size_override("font_size", 13)
	search_hbox.add_child(search_edit)

	var sync_btn = Button.new()
	sync_btn.text = "🔄 Sync"
	sync_btn.custom_minimum_size = Vector2(75, 34)
	sync_btn.add_theme_font_size_override("font_size", 12)
	sync_btn.tooltip_text = "Scan all asset folders & auto-register new files"
	sync_btn.pressed.connect(_on_sync_pressed)
	search_hbox.add_child(sync_btn)

	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_theme_font_size_override("font_size", 13)
	root_vbox.add_child(tab_container)

	context_menu = PopupMenu.new()
	context_menu.add_item("⚙ Customize in Asset Editor...", 0)
	context_menu.add_item("📋 Copy Asset ID", 1)
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)
	add_child(context_menu)

func _on_context_menu_id_pressed(id: int) -> void:
	if _context_asset.is_empty(): return
	var aid = str(_context_asset.get("asset_id", _context_asset.get("id", "")))
	if id == 0:
		customize_asset_requested.emit(aid, _context_asset)
		var shell_cls = load("res://editor/ui/editor_shell.gd")
		if shell_cls and shell_cls.has_method("open_asset_in_editor"):
			shell_cls.open_asset_in_editor(aid)
	elif id == 1:
		DisplayServer.clipboard_set(aid)

func _show_asset_context_menu(asset: Dictionary, global_pos: Vector2) -> void:
	_context_asset = asset
	if context_menu:
		context_menu.position = Vector2i(global_pos)
		context_menu.popup()

func _on_sync_pressed() -> void:
	AssetRegistry.scan_and_sync_all_assets()
	refresh_assets_list()
	_populate_palette()

func refresh_prefabs_list() -> void:
	refresh_assets_list()

func refresh_assets_list() -> void:
	AssetRegistry.ensure_initialized()
	var pal_assets = AssetRegistry.get_all_palette_assets()
	for cat_k in pal_assets.keys():
		categories[cat_k] = pal_assets[cat_k]
		
	categories["Prefabs"] = []
	var files = DirAccess.get_files_at("res://data/prefabs/")
	if files:
		for fname in files:
			if fname.ends_with(".json"):
				var data = WorldSerializer.load_prefab("res://data/prefabs/" + fname)
				if not data.is_empty():
					categories["Prefabs"].append({
						"id": data.get("id", fname.get_basename()),
						"name": data.get("name", fname.get_basename()),
						"type": "prefab",
						"layer": "OBJECT",
						"prefab_data": data
					})

	if ClassDB.class_exists("AssetDefinitionManager"):
		var defs = AssetDefinitionManager.get_all_definitions()
		for asset_id in defs.keys():
			var def_data = defs[asset_id]
			var t = def_data.get("identity", {}).get("type", "object")
			var item = {
				"id": asset_id,
				"name": def_data.get("identity", {}).get("display_name", asset_id),
				"type": t,
				"layer": def_data.get("components", {}).get("visual", {}).get("layer", "OBJECT")
			}
			var props = AssetDefinitionManager.resolve_instance_properties(asset_id, {})
			for k in props.keys():
				item[k] = props[k]
			if "house" in asset_id or "shed" in asset_id or "barn" in asset_id:
				categories["Buildings"].append(item)
			elif item.get("interactable", false):
				categories["Interactive"].append(item)
			elif t == "NPC":
				categories["NPC"].append(item)
			else:
				categories["Nature"].append(item)
	
func _populate_palette() -> void:
	if not tab_container: return
	for child in tab_container.get_children(): child.queue_free()
	var filter = search_edit.text.to_lower() if search_edit else ""
	
	# Compile 'All'
	var all_items: Array = []
	for k in ["Terrain", "Nature", "Buildings", "Interactive", "NPC", "World Connection", "Prefabs"]:
		for item in categories.get(k, []): all_items.append(item)
	categories["All"] = all_items

	for cat_name in ["All", "Terrain", "Nature", "Buildings", "Interactive", "NPC", "World Connection", "Prefabs"]:
		var scroll = ScrollContainer.new()
		scroll.name = cat_name
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var grid = GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		
		var items = categories.get(cat_name, [])
		for asset in items:
			var aname = asset.get("name", "").to_lower()
			var aid = asset.get("id", "").to_lower()
			var atype = asset.get("type", "object")
			if filter != "" and not (filter in aname or filter in aid):
				continue
				
			var btn = Button.new()
			btn.text = " " + asset.get("name", "Asset")
			btn.set_meta("asset_id", aid)
			btn.custom_minimum_size = Vector2(110, 30)
			btn.add_theme_font_size_override("font_size", 11)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			
			# Resolve and attach real texture icon
			var tex = AssetRegistry.get_asset_texture(aid, atype)
			if not tex:
				tex = AssetRegistry.get_fallback_placeholder_texture(aid)
			if tex:
				btn.icon = tex
				btn.expand_icon = true
				
			btn.modulate = Color.WHITE
			if selected_asset.get("id", "") == aid:
				btn.add_theme_stylebox_override("normal", UIConstants.create_active_button_stylebox())
				btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			else:
				btn.remove_theme_stylebox_override("normal")
				btn.remove_theme_color_override("font_color")
				
			btn.pressed.connect(func():
				_select_asset(asset)
			)
			btn.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
					_show_asset_context_menu(asset, btn.get_global_mouse_position())
			)
			grid.add_child(btn)
			
		scroll.add_child(grid)
		tab_container.add_child(scroll)

func _highlight_selected_button(asset_id: String) -> void:
	if not tab_container: return
	for scroll in tab_container.get_children():
		var grid = scroll.get_child(0) if scroll.get_child_count() > 0 else null
		if grid:
			for btn in grid.get_children():
				if btn is Button:
					var is_match = btn.get_meta("asset_id", "") == asset_id
					btn.modulate = Color.WHITE
					if is_match:
						btn.add_theme_stylebox_override("normal", UIConstants.create_active_button_stylebox())
						btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
					else:
						btn.remove_theme_stylebox_override("normal")
						btn.remove_theme_color_override("font_color")

func _select_asset(asset: Dictionary) -> void:
	selected_asset = asset
	var aid = asset.get("id", "")
	var aname = asset.get("name", "Asset")
	var atype = str(asset.get("type", "object")).capitalize()
	var alayer = str(asset.get("layer", "OBJECT"))

	if preview_name:
		preview_name.text = aname
	if preview_info:
		preview_info.text = "%s • %s" % [atype, alayer]
	if preview_icon:
		var tex = AssetRegistry.get_asset_texture(aid, asset.get("type", "object"))
		if not tex:
			tex = AssetRegistry.get_fallback_placeholder_texture(aid)
		preview_icon.texture = tex

	_highlight_selected_button(aid)
	asset_selected.emit(asset)

