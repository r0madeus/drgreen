@tool
extends SceneTree

func _init() -> void:
	pack_phase3_scene()
	quit()

static func pack_phase3_scene() -> void:
	var root = Control.new()
	root.name = "WorldBuilder"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_script(load("res://editor/world_builder/world_builder.gd"))

	# TopBar
	var top_bar = PanelContainer.new(); top_bar.name = "TopBar"; top_bar.custom_minimum_size = Vector2(0, 44); top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE); root.add_child(top_bar)
	var tb_m = MarginContainer.new(); tb_m.add_theme_constant_override("margin_left", 8); tb_m.add_theme_constant_override("margin_right", 8); top_bar.add_child(tb_m)
	var tb_h = HBoxContainer.new(); tb_h.add_theme_constant_override("separation", 6); tb_m.add_child(tb_h)

	var title_lbl = Label.new(); title_lbl.name = "AppTitle"; title_lbl.text = "🌍 World Builder Pro"; title_lbl.modulate = Color(1.0, 0.85, 0.3); tb_h.add_child(title_lbl)
	tb_h.add_child(VSeparator.new())

	var w_opt = OptionButton.new(); w_opt.name = "WorldOption"; w_opt.custom_minimum_size = Vector2(110, 0); tb_h.add_child(w_opt)
	var save_b = Button.new(); save_b.name = "SaveButton"; save_b.text = "💾 Save"; tb_h.add_child(save_b)
	var open_b = Button.new(); open_b.name = "OpenButton"; open_b.text = "📂 Open"; tb_h.add_child(open_b)
	var new_b = Button.new(); new_b.name = "NewButton"; new_b.text = "➕ New"; tb_h.add_child(new_b)
	var graph_b = Button.new(); graph_b.name = "GraphButton"; graph_b.text = "🗺️ Graph"; tb_h.add_child(graph_b)
	var val_b = Button.new(); val_b.name = "ValidateButton"; val_b.text = "🔍 Validate (F5)"; val_b.modulate = Color(0.4, 1.0, 0.7); tb_h.add_child(val_b)
	tb_h.add_child(VSeparator.new())

	var t_sel = Button.new(); t_sel.name = "ToolSelect"; t_sel.text = "👆"; tb_h.add_child(t_sel)
	var t_bru = Button.new(); t_bru.name = "ToolBrush"; t_bru.text = "🖌️"; tb_h.add_child(t_bru)
	var t_era = Button.new(); t_era.name = "ToolEraser"; t_era.text = "🧹"; tb_h.add_child(t_era)
	var t_rec = Button.new(); t_rec.name = "ToolRect"; t_rec.text = "⬜"; tb_h.add_child(t_rec)
	var t_fil = Button.new(); t_fil.name = "ToolFill"; t_fil.text = "🪣"; tb_h.add_child(t_fil)
	tb_h.add_child(VSeparator.new())

	var tg_grid = Button.new(); tg_grid.name = "ToggleGrid"; tg_grid.text = "📐"; tb_h.add_child(tg_grid)
	var tg_col = Button.new(); tg_col.name = "ToggleCollision"; tg_col.text = "🔴"; tb_h.add_child(tg_col)
	var pr_b = Button.new(); pr_b.name = "CreatePrefabBtn"; pr_b.text = "📦"; tb_h.add_child(pr_b)
	tb_h.add_child(VSeparator.new())

	var u_btn = Button.new(); u_btn.name = "UndoButton"; u_btn.text = "↩️"; tb_h.add_child(u_btn)
	var r_btn = Button.new(); r_btn.name = "RedoButton"; r_btn.text = "↪️"; tb_h.add_child(r_btn)

	# Main Split
	var hsplit = HBoxContainer.new(); hsplit.name = "HSplit"; hsplit.set_anchors_preset(Control.PRESET_FULL_RECT); hsplit.position.y = 46; hsplit.size.y = 574; root.add_child(hsplit)

	# Left Panel
	var left_vbox = VBoxContainer.new(); left_vbox.name = "LeftPanel"; left_vbox.custom_minimum_size = Vector2(230, 0); hsplit.add_child(left_vbox)
	var pal = PanelContainer.new(); pal.name = "AssetPalette"; pal.set_script(load("res://editor/world_builder/asset_palette.gd")); pal.size_flags_vertical = Control.SIZE_EXPAND_FILL; left_vbox.add_child(pal)
	var pal_m = MarginContainer.new(); pal_m.add_theme_constant_override("margin_left", 6); pal_m.add_theme_constant_override("margin_right", 6); pal_m.add_theme_constant_override("margin_top", 6); pal_m.add_theme_constant_override("margin_bottom", 6); pal.add_child(pal_m)
	var pal_vb = VBoxContainer.new(); pal_vb.add_theme_constant_override("separation", 4); pal_m.add_child(pal_vb)
	var pal_t = Label.new(); pal_t.text = "🎨 Palette & Prefabs"; pal_t.modulate = Color(1.0, 0.85, 0.3); pal_vb.add_child(pal_t)
	var s_edit = LineEdit.new(); s_edit.name = "SearchEdit"; s_edit.placeholder_text = "🔍 Search assets..."; pal_vb.add_child(s_edit)
	var tabs = TabContainer.new(); tabs.name = "TabContainer"; tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL; pal_vb.add_child(tabs)

	var layer_p = PanelContainer.new(); layer_p.name = "LayerPanel"; layer_p.custom_minimum_size = Vector2(0, 150); left_vbox.add_child(layer_p)
	var lm = MarginContainer.new(); lm.add_theme_constant_override("margin_left", 6); lm.add_theme_constant_override("margin_right", 6); lm.add_theme_constant_override("margin_top", 4); lm.add_theme_constant_override("margin_bottom", 4); layer_p.add_child(lm)
	var l_vb = VBoxContainer.new(); l_vb.add_theme_constant_override("separation", 2); lm.add_child(l_vb)
	var lt = Label.new(); lt.text = "📑 Layer Manager"; lt.modulate = Color(1.0, 0.85, 0.3); l_vb.add_child(lt)
	var l_scroll = ScrollContainer.new(); l_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; l_vb.add_child(l_scroll)
	var l_list = VBoxContainer.new(); l_list.name = "LayerListVBox"; l_scroll.add_child(l_list)

	# Center Area with Canvas + Collapsible Validation Dock
	var center_vbox = VBoxContainer.new(); center_vbox.name = "CenterVBox"; center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL; center_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL; hsplit.add_child(center_vbox)
	var center_area = PanelContainer.new(); center_area.name = "CenterArea"; center_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL; center_area.size_flags_vertical = Control.SIZE_EXPAND_FILL; center_vbox.add_child(center_area)
	var canvas = Control.new(); canvas.name = "WorldCanvas"; canvas.set_script(load("res://editor/world_builder/world_canvas.gd")); canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL; canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL; center_area.add_child(canvas)

	var val_panel_node = PanelContainer.new(); val_panel_node.name = "ValidationPanel"; val_panel_node.set_script(load("res://editor/world_builder/validation_panel.gd")); val_panel_node.custom_minimum_size = Vector2(0, 130); val_panel_node.visible = false; center_vbox.add_child(val_panel_node)
	var vm = MarginContainer.new(); vm.add_theme_constant_override("margin_left", 6); vm.add_theme_constant_override("margin_right", 6); vm.add_theme_constant_override("margin_top", 4); vm.add_theme_constant_override("margin_bottom", 4); val_panel_node.add_child(vm)
	var v_vb = VBoxContainer.new(); vm.add_child(v_vb)
	var v_top = HBoxContainer.new(); v_vb.add_child(v_top)
	var v_stat = Label.new(); v_stat.name = "ValidationStatusLabel"; v_stat.text = "World Validation"; v_stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL; v_top.add_child(v_stat)
	var v_filt = OptionButton.new(); v_filt.name = "FilterOption"; v_top.add_child(v_filt)
	var v_close = Button.new(); v_close.text = "✖"; v_close.pressed.connect(func(): val_panel_node.visible = false); v_top.add_child(v_close)
	var v_scroll = ScrollContainer.new(); v_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; v_vb.add_child(v_scroll)
	var v_res = VBoxContainer.new(); v_res.name = "ResultsVBox"; v_scroll.add_child(v_res)

	# Right Panel (Inspector)
	var right_panel = PanelContainer.new(); right_panel.name = "RightPanel"; right_panel.custom_minimum_size = Vector2(230, 0); hsplit.add_child(right_panel)
	var insp = PanelContainer.new(); insp.name = "WorldInspector"; insp.set_script(load("res://editor/world_builder/world_inspector.gd")); insp.size_flags_horizontal = Control.SIZE_EXPAND_FILL; insp.size_flags_vertical = Control.SIZE_EXPAND_FILL; right_panel.add_child(insp)
	var im = MarginContainer.new(); im.add_theme_constant_override("margin_left", 8); im.add_theme_constant_override("margin_right", 8); im.add_theme_constant_override("margin_top", 8); im.add_theme_constant_override("margin_bottom", 8); insp.add_child(im)
	var ivb = VBoxContainer.new(); ivb.add_theme_constant_override("separation", 6); im.add_child(ivb)
	var it = Label.new(); it.name = "TitleLabel"; it.text = "🏷️ Inspector"; it.modulate = Color(1.0, 0.85, 0.3); ivb.add_child(it)
	var emp = Label.new(); emp.name = "EmptyLabel"; emp.text = "No element selected.\\nClick a tile or drag-select objects."; emp.modulate = Color(0.6, 0.6, 0.6); emp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; ivb.add_child(emp)
	var pv = VBoxContainer.new(); pv.name = "PropsContainer"; pv.visible = false; ivb.add_child(pv)

	var p_grid = GridContainer.new(); p_grid.columns = 2
	var b_w = Button.new(); b_w.name = "PresetWalkable"; b_w.text = "Walkable"; p_grid.add_child(b_w)
	var b_s = Button.new(); b_s.name = "PresetSolid"; b_s.text = "Solid"; p_grid.add_child(b_s)
	var b_i = Button.new(); b_i.name = "PresetInteractable"; b_i.text = "Interact"; p_grid.add_child(b_i)
	var b_d = Button.new(); b_d.name = "PresetDecoration"; b_d.text = "Decor"; p_grid.add_child(b_d)
	pv.add_child(p_grid); pv.add_child(HSeparator.new())

	var ab = HBoxContainer.new(); var al = Label.new(); al.text = "Asset ID:"; al.custom_minimum_size = Vector2(70, 0); ab.add_child(al); var av = Label.new(); av.name = "AssetIdValue"; av.text = "grass"; ab.add_child(av); pv.add_child(ab)
	var ib = HBoxContainer.new(); var il = Label.new(); il.text = "Instance:"; il.custom_minimum_size = Vector2(70, 0); ib.add_child(il); var ie = LineEdit.new(); ie.name = "InstanceEdit"; ie.size_flags_horizontal = Control.SIZE_EXPAND_FILL; ib.add_child(ie); pv.add_child(ib)
	var pb = HBoxContainer.new(); var pl = Label.new(); pl.text = "Pos (X, Y):"; pl.custom_minimum_size = Vector2(70, 0); pb.add_child(pl); var px = SpinBox.new(); px.name = "XSpin"; px.min_value = 0; px.max_value = 100; pb.add_child(px); var py = SpinBox.new(); py.name = "YSpin"; py.min_value = 0; py.max_value = 100; pb.add_child(py); pv.add_child(pb)
	var lb = HBoxContainer.new(); var ll = Label.new(); ll.text = "Layer:"; ll.custom_minimum_size = Vector2(70, 0); lb.add_child(ll); var lo = OptionButton.new(); lo.name = "LayerOption"; lo.size_flags_horizontal = Control.SIZE_EXPAND_FILL; lb.add_child(lo); pv.add_child(lb)
	var w_c = CheckBox.new(); w_c.name = "WalkableCheck"; w_c.text = "Walkable"; pv.add_child(w_c)
	var s_c = CheckBox.new(); s_c.name = "SolidCheck"; s_c.text = "Solid"; pv.add_child(s_c)
	var in_c = CheckBox.new(); in_c.name = "InteractableCheck"; in_c.text = "Interactable"; pv.add_child(in_c)

	# Bottom Status Bar
	var bot_bar = PanelContainer.new(); bot_bar.name = "BottomBar"; bot_bar.custom_minimum_size = Vector2(0, 26); bot_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); root.add_child(bot_bar)
	var bm = MarginContainer.new(); bm.add_theme_constant_override("margin_left", 8); bm.add_theme_constant_override("margin_right", 8); bot_bar.add_child(bm)
	var b_lbl = Label.new(); b_lbl.name = "BottomStatusLabel"; b_lbl.text = "X: 0  Y: 0 | Zoom: 150% | Layer: TERRAIN | Selected: 0"; b_lbl.modulate = Color(0.7, 0.9, 1.0); bm.add_child(b_lbl)

	set_owner_recursive(root, root)
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://editor/world_builder/world_builder.tscn")
	print("[Phase3ScenePacker] Packed Phase 3 scene successfully!")

static func set_owner_recursive(node: Node, root_node: Node) -> void:
	for child in node.get_children():
		child.owner = root_node
		set_owner_recursive(child, root_node)
