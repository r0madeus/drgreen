class_name ItemSlot
extends Button

## UI component representing an individual item slot in the inventory.

signal slot_clicked(item_id: String)

var item_id: String = ""
var quantity: int = 0
var is_selected: bool = false
var player_id: String = "player_001"

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var count_label: Label = $MarginContainer/VBoxContainer/CountLabel

func _ready() -> void:
	custom_minimum_size = Vector2(140, 50)
	pressed.connect(_on_pressed)

func set_item(p_item_id: String, p_count: int, p_selected: bool = false) -> void:
	item_id = p_item_id
	quantity = p_count
	is_selected = p_selected
	
	var display_name = item_id.replace("seed_", "🌱 ").replace("_", " ").capitalize()
	if not item_id.begins_with("seed_"):
		display_name = "🌸 " + display_name
		
	var icon_tex = AssetRegistry.get_item_icon(item_id)
	if icon_tex:
		icon = icon_tex
		expand_icon = true
		
	if name_label:
		name_label.text = display_name
	if count_label:
		count_label.text = "x" + str(quantity)
		
	if is_selected:
		modulate = Color(1.2, 1.2, 0.8) # Highlight selected slot
	else:
		modulate = Color(1.0, 1.0, 1.0)

func _on_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	var im = get_node_or_null("/root/InventoryManager")
	if im and item_id != "":
		im.select_item(player_id, item_id)
	slot_clicked.emit(item_id)
