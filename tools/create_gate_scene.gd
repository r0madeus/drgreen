@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Node2D.new()
	root.name = "WoodenGate"
	root.set_script(load("res://systems/world/wooden_gate.gd"))
	root.position = Vector2(31 * 16 + 8, 12 * 16 + 8)

	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	var tex = ResourceLoader.load("res://assets/sprites/environment/wooden_gate.png")
	if tex:
		sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(sprite)
	sprite.owner = root

	var prompt = Label.new()
	prompt.name = "PromptLabel"
	prompt.text = "💬 [E] Grove Gate"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.modulate = Color(1.0, 0.9, 0.4)
	prompt.add_theme_font_size_override("font_size", 9)
	prompt.position = Vector2(-50, -22)
	prompt.custom_minimum_size = Vector2(100, 16)
	prompt.visible = false
	root.add_child(prompt)
	prompt.owner = root

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://systems/world/wooden_gate.tscn")
	print("[GateSceneBuilder] Successfully created wooden_gate.tscn!")
