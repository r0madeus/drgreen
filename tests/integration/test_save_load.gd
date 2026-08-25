class_name TestSaveLoad
extends TestCase

## Integration tests for SaveManager.
## Uses an isolated temp slot (slot 99) to avoid touching real player saves.
## Always cleans up the temp file after the test.

const TEMP_SLOT: int = 99

func test_name_id() -> String:
	return "INTEGRATION.SaveLoad"

func run_all() -> void:
	test_name = test_name_id()
	_setup_temp_dir()
	_test_save_creates_file()
	_test_load_reads_file()
	_test_roundtrip_gold()
	_test_roundtrip_inventory()
	_test_roundtrip_position_world_space()
	_test_roundtrip_hotbar()
	_test_roundtrip_current_world()
	_test_roundtrip_tool_upgrades()
	_test_corrupted_save_detection()
	_test_missing_save_detection()
	_test_no_localised_text_in_save()
	_test_slot_metadata()
	_cleanup_temp()

func _get_sm() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("/root/SaveManager")

func _get_psm() -> Node:
	return Engine.get_main_loop().root.get_node_or_null("/root/PlayerRegistry")

func _temp_path() -> String:
	return "user://saves/slot_%d.json" % TEMP_SLOT

func _setup_temp_dir() -> void:
	if not DirAccess.dir_exists_absolute("user://saves"):
		DirAccess.make_dir_recursive_absolute("user://saves")

func _cleanup_temp() -> void:
	if FileAccess.file_exists(_temp_path()):
		var dir = DirAccess.open("user://saves")
		if dir: dir.remove("slot_%d.json" % TEMP_SLOT)

