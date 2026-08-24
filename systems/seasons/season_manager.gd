extends Node

## Manages 4-season cycle, day of season, year progression and seasonal environmental styling.

enum Season { SPRING = 0, SUMMER = 1, AUTUMN = 2, WINTER = 3 }

signal season_changed(old_season: String, new_season: String)
signal year_started(year: int)

var days_per_season: int = 7
var current_season_idx: int = 0
var day_of_season: int = 1
var total_year: int = 1

var seasons_catalog: Array = [
	{ "id": "spring", "name": "Spring", "icon": "🌱", "banner": "🌱 Spring Begins!", "tint": Color(1.0, 1.05, 0.98, 1.0) },
	{ "id": "summer", "name": "Summer", "icon": "☀️", "banner": "☀️ Summer Begins!", "tint": Color(1.05, 1.05, 0.9, 1.0) },
	{ "id": "autumn", "name": "Autumn", "icon": "🍂", "banner": "🍂 Autumn Begins!", "tint": Color(1.1, 0.95, 0.8, 1.0) },
	{ "id": "winter", "name": "Winter", "icon": "❄️", "banner": "❄️ Winter Begins!", "tint": Color(0.85, 0.95, 1.15, 1.0) }
]

func _ready() -> void:
	load_config()
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.day_started.connect(_on_day_advanced)
		update_from_day(tm.current_day)

func load_config() -> void:
	var path = "res://data/world/seasons.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				days_per_season = int(json.data.get("days_per_season", 7))

func update_from_day(day: int, emit_notifications: bool = false) -> void:
	var old_s_id = get_season_id()
	var old_year = total_year
	
	var total_days_0 = max(0, day - 1)
	var total_seasons = total_days_0 / days_per_season
	current_season_idx = total_seasons % 4
	total_year = 1 + (total_seasons / 4)
	day_of_season = 1 + (total_days_0 % days_per_season)
	
	var new_s_id = get_season_id()
	if old_s_id != new_s_id:
		season_changed.emit(old_s_id, new_s_id)
		if emit_notifications:
			var am = get_node_or_null("/root/AudioManager")
			if am: am.play_sfx("season_transition")
			var spawner = EffectSpawner.get_instance()
			var player = get_tree().root.find_child("Player", true, false)
			var pos = player.global_position if player else Vector2(240, 180)
			if spawner:
				spawner.spawn_floating_text(pos, get_season_banner(), Color(1.0, 0.9, 0.3))
				
	if total_year > old_year:
		year_started.emit(total_year)

func _on_day_advanced(new_day: int) -> void:
	update_from_day(new_day, true)

func get_season_id() -> String:
	return seasons_catalog[current_season_idx]["id"]

func get_season_name() -> String:
	return seasons_catalog[current_season_idx]["name"]

func get_season_icon() -> String:
	return seasons_catalog[current_season_idx]["icon"]

func get_season_banner() -> String:
	return seasons_catalog[current_season_idx]["banner"]

func get_season_tint() -> Color:
	return seasons_catalog[current_season_idx]["tint"]

func is_winter() -> bool:
	return current_season_idx == Season.WINTER

# --- State Persistence ---
func get_season_state() -> Dictionary:
	return {
		"season": get_season_id(),
		"season_index": current_season_idx,
		"day_of_season": day_of_season,
		"year": total_year
	}

func load_season_state(data: Dictionary) -> void:
	if data.has("season_index"):
		current_season_idx = int(data.get("season_index", 0))
	elif data.has("season"):
		var sid = str(data["season"])
		for i in range(seasons_catalog.size()):
			if seasons_catalog[i]["id"] == sid:
				current_season_idx = i
				break
	day_of_season = int(data.get("day_of_season", 1))
	total_year = int(data.get("year", 1))
