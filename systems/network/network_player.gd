class_name NetworkPlayer
extends CharacterBody2D

## Visual and interpolated presentation of a remote peer player entity in the world.

@export var peer_id: int = 1
@export var player_id: String = "player_002"
@export var display_name: String = "Co-op Botanist"
@export var current_world: String = "farm"

var target_position: Vector2 = Vector2.ZERO
var facing_direction: Vector2i = Vector2i.DOWN
var movement_state: String = "idle"
var interpolation_speed: float = 18.0

var animation_handler: PlayerAnimation
var name_label: Label

func _ready() -> void:
	z_index = 5
	_setup_visuals()
	target_position = position

func _setup_visuals() -> void:
	# 1. Animation handler
	var anim_script = load("res://systems/player/player_animation.gd") as GDScript
	if anim_script:
		animation_handler = anim_script.new() as PlayerAnimation
		add_child(animation_handler)
		
	# 2. Name tag above head
	name_label = Label.new()
	name_label.text = display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.position = Vector2(-40, -22)
	name_label.size = Vector2(80, 14)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.7, 0.9))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(name_label)

func update_network_state(pos: Vector2, facing: Vector2i, state: String, world_id: String) -> void:
	target_position = pos
	facing_direction = facing
	movement_state = state
	current_world = world_id
	
	if animation_handler:
		animation_handler.set_direction(facing_direction)
		animation_handler.set_state(movement_state)

func _process(delta: float) -> void:
	# Smooth interpolation between received network packets
	if position.distance_to(target_position) > 0.5:
		position = position.lerp(target_position, clampf(interpolation_speed * delta, 0.0, 1.0))
	else:
		position = target_position
		
	if not is_inside_tree(): return
		
	# Visibility based on local player's active world
	var wm = get_node_or_null("/root/WorldManager")
	if wm:
		var local_world = wm.get_current_world()
		visible = (current_world == local_world)

