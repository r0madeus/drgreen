class_name ItemEditorPanel
extends EditorPanel

## In-Game Item, Crop, Tool & Economy Editor Panel for Botanical Haven (Phase 32).
## Manages items, crops, growth stages, tools, upgrade chains, economy ROI calculations,
## NPC gift preferences, cross-editor references, live visual previews, and non-destructive mod overrides.

signal item_selected(stable_id: String)
signal switch_to_npc_editor(npc_id: String)
signal switch_to_quest_editor(quest_id: String)
signal switch_to_dialogue_editor(dialogue_id: String)
signal switch_to_world_editor(world_id: String)

enum EditorSubMode { ITEMS, CROPS, TOOLS, ECONOMY }
var current_mode: EditorSubMode = EditorSubMode.ITEMS

var current_item_id: String = "plant_red_flower"
var current_item_data: Dictionary = {}

# UI Controls
var mode_tabs: TabBar
var item_list_container: VBoxContainer
var search_line_edit: LineEdit
var category_filter_opt: OptionButton
var center_preview_container: VBoxContainer
var preview_icon: TextureRect
var preview_title_lbl: Label
var preview_stats_lbl: Label
var roi_calculator_container: VBoxContainer
var roi_result_lbl: Label

# Inspector Fields
var id_edit: LineEdit
var name_edit: LineEdit
var desc_text_edit: TextEdit
var category_opt: OptionButton
var tags_edit: LineEdit
var stack_spin: SpinBox
var buy_price_spin: SpinBox
var sell_price_spin: SpinBox
var rarity_opt: OptionButton

# Flags
var check_giftable: CheckBox
var check_sellable: CheckBox
var check_purchasable: CheckBox
var check_quest_item: CheckBox

# Crop & Tool Specific Fields
var crop_growth_days_edit: LineEdit
var crop_yield_spin: SpinBox
var tool_power_spin: SpinBox
var tool_energy_spin: SpinBox
var tool_range_spin: SpinBox
var tool_upgrade_opt: OptionButton

# NPC Gift Preferences Container
var gift_prefs_container: VBoxContainer
var used_by_container: VBoxContainer

# Status Bar
var status_item_label: Label
var status_changes_label: Label
var validation_status_label: Label

const ITEM_CATEGORIES = ["crop", "seed", "tool", "material", "forage", "quest", "special"]
const RARITIES = ["common", "uncommon", "rare", "legendary"]
const TOOL_TYPES = ["hoe", "watering_can", "axe", "pickaxe"]
const TOOL_QUALITIES = ["basic", "copper", "iron", "gold"]
const GIFT_LEVELS = ["loved", "liked", "neutral", "disliked", "hated"]
const NPCS = ["rowan", "elias", "mira"]

func _init() -> void:
	super._init("item", "ui.editor.cat_item", "icon_item")

func setup(p_service: Variant) -> void:
	super.setup(p_service)
	_build_ui()
	_load_item_catalog()
	_select_item(current_item_id)

func open_panel() -> void:
	super.open_panel()
	refresh()

func refresh() -> void:
	_load_item_catalog()
	_select_item(current_item_id)

