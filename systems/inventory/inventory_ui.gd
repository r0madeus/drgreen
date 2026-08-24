class_name InventoryUI
extends Control

## UI panel displaying player inventory items and active selection.

@onready var grid_container: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var selected_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/SelectedLabel

func _ready() -> void:
	visible = false
	var im = get_node_or_null("/root/InventoryManager")
	if im:
		im.inventory_updated.connect(refresh_ui)
		im.item_selected.connect(_on_item_selected)
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(func(_l): refresh_ui())
	refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_visibility()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and visible:
			visible = false
			var am = get_node_or_null("/root/AudioManager")
			if am: am.play_sfx("ui_close")
			get_viewport().set_input_as_handled()

func toggle_visibility() -> void:
	visible = not visible
	var am = get_node_or_null("/root/AudioManager")
	if visible:
		if am: am.play_sfx("ui_open")
		var lab = get_tree().root.find_child("CombinationUI", true, false)
		if lab and lab.visible: lab.visible = false
		var jrn = get_tree().root.find_child("JournalUI", true, false)
		if jrn and jrn.visible: jrn.visible = false
		var shop = get_tree().root.find_child("ShopUI", true, false)
		if shop and shop.visible: shop.close_shop()
		refresh_ui()
	else:
		if am: am.play_sfx("ui_close")

func refresh_ui() -> void:
	if not grid_container:
		return
		
	# Clear old children
	for child in grid_container.get_children():
		child.queue_free()
		
	var im = get_node_or_null("/root/InventoryManager")
	if not im:
		return
		
	var all_items = im.get_all_items()
	var selected = im.get_selected_item()
	var lm = get_node_or_null("/root/LocalizationManager")
	
	if selected_label:
		if selected != "":
			var sel_name = ItemRegistry.get_localized_name(selected)
			var sel_cnt = im.get_item_count(selected)
			if lm:
				selected_label.text = lm.format("ui.hud.selected_format", { "item": sel_name, "count": sel_cnt })
			else:
				selected_label.text = "Selected: %s (%d)" % [sel_name, sel_cnt]
		else:
			selected_label.text = tr("ui.hud.selected_none")
			
	for item_id in all_items.keys():
		var count = all_items[item_id]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(150, 40)
		var is_sel = (item_id == selected)
		var icon = ItemRegistry.get_icon(item_id)
		var dname = ItemRegistry.get_localized_name(item_id)
		btn.text = "%s %s (x%d)" % [icon, dname, count]
		if is_sel:
			btn.modulate = Color(0.8, 1.2, 0.8)
		btn.pressed.connect(func():
			im.select_item(item_id)
			refresh_ui()
		)
		grid_container.add_child(btn)


func _on_item_selected(_item_id: String) -> void:
	refresh_ui()
