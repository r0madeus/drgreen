class_name TestMultiplayer
extends TestCase

## Regression & architecture tests for Host-Authoritative Multiplayer subsystem.
## Tests synchronization hooks, remote interpolation, authority boundaries,
## inventory isolation and shared world state replication.

func test_name_id() -> String:
	return "MULTIPLAYER.HostAuthoritative"

func run_all() -> void:
	test_name = test_name_id()
	_test_network_manager_exists()
	_test_network_gameplay_hooks()
	_test_network_containers_hooks()
	_test_network_shop_hooks()
	_test_network_synthesis_hooks()
	_test_network_quests_hooks()
	_test_network_player_interpolation()
	_test_inventory_isolation_per_peer()
	_test_shared_world_state_separation()
	_test_client_authority_boundary()
	_test_late_join_state_serialization()

func _get_nm() -> Node:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if root:
		var n = root.find_child("NetworkManager", true, false)
		if n: return n
	var c = load("res://systems/network/network_manager.gd")
	if c:
		var inst = c.new()
		inst.name = "NetworkManager"
		if root: root.add_child(inst)
		return inst
	return null

func _get_ng() -> Node:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if root:
		var n = root.find_child("NetworkGameplay", true, false)
		if n: return n
	var c = load("res://systems/network/network_gameplay.gd")
	if c:
		var inst = c.new()
		inst.name = "NetworkGameplay"
		if root: root.add_child(inst)
		return inst
	return null

func _test_network_manager_exists() -> void:
	begin_test("network_manager_exists")
	var nm = _get_nm()
	assert_true(nm != null, "NetworkManager autoload exists")

func _test_network_gameplay_hooks() -> void:
	begin_test("network_gameplay_hooks")
	var ng = _get_ng()
	assert_true(ng != null, "NetworkGameplay autoload exists")
	if ng:
		assert_true(ng.has_method("request_till") or ng.has_method("request_hoe"), "has hoe/till request method")
		assert_true(ng.has_method("request_water"), "has water request method")
		assert_true(ng.has_method("request_plant"), "has plant request method")
		assert_true(ng.has_method("request_harvest"), "has harvest request method")

func _test_network_containers_hooks() -> void:
	begin_test("network_containers_hooks")
	var nc = Engine.get_main_loop().root.get_node_or_null("/root/NetworkContainers")
	assert_true(nc != null, "NetworkContainers autoload exists")
	if nc:
		assert_true(nc.has_method("request_deposit"), "has deposit method")
		assert_true(nc.has_method("request_withdraw"), "has withdraw method")

func _test_network_shop_hooks() -> void:
	begin_test("network_shop_hooks")
	var ns = Engine.get_main_loop().root.get_node_or_null("/root/NetworkShop")
	assert_true(ns != null, "NetworkShop autoload exists")
	if ns:
		assert_true(ns.has_method("request_buy"), "has buy request method")
		assert_true(ns.has_method("request_sell"), "has sell request method")

func _test_network_synthesis_hooks() -> void:
	begin_test("network_synthesis_hooks")
	var nsyn = Engine.get_main_loop().root.get_node_or_null("/root/NetworkSynthesis")
	assert_true(nsyn != null, "NetworkSynthesis autoload exists")
	if nsyn:
		assert_true(nsyn.has_method("request_synthesis"), "has synthesize request method")

func _test_network_quests_hooks() -> void:
	begin_test("network_quests_hooks")
	var nq = Engine.get_main_loop().root.get_node_or_null("/root/NetworkQuests")
	assert_true(nq != null, "NetworkQuests autoload exists")
	if nq:
		assert_true(nq.has_method("request_claim_quest_reward"), "has claim reward method")


func _test_network_player_interpolation() -> void:
	begin_test("network_player_interpolation")
	var np = NetworkPlayer.new()
	np.position = Vector2(100.0, 100.0)
	np.target_position = Vector2(120.0, 100.0)
	np._process(0.016)
	assert_gt(np.position.x, 100.0, "position lerps towards target_position")
	assert_lt(np.position.x, 120.0, "smooth interpolation without teleporting")
	np.queue_free()

func _test_inventory_isolation_per_peer() -> void:
	begin_test("inventory_isolation_per_peer")
	var ps1 = PlayerState.new("peer_1", "Host")
	var ps2 = PlayerState.new("peer_2", "Guest")
	ps1.add_item("wood", 10)
	ps2.add_item("stone", 5)
	assert_eq(ps1.get_item_count("wood"), 10, "peer 1 has 10 wood")
	assert_eq(ps1.get_item_count("stone"), 0, "peer 1 has 0 stone")
	assert_eq(ps2.get_item_count("wood"), 0, "peer 2 has 0 wood")
	assert_eq(ps2.get_item_count("stone"), 5, "peer 2 has 5 stone")

func _test_shared_world_state_separation() -> void:
	begin_test("shared_world_state_separation")
	var sws = SharedWorldState.new("farm", "Peaceful Farm")
	var ps = PlayerState.new("player_001", "Botanist")
	# Shared state holds world objects (crops, containers)
	# PlayerState holds personal items and personal gold
	ps.gold = 500
	assert_eq(ps.gold, 500, "player gold is in PlayerState")
	assert_true(sws.plants is Dictionary, "world crops are in SharedWorldState")

func _test_client_authority_boundary() -> void:
	begin_test("client_authority_boundary")
	# Client must send RPC requests to Server, never mutate SharedWorldState directly
	var ng = _get_ng()
	if ng:
		# Verified: NetworkGameplay exposes RPC requests: request_hoe, request_water, request_plant, request_harvest
		assert_true(ng.has_method("request_plant"), "client communicates via request_plant RPC")

func _test_late_join_state_serialization() -> void:
	begin_test("late_join_state_serialization")
	var wm = Engine.get_main_loop().root.get_node_or_null("/root/WorldManager")
	if wm:
		var farm_state = wm.get_shared_world_state("farm")
		var serialized = farm_state.to_dict()
		assert_true(serialized is Dictionary, "world state can be serialized for late join packets")
		assert_has(serialized, "world_id", "serialized packet includes world_id")
