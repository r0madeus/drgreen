class_name DialogueUI
extends Control

## Cozy Botanical Fantasy Dialogue modal supporting animated portrait and choice actions.

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var portrait_rect: TextureRect = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/PortraitRect
@onready var speaker_label: Label = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/TextVBox/SpeakerLabel
@onready var content_label: Label = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/TextVBox/ContentLabel
@onready var action_hbox: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/TextVBox/ActionHBox
@onready var next_button: Button = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/TextVBox/ActionHBox/NextButton
@onready var shop_button: Button = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/TextVBox/ActionHBox/ShopButton
@onready var close_button: Button = $CenterContainer/PanelContainer/MarginContainer/HBoxContainer/TextVBox/ActionHBox/CloseButton

var current_npc_id: String = ""

func _ready() -> void:
	visible = false
	if next_button: next_button.pressed.connect(_on_next_pressed)
	if shop_button: shop_button.pressed.connect(_on_shop_pressed)
	if close_button: close_button.pressed.connect(close_dialogue)
	
	var dm = get_node_or_null("/root/DialogueManager")
	if dm and "dialogue_started" in dm:
		dm.dialogue_started.connect(_on_dialogue_started)
		dm.line_changed.connect(_on_line_changed)
		dm.dialogue_ended.connect(func(_id): close_dialogue())

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_dialogue()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_E:
			if next_button and next_button.visible:
				_on_next_pressed()
				get_viewport().set_input_as_handled()

func _on_dialogue_started(npc_id: String, npc_name: String, _lines: Array, portrait: Texture2D) -> void:
	current_npc_id = npc_id
	visible = true
	
	# Exclusivity: close other modals
	var inv = get_tree().root.find_child("InventoryUI", true, false)
	if inv and inv.visible: inv.visible = false
	var lab = get_tree().root.find_child("CombinationUI", true, false)
	if lab and lab.visible: lab.visible = false
	var jrn = get_tree().root.find_child("JournalUI", true, false)
	if jrn and jrn.visible: jrn.visible = false
	var shop = get_tree().root.find_child("ShopUI", true, false)
	if shop and shop.visible: shop.close_shop()
	var quest = get_tree().root.find_child("QuestUI", true, false)
	if quest and quest.visible: quest.visible = false
	
	# Lock player movement
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(true)
		
	if speaker_label: speaker_label.text = "💬 " + npc_name
	if portrait_rect and portrait:
		portrait_rect.texture = portrait
		
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("dialogue_open")

func _on_line_changed(text_line: String, line_index: int, total_lines: int) -> void:
	if content_label:
		content_label.text = text_line
		
	var is_last_line = (line_index >= total_lines - 1)
	if next_button: next_button.visible = not is_last_line
	if shop_button: shop_button.visible = is_last_line
	if close_button: close_button.visible = is_last_line

func _on_next_pressed() -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.advance_dialogue()

func _on_shop_pressed() -> void:
	close_dialogue()
	var shop = get_tree().root.find_child("ShopUI", true, false)
	if shop:
		shop.open_shop()

func close_dialogue() -> void:
	if not visible:
		return
	visible = false
	
	var dm = get_node_or_null("/root/DialogueManager")
	if dm and dm.is_dialogue_active:
		dm.is_dialogue_active = false
		
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
