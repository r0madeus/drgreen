@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Node2D.new()
	root.name = "GreenhouseBuilding"
	root.set_script(load("res://systems/world/greenhouse_building.gd"))
	root.position = Vector2(23 * 16, 6 * 16) # (368, 96)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var tex = ResourceLoader.load("res://assets/sprites/environment/greenhouse_ruined.png")
	if tex:
		sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(sprite)
	sprite.owner = root

	var prompt = Label.new()
	prompt.name = "PromptLabel"
	prompt.text = "💬 [E] Repair Greenhouse"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.modulate = Color(1.0, 0.9, 0.4)
	prompt.add_theme_font_size_override("font_size", 9)
	prompt.position = Vector2(-75, -28)
	prompt.custom_minimum_size = Vector2(150, 16)
	prompt.visible = false
	root.add_child(prompt)
	prompt.owner = root

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://systems/world/greenhouse_building.tscn")
	print("[GreenhouseSceneBuilder] Successfully created greenhouse_building.tscn!")
