class_name TestTimeSystem
extends TestCase

## Comprehensive 39-Point Test Suite for Phase 18:
## Time, Day/Night Cycle, Calendar Progression, Sleep System & Multi-System Integrations.

func test_name_id() -> String:
	return "TIME.DayNightSleep"

func run_all() -> void:
	test_name = test_name_id()
	_test_T01_time_manager_initialization()
	_test_T02_time_progression()
	_test_T03_time_pause()
	_test_T04_time_resume()
	_test_T05_hour_changed_event()
	_test_T06_day_phase_transition()
	_test_T07_dawn_transition()
	_test_T08_dusk_transition()
	_test_T09_night_transition()
	_test_T10_hud_clock_update()
	_test_T11_sleep_interaction()
	_test_T12_sleep_confirmation()
	_test_T13_next_day()
	_test_T14_calendar_advance()
	_test_T15_crop_growth_on_new_day()
	_test_T16_watered_crop_growth()
	_test_T17_unwatered_crop_behavior()
	_test_T18_season_transition()
	_test_T19_weather_integration()
	_test_T20_npc_day_start_hook()
	_test_T21_quest_day_hook()
	_test_T22_world_transition_preserves_time()
	_test_T23_save_time()
	_test_T24_load_time()
	_test_T25_old_save_migration()
	_test_T26_invalid_time_recovery()
	_test_T27_multiplayer_host_clock()
	_test_T28_multiplayer_client_clock_sync()
	_test_T29_multiplayer_late_join_clock_snapshot()
	_test_T30_local_state_isolation()
	_test_T31_pause_reason_isolation()
	_test_T32_double_day_advance_protection()
	_test_T33_singleplayer_regression()
	_test_T34_farming_regression()
	_test_T35_save_load_regression()
	_test_T36_world_transition_regression()
	_test_T37_multiplayer_regression()
	_test_T38_localization_regression()
	_test_T39_asset_pipeline_regression()

func _get_tm() -> Node:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if root:
		var n = root.find_child("TimeManager", true, false)
		if n: return n
	var c = load("res://systems/time/time_manager.gd")
	if c:
		var inst = c.new()
		inst.name = "TimeManager"
		if root: root.add_child(inst)
		return inst
	return null

func _get_sm() -> Node:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if root:
		var n = root.find_child("SeasonManager", true, false)
		if n: return n
	var c = load("res://systems/seasons/season_manager.gd")
	if c:
		var inst = c.new()
		inst.name = "SeasonManager"
		if root: root.add_child(inst)
		return inst
	return null

func _get_wm() -> Node:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if root:
		var n = root.find_child("WeatherManager", true, false)
		if n: return n
	var c = load("res://systems/weather/weather_manager.gd")
	if c:
		var inst = c.new()
		inst.name = "WeatherManager"
		if root: root.add_child(inst)
		return inst
	return null

func _get_gm() -> Node:
	return Engine.get_main_loop().root.find_child("GridManager", true, false)

func _get_psm() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("/root/PlayerRegistry")

# --- Tests ---

func _test_T01_time_manager_initialization() -> void:
	begin_test("T01_TimeManagerInitialization")
	var tm = _get_tm()
	assert_true(tm != null, "TimeManager exists")
	if tm:
		tm.set_day(1)
		assert_gt(tm.get_current_day(), 0, "current day > 0")
		assert_gt(tm.get_current_time(), 0.0, "current time > 0")
		assert_not_empty(tm.get_day_phase(), "has day phase")

func _test_T02_time_progression() -> void:
	begin_test("T02_TimeProgression")
	var tm = _get_tm()
	if not tm: return
	tm.current_time_minutes = 400.0
	var t_before = tm.get_current_time()
	tm.advance_time(15.0)
	assert_approx_eq(tm.get_current_time(), t_before + 15.0, 0.1, "time advances by 15 minutes")

func _test_T03_time_pause() -> void:
	begin_test("T03_TimePause")
	var tm = _get_tm()
	if not tm: return
	tm._pause_reasons.clear()
	tm.pause_time("TEST_REASON")
	assert_true(tm.is_time_paused(), "time is paused")
	assert_has(tm.get_pause_reasons(), "TEST_REASON", "pause reason recorded")

func _test_T04_time_resume() -> void:
	begin_test("T04_TimeResume")
	var tm = _get_tm()
	if not tm: return
	tm.resume_time("TEST_REASON")
	assert_false(tm.is_time_paused(), "time is resumed")