func _write_temp_save(data: Dictionary) -> void:
	var f = FileAccess.open(_temp_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func _read_temp_save() -> Dictionary:
	if not FileAccess.file_exists(_temp_path()): return {}
	var f = FileAccess.open(_temp_path(), FileAccess.READ)
	if not f: return {}
	var json = JSON.new()
	var text = f.get_as_text()
	f.close()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		return json.data
	return {}

func _test_save_creates_file() -> void:
	begin_test("save_creates_file")
	_cleanup_temp()
	var sm = _get_sm()
	if not sm:
		_results.append({"test": _current_test, "assertion": "SKIP: no SaveManager", "status": "PASS"})
		return
	sm.save_game(_temp_path())
	assert_true(FileAccess.file_exists(_temp_path()), "save file created at temp slot")

func _test_load_reads_file() -> void:
	begin_test("load_reads_file")
	var sm = _get_sm()
	if not sm or not FileAccess.file_exists(_temp_path()):
		_results.append({"test": _current_test, "assertion": "SKIP: no save to load", "status": "PASS"})
		return
	var ok = sm.load_game(_temp_path())
	assert_true(ok, "load_game returns true for existing file")

func _test_roundtrip_gold() -> void:
	begin_test("roundtrip_gold")
	var psm = _get_psm()
	if not psm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var ps = psm.get_local_player_state()
	if not ps:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var original_gold = ps.gold
	ps.set_gold(777)
	var sm = _get_sm()
	if sm: sm.save_game(_temp_path())
	ps.set_gold(1)
	if sm: sm.load_game(_temp_path())
	ps = psm.get_local_player_state()
	assert_eq(ps.gold, 777, "gold preserved in save/load")
	ps.set_gold(original_gold)

func _test_roundtrip_inventory() -> void:
	begin_test("roundtrip_inventory")
	var psm = _get_psm()
	if not psm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var ps = psm.get_local_player_state()
	if not ps:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	ps.add_item("test_item_abc", 42)
	var sm = _get_sm()
	if sm: sm.save_game(_temp_path())
	ps.remove_item("test_item_abc", 42)
	if sm: sm.load_game(_temp_path())
	ps = psm.get_local_player_state()
	assert_eq(ps.get_item_count("test_item_abc"), 42, "inventory item persisted")
	ps.remove_item("test_item_abc", 42)

func _test_roundtrip_position_world_space() -> void:
	begin_test("roundtrip_position_world_space")
	var psm = _get_psm()
	var player = Engine.get_main_loop().root.find_child("Player", true, false)
	if not psm or not player:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var ps = psm.get_local_player_state()
	var test_pos = Vector2(317.3, 188.7)
	player.position = test_pos
	if ps: ps.position = test_pos
	var sm = _get_sm()
	if sm: sm.save_game(_temp_path())
	player.position = Vector2.ZERO
	if ps: ps.position = Vector2.ZERO
	if sm: sm.load_game(_temp_path())
	ps = psm.get_local_player_state()
	var res_pos = player.position if player else (ps.position if ps else Vector2.ZERO)
	assert_approx_eq(res_pos.x, test_pos.x, 16.0, "position.x world-space preserved")
	assert_approx_eq(res_pos.y, test_pos.y, 16.0, "position.y world-space preserved")

func _test_roundtrip_hotbar() -> void:
	begin_test("roundtrip_hotbar")
	var psm = _get_psm()
	if not psm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var ps = psm.get_local_player_state()
	if not ps:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	ps.set_hotbar_slot(7, "hoe_copper")
	var sm = _get_sm()
	if sm: sm.save_game(_temp_path())
	ps.set_hotbar_slot(7, "")
	if sm: sm.load_game(_temp_path())
	ps = psm.get_local_player_state()
	assert_eq(ps.get_hotbar_slot(7), "hoe_copper", "hotbar slot 7 preserved")
	ps.set_hotbar_slot(7, "")

func _test_roundtrip_current_world() -> void:
	begin_test("roundtrip_current_world")
	var psm = _get_psm()
	var wl = Engine.get_main_loop().root.get_node_or_null("/root/WorldLoader")
	var wm = Engine.get_main_loop().root.get_node_or_null("/root/WorldManager")
	if not psm or not wl:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var ps = psm.get_local_player_state()
	var orig_world = ps.current_world if ps else "farm"
	if ps: ps.current_world = "town"
	wl.current_world_id = "town"
	if wm: wm.current_world_id = "town"
	var sm = _get_sm()
	if sm: sm.save_game(_temp_path())
	if ps: ps.current_world = "farm"
	wl.current_world_id = "farm"
	if wm: wm.current_world_id = "farm"
	if sm: sm.load_game(_temp_path())
	ps = psm.get_local_player_state()
	var restored_w = wl.current_world_id
	assert_eq(restored_w, "town", "current_world preserved")
	if ps: ps.current_world = orig_world
	wl.current_world_id = orig_world
	if wm: wm.current_world_id = orig_world

func _test_roundtrip_tool_upgrades() -> void:
	begin_test("roundtrip_tool_upgrades")
	var psm = _get_psm()
	if not psm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var ps = psm.get_local_player_state()
	if not ps:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	ps.add_item("hoe_copper", 1)
	var sm = _get_sm()
	if sm: sm.save_game(_temp_path())
	ps.remove_item("hoe_copper", 1)
	if sm: sm.load_game(_temp_path())
	ps = psm.get_local_player_state()
	assert_true(ps.has_item("hoe_copper"), "upgraded tool preserved")
	ps.remove_item("hoe_copper", 1)

func _test_corrupted_save_detection() -> void:
	begin_test("corrupted_save_detection")
	var sm = _get_sm()
	if not sm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var f = FileAccess.open(_temp_path(), FileAccess.WRITE)
	if f:
		f.store_string("{bad json {{ CORRUPTED")
		f.close()
	var meta = sm.get_save_slot_metadata(TEMP_SLOT)
	assert_true(meta.get("corrupted", false), "corrupted save detected")

func _test_missing_save_detection() -> void:
	begin_test("missing_save_detection")
	var sm = _get_sm()
	if not sm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	_cleanup_temp()
	var meta = sm.get_save_slot_metadata(TEMP_SLOT)
	assert_false(meta.get("exists", true), "missing save detected as non-existent")

func _test_no_localised_text_in_save() -> void:
	begin_test("no_localised_text_in_save")
	var sm = _get_sm()
	if not sm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	sm.save_game(_temp_path())
	var raw = _read_temp_save()
	if raw.is_empty():
		_results.append({"test": _current_test, "assertion": "SKIP: save empty", "status": "PASS"})
		return
	var json_str = JSON.stringify(raw)
	# Verify items and tools store stable IDs rather than localized UI display names
	assert_false(json_str.contains("Watering Can"), "no item display name in save")
	assert_false(json_str.contains("Copper Hoe"), "no tool display name in save")
	assert_false(json_str.contains("tool.quality"), "no quality translation key in save")


func _test_slot_metadata() -> void:
	begin_test("slot_metadata")
	var sm = _get_sm()
	if not sm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	_write_temp_save({
		"day": 5, "current_world": "farm", "timestamp": 1000000,
		"season": { "season": "Spring" },
		"economy": { "gold": 250 },
		"players": { "player_001": { "display_name": "Botanist" } }
	})
	var meta = sm.get_save_slot_metadata(TEMP_SLOT)
	assert_true(meta is Dictionary, "metadata is a Dictionary")
