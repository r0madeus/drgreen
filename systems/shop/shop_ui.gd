class_name ShopUI
extends Control

## Cozy Botanical Fantasy Shop UI with Seeds, Supplies, Upgrades and Sell tabs.

enum Tab { SEEDS, SUPPLIES, UPGRADES, SELL }
var current_tab: Tab = Tab.SEEDS

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var gold_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/GoldLabel
@onready var close_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton

@onready var seeds_tab_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/SeedsTabButton
@onready var supplies_tab_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/SuppliesTabButton
@onready var upgrades_tab_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/UpgradesTabButton
@onready var sell_tab_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/SellTabButton

@onready var scroll_container: ScrollContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContentContainer/MainScroll
@onready var item_list_vbox: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContentContainer/MainScroll/ItemList
@onready var empty_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContentContainer/EmptyLabel

var shop_catalog: Dictionary = {}
var upgrades_catalog: Dictionary = {}

func _ready() -> void:
	visible = false
	load_all_data()
	
	if close_btn: close_btn.pressed.connect(close_shop)
	if seeds_tab_btn: seeds_tab_btn.pressed.connect(func(): _switch_tab(Tab.SEEDS))
	if supplies_tab_btn: supplies_tab_btn.pressed.connect(func(): _switch_tab(Tab.SUPPLIES))
	if upgrades_tab_btn: upgrades_tab_btn.pressed.connect(func(): _switch_tab(Tab.UPGRADES))
	if sell_tab_btn: sell_tab_btn.pressed.connect(func(): _switch_tab(Tab.SELL))
	
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(func(_l): 
			_update_tab_texts()
			if visible: refresh_ui()
		)
	_update_tab_texts()
	
	var em = get_node_or_null("/root/EconomyManager")
	if em:
				em.upgrade_purchased.connect(func(_u): refresh_ui())
		
	var im = get_node_or_null("/root/InventoryManager")
	if im:
		EventBus.world_changed.connect(_bind_local_player)

func _update_tab_texts() -> void:
	if title_label: title_label.text = tr("ui.shop.title")
	if seeds_tab_btn: seeds_tab_btn.text = tr("ui.shop.buy_tab")
	if sell_tab_btn: sell_tab_btn.text = tr("ui.shop.sell_tab")


