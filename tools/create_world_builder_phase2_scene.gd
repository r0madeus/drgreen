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

	# TopBar
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

	var title_lbl = Label.new(); title_lbl.name = "AppTitle"; title_lbl.text = "🌍 World Builder Pro"; title_lbl.modulate = Color(1.0, 0.85, 0.3); tb_hbox.add_child(title_lbl)
	tb_hbox.add_child(VSeparator.new())

	var save_b = Button.new(); save_b.name = "SaveButton"; save_b.text = "💾 Save"; tb_hbox.add_child(save_b)
	var open_b = Button.new(); open_b.name = "OpenButton"; open_b.text = "📂 Open"; tb_hbox.add_child(open_b)
	var new_b = Button.new(); new_b.name = "NewButton"; new_b.text = "➕ New"; tb_hbox.add_child(new_b)
	tb_hbox.add_child(VSeparator.new())

	var t_sel = Button.new(); t_sel.name = "ToolSelect"; t_sel.text = "👆 Select"; tb_hbox.add_child(t_sel)
	var t_bru = Button.new(); t_bru.name = "ToolBrush"; t_bru.text = "🖌️ Brush"; tb_hbox.add_child(t_bru)
	var t_era = Button.new(); t_era.name = "ToolEraser"; t_era.text = "🧹 Eraser"; tb_hbox.add_child(t_era)
	var t_rec = Button.new(); t_rec.name = "ToolRect"; t_rec.text = "⬜ Rect"; tb_hbox.add_child(t_rec)
	var t_fil = Button.new(); t_fil.name = "ToolFill"; t_fil.text = "🪣 Fill"; tb_hbox.add_child(t_fil)
	tb_hbox.add_child(VSeparator.new())

	var tg_grid = Button.new(); tg_grid.name = "ToggleGrid"; tg_grid.text = "📐 Grid"; tb_hbox.add_child(tg_grid)
	var tg_col = Button.new(); tg_col.name = "ToggleCollision"; tg_col.text = "🔴 Collision"; tb_hbox.add_child(tg_col)
	var pr_b = Button.new(); pr_b.name = "CreatePrefabBtn"; pr_b.text = "📦 +Prefab"; tb_hbox.add_child(pr_b)
	tb_hbox.add_child(VSeparator.new())

	var u_btn = Button.new(); u_btn.name = "UndoButton"; u_btn.text = "↩️ Undo"; tb_hbox.add_child(u_btn)
	var r_btn = Button.new(); r_btn.name = "RedoButton"; r_btn.text = "↪️ Redo"; tb_hbox.add_child(r_btn)

	# Main Horizontal Split
	var hsplit = HBoxContainer.new()
	hsplit.name = "HSplit"
	hsplit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hsplit.position.y = 46
	hsplit.size.y = 574
	root.add_child(hsplit)

	# LEFT PANEL: Palette + Layer Manager
	var left_vbox = VBoxContainer.new()
	left_vbox.name = "LeftPanel"
	left_vbox.custom_minimum_size = Vector2(240, 0)
	hsplit.add_child(left_vbox)

	var pal = PanelContainer.new()
	pal.name = "AssetPalette"
	pal.set_script(load("res://editor/world_builder/asset_palette.gd"))
	pal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(pal)

	var pal_m = MarginContainer.new()
	pal_m.add_theme_constant_override("margin_left", 6); pal_m.add_theme_constant_override("margin_right", 6)
	pal_m.add_theme_constant_override("margin_top", 6); pal_m.add_theme_constant_override("margin_bottom", 6)
	pal.add_child(pal_m)

	var pal_vb = VBoxContainer.new()
	pal_vb.add_theme_constant_override("separation", 4)
	pal_m.add_child(pal_vb)

	var pal_t = Label.new(); pal_t.text = "🎨 Palette & Prefabs"; pal_t.modulate = Color(1.0, 0.85, 0.3); pal_vb.add_child(pal_t)
	var s_edit = LineEdit.new(); s_edit.name = "SearchEdit"; s_edit.placeholder_text = "🔍 Search assets..."; pal_vb.add_child(s_edit)
	var tabs = TabContainer.new(); tabs.name = "TabContainer"; tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL; pal_vb.add_child(tabs)

	# Layer Panel (Bottom Left)
	var layer_p = PanelContainer.new()
	layer_p.name = "LayerPanel"
	layer_p.custom_minimum_size = Vector2(0, 160)
	left_vbox.add_child(layer_p)

	var lm = MarginContainer.new()
	lm.add_theme_constant_override("margin_left", 6); lm.add_theme_constant_override("margin_right", 6)
	lm.add_theme_constant_override("margin_top", 4); lm.add_theme_constant_override("margin_bottom", 4)
	layer_p.add_child(lm)

	var l_vb = VBoxContainer.new()
	l_vb.add_theme_constant_override("separation", 2)
	lm.add_child(l_vb)

	var lt = Label.new(); lt.text = "📑 Layer Manager"; lt.modulate = Color(1.0, 0.85, 0.3); l_vb.add_child(lt)
	var l_scroll = ScrollContainer.new(); l_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; l_vb.add_child(l_scroll)
	var l_list = VBoxContainer.new(); l_list.name = "LayerListVBox"; l_scroll.add_child(l_list)

	# CENTER AREA: Canvas
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

	# RIGHT PANEL: Inspector
	var right_panel = PanelContainer.new()
	right_panel.name = "RightPanel"
	right_panel.custom_minimum_size = Vector2(240, 0)
	hsplit.add_child(right_panel)

	var insp = PanelContainer.new()
	insp.name = "WorldInspector"
	insp.set_script(load("res://editor/world_builder/world_inspector.gd"))
	insp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(insp)

	var im = MarginContainer.new()
	im.add_theme_constant_override("margin_left", 8); im.add_theme_constant_override("margin_right", 8)
	im.add_theme_constant_override("margin_top", 8); im.add_theme_constant_override("margin_bottom", 8)
	insp.add_child(im)

	var ivb = VBoxContainer.new()
	ivb.add_theme_constant_override("separation", 6)
	im.add_child(ivb)

	var ih = HBoxContainer.new()
	var it = Label.new(); it.name = "TitleLabel"; it.text = "🏷️ Inspector"; it.modulate = Color(1.0, 0.85, 0.3); ih.add_child(it)
	ivb.add_child(ih)

	var emp = Label.new(); emp.name = "EmptyLabel"; emp.text = "No element selected.\\nClick a tile or drag-select objects."
	emp.modulate = Color(0.6, 0.6, 0.6); emp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ivb.add_child(emp)

	var pv = VBoxContainer.new(); pv.name = "PropsContainer"; pv.visible = false; ivb.add_child(pv)

	# Preset Buttons
	var p_grid = GridContainer.new(); p_grid.columns = 2
	var b_w = Button.new(); b_w.name = "PresetWalkable"; b_w.text = "Walkable"; p_grid.add_child(b_w)
	var b_s = Button.new(); b_s.name = "PresetSolid"; b_s.text = "Solid"; p_grid.add_child(b_s)
	var b_i = Button.new(); b_i.name = "PresetInteractable"; b_i.text = "Interact"; p_grid.add_child(b_i)
	var b_d = Button.new(); b_d.name = "PresetDecoration"; b_d.text = "Decor"; p_grid.add_child(b_d)
	pv.add_child(p_grid)
	pv.add_child(HSeparator.new())

	# Asset ID
	var ab = HBoxContainer.new()
	var al = Label.new(); al.text = "Asset ID:"; al.custom_minimum_size = Vector2(70, 0); ab.add_child(al)
	var av = Label.new(); av.name = "AssetIdValue"; av.text = "grass"; ab.add_child(av)
	pv.add_child(ab)

	# Instance ID
	var ib = HBoxContainer.new()
	var il = Label.new(); il.text = "Instance:"; il.custom_minimum_size = Vector2(70, 0); ib.add_child(il)
	var ie = LineEdit.new(); ie.name = "InstanceEdit"; ie.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ib.add_child(ie)
	pv.add_child(ib)

	# Pos X, Y
	var pb = HBoxContainer.new()
	var pl = Label.new(); pl.text = "Pos (X, Y):"; pl.custom_minimum_size = Vector2(70, 0); pb.add_child(pl)
	var px = SpinBox.new(); px.name = "XSpin"; px.min_value = 0; px.max_value = 100; pb.add_child(px)
	var py = SpinBox.new(); py.name = "YSpin"; py.min_value = 0; py.max_value = 100; pb.add_child(py)
	pv.add_child(pb)

	# Layer
	var lb = HBoxContainer.new()
	var ll = Label.new(); ll.text = "Layer:"; ll.custom_minimum_size = Vector2(70, 0); lb.add_child(ll)
	var lo = OptionButton.new(); lo.name = "LayerOption"; lo.size_flags_horizontal = Control.SIZE_EXPAND_FILL; lb.add_child(lo)
	pv.add_child(lb)

	var w_c = CheckBox.new(); w_c.name = "WalkableCheck"; w_c.text = "Walkable"; pv.add_child(w_c)
	var s_c = CheckBox.new(); s_c.name = "SolidCheck"; s_c.text = "Solid"; pv.add_child(s_c)
	var in_c = CheckBox.new(); in_c.name = "InteractableCheck"; in_c.text = "Interactable"; pv.add_child(in_c)

	# Bottom Status Bar
	var bot_bar = PanelContainer.new()
	bot_bar.name = "BottomBar"
	bot_bar.custom_minimum_size = Vector2(0, 26)
	bot_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	root.add_child(bot_bar)

	var bm = MarginContainer.new()
	bm.add_theme_constant_override("margin_left", 8); bm.add_theme_constant_override("margin_right", 8)
	bot_bar.add_child(bm)

	var b_lbl = Label.new()
	b_lbl.name = "BottomStatusLabel"
	b_lbl.text = "X: 0  Y: 0 | Zoom: 150% | Layer: TERRAIN | Selected: 0"
	b_lbl.modulate = Color(0.7, 0.9, 1.0)
	bm.add_child(b_lbl)

	# Set recursive owner on all nodes
	set_owner_recursive(root, root)

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://editor/world_builder/world_builder.tscn")
	print("[WorldBuilderPhase2SceneTool] Successfully created res://editor/world_builder/world_builder.tscn!")

static func set_owner_recursive(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		child.owner = root_node
		set_owner_recursive(child, root_node)
