class_name PlantInstance
extends Node2D

## Visual and logical representation of a growing plant on a grid tile.

@export var plant_id: String = "red_flower"
@export var grid_position: Vector2i = Vector2i.ZERO
@export var growth_stage: int = 0
@export var days_in_stage: int = 0
@export var watered_today: bool = false
@export var is_mature: bool = false

var plant_data: Dictionary = {}
var genetic_identity: String = ""
var genetic_profile: Dictionary = {}

func _ready() -> void:
	update_plant_data()
	queue_redraw()

func setup(p_plant_id: String, p_pos: Vector2i, p_stage: int = 0, p_watered: bool = false, gen_id: String = "", gen_prof: Dictionary = {}) -> void:
	plant_id = p_plant_id
	grid_position = p_pos
	growth_stage = p_stage
	days_in_stage = 0
	watered_today = p_watered
	genetic_identity = gen_id
	genetic_profile = gen_prof
	position = Vector2(p_pos.x * 16 + 8, p_pos.y * 16 + 8)
	update_plant_data()
	queue_redraw()

func update_plant_data() -> void:
	var pm = get_node_or_null("/root/PlantManager")
	if pm:
		plant_data = pm.get_plant(plant_id)
		var max_stages = pm.get_max_stages(plant_id)
		is_mature = (growth_stage >= max_stages - 1)

func set_watered(watered: bool) -> void:
	watered_today = watered
	queue_redraw()

func advance_growth() -> bool:
	var needs_water = true
	if not genetic_profile.is_empty():
		needs_water = bool(genetic_profile.get("water_required", true))
		
	if needs_water and not watered_today:
		return false
		
	var old_stage = growth_stage
	var pm = get_node_or_null("/root/PlantManager")
	if pm:
		var result = pm.calculate_growth(plant_id, growth_stage, days_in_stage, genetic_profile)
		growth_stage = result.get("new_stage", growth_stage)
		days_in_stage = result.get("days_in_stage", 0)
		is_mature = result.get("is_mature", false)
	else:
		growth_stage += 1
		days_in_stage = 0
		
	if growth_stage > old_stage:
		var spawner = EffectSpawner.get_instance()
		if spawner:
			spawner.spawn_growth_effect(global_position)
		
	watered_today = false
	queue_redraw()
	return true

func _draw() -> void:
	# 1. Check for custom sprite asset via AssetRegistry
	var custom_tex = AssetRegistry.get_plant_texture(plant_id, growth_stage)
	if custom_tex:
		draw_texture(custom_tex, Vector2(-8, -8))
		if watered_today:
			draw_circle(Vector2(5, -5), 1.5, Color(0.2, 0.7, 1.0, 0.9))
		return

	# 2. Draw watering moisture highlight around base if watered
	if watered_today:
		draw_circle(Vector2(0, 4), 6.0, Color(0.12, 0.38, 0.65, 0.45))
		# Tiny blue droplet icon
		draw_circle(Vector2(5, -5), 1.6, Color(0.2, 0.75, 1.0, 0.95))

	var color_str = plant_data.get("visual", {}).get("color", "#E63946")
	var accent_str = plant_data.get("visual", {}).get("accent_color", "#FF758F")
	var main_color = Color.from_string(color_str, Color.RED)
	var accent_color = Color.from_string(accent_str, Color.PINK)
	var stem_color = Color(0.22, 0.60, 0.25)
	var leaf_color = Color(0.32, 0.72, 0.28)
	var leaf_dark = Color(0.18, 0.48, 0.18)
	
	match growth_stage:
		0: # Seed / Mound & Tiny Sprout Tip
			draw_circle(Vector2(0, 4), 4.0, Color(0.35, 0.20, 0.10))
			draw_circle(Vector2(0, 3), 2.0, Color(0.70, 0.58, 0.38))
			draw_line(Vector2(0, 2), Vector2(0, 0), Color(0.45, 0.82, 0.35), 1.2)
		1: # Sprout / Cotyledon Leaves
			draw_line(Vector2(0, 5), Vector2(0, -1), stem_color, 1.5)
			# Left leaf
			draw_circle(Vector2(-3, -1), 2.0, leaf_color)
			draw_circle(Vector2(-2, -1), 1.0, leaf_dark)
			# Right leaf
			draw_circle(Vector2(3, -2), 2.0, leaf_color)
			draw_circle(Vector2(2, -2), 1.0, leaf_dark)
		2: # Growing / Branching & Budding
			draw_line(Vector2(0, 6), Vector2(0, -3), stem_color, 2.0)
			# Lower foliage
			draw_circle(Vector2(-4, 0), 2.5, leaf_dark)
			draw_circle(Vector2(4, 1), 2.5, leaf_dark)
			# Upper foliage
			draw_circle(Vector2(-3, -2), 2.5, leaf_color)
			draw_circle(Vector2(3, -1), 2.5, leaf_color)
			# Species color bud
			draw_circle(Vector2(0, -4), 3.0, main_color.darkened(0.15))
			draw_circle(Vector2(0, -5), 1.5, accent_color)
		_: # Mature / Full Bloom & Shimmer
			# Sturdy stem & rich leafy backdrop
			draw_line(Vector2(0, 6), Vector2(0, -2), stem_color, 2.0)
			draw_circle(Vector2(-5, 0), 3.0, leaf_dark)
			draw_circle(Vector2(5, 1), 3.0, leaf_dark)
			draw_circle(Vector2(-3, 1), 2.5, leaf_color)
			draw_circle(Vector2(3, 2), 2.5, leaf_color)
			
			# Multi-petal flower / mushroom cap
			draw_circle(Vector2(0, -4), 5.0, main_color)
			draw_circle(Vector2(-3, -6), 2.2, accent_color)
			draw_circle(Vector2(3, -6), 2.2, accent_color)
			draw_circle(Vector2(-3, -2), 2.2, accent_color)
			draw_circle(Vector2(3, -2), 2.2, accent_color)
			
			# Golden central pollen pistil
			draw_circle(Vector2(0, -4), 1.8, Color(1.0, 0.88, 0.20))
			
			# Harvest sparkles
			draw_circle(Vector2(5, -7), 1.2, Color.WHITE)
			draw_circle(Vector2(-4, -8), 0.8, Color.WHITE)