func _build_ui() -> void:
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.grow_horizontal = GROW_DIRECTION_BOTH
	main_vbox.grow_vertical = GROW_DIRECTION_BOTH
	add_child(main_vbox)

	# --- TOP TOOLBAR ---
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_bar.add_child(top_hbox)

	var top_title = Label.new()
	top_title.text = "🧰 Item, Crop, Tool & Economy Editor"
	top_title.add_theme_font_size_override("font_size", 13)
	top_title.modulate = Color(0.9, 0.85, 0.4)
	top_hbox.add_child(top_title)

	top_hbox.add_spacer(false)

	var add_item_btn = Button.new()
	add_item_btn.text = " New Entry"
	add_item_btn.pressed.connect(_on_add_new_entry)
	top_hbox.add_child(add_item_btn)

	var dup_item_btn = Button.new()
	dup_item_btn.text = " Duplicate"
	dup_item_btn.pressed.connect(_on_duplicate_entry)
	top_hbox.add_child(dup_item_btn)

	var safe_del_btn = Button.new()
	safe_del_btn.text = " Safe Delete"
	safe_del_btn.pressed.connect(_on_safe_delete_entry)
	top_hbox.add_child(safe_del_btn)

	var sep1 = VSeparator.new()
	top_hbox.add_child(sep1)

	var playtest_btn = Button.new()
	playtest_btn.text = " Playtest"
	playtest_btn.modulate = Color(0.5, 1.0, 0.6)
	playtest_btn.pressed.connect(_on_playtest_entry)
	top_hbox.add_child(playtest_btn)

	# Mode Switcher Tabs
	mode_tabs = TabBar.new()
	mode_tabs.add_tab(" Items")
	mode_tabs.add_tab(" Crops")
	mode_tabs.add_tab(" Tools")
	mode_tabs.add_tab(" Economy")
	mode_tabs.tab_changed.connect(_on_mode_changed)
	main_vbox.add_child(mode_tabs)

	# --- 3-COLUMN WORKSPACE ---
	var mid_hbox = HBoxContainer.new()
	mid_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(mid_hbox)

	# 1. LEFT: Catalog List & Filtering
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(210, 0)
	mid_hbox.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_panel.add_child(left_vbox)

	var cat_lbl = Label.new()
	cat_lbl.text = "Catalog Browser:"
	cat_lbl.add_theme_font_size_override("font_size", 11)
	left_vbox.add_child(cat_lbl)

	search_line_edit = LineEdit.new()
	search_line_edit.placeholder_text = "Search item, crop, tool..."
	search_line_edit.text_changed.connect(func(_t): _refresh_item_list())
	left_vbox.add_child(search_line_edit)

	category_filter_opt = OptionButton.new()
	category_filter_opt.add_item("All Categories", 0)
	for i in range(ITEM_CATEGORIES.size()):
		category_filter_opt.add_item(ITEM_CATEGORIES[i].capitalize(), i + 1)
	category_filter_opt.item_selected.connect(func(_idx): _refresh_item_list())
	left_vbox.add_child(category_filter_opt)

	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(left_scroll)

	item_list_container = VBoxContainer.new()
	item_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(item_list_container)

	# 2. CENTER: Live Visual Preview & Growth / Upgrade Timelines / Economy ROI
	var center_panel = PanelContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_hbox.add_child(center_panel)

	var center_vbox = VBoxContainer.new()
	center_panel.add_child(center_vbox)

	var center_header = HBoxContainer.new()
	center_vbox.add_child(center_header)

	var center_title = Label.new()
	center_title.text = "Visual Preview & Lifecycle Pipeline"
	center_title.add_theme_font_size_override("font_size", 13)
	center_header.add_child(center_title)

	center_header.add_spacer(false)

	var prev_btn = Button.new()
	prev_btn.text = " Refresh Preview"
	prev_btn.pressed.connect(_update_center_preview)
	center_header.add_child(prev_btn)

	var center_scroll = ScrollContainer.new()
	center_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.add_child(center_scroll)

	center_preview_container = VBoxContainer.new()
	center_preview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_scroll.add_child(center_preview_container)

	# Preview Header Box
	var prev_card = PanelContainer.new()
	center_preview_container.add_child(prev_card)

	var prev_hbox = HBoxContainer.new()
	prev_card.add_child(prev_hbox)

	preview_icon = TextureRect.new()
	preview_icon.custom_minimum_size = Vector2(64, 64)
	preview_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	prev_hbox.add_child(preview_icon)

	var prev_meta_vbox = VBoxContainer.new()
	prev_hbox.add_child(prev_meta_vbox)

	preview_title_lbl = Label.new()
	preview_title_lbl.text = "Red Flower Plant"
	preview_title_lbl.add_theme_font_size_override("font_size", 13)
	preview_title_lbl.modulate = Color(0.9, 0.9, 0.5)
	prev_meta_vbox.add_child(preview_title_lbl)

	preview_stats_lbl = Label.new()
	preview_stats_lbl.text = "Buy: 25g | Sell: 50g | Stack: 99"
	preview_stats_lbl.add_theme_font_size_override("font_size", 11)
	prev_meta_vbox.add_child(preview_stats_lbl)

	# Economy ROI & Analytics Box
	roi_calculator_container = VBoxContainer.new()
	center_preview_container.add_child(roi_calculator_container)
	_build_roi_calculator(roi_calculator_container)

	# 3. RIGHT: Inspector Tabs
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(300, 0)
	mid_hbox.add_child(right_panel)

	var right_tabs = TabContainer.new()
	right_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_tabs)

	# Tab 1: Properties
	var prop_scroll = ScrollContainer.new()
	prop_scroll.name = "Properties"
	right_tabs.add_child(prop_scroll)
	var prop_vbox = VBoxContainer.new()
	prop_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prop_scroll.add_child(prop_vbox)
	_build_properties_tab(prop_vbox)

	# Tab 2: Crop / Tool Stats
	var stats_scroll = ScrollContainer.new()
	stats_scroll.name = "Crop/Tool"
	right_tabs.add_child(stats_scroll)
	var stats_vbox = VBoxContainer.new()
	stats_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_scroll.add_child(stats_vbox)
	_build_crop_tool_stats_tab(stats_vbox)

	# Tab 3: NPC Gift Preferences
	var gift_scroll = ScrollContainer.new()
	gift_scroll.name = "NPC Gifts"
	right_tabs.add_child(gift_scroll)
	var gift_vbox = VBoxContainer.new()
	gift_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gift_scroll.add_child(gift_vbox)
	_build_gift_preferences_tab(gift_vbox)

	# Tab 4: Used By / References
	var used_scroll = ScrollContainer.new()
	used_scroll.name = "Used By"
	right_tabs.add_child(used_scroll)
	var used_vbox = VBoxContainer.new()
	used_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	used_scroll.add_child(used_vbox)
	_build_used_by_tab(used_vbox)

	# --- BOTTOM STATUS BAR ---
	var bottom_bar = PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 26)
	main_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_bar.add_child(bottom_hbox)

	status_item_label = Label.new()
	status_item_label.text = "Item: plant_red_flower"
	status_item_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_item_label)

	bottom_hbox.add_spacer(false)

	status_changes_label = Label.new()
	status_changes_label.text = "Changes: 0"
	status_changes_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_changes_label)

	bottom_hbox.add_spacer(false)

	validation_status_label = Label.new()
	validation_status_label.text = "Validation: OK"
	validation_status_label.modulate = Color(0.4, 0.9, 0.4)
	validation_status_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(validation_status_label)

