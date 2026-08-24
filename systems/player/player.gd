class_name Player
extends CharacterBody2D

## Main Player Controller coordinating Movement, Mouse Targeting, Tools, World Transitions and Camera.

@export var grid_manager: GridManager
@export var initial_grid_position: Vector2i = Vector2i(16, 12)

var movement: PlayerMovement = null
var interaction: PlayerInteraction = null
var animation_handler: PlayerAnimation = null
var camera: Camera2D = null

var tile_highlight: TileHighlight
var grid_position: Vector2i = Vector2i(16, 12)
var facing_direction: Vector2i = Vector2i.DOWN
var is_movement_locked: bool = false
var mouse_grid_position: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	movement = get_node_or_null("Movement") as PlayerMovement
	interaction = get_node_or_null("Interaction") as PlayerInteraction
	animation_handler = get_node_or_null("Animation") as PlayerAnimation
	camera = get_node_or_null("Camera2D") as Camera2D
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		add_child(camera)
	grid_position = initial_grid_position
	
	if not grid_manager and get_parent():
		grid_manager = get_parent().get_node_or_null("GridManager") as GridManager
		
	if grid_manager:
		position = grid_manager.grid_to_world(grid_position, true)
	else:
		position = Vector2(grid_position.x * 16 + 8, grid_position.y * 16 + 8)
		
	# Setup Tile Highlight overlay
	tile_highlight = TileHighlight.new()
	if grid_manager:
		grid_manager.add_child(tile_highlight)
	else:
		add_sibling(tile_highlight)
		
	if movement:
		if not movement.movement_started.is_connected(_on_movement_started):
			movement.movement_started.connect(_on_movement_started)
		# Grid-cell changes are observed in _physics_process; they are not movement completion.
		if not movement.direction_changed.is_connected(_on_direction_changed):
			movement.direction_changed.connect(_on_direction_changed)
	if interaction:
		if not interaction.interaction_triggered.is_connected(_on_interaction_triggered):
			interaction.interaction_triggered.connect(_on_interaction_triggered)

func set_movement_locked(locked: bool) -> void:
	is_movement_locked = locked
	if locked:
		if animation_handler and is_instance_valid(animation_handler):
			animation_handler.set_state("idle")
		if tile_highlight and is_instance_valid(tile_highlight):
			tile_highlight.visible = false
	else:
		if tile_highlight and is_instance_valid(tile_highlight):
			tile_highlight.visible = true

func _physics_process(delta: float) -> void:
	if is_movement_locked:
		velocity = Vector2.ZERO
		if animation_handler: animation_handler.set_state("idle")
		if tile_highlight: tile_highlight.visible = false
		return
		
	if not grid_manager and get_parent():
		grid_manager = get_parent().get_node_or_null("GridManager") as GridManager
		
	var previous_grid_position = grid_position
	if movement:
		grid_position = movement.handle_movement(self, delta, grid_manager, grid_position)
		if animation_handler:
			animation_handler.set_state("walk" if velocity.length_squared() > 4.0 else "idle")
			animation_handler.set_direction(facing_direction)

	# The grid is derived for interactions and transitions; it never drives position.
	if grid_position != previous_grid_position:
		_on_grid_position_changed(grid_position)
	_persist_continuous_position()

	interaction.handle_input(grid_position, facing_direction)
	_update_mouse_targeting()


