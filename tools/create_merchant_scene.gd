@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Node2D.new()
	root.name = "SeedMerchant"
	root.set_script(load("res://systems/npc/seed_merchant.gd"))

	var stall = Sprite2D.new()
	stall.name = "StallSprite"
	root.add_child(stall)
	stall.owner = root

	var merchant = Sprite2D.new()
	merchant.name = "MerchantSprite"
	root.add_child(merchant)
	merchant.owner = root

	var lbl = Label.new()
	lbl.name = "PromptLabel"
	root.add_child(lbl)
	lbl.owner = root

	var timer = Timer.new()
	timer.name = "AnimTimer"
	root.add_child(timer)
	timer.owner = root

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://systems/npc/seed_merchant.tscn")
	print("[SeedMerchantSceneBuilder] Successfully saved seed_merchant.tscn!")