func _build_properties_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("Stable ID:"))
	id_edit = LineEdit.new()
	id_edit.text_submitted.connect(_on_id_submitted)
	container.add_child(id_edit)

	container.add_child(_create_field_label("Display Name:"))
	name_edit = LineEdit.new()
	name_edit.text_changed.connect(func(t): _on_field_changed("name", t))
	container.add_child(name_edit)

	container.add_child(_create_field_label("Description:"))
	desc_text_edit = TextEdit.new()
	desc_text_edit.custom_minimum_size = Vector2(0, 60)
	desc_text_edit.text_changed.connect(func(): _on_field_changed("description", desc_text_edit.text))
	container.add_child(desc_text_edit)

	container.add_child(_create_field_label("Category:"))
	category_opt = OptionButton.new()
	for i in range(ITEM_CATEGORIES.size()):
		category_opt.add_item(ITEM_CATEGORIES[i].capitalize(), i)
	category_opt.item_selected.connect(func(idx): _on_field_changed("category", ITEM_CATEGORIES[idx]))
	container.add_child(category_opt)

	container.add_child(_create_field_label("Buy Price (Gold):"))
	buy_price_spin = SpinBox.new()
	buy_price_spin.min_value = 0
	buy_price_spin.max_value = 10000
	buy_price_spin.value_changed.connect(func(v): _on_field_changed("buy_price", float(v)))
	container.add_child(buy_price_spin)

	container.add_child(_create_field_label("Sell Price (Gold):"))
	sell_price_spin = SpinBox.new()
	sell_price_spin.min_value = 0
	sell_price_spin.max_value = 10000
	sell_price_spin.value_changed.connect(func(v): _on_field_changed("sell_price", float(v)))
	container.add_child(sell_price_spin)

	container.add_child(_create_field_label("Max Stack Size:"))
	stack_spin = SpinBox.new()
	stack_spin.min_value = 1
	stack_spin.max_value = 999
	stack_spin.value = 99
	stack_spin.value_changed.connect(func(v): _on_field_changed("stack_size", int(v)))
	container.add_child(stack_spin)

	container.add_child(_create_field_label("Rarity:"))
	rarity_opt = OptionButton.new()
	for i in range(RARITIES.size()):
		rarity_opt.add_item(RARITIES[i].capitalize(), i)
	rarity_opt.item_selected.connect(func(idx): _on_field_changed("rarity", RARITIES[idx]))
	container.add_child(rarity_opt)

	container.add_child(_create_field_label("Tags (comma separated):"))
	tags_edit = LineEdit.new()
	tags_edit.text_changed.connect(func(t):
		var arr: Array[String] = []
		for s in t.split(","):
			var trimmed = s.strip_edges()
			if trimmed != "": arr.append(trimmed)
		_on_field_changed("tags", arr)
	)
	container.add_child(tags_edit)

	var reset_btn = Button.new()
	reset_btn.text = "↺ Reset Item to Default"
	reset_btn.pressed.connect(reset_current_item)
	container.add_child(reset_btn)

