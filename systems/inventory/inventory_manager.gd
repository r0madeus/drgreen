extends Node

## Facade / Adapter for player inventory operations, delegating true data ownership to PlayerState.

signal inventory_updated()
signal item_selected(item_id: String)

func _ready() -> void:
	pass

func _get_player_state(player_id: String) -> PlayerState:
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var psm = root.get_node_or_null("PlayerRegistry") if root else null
	if psm and psm.has_method("get_player_state"):
		return psm.get_player_state(player_id)
	return null

func add_item(player_id: String, item_id: String, quantity: int = 1, profile: GeneticProfile = null) -> void:
	var state = _get_player_state(player_id)
	if state: state.add_item(item_id, quantity, profile)

func remove_item(player_id: String, item_id: String, quantity: int = 1, profile: GeneticProfile = null) -> bool:
	var state = _get_player_state(player_id)
	return state.remove_item(item_id, quantity, profile) if state else false

func has_item(player_id: String, item_id: String, quantity: int = 1, profile: GeneticProfile = null) -> bool:
	var state = _get_player_state(player_id)
	return state.has_item(item_id, quantity, profile) if state else false

func get_item_count(player_id: String, item_id: String, profile: GeneticProfile = null) -> int:
	var state = _get_player_state(player_id)
	return state.get_item_count(item_id, profile) if state else 0

func get_all_items(player_id: String) -> Dictionary:
	var state = _get_player_state(player_id)
	return state.get_all_items() if state else {}

func select_item(player_id: String, item_id: String) -> void:
	var state = _get_player_state(player_id)
	if state: state.select_item(item_id)

func get_selected_item(player_id: String) -> String:
	var state = _get_player_state(player_id)
	return state.selected_item_id if state else ""

func get_item_keys(player_id: String) -> Array:
	return get_all_items(player_id).keys()

func get_hotbar_slots(player_id: String) -> Array:
	var state = _get_player_state(player_id)
	return state.hotbar_slots.duplicate() if state else []

func get_selected_hotbar_slot(player_id: String) -> int:
	var state = _get_player_state(player_id)
	return state.selected_hotbar_slot if state else 0

func set_hotbar_slot(player_id: String, slot_idx: int, item_id: String) -> void:
	var state = _get_player_state(player_id)
	if state: state.set_hotbar_slot(slot_idx, item_id)

func select_slot_index(player_id: String, idx: int) -> void:
	var state = _get_player_state(player_id)
	if state:
		state.select_hotbar_slot(idx)
	else:
		var keys = get_item_keys(player_id)
		if idx >= 0 and idx < keys.size():
			select_item(player_id, keys[idx])

func cycle_hotbar(player_id: String, direction: int) -> void:
	var state = _get_player_state(player_id)
	if state:
		state.cycle_hotbar_slot(direction)
	else:
		var keys = get_item_keys(player_id)
		if keys.is_empty(): return
		var cur = get_selected_item(player_id)
		var cur_idx = keys.find(cur)
		if cur_idx == -1: cur_idx = 0
		var next_idx = (cur_idx + direction) % keys.size()
		if next_idx < 0: next_idx += keys.size()
		select_item(player_id, keys[next_idx])



