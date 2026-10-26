extends TestCase

var player_a: PlayerState
var player_b: PlayerState
var net_synthesis: Node
var world_manager: Node
var event_bus: Node
var mock_ng: Node

func _setup_test() -> void:
	var tree = Engine.get_main_loop() as SceneTree
	
	var nm = tree.root.get_node_or_null("NetworkManager")
	if not nm:
		nm = Node.new()
		nm.name = "NetworkManager"
		tree.root.add_child(nm)
		
	var nm_script = GDScript.new()
	nm_script.source_code = """
extends Node
func is_host() -> bool: return true
func is_offline() -> bool: return true
func get_local_peer_id() -> int: return 1
"""
	nm_script.reload()
	nm.set_script(nm_script)
	
	if not Engine.has_singleton("EventBus"):
		var eb = Node.new()
		eb.name = "EventBus"
		tree.root.add_child(eb)
		event_bus = eb
		
	if not Engine.has_singleton("WorldManager"):
		var wm_script = load("res://systems/world/world_manager.gd")
		if wm_script:
			world_manager = wm_script.new()
			world_manager.name = "WorldManager"
			tree.root.add_child(world_manager)
		
	if not Engine.has_singleton("CombinationManager"):
		var cm_script = load("res://systems/combination/combination_manager.gd")
		if cm_script:
			var cm = cm_script.new()
			cm.name = "CombinationManager"
			tree.root.add_child(cm)
		
	var ns_script = load("res://systems/network/network_synthesis.gd")
	if ns_script:
		net_synthesis = ns_script.new()
		net_synthesis.name = "NetworkSynthesis"
		tree.root.add_child(net_synthesis)

	player_a = PlayerState.new("player_A", "Alice")
	player_a.home_owner_id = "player_A"
	player_b = PlayerState.new("player_B", "Bob")
	player_b.home_owner_id = "player_B"
	
	# Mock NetworkGameplay for player state lookup
	var old_ng = tree.root.get_node_or_null("NetworkGameplay")
	if old_ng:
		tree.root.remove_child(old_ng)
		old_ng.queue_free()

	mock_ng = Node.new()
	mock_ng.name = "NetworkGameplay"
	
	var script_src = """
extends Node
var states = {}
func _get_player_state_for_peer(peer_id: int):
	if peer_id == 1: return states.get("player_A")
	if peer_id == 2: return states.get("player_B")
	return null
"""
	var ng_script = GDScript.new()
	ng_script.source_code = script_src
	ng_script.reload()
	mock_ng.set_script(ng_script)
	mock_ng.set("states", {"player_A": player_a, "player_B": player_b})
	tree.root.add_child(mock_ng)

func _teardown_test() -> void:
	if is_instance_valid(net_synthesis): net_synthesis.queue_free()
	if is_instance_valid(world_manager): world_manager.queue_free()
	if is_instance_valid(mock_ng): mock_ng.queue_free()

func _test_T01_owner_access_allowed() -> void:
	begin_test("T01_owner_access_allowed")
	if not net_synthesis:
		assert_false(true, "Setup failed")
		return
		
	var err_state = {"received": false}
	var on_err = func(r): err_state.received = true
	net_synthesis.synthesis_error.connect(on_err)
	
	net_synthesis.host_synthesis(1, "laboratory:player_A", "seed_tomato", "seed_corn")
	
	assert_ne(err_state.get("reason", ""), "ACCESS_DENIED", "Owner should be allowed to access their own lab")
	net_synthesis.synthesis_error.disconnect(on_err)

func _test_T02_cross_access_denied() -> void:
	begin_test("T02_cross_access_denied")
	if not net_synthesis: return
	var err_state = {"reason": ""}
	var on_err = func(r): err_state.reason = r
	net_synthesis.synthesis_error.connect(on_err)
	
	# Peer 2 (Bob) tries to access Alice's lab
	net_synthesis.host_synthesis(2, "laboratory:player_A", "seed_tomato", "seed_corn")
	
	assert_eq(err_state.reason, "ACCESS_DENIED", "Player B must be denied access to Player A's lab")
	
	net_synthesis.synthesis_error.disconnect(on_err)

func _test_T03_missing_player_rejected() -> void:
	begin_test("T03_missing_player_rejected")
	if not net_synthesis: return
	var err_state = {"reason": ""}
	var on_err = func(r): err_state.reason = r
	net_synthesis.synthesis_error.connect(on_err)
	
	# Peer 3 (Unknown) tries to access
	net_synthesis.host_synthesis(3, "laboratory:player_A", "seed_tomato", "seed_corn")
	
	assert_eq(err_state.reason, "INVALID_PLAYER", "Unknown peer must be rejected")
	
	net_synthesis.synthesis_error.disconnect(on_err)

func run_all() -> void:
	_setup_test()
	_test_T01_owner_access_allowed()
	_test_T02_cross_access_denied()
	_test_T03_missing_player_rejected()
	_teardown_test()