func _build_crop_tool_stats_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("Crop Growth Days Per Stage (e.g. 1, 1, 2):"))
	crop_growth_days_edit = LineEdit.new()
	crop_growth_days_edit.text = "1, 1, 1"
	crop_growth_days_edit.text_changed.connect(func(t):
		var stages_arr: Array[float] = []
		for s in t.split(","):
			stages_arr.append(float(s.strip_edges()))
		_on_field_changed("growth_days", stages_arr)
	)
	container.add_child(crop_growth_days_edit)

	container.add_child(_create_field_label("Harvest Yield (Count):"))
	crop_yield_spin = SpinBox.new()
	crop_yield_spin.min_value = 1
	crop_yield_spin.max_value = 20
	crop_yield_spin.value = 2
	crop_yield_spin.value_changed.connect(func(v): _on_field_changed("yield", float(v)))
	container.add_child(crop_yield_spin)

	container.add_child(_create_field_label("Tool Power:"))
	tool_power_spin = SpinBox.new()
	tool_power_spin.min_value = 1
	tool_power_spin.max_value = 10
	tool_power_spin.value = 1
	tool_power_spin.value_changed.connect(func(v): _on_field_changed("power", int(v)))
	container.add_child(tool_power_spin)

	container.add_child(_create_field_label("Tool Energy Cost:"))
	tool_energy_spin = SpinBox.new()
	tool_energy_spin.min_value = 0.5
	tool_energy_spin.max_value = 20.0
	tool_energy_spin.step = 0.5
	tool_energy_spin.value = 3.0
	tool_energy_spin.value_changed.connect(func(v): _on_field_changed("energy_cost", float(v)))
	container.add_child(tool_energy_spin)

	container.add_child(_create_field_label("Tool Range (Grid Tiles):"))
	tool_range_spin = SpinBox.new()
	tool_range_spin.min_value = 1
	tool_range_spin.max_value = 5
	tool_range_spin.value = 1
	tool_range_spin.value_changed.connect(func(v): _on_field_changed("range", int(v)))
	container.add_child(tool_range_spin)

	container.add_child(_create_field_label("Tool Quality Tier:"))
	tool_upgrade_opt = OptionButton.new()
	for i in range(TOOL_QUALITIES.size()):
		tool_upgrade_opt.add_item(TOOL_QUALITIES[i].capitalize(), i)
	tool_upgrade_opt.item_selected.connect(func(idx): _on_field_changed("quality", TOOL_QUALITIES[idx]))
	container.add_child(tool_upgrade_opt)

func _build_gift_preferences_tab(container: VBoxContainer) -> void:
	var gift_title = Label.new()
	gift_title.text = "NPC Gift Sentiments"
	gift_title.add_theme_font_size_override("font_size", 12)
	container.add_child(gift_title)

	gift_prefs_container = VBoxContainer.new()
	container.add_child(gift_prefs_container)
	_refresh_gift_preferences()

