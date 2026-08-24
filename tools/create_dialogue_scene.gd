@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Control.new()
	root.name = "DialogueUI"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://systems/dialogue/dialogue_ui.gd"))

	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	center.owner = root

	var panel = PanelContainer.new()
	panel.name = "PanelContainer"
	panel.custom_minimum_size = Vector2(580, 160)
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

	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.add_theme_constant_override("separation", 14)
	margin.add_child(hbox)
	hbox.owner = root

	var portrait = TextureRect.new()
	portrait.name = "PortraitRect"
	portrait.custom_minimum_size = Vector2(64, 64)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hbox.add_child(portrait)
	portrait.owner = root

	var text_vbox = VBoxContainer.new()
	text_vbox.name = "TextVBox"
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 6)
	hbox.add_child(text_vbox)
	text_vbox.owner = root

	var speaker = Label.new()
	speaker.name = "SpeakerLabel"
	speaker.text = "💬 Rowan the Herbalist"
	speaker.modulate = Color(1.0, 0.9, 0.4)
	speaker.add_theme_font_size_override("font_size", 14)
	text_vbox.add_child(speaker)
	speaker.owner = root

	var content = Label.new()
	content.name = "ContentLabel"
	content.text = "Welcome to the valley!"
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.custom_minimum_size = Vector2(460, 60)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_vbox.add_child(content)
	content.owner = root

	var actions = HBoxContainer.new()
	actions.name = "ActionHBox"
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 8)
	text_vbox.add_child(actions)
	actions.owner = root

	var next_b = Button.new()
	next_b.name = "NextButton"
	next_b.text = "Next (E / Space) ▶"
	next_b.custom_minimum_size = Vector2(130, 28)
	actions.add_child(next_b)
	next_b.owner = root

	var shop_b = Button.new()
	shop_b.name = "ShopButton"
	shop_b.text = "🏪 Open Seed Stall"
	shop_b.custom_minimum_size = Vector2(140, 28)
	shop_b.visible = false
	actions.add_child(shop_b)
	shop_b.owner = root

	var close_b = Button.new()
	close_b.name = "CloseButton"
	close_b.text = "✕ Goodbye"
	close_b.custom_minimum_size = Vector2(90, 28)
	close_b.visible = false
	actions.add_child(close_b)
	close_b.owner = root

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://systems/dialogue/dialogue_ui.tscn")
	print("[DialogueSceneBuilder] Successfully saved dialogue_ui.tscn!")