func load_all_data() -> void:
	# Load base shop items
	var path_items = "res://data/economy/base_shop_items.json"
	if FileAccess.file_exists(path_items):
		var f = FileAccess.open(path_items, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				shop_catalog = json.data
				
	# Load upgrades
	var path_upgrades = "res://data/economy/base_upgrades.json"
	if FileAccess.file_exists(path_upgrades):
		var f = FileAccess.open(path_upgrades, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				upgrades_catalog = json.data

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_shop()
			get_viewport().set_input_as_handled()

func open_shop() -> void:
	visible = true
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("shop_open")
	
	# Exclusivity: close other open modals
	var inv = get_tree().root.find_child("InventoryUI", true, false)
	if inv and inv.visible: inv.visible = false
	var lab = get_tree().root.find_child("CombinationUI", true, false)
	if lab and lab.visible: lab.visible = false
	var jrn = get_tree().root.find_child("JournalUI", true, false)
	if jrn and jrn.visible: jrn.visible = false
	var qst = get_tree().root.find_child("QuestUI", true, false)
	if qst and qst.visible: qst.visible = false
	var dial = get_tree().root.find_child("DialogueUI", true, false)
	if dial and dial.visible: dial.close_dialogue()
	
	# Lock player movement
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(true)
		
	_switch_tab(Tab.SEEDS)

func close_shop() -> void:
	if not visible:
		return
	visible = false
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("shop_close")
	
	# Unlock player movement
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)

func _switch_tab(tab: Tab) -> void:
	current_tab = tab
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	if seeds_tab_btn: seeds_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.SEEDS else Color.WHITE
	if supplies_tab_btn: supplies_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.SUPPLIES else Color.WHITE
	if upgrades_tab_btn: upgrades_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.UPGRADES else Color.WHITE
	if sell_tab_btn: sell_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.SELL else Color.WHITE
	
	refresh_ui()

func refresh_ui() -> void:
	if not visible:
		return
	_update_gold_display()
	
	match current_tab:
		Tab.SEEDS:
			_populate_seeds()
		Tab.SUPPLIES:
			_populate_supplies()
		Tab.UPGRADES:
			_populate_upgrades()
		Tab.SELL:
			_populate_sell()

func _update_gold_display() -> void:
	var _p = get_tree().get_first_node_in_group("local_player")
	var player_id = _p.player_id if _p and "player_id" in _p else "player_001"
	var em = get_node_or_null("/root/EconomyManager")
	var g = em.get_gold(player_id) if em else 0
	if gold_label:
		gold_label.text = "💰 Your Gold: %d G" % g

func _populate_seeds() -> void:
	var _p = get_tree().get_first_node_in_group("local_player")
	var player_id = _p.player_id if _p and "player_id" in _p else ""
	_clear_list()
	var seeds = shop_catalog.get("seeds", [])
	var em = get_node_or_null("/root/EconomyManager")
	var im = get_node_or_null("/root/InventoryManager")
	var cm = get_node_or_null("/root/CombinationManager")
	var jm = get_node_or_null("/root/JournalManager")
	var current_gold = em.get_gold(player_id) if em else 0
	
	for s_info in seeds:
		var item_id = s_info.get("id", "")
		var plant_id = s_info.get("plant_id", "")
		var item_name = s_info.get("name", "Seed")
		var price = int(s_info.get("price", 25))
		var unlock_type = s_info.get("unlock_type", "always")
		
		var is_unlocked = true
		if unlock_type == "discovery":
			var is_discovered = false
			if cm and cm.has_method("get_discovered_combinations"):
				for cid in cm.get_discovered_combinations():
					var cdata = cm.get_combination_by_id(cid) if cm.has_method("get_combination_by_id") else {}
					if cdata.get("output", "") == plant_id:
						is_discovered = true
						break
			if jm and not is_discovered:
				is_discovered = (plant_id in ["red_flower", "blue_flower", "yellow_herb", "green_vine", "white_lily"])
			is_unlocked = is_discovered
			
		var owned_count = im.get_item_count(player_id, item_id) if im else 0
		
		# Row container
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(480, 44)
		var row_margin = MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 8)
		row_margin.add_theme_constant_override("margin_right", 8)
		row_margin.add_theme_constant_override("margin_top", 4)
		row_margin.add_theme_constant_override("margin_bottom", 4)
		row.add_child(row_margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		row_margin.add_child(hbox)
		
		# Icon
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(24, 24)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = AssetRegistry.get_item_icon(item_id)
		if not is_unlocked:
			icon_rect.modulate = Color(0.3, 0.3, 0.3, 0.6)
		hbox.add_child(icon_rect)
		
		# Label & Status
		var name_lbl = Label.new()
		if is_unlocked:
			name_lbl.text = "%s (Owned: %d)" % [item_name, owned_count]
		else:
			name_lbl.text = "🔒 %s [Discover in Lab]" % item_name
			name_lbl.modulate = Color(0.6, 0.6, 0.6)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)
		
		# Price
		if is_unlocked:
			var price_lbl = Label.new()
			price_lbl.text = "💰 %d G" % price
			price_lbl.modulate = Color(1.0, 0.85, 0.3)
			hbox.add_child(price_lbl)
			
			var buy_btn = Button.new()
			buy_btn.text = "Buy"
			buy_btn.custom_minimum_size = Vector2(64, 28)
			var can_buy = (current_gold >= price)
			buy_btn.disabled = not can_buy
			if not can_buy: buy_btn.modulate = Color(0.7, 0.7, 0.7, 0.6)
			buy_btn.pressed.connect(func(): _on_buy_item(item_id, item_name, price))
			hbox.add_child(buy_btn)
		else:
			var lock_lbl = Label.new()
			lock_lbl.text = "🔒 Locked"
			lock_lbl.modulate = Color(0.7, 0.4, 0.4)
			hbox.add_child(lock_lbl)
			
		item_list_vbox.add_child(row)