func _build_used_by_tab(container: VBoxContainer) -> void:
	var used_title = Label.new()
	used_title.text = "Referenced In Gameplay"
	used_title.add_theme_font_size_override("font_size", 12)
	container.add_child(used_title)

	used_by_container = VBoxContainer.new()
	container.add_child(used_by_container)
	_refresh_used_by_references()

func _build_roi_calculator(container: VBoxContainer) -> void:
	var roi_box = PanelContainer.new()
	roi_box.modulate = Color(0.85, 1.0, 0.85)
	container.add_child(roi_box)

	var roi_vbox = VBoxContainer.new()
	roi_box.add_child(roi_vbox)

	var title = Label.new()
	title.text = " Economy & Crop ROI Calculator"
	title.add_theme_font_size_override("font_size", 12)
	roi_vbox.add_child(title)

	roi_result_lbl = Label.new()
	roi_result_lbl.text = "Seed Cost: 20g | Harvest Yield: 50g | Net Profit: +30g | ROI: 150%"
	roi_result_lbl.add_theme_font_size_override("font_size", 11)
	roi_vbox.add_child(roi_result_lbl)

func _create_field_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(0.8, 0.8, 0.8)
	return l

func _on_mode_changed(idx: int) -> void:
	current_mode = idx as EditorSubMode
	_load_item_catalog()

func _load_item_catalog() -> void:
	if not item_list_container: return
	for c in item_list_container.get_children(): c.queue_free()

	var prefix = "item."
	if current_mode == EditorSubMode.CROPS: prefix = "crop."
	elif current_mode == EditorSubMode.TOOLS: prefix = "tool."

	var keys: Array[String] = []
	if editor_service and editor_service.data_service:
		keys = editor_service.data_service.get_all_stable_ids(prefix)

	if keys.is_empty():
		keys = [prefix + "red_flower", prefix + "blue_flower", prefix + "sunflower"]

	for k in keys:
		var raw_id = k.replace(prefix, "")
		var btn = Button.new()
		var is_overridden = editor_service.data_service.has_override(k) if editor_service else false
		btn.text = (" " if is_overridden else "") + raw_id
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if raw_id == current_item_id:
			btn.modulate = Color(1.0, 0.9, 0.5)
		btn.pressed.connect(func(): _select_item(raw_id))
		item_list_container.add_child(btn)

func _select_item(raw_id: String) -> void:
	current_item_id = raw_id
	var prefix = "item."
	if current_mode == EditorSubMode.CROPS: prefix = "crop."
	elif current_mode == EditorSubMode.TOOLS: prefix = "tool."

	if editor_service and editor_service.data_service:
		current_item_data = editor_service.data_service.get_resolved_object(prefix + raw_id)

	if current_item_data.is_empty():
		current_item_data = {
			"id": raw_id,
			"name": raw_id.capitalize(),
			"category": "crop" if current_mode == EditorSubMode.CROPS else "tool",
			"buy_price": 25.0,
			"sell_price": 50.0,
			"stack_size": 99,
			"rarity": "common",
			"power": 1,
			"energy_cost": 3.0,
			"range": 1
		}

	_refresh_item_list()
	_populate_inspector()
	_update_center_preview()
	_calculate_roi()
	validate()
	item_selected.emit(raw_id)

func _refresh_item_list() -> void:
	if not item_list_container: return
	var filter_text = search_line_edit.text.to_lower() if search_line_edit else ""

	for btn in item_list_container.get_children():
		if btn is Button:
			var txt = btn.text.to_lower()
			btn.visible = (filter_text == "" or txt.contains(filter_text))