func _update_mouse_targeting() -> void:
	if not grid_manager or not tile_highlight: return
	
	if interaction.is_mouse_over_ui():
		tile_highlight.visible = false
		return
		
	var mouse_world = get_global_mouse_position()
	mouse_grid_position = grid_manager.world_to_grid(mouse_world)
	
	var in_range = interaction.is_world_position_in_range(global_position, mouse_grid_position, grid_manager)
	var tile = grid_manager.get_tile(mouse_grid_position)
	
	if not tile:
		tile_highlight.visible = false
		return
		
	tile_highlight.visible = true
	var mode = "default"
	var tooltip = ""
	var valid = in_range
	
	var im = get_node_or_null("/root/InventoryManager")
	var selected = im.get_selected_item() if im else ""
	var use_act = ItemRegistry.get_use_action(selected)
	
	# Detect entity / tile state
	var wl = get_node_or_null("/root/WorldLoader")
	var tr = wl.check_transition_trigger(mouse_grid_position) if wl else {}
	
	if not tr.is_empty():
		mode = "exit"
		tooltip = "Exit: " + str(tr.get("name", tr.get("target_world", "")))
	elif mouse_grid_position == Vector2i(15, 3) and (wl.current_world_id if wl else "farm") == "farm":
		mode = "interact"
		tooltip = "Talk to Rowan"
	elif grid_manager.is_tile_harvestable(mouse_grid_position):
		mode = "harvest"
		tooltip = "Harvest Crop"
	elif use_act == ItemRegistry.UseAction.HOE:
		if grid_manager.can_till_here(mouse_grid_position):
			mode = "hoe"
			tooltip = "Till Soil"
		else:
			mode = "invalid"
			valid = false
			tooltip = "Cannot Till Here"
	elif use_act == ItemRegistry.UseAction.WATER:
		if (tile.type == "soil" and not tile.watered_today):
			mode = "water"
			tooltip = "Water Tile"
		else:
			mode = "invalid"
			valid = false
			tooltip = "Cannot Water Here"
	elif use_act == ItemRegistry.UseAction.PLANT:
		if grid_manager.can_plant_here(mouse_grid_position):
			mode = "plant"
			var dname = ItemRegistry.get_display_name(selected)
			tooltip = "Plant " + dname
		else:
			mode = "invalid"
			valid = false
			tooltip = "Cannot Plant Here"
	elif use_act == ItemRegistry.UseAction.AXE:
		if grid_manager.can_chop_here(mouse_grid_position):
			mode = "axe"
			tooltip = "Chop Tree"
		else:
			mode = "invalid"
			valid = false
			tooltip = "Cannot Chop Here"
	elif use_act == ItemRegistry.UseAction.PICKAXE:
		if grid_manager.can_mine_here(mouse_grid_position):
			mode = "pickaxe"
			tooltip = "Mine Stone"
		else:
			mode = "invalid"
			valid = false
			tooltip = "Cannot Mine Here"
	else:
		mode = "default"
		tooltip = "Inspect Tile"
		
	tile_highlight.update_target(mouse_grid_position, in_range, valid, mode, tooltip)

func _unhandled_input(event: InputEvent) -> void:
	if is_movement_locked or interaction.is_mouse_over_ui():
		return
		
	# 1. Hotbar Mouse Wheel (10 Slots)
	if event.is_action_pressed("hotbar_next") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var im = get_node_or_null("/root/InventoryManager")
		if im: im.cycle_hotbar(1)
		get_viewport().set_input_as_handled()
		return
	elif event.is_action_pressed("hotbar_prev") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP):
		var im = get_node_or_null("/root/InventoryManager")
		if im: im.cycle_hotbar(-1)
		get_viewport().set_input_as_handled()
		return
		
	# 2. Number Keys 1..0 for 10-Slot Hotbar Selection
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var slot_idx = event.keycode - KEY_1
			var im = get_node_or_null("/root/InventoryManager")
			if im: im.select_slot_index(slot_idx)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_0:
			var im = get_node_or_null("/root/InventoryManager")
			if im: im.select_slot_index(9) # 10th Slot (Index 9)
			get_viewport().set_input_as_handled()
			return
			
	# 3. Left Mouse Button (Use Selected Item / Tool)
	if event.is_action_pressed("use_tool") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if not grid_manager: return
		var mouse_grid = grid_manager.world_to_grid(get_global_mouse_position())
		if interaction.is_world_position_in_range(global_position, mouse_grid, grid_manager):
			_face_towards(mouse_grid)
			use_tool_at(mouse_grid)
			get_viewport().set_input_as_handled()
		return
		
	# 4. Right Mouse Button (Generic Interaction ONLY: NPC, Shop, Chest, World Exit, Dialogue)
	if event.is_action_pressed("interact") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
		if not grid_manager: return
		var mouse_grid = grid_manager.world_to_grid(get_global_mouse_position())
		if interaction.is_world_position_in_range(global_position, mouse_grid, grid_manager):
			_face_towards(mouse_grid)
			_on_interaction_triggered(mouse_grid)
			get_viewport().set_input_as_handled()
		return

