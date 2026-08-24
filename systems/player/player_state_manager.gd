extends Node

## Central Player State Registry (Autoload Singleton) managing PlayerState instances and active local player reference.

signal active_player_changed(player_id: String)
signal player_registered(player_id: String)

const DEFAULT_PLAYER_ID: String = "player_001"

var players: Dictionary = {} # player_id -> PlayerState
var active_player_id: String = DEFAULT_PLAYER_ID

func _ready() -> void:
	# Ensure default local player state exists
	get_or_create_player(DEFAULT_PLAYER_ID, "Botanist")
	EventBus.day_started.connect(_on_day_started)

func _on_day_started(_day: int) -> void:
	for p_id in players.keys():
		if players[p_id]:
			players[p_id].reset_daily_social_limits()


func get_or_create_player(player_id: String = DEFAULT_PLAYER_ID, display_name: String = "Botanist") -> PlayerState:
	if not players.has(player_id):
		var p_state = PlayerState.new(player_id, display_name)
		p_state.init_starter_kit()
		players[player_id] = p_state
		player_registered.emit(player_id)
	return players[player_id]

func get_active_player_state() -> PlayerState:
	return get_or_create_player(active_player_id)

func get_player_state(player_id: String) -> PlayerState:
	return players.get(player_id, null)

func set_active_player(player_id: String) -> void:
	if players.has(player_id):
		active_player_id = player_id
		active_player_changed.emit(active_player_id)

func get_all_players() -> Dictionary:
	return players.duplicate()

func get_all_player_states_dict() -> Dictionary:
	var result = {}
	for pid in players.keys():
		var p = players[pid]
		if p and p.has_method("to_dict"):
			result[pid] = p.to_dict()
	return result

func load_player_states_dict(dict: Dictionary) -> void:
	for pid in dict.keys():
		var data = dict[pid]
		if data is Dictionary:
			var p_state = PlayerState.from_dict(data)
			players[pid] = p_state
