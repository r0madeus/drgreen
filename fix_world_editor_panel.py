import os
with open('editor/ui/panels/world_editor_panel.gd', 'r', encoding='utf-8') as f:
    content = f.read()

insert_tab = '''
	# Tab 4: World Settings
	var ws_tab = ScrollContainer.new()
	ws_tab.name = "?? World Settings"
	right_dock.add_child(ws_tab)
	var ws_vbox = VBoxContainer.new()
	ws_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ws_tab.add_child(ws_vbox)
	
	var ws_w_lbl = Label.new()
	ws_w_lbl.text = "Width:"
	ws_vbox.add_child(ws_w_lbl)
	var ws_w_spin = SpinBox.new()
	ws_w_spin.min_value = 16
	ws_w_spin.max_value = 4096
	ws_w_spin.value = 32
	ws_w_spin.name = "WidthSpin"
	ws_vbox.add_child(ws_w_spin)
	
	var ws_h_lbl = Label.new()
	ws_h_lbl.text = "Height:"
	ws_vbox.add_child(ws_h_lbl)
	var ws_h_spin = SpinBox.new()
	ws_h_spin.min_value = 16
	ws_h_spin.max_value = 4096
	ws_h_spin.value = 24
	ws_h_spin.name = "HeightSpin"
	ws_vbox.add_child(ws_h_spin)
	
	var ws_apply_btn = Button.new()
	ws_apply_btn.text = "Apply Resize"
	ws_apply_btn.pressed.connect(func():
		var nw = int(ws_w_spin.value)
		var nh = int(ws_h_spin.value)
		if canvas:
			canvas.resize_world(nw, nh)
	)
	ws_vbox.add_child(ws_apply_btn)
'''

if 'Tab 4: World Settings' not in content:
    content = content.replace('	# =========================================================================\\n	# 3. BOTTOM STATUS BAR', insert_tab + '\\n	# =========================================================================\\n	# 3. BOTTOM STATUS BAR')

insert_tool = '''
	tool_buttons[CANVAS_SCRIPT.ToolMode.TRANSITION] = _add_tool_btn(tools_vbox, "??", "Transition (T)")
	tool_buttons[CANVAS_SCRIPT.ToolMode.TRANSITION].pressed.connect(func(): _set_tool(CANVAS_SCRIPT.ToolMode.TRANSITION))
'''
if 'CANVAS_SCRIPT.ToolMode.TRANSITION' not in content:
    content = content.replace('	tool_buttons[CANVAS_SCRIPT.ToolMode.SELECT] = _add_tool_btn(tools_vbox, \"???\", \"Select (S)\")', insert_tool + '\\n	tool_buttons[CANVAS_SCRIPT.ToolMode.SELECT] = _add_tool_btn(tools_vbox, \"???\", \"Select (S)\")')

insert_load = '''
	if right_dock:
		var w_spin = right_dock.find_child("WidthSpin", true, false)
		var h_spin = right_dock.find_child("HeightSpin", true, false)
		if w_spin: w_spin.value = int(current_world_data.get("width", 32))
		if h_spin: h_spin.value = int(current_world_data.get("height", 24))
'''
if 'WidthSpin' not in content:
    content = content.replace('	_is_dirty = false\\n	_update_status()', '	_is_dirty = false\\n' + insert_load + '\\n	_update_status()')

with open('editor/ui/panels/world_editor_panel.gd', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done!')
