class_name SharedWorldState
extends RefCounted

## Represents the decoupled, authoritative Shared World State for a specific world map.
## Encapsulates all world-owned dynamic state (tiles, plants, objects, containers, shared discoveries and progression).

signal plant_added(pos: Vector2i, plant_id: String)
signal plant_removed(pos: Vector2i)
signal discovery_registered(item_id: String)
signal container_updated(container_id: String)

var world_id: String = "farm"
var display_name: String = "Farm"
var plants: Dictionary = {} # Vector2i -> { "plant_id": String, "growth_stage": int, "days_in_stage": int, "watered_today": bool }
var modified_tiles: Dictionary = {} # Vector2i -> Dictionary (tile override)
var dynamic_objects: Dictionary = {} # instance_id -> Dictionary
var containers: Dictionary = {} # container_id -> Dictionary (items)
var discovered_combinations: Array[String] = []
var discovered_plants: Array[String] = []
var world_progression: Dictionary = {}
var world_time: Dictionary = { "day": 1, "season": "spring", "weather": "sunny" }
var metadata: Dictionary = {}
var shared_events: Dictionary = {} # event_id (String) -> Dictionary { "applied": true, "timestamp": int, "data": Dictionary }
var npc_positions: Dictionary = {} # npc_id (String) -> Dictionary { "world_id": String, "position": [x, y], "schedule_state": String }

func _init(p_world_id: String = "farm", p_display_name: String = "Farm") -> void:
	world_id = p_world_id
	display_name = p_display_name

func add_or_update_plant(pos: Vector2i, plant_id: String, stage: int = 0, days: int = 0, watered: bool = false, gen_id: String = "", gen_prof: Dictionary = {}) -> void:
	plants[pos] = {
		"position": [pos.x, pos.y],
		"plant_id": plant_id,
		"growth_stage": stage,
		"days_in_stage": days,
		"watered_today": watered,
		"genetic_identity": gen_id,
		"genetic_profile": gen_prof
	}
	plant_added.emit(pos, plant_id)

func remove_plant(pos: Vector2i) -> bool:
	if plants.has(pos):
		plants.erase(pos)
		plant_removed.emit(pos)
		return true
	return false

func get_plant(pos: Vector2i) -> Dictionary:
	return plants.get(pos, {})

func has_plant(pos: Vector2i) -> bool:
	return plants.has(pos)

func get_all_plants() -> Array:
	var list: Array = []
	for pos in plants.keys():
		var p = plants[pos].duplicate(true)
		p["position"] = [pos.x, pos.y]
		list.append(p)
	return list

func set_container_items(container_id: String, items_dict: Dictionary) -> void:
	containers[container_id] = items_dict.duplicate(true)
	container_updated.emit(container_id)

func get_container_items(container_id: String) -> Dictionary:
	return containers.get(container_id, {}).duplicate(true)

func register_discovery(combo_id: String, plant_id: String) -> void:
	if not discovered_combinations.has(combo_id) and combo_id != "":
		discovered_combinations.append(combo_id)
	if not discovered_plants.has(plant_id) and plant_id != "":
		discovered_plants.append(plant_id)
	discovery_registered.emit(plant_id)

func is_combination_discovered(combo_id: String) -> bool:
	return discovered_combinations.has(combo_id)

func is_plant_discovered(plant_id: String) -> bool:
	return discovered_plants.has(plant_id)

# --- Shared NPC Events & Idempotency ---
func is_event_applied(event_id: String) -> bool:
	return shared_events.has(event_id)

func apply_event(event_id: String, event_data: Dictionary = {}) -> bool:
	if is_event_applied(event_id):
		return false
	shared_events[event_id] = {
		"applied": true,
		"timestamp": Time.get_unix_time_from_system(),
		"data": event_data.duplicate(true)
	}
	return true

func get_applied_events() -> Array:
	return shared_events.keys()

# --- Shared NPC Positions & Schedules ---
func set_npc_position(npc_id: String, p_world_id: String, pos: Vector2i, schedule_state: String = "default") -> void:
	npc_positions[npc_id] = {
		"world_id": p_world_id,
		"position": [pos.x, pos.y],
		"schedule_state": schedule_state
	}

func get_npc_position(npc_id: String) -> Dictionary:
	return npc_positions.get(npc_id, {}).duplicate(true)

func get_all_npc_positions() -> Dictionary:
	return npc_positions.duplicate(true)

func to_dict() -> Dictionary:
	var plants_arr: Array = []
	for pos in plants.keys():
		var p_data = plants[pos]
		plants_arr.append({
			"position": [pos.x, pos.y],
			"plant_id": p_data.get("plant_id", ""),
			"growth_stage": p_data.get("growth_stage", 0),
			"days_in_stage": p_data.get("days_in_stage", 0),
			"watered_today": p_data.get("watered_today", false)
		})
		
	var tiles_dict: Dictionary = {}
	for pos in modified_tiles.keys():
		tiles_dict["%d,%d" % [pos.x, pos.y]] = modified_tiles[pos]

	return {
		"world_id": world_id,
		"display_name": display_name,
		"plants": plants_arr,
		"modified_tiles": tiles_dict,
		"dynamic_objects": dynamic_objects.duplicate(true),
		"containers": containers.duplicate(true),
		"discovered_combinations": discovered_combinations.duplicate(),
		"discovered_plants": discovered_plants.duplicate(),
		"world_progression": world_progression.duplicate(true),
		"world_time": world_time.duplicate(true),
		"metadata": metadata.duplicate(true),
		"shared_events": shared_events.duplicate(true),
		"npc_positions": npc_positions.duplicate(true)
	}

static func from_dict(p_world_id: String, data: Dictionary) -> SharedWorldState:
	var state = SharedWorldState.new(p_world_id, str(data.get("display_name", p_world_id.capitalize())))
	
	# Restore plants
	var p_list = data.get("plants", [])
	for p in p_list:
		var pos_arr = p.get("position", [0, 0])
		var pos = Vector2i(int(pos_arr[0]), int(pos_arr[1]))
		state.plants[pos] = {
			"position": [pos.x, pos.y],
			"plant_id": str(p.get("plant_id", "")),
			"growth_stage": int(p.get("growth_stage", 0)),
			"days_in_stage": int(p.get("days_in_stage", 0)),
			"watered_today": bool(p.get("watered_today", false))
		}
		
	# Restore containers
	state.containers = data.get("containers", {}).duplicate(true)
	
	# Restore modified tiles
	var m_tiles = data.get("modified_tiles", {})
	for k in m_tiles.keys():
		var parts = k.split(",")
		if parts.size() == 2:
			var t_pos = Vector2i(parts[0].to_int(), parts[1].to_int())
			state.modified_tiles[t_pos] = m_tiles[k].duplicate(true)
	
	# Restore discoveries
	var combos = data.get("discovered_combinations", [])
	for c in combos: state.discovered_combinations.append(str(c))
	
	var plants = data.get("discovered_plants", [])
	for pl in plants: state.discovered_plants.append(str(pl))
	
	state.world_progression = data.get("world_progression", {}).duplicate(true)
	state.world_time = data.get("world_time", {}).duplicate(true)
	state.dynamic_objects = data.get("dynamic_objects", {}).duplicate(true)
	state.metadata = data.get("metadata", {}).duplicate(true)
	state.shared_events = data.get("shared_events", {}).duplicate(true)
	state.npc_positions = data.get("npc_positions", {}).duplicate(true)
	
	return state

