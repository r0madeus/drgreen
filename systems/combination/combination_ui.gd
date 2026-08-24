class_name CombinationUI
extends Control

## UI panel for selecting 2 ingredients, executing combinations and displaying discovery celebrations.

var slot_a_item: String = ""
var slot_b_item: String = ""
var active_slot_target: int = 1 # 1: choosing for Slot A, 2: choosing for Slot B

@onready var slot_a_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/SlotsHBox/SlotAButton
@onready var slot_b_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/SlotsHBox/SlotBButton
@onready var combine_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionsHBox/CombineButton
@onready var clear_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/ActionsHBox/ClearButton
@onready var close_btn: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var result_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ResultBanner/ResultLabel
@onready var result_panel: PanelContainer = $PanelContainer/MarginContainer/VBoxContainer/ResultBanner
@onready var picker_grid: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/PickerScroll/PickerGrid
@onready var instruction_label: Label = $PanelContainer/MarginContainer/VBoxContainer/InstructionLabel

func _ready() -> void:
	visible = false
	if slot_a_btn:
		slot_a_btn.pressed.connect(func(): _set_active_target(1))
	if slot_b_btn:
		slot_b_btn.pressed.connect(func(): _set_active_target(2))
	if combine_btn:
		combine_btn.pressed.connect(_on_combine_pressed)
	if clear_btn:
		clear_btn.pressed.connect(clear_slots)
	if close_btn:
		close_btn.pressed.connect(func(): visible = false)
		
	var cm = get_node_or_null("/root/CombinationManager")
	if cm:
		cm.combination_performed.connect(_on_combination_performed)
		
	refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("combination"):
		toggle_visibility()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and visible:
			visible = false
			get_viewport().set_input_as_handled()

func toggle_visibility() -> void:
	visible = not visible
	if visible:
		# Close standard inventory, journal and shop if open to avoid clutter
		var inv = get_tree().root.find_child("InventoryUI", true, false)
		if inv and inv.visible: inv.visible = false
		var jrn = get_tree().root.find_child("JournalUI", true, false)
		if jrn and jrn.visible: jrn.visible = false
		var shop = get_tree().root.find_child("ShopUI", true, false)
		if shop and shop.visible: shop.close_shop()
		refresh_ui()

func _set_active_target(target: int) -> void:
	active_slot_target = target
	_update_slot_buttons()

func clear_slots() -> void:
	slot_a_item = ""
	slot_b_item = ""
	active_slot_target = 1
	if result_panel:
		result_panel.visible = false
	refresh_ui()

func _format_item_name(item_id: String) -> String:
	if item_id == "":
		return "[ Empty Slot ]"
	var dname = item_id.replace("seed_", "🌱 ").replace("_", " ").capitalize()
	if not item_id.begins_with("seed_"):
		dname = "🌸 " + dname
	return dname

func refresh_ui() -> void:
	_update_slot_buttons()
	_populate_picker()

func _update_slot_buttons() -> void:
	var im = get_node_or_null("/root/InventoryManager")
	
	if slot_a_btn:
		var txt = "Slot A: " + _format_item_name(slot_a_item)
		if slot_a_item != "" and im:
			txt += " (x" + str(im.get_item_count(slot_a_item)) + ")"
		slot_a_btn.text = txt
		slot_a_btn.modulate = Color(1.3, 1.3, 0.8) if active_slot_target == 1 else Color.WHITE
		
	if slot_b_btn:
		var txt = "Slot B: " + _format_item_name(slot_b_item)
		if slot_b_item != "" and im:
			txt += " (x" + str(im.get_item_count(slot_b_item)) + ")"
		slot_b_btn.text = txt
		slot_b_btn.modulate = Color(1.3, 1.3, 0.8) if active_slot_target == 2 else Color.WHITE
		
	if instruction_label:
		if active_slot_target == 1:
			instruction_label.text = "Select an item below for Slot A:"
		else:
			instruction_label.text = "Select an item below for Slot B:"
			
	if combine_btn:
		combine_btn.disabled = (slot_a_item == "" or slot_b_item == "")

