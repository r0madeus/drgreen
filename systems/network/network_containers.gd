extends Node
## Host-authoritative shared container (chest) synchronization.
## Containers are part of SharedWorldState.containers.
## Clients never mutate containers directly.

signal container_snapshot_received(container_id: String, items: Dictionary)
signal container_updated_local(container_id: String, items: Dictionary)
signal container_error(reason: String)

const MAX_RANGE_SQ: float = 36.0
const DEFAULT_CAPACITY: int = 20

# Track which containers each local peer has open (for update routing)
var _open_containers: Dictionary = {} # peer_id -> container_id

func is_host() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_host() if nm else true

func is_offline() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_offline() if nm else true

func get_local_peer_id() -> int:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.get_local_peer_id() if nm else 1

func has_container(world_id: String, pos: Vector2i) -> bool:
	var state = _get_world_state(world_id)
	var cid = "chest_%d_%d" % [pos.x, pos.y]
	return state != null and state.containers.has(cid)

func open_container(world_id: String, pos: Vector2i) -> void:
	var cid = "chest_%d_%d" % [pos.x, pos.y]
	request_open_container(world_id, cid)

func request_open_container(world_id: String, container_id: String) -> void:

	if is_offline():
		_local_open_container(world_id, container_id)
		return
	rpc("host_open_container", get_local_peer_id(), world_id, container_id)

func request_deposit(world_id: String, container_id: String, item_id: String, quantity: int) -> void:
	if is_offline():
		_local_deposit(world_id, container_id, item_id, quantity)
		return
	rpc("host_deposit", get_local_peer_id(), world_id, container_id, item_id, quantity)

func request_withdraw(world_id: String, container_id: String, item_id: String, quantity: int) -> void:
	if is_offline():
		_local_withdraw(world_id, container_id, item_id, quantity)
		return
	rpc("host_withdraw", get_local_peer_id(), world_id, container_id, item_id, quantity)

func request_close_container(container_id: String) -> void:
	if is_offline(): return
	rpc("host_close_container", get_local_peer_id(), container_id)

# ---------------------------------------------------------------
# HOST VALIDATION HELPERS
# ---------------------------------------------------------------

func _get_world_state(world_id: String) -> SharedWorldState:
	var wm = get_node_or_null("/root/WorldManager")
	return wm.get_shared_world_state(world_id) if wm else null

func _get_player_state(peer_id: int) -> PlayerState:
	var ng = get_node_or_null("/root/NetworkGameplay")
	return ng._get_player_state_for_peer(peer_id) if ng else null

func _send_error(peer_id: int, reason: String) -> void:
	if peer_id == 1 or is_offline() or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(peer_id):
		container_error.emit(reason)
		var spawner = EffectSpawner.get_instance()
		var player = get_tree().root.find_child("Player", true, false)
		var pos2 = player.global_position if player else Vector2(240, 180)
		if spawner: spawner.spawn_floating_text(pos2, "❌ %s" % reason, Color(1.0, 0.4, 0.4))
	else:
		rpc_id(peer_id, "client_receive_container_error", reason)

func _broadcast_container_update(world_id: String, container_id: String, items: Dictionary) -> void:
	# Only broadcast to peers in the same world
	var nm = get_node_or_null("/root/NetworkManager")
	if not nm or is_offline():
		client_receive_container_update(world_id, container_id, items)
		return
	rpc("client_receive_container_update", world_id, container_id, items)

# ---------------------------------------------------------------
# HOST RPC HANDLERS
# ---------------------------------------------------------------

@rpc("any_peer", "call_local", "reliable")
func host_open_container(requester_peer: int, world_id: String, container_id: String) -> void:
	if not is_host(): return
	var ws = _get_world_state(world_id)
	if not ws:
		_send_error(requester_peer, "INVALID_WORLD")
		return
	# Ensure container dict exists
	if not ws.containers.has(container_id):
		ws.containers[container_id] = {}
	
	var items = ws.get_container_items(container_id)
	_open_containers[requester_peer] = container_id
	
	if requester_peer == 1 or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(requester_peer):
		client_receive_container_snapshot(world_id, container_id, items)
	else:
		rpc_id(requester_peer, "client_receive_container_snapshot", world_id, container_id, items)

@rpc("any_peer", "call_local", "reliable")
func host_close_container(requester_peer: int, container_id: String) -> void:
	if not is_host(): return
	if _open_containers.get(requester_peer, "") == container_id:
		_open_containers.erase(requester_peer)

