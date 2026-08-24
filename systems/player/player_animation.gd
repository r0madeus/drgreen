class_name PlayerAnimation
extends Node2D

## Handles visual representation, 4-direction facing and animation states.

@export var visual_body: CanvasItem
@export var facing_indicator: Node2D

var current_state: String = "idle" # "idle", "walk"
var current_direction: Vector2i = Vector2i.DOWN
var walk_frame_index: int = 0
var walk_timer: float = 0.0

func _ready() -> void:
	update_visuals()

func _process(delta: float) -> void:
	if current_state == "walk":
		walk_timer += delta
		if walk_timer >= 0.12:
			walk_timer = 0.0
			walk_frame_index = (walk_frame_index + 1) % 3
			queue_redraw()
	else:
		if walk_frame_index != 0:
			walk_frame_index = 0
			walk_timer = 0.0
			queue_redraw()

func set_direction(new_dir: Vector2i) -> void:
	current_direction = new_dir
	update_visuals()

func set_state(state: String) -> void:
	current_state = state
	if current_state == "idle":
		walk_frame_index = 0
		walk_timer = 0.0
	update_visuals()

func update_visuals() -> void:
	if facing_indicator:
		# Position the indicator dot 5 pixels in front of the center
		facing_indicator.position = Vector2(current_direction.x * 5, current_direction.y * 5)
	queue_redraw()

func _draw() -> void:
	var bob = -1.0 if (current_state == "walk" and walk_frame_index != 0) else 0.0
	var frame = walk_frame_index if current_state == "walk" else 0
	
	# 1. Check for PNG sprite asset via AssetRegistry
	var sprite_tex = AssetRegistry.get_player_texture(current_direction, frame)
	if sprite_tex:
		draw_texture(sprite_tex, Vector2(-8, -8 + bob))
		return
		
	# 2. Fallback: Draw charming procedural pixel-art character
	if visual_body == null:
		
		# 1. Soft foot shadow
		draw_circle(Vector2(0, 6), 5.5, Color(0, 0, 0, 0.28))
		
		# 2. Legs / Shoes
		draw_rect(Rect2(-4, 3 + bob, 3, 4), Color(0.18, 0.20, 0.28)) # Left leg
		draw_rect(Rect2(1, 3 + bob, 3, 4), Color(0.18, 0.20, 0.28))  # Right leg
		
		# 3. Torso / Lab Field Jacket
		draw_rect(Rect2(-5, -2 + bob, 10, 6), Color(0.22, 0.48, 0.35)) # Green field jacket
		draw_rect(Rect2(-2, -2 + bob, 4, 5), Color(0.92, 0.88, 0.80))  # Inner cream vest
		
		# 4. Head & Face
		draw_circle(Vector2(0, -3 + bob), 4.0, Color(0.96, 0.80, 0.68)) # Skin tone
		
		# 5. Straw Hat (Crown + Brim)
		draw_circle(Vector2(0, -5 + bob), 5.5, Color(0.85, 0.72, 0.40)) # Hat brim
		draw_circle(Vector2(0, -6 + bob), 3.5, Color(0.92, 0.80, 0.48)) # Hat crown
		draw_rect(Rect2(-3, -5 + bob, 6, 1.5), Color(0.55, 0.25, 0.18)) # Brown hat band
		
		# 6. Directional Eyes / Details
		match current_direction:
			Vector2i.DOWN:
				draw_circle(Vector2(-1.5, -2 + bob), 1.0, Color(0.12, 0.12, 0.18)) # Left eye
				draw_circle(Vector2(1.5, -2 + bob), 1.0, Color(0.12, 0.12, 0.18))  # Right eye
			Vector2i.UP:
				# Back of hat covers eyes
				pass
			Vector2i.LEFT:
				draw_circle(Vector2(-2.5, -2 + bob), 1.0, Color(0.12, 0.12, 0.18)) # Side profile eye
			Vector2i.RIGHT:
				draw_circle(Vector2(2.5, -2 + bob), 1.0, Color(0.12, 0.12, 0.18))  # Side profile eye
