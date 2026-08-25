extends Node

## Centralized, deterministic World Clock, Day/Night Cycle, and Sleep Manager (Autoload Singleton).
## Decoupled from frame-rate, supporting reference-counted pausing, data-driven phases,
## ambient lighting interpolation, and the complete sleep-to-morning pipeline.

signal time_changed(minutes: int, time_str: String)
signal hour_changed(hour: int)
signal day_phase_changed(old_phase: String, new_phase: String)
signal day_started(day_number: int)
signal day_ended(day_number: int)
signal morning_started(day_number: int)
signal night_started(day_number: int)
signal time_advanced(day_number: int, phase: String)
signal sleep_requested()
signal sleep_completed(new_day: int)
signal time_paused(is_paused: bool, reason: String)

const CONFIG_PATH: String = "res://data/time/time_config.json"

# --- Calendar & Time State ---
var current_day: int = 1
var current_time_minutes: float = 360.0 # 06:00 AM default start
var current_day_phase: String = "dawn"
var day_start_minutes: int = 360
var day_end_minutes: int = 1440
var minutes_per_real_second: float = 1.0
var time_scale: float = 1.0
var auto_sleep_at_midnight: bool = true
var total_played_days: int = 1
var is_sleeping: bool = false


# Reference-counted pause reasons (e.g. UI, DIALOGUE, MENU, BUILDER, CUTSCENE)
var _pause_reasons: Dictionary = {}

var is_paused: bool:
	get: return not _pause_reasons.is_empty()
	set(val):
		if val:
			pause_time("manual")
		else:
			resume_time("manual")



# Accumulator for deterministic integer minute ticks
var _minute_accumulator: float = 0.0
var _last_emitted_hour: int = 6
var _last_emitted_minute: int = 360

# Data-driven phase configurations
var phases_config: Dictionary = {
	"dawn": { "start_minute": 360, "end_minute": 480, "name_key": "time.phase.dawn", "ambient_color": Color(0.88, 0.80, 0.90, 1.0), "light_energy": 0.85 },
	"day": { "start_minute": 480, "end_minute": 1080, "name_key": "time.phase.day", "ambient_color": Color(1.0, 1.0, 1.0, 1.0), "light_energy": 1.0 },
	"dusk": { "start_minute": 1080, "end_minute": 1260, "name_key": "time.phase.dusk", "ambient_color": Color(0.94, 0.70, 0.52, 1.0), "light_energy": 0.78 },
	"night": { "start_minute": 1260, "end_minute": 1440, "name_key": "time.phase.night", "ambient_color": Color(0.35, 0.40, 0.62, 1.0), "light_energy": 0.45 }
}

# Compatibility property
var current_time: String:
	get: return current_day_phase
	set(val): current_day_phase = val

func _ready() -> void:
	load_config()
	_update_phase(false)
	_last_emitted_hour = int(floor(current_time_minutes / 60.0))
	_last_emitted_minute = int(floor(current_time_minutes))

func _process(delta: float) -> void:
	if is_time_paused() or is_sleeping:
		return
		
	_minute_accumulator += delta * minutes_per_real_second * time_scale
	if _minute_accumulator >= 1.0:
		var minutes_to_add = floor(_minute_accumulator)
		_minute_accumulator -= minutes_to_add
		advance_time(minutes_to_add)

func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var f = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if not f: return
	var text = f.get_as_text()
	f.close()
	
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		var d: Dictionary = json.data
		day_start_minutes = int(d.get("day_start_minutes", 360))
		day_end_minutes = int(d.get("day_end_minutes", 1440))
		minutes_per_real_second = float(d.get("minutes_per_real_second", 1.0))
		time_scale = float(d.get("time_scale", 1.0))
		auto_sleep_at_midnight = bool(d.get("auto_sleep_at_midnight", true))
		
		var raw_phases = d.get("phases", {})
		for pk in raw_phases.keys():
			var pinfo = raw_phases[pk]
			var c_arr = pinfo.get("ambient_color", [1.0, 1.0, 1.0, 1.0])
			var col = Color(c_arr[0], c_arr[1], c_arr[2], c_arr[3])
			phases_config[pk] = {
				"start_minute": int(pinfo.get("start_minute", 360)),
				"end_minute": int(pinfo.get("end_minute", 480)),
				"name_key": str(pinfo.get("name_key", "time.phase." + pk)),
				"ambient_color": col,
				"light_energy": float(pinfo.get("light_energy", 1.0))
			}

# ---------- Time Flow & Advancement ----------

