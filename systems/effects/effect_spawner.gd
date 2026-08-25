class_name EffectSpawner
extends Node2D

## Lightweight pixel-art particle effect generator and floating text spawner.

static var _instance: Node = null

func _init() -> void:
	if not _instance:
		_instance = self

func _ready() -> void:
	_instance = self

static func get_instance() -> Node:
	if not _instance or not is_instance_valid(_instance):
		_instance = EffectSpawner.new()
	return _instance

static func play_effect(effect_id: String, pos: Vector2, text: String = "", color: Color = Color.WHITE) -> void:
	if not _instance: return
	var spawner = _instance as EffectSpawner
	match effect_id:
		"farming.plant", "plant":
			spawner.spawn_planting_effect(pos)
		"farming.water", "water":
			spawner.spawn_watering_effect(pos)
		"farming.growth", "growth":
			spawner.spawn_growth_effect(pos)
		"farming.harvest", "harvest":
			spawner.spawn_harvest_effect(pos)
		"floating_text", "text":
			spawner.spawn_floating_text(pos, text, color)
		_:
			if text != "":
				spawner.spawn_floating_text(pos, text, color)
			else:
				spawner.spawn_growth_effect(pos)


# 1. PLANTING EFFECT: Earthy soil specks
func spawn_planting_effect(pos: Vector2) -> void:
	var container = Node2D.new()
	container.position = pos
	add_child(container)
	
	var colors = [Color("6e3d1a"), Color("8a5025"), Color("3a1e0b"), Color("58b83d")]
	for i in range(8):
		var speck = ColorRect.new()
		speck.size = Vector2(2, 2)
		speck.color = colors[i % colors.size()]
		speck.position = Vector2(randf_range(-4, 4), randf_range(-2, 2))
		container.add_child(speck)
		
		var target_offset = Vector2(randf_range(-10, 10), randf_range(-12, -4))
		var tween = create_tween().set_parallel(true)
		tween.tween_property(speck, "position", speck.position + target_offset, 0.25).set_ease(Tween.EASE_OUT)
		tween.tween_property(speck, "position:y", speck.position.y + 6, 0.25).set_delay(0.15).set_ease(Tween.EASE_IN)
		tween.tween_property(speck, "modulate:a", 0.0, 0.4)
		
	var tree = get_tree()
	if tree: tree.create_timer(0.45).timeout.connect(_safe_free_node.bind(container))

# 2. WATERING EFFECT: Blue splash droplets & ring
func spawn_watering_effect(pos: Vector2) -> void:
	var container = Node2D.new()
	container.position = pos
	add_child(container)
	
	var water_colors = [Color("3a82e8"), Color("6ea8ff"), Color("b3d4fc")]
	for i in range(10):
		var drop = ColorRect.new()
		drop.size = Vector2(2, 2)
		drop.color = water_colors[i % water_colors.size()]
		drop.position = Vector2(randf_range(-4, 4), randf_range(-6, -2))
		container.add_child(drop)
		
		var target_offset = Vector2(randf_range(-12, 12), randf_range(-14, 2))
		var tween = create_tween().set_parallel(true)
		tween.tween_property(drop, "position", drop.position + target_offset, 0.3).set_ease(Tween.EASE_OUT)
		tween.tween_property(drop, "modulate:a", 0.0, 0.35)
		
	var tree = get_tree()
	if tree: tree.create_timer(0.4).timeout.connect(_safe_free_node.bind(container))

# 3. GROWTH EFFECT: Emerald rising sparkles
func spawn_growth_effect(pos: Vector2) -> void:
	var container = Node2D.new()
	container.position = pos
	add_child(container)
	
	var colors = [Color("58b83d"), Color("87de66"), Color("ffea78")]
	for i in range(8):
		var star = ColorRect.new()
		star.size = Vector2(2, 2)
		star.color = colors[i % colors.size()]
		star.position = Vector2(randf_range(-6, 6), randf_range(-2, 4))
		container.add_child(star)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(star, "position:y", star.position.y - randf_range(12, 20), 0.45).set_ease(Tween.EASE_OUT)
		tween.tween_property(star, "position:x", star.position.x + randf_range(-6, 6), 0.45)
		tween.tween_property(star, "modulate:a", 0.0, 0.45)
		
	var tree = get_tree()
	if tree: tree.create_timer(0.5).timeout.connect(_safe_free_node.bind(container))

# 4. HARVEST EFFECT: Golden starburst + leafy floaters
func spawn_harvest_effect(pos: Vector2) -> void:
	var container = Node2D.new()
	container.position = pos
	add_child(container)
	
	var colors = [Color("ffcc24"), Color("fff07a"), Color("ffffff"), Color("429930")]
	for i in range(12):
		var sparkle = ColorRect.new()
		sparkle.size = Vector2(randf_range(2, 3), randf_range(2, 3))
		sparkle.color = colors[i % colors.size()]
		sparkle.position = Vector2(randf_range(-3, 3), randf_range(-3, 3))
		container.add_child(sparkle)
		
		var angle = (float(i) / 12.0) * TAU
		var dir = Vector2(cos(angle), sin(angle)) * randf_range(10, 18)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(sparkle, "position", sparkle.position + dir, 0.35).set_ease(Tween.EASE_OUT)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.4)
		
	var tree = get_tree()
	if tree: tree.create_timer(0.45).timeout.connect(_safe_free_node.bind(container))

# 5. FLOATING POPUP TEXT: Floating feedback message (+1 Crop, etc.)
func spawn_floating_text(pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	if not is_inside_tree(): return
	var sm = get_node_or_null("/root/SettingsManager")
	if sm and not bool(sm.get_setting("gameplay", "floating_text", true)):
		return
		
	var lbl = Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.position = pos + Vector2(-20, -16)
	lbl.add_theme_font_size_override("font_size", 10)
	add_child(lbl)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(lbl, "position:y", lbl.position.y - 18, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(0.2)
	var tree = get_tree()
	if tree: tree.create_timer(0.85).timeout.connect(_safe_free_node.bind(lbl))

func _safe_free_node(node: Node) -> void:
	if node and is_instance_valid(node):
		node.queue_free()
