class_name SaveSelectUI
extends Control

## Save Slot Selection & Management Modal with Dynamic Slot Expansion & Clean Delegation.

signal slot_loaded(slot_index: int)
signal slot_new_game_started(slot_index: int)
signal back_pressed()

@onready var slots_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SlotsContainer
@onready var back_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/BackButton
@onready var confirm_dialog: ConfirmationDialog = $DeleteConfirmDialog

var slot_to_delete: int = -1

func _ready() -> void:
	visible = false
	theme = UIConstants.get_theme()
	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if confirm_dialog:
		confirm_dialog.confirmed.connect(_on_delete_confirmed)
		confirm_dialog.canceled.connect(func(): slot_to_delete = -1)
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(func(_l): 
			if back_btn: back_btn.text = tr("ui.menu.back")
			if visible: refresh_slots()
		)
	if back_btn: back_btn.text = tr("ui.menu.back")

func open_ui() -> void:
	visible = true
	if back_btn: back_btn.text = tr("ui.menu.back")
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_open")
	refresh_slots()

func close_ui() -> void:
	visible = false
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_close")

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_back_pressed()
			get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	close_ui()
	back_pressed.emit()

func refresh_slots() -> void:
	if not slots_container: return
	for c in slots_container.get_children():
		c.queue_free()
		
	var sm = get_node_or_null("/root/SaveManager")
	if not sm: return
	
	var metadata_list = sm.get_all_slots_metadata()
	
	for meta in metadata_list:
		var slot_idx = int(meta.get("slot_index", 1))
		var exists = bool(meta.get("exists", false))
		var corrupted = bool(meta.get("corrupted", false))
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(460, 85)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		margin.add_child(hbox)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 4)
		hbox.add_child(vbox)
		
		# Slot Header HBox
		var header_hbox = HBoxContainer.new()
		var title_lbl = Label.new()
		var time_lbl = Label.new()
		
		if exists and not corrupted:
			title_lbl.text = "🌱 SAVE SLOT %d" % slot_idx
			title_lbl.modulate = Color(1.0, 0.9, 0.3)
			time_lbl.text = "🕒 " + str(meta.get("last_played_str", ""))
			time_lbl.modulate = Color(0.7, 0.7, 0.7)
		elif corrupted:
			title_lbl.text = "⚠️ CORRUPTED SLOT %d" % slot_idx
			title_lbl.modulate = Color(1.0, 0.4, 0.4)
			time_lbl.text = "Corrupted data"
			time_lbl.modulate = Color(0.8, 0.4, 0.4)
		else:
			title_lbl.text = "📁 EMPTY SLOT %d" % slot_idx
			title_lbl.modulate = Color(0.7, 0.7, 0.7)
			time_lbl.text = "No save data"
			time_lbl.modulate = Color(0.5, 0.5, 0.5)
			
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header_hbox.add_child(title_lbl)
		header_hbox.add_child(time_lbl)
		vbox.add_child(header_hbox)
		
		# Slot Body
		var body_lbl = Label.new()
		if exists and not corrupted:
			body_lbl.text = "%s • 💰 %d Gold • 📜 %d Quests • 🧪 %d Hybrids" % [
				str(meta.get("summary", "")),
				int(meta.get("gold", 0)),
				int(meta.get("quests_completed", 0)),
				int(meta.get("discoveries_count", 0))
			]
			body_lbl.modulate = Color(0.85, 0.95, 0.85)
		elif corrupted:
			body_lbl.text = "Error: " + str(meta.get("error", "Unable to read save file."))
			body_lbl.modulate = Color(0.9, 0.6, 0.6)
		else:
			body_lbl.text = "Empty slot. Click 'New Game' to begin here."
			body_lbl.modulate = Color(0.6, 0.6, 0.6)
			
		body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(body_lbl)
		
		# Action Buttons HBox
		var btn_hbox = HBoxContainer.new()
		btn_hbox.alignment = BoxContainer.ALIGNMENT_END
		btn_hbox.add_theme_constant_override("separation", 8)
		hbox.add_child(btn_hbox)
		
		if exists and not corrupted:
			var load_btn = Button.new()
			load_btn.text = "▶ Load"
			load_btn.custom_minimum_size = Vector2(80, 32)
			load_btn.modulate = Color(1.2, 1.2, 0.7)
			load_btn.pressed.connect(func(): _on_load_slot_pressed(slot_idx))
			btn_hbox.add_child(load_btn)
			
			var del_btn = Button.new()
			del_btn.text = "🗑"
			del_btn.custom_minimum_size = Vector2(36, 32)
			del_btn.modulate = Color(1.0, 0.5, 0.5)
			del_btn.pressed.connect(func(): _on_request_delete(slot_idx))
			btn_hbox.add_child(del_btn)
		elif corrupted:
			var del_btn = Button.new()
			del_btn.text = "🗑 Reset"
			del_btn.custom_minimum_size = Vector2(80, 32)
			del_btn.modulate = Color(1.0, 0.4, 0.4)
			del_btn.pressed.connect(func(): _on_request_delete(slot_idx))
			btn_hbox.add_child(del_btn)
		else:
			var new_btn = Button.new()
			new_btn.text = "🌱 New"
			new_btn.custom_minimum_size = Vector2(80, 32)
			new_btn.pressed.connect(func(): _on_new_slot_pressed(slot_idx))
			btn_hbox.add_child(new_btn)
			
		slots_container.add_child(card)

func _on_load_slot_pressed(slot_idx: int) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_slot_save(slot_idx):
		sm.set_active_slot_index(slot_idx)
		close_ui()
		slot_loaded.emit(slot_idx)

func _on_new_slot_pressed(slot_idx: int) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		if sm.has_slot_save(slot_idx):
			# Slot is occupied, prevent accidental overwrite without delete
			return
		sm.set_active_slot_index(slot_idx)
		
	close_ui()
	slot_new_game_started.emit(slot_idx)

func _on_request_delete(slot_idx: int) -> void:
	slot_to_delete = slot_idx
	if confirm_dialog:
		confirm_dialog.dialog_text = "Are you sure you want to delete Save Slot %d?\nAll progress will be permanently lost." % slot_idx
		confirm_dialog.popup_centered()
	else:
		_on_delete_confirmed()

func _on_delete_confirmed() -> void:
	if slot_to_delete > 0:
		var sm = get_node_or_null("/root/SaveManager")
		if sm:
			sm.delete_slot(slot_to_delete)
		slot_to_delete = -1
		refresh_slots()
