class_name SettingsUI
extends Control

## Comprehensive Cozy Botanical Fantasy Settings modal covering Graphics, Audio, Gameplay, Controls, Accessibility and Language.

signal back_pressed()
signal closed()

enum Tab { GRAPHICS, AUDIO, GAMEPLAY, CONTROLS, ACCESSIBILITY, LANGUAGE, DEVELOPER }

var current_tab: Tab = Tab.GRAPHICS

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var close_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton

@onready var tab_graphics_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/GraphicsTabBtn
@onready var tab_audio_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/AudioTabBtn
@onready var tab_gameplay_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/GameplayTabBtn
@onready var tab_controls_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/ControlsTabBtn
@onready var tab_access_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/AccessTabBtn
@onready var tab_lang_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/LangTabBtn
@onready var tab_developer_btn: Button = find_child("DeveloperTabBtn", true, false)

@onready var content_vbox: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContentScroll/ContentVBox
@onready var apply_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/ApplyButton
@onready var reset_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/ResetButton
@onready var cancel_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/CancelButton

var temp_settings: Dictionary = {}
var is_rebinding: bool = false
var rebind_action: String = ""

func _ready() -> void:
	visible = false
	theme = UIConstants.get_theme()
	_bind_header_footer()
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(_on_locale_changed)
	_update_localized_texts()
	_switch_tab(Tab.GRAPHICS)

func _on_locale_changed(_locale_id: String) -> void:
	_update_localized_texts()
	if visible:
		_switch_tab(current_tab)

func _update_localized_texts() -> void:
	if title_label: title_label.text = tr("ui.menu.settings")
	if apply_btn: apply_btn.text = tr("ui.menu.apply")
	if cancel_btn: cancel_btn.text = tr("ui.menu.cancel")
	if reset_btn: reset_btn.text = tr("ui.menu.reset")
	if tab_graphics_btn: tab_graphics_btn.text = tr("ui.settings.tab.graphics")
	if tab_audio_btn: tab_audio_btn.text = tr("ui.settings.tab.audio")
	if tab_gameplay_btn: tab_gameplay_btn.text = tr("ui.settings.tab.gameplay")
	if tab_controls_btn: tab_controls_btn.text = tr("ui.settings.tab.controls")
	if tab_access_btn: tab_access_btn.text = tr("ui.settings.tab.accessibility")
	if tab_lang_btn: tab_lang_btn.text = tr("ui.settings.tab.language")
	if tab_developer_btn: tab_developer_btn.text = tr("ui.settings.tab.developer") if tr("ui.settings.tab.developer") != "ui.settings.tab.developer" else "🛠️ Developer"

func _bind_header_footer() -> void:
	if close_btn: close_btn.pressed.connect(close_settings)
	if cancel_btn: cancel_btn.pressed.connect(close_settings)
	if apply_btn: apply_btn.pressed.connect(_on_apply_pressed)
	if reset_btn: reset_btn.pressed.connect(_on_reset_pressed)
	
	if tab_graphics_btn: tab_graphics_btn.pressed.connect(func(): _switch_tab(Tab.GRAPHICS))
	if tab_audio_btn: tab_audio_btn.pressed.connect(func(): _switch_tab(Tab.AUDIO))
	if tab_gameplay_btn: tab_gameplay_btn.pressed.connect(func(): _switch_tab(Tab.GAMEPLAY))
	if tab_controls_btn: tab_controls_btn.pressed.connect(func(): _switch_tab(Tab.CONTROLS))
	if tab_access_btn: tab_access_btn.pressed.connect(func(): _switch_tab(Tab.ACCESSIBILITY))
	if tab_lang_btn: tab_lang_btn.pressed.connect(func(): _switch_tab(Tab.LANGUAGE))
	if tab_developer_btn: tab_developer_btn.pressed.connect(func(): _switch_tab(Tab.DEVELOPER))


func open_settings() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm: temp_settings = sm.settings.duplicate(true)
	else: temp_settings = SettingsData.get_default_settings()
	
	UIConstants.close_all_modals(get_tree(), self)
	visible = true
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_open")
	UIConstants.update_player_lock(get_tree())
	_switch_tab(current_tab)

func close_settings() -> void:
	visible = false
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_close")
	UIConstants.update_player_lock(get_tree())
	back_pressed.emit()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if is_rebinding and event is InputEventKey and event.pressed:
		var k_str = OS.get_keycode_string(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)
		if k_str != "":
			if not temp_settings.has("controls"): temp_settings["controls"] = {}
			temp_settings["controls"][rebind_action] = [k_str]
			is_rebinding = false
			rebind_action = ""
			_populate_controls()
		get_viewport().set_input_as_handled()
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_settings()
			get_viewport().set_input_as_handled()