func _populate_supplies() -> void:
	var _p = get_tree().get_first_node_in_group("local_player")
	var player_id = _p.player_id if _p and "player_id" in _p else ""
	_clear_list()
	var supplies = shop_catalog.get("supplies", [])
	var em = get_node_or_null("/root/EconomyManager")
	var im = get_node_or_null("/root/InventoryManager")
	var current_gold = em.get_gold(player_id) if em else 0
	
	for sup in supplies:
		var item_id = sup.get("id", "")
		var item_name = sup.get("name", "Supply")
		var desc = sup.get("description", "")
		var price = int(sup.get("price", 30))
		var owned_count = im.get_item_count(player_id, item_id) if im else 0
		
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(480, 52)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		row.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(24, 24)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = AssetRegistry.get_item_icon(item_id)
		hbox.add_child(icon_rect)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title_l = Label.new()
		title_l.text = "%s (Owned: %d)" % [item_name, owned_count]
		title_l.modulate = Color(1.0, 0.95, 0.5)
		vbox.add_child(title_l)
		
		var desc_l = Label.new()
		desc_l.text = desc
		desc_l.modulate = Color(0.8, 0.8, 0.8)
		desc_l.add_theme_font_size_override("font_size", 11)
		vbox.add_child(desc_l)
		hbox.add_child(vbox)
		
		var price_lbl = Label.new()
		price_lbl.text = "💰 %d G" % price
		price_lbl.modulate = Color(1.0, 0.85, 0.3)
		hbox.add_child(price_lbl)
		
		var buy_btn = Button.new()
		buy_btn.text = "Buy"
		buy_btn.custom_minimum_size = Vector2(64, 28)
		var can_buy = (current_gold >= price)
		buy_btn.disabled = not can_buy
		if not can_buy: buy_btn.modulate = Color(0.7, 0.7, 0.7, 0.6)
		buy_btn.pressed.connect(func(): _on_buy_item(item_id, item_name, price))
		hbox.add_child(buy_btn)
		
		item_list_vbox.add_child(row)

func _populate_upgrades() -> void:
	var _p = get_tree().get_first_node_in_group("local_player")
	var player_id = _p.player_id if _p and "player_id" in _p else ""
	_clear_list()
	var upgrades = upgrades_catalog.get("upgrades", [])
	var em = get_node_or_null("/root/EconomyManager")
	var current_gold = em.get_gold(player_id) if em else 0
	
	for up in upgrades:
		var up_id = up.get("id", "")
		var up_name = up.get("name", "Upgrade")
		var desc = up.get("description", "")
		var price = int(up.get("price", 100))
		var is_purchased = em.has_upgrade(player_id, up_id) if em else false
		
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(480, 56)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		row.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(28, 28)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = AssetRegistry.get_item_icon(up_id)
		hbox.add_child(icon_rect)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title_l = Label.new()
		title_l.text = "⭐ " + up_name
		title_l.modulate = Color(1.0, 0.95, 0.4) if not is_purchased else Color(0.6, 1.0, 0.6)
		vbox.add_child(title_l)
		
		var desc_l = Label.new()
		desc_l.text = desc
		desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_l.modulate = Color(0.8, 0.8, 0.8)
		desc_l.add_theme_font_size_override("font_size", 11)
		vbox.add_child(desc_l)
		hbox.add_child(vbox)
		
		if is_purchased:
			var acq_lbl = Label.new()
			acq_lbl.text = "✅ Acquired"
			acq_lbl.modulate = Color(0.5, 1.0, 0.5)
			hbox.add_child(acq_lbl)
		else:
			var price_lbl = Label.new()
			price_lbl.text = "💰 %d G" % price
			price_lbl.modulate = Color(1.0, 0.85, 0.3)
			hbox.add_child(price_lbl)
			
			var buy_btn = Button.new()
			buy_btn.text = "Unlock"
			buy_btn.custom_minimum_size = Vector2(70, 28)
			var can_buy = (current_gold >= price)
			buy_btn.disabled = not can_buy
			if not can_buy: buy_btn.modulate = Color(0.7, 0.7, 0.7, 0.6)
			buy_btn.pressed.connect(func():
				if em:
					em.purchase_upgrade(player_id, up_id, price)
					refresh_ui()
			)
			hbox.add_child(buy_btn)
			
		item_list_vbox.add_child(row)

