class_name JournalUI
extends Control

## UI modal presenting the Botanical Codex and Synthesis Formulas discovery progress.

enum Tab { PLANTS, COMBINATIONS, WORLDS }
var current_tab: Tab = Tab.PLANTS
var selected_plant_id: String = "red_flower"

@onready var plants_tab_btn: Button = find_child("PlantsTabButton", true, false)
@onready var combos_tab_btn: Button = find_child("CombosTabButton", true, false)
@onready var close_btn: Button = find_child("CloseButton", true, false)
@onready var progress_label: Label = find_child("ProgressLabel", true, false)
var worlds_tab_btn: Button = null

@onready var plants_view: HBoxContainer = find_child("PlantsView", true, false)
@onready var plants_list_container: VBoxContainer = find_child("PlantsList", true, false)
@onready var detail_icon: TextureRect = find_child("DetailIcon", true, false)
@onready var detail_name: Label = find_child("DetailName", true, false)
@onready var detail_rarity: Label = find_child("DetailRarity", true, false)
@onready var detail_type: Label = find_child("DetailType", true, false)
@onready var detail_price: Label = find_child("DetailPrice", true, false)
@onready var detail_growth: Label = find_child("DetailGrowth", true, false)
@onready var detail_yield: Label = find_child("DetailYield", true, false)

@onready var combos_view: VBoxContainer = find_child("CombosView", true, false)
@onready var combos_list_container: VBoxContainer = find_child("CombosList", true, false)
var worlds_view: VBoxContainer = null

func _ready() -> void:
	visible = false
	theme = UIConstants.get_theme()
	if not InputMap.has_action("journal"):
		InputMap.add_action("journal")
		var ev = InputEventKey.new()
		ev.keycode = KEY_J
		InputMap.action_add_event("journal", ev)
		
	var tab_hbox = find_child("TabHBox", true, false)
	if tab_hbox:
		worlds_tab_btn = Button.new()
		worlds_tab_btn.text = "🗺️ World Progress"
		worlds_tab_btn.pressed.connect(func(): _switch_tab(Tab.WORLDS))
		tab_hbox.add_child(worlds_tab_btn)
		
	var main_vbox = find_child("VBoxContainer", true, false)
	if main_vbox:
		worlds_view = VBoxContainer.new()
		worlds_view.name = "WorldsView"
		worlds_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
		worlds_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		worlds_view.visible = false
		main_vbox.add_child(worlds_view)
		
	if plants_tab_btn:
		plants_tab_btn.pressed.connect(func(): _switch_tab(Tab.PLANTS))
	if combos_tab_btn:
		combos_tab_btn.pressed.connect(func(): _switch_tab(Tab.COMBINATIONS))
	if close_btn:
		close_btn.pressed.connect(close_ui)
		
	var jm = get_node_or_null("/root/JournalManager")
	if jm:
		jm.journal_updated.connect(refresh_ui)
		
	refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_J or event.physical_keycode == KEY_J)):
		toggle_visibility()
		get_viewport().set_input_as_handled()
	elif visible and (event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)):
		close_ui()
		get_viewport().set_input_as_handled()

func open_ui() -> void:
	UIConstants.close_all_modals(get_tree(), self)
	visible = true
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_open")
	UIConstants.update_player_lock(get_tree())
	refresh_ui()

func close_ui() -> void:
	visible = false
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_close")
	UIConstants.update_player_lock(get_tree())

func toggle_visibility() -> void:
	if visible:
		close_ui()
	else:
		open_ui()

func _switch_tab(tab: Tab) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	current_tab = tab
	if plants_tab_btn: plants_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.PLANTS else Color.WHITE
	if combos_tab_btn: combos_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.COMBINATIONS else Color.WHITE
	if worlds_tab_btn: worlds_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.WORLDS else Color.WHITE
	
	if plants_view: plants_view.visible = (tab == Tab.PLANTS)
	if combos_view: combos_view.visible = (tab == Tab.COMBINATIONS)
	if worlds_view: worlds_view.visible = (tab == Tab.WORLDS)
	refresh_ui()

