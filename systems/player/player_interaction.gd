class_name PlayerInteraction
extends Node

## Resolves grid gameplay targets from a continuous player world position.

signal interaction_triggered(target_grid_pos: Vector2i)
signal tool_used(target_grid_pos: Vector2i, action_type: String)

const MAX_INTERACTION_DISTANCE: int = 2

func get_facing_tile(current_grid_pos: Vector2i, facing_dir: Vector2i) -> Vector2i:
	return current_grid_pos + facing_dir

func get_mouse_grid_position(player: Node2D, grid_manager: GridManager) -> Vector2i:
	if not player or not grid_manager:
		return Vector2i(-1, -1)
	return grid_manager.world_to_grid(player.get_global_mouse_position())

func is_in_range(player_grid_pos: Vector2i, target_grid_pos: Vector2i, range_dist: int = MAX_INTERACTION_DISTANCE) -> bool:
	var max_dist = maxi(MAX_INTERACTION_DISTANCE, range_dist)
	return abs(target_grid_pos.x - player_grid_pos.x) <= max_dist and abs(target_grid_pos.y - player_grid_pos.y) <= max_dist

func is_world_position_in_range(player_world_pos: Vector2, target_grid_pos: Vector2i, grid_manager: GridManager, range_dist: int = MAX_INTERACTION_DISTANCE) -> bool:
	if not grid_manager:
		return false
	var max_tiles = maxi(MAX_INTERACTION_DISTANCE, range_dist)
	var target_world_pos = grid_manager.grid_to_world(target_grid_pos, true)
	# Preserve the former square-grid reach, including a corner tile at max range.
	var max_distance = float(max_tiles * grid_manager.tile_size) * sqrt(2.0)
	return player_world_pos.distance_to(target_world_pos) <= max_distance

func is_mouse_over_ui() -> bool:
	var root = get_tree().root
	var wb = root.find_child("WorldBuilder", true, false)
	if wb and wb.visible:
		return true
	var modal_names = ["ShopUI", "CombinationUI", "DialogueUI", "QuestUI", "SettingsUI", "PauseMenu", "SaveSelectUI", "InventoryUI", "MainMenu", "SleepConfirmationUI"]

	for m_name in modal_names:
		var node = root.find_child(m_name, true, false)
		if node and node.visible:
			return true
	var viewport = root.get_viewport()
	if viewport:
		var mpos = viewport.get_mouse_position()
		for ui_name in ["HotbarUI", "TopLeftCard", "TopRightCard"]:
			var control = root.find_child(ui_name, true, false) as Control
			if control and control.is_visible_in_tree() and control.get_global_rect().has_point(mpos):
				return true
	return false

func handle_input(current_grid_pos: Vector2i, facing_dir: Vector2i) -> void:
	if Input.is_action_just_pressed("interact") and not is_mouse_over_ui():
		var target_pos = get_facing_tile(current_grid_pos, facing_dir)
		interaction_triggered.emit(target_pos)
		var bus = get_node_or_null("/root/EventBus")
		if bus:
			bus.player_interacted.emit(target_pos)
