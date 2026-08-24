class_name WeatherOverlay
extends Node2D

## Lightweight pixel-art rain and snow environmental particle overlay.

var rain_particles: Array = []
var snow_particles: Array = []
const MAX_RAIN = 60
const MAX_SNOW = 45

func _ready() -> void:
	z_index = 100
	var wm = get_node_or_null("/root/WeatherManager")
	if wm:
		wm.weather_changed.connect(func(_o, _n): _init_particles())
	_init_particles()

func _init_particles() -> void:
	rain_particles.clear()
	snow_particles.clear()
	var wm = get_node_or_null("/root/WeatherManager")
	var w = wm.current_weather if wm else "clear"
	
	if w == "rain":
		for i in range(MAX_RAIN):
			rain_particles.append({
				"pos": Vector2(randf_range(0, 512), randf_range(0, 384)),
				"speed": randf_range(260, 340),
				"len": randf_range(5, 8)
			})
	elif w == "snow":
		for i in range(MAX_SNOW):
			snow_particles.append({
				"pos": Vector2(randf_range(0, 512), randf_range(0, 384)),
				"speed": randf_range(30, 50),
				"drift": randf_range(-15, 15),
				"size": randf_range(1.0, 2.0)
			})
	queue_redraw()

func _process(delta: float) -> void:
	var wm = get_node_or_null("/root/WeatherManager")
	var w = wm.current_weather if wm else "clear"
	if w == "clear":
		return
		
	if w == "rain":
		for p in rain_particles:
			p["pos"].y += p["speed"] * delta
			p["pos"].x -= p["speed"] * 0.25 * delta
			if p["pos"].y > 384:
				p["pos"].y = -10
				p["pos"].x = randf_range(0, 530)
	elif w == "snow":
		for p in snow_particles:
			p["pos"].y += p["speed"] * delta
			p["pos"].x += p["drift"] * delta
			if p["pos"].y > 384:
				p["pos"].y = -5
				p["pos"].x = randf_range(0, 512)
				
	queue_redraw()

func _draw() -> void:
	var wm = get_node_or_null("/root/WeatherManager")
	var w = wm.current_weather if wm else "clear"
	
	if w == "rain":
		var c_rain = Color(0.65, 0.82, 0.95, 0.6)
		for p in rain_particles:
			var start = p["pos"]
			var finish = start + Vector2(-p["len"] * 0.25, p["len"])
			draw_line(start, finish, c_rain, 1.0)
	elif w == "snow":
		var c_snow = Color(0.95, 0.98, 1.0, 0.8)
		for p in snow_particles:
			draw_circle(p["pos"], p["size"], c_snow)
