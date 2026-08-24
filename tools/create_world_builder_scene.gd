@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Control.new()
	root.name = "WorldBuilder"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://editor/world_builder/world_builder.gd"))

	# 1. TopBar Panel
	var top_bar = PanelContainer.new()
	top_bar.name = "TopBar"
	top_bar.custom_minimum_size = Vector2(0, 44)
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	root.add_child(top_bar)

	var tb_margin = MarginContainer.new()
	tb_margin.name = "MarginContainer"
	tb_margin.add_theme_constant_override("margin_left", 8)
	tb_margin.add_theme_constant_override("margin_right", 8)
	top_bar.add_child(tb_margin)

	var tb_hbox = HBoxContainer.new()
	tb_hbox.name = "HBox"
	tb_hbox.add_theme_constant_override("separation", 6)
	tb_margin.add_child(tb_hbox)

	var title_lbl = Label.new()
	title_lbl.name = "AppTitle"
	title_lbl.text = "🌍 World Builder"
	title_lbl.modulate = Color(1.0, 0.85, 0.3)
	tb_hbox.add_child(title_lbl)

	var sep1 = VSeparator.new()
	tb_hbox.add_child(sep1)

	var save_b = Button.new(); save_b.name = "SaveButton"; save_b.text = "💾 Save"; tb_hbox.add_child(save_b)
	var open_b = Button.new(); open_b.name = "OpenButton"; open_b.text = "📂 Open"; tb_hbox.add_child(open_b)
	var new_b = Button.new(); new_b.name = "NewButton"; new_b.text = "➕ New"; tb_hbox.add_child(new_b)

	var sep2 = VSeparator.new()
	tb_hbox.add_child(sep2)

	var t_sel = Button.new(); t_sel.name = "ToolSelect"; t_sel.text = "👆 Select"; tb_hbox.add_child(t_sel)
	var t_bru = Button.new(); t_bru.name = "ToolBrush"; t_bru.text = "🖌️ Brush"; tb_hbox.add_child(t_bru)
	var t_era = Button.new(); t_era.name = "ToolEraser"; t_era.text = "🧹 Eraser"; tb_hbox.add_child(t_era)
	var t_rec = Button.new(); t_rec.name = "ToolRect"; t_rec.text = "⬜ Rect"; tb_hbox.add_child(t_rec)
	var t_fil = Button.new(); t_fil.name = "ToolFill"; t_fil.text = "🪣 Fill"; tb_hbox.add_child(t_fil)

	var sep3 = VSeparator.new()
	tb_hbox.add_child(sep3)

	var tg_grid = Button.new(); tg_grid.name = "ToggleGrid"; tg_grid.text = "📐 Grid"; tb_hbox.add_child(tg_grid)
	var tg_col = Button.new(); tg_col.name = "ToggleCollision"; tg_col.text = "🔴 Collision"; tb_hbox.add_child(tg_col)

	var sep4 = VSeparator.new()
	tb_hbox.add_child(sep4)

	var u_btn = Button.new(); u_btn.name = "UndoButton"; u_btn.text = "↩️ Undo"; tb_hbox.add_child(u_btn)
	var r_btn = Button.new(); r_btn.name = "RedoButton"; r_btn.text = "↪️ Redo"; tb_hbox.add_child(r_btn)

	var st_lbl = Label.new()
	st_lbl.name = "StatusLabel"
	st_lbl.text = "Ready"
	st_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	st_lbl.modulate = Color(0.7, 0.9, 1.0)
	tb_hbox.add_child(st_lbl)

	# 2. Main Horizontal Split Layout
	var hsplit = HBoxContainer.new()
	hsplit.name = "HSplit"
	hsplit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hsplit.position.y = 48
	hsplit.size.y = 600
	root.add_child(hsplit)

	# LEFT PANEL: Asset Palette
	var left_panel = PanelContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.custom_minimum_size = Vector2(230, 0)
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(left_panel)

	var pal = PanelContainer.new()
	pal.name = "AssetPalette"
	pal.set_script(load("res://editor/world_builder/asset_palette.gd"))
	pal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(pal)

	var pal_margin = MarginContainer.new()
	pal_margin.name = "MarginContainer"
	pal_margin.add_theme_constant_override("margin_left", 6)
	pal_margin.add_theme_constant_override("margin_right", 6)
	pal_margin.add_theme_constant_override("margin_top", 6)
	pal_margin.add_theme_constant_override("margin_bottom", 6)
	pal.add_child(pal_margin)

	var pal_vbox = VBoxContainer.new()
	pal_vbox.name = "VBoxContainer"
	pal_vbox.add_theme_constant_override("separation", 6)
	pal_margin.add_child(pal_vbox)

	var pal_title = Label.new()
	pal_title.text = "🎨 Asset Palette"
	pal_title.modulate = Color(1.0, 0.85, 0.3)
	pal_vbox.add_child(pal_title)

	var search_edit = LineEdit.new()
	search_edit.name = "SearchEdit"
	search_edit.placeholder_text = "🔍 Search assets..."
	pal_vbox.add_child(search_edit)

	var tabs = TabContainer.new()
	tabs.name = "TabContainer"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pal_vbox.add_child(tabs)

	# CENTER AREA: World Canvas
	var center_area = PanelContainer.new()
	center_area.name = "CenterArea"
	center_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(center_area)

	var canvas = Control.new()
	canvas.name = "WorldCanvas"
	canvas.set_script(load("res://editor/world_builder/world_canvas.gd"))
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_area.add_child(canvas)

	# RIGHT PANEL: World Inspector
	var right_panel = PanelContainer.new()
	right_panel.name = "RightPanel"
	right_panel.custom_minimum_size = Vector2(230, 0)
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hsplit.add_child(right_panel)

	var insp = PanelContainer.new()
	insp.name = "WorldInspector"
	insp.set_script(load("res://editor/world_builder/world_inspector.gd"))
	insp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(insp)

	var insp_margin = MarginContainer.new()
	insp_margin.name = "MarginContainer"
	insp_margin.add_theme_constant_override("margin_left", 8)
	insp_margin.add_theme_constant_override("margin_right", 8)
	insp_margin.add_theme_constant_override("margin_top", 8)
	insp_margin.add_theme_constant_override("margin_bottom", 8)
	insp.add_child(insp_margin)

	var insp_vbox = VBoxContainer.new()
	insp_vbox.name = "VBoxContainer"
	insp_vbox.add_theme_constant_override("separation", 8)
	insp_margin.add_child(insp_vbox)

	var insp_header = HBoxContainer.new()
	insp_header.name = "Header"
	var insp_title = Label.new()
	insp_title.name = "TitleLabel"
	insp_title.text = "🏷️ Inspector"
	insp_title.modulate = Color(1.0, 0.85, 0.3)
	insp_header.add_child(insp_title)
	insp_vbox.add_child(insp_header)

	var empty_lbl = Label.new()
	empty_lbl.name = "EmptyLabel"
	empty_lbl.text = "No element selected.\\nClick a tile or object to inspect."
	empty_lbl.modulate = Color(0.6, 0.6, 0.6)
	empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	insp_vbox.add_child(empty_lbl)

	var props_vbox = VBoxContainer.new()
	props_vbox.name = "PropsContainer"
	props_vbox.add_theme_constant_override("separation", 6)
	props_vbox.visible = false
	insp_vbox.add_child(props_vbox)

	# Asset ID
	var a_box = HBoxContainer.new(); a_box.name = "AssetIdHBox"
	var a_l = Label.new(); a_l.text = "Asset ID:"; a_l.custom_minimum_size = Vector2(80, 0); a_box.add_child(a_l)
	var a_v = Label.new(); a_v.name = "AssetIdValue"; a_v.text = "grass"; a_box.add_child(a_v)
	props_vbox.add_child(a_box)

	# Instance ID
	var i_box = HBoxContainer.new(); i_box.name = "InstanceHBox"
	var i_l = Label.new(); i_l.text = "Instance:"; i_l.custom_minimum_size = Vector2(80, 0); i_box.add_child(i_l)
	var i_e = LineEdit.new(); i_e.name = "InstanceEdit"; i_e.size_flags_horizontal = Control.SIZE_EXPAND_FILL; i_box.add_child(i_e)
	props_vbox.add_child(i_box)

	# Position X, Y
	var p_box = HBoxContainer.new(); p_box.name = "PosHBox"
	var p_l = Label.new(); p_l.text = "Pos (X, Y):"; p_l.custom_minimum_size = Vector2(80, 0); p_box.add_child(p_l)
	var px = SpinBox.new(); px.name = "XSpin"; px.min_value = 0; px.max_value = 100; p_box.add_child(px)
	var py = SpinBox.new(); py.name = "YSpin"; py.min_value = 0; py.max_value = 100; p_box.add_child(py)
	props_vbox.add_child(p_box)

	# Layer
	var l_box = HBoxContainer.new(); l_box.name = "LayerHBox"
	var l_l = Label.new(); l_l.text = "Layer:"; l_l.custom_minimum_size = Vector2(80, 0); l_box.add_child(l_l)
	var l_o = OptionButton.new(); l_o.name = "LayerOption"; l_o.size_flags_horizontal = Control.SIZE_EXPAND_FILL; l_box.add_child(l_o)
	props_vbox.add_child(l_box)

	# Walkable / Solid / Interactable
	var w_chk = CheckBox.new(); w_chk.name = "WalkableCheck"; w_chk.text = "Walkable (Player pass)"; props_vbox.add_child(w_chk)
	var s_chk = CheckBox.new(); s_chk.name = "SolidCheck"; s_chk.text = "Solid (Collision blocker)"; props_vbox.add_child(s_chk)
	var in_chk = CheckBox.new(); in_chk.name = "InteractableCheck"; in_chk.text = "Interactable (Actionable)"; props_vbox.add_child(in_chk)

	# Set recursive owner on all nodes
	set_owner_recursive(root, root)

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://editor/world_builder/world_builder.tscn")
	print("[WorldBuilderSceneBuilder] Successfully rebuilt res://editor/world_builder/world_builder.tscn!")

static func set_owner_recursive(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		child.owner = root_node
		set_owner_recursive(child, root_node)
