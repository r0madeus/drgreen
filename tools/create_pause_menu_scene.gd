@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Control.new()
	root.name = "PauseMenu"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://ui/pause_menu.gd"))

	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	center.owner = root

	var panel = PanelContainer.new()
	panel.name = "PanelContainer"
	panel.custom_minimum_size = Vector2(320, 280)
	center.add_child(panel)
	panel.owner = root

	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	margin.owner = root

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	vbox.owner = root

	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "🌿 Game Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(title)
	title.owner = root

	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	sep1.owner = root

	var res_btn = Button.new()
	res_btn.name = "ResumeButton"
	res_btn.text = "▶ Resume Game"
	res_btn.custom_minimum_size = Vector2(240, 32)
	vbox.add_child(res_btn)
	res_btn.owner = root

	var save_btn = Button.new()
	save_btn.name = "SaveButton"
	save_btn.text = "💾 Save Game (F5)"
	save_btn.custom_minimum_size = Vector2(240, 32)
	vbox.add_child(save_btn)
	save_btn.owner = root

	var load_btn = Button.new()
	load_btn.name = "LoadButton"
	load_btn.text = "📂 Load Game (F9)"
	load_btn.custom_minimum_size = Vector2(240, 32)
	vbox.add_child(load_btn)
	load_btn.owner = root

	var opt_btn = Button.new()
	opt_btn.name = "OptionsButton"
	opt_btn.text = "⚙️ Audio & Settings"
	opt_btn.custom_minimum_size = Vector2(240, 32)
	vbox.add_child(opt_btn)
	opt_btn.owner = root

	# Options Panel (collapsible)
	var opt_panel = VBoxContainer.new()
	opt_panel.name = "OptionsPanel"
	opt_panel.add_theme_constant_override("separation", 8)
	opt_panel.visible = false
	vbox.add_child(opt_panel)
	opt_panel.owner = root

	# Master
	var m_box = HBoxContainer.new()
	m_box.name = "MasterHBox"
	var m_lbl = Label.new()
	m_lbl.text = "Master"
	m_lbl.custom_minimum_size = Vector2(60, 0)
	m_box.add_child(m_lbl)
	m_lbl.owner = root
	var m_sl = HSlider.new()
	m_sl.name = "MasterSlider"
	m_sl.min_value = 0.0; m_sl.max_value = 1.0; m_sl.step = 0.05; m_sl.value = 1.0
	m_sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_box.add_child(m_sl)
	m_sl.owner = root
	opt_panel.add_child(m_box)
	m_box.owner = root

	# SFX
	var s_box = HBoxContainer.new()
	s_box.name = "SFXHBox"
	var s_lbl = Label.new()
	s_lbl.text = "SFX"
	s_lbl.custom_minimum_size = Vector2(60, 0)
	s_box.add_child(s_lbl)
	s_lbl.owner = root
	var s_sl = HSlider.new()
	s_sl.name = "SFXSlider"
	s_sl.min_value = 0.0; s_sl.max_value = 1.0; s_sl.step = 0.05; s_sl.value = 1.0
	s_sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_box.add_child(s_sl)
	s_sl.owner = root
	opt_panel.add_child(s_box)
	s_box.owner = root

	# Music
	var mu_box = HBoxContainer.new()
	mu_box.name = "MusicHBox"
	var mu_lbl = Label.new()
	mu_lbl.text = "Music"
	mu_lbl.custom_minimum_size = Vector2(60, 0)
	mu_box.add_child(mu_lbl)
	mu_lbl.owner = root
	var mu_sl = HSlider.new()
	mu_sl.name = "MusicSlider"
	mu_sl.min_value = 0.0; mu_sl.max_value = 1.0; mu_sl.step = 0.05; mu_sl.value = 0.8
	mu_sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mu_box.add_child(mu_sl)
	mu_sl.owner = root
	opt_panel.add_child(mu_box)
	mu_box.owner = root

	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	sep2.owner = root

	var quit_btn = Button.new()
	quit_btn.name = "QuitButton"
	quit_btn.text = "✕ Quit Game"
	quit_btn.custom_minimum_size = Vector2(240, 32)
	vbox.add_child(quit_btn)
	quit_btn.owner = root

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://ui/pause_menu.tscn")
	print("[PauseMenuBuilder] Successfully built pause_menu.tscn!")