func refresh_ui() -> void:
	var jm = get_node_or_null("/root/JournalManager")
	if not jm:
		return
		
	var p_disc = jm.get_discovered_plants_count()
	var p_tot = jm.get_total_plants_count()
	var c_disc = jm.get_discovered_combos_count()
	var c_tot = jm.get_total_combos_count()
	
	if progress_label:
		progress_label.text = "🌿 Plants: %d/%d  |  ⚗️ Formulas: %d/%d" % [p_disc, p_tot, c_disc, c_tot]
		
	if current_tab == Tab.PLANTS:
		_populate_plants_tab(jm)
	elif current_tab == Tab.COMBINATIONS:
		_populate_combos_tab(jm)
	elif current_tab == Tab.WORLDS:
		_populate_worlds_tab()

func _populate_worlds_tab() -> void:
	if not worlds_view: return
	for c in worlds_view.get_children(): c.queue_free()
	
	var pm = get_node_or_null("/root/ProgressionManager")
	var unlocked_worlds = pm.unlocked_worlds if pm else { "farm": true, "town": true }
	var visited_worlds = pm.visited_worlds if pm else { "farm": true }
	
	var title = Label.new()
	title.text = "🗺️ Botanical World Unlocks & Research Progression"
	title.modulate = Color(1.0, 0.85, 0.3)
	worlds_view.add_child(title)
	
	var world_list = [
		["farm", "Peaceful Farm", "Starting heritage farm with tilled fields and laboratory.", true],
		["town", "Botanist Village (Town)", "Central commerce hub with seed merchants and local botanists.", true],
		["forest", "Whispering Forest", "Wild woodland with untamed botanical flora and hidden paths.", false],
		["botanical_grove", "Botanical Grove", "Ancient research sanctuary with primal rare species.", false]
	]
	
	for w in world_list:
		var wid = w[0]; var wname = w[1]; var wdesc = w[2]
		var is_unl = bool(unlocked_worlds.get(wid, w[3]))
		var is_vis = bool(visited_worlds.get(wid, false))
		
		var panel = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 8)
		
		var hbox = HBoxContainer.new()
		var status_lbl = Label.new()
		if is_vis:
			status_lbl.text = "✓ Visited"
			status_lbl.modulate = Color(0.4, 1.0, 0.4)
		elif is_unl:
			status_lbl.text = "🔓 Unlocked"
			status_lbl.modulate = Color(1.0, 0.85, 0.2)
		else:
			status_lbl.text = "🔒 Locked"
			status_lbl.modulate = Color(0.65, 0.65, 0.65)
		status_lbl.custom_minimum_size = Vector2(100, 20)
		hbox.add_child(status_lbl)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl = Label.new()
		name_lbl.text = wname
		info_vbox.add_child(name_lbl)
		var desc_lbl = Label.new()
		desc_lbl.text = wdesc
		desc_lbl.modulate = Color(0.8, 0.8, 0.8)
		info_vbox.add_child(desc_lbl)
		hbox.add_child(info_vbox)
		
		margin.add_child(hbox)
		panel.add_child(margin)
		worlds_view.add_child(panel)


func _populate_plants_tab(jm: Node) -> void:

	if not plants_list_container:
		return
		
	for child in plants_list_container.get_children():
		child.queue_free()
		
	var plant_entries = jm.get_all_plants_status()
	for entry in plant_entries:
		var pid = entry["id"]
		var is_disc = entry["discovered"]
		var pname = entry["name"]
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 34)
		
		if is_disc:
			var icon_tex = AssetRegistry.get_item_icon(pid)
			if icon_tex:
				btn.icon = icon_tex
				btn.expand_icon = true
			btn.text = "🌸 " + pname
			btn.modulate = Color(1.2, 1.2, 0.9) if pid == selected_plant_id else Color.WHITE
		else:
			btn.text = "❓ ??? (Undiscovered)"
			btn.modulate = Color(0.65, 0.65, 0.65)
			
		btn.pressed.connect(func(): _select_plant(pid))
		plants_list_container.add_child(btn)
		
	_update_plant_detail_panel(jm)

