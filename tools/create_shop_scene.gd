@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Control.new()
	root.name = "ShopUI"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://systems/shop/shop_ui.gd"))

	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	center.owner = root

	var panel = PanelContainer.new()
	panel.name = "PanelContainer"
	panel.custom_minimum_size = Vector2(560, 420)
	center.add_child(panel)
	panel.owner = root

	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	margin.owner = root

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	vbox.owner = root

	# Header
	var header = HBoxContainer.new()
	header.name = "Header"
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)
	header.owner = root

	var title_lbl = Label.new()
	title_lbl.name = "TitleLabel"
	title_lbl.text = "🌿 Rowan's Botanical Stall"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)
	title_lbl.owner = root

	var gold_lbl = Label.new()
	gold_lbl.name = "GoldLabel"
	gold_lbl.text = "💰 Your Gold: 100 G"
	gold_lbl.modulate = Color(1.0, 0.85, 0.2)
	header.add_child(gold_lbl)
	gold_lbl.owner = root

	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 28)
	header.add_child(close_btn)
	close_btn.owner = root

	# Tab Buttons
	var tabs = HBoxContainer.new()
	tabs.name = "TabButtons"
	tabs.add_theme_constant_override("separation", 8)
	vbox.add_child(tabs)
	tabs.owner = root

	var seeds_btn = Button.new()
	seeds_btn.name = "SeedsTabButton"
	seeds_btn.text = "🌱 Seeds"
	seeds_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(seeds_btn)
	seeds_btn.owner = root

	var sup_btn = Button.new()
	sup_btn.name = "SuppliesTabButton"
	sup_btn.text = "🧺 Supplies"
	sup_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(sup_btn)
	sup_btn.owner = root

	var up_btn = Button.new()
	up_btn.name = "UpgradesTabButton"
	up_btn.text = "⚙️ Upgrades"
	up_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(up_btn)
	up_btn.owner = root

	var sell_btn = Button.new()
	sell_btn.name = "SellTabButton"
	sell_btn.text = "🌾 Sell Harvest"
	sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(sell_btn)
	sell_btn.owner = root

	var sep = HSeparator.new()
	vbox.add_child(sep)
	sep.owner = root

	# Content
	var content = VBoxContainer.new()
	content.name = "ContentContainer"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)
	content.owner = root

	var main_scroll = ScrollContainer.new()
	main_scroll.name = "MainScroll"
	main_scroll.custom_minimum_size = Vector2(520, 270)
	main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(main_scroll)
	main_scroll.owner = root

	var item_list = VBoxContainer.new()
	item_list.name = "ItemList"
	item_list.add_theme_constant_override("separation", 6)
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_scroll.add_child(item_list)
	item_list.owner = root

	var empty_lbl = Label.new()
	empty_lbl.name = "EmptyLabel"
	empty_lbl.text = "No items available in this category."
	empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_lbl.custom_minimum_size = Vector2(520, 220)
	empty_lbl.visible = false
	content.add_child(empty_lbl)
	empty_lbl.owner = root

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://systems/shop/shop_ui.tscn")
	print("[ShopSceneBuilder] Successfully rebuilt shop_ui.tscn!")
