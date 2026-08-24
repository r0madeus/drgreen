extends Node

## Central Multiplayer Network Manager (Autoload Singleton).
## Manages ENet sessions, Host/Join connections, Peer lifecycle, and Player synchronization.

signal connection_started()
signal connected()
signal connection_failed(reason: String)
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal disconnected()
signal host_started()
signal host_stopped()
signal remote_player_updated(peer_id: int, data: Dictionary)

const DEFAULT_PORT: int = 7000
const MAX_CLIENTS: int = 3 # 1 host + 3 clients = 4 players

var session: NetworkSession
var enet_peer: ENetMultiplayerPeer
var remote_players: Dictionary = {} # peer_id (int) -> NetworkPlayer
var sync_timer: float = 0.0
const SYNC_RATE: float = 0.05 # 20 Hz movement updates

var debug_overlay: NetworkDebugOverlay
var multiplayer_ui: MultiplayerUI

func _init() -> void:
	session = NetworkSession.new()

func _ready() -> void:
	debug_overlay = NetworkDebugOverlay.new()
	add_child(debug_overlay)
	
	multiplayer_ui = MultiplayerUI.new()
	add_child(multiplayer_ui)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func is_offline() -> bool:
	return session.is_offline()

func is_host() -> bool:
	return session.is_host()

func is_client() -> bool:
	return session.is_client()

func get_local_peer_id() -> int:
	if session.is_offline(): return 1
	return multiplayer.get_unique_id()

func get_connected_peers() -> Dictionary:
	return session.peers.duplicate()

func get_connection_status() -> String:
	return session.get_mode_name()

func _get_local_player_grid_position(state: PlayerState = null) -> Vector2i:
	var tree = get_tree()
	var grid = tree.current_scene.find_child("GridManager", true, false) as GridManager if tree and tree.current_scene else null
	if state and grid:
		return grid.world_to_grid(state.position)
	if state:
		return Vector2i(int(floor(state.position.x / 16.0)), int(floor(state.position.y / 16.0)))
	return Vector2i(16, 12)

# --- Host / Client Operations ---
func create_host(port: int = DEFAULT_PORT) -> bool:
	if not session.is_offline():
		disconnect_session()
		
	enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		push_error("[NetworkManager] Failed to create host server on port %d: Error %d" % [port, error])
		connection_failed.emit("Failed to create server on port %d" % port)
		return false
		
	multiplayer.multiplayer_peer = enet_peer
	session.mode = NetworkSession.NetworkMode.HOST
	session.port = port
	
	# Register host local identity
	var psm = get_node_or_null("/root/PlayerRegistry")
	var host_state = psm.get_active_player_state() if psm else null
	var host_id = host_state.player_id if host_state else "player_host"
	var host_name = host_state.display_name if host_state else "Host Botanist"
	var host_world = host_state.current_world if host_state else "farm"
	var host_pos: Vector2i = _get_local_player_grid_position(host_state)
	
	var host_ident = NetworkIdentity.new(1, host_id, host_name)
	host_ident.current_world = host_world
	host_ident.position = host_pos
	session.add_peer(host_ident)
	
	print("[NetworkManager] Host started on port %d with peer ID 1." % port)
	host_started.emit()
	connected.emit()
	return true

func join_host(address: String = "127.0.0.1", port: int = DEFAULT_PORT) -> bool:
	if not session.is_offline():
		disconnect_session()
		
	connection_started.emit()
	enet_peer = ENetMultiplayerPeer.new()
	var error = enet_peer.create_client(address, port)
	if error != OK:
		push_error("[NetworkManager] Failed to connect to %s:%d: Error %d" % [address, port, error])
		connection_failed.emit("Failed to initiate connection to %s:%d" % [address, port])
		return false
		
	multiplayer.multiplayer_peer = enet_peer
	session.mode = NetworkSession.NetworkMode.CLIENT
	session.host_address = address
	session.port = port
	print("[NetworkManager] Connecting to host %s:%d..." % [address, port])
	return true

func disconnect_session() -> void:
	if enet_peer:
		enet_peer.close()
		multiplayer.multiplayer_peer = null
		enet_peer = null
		
	_cleanup_remote_players()
	var was_host = session.is_host()
	session.clear()
	
	if was_host: host_stopped.emit()
	disconnected.emit()
	print("[NetworkManager] Disconnected from network session. Back in Offline mode.")

# --- Peer Lifecycle Callbacks ---
func _on_connected_to_server() -> void:
	var local_id = multiplayer.get_unique_id()
	print("[NetworkManager] Client connected to server with peer ID: %d" % local_id)
	
	var psm = get_node_or_null("/root/PlayerRegistry")
	var p_state = psm.get_active_player_state() if psm else null
	var pid = p_state.player_id if p_state else ("player_%d" % local_id)
	var pname = p_state.display_name if p_state else ("Botanist %d" % local_id)
	var pworld = p_state.current_world if p_state else "farm"
	var ppos: Vector2i = _get_local_player_grid_position(p_state)
	
	var ident = NetworkIdentity.new(local_id, pid, pname)
	ident.current_world = pworld
	ident.position = ppos
	session.add_peer(ident)
	
	# Register identity with host and peers
	rpc("register_player_identity", local_id, pid, pname, pworld, ppos)
	connected.emit()

