@tool
extends SceneTree

func _init() -> void:
	build_scene()
	quit()

static func build_scene() -> void:
	var root = Node2D.new()
	root.name = "WeatherOverlay"
	root.set_script(load("res://systems/weather/weather_overlay.gd"))

	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://systems/weather/weather_overlay.tscn")
	print("[WeatherOverlayBuilder] Successfully created weather_overlay.tscn!")