func _populate_inspector() -> void:
	if id_edit: id_edit.text = str(current_item_data.get("id", current_item_id))
	if name_edit: name_edit.text = str(current_item_data.get("name", current_item_id.capitalize()))
	if desc_text_edit: desc_text_edit.text = str(current_item_data.get("description", ""))

	var buy_p = float(current_item_data.get("buy_price", current_item_data.get("price", 25.0)))
	var sell_p = float(current_item_data.get("sell_price", current_item_data.get("value", {}).get("base_price", 50.0)))
	if buy_price_spin: buy_price_spin.value = buy_p
	if sell_price_spin: sell_price_spin.value = sell_p

	if tool_power_spin: tool_power_spin.value = float(current_item_data.get("power", 1))
	if tool_energy_spin: tool_energy_spin.value = float(current_item_data.get("energy_cost", 3.0))
	if tool_range_spin: tool_range_spin.value = float(current_item_data.get("range", 1))

	_refresh_gift_preferences()
	_refresh_used_by_references()

func _refresh_gift_preferences() -> void:
	if not gift_prefs_container: return
	for c in gift_prefs_container.get_children(): c.queue_free()

	for npc in NPCS:
		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = npc.capitalize() + ":"
		lbl.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(lbl)

		var opt = OptionButton.new()
		for i in range(GIFT_LEVELS.size()):
			opt.add_item(GIFT_LEVELS[i].capitalize(), i)
			if GIFT_LEVELS[i] == "liked" and npc == "rowan": opt.selected = i
		hbox.add_child(opt)
		gift_prefs_container.add_child(hbox)

func _refresh_used_by_references() -> void:
	if not used_by_container: return
	for c in used_by_container.get_children(): c.queue_free()

	# Quests reference
	var q_btn = Button.new()
	q_btn.text = " Quest: First Seeds (Objective Target)"
	q_btn.pressed.connect(func(): switch_to_quest_editor.emit("quest_01"))
	used_by_container.add_child(q_btn)

	# NPC reference
	var n_btn = Button.new()
	n_btn.text = " Rowan (Loved Gift)"
	n_btn.pressed.connect(func(): switch_to_npc_editor.emit("rowan"))
	used_by_container.add_child(n_btn)

	# Dialogue reference
	var d_btn = Button.new()
	d_btn.text = " Rowan Dialogue (Reward Item)"
	d_btn.pressed.connect(func(): switch_to_dialogue_editor.emit("rowan"))
	used_by_container.add_child(d_btn)

func _update_center_preview() -> void:
	if preview_icon:
		var tex = AssetRegistry.get_item_icon(current_item_id)
		preview_icon.texture = tex
	if preview_title_lbl:
		preview_title_lbl.text = current_item_data.get("name", current_item_id.capitalize())
	if preview_stats_lbl:
		var buy_p = float(current_item_data.get("buy_price", 25.0))
		var sell_p = float(current_item_data.get("sell_price", 50.0))
		preview_stats_lbl.text = "Buy: %dg | Sell: %dg | Rarity: %s" % [int(buy_p), int(sell_p), current_item_data.get("rarity", "common")]

func _calculate_roi() -> void:
	var seed_cost = float(current_item_data.get("buy_price", 20.0))
	var harvest_val = float(current_item_data.get("sell_price", 60.0))
	var energy_cost = 7.5
	var net_profit = harvest_val - seed_cost
	var roi_pct = (net_profit / seed_cost * 100.0) if seed_cost > 0 else 0.0
	var profit_per_energy = net_profit / energy_cost if energy_cost > 0 else 0.0

	if roi_result_lbl:
		roi_result_lbl.text = "Seed Cost: %dg | Harvest: %dg | Net: +%dg | ROI: %d%% | Profit/Energy: %.1f" % [
			int(seed_cost), int(harvest_val), int(net_profit), int(roi_pct), profit_per_energy
		]

func _on_field_changed(field: String, val: Variant) -> void:
	current_item_data[field] = val
	var prefix = "item."
	if current_mode == EditorSubMode.CROPS: prefix = "crop."
	elif current_mode == EditorSubMode.TOOLS: prefix = "tool."

	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override(prefix + current_item_id, field, val, false)

	_update_center_preview()
	_calculate_roi()
	validate()
	panel_dirtied.emit()

func _on_id_submitted(new_id: String) -> void:
	if new_id == "" or new_id == current_item_id: return
	var prefix = "item."
	if current_mode == EditorSubMode.CROPS: prefix = "crop."
	elif current_mode == EditorSubMode.TOOLS: prefix = "tool."

	if editor_service and editor_service.data_service:
		for k in current_item_data.keys():
			editor_service.data_service.set_staged_override(prefix + new_id, k, current_item_data[k])

	current_item_id = new_id
	_load_item_catalog()
	_select_item(new_id)