func _populate_picker() -> void:
	if not picker_grid:
		return
		
	for child in picker_grid.get_children():
		child.queue_free()
		
	var im = get_node_or_null("/root/InventoryManager")
	if not im:
		return
		
	var _p = get_tree().get_first_node_in_group("local_player")
	var pid = _p.player_id if _p and "player_id" in _p else ""
	var items = im.get_all_items(pid)
	for item_id in items.keys():
		var count = items[item_id]
		if count <= 0:
			continue
			
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 36)
		var icon_tex = AssetRegistry.get_item_icon(item_id)
		if icon_tex:
			btn.icon = icon_tex
			btn.expand_icon = true
		btn.text = _format_item_name(item_id) + " (x" + str(count) + ")"
		btn.pressed.connect(func(): _on_picker_item_selected(item_id))
		picker_grid.add_child(btn)

func _on_picker_item_selected(item_id: String) -> void:
	if active_slot_target == 1:
		slot_a_item = item_id
		active_slot_target = 2 # Automatically switch to slot B
	else:
		slot_b_item = item_id
		active_slot_target = 1
	_update_slot_buttons()

func _on_combine_pressed() -> void:
	if slot_a_item == "" or slot_b_item == "":
		_show_result("❌ Select two ingredients first.", Color(1.0, 0.4, 0.4))
		return
	
	# Use NetworkSynthesis (host-authoritative, works offline too)
	var ns = get_node_or_null("/root/NetworkSynthesis")
	if ns:
		var wl = get_node_or_null("/root/WorldLoader")
		var world_id = wl.current_world_id if wl else "farm"
		# Connect one-shot for result feedback
		if not ns.synthesis_completed.is_connected(_on_network_synthesis_completed):
			ns.synthesis_completed.connect(_on_network_synthesis_completed, CONNECT_ONE_SHOT)
		if not ns.synthesis_error.is_connected(_on_network_synthesis_error):
			ns.synthesis_error.connect(_on_network_synthesis_error, CONNECT_ONE_SHOT)
		ns.request_synthesis(world_id, slot_a_item, slot_b_item)
		return
	
	# Direct fallback (single-player, no NetworkSynthesis)
	var cm = get_node_or_null("/root/CombinationManager")
	var am = get_node_or_null("/root/AudioManager")
	if not cm: return
	var _p = get_tree().get_first_node_in_group("local_player")
	var pid = _p.player_id if _p and "player_id" in _p else ""
	var result = cm.perform_combination(pid, slot_a_item, slot_b_item)
	if not result.get("success", false):
		if am: am.play_sfx("ui_close")
		_show_result("❌ " + result.get("error", "Failed combination."), Color(1.0, 0.4, 0.4))
	else:
		var output_name = _format_item_name(result.get("output", ""))
		if result.get("is_new_discovery", false):
			if am: am.play_sfx("discovery")
			_show_result("✨ NEW DISCOVERY! ✨\n%s + %s ➔ %s" % [
				_format_item_name(slot_a_item),
				_format_item_name(slot_b_item),
				output_name
			], Color(1.0, 0.88, 0.2))
		else:
			if am: am.play_sfx("combine")
			_show_result("✅ Synthesized: %s" % output_name, Color(0.4, 1.0, 0.5))
	refresh_ui()

func _on_network_synthesis_completed(combo_id: String, output_item: String, is_new_discovery: bool) -> void:
	var am = get_node_or_null("/root/AudioManager")
	var output_name = _format_item_name(output_item)
	if is_new_discovery:
		if am: am.play_sfx("discovery")
		_show_result("✨ NEW DISCOVERY! ✨\n%s + %s ➔ %s" % [
			_format_item_name(slot_a_item),
			_format_item_name(slot_b_item),
			output_name
		], Color(1.0, 0.88, 0.2))
	else:
		if am: am.play_sfx("combine")
		_show_result("✅ Synthesized: %s" % output_name, Color(0.4, 1.0, 0.5))
	refresh_ui()

func _on_network_synthesis_error(reason: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_close")
	_show_result("❌ " + reason, Color(1.0, 0.4, 0.4))
	refresh_ui()



func _show_result(text: String, color: Color) -> void:
	if result_panel and result_label:
		result_panel.visible = true
		result_label.text = text
		result_label.modulate = color
		
		# Feedback pulse tween
		result_panel.scale = Vector2(0.9, 0.9)
		result_panel.modulate.a = 0.5
		var tween = create_tween().set_parallel(true)
		tween.tween_property(result_panel, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT)
		tween.tween_property(result_panel, "modulate:a", 1.0, 0.25)

func _on_combination_performed(_id: String, _output: String, _is_new: bool) -> void:
	refresh_ui()
