class_name SleepConfirmationUI
extends Control

## Modal dialog asking player for confirmation before advancing to the next day.
## Uses Localization keys and prevents accidental day advancement.

signal sleep_confirmed()
signal sleep_cancelled()

var panel: PanelContainer
var prompt_label: Label
var btn_yes: Button
var btn_no: Button

func _ready() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH
	mouse_filter = MOUSE_FILTER_STOP
	visible = false
	z_index = 150
	
	_create_ui()
	
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.sleep_requested.connect(show_dialog)
		
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(func(_l): _update_texts())

func _create_ui() -> void:
	# Dim background overlay
	var bg = ColorRect.new()
	bg.anchors_preset = PRESET_FULL_RECT
	bg.color = Color(0.0, 0.0, 0.0, 0.6)
	bg.mouse_filter = MOUSE_FILTER_STOP
	add_child(bg)
	
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 140)
	panel.set_anchors_preset(PRESET_CENTER)
	panel.grow_horizontal = GROW_DIRECTION_BOTH
	panel.grow_vertical = GROW_DIRECTION_BOTH
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.13, 0.18, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.38, 0.46, 0.60, 0.9)
	sb.set_corner_radius_all(6)
	sb.shadow_size = 8
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Prompt label
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85, 1.0))
	vbox.add_child(prompt_label)
	
	# Buttons HBox
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	btn_yes = Button.new()
	btn_yes.custom_minimum_size = Vector2(90, 26)
	btn_yes.add_theme_font_size_override("font_size", 11)
	btn_yes.pressed.connect(_on_yes_pressed)
	hbox.add_child(btn_yes)
	
	btn_no = Button.new()
	btn_no.custom_minimum_size = Vector2(90, 26)
	btn_no.add_theme_font_size_override("font_size", 11)
	btn_no.pressed.connect(_on_no_pressed)
	hbox.add_child(btn_no)
	
	_update_texts()

func _update_texts() -> void:
	var lm = get_node_or_null("/root/LocalizationManager")
	if prompt_label:
		prompt_label.text = lm.get_text("ui.sleep.confirm_prompt", "Sleep until tomorrow morning?") if lm else "Sleep until tomorrow morning?"
	if btn_yes:
		btn_yes.text = lm.get_text("ui.sleep.confirm_yes", "Yes - Sleep") if lm else "Yes - Sleep"
	if btn_no:
		btn_no.text = lm.get_text("ui.sleep.confirm_no", "Cancel") if lm else "Cancel"

func show_dialog() -> void:
	_update_texts()
	visible = true
	var tm = get_node_or_null("/root/TimeManager")
	if tm: tm.pause_time("SLEEP_UI")
	if btn_yes: btn_yes.grab_focus()

func hide_dialog() -> void:
	visible = false
	var tm = get_node_or_null("/root/TimeManager")
	if tm: tm.resume_time("SLEEP_UI")

func _on_yes_pressed() -> void:
	hide_dialog()
	sleep_confirmed.emit()
	var tm = get_node_or_null("/root/TimeManager")
	if tm: tm.execute_sleep(false)

func _on_no_pressed() -> void:
	hide_dialog()
	sleep_cancelled.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_cancel"):
		_on_no_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_yes_pressed()
		get_viewport().set_input_as_handled()