func _on_add_new_entry() -> void:
	var prefix = "item."
	if current_mode == EditorSubMode.CROPS: prefix = "crop."
	elif current_mode == EditorSubMode.TOOLS: prefix = "tool."

	var new_id = "custom_%s_%d" % [prefix.replace(".", ""), (int(Time.get_unix_time_from_system()) % 1000)]
	var new_data = {
		"id": new_id,
		"name": new_id.capitalize(),
		"buy_price": 30.0,
		"sell_price": 75.0,
		"rarity": "uncommon",
		"category": "crop" if current_mode == EditorSubMode.CROPS else "tool"
	}
	if editor_service and editor_service.data_service:
		for k in new_data.keys():
			editor_service.data_service.set_staged_override(prefix + new_id, k, new_data[k])

	_load_item_catalog()
	_select_item(new_id)

func _on_duplicate_entry() -> void:
	var prefix = "item."
	if current_mode == EditorSubMode.CROPS: prefix = "crop."
	elif current_mode == EditorSubMode.TOOLS: prefix = "tool."

	var dup_id = "%s_copy_%d" % [current_item_id, (int(Time.get_unix_time_from_system()) % 1000)]
	var dup_data = current_item_data.duplicate(true)
	dup_data["id"] = dup_id
	dup_data["name"] = dup_data.get("name", current_item_id) + " (Copy)"

	if editor_service and editor_service.data_service:
		for k in dup_data.keys():
			editor_service.data_service.set_staged_override(prefix + dup_id, k, dup_data[k])

	_load_item_catalog()
	_select_item(dup_id)

func _on_safe_delete_entry() -> void:
	var prefix = "item."
	if current_mode == EditorSubMode.CROPS: prefix = "crop."
	elif current_mode == EditorSubMode.TOOLS: prefix = "tool."

	if editor_service and editor_service.data_service:
		editor_service.data_service.restore_default(prefix + current_item_id, "", true)
	_load_item_catalog()

func _on_playtest_entry() -> void:
	var psm = Engine.get_main_loop().root.get_node_or_null("/root/PlayerStateManager") if Engine.get_main_loop() else null
	if psm:
		var p_state = psm.get_active_player_state()
		if p_state: p_state.add_item(current_item_id, 5)

func reset_current_item() -> void:
	var prefix = "item."
	if current_mode == EditorSubMode.CROPS: prefix = "crop."
	elif current_mode == EditorSubMode.TOOLS: prefix = "tool."

	if editor_service and editor_service.data_service:
		editor_service.data_service.restore_default(prefix + current_item_id, "", true)
	_select_item(current_item_id)

func reset_all_gameplay_data() -> void:
	if editor_service and editor_service.data_service:
		editor_service.data_service.clear_staged_overrides()
	_load_item_catalog()
	_select_item(current_item_id)

func validate() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var buy_p = float(current_item_data.get("buy_price", 0))
	var sell_p = float(current_item_data.get("sell_price", 0))
	if buy_p < 0 or sell_p < 0:
		errors.append("Price values cannot be negative.")

	if float(current_item_data.get("stack_size", 1)) <= 0:
		errors.append("Stack size must be at least 1.")

	if validation_status_label:
		if errors.size() > 0:
			validation_status_label.text = "Validation: %d Errors" % errors.size()
			validation_status_label.modulate = Color(1.0, 0.4, 0.4)
		elif warnings.size() > 0:
			validation_status_label.text = "Validation: %d Warnings" % warnings.size()
			validation_status_label.modulate = Color(1.0, 0.8, 0.3)
		else:
			validation_status_label.text = "Validation: OK"
			validation_status_label.modulate = Color(0.4, 0.9, 0.4)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"total_checked": 1
	}