@rpc("any_peer", "call_local", "reliable")
func host_deposit(requester_peer: int, world_id: String, container_id: String, item_id: String, quantity: int) -> void:
	if not is_host(): return
	if quantity <= 0:
		_send_error(requester_peer, "INVALID_QUANTITY")
		return
	
	var ws = _get_world_state(world_id)
	if not ws:
		_send_error(requester_peer, "INVALID_WORLD")
		return
	
	var player_state = _get_player_state(requester_peer)
	if not player_state:
		_send_error(requester_peer, "INVALID_PLAYER")
		return
	
	if not player_state.has_item(item_id, quantity):
		_send_error(requester_peer, "NOT_ENOUGH_ITEMS")
		return
	
	# Capacity check
	var items = ws.get_container_items(container_id)
	var total_slots = items.size()
	if not items.has(item_id) and total_slots >= DEFAULT_CAPACITY:
		_send_error(requester_peer, "CONTAINER_FULL")
		return
	
	# Atomic: remove from player, add to container
	player_state.remove_item(item_id, quantity)
	items[item_id] = items.get(item_id, 0) + quantity
	ws.set_container_items(container_id, items)
	
	_broadcast_container_update(world_id, container_id, ws.get_container_items(container_id))
	EventBus.container_deposited.emit("", container_id, item_id, quantity)
	print("[NetContainers] Peer %d deposited %dx %s into %s" % [requester_peer, quantity, item_id, container_id])

@rpc("any_peer", "call_local", "reliable")
func host_withdraw(requester_peer: int, world_id: String, container_id: String, item_id: String, quantity: int) -> void:
	if not is_host(): return
	if quantity <= 0:
		_send_error(requester_peer, "INVALID_QUANTITY")
		return
	
	var ws = _get_world_state(world_id)
	if not ws:
		_send_error(requester_peer, "INVALID_WORLD")
		return
	
	var player_state = _get_player_state(requester_peer)
	if not player_state:
		_send_error(requester_peer, "INVALID_PLAYER")
		return
	
	var items = ws.get_container_items(container_id)
	if not items.has(item_id) or int(items.get(item_id, 0)) < quantity:
		_send_error(requester_peer, "NOT_ENOUGH_ITEMS")
		return
	
	# Atomic: remove from container, add to player
	var new_qty = int(items[item_id]) - quantity
	if new_qty <= 0:
		items.erase(item_id)
	else:
		items[item_id] = new_qty
	ws.set_container_items(container_id, items)
	player_state.add_item(item_id, quantity)
	
	_broadcast_container_update(world_id, container_id, ws.get_container_items(container_id))
	EventBus.container_withdrawn.emit("", container_id, item_id, quantity)
	print("[NetContainers] Peer %d withdrew %dx %s from %s" % [requester_peer, quantity, item_id, container_id])


# ---------------------------------------------------------------
# CLIENT RECEIVERS
# ---------------------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func client_receive_container_snapshot(world_id: String, container_id: String, items: Dictionary) -> void:
	container_snapshot_received.emit(container_id, items)

@rpc("authority", "call_local", "reliable")
func client_receive_container_update(world_id: String, container_id: String, items: Dictionary) -> void:
	var ws = _get_world_state(world_id)
	if ws: ws.set_container_items(container_id, items)
	container_updated_local.emit(container_id, items)

@rpc("authority", "call_remote", "reliable")
func client_receive_container_error(reason: String) -> void:
	container_error.emit(reason)
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos2 = player.global_position if player else Vector2(240, 180)
	if spawner: spawner.spawn_floating_text(pos2, "❌ %s" % reason, Color(1.0, 0.4, 0.4))

# ---------------------------------------------------------------
# OFFLINE FALLBACKS
# ---------------------------------------------------------------

func _local_open_container(world_id: String, container_id: String) -> void:
	var ws = _get_world_state(world_id)
	if not ws: return
	if not ws.containers.has(container_id):
		ws.containers[container_id] = {}
	client_receive_container_snapshot(world_id, container_id, ws.get_container_items(container_id))

func _local_deposit(world_id: String, container_id: String, item_id: String, quantity: int) -> void:
	host_deposit(1, world_id, container_id, item_id, quantity)

func _local_withdraw(world_id: String, container_id: String, item_id: String, quantity: int) -> void:
	host_withdraw(1, world_id, container_id, item_id, quantity)
