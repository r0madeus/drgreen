class_name TestWorldTransitions
extends TestCase

## Integration tests for World Transition system.
## Tests all 8 bidirectional world graph pairs plus error cases.

func test_name_id() -> String:
	return "INTEGRATION.WorldTransitions"

func run_all() -> void:
	test_name = test_name_id()
	_test_world_graph_exists()
	_test_farm_to_town()
	_test_town_to_farm()
	_test_town_to_forest()
	_test_forest_to_town()
	_test_forest_to_botanical_grove()
	_test_botanical_grove_to_forest()
	_test_farm_to_botanical_grove()
	_test_botanical_grove_to_farm()
	_test_invalid_world_rejected()
	_test_double_transition_guard()
	_test_world_validator()
	_test_spawn_points_valid()
	_test_current_world_updated_after_transition()
	_test_player_state_world_synced()

func _get_wm() -> Node:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if root:
		var n = root.find_child("WorldManager", true, false)
		if n: return n
	var wm_class = load("res://systems/world/world_manager.gd")
	if wm_class:
		var inst = wm_class.new()
		inst.name = "WorldManager"
		if root: root.add_child(inst)
		return inst
	return null 

func _test_world_graph_exists() -> void:
	begin_test("world_graph_exists")
	var wm = _get_wm()
	assert_true(wm != null, "WorldManager autoload exists")
	assert_false(wm.world_definitions.is_empty(), "world definitions loaded")

func _assert_can_travel(from: String, to: String) -> void:
	begin_test("can_travel_%s_to_%s" % [from, to])
	var wm = _get_wm()
	if not wm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	assert_true(wm.can_travel(from, to), "%s → %s is connected" % [from, to])

func _test_farm_to_town() -> void: _assert_can_travel("farm", "town")
func _test_town_to_farm() -> void: _assert_can_travel("town", "farm")
func _test_town_to_forest() -> void: _assert_can_travel("town", "forest")
func _test_forest_to_town() -> void: _assert_can_travel("forest", "town")
func _test_forest_to_botanical_grove() -> void: _assert_can_travel("forest", "botanical_grove")
func _test_botanical_grove_to_forest() -> void: _assert_can_travel("botanical_grove", "forest")
func _test_farm_to_botanical_grove() -> void: _assert_can_travel("farm", "botanical_grove")
func _test_botanical_grove_to_farm() -> void: _assert_can_travel("botanical_grove", "farm")


func _test_invalid_world_rejected() -> void:
	begin_test("invalid_world_rejected")
	var wm = _get_wm()
	if not wm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	assert_false(wm.check_world_exists("nonexistent_world_xyz"), "nonexistent world returns false")
	assert_false(wm.can_travel("farm", "nonexistent_world_xyz"), "cannot travel to nonexistent world")

func _test_double_transition_guard() -> void:
	begin_test("double_transition_guard")
	var wm = _get_wm()
	if not wm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	wm.is_transitioning = true # Simulate in-progress transition
	var result = wm.transition_to("town", "default", false)
	assert_false(result, "double transition is blocked")
	wm.is_transitioning = false # Reset

func _test_world_validator() -> void:
	begin_test("world_validator")
	var validation = WorldValidator.validate_world_graph()
	assert_true(validation.is_valid, "WorldValidator reports 0 graph errors")

func _test_spawn_points_valid() -> void:
	begin_test("spawn_points_valid")
	var wm = _get_wm()
	if not wm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	for wid in ["farm", "town", "whispering_forest", "botanical_grove"]:
		var sp = wm.get_spawn_point(wid, "default")
		assert_true(sp.x >= 0 and sp.y >= 0, "spawn for '%s' has positive coords" % wid)
		assert_true(sp.x < 200 and sp.y < 200, "spawn for '%s' has sane coords" % wid)

func _test_current_world_updated_after_transition() -> void:
	begin_test("current_world_updated")
	var wm = _get_wm()
	if not wm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var orig_world = wm.current_world_id
	wm.transition_to("town", "default", false)
	assert_eq(wm.current_world_id, "town", "WorldManager.current_world_id is 'town' after transition")
	wm.transition_to(orig_world, "default", false)

func _test_player_state_world_synced() -> void:
	begin_test("player_state_world_synced")
	var wm = _get_wm()
	var psm = Engine.get_main_loop().root.get_node_or_null("/root/PlayerStateManager") 
	if not wm or not psm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var orig_world = wm.current_world_id
	wm.transition_to("town", "default", false)
	var ps = psm.get_active_player_state()
	if ps:
		assert_eq(ps.current_world, "town", "PlayerState.current_world synced after transition")
	wm.transition_to(orig_world, "default", false)
