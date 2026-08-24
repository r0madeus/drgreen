@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Control.new()
	root.name = "QuestUI"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://systems/quest/quest_ui.gd"))

	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	center.owner = root

	var panel = PanelContainer.new()
	panel.name = "PanelContainer"
	panel.custom_minimum_size = Vector2(520, 380)
	center.add_child(panel)
	panel.owner = root

	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
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
	title_lbl.text = "📜 Valley Quests & Tasks"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_lbl)
	title_lbl.owner = root

	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(32, 28)
	header.add_child(close_btn)
	close_btn.owner = root

	# Tabs
	var tabs = HBoxContainer.new()
	tabs.name = "TabButtons"
	tabs.add_theme_constant_override("separation", 10)
	vbox.add_child(tabs)
	tabs.owner = root

	var active_btn = Button.new()
	active_btn.name = "ActiveTabButton"
	active_btn.text = "⏳ Active Quests"
	active_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(active_btn)
	active_btn.owner = root

	var comp_btn = Button.new()
	comp_btn.name = "CompletedTabButton"
	comp_btn.text = "✅ Completed"
	comp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(comp_btn)
	comp_btn.owner = root

	var sep = HSeparator.new()
	vbox.add_child(sep)
	sep.owner = root

	# Content
	var content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content)
	content.owner = root

	var active_scroll = ScrollContainer.new()
	active_scroll.name = "ActiveScroll"
	active_scroll.custom_minimum_size = Vector2(480, 240)
	active_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(active_scroll)
	active_scroll.owner = root

	var active_list = VBoxContainer.new()
	active_list.name = "ActiveList"
	active_list.add_theme_constant_override("separation", 8)
	active_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_scroll.add_child(active_list)
	active_list.owner = root

	var active_empty = Label.new()
	active_empty.name = "ActiveEmptyLabel"
	active_empty.text = "No active quests at the moment.\nTalk to Rowan for new tasks!"
	active_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	active_empty.custom_minimum_size = Vector2(480, 200)
	active_empty.visible = false
	content.add_child(active_empty)
	active_empty.owner = root

	var comp_scroll = ScrollContainer.new()
	comp_scroll.name = "CompletedScroll"
	comp_scroll.custom_minimum_size = Vector2(480, 240)
	comp_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	comp_scroll.visible = false
	content.add_child(comp_scroll)
	comp_scroll.owner = root

	var comp_list = VBoxContainer.new()
	comp_list.name = "CompletedList"
	comp_list.add_theme_constant_override("separation", 8)
	comp_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	comp_scroll.add_child(comp_list)
	comp_list.owner = root

	var comp_empty = Label.new()
	comp_empty.name = "CompletedEmptyLabel"
	comp_empty.text = "No completed quests yet."
	comp_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comp_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	comp_empty.custom_minimum_size = Vector2(480, 200)
	comp_empty.visible = false
	content.add_child(comp_empty)
	comp_empty.owner = root

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://systems/quest/quest_ui.tscn")
	print("[QuestSceneBuilder] Successfully saved quest_ui.tscn!")