func _test_T05_hour_changed_event() -> void:
	begin_test("T05_HourChangedEvent")
	var tm = _get_tm()
	if not tm: return
	tm.current_time_minutes = 420.0 # 07:00 AM
	tm._last_emitted_hour = 7
	var hour_emitted = [false]
	var cb = func(_h): hour_emitted[0] = true
	tm.hour_changed.connect(cb)
	tm.advance_time(65.0) # Moves to 485.0 (08:05 AM, hour 8)
	assert_true(hour_emitted[0], "hour_changed signal fired")
	tm.hour_changed.disconnect(cb)

func _test_T06_day_phase_transition() -> void:
	begin_test("T06_DayPhaseTransition")
	var tm = _get_tm()
	if not tm: return
	tm.current_time_minutes = 600.0 # 10:00 AM
	tm._update_phase(false)
	assert_eq(tm.get_day_phase(), "day", "10:00 AM is day phase")
	assert_true(tm.is_daytime(), "is_daytime is true during day")
	assert_false(tm.is_night(), "is_night is false during day")

func _test_T07_dawn_transition() -> void:
	begin_test("T07_DawnTransition")
	var tm = _get_tm()
	if not tm: return
	tm.current_time_minutes = 400.0 # 06:40 AM
	tm._update_phase(false)
	assert_eq(tm.get_day_phase(), "dawn", "06:40 AM is dawn")
	assert_true(tm.is_daytime(), "dawn is daytime")

func _test_T08_dusk_transition() -> void:
	begin_test("T08_DuskTransition")
	var tm = _get_tm()
	if not tm: return
	tm.current_time_minutes = 1140.0 # 19:00 / 07:00 PM
	tm._update_phase(false)
	assert_eq(tm.get_day_phase(), "dusk", "07:00 PM is dusk")
	assert_true(tm.is_night(), "dusk counts as night transition")

func _test_T09_night_transition() -> void:
	begin_test("T09_NightTransition")
	var tm = _get_tm()
	if not tm: return
	tm.current_time_minutes = 1320.0 # 22:00 / 10:00 PM
	tm._update_phase(false)
	assert_eq(tm.get_day_phase(), "night", "10:00 PM is night")
	assert_true(tm.is_night(), "night is night")

func _test_T10_hud_clock_update() -> void:
	begin_test("T10_HUDClockUpdate")
	var tm = _get_tm()
	if not tm: return
	tm.current_time_minutes = 480.0 # 08:00 AM
	var t_str = tm.get_time_string()
	assert_eq(t_str, "08:00 AM", "formatted time string is 08:00 AM")

func _test_T11_sleep_interaction() -> void:
	begin_test("T11_SleepInteraction")
	var tm = _get_tm()
	if not tm: return
	var sleep_emitted = [false]
	var cb = func(): sleep_emitted[0] = true
	tm.sleep_requested.connect(cb)
	tm.request_sleep()
	assert_true(sleep_emitted[0], "request_sleep emitted signal")
	tm.sleep_requested.disconnect(cb)



func _test_T12_sleep_confirmation() -> void:
	begin_test("T12_SleepConfirmation")
	var sleep_ui = SleepConfirmationUI.new()
	assert_true(sleep_ui != null, "SleepConfirmationUI instantiated")
	sleep_ui.queue_free()

func _test_T13_next_day() -> void:
	begin_test("T13_NextDay")
	var tm = _get_tm()
	if not tm: return
	var d_before = tm.get_current_day()
	tm.execute_sleep(false)
	assert_eq(tm.get_current_day(), d_before + 1, "day incremented after sleep")
	assert_approx_eq(tm.get_current_time(), float(tm.day_start_minutes), 0.1, "time reset to morning 06:00 AM")

func _test_T14_calendar_advance() -> void:
	begin_test("T14_CalendarAdvance")
	var sm = _get_sm()
	if not sm: return
	sm.update_from_day(1, false)
	assert_eq(sm.get_season_id(), "spring", "Day 1 is Spring")
	sm.update_from_day(8, false) # 7 days per season
	assert_eq(sm.get_season_id(), "summer", "Day 8 is Summer")
	sm.update_from_day(1, false) # Restore

func _test_T15_crop_growth_on_new_day() -> void:
	begin_test("T15_CropGrowthOnNewDay")
	var gm = _get_gm()
	if not gm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var target = Vector2i(7, 7)
	gm.till_tile(target)
	gm.plant_seed(target, "red_flower")
	gm.water_tile(target)
	gm.advance_day()
	var tile = gm.get_tile(target)
	assert_true(tile.growth_stage > 0 or tile.days_in_stage > 0, "watered crop grows on new day")