func _face_towards(target_grid: Vector2i) -> void:
	var diff = target_grid - grid_position
	if abs(diff.x) >= abs(diff.y):
		if diff.x > 0: facing_direction = Vector2i.RIGHT
		elif diff.x < 0: facing_direction = Vector2i.LEFT
	else:
		if diff.y > 0: facing_direction = Vector2i.DOWN
		elif diff.y < 0: facing_direction = Vector2i.UP
	if animation_handler:
		animation_handler.set_direction(facing_direction)

func use_tool_at(target_pos: Vector2i) -> bool:
	if not grid_manager: return false
	var im = get_node_or_null("/root/InventoryManager")
	var selected = im.get_selected_item() if im else ""
	return ToolUseManager.use_selected_item(self, target_pos, selected)

func _on_movement_started(_target_pos: Vector2i) -> void:
	animation_handler.set_state("walk")

func _persist_continuous_position() -> void:
	var psm = get_node_or_null("/root/PlayerStateManager")
	if psm:
		var state = psm.get_active_player_state()
		if state:
			state.position = global_position
			state.facing_direction = facing_direction

func _on_grid_position_changed(new_pos: Vector2i) -> void:
	grid_position = new_pos
	# World transitions are grid triggers, but they must not snap normal movement.
	var wm = get_node_or_null("/root/WorldManager")
	var wl = get_node_or_null("/root/WorldLoader")
	if wm and wl:
		var tr = wl.check_transition_trigger(new_pos)
		if not tr.is_empty():
			var target_world = str(tr.get("target_world", ""))
			var target_spawn = tr.get("target_spawn", "default")
			if target_world != "":
				wm.transition_to(target_world, target_spawn)
	elif wl:
		var tr = wl.check_transition_trigger(new_pos)
		if not tr.is_empty():
			var target_world = str(tr.get("target_world", ""))
			var target_spawn = tr.get("target_spawn", null)
			if target_world != "":
				wl.change_world(target_world, target_spawn)

func _on_direction_changed(new_dir: Vector2i) -> void:
	facing_direction = new_dir
	animation_handler.set_direction(new_dir)

func _on_interaction_triggered(target_pos: Vector2i) -> void:
	if not grid_manager and get_parent():
		grid_manager = get_parent().get_node_or_null("GridManager") as GridManager
	if not grid_manager: return
		
	var tile = grid_manager.get_tile(target_pos)
	if not tile: return
	
	# 1. World Exit Transition
	var wl = get_node_or_null("/root/WorldLoader")
	var wm = get_node_or_null("/root/WorldManager")
	if wl:
		var tr = wl.check_transition_trigger(target_pos)
		if tr.is_empty(): tr = wl.check_transition_trigger(grid_position)
		if not tr.is_empty():
			var target_world = str(tr.get("target_world", ""))
			var target_spawn = tr.get("target_spawn", "default")
			if target_world != "":
				if wm: wm.transition_to(target_world, target_spawn)
				else: wl.change_world(target_world, target_spawn)
				return
				
	# 2. NPC / Dialogue / Shop Interaction
	var cur_w = wl.current_world_id if wl else "farm"
	if target_pos == Vector2i(15, 3) and cur_w == "farm":
		var merchant = get_tree().root.find_child("SeedMerchant", true, false)
		if merchant and merchant.has_method("interact"):
			merchant.interact()
			return
			
	# 3. Chest / Container / Object Interaction
	var nc = get_node_or_null("/root/NetworkContainers")
	if nc and nc.has_container(cur_w, target_pos):
		nc.open_container(cur_w, target_pos)
		return
		
	# 4. Bed / Sleep Object Interaction
	if tile.interactable and (tile.type == "bed" or str(tile.meta.get("object_type", "")).to_lower() == "bed"):
		var tm = get_node_or_null("/root/TimeManager")
		if tm: tm.request_sleep()
		return



	
func get_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"grid_position": [grid_position.x, grid_position.y],
		"velocity": [velocity.x, velocity.y],
		"direction": movement.get_direction_string(facing_direction),
		"is_moving": movement.is_moving
	}
