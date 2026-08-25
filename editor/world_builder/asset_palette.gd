class_name AssetPalette
extends PanelContainer

## Left-side Asset Palette with Search, Filter Categories, Nature, Buildings, Interactive & NPC entities.

signal asset_selected(asset_info: Dictionary)

var search_edit: LineEdit
var tab_container: TabContainer

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
	root_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(root_vbox)

	var lbl = Label.new()
	lbl.text = "🎨 Palette & Assets"
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = Color(1.0, 0.85, 0.3)
	root_vbox.add_child(lbl)

	# --- ACTIVE SELECTION CARD ---
	preview_card = PanelContainer.new()
	preview_card.custom_minimum_size = Vector2(0, 44)
	root_vbox.add_child(preview_card)

	var p_margin = MarginContainer.new()
	p_margin.add_theme_constant_override("margin_left", 4)
	p_margin.add_theme_constant_override("margin_top", 4)
	p_margin.add_theme_constant_override("margin_right", 4)
	p_margin.add_theme_constant_override("margin_bottom", 4)
	preview_card.add_child(p_margin)

	var p_hbox = HBoxContainer.new()
	p_hbox.add_theme_constant_override("separation", 8)
	p_margin.add_child(p_hbox)

	preview_icon = TextureRect.new()
	preview_icon.custom_minimum_size = Vector2(32, 32)
	preview_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	p_hbox.add_child(preview_icon)

	var p_vbox = VBoxContainer.new()
	p_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_vbox.add_theme_constant_override("separation", 0)
	p_hbox.add_child(p_vbox)

	preview_name = Label.new()
	preview_name.text = "No Asset Selected"
	preview_name.add_theme_font_size_override("font_size", 12)
	p_vbox.add_child(preview_name)

	preview_info = Label.new()
	preview_info.text = "Select from categories below"
	preview_info.add_theme_font_size_override("font_size", 10)
	preview_info.modulate = Color(0.7, 0.7, 0.7)
	p_vbox.add_child(preview_info)

	search_edit = LineEdit.new()
	search_edit.placeholder_text = "🔍 Search assets..."
	search_edit.add_theme_font_size_override("font_size", 11)
	root_vbox.add_child(search_edit)

	tab_container = TabContainer.new()
	tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_container.add_theme_font_size_override("font_size", 11)
	root_vbox.add_child(tab_container)


func refresh_prefabs_list() -> void:
	refresh_assets_list()

func refresh_assets_list() -> void:
	AssetRegistry.ensure_initialized()
	categories["Terrain"] = AssetRegistry.get_terrain_assets()
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
		var mapped = []
		for asset_id in defs.keys():
			var def_data = defs[asset_id]
			var t = def_data.get("identity", {}).get("type", "object")
			var item = {
				"id": asset_id,
				"name": def_data.get("identity", {}).get("display_name", asset_id),
				"type": t,
				"layer": def_data.get("components", {}).get("visual", {}).get("layer", "OBJECT")
			}
			# Basic properties for palette
			var props = AssetDefinitionManager.resolve_instance_properties(asset_id, {})
			for k in props.keys():
				item[k] = props[k]
			mapped.append(item)

		if mapped.size() > 0:
			categories["Nature"] = []
			categories["Buildings"] = []
			categories["Interactive"] = []
			categories["NPC"] = []
			for m in mapped:
				if m["type"] in ["tile", "terrain"]:
					var existing = false
					for existing_item in categories["Terrain"]:
						if existing_item.get("id") == m["id"]:
							existing = true
							break
					if not existing:
						categories["Terrain"].append(m)
				elif m["type"] == "plant" or "tree" in m["id"] or "rock" in m["id"]: categories["Nature"].append(m)
				elif "house" in m["id"] or "shed" in m["id"] or "barn" in m["id"]: categories["Buildings"].append(m)
				elif m.get("interactable", false) and m["type"] != "plant" and m["type"] != "NPC": categories["Interactive"].append(m)
				elif m["type"] == "NPC" or "npc" in m.get("tags", []): categories["NPC"].append(m)
				else: categories["Nature"].append(m) # fallback
	
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
				
			if selected_asset.get("id", "") == aid:
				btn.modulate = Color(1.3, 1.3, 0.7)
			else:
				btn.modulate = Color.WHITE
				
			btn.pressed.connect(func():
				_select_asset(asset)
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
					btn.modulate = Color(1.3, 1.3, 0.7) if is_match else Color.WHITE

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