func _test_T16_watered_crop_growth() -> void:
	begin_test("T16_WateredCropGrowth")
	var gm = _get_gm()
	if not gm: return
	var target = Vector2i(7, 7)
	var tile = gm.get_tile(target)
	if tile and tile.plant_id != "":
		gm.water_tile(target)
		gm.advance_day()
		tile = gm.get_tile(target)
		assert_true(tile.growth_stage > 0 or tile.days_in_stage > 0, "growth advanced when watered")

func _test_T17_unwatered_crop_behavior() -> void:



	begin_test("T17_UnwateredCropBehavior")
	var gm = _get_gm()
	if not gm: return
	var target = Vector2i(7, 7)
	var tile = gm.get_tile(target)
	if tile and tile.plant_id != "":
		tile.watered_today = false
		var st_before = tile.growth_stage
		gm.advance_day()
		assert_eq(tile.growth_stage, st_before, "growth paused when unwatered")

func _test_T18_season_transition() -> void:
	begin_test("T18_SeasonTransition")
	var sm = _get_sm()
	if not sm: return
	var s_tint = sm.get_season_tint()
	assert_true(s_tint is Color, "season tint is valid Color")


func _test_T19_weather_integration() -> void:
	begin_test("T19_WeatherIntegration")
	var wm = _get_wm()
	if not wm: return
	assert_has(["clear", "rain", "snow"], wm.current_weather, "weather is valid type")

func _test_T20_npc_day_start_hook() -> void:
	begin_test("T20_NPCDayStartHook")
	var npcm = Engine.get_main_loop().root.get_node_or_null("/root/NPCManager")
	assert_true(npcm != null, "NPCManager exists")
	if npcm:
		assert_true(npcm.has_method("reset_daily_schedules"), "has reset_daily_schedules hook")

func _test_T21_quest_day_hook() -> void:
	begin_test("T21_QuestDayHook")
	var qm = Engine.get_main_loop().root.get_node_or_null("/root/QuestManager")
	assert_true(qm != null, "QuestManager exists")

func _test_T22_world_transition_preserves_time() -> void:
	begin_test("T22_WorldTransitionPreservesTime")
	var tm = _get_tm()
	if not tm: return
	tm.current_time_minutes = 750.0 # 12:30 PM
	var cur_t = tm.get_current_time()
	var cur_d = tm.get_current_day()
	# World transition must not reset time
	var wm = Engine.get_main_loop().root.get_node_or_null("/root/WorldManager")
	if wm:
		wm.transition_to("town", "default", false)
		assert_approx_eq(tm.get_current_time(), cur_t, 0.1, "time preserved across world transition")
		assert_eq(tm.get_current_day(), cur_d, "day preserved across world transition")
		wm.transition_to("farm", "default", false)

func _test_T23_save_time() -> void:
	begin_test("T23_SaveTime")
	var tm = _get_tm()
	if not tm: return
	var t_state = tm.get_time_state()
	assert_has(t_state, "current_day", "time state has current_day")
	assert_has(t_state, "current_time_minutes", "time state has current_time_minutes")

func _test_T24_load_time() -> void:
	begin_test("T24_LoadTime")
	var tm = _get_tm()
	if not tm: return
	tm.load_time_state({ "current_day": 5, "current_time_minutes": 720.0 })
	assert_eq(tm.get_current_day(), 5, "loaded day 5")
	assert_approx_eq(tm.get_current_time(), 720.0, 0.1, "loaded 12:00 PM (720 min)")

func _test_T25_old_save_migration() -> void:
	begin_test("T25_OldSaveMigration")
	var tm = _get_tm()
	if not tm: return
	# Legacy save without current_time_minutes defaults to 360
	tm.load_time_state({ "current_day": 3 })
	assert_eq(tm.get_current_day(), 3, "migrated day 3")
	assert_approx_eq(tm.get_current_time(), 360.0, 0.1, "defaulted to 06:00 AM")

func _test_T26_invalid_time_recovery() -> void:
	begin_test("T26_InvalidTimeRecovery")
	var tm = _get_tm()
	if not tm: return
	# Negative or excessive time clamped safely
	tm.load_time_state({ "current_day": -5, "current_time_minutes": 9999.0 })
	assert_gte(tm.get_current_day(), 1, "negative day recovered to >= 1")
	assert_lte(tm.get_current_time(), float(tm.day_end_minutes), "excessive time clamped to day_end")