func _on_connection_failed() -> void:
	push_warning("[NetworkManager] Connection attempt to host failed.")
	disconnect_session()
	connection_failed.emit("Could not reach host server.")

func _on_server_disconnected() -> void:
	print("[NetworkManager] Server disconnected.")
	disconnect_session()

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Remote peer connected: %d" % id)
	peer_connected.emit(id)
	
	# If we are host, send session manifest to new peer
	if is_host():
		var manifest: Array = []
		for p in session.peers.values():
			manifest.append((p as NetworkIdentity).to_dict())
		rpc_id(id, "sync_session_manifest", manifest)
		
		var wm = get_node_or_null("/root/WorldManager")
		var cur_w = wm.get_current_world() if wm else "farm"
		var net_gameplay = get_node_or_null("/root/NetworkGameplay")
		if net_gameplay: net_gameplay.client_request_snapshot(id, cur_w)
		var net_npc = get_node_or_null("/root/NetworkNPC")
		if net_npc: net_npc.host_request_npc_snapshot(id, cur_w)
		var net_quests = get_node_or_null("/root/NetworkQuests")
		if net_quests: net_quests.host_request_quest_snapshot(id)



func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Remote peer disconnected: %d" % id)
	session.remove_peer(id)
	_despawn_remote_player(id)
	peer_disconnected.emit(id)

# --- Remote Player Entity Management ---
func _spawn_remote_player(ident: NetworkIdentity) -> void:
	if ident.peer_id == get_local_peer_id(): return
	if remote_players.has(ident.peer_id): return
	
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	if not root: return
	
	var target_parent: Node = root
	var main = root.find_child("Main", true, false)
	if main and "scene_container" in main and main.scene_container:
		target_parent = main.scene_container
	elif root.get_node_or_null("Farm"):
		target_parent = root.get_node_or_null("Farm")
	
	var np = NetworkPlayer.new()
	np.peer_id = ident.peer_id
	np.player_id = ident.player_id
	np.display_name = ident.display_name
	np.current_world = ident.current_world
	
	var gm = target_parent.find_child("GridManager", true, false)
	if gm:
		np.position = gm.grid_to_world(ident.position, true)
	else:
		np.position = Vector2(ident.position.x * 16 + 8, ident.position.y * 16 + 8)
		
	target_parent.add_child(np)
	remote_players[ident.peer_id] = np
	print("[NetworkManager] Spawned remote player entity for peer %d (%s) at %s" % [ident.peer_id, ident.display_name, np.position])


func _despawn_remote_player(peer_id: int) -> void:
	if remote_players.has(peer_id):
		var np = remote_players[peer_id]
		if is_instance_valid(np):
			np.queue_free()
		remote_players.erase(peer_id)

func _cleanup_remote_players() -> void:
	for pid in remote_players.keys():
		var np = remote_players[pid]
		if is_instance_valid(np):
			np.queue_free()
	remote_players.clear()

# --- RPC Handlers ---
@rpc("any_peer", "call_local", "reliable")
func register_player_identity(p_peer: int, p_id: String, p_name: String, p_world: String, p_pos: Vector2i) -> void:
	var ident = NetworkIdentity.new(p_peer, p_id, p_name)
	ident.current_world = p_world
	ident.position = p_pos
	session.add_peer(ident)
	_spawn_remote_player(ident)
	remote_player_updated.emit(p_peer, ident.to_dict())

@rpc("authority", "call_remote", "reliable")
func sync_session_manifest(manifest: Array) -> void:
	for data in manifest:
		var ident = NetworkIdentity.from_dict(data)
		session.add_peer(ident)
		if ident.peer_id != get_local_peer_id():
			_spawn_remote_player(ident)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_player_movement(p_peer: int, pos_x: float, pos_y: float, f_x: int, f_y: int, anim_state: String, world_id: String) -> void:
	if remote_players.has(p_peer):
		var np = remote_players[p_peer]
		if is_instance_valid(np):
			np.update_network_state(Vector2(pos_x, pos_y), Vector2i(f_x, f_y), anim_state, world_id)
			
	var ident = session.get_peer(p_peer)
	if ident:
		ident.current_world = world_id
		ident.facing_direction = Vector2i(f_x, f_y)

# --- Process Sync Loop ---
func _process(delta: float) -> void:
	if session.is_offline(): return
	
	sync_timer += delta
	if sync_timer >= SYNC_RATE:
		sync_timer = 0.0
		_broadcast_local_player_state()

func _broadcast_local_player_state() -> void:
	var tree = get_tree()
	if not tree or not tree.current_scene: return
	var player = tree.current_scene.find_child("Player", true, false)
	if not player: return
	
	var wm = get_node_or_null("/root/WorldManager")
	var c_world = wm.get_current_world() if wm else "farm"
	var my_peer_id = get_local_peer_id()
	var state_str = player.animation_handler.current_state if player.animation_handler else "idle"
	
	rpc("send_player_movement", my_peer_id, player.position.x, player.position.y, player.facing_direction.x, player.facing_direction.y, state_str, c_world)
