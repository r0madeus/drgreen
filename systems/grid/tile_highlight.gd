class_name TileHighlight
extends Node2D

## Visual Tile Target Highlight and Tool Preview Overlay for Mouse & Stardew-Style Controls.

var target_grid_pos: Vector2i = Vector2i(-1, -1)
var is_in_range: bool = false
var is_valid_action: bool = false
var highlight_mode: String = "default" # "default", "plant", "water", "harvest", "interact", "exit", "invalid"
var preview_text: String = ""

var border_color: Color = Color(1.0, 1.0, 1.0, 0.7)
var fill_color: Color = Color(1.0, 1.0, 1.0, 0.1)

func _ready() -> void:
	z_index = 25 # Above terrain/ground, below floating text & UI
	queue_redraw()

func update_target(grid_pos: Vector2i, in_range: bool, valid_action: bool, mode: String = "default", tooltip: String = "") -> void:
	target_grid_pos = grid_pos
	is_in_range = in_range
	is_valid_action = valid_action
	highlight_mode = mode
	preview_text = tooltip
	
	position = Vector2(grid_pos.x * 16, grid_pos.y * 16)
	
	# Determine colors
	if not is_in_range:
		border_color = Color(0.9, 0.3, 0.3, 0.6)
		fill_color = Color(0.9, 0.3, 0.3, 0.08)
	else:
		match highlight_mode:
			"plant":
				border_color = Color(0.3, 1.0, 0.4, 0.85)
				fill_color = Color(0.3, 1.0, 0.4, 0.2)
			"water":
				border_color = Color(0.3, 0.8, 1.0, 0.85)
				fill_color = Color(0.3, 0.8, 1.0, 0.2)
			"hoe", "till":
				border_color = Color(0.85, 0.6, 0.3, 0.85)
				fill_color = Color(0.85, 0.6, 0.3, 0.2)
			"axe":
				border_color = Color(0.9, 0.7, 0.35, 0.85)
				fill_color = Color(0.9, 0.7, 0.35, 0.2)
			"pickaxe":
				border_color = Color(0.8, 0.8, 0.9, 0.85)
				fill_color = Color(0.8, 0.8, 0.9, 0.2)
			"harvest":
				border_color = Color(1.0, 0.9, 0.2, 0.9)
				fill_color = Color(1.0, 0.9, 0.2, 0.25)
			"interact":
				border_color = Color(0.9, 0.5, 1.0, 0.85)
				fill_color = Color(0.9, 0.5, 1.0, 0.2)
			"exit":
				border_color = Color(0.2, 0.9, 0.9, 0.9)
				fill_color = Color(0.2, 0.9, 0.9, 0.25)
			"invalid":
				border_color = Color(0.9, 0.3, 0.3, 0.7)
				fill_color = Color(0.9, 0.3, 0.3, 0.12)
			_:
				border_color = Color(1.0, 1.0, 1.0, 0.75) if is_valid_action else Color(0.8, 0.8, 0.8, 0.4)
				fill_color = Color(1.0, 1.0, 1.0, 0.08)

				
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm and lsm.get_setting("accessibility", "high_contrast", false):
		border_color.a = 1.0
		fill_color.a = min(fill_color.a * 1.5, 0.4)
		
	queue_redraw()

func _draw() -> void:
	if target_grid_pos.x < 0 or target_grid_pos.y < 0:
		return
		
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm and not lsm.get_setting("accessibility", "show_tile_highlight", true):
		return
		
	# Draw filled inner rect
	draw_rect(Rect2(Vector2(1, 1), Vector2(14, 14)), fill_color, true)
	
	# Draw 16x16 border box
	draw_rect(Rect2(Vector2.ZERO, Vector2(16, 16)), border_color, false, 1.0)
	
	# Draw corner accents for high readability
	draw_line(Vector2(0, 0), Vector2(3, 0), border_color, 1.5)
	draw_line(Vector2(0, 0), Vector2(0, 3), border_color, 1.5)
	draw_line(Vector2(16, 0), Vector2(13, 0), border_color, 1.5)
	draw_line(Vector2(16, 0), Vector2(16, 3), border_color, 1.5)
	draw_line(Vector2(0, 16), Vector2(3, 16), border_color, 1.5)
	draw_line(Vector2(0, 16), Vector2(0, 13), border_color, 1.5)
	draw_line(Vector2(16, 16), Vector2(13, 16), border_color, 1.5)
	draw_line(Vector2(16, 16), Vector2(16, 13), border_color, 1.5)