func _switch_tab(tab: Tab) -> void:
	current_tab = tab
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	var tab_btns = [tab_graphics_btn, tab_audio_btn, tab_gameplay_btn, tab_controls_btn, tab_access_btn, tab_lang_btn, tab_developer_btn]
	for i in range(tab_btns.size()):
		var b: Button = tab_btns[i]
		if b:
			b.modulate = Color.WHITE
			if i == tab:
				b.add_theme_stylebox_override("normal", UIConstants.create_active_button_stylebox())
				b.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
			else:
				b.remove_theme_stylebox_override("normal")
				b.remove_theme_color_override("font_color")
			
	if not content_vbox: return
	for c in content_vbox.get_children(): c.queue_free()
	
	match tab:
		Tab.GRAPHICS: _populate_graphics()
		Tab.AUDIO: _populate_audio()
		Tab.GAMEPLAY: _populate_gameplay()
		Tab.CONTROLS: _populate_controls()
		Tab.ACCESSIBILITY: _populate_accessibility()
		Tab.LANGUAGE: _populate_language()
		Tab.DEVELOPER: _populate_developer()

func _populate_graphics() -> void:
	var g = temp_settings.get("graphics", {})
	_add_option_dropdown("Resolution", ["1280x720", "1366x768", "1600x900", "1920x1080", "2560x1440", "3840x2160"], str(g.get("resolution", "1920x1080")), func(v): g["resolution"] = v)
	_add_option_dropdown("Window Mode", ["Windowed", "Borderless", "Fullscreen"], str(g.get("window_mode", "Windowed")).capitalize(), func(v): g["window_mode"] = v.to_lower())
	_add_option_checkbox("VSync", bool(g.get("vsync", true)), func(b): g["vsync"] = b)
	
	var cur_fps = int(g.get("fps_limit", 60))
	var cur_fps_str = "Unlimited" if cur_fps <= 0 else str(cur_fps)
	_add_option_dropdown("FPS Limit", ["30", "60", "90", "120", "144", "240", "Unlimited"], cur_fps_str, func(v): g["fps_limit"] = 0 if v == "Unlimited" else int(v))
	_add_option_dropdown("Camera Zoom", ["75%", "100%", "125%", "150%"], "%d%%" % int(float(g.get("camera_zoom", 1.0)) * 100.0), func(v): g["camera_zoom"] = float(v.trim_suffix("%")) / 100.0)
	_add_option_checkbox("Integer Pixel Scaling", bool(g.get("integer_scaling", false)), func(b): g["integer_scaling"] = b)


func _populate_audio() -> void:
	var a = temp_settings.get("audio", {})
	_add_option_slider("Master Volume", int(a.get("master_volume", 100)), func(v): a["master_volume"] = v)
	_add_option_slider("Music Volume", int(a.get("music_volume", 70)), func(v): a["music_volume"] = v)
	_add_option_slider("SFX Volume", int(a.get("sfx_volume", 100)), func(v): a["sfx_volume"] = v)

func _populate_gameplay() -> void:
	var gp = temp_settings.get("gameplay", {})
	_add_option_checkbox("Screen Shake", bool(gp.get("screen_shake", true)), func(b): gp["screen_shake"] = b)
	_add_option_dropdown("Particle Effects", ["Full", "Reduced", "Off"], str(gp.get("particle_effects", "Full")).capitalize(), func(v): gp["particle_effects"] = v.to_lower())
	_add_option_checkbox("Floating Popup Text", bool(gp.get("floating_text", true)), func(b): gp["floating_text"] = b)
	_add_option_checkbox("Auto Save on Sleep", bool(gp.get("auto_save", true)), func(b): gp["auto_save"] = b)
	_add_option_checkbox("Action Tooltips", bool(gp.get("tooltips", true)), func(b): gp["tooltips"] = b)

func _populate_controls() -> void:
	var c = temp_settings.get("controls", {})
	for action in ["move_up", "move_down", "move_left", "move_right", "interact", "inventory", "journal", "combination", "quest", "pause", "quick_save", "quick_load"]:
		var dname = action.replace("_", " ").capitalize()
		var keys_list = c.get(action, ["?"])
		var key_display = ", ".join(keys_list)
		_add_rebind_row(dname, action, key_display)

