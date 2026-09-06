class_name InventoryUI
extends Control

## UI panel displaying player inventory items and active selection.

@onready var grid_container: GridContainer = find_child("GridContainer", true, false)
@onready var selected_label: Label = find_child("SelectedLabel", true, false)
@onready var close_button: Button = find_child("CloseButton", true, false)

func _ready() -> void:
	visible = false
	theme = UIConstants.get_theme()
	if close_button:
		close_button.pressed.connect(close_inventory)
	var im = get_node_or_null("/root/InventoryManager")
	var eb = get_node_or_null("/root/EventBus")
	if im and eb:
		eb.world_changed.connect(_bind_local_player)
		
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
			close_inventory()
			get_viewport().set_input_as_handled()

func open_inventory() -> void:
	UIConstants.close_all_modals(get_tree(), self)
	visible = true
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_open")
	UIConstants.update_player_lock(get_tree())
	refresh_ui()

func close_inventory() -> void:
	visible = false
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_close")
	UIConstants.update_player_lock(get_tree())

func toggle_visibility() -> void:
	if visible:
		close_inventory()
	else:
		open_inventory()

func refresh_ui() -> void:
	var tree = get_tree()
	var _p = tree.get_first_node_in_group("local_player") if tree else null
	var player_id = _p.player_id if _p and "player_id" in _p else ""
	if not grid_container:
		return
		
	# Clear old children
	for child in grid_container.get_children():
		child.queue_free()
		
	var im = get_node_or_null("/root/InventoryManager")
	if not im:
		return
		
	var all_items = im.get_all_items(player_id)
	var selected = im.get_selected_item(player_id)
	var lm = get_node_or_null("/root/LocalizationManager")
	
	if selected_label:
		if selected != "":
			var sel_name = ItemRegistry.get_localized_name(PlayerState.get_base_item_id(selected))
			var sel_cnt = im.get_item_count(player_id, selected)
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
		var icon = ItemRegistry.get_icon(PlayerState.get_base_item_id(item_id))
		var dname = ItemRegistry.get_localized_name(PlayerState.get_base_item_id(item_id))
		btn.text = "%s %s (x%d)" % [icon, dname, count]
		if is_sel:
			btn.modulate = Color(0.8, 1.2, 0.8)
		btn.pressed.connect(func():
			im.select_item(player_id, item_id)
			refresh_ui()
		)
		grid_container.add_child(btn)


func _on_item_selected(_item_id: String) -> void:
	refresh_ui()

func _bind_local_player(world_id: String, _world_data: Dictionary = {}) -> void:
	var player = get_tree().get_first_node_in_group("local_player")
	if player and player.player_state:
		if not player.player_state.inventory_changed.is_connected(refresh_ui):
			player.player_state.inventory_changed.connect(refresh_ui)
		if not player.player_state.item_selected.is_connected(_on_item_selected):
			player.player_state.item_selected.connect(_on_item_selected)
	refresh_ui()