func focus_entry(entry_id: String, mode_hint: String = "") -> void:
	var clean_id = entry_id.trim_prefix("item.").trim_prefix("crop.").trim_prefix("tool.").trim_prefix("seed_").trim_prefix("plant_")
	if mode_hint == "crops" or mode_hint == "crop" or entry_id.begins_with("crop.") or entry_id.begins_with("plant."):
		current_mode = EditorSubMode.CROPS
		if mode_tabs: mode_tabs.current_tab = EditorSubMode.CROPS
	elif mode_hint == "tools" or mode_hint == "tool" or entry_id.begins_with("tool."):
		current_mode = EditorSubMode.TOOLS
		if mode_tabs: mode_tabs.current_tab = EditorSubMode.TOOLS
	else:
		current_mode = EditorSubMode.ITEMS
		if mode_tabs: mode_tabs.current_tab = EditorSubMode.ITEMS
		
	_load_item_catalog()
	_select_item(clean_id)


## Public programmatic and UI authoring entry points for Item / Crop / Tool creation (Phase 36)
func create_item(item_id: String, item_name: String, category: String = "general", sell_price: int = 50, icon_asset: String = "") -> Dictionary:
	var clean_id = item_id.strip_edges().to_lower().replace(" ", "_").trim_prefix("item.")
	if clean_id == "": clean_id = "item_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	
	var d = {
		"id": clean_id,
		"name": item_name if item_name != "" else clean_id.capitalize().replace("_", " "),
		"category": category,
		"buy_price": float(sell_price * 2),
		"sell_price": float(sell_price),
		"rarity": "common",
		"stack_size": 99
	}
	if icon_asset != "": d["icon"] = icon_asset
	
	if editor_service and editor_service.data_service:
		editor_service.data_service.create_entity("item." + clean_id, d)
		
	current_mode = EditorSubMode.ITEMS
	if mode_tabs: mode_tabs.current_tab = EditorSubMode.ITEMS
	_load_item_catalog()
	_select_item(clean_id)
	panel_dirtied.emit()
	return d

func create_crop(crop_id: String, crop_name: String, growth_duration: int = 4, harvest_item: String = "", icon_asset: String = "") -> Dictionary:
	var clean_id = crop_id.strip_edges().to_lower().replace(" ", "_").trim_prefix("crop.").trim_prefix("plant.")
	if clean_id == "": clean_id = "crop_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	
	var d = {
		"id": clean_id,
		"name": crop_name if crop_name != "" else clean_id.capitalize().replace("_", " "),
		"growth_days": growth_duration,
		"stages": 4,
		"harvest_item": harvest_item if harvest_item != "" else ("item." + clean_id),
		"sell_price": 60.0,
		"category": "crop"
	}
	if icon_asset != "": d["icon"] = icon_asset
	
	if editor_service and editor_service.data_service:
		editor_service.data_service.create_entity("crop." + clean_id, d)
		# Automatically create corresponding seed item
		editor_service.data_service.create_entity("item.seed_" + clean_id, {
			"id": "seed_" + clean_id,
			"name": d["name"] + " Seed",
			"type": "seed",
			"crop_id": "crop." + clean_id,
			"buy_price": 20.0,
			"sell_price": 10.0
		})
		
	current_mode = EditorSubMode.CROPS
	if mode_tabs: mode_tabs.current_tab = EditorSubMode.CROPS
	_load_item_catalog()
	_select_item(clean_id)
	panel_dirtied.emit()
	return d

func create_tool(tool_id: String, tool_name: String, power: int = 1, energy_cost: int = 2, icon_asset: String = "") -> Dictionary:
	var clean_id = tool_id.strip_edges().to_lower().replace(" ", "_").trim_prefix("tool.")
	if clean_id == "": clean_id = "tool_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	
	var d = {
		"id": clean_id,
		"name": tool_name if tool_name != "" else clean_id.capitalize().replace("_", " "),
		"power": power,
		"energy_cost": energy_cost,
		"tier": 1,
		"category": "tool"
	}
	if icon_asset != "": d["icon"] = icon_asset
	
	if editor_service and editor_service.data_service:
		editor_service.data_service.create_entity("tool." + clean_id, d)
		
	current_mode = EditorSubMode.TOOLS
	if mode_tabs: mode_tabs.current_tab = EditorSubMode.TOOLS
	_load_item_catalog()
	_select_item(clean_id)
	panel_dirtied.emit()
	return d