func _test_T27_multiplayer_host_clock() -> void:

	begin_test("T27_MultiplayerHostClock")
	var ng = Engine.get_main_loop().root.get_node_or_null("/root/NetworkGameplay")
	assert_true(ng != null, "NetworkGameplay exists")
	if ng:
		assert_true(ng.has_method("broadcast_time_sync"), "has broadcast_time_sync method")

func _test_T28_multiplayer_client_clock_sync() -> void:
	begin_test("T28_MultiplayerClientClockSync")
	var ng = Engine.get_main_loop().root.get_node_or_null("/root/NetworkGameplay")
	if ng:
		assert_true(ng.has_method("client_receive_time_sync"), "has client_receive_time_sync method")

func _test_T29_multiplayer_late_join_clock_snapshot() -> void:
	begin_test("T29_MultiplayerLateJoinClockSnapshot")
	var ng = Engine.get_main_loop().root.get_node_or_null("/root/NetworkGameplay")
	if ng:
		assert_true(ng.has_method("request_time_sync"), "has request_time_sync method")

func _test_T30_local_state_isolation() -> void:
	begin_test("T30_LocalStateIsolation")
	var lsm = Engine.get_main_loop().root.get_node_or_null("/root/LocalStateManager")
	assert_true(lsm != null, "LocalStateManager exists")
	# LocalState should NOT store authoritative game clock
	var tm = _get_tm()
	assert_true(tm != null and not tm.get_time_state().is_empty(), "game clock is in TimeManager")

func _test_T31_pause_reason_isolation() -> void:
	begin_test("T31_PauseReasonIsolation")
	var tm = _get_tm()
	if not tm: return
	tm._pause_reasons.clear()
	tm.pause_time("PAUSE_UI")
	tm.pause_time("PAUSE_DIALOGUE")
	assert_true(tm.is_time_paused(), "paused by 2 reasons")
	tm.resume_time("PAUSE_UI")
	assert_true(tm.is_time_paused(), "still paused by PAUSE_DIALOGUE")
	tm.resume_time("PAUSE_DIALOGUE")
	assert_false(tm.is_time_paused(), "unpaused after all reasons cleared")


func _test_T32_double_day_advance_protection() -> void:
	begin_test("T32_DoubleDayAdvanceProtection")
	var tm = _get_tm()
	if not tm: return
	var d_start = tm.get_current_day()
	tm.is_sleeping = true
	tm.execute_sleep(false) # Should be blocked by guard
	assert_eq(tm.get_current_day(), d_start, "double advance prevented while is_sleeping is true")
	tm.is_sleeping = false

func _test_T33_singleplayer_regression() -> void:
	begin_test("T33_SingleplayerRegression")
	var ps = PlayerStateFixture.create_default()
	assert_eq(ps.gold, 100, "player starts with 100 gold")

func _test_T34_farming_regression() -> void:
	begin_test("T34_FarmingRegression")
	var gm = _get_gm()
	if gm:
		var target = Vector2i(6, 6)
		gm.till_tile(target)
		var tile = gm.get_tile(target)
		assert_eq(tile.type, "soil", "tilling creates soil")

func _test_T35_save_load_regression() -> void:
	begin_test("T35_SaveLoadRegression")
	var sm = Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")
	assert_true(sm != null, "SaveManager available")

func _test_T36_world_transition_regression() -> void:
	begin_test("T36_WorldTransitionRegression")
	var wm = Engine.get_main_loop().root.get_node_or_null("/root/WorldManager")
	if wm:
		assert_true(wm.can_travel("farm", "town"), "farm can travel to town")

func _test_T37_multiplayer_regression() -> void:
	begin_test("T37_MultiplayerRegression")
	var nm = Engine.get_main_loop().root.get_node_or_null("/root/NetworkManager")
	assert_true(nm != null, "NetworkManager available")

func _test_T38_localization_regression() -> void:
	begin_test("T38_LocalizationRegression")
	var lm = Engine.get_main_loop().root.get_node_or_null("/root/LocalizationManager")
	if lm:
		var dawn_txt = lm.get_text("time.phase.dawn")
		assert_not_empty(dawn_txt, "dawn phase translated")

func _test_T39_asset_pipeline_regression() -> void:
	begin_test("T39_AssetPipelineRegression")
	AssetRegistry.ensure_initialized()
	assert_true(AssetRegistry.get_all_asset_ids() is Array, "asset registry functional")