func _select_plant(plant_id: String) -> void:
	selected_plant_id = plant_id
	refresh_ui()

func _update_plant_detail_panel(jm: Node) -> void:
	var pm = get_node_or_null("/root/PlantManager")
	if not pm or not detail_name:
		return
		
	var is_disc = jm.is_plant_discovered(selected_plant_id)
	if is_disc:
		var pdata = pm.get_plant(selected_plant_id)
		var icon_tex = AssetRegistry.get_item_icon(selected_plant_id)
		if detail_icon:
			detail_icon.texture = icon_tex
			detail_icon.modulate = Color.WHITE
			
		detail_name.text = pdata.get("name", selected_plant_id)
		detail_name.modulate = Color(1.0, 0.9, 0.3)
		detail_type.text = "Category: " + pdata.get("type", "Plant").capitalize()
		detail_rarity.text = "Rarity: " + pdata.get("rarity", "Common").capitalize()
		detail_price.text = "Base Value: %d Gold" % pdata.get("value", {}).get("base_price", 50)
		
		var growth_info = pdata.get("growth", {})
		var stages = growth_info.get("stages", 4)
		var days_arr = growth_info.get("days_per_stage", [1, 1, 1])
		detail_growth.text = "Growth: %d Stages (%s d/stg)" % [stages, str(days_arr)]
		
		var h_info = pdata.get("harvest", {})
		var y_arr = h_info.get("yield", [1, 2])
		detail_yield.text = "Harvest Yield: %d - %d units" % [y_arr[0], y_arr[1]]
	else:
		if detail_icon:
			detail_icon.texture = null
		detail_name.text = "❓ Unknown Species"
		detail_name.modulate = Color(0.7, 0.7, 0.7)
		detail_type.text = "Category: ???"
		detail_rarity.text = "Rarity: ???"
		detail_price.text = "Base Value: ???"
		detail_growth.text = "Growth: ???"
		detail_yield.text = "Harvest Yield: ???"

func _populate_combos_tab(jm: Node) -> void:
	if not combos_list_container:
		return
		
	for child in combos_list_container.get_children():
		child.queue_free()
		
	var combo_entries = jm.get_all_combos_status()
	for c in combo_entries:
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(480, 42)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var is_disc = c["discovered"]
		if is_disc:
			var btn_a = Button.new()
			btn_a.text = c["input_a"].replace("_", " ").capitalize()
			btn_a.icon = AssetRegistry.get_item_icon(c["input_a"])
			btn_a.expand_icon = true
			btn_a.disabled = true
			
			var plus_lbl = Label.new()
			plus_lbl.text = "➕"
			
			var btn_b = Button.new()
			btn_b.text = c["input_b"].replace("_", " ").capitalize()
			btn_b.icon = AssetRegistry.get_item_icon(c["input_b"])
			btn_b.expand_icon = true
			btn_b.disabled = true
			
			var arrow_lbl = Label.new()
			arrow_lbl.text = "➔"
			
			var btn_out = Button.new()
			btn_out.text = "🌸 " + c["output_name"]
			btn_out.icon = AssetRegistry.get_item_icon(c["output"])
			btn_out.expand_icon = true
			btn_out.modulate = Color(1.0, 0.9, 0.4)
			btn_out.disabled = true
			
			hbox.add_child(btn_a)
			hbox.add_child(plus_lbl)
			hbox.add_child(btn_b)
			hbox.add_child(arrow_lbl)
			hbox.add_child(btn_out)
		else:
			var secret_lbl = Label.new()
			secret_lbl.text = "❓ ???  ➕  ❓ ???   ➔   ❓ Unknown Formula"
			secret_lbl.modulate = Color(0.6, 0.6, 0.6)
			hbox.add_child(secret_lbl)
			
		card.add_child(hbox)
		combos_list_container.add_child(card)