func advance_time(minutes: float) -> void:
	if minutes <= 0.0: return
	
	current_time_minutes += minutes
	var cur_int_min = int(floor(current_time_minutes))
	
	# Check midnight / day end
	if current_time_minutes >= day_end_minutes:
		if auto_sleep_at_midnight:
			execute_sleep(true)
			return
		else:
			current_time_minutes = fmod(current_time_minutes, float(day_end_minutes))
			
	var cur_hour = int(floor(current_time_minutes / 60.0)) % 24
	if cur_hour != _last_emitted_hour:
		_last_emitted_hour = cur_hour
		hour_changed.emit(cur_hour)
		var bus = get_node_or_null("/root/EventBus")
		if bus: bus.hour_changed.emit(cur_hour)
		
	if cur_int_min != _last_emitted_minute:
		_last_emitted_minute = cur_int_min
		var t_str = get_time_string()
		time_changed.emit(cur_int_min, t_str)
		var bus = get_node_or_null("/root/EventBus")
		if bus: bus.time_changed.emit(cur_int_min, t_str)
		
	_update_phase(true)

func _update_phase(emit_signals: bool = true) -> void:
	var old_phase = current_day_phase
	var resolved_phase = "day"
	var m = current_time_minutes
	
	if m >= phases_config["dawn"]["start_minute"] and m < phases_config["dawn"]["end_minute"]:
		resolved_phase = "dawn"
	elif m >= phases_config["day"]["start_minute"] and m < phases_config["day"]["end_minute"]:
		resolved_phase = "day"
	elif m >= phases_config["dusk"]["start_minute"] and m < phases_config["dusk"]["end_minute"]:
		resolved_phase = "dusk"
	else:
		resolved_phase = "night"
		
	current_day_phase = resolved_phase
	if old_phase != resolved_phase and emit_signals:
		day_phase_changed.emit(old_phase, resolved_phase)
		time_advanced.emit(current_day, resolved_phase)
		var bus = get_node_or_null("/root/EventBus")
		if bus:
			bus.day_phase_changed.emit(old_phase, resolved_phase)
			if resolved_phase == "dawn" or resolved_phase == "day":
				morning_started.emit(current_day)
				bus.morning_started.emit(current_day)
			elif resolved_phase == "dusk" or resolved_phase == "night":
				night_started.emit(current_day)
				bus.night_started.emit(current_day)

# ---------- Day Transition & Sleep Pipeline ----------

func set_day(day_number: int) -> void:
	current_day = max(1, day_number)
	current_time_minutes = float(day_start_minutes)
	_minute_accumulator = 0.0
	_last_emitted_hour = int(floor(current_time_minutes / 60.0))
	_last_emitted_minute = int(floor(current_time_minutes))
	_update_phase(false)
	
	day_started.emit(current_day)
	var bus = get_node_or_null("/root/EventBus")
	if bus:
		bus.day_started.emit(current_day)
		bus.morning_started.emit(current_day)

func request_sleep() -> void:
	sleep_requested.emit()
	var bus = get_node_or_null("/root/EventBus")
	if bus: bus.sleep_requested.emit()

func execute_sleep(from_exhaustion: bool = false) -> void:
	if is_sleeping: return
	is_sleeping = true
	
	# 1. Day End Notification
	day_ended.emit(current_day)
	var bus = get_node_or_null("/root/EventBus")
	if bus: bus.day_ended.emit(current_day)
	
	# 2. Restore ALL players energy
	var psm = get_node_or_null("/root/PlayerRegistry")
	if psm:
		for pid in psm.players.keys():
			var p_state = psm.players[pid]
			var restored_energy = p_state.max_energy if not from_exhaustion else (p_state.max_energy * 0.5)
			p_state.energy = restored_energy
			p_state.energy_changed.emit(p_state.energy, restored_energy)
			
	# 3. Advance Season & Calendar
	current_day += 1
	total_played_days += 1
	current_time_minutes = float(day_start_minutes)
	_minute_accumulator = 0.0
	_last_emitted_hour = int(floor(current_time_minutes / 60.0))
	_last_emitted_minute = int(floor(current_time_minutes))
	
	var sm = get_node_or_null("/root/SeasonManager")
	if sm and sm.has_method("update_from_day"):
		sm.update_from_day(current_day, true)
		
	# 4. Advance Weather
	var wm = get_node_or_null("/root/WeatherManager")
	if wm and wm.has_method("evaluate_weather_for_current_day"):
		wm.evaluate_weather_for_current_day(true)
		
	# 5. Advance Crop Growth in GridManager
	var gm = get_tree().root.find_child("GridManager", true, false)
	if gm and gm.has_method("advance_day"):
		gm.advance_day()
		
	# 6. NPC Daily Reset Hook
	var npcm = get_node_or_null("/root/NPCManager")
	if npcm and npcm.has_method("reset_daily_schedules"):
		npcm.reset_daily_schedules()
		
	# 7. Day Start Notifications
	_update_phase(false)
	day_started.emit(current_day)
	morning_started.emit(current_day)
	if bus:
		bus.day_started.emit(current_day)
		bus.morning_started.emit(current_day)
		
	# 8. Auto-Save on Sleep
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr and save_mgr.has_method("save_game"):
		save_mgr.save_game()
		
	is_sleeping = false
	sleep_completed.emit(current_day)
	if bus: bus.sleep_completed.emit(current_day)
	
	# Spawn sleep notification
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		var lm = get_node_or_null("/root/LocalizationManager")
		var msg = lm.get_text("ui.sleep.restored") if lm else "Fully rested! Energy restored."
		spawner.spawn_floating_text(pos, "💤 " + msg, Color(0.4, 1.0, 0.7))

