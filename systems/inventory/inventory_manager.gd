extends Node

## Facade / Adapter for player inventory operations, delegating true data ownership to PlayerState.

signal inventory_updated()
signal item_selected(item_id: String)

var items: Dictionary:
	get:
		var state = _get_active_state()
		return state.inventory if state else {}
	set(val):
		var state = _get_active_state()
		if state: state.inventory = val

var selected_item_id: String:
	get:
		var state = _get_active_state()
		return state.selected_item_id if state else ""
	set(val):
		var state = _get_active_state()
		if state: state.selected_item_id = val

func _ready() -> void:
	var psm = get_node_or_null("/root/PlayerStateManager")
	if psm and "active_player_changed" in psm:
		psm.active_player_changed.connect(_on_active_player_changed)
	_bind_active_state_signals()

func _get_active_state() -> PlayerState:
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var psm = root.get_node_or_null("PlayerStateManager") if root else null
	if psm and psm.has_method("get_active_player_state"):
		return psm.get_active_player_state()
	return null

func _on_active_player_changed(_pid: String) -> void:
	_bind_active_state_signals()
	inventory_updated.emit()
	item_selected.emit(selected_item_id)

func _bind_active_state_signals() -> void:
	var state = _get_active_state()
	if state:
		if not state.inventory_changed.is_connected(_on_state_inventory_changed):
			state.inventory_changed.connect(_on_state_inventory_changed)
		if not state.item_selected.is_connected(_on_state_item_selected):
			state.item_selected.connect(_on_state_item_selected)

func _on_state_inventory_changed() -> void:
	inventory_updated.emit()
	var bus = get_node_or_null("/root/EventBus")
	if bus: bus.inventory_changed.emit()

func _on_state_item_selected(item_id: String) -> void:
	item_selected.emit(item_id)

func add_item(item_id: String, quantity: int = 1) -> void:
	var state = _get_active_state()
	if state: state.add_item(item_id, quantity)

func remove_item(item_id: String, quantity: int = 1) -> bool:
	var state = _get_active_state()
	return state.remove_item(item_id, quantity) if state else false

func has_item(item_id: String, quantity: int = 1) -> bool:
	var state = _get_active_state()
	return state.has_item(item_id, quantity) if state else false

func get_item_count(item_id: String) -> int:
	var state = _get_active_state()
	return state.get_item_count(item_id) if state else 0

func get_all_items() -> Dictionary:
	var state = _get_active_state()
	return state.get_all_items() if state else {}

func select_item(item_id: String) -> void:
	var state = _get_active_state()
	if state: state.select_item(item_id)

func get_selected_item() -> String:
	return selected_item_id

func get_item_keys() -> Array:
	return get_all_items().keys()

func get_hotbar_slots() -> Array:

	var state = _get_active_state()
	return state.hotbar_slots.duplicate() if state else []

func get_selected_hotbar_slot() -> int:
	var state = _get_active_state()
	return state.selected_hotbar_slot if state else 0

func set_hotbar_slot(slot_idx: int, item_id: String) -> void:
	var state = _get_active_state()
	if state: state.set_hotbar_slot(slot_idx, item_id)

func select_slot_index(idx: int) -> void:
	var state = _get_active_state()
	if state:
		state.select_hotbar_slot(idx)
	else:
		var keys = get_item_keys()
		if idx >= 0 and idx < keys.size():
			select_item(keys[idx])

func cycle_hotbar(direction: int) -> void:
	var state = _get_active_state()
	if state:
		state.cycle_hotbar_slot(direction)
	else:
		var keys = get_item_keys()
		if keys.is_empty(): return
		var cur = get_selected_item()
		var cur_idx = keys.find(cur)
		if cur_idx == -1: cur_idx = 0
		var next_idx = (cur_idx + direction) % keys.size()
		if next_idx < 0: next_idx += keys.size()
		select_item(keys[next_idx])



