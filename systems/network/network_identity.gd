class_name NetworkIdentity
extends RefCounted

## Represents identity metadata for a connected network peer.

var peer_id: int = 1
var player_id: String = "player_001"
var display_name: String = "Botanist"
var current_world: String = "farm"
var position: Vector2i = Vector2i(16, 12)
var facing_direction: Vector2i = Vector2i.DOWN
var is_host: bool = false
var ping_ms: int = 0

func _init(p_peer: int = 1, p_pid: String = "player_001", p_name: String = "Botanist") -> void:
	peer_id = p_peer
	player_id = p_pid
	display_name = p_name
	is_host = (p_peer == 1)

func to_dict() -> Dictionary:
	return {
		"peer_id": peer_id,
		"player_id": player_id,
		"display_name": display_name,
		"current_world": current_world,
		"position": [position.x, position.y],
		"facing_direction": [facing_direction.x, facing_direction.y],
		"is_host": is_host,
		"ping_ms": ping_ms
	}

static func from_dict(data: Dictionary) -> NetworkIdentity:
	var script = load("res://systems/network/network_identity.gd") as GDScript
	var ident = script.new(int(data.get("peer_id", 1)), str(data.get("player_id", "player_001")), str(data.get("display_name", "Botanist")))
	ident.current_world = str(data.get("current_world", "farm"))
	var p_arr = data.get("position", [16, 12])
	ident.position = Vector2i(int(p_arr[0]), int(p_arr[1]))
	var f_arr = data.get("facing_direction", [0, 1])
	ident.facing_direction = Vector2i(int(f_arr[0]), int(f_arr[1]))
	ident.is_host = bool(data.get("is_host", ident.peer_id == 1))
	ident.ping_ms = int(data.get("ping_ms", 0))
	return ident