func advance_day() -> void:
	execute_sleep(false)

# ---------- Reference-Counted Pausing ----------

func pause_time(reason: String = "manual") -> void:
	_pause_reasons[reason] = true
	time_paused.emit(true, reason)
	var bus = get_node_or_null("/root/EventBus")
	if bus: bus.time_paused.emit(true, reason)

func resume_time(reason: String = "manual") -> void:
	_pause_reasons.erase(reason)
	if _pause_reasons.is_empty():
		time_paused.emit(false, reason)
		var bus = get_node_or_null("/root/EventBus")
		if bus: bus.time_paused.emit(false, reason)

func is_time_paused() -> bool:
	return not _pause_reasons.is_empty()

func get_pause_reasons() -> Array:
	return _pause_reasons.keys()

# ---------- Query & Formatting API ----------

func get_current_time() -> float:
	return current_time_minutes

func get_current_day() -> int:
	return current_day

func get_day() -> int:
	return current_day

func get_current_season() -> String:
	var sm = get_node_or_null("/root/SeasonManager")
	return sm.get_season_id() if sm else "spring"

func get_current_year() -> int:
	var sm = get_node_or_null("/root/SeasonManager")
	return sm.total_year if sm else 1

func get_day_phase() -> String:
	return current_day_phase

func is_daytime() -> bool:
	return current_day_phase in ["dawn", "day"]

func is_night() -> bool:
	return current_day_phase in ["dusk", "night"]

func get_time_string() -> String:
	var total_min = int(floor(current_time_minutes))
	var hours = (total_min / 60) % 24
	var mins = total_min % 60
	var is_pm = hours >= 12
	var h12 = hours % 12
	if h12 == 0: h12 = 12
	var period = "PM" if is_pm else "AM"
	return "%02d:%02d %s" % [h12, mins, period]

func get_time_formatted() -> String:
	return get_time_string()

func get_ambient_color() -> Color:
	var m = current_time_minutes
	if m >= 360 and m < 480:
		# Dawn -> Day transition
		var factor = (m - 360.0) / 120.0
		return phases_config["dawn"]["ambient_color"].lerp(phases_config["day"]["ambient_color"], factor)
	elif m >= 480 and m < 1080:
		# Full Day
		return phases_config["day"]["ambient_color"]
	elif m >= 1080 and m < 1260:
		# Day -> Dusk transition
		var factor = (m - 1080.0) / 180.0
		return phases_config["day"]["ambient_color"].lerp(phases_config["dusk"]["ambient_color"], factor)
	else:
		# Dusk -> Night transition
		var night_m = (m - 1260.0) if m >= 1260.0 else (m + 180.0)
		var factor = clampf(night_m / 180.0, 0.0, 1.0)
		return phases_config["dusk"]["ambient_color"].lerp(phases_config["night"]["ambient_color"], factor)

# ---------- State Persistence ----------

func get_time_state() -> Dictionary:
	return {
		"current_day": current_day,
		"current_time_minutes": current_time_minutes,
		"current_day_phase": current_day_phase,
		"total_played_days": total_played_days,
		"current_time": current_day_phase
	}

func load_time_state(data: Dictionary) -> void:
	current_day = max(1, int(data.get("current_day", 1)))
	current_time_minutes = float(data.get("current_time_minutes", data.get("time_minutes", day_start_minutes)))
	current_time_minutes = clampf(current_time_minutes, 0.0, float(day_end_minutes))
	total_played_days = max(1, int(data.get("total_played_days", current_day)))
	
	_minute_accumulator = 0.0
	_last_emitted_hour = int(floor(current_time_minutes / 60.0))
	_last_emitted_minute = int(floor(current_time_minutes))
	_update_phase(false)

	
	day_started.emit(current_day)
	var bus = get_node_or_null("/root/EventBus")
	if bus: bus.day_started.emit(current_day)
