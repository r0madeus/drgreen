extends Node

## Manages deterministic daily weather, rain watering and environmental effects.

enum WeatherType { CLEAR, RAIN, SNOW }

signal weather_changed(old_weather: String, new_weather: String)

var current_weather: String = "clear"
var weather_probabilities: Dictionary = {}

func _ready() -> void:
	load_config()
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.day_started.connect(_on_day_advanced)
		evaluate_weather_for_current_day(false)

func load_config() -> void:
	var path = "res://data/world/weather.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				weather_probabilities = json.data.get("probabilities", {})

func evaluate_weather_for_current_day(emit_notifications: bool = true) -> void:
	var sm = get_node_or_null("/root/SeasonManager")
	var season_id = sm.get_season_id() if sm else "spring"
	var season_idx = sm.current_season_idx if sm else 0
	var day_s = sm.day_of_season if sm else 1
	var yr = sm.total_year if sm else 1
	
	# Deterministic pseudo-random seed based on calendar date
	var seed_val = (yr * 7919) + (season_idx * 997) + (day_s * 101)
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	var roll = rng.randf()
	
	var probs = weather_probabilities.get(season_id, { "clear": 0.7, "rain": 0.3, "snow": 0.0 })
	var clear_p = float(probs.get("clear", 0.7))
	var rain_p = float(probs.get("rain", 0.3))
	
	var old_w = current_weather
	if roll < clear_p:
		current_weather = "clear"
	elif roll < clear_p + rain_p:
		current_weather = "rain"
	else:
		current_weather = "snow"
		
	if old_w != current_weather or emit_notifications:
		weather_changed.emit(old_w, current_weather)
		_apply_weather_effects(emit_notifications)

func _on_day_advanced(_day: int) -> void:
	evaluate_weather_for_current_day(true)

func _apply_weather_effects(notify: bool) -> void:
	var am = get_node_or_null("/root/AudioManager")
	var gm = get_tree().root.find_child("GridManager", true, false)
	
	if current_weather == "rain":
		if am: am.play_sfx("rain_ambient")
		if gm and gm.has_method("apply_rain_watering"):
			gm.apply_rain_watering()
		if notify:
			var spawner = EffectSpawner.get_instance()
			var player = get_tree().root.find_child("Player", true, false)
			var pos = player.global_position if player else Vector2(240, 180)
			if spawner:
				spawner.spawn_floating_text(pos, "🌧️ Rain: Outdoor fields watered!", Color(0.4, 0.8, 1.0))
	elif current_weather == "snow":
		if am: am.play_sfx("snow_wind")
		if notify:
			var spawner = EffectSpawner.get_instance()
			var player = get_tree().root.find_child("Player", true, false)
			var pos = player.global_position if player else Vector2(240, 180)
			if spawner:
				spawner.spawn_floating_text(pos, "❄️ Snowfall: Outdoor flora dormant!", Color(0.8, 0.9, 1.0))

func get_weather_icon() -> String:
	match current_weather:
		"rain": return "🌧️"
		"snow": return "❄️"
		_: return "☀️"

func is_raining() -> bool:
	return current_weather == "rain"

func is_snowing() -> bool:
	return current_weather == "snow"


func get_weather_name() -> String:
	match current_weather:
		"rain": return "Rain"
		"snow": return "Snow"
		_: return "Clear"

# --- State Persistence ---
func get_weather_state() -> Dictionary:
	return { "current": current_weather }

func load_weather_state(data: Dictionary) -> void:
	current_weather = str(data.get("current", "clear"))
