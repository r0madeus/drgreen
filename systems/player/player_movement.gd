class_name PlayerMovement
extends Node

## Handles Stardew-style smooth continuous 2D movement, 8-directional input, acceleration, friction and collisions.

signal movement_started(target_grid_pos: Vector2i)
signal movement_completed(new_grid_pos: Vector2i)
signal direction_changed(new_dir: Vector2i)

@export var movement_speed: float = 85.0 # Pixels per second walking
@export var run_speed: float = 135.0      # Pixels per second running
@export var acceleration: float = 850.0   # Pixels/sec^2 acceleration
@export var friction: float = 1100.0      # Pixels/sec^2 deceleration / stop

var is_moving: bool = false
var facing_direction: Vector2i = Vector2i.DOWN

func get_direction_string(dir: Vector2i) -> String:
	match dir:
		Vector2i.UP: return "up"
		Vector2i.DOWN: return "down"
		Vector2i.LEFT: return "left"
		Vector2i.RIGHT: return "right"
		_: return "down"

func handle_movement(player: CharacterBody2D, delta: float, grid_manager: GridManager, current_grid_pos: Vector2i) -> Vector2i:
	var input_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Fallback for manual arrow keys / standard input if get_vector is 0
	if input_vec == Vector2.ZERO:
		var ix = 0.0
		var iy = 0.0
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): ix -= 1.0
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): ix += 1.0
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): iy -= 1.0
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): iy += 1.0
		input_vec = Vector2(ix, iy)
		
	# Normalize 8-directional input so diagonal isn't faster
	if input_vec.length_squared() > 0.0:
		input_vec = input_vec.normalized()
		
	var is_running = Input.is_action_pressed("run") or Input.is_key_pressed(KEY_SHIFT)
	var max_speed = run_speed if is_running else movement_speed
	
	# Apply responsive acceleration / deceleration
	if input_vec != Vector2.ZERO:
		var target_vel = input_vec * max_speed
		player.velocity = player.velocity.move_toward(target_vel, acceleration * delta)
		
		# Determine dominant facing direction (4-way sprite compatibility)
		var new_facing = facing_direction
		if abs(input_vec.x) > abs(input_vec.y):
			new_facing = Vector2i.RIGHT if input_vec.x > 0.0 else Vector2i.LEFT
		elif abs(input_vec.y) > 0.0:
			new_facing = Vector2i.DOWN if input_vec.y > 0.0 else Vector2i.UP
			
		if new_facing != facing_direction:
			facing_direction = new_facing
			direction_changed.emit(facing_direction)
	else:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, friction * delta)
		
	# Execute continuous physics movement
	player.move_and_slide()
	
	# Clamp position safely within world boundaries
	if grid_manager:
		var min_x = 6.0
		var min_y = 6.0
		var max_x = float(grid_manager.grid_width * 16 - 6)
		var max_y = float(grid_manager.grid_height * 16 - 6)
		player.position.x = clampf(player.position.x, min_x, max_x)
		player.position.y = clampf(player.position.y, min_y, max_y)
		
	# Update moving flag
	is_moving = player.velocity.length_squared() > 4.0
	
	# Calculate continuous grid position
	var new_grid_pos = current_grid_pos
	if grid_manager:
		new_grid_pos = grid_manager.world_to_grid(player.position)
	else:
		new_grid_pos = Vector2i(int(player.position.x / 16.0), int(player.position.y / 16.0))
		
	if new_grid_pos != current_grid_pos:
		movement_completed.emit(new_grid_pos)
		var bus = player.get_node_or_null("/root/EventBus")
		if bus: bus.player_moved.emit(new_grid_pos)
		
	return new_grid_pos

# Backward compatible signature for existing calls
func handle_input(player: Node2D, grid_manager: GridManager, current_grid_pos: Vector2i) -> Vector2i:
	if player is CharacterBody2D:
		return handle_movement(player, player.get_physics_process_delta_time(), grid_manager, current_grid_pos)
	return current_grid_pos