func _populate_accessibility() -> void:
	var acc = temp_settings.get("accessibility", {})
	_add_option_dropdown("UI Scale", ["80%", "90%", "100%", "110%", "125%", "150%"], "%d%%" % int(float(acc.get("ui_scale", 1.0)) * 100.0), func(v): acc["ui_scale"] = float(v.trim_suffix("%")) / 100.0)
	_add_option_dropdown("Text Size", ["Small", "Normal", "Large"], str(acc.get("text_size", "Normal")).capitalize(), func(v): acc["text_size"] = v.to_lower())
	_add_option_checkbox("High Contrast UI", bool(acc.get("high_contrast", false)), func(b): acc["high_contrast"] = b)
	_add_option_checkbox("Reduced Motion", bool(acc.get("reduced_motion", false)), func(b): acc["reduced_motion"] = b)

func _populate_language() -> void:
	var l = temp_settings.get("language", {})
	var cur_code = str(l.get("current_language", "en"))
	
	var lm = get_node_or_null("/root/LocalizationManager")
	var supported = lm.get_supported_languages() if lm else { "en": "English", "tr": "Türkçe" }
	
	var lang_names: Array = []
	var lang_codes: Array = []
	var selected_name = supported.get(cur_code, "English")
	
	for code in supported.keys():
		lang_codes.append(code)
		lang_names.append(supported[code])
		
	_add_option_dropdown(tr("ui.settings.language_select"), lang_names, selected_name, func(v):
		for code in supported.keys():
			if supported[code] == v:
				l["current_language"] = code
				break
	)

func _populate_developer() -> void:
	var dev = temp_settings.get("developer", {})
	if typeof(dev) != TYPE_DICTIONARY:
		dev = {}
		temp_settings["developer"] = dev
	var is_dev_mode = bool(dev.get("developer_mode", false))
	_add_option_checkbox(tr("ui.settings.developer_mode") if tr("ui.settings.developer_mode") != "ui.settings.developer_mode" else "Developer Mode", is_dev_mode, func(b): dev["developer_mode"] = b)

func _add_option_dropdown(label_text: String, items: Array, selected_item: String, on_change: Callable) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	
	var opt = OptionButton.new()
	opt.custom_minimum_size = Vector2(160, 28)
	var sel_idx = 0
	for i in range(items.size()):
		opt.add_item(items[i])
		if items[i] == selected_item: sel_idx = i
	opt.select(sel_idx)
	opt.item_selected.connect(func(idx): on_change.call(opt.get_item_text(idx)))
	hbox.add_child(opt)
	content_vbox.add_child(hbox)

func _add_option_checkbox(label_text: String, is_checked: bool, on_toggle: Callable) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	
	var chk = CheckBox.new()
	chk.button_pressed = is_checked
	UIConstants.apply_checkbox_style(chk)
	chk.toggled.connect(on_toggle)
	hbox.add_child(chk)
	content_vbox.add_child(hbox)

func _add_option_slider(label_text: String, val: int, on_val_change: Callable) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = "%s (%d%%)" % [label_text, val]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	
	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = val
	slider.custom_minimum_size = Vector2(160, 20)
	slider.value_changed.connect(func(v):
		lbl.text = "%s (%d%%)" % [label_text, int(v)]
		on_val_change.call(int(v))
	)
	hbox.add_child(slider)
	content_vbox.add_child(hbox)

func _add_rebind_row(display_name: String, action: String, current_key: String) -> void:
	var hbox = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = display_name
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)
	
	var btn = Button.new()
	btn.text = "[ %s ]" % current_key
	btn.custom_minimum_size = Vector2(140, 26)
	btn.pressed.connect(func():
		is_rebinding = true
		rebind_action = action
		btn.text = "Press any key..."
		btn.modulate = Color(1.3, 1.3, 0.5)
	)
	hbox.add_child(btn)
	content_vbox.add_child(hbox)

func _on_apply_pressed() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm:
		sm.settings = temp_settings.duplicate(true)
		sm.save_settings()
		sm.apply_all_settings()
		
	var target_lang = str(temp_settings.get("language", {}).get("current_language", "en"))
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.set_locale(target_lang)
		
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner: spawner.spawn_floating_text(pos, "⚙️ Settings Saved!", Color(0.4, 1.0, 0.4))
	close_settings()


func _on_reset_pressed() -> void:
	var sm = get_node_or_null("/root/SettingsManager")
	if sm: sm.reset_to_defaults()
	temp_settings = SettingsData.get_default_settings()
	_switch_tab(current_tab)