func _populate_sell() -> void:
	var _p = get_tree().get_first_node_in_group("local_player")
	var player_id = _p.player_id if _p and "player_id" in _p else ""
	_clear_list()
	var im = get_node_or_null("/root/InventoryManager")
	var pm = get_node_or_null("/root/PlantManager")
	var em = get_node_or_null("/root/EconomyManager")
	
	var all_items = im.get_all_items(player_id) if im else {}
	var has_crops = false
	
	for item_id in all_items.keys():
		if item_id.begins_with("seed_") or item_id in ["fertilizer_growth", "herbal_tonic"]:
			continue
		var count = int(all_items[item_id])
		if count <= 0:
			continue
			
		has_crops = true
		var plant_data = pm.get_plant(item_id) if pm else {}
		var item_name = plant_data.get("name", item_id.capitalize())
		var raw_price = int(plant_data.get("value", {}).get("base_price", 50))
		var multiplier = em.get_sell_price_multiplier(item_id) if em else 1.0
		var final_unit_price = int(raw_price * multiplier)
		
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(480, 44)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		row.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		margin.add_child(hbox)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(24, 24)
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.texture = AssetRegistry.get_item_icon(item_id)
		hbox.add_child(icon_rect)
		
		var name_lbl = Label.new()
		name_lbl.text = "%s (x%d)" % [item_name, count]
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)
		
		var price_lbl = Label.new()
		price_lbl.text = "💰 %d G/ea" % final_unit_price
		price_lbl.modulate = Color(0.6, 1.0, 0.4)
		hbox.add_child(price_lbl)
		
		var sell_1_btn = Button.new()
		sell_1_btn.text = "Sell 1"
		sell_1_btn.custom_minimum_size = Vector2(56, 28)
		sell_1_btn.pressed.connect(func(): _on_sell_item(item_id, item_name, final_unit_price, 1))
		hbox.add_child(sell_1_btn)
		
		var sell_all_btn = Button.new()
		sell_all_btn.text = "Sell All"
		sell_all_btn.custom_minimum_size = Vector2(64, 28)
		sell_all_btn.pressed.connect(func(): _on_sell_item(item_id, item_name, final_unit_price, count))
		hbox.add_child(sell_all_btn)
		
		item_list_vbox.add_child(row)
		
	if empty_label: empty_label.visible = not has_crops
	if scroll_container: scroll_container.visible = has_crops

func _clear_list() -> void:
	if item_list_vbox:
		for c in item_list_vbox.get_children():
			c.queue_free()
	if empty_label: empty_label.visible = false
	if scroll_container: scroll_container.visible = true

func _on_buy_item(item_id: String, item_name: String, price: int) -> void:
	var _p = get_tree().get_first_node_in_group("local_player")
	var player_id = _p.player_id if _p and "player_id" in _p else "player_001"
	var ns = get_node_or_null("/root/NetworkShop")
	if ns:
		var wl = get_node_or_null("/root/WorldLoader")
		var world_id = wl.current_world_id if wl else "farm"
		ns.request_buy(world_id, "rowan_seed_shop", item_id, 1)
		# UI refresh will happen via NetworkShop.purchase_completed signal
		call_deferred("refresh_ui")
		return
	# Offline fallback (original logic)
	var em = get_node_or_null("/root/EconomyManager")
	var im = get_node_or_null("/root/InventoryManager")
	var am = get_node_or_null("/root/AudioManager")
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if em and em.can_afford(player_id, price):
		if em.spend_gold(player_id, price):
			if im: im.add_item(player_id, item_id, 1)
			if am: am.play_sfx("buy")
			if spawner:
				spawner.spawn_floating_text(pos, "+1 %s\n-%d Gold" % [item_name, price], Color(0.4, 1.0, 0.4))
			var bus = get_node_or_null("/root/EventBus")
			if bus: bus.item_bought.emit(player_id, item_id, 1, price)
			refresh_ui()
	else:
		if am: am.play_sfx("insufficient_gold")
		if spawner:
			spawner.spawn_floating_text(pos, "Not enough Gold!", Color(1.0, 0.4, 0.4))

func _on_sell_item(item_id: String, item_name: String, unit_price: int, count: int) -> void:
	var _p = get_tree().get_first_node_in_group("local_player")
	var player_id = _p.player_id if _p and "player_id" in _p else "player_001"
	var ns = get_node_or_null("/root/NetworkShop")
	if ns:
		var wl = get_node_or_null("/root/WorldLoader")
		var world_id = wl.current_world_id if wl else "farm"
		ns.request_sell(world_id, "rowan_seed_shop", item_id, count)
		call_deferred("refresh_ui")
		return
	# Offline fallback (original logic)
	var em = get_node_or_null("/root/EconomyManager")
	var im = get_node_or_null("/root/InventoryManager")
	var am = get_node_or_null("/root/AudioManager")
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if im and im.has_item(player_id, item_id, count):
		if im.remove_item(player_id, item_id, count):
			var total_gold = unit_price * count
			if em: em.add_gold(player_id, total_gold)
			if am: am.play_sfx("sell")
			if spawner:
				spawner.spawn_floating_text(pos, "+%d Gold\n-%d %s" % [total_gold, count, item_name], Color(1.0, 0.9, 0.2))
			var bus = get_node_or_null("/root/EventBus")
			if bus: bus.item_sold.emit(player_id, item_id, count, total_gold)
			refresh_ui()

func _bind_local_player(world_id: String, _world_data: Dictionary = {}) -> void:
	var player = get_tree().get_first_node_in_group("local_player")
	if player and player.player_state:
		if not player.player_state.inventory_changed.is_connected(refresh_ui):
			player.player_state.inventory_changed.connect(refresh_ui)
	refresh_ui()
