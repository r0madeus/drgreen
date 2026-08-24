class_name SaveData
extends Resource

## Data container representing a complete game save file version 6 with Multi-World architecture.

const CURRENT_VERSION: int = 8

@export var version: int = CURRENT_VERSION
@export var game_id: String = "botanical_haven"
@export var game_version: String = "1.0.0"
@export var active_mods: Array = []
@export var gameplay_state: Dictionary = {}
@export var timestamp: int = 0
@export var day: int = 1
@export var current_world: String = "farm"
@export var player: Dictionary = {}
@export var players: Dictionary = {}
@export var inventory: Dictionary = {}
@export var grid: Dictionary = {}
@export var worlds: Dictionary = {}
@export var world_states: Dictionary = {}
@export var discoveries: Dictionary = {}
@export var economy: Dictionary = {}
@export var quests: Dictionary = {}
@export var npc_state: Dictionary = {}
@export var world: Dictionary = {}
@export var time: Dictionary = {}
@export var season: Dictionary = {}
@export var weather: Dictionary = {}
@export var progression: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"version": version,
		"game_id": game_id,
		"game_version": game_version,
		"active_mods": active_mods,
		"gameplay_state": gameplay_state,
		"timestamp": Time.get_unix_time_from_system() if timestamp == 0 else timestamp,
		"day": day,
		"time": time,
		"current_world": current_world,

		"player": player,
		"players": players,
		"inventory": inventory,
		"grid": grid,
		"worlds": world_states,
		"world_states": world_states,
		"discoveries": discoveries,
		"economy": economy,
		"quests": quests,
		"npc_state": npc_state,
		"world": world,
		"season": season,
		"weather": weather,
		"progression": progression
	}

static func from_dict(data: Dictionary) -> SaveData:
	var save = SaveData.new()
	save.version = int(data.get("version", 1))
	save.game_id = str(data.get("game_id", "botanical_haven"))
	save.game_version = str(data.get("game_version", "1.0.0"))
	save.active_mods = data.get("active_mods", [])
	save.gameplay_state = data.get("gameplay_state", {})
	save.timestamp = int(data.get("timestamp", 0))
	save.day = int(data.get("day", 1))
	save.time = data.get("time", {})
	save.current_world = str(data.get("current_world", data.get("player", {}).get("current_world", "farm")))

	save.player = data.get("player", {})
	save.players = data.get("players", {})
	save.inventory = data.get("inventory", {})
	save.grid = data.get("grid", {})
	save.world_states = data.get("worlds", data.get("world_states", {}))
	save.worlds = save.world_states
	save.discoveries = data.get("discoveries", {})
	save.economy = data.get("economy", {})
	save.quests = data.get("quests", {})
	save.npc_state = data.get("npc_state", {})
	save.world = data.get("world", {})
	save.season = data.get("season", {})
	save.weather = data.get("weather", {})
	save.progression = data.get("progression", {})

	# Migrate legacy player data (v1-v7) into players["player_001"]
	if save.players.is_empty():
		var p_pos = save.player.get("position", [16, 12])
		var p_facing = save.player.get("facing", [0, 1])
		var p_items = save.inventory.get("items", {})
		var p_selected = save.inventory.get("selected", "seed_red_flower")
		var p_gold = int(save.economy.get("gold", 100))
		
		save.players["player_001"] = {
			"player_id": "player_001",
			"display_name": "Botanist",
			"current_world": save.current_world,
			"position": p_pos,
			"facing_direction": p_facing,
			"inventory": p_items,
			"selected_item_id": p_selected,
			"gold": p_gold,
			"energy": 100.0,
			"max_energy": 100.0
		}
	
	# Migrate legacy save files (v1-v5)
	if save.world_states.is_empty() and not save.grid.is_empty():
		save.world_states["farm"] = save.grid.duplicate(true)
		save.worlds = save.world_states
		
	return save


