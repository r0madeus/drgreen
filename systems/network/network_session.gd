class_name NetworkSession
extends RefCounted

## Represents the live multiplayer session configuration and registry of peers.

enum NetworkMode { OFFLINE, HOST, CLIENT }

var mode: NetworkMode = NetworkMode.OFFLINE
var host_address: String = "127.0.0.1"
var port: int = 7000
var game_id: String = "botanical_haven"
var game_version: String = "1.0.0" 
var max_players: int = 4
var peers: Dictionary = {} # peer_id (int) -> NetworkIdentity

func is_offline() -> bool:
	return mode == NetworkMode.OFFLINE

func is_host() -> bool:
	return mode == NetworkMode.HOST

func is_client() -> bool:
	return mode == NetworkMode.CLIENT

func get_peer_count() -> int:
	return peers.size()

func add_peer(ident: NetworkIdentity) -> void:
	peers[ident.peer_id] = ident

func remove_peer(peer_id: int) -> bool:
	return peers.erase(peer_id)

func get_peer(peer_id: int) -> NetworkIdentity:
	return peers.get(peer_id, null)

func clear() -> void:
	peers.clear()
	mode = NetworkMode.OFFLINE

func get_mode_name() -> String:
	match mode:
		NetworkMode.HOST: return "Host"
		NetworkMode.CLIENT: return "Client"
		_: return "Offline"

func is_compatible_with_host(host_game_id: String, host_game_version: String) -> bool:
	if host_game_id == "" or host_game_id == "all": return true
	return host_game_id == game_id and (host_game_version == "" or host_game_version == game_version)
