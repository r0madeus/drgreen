extends Node

## Central Multi-World Lifecycle, Connection & Transition Manager (Autoload Singleton).

signal world_changing(from_world: String, to_world: String)
signal world_changed(world_id: String, world_data: Dictionary)
signal world_transition_started(target_world: String)
signal world_transition_finished(world_id: String)

const WORLDS_CONFIG_PATH = "res://data/worlds/worlds.json"
const DEFAULT_WORLD_ID = "farm"

var world_definitions: Dictionary = {} # world_id -> WorldDefinition
var current_world_id: String = DEFAULT_WORLD_ID
var shared_world_states: Dictionary = {} # world_id -> SharedWorldState
var is_transitioning: bool = false
var transition_overlay: WorldTransition

func _init() -> void:
	load_world_definitions()

func _ready() -> void:
	load_world_definitions()
	_setup_transition_overlay()

func get_shared_world_state(world_id: String) -> SharedWorldState:
	if not shared_world_states.has(world_id):
		var dname = world_definitions.get(world_id, {}).display_name if world_definitions.has(world_id) else world_id.capitalize()
		shared_world_states[world_id] = SharedWorldState.new(world_id, dname)
	return shared_world_states[world_id]

func get_active_world_state() -> SharedWorldState:
	return get_shared_world_state(current_world_id)

func load_world_definitions() -> void:
	world_definitions.clear()
	if FileAccess.file_exists(WORLDS_CONFIG_PATH):
		var f = FileAccess.open(WORLDS_CONFIG_PATH, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				var list = json.data.get("worlds", {})
				for wid in list.keys():
					world_definitions[wid] = WorldDefinition.from_dict(wid, list[wid])
					if not shared_world_states.has(wid):
						shared_world_states[wid] = SharedWorldState.new(wid, world_definitions[wid].display_name)
	
	# Fallback auto-discovery if worlds.json was empty
	if world_definitions.is_empty():
		for fn in DirAccess.get_files_at("res://data/worlds/"):
			if fn.ends_with(".json") and fn != "worlds.json":
				var wid = fn.trim_suffix(".json")
				world_definitions[wid] = WorldDefinition.from_dict(wid, { "id": wid, "display_name": wid.capitalize() })
				if not shared_world_states.has(wid):
					shared_world_states[wid] = SharedWorldState.new(wid, world_definitions[wid].display_name)
				
	print("[WorldManager] Loaded %d Multi-World Definitions & SharedWorldStates." % world_definitions.size())

func _setup_transition_overlay() -> void:
	if not transition_overlay:
		transition_overlay = WorldTransition.new()
		add_child(transition_overlay)

func get_current_world() -> String:
	return current_world_id

func check_world_exists(world_id: String) -> bool:
	return world_definitions.has(world_id) or FileAccess.file_exists("res://data/worlds/%s.json" % world_id)

func get_world_definition(world_id: String) -> WorldDefinition:
	return world_definitions.get(world_id, null)

func get_all_world_definitions() -> Dictionary:
	return world_definitions.duplicate()


func get_spawn_point(world_id: String, spawn_id: String = "default") -> Vector2i:
	var def = get_world_definition(world_id)
	if def and def.spawn_points.has(spawn_id):
		var p = def.spawn_points[spawn_id]
		return Vector2i(int(p[0]), int(p[1]))
	elif def and def.spawn_points.has("default"):
		var p = def.spawn_points["default"]
		return Vector2i(int(p[0]), int(p[1]))
	return Vector2i(16, 12)

func get_connected_worlds(world_id: String) -> Array:
	var list: Array = []
	var def = get_world_definition(world_id)
	if def and def.connections:
		for dir in def.connections.keys():
			var c = def.connections[dir]
			var w = str(c.get("world", ""))
			if w != "" and not list.has(w):
				list.append(w)
	return list

func can_travel(from_world: String, to_world: String) -> bool:
	var connected = get_connected_worlds(from_world)
	return connected.has(to_world)

func get_transition(transition_id: String) -> Dictionary:
	for wid in world_definitions.keys():
		var path = "res://data/worlds/%s.json" % wid
		if FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var json = JSON.new()
				if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
					for tr in json.data.get("transitions", []):
						if tr.get("transition_id") == transition_id or tr.get("instance_id") == transition_id:
							f.close()
							return tr
				f.close()
	return {}

func get_all_transitions_for_world(world_id: String) -> Array:
	var path = "res://data/worlds/%s.json" % world_id
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK and typeof(json.data) == TYPE_DICTIONARY:
				var trs = json.data.get("transitions", [])
				f.close()
				return trs
			f.close()
	return []

func load_world(world_id: String) -> Dictionary:
	var wl = get_node_or_null("/root/WorldLoader")
	if wl:
		return wl.load_world(world_id)
	return {}


func transition_to(target_world_id: String, target_spawn: Variant = "default", animate: bool = true) -> bool:
	if is_transitioning: return false
	
	var pm = get_node_or_null("/root/ProgressionManager")
	if pm and not pm.is_world_unlocked(target_world_id):
		var spawner = EffectSpawner.get_instance()
		var p_node = get_tree().root.find_child("Player", true, false)
		var pos = p_node.global_position if p_node else Vector2(240, 180)
		if spawner:
			spawner.spawn_floating_text(pos, "🔒 Area Locked! Complete research quest first.", Color(1.0, 0.4, 0.4))
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("ui_close")
		return false
		
	if not check_world_exists(target_world_id):
		push_warning("[WorldManager] World does not exist: %s" % target_world_id)
		var spawner = EffectSpawner.get_instance()
		var p_node = get_tree().root.find_child("Player", true, false)
		var pos = p_node.global_position if p_node else Vector2(240, 180)
		if spawner:
			spawner.spawn_floating_text(pos, "Destination missing", Color(1.0, 0.4, 0.4))
		return false


		
	is_transitioning = true
	var from_world = current_world_id
	world_changing.emit(from_world, target_world_id)
	world_transition_started.emit(target_world_id)
	EventBus.world_transition_started.emit(target_world_id)
	
	var player = get_tree().root.find_child("Player", true, false)
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(true)
		
	# 1. Fade Out
	if animate and transition_overlay:
		await transition_overlay.fade_out(0.2)
		
	# 2. Resolve Spawn
	var resolved_spawn = Vector2i(16, 12)
	if target_spawn is Vector2i:
		resolved_spawn = target_spawn
	elif target_spawn is Array and target_spawn.size() >= 2:
		resolved_spawn = Vector2i(int(target_spawn[0]), int(target_spawn[1]))
	elif target_spawn is String:
		resolved_spawn = get_spawn_point(target_world_id, target_spawn)
	else:
		resolved_spawn = get_spawn_point(target_world_id, "default")
		
	# 3. Delegate to WorldLoader for GridManager rebuild & per-world state caching
	var wl = get_node_or_null("/root/WorldLoader")
	if wl:
		wl.change_world(target_world_id, resolved_spawn, false)
		
	current_world_id = target_world_id
	
	var psm = get_node_or_null("/root/PlayerStateManager")
	if psm:
		var p_state = psm.get_active_player_state()
		if p_state:
			p_state.current_world = target_world_id
			p_state.position = player.global_position if player else Vector2(resolved_spawn.x * 16 + 8, resolved_spawn.y * 16 + 8)
			
	world_changed.emit(target_world_id, wl.current_world_data if wl else {})

	
	# 4. Fade In
	if animate and transition_overlay:
		await transition_overlay.fade_in(0.2)
		
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
		
	is_transitioning = false
	world_transition_finished.emit(target_world_id)
	EventBus.world_transition_completed.emit(target_world_id)
	return true

func get_default_starting_world() -> String:
	var pkg_script = ResourceLoader.load("res://core/game_package_manager.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	if pkg_script:
		var pm = pkg_script.get_instance()
		if pm and pm.get_active_game_package():
			return str(pm.get_active_game_package().starting_world)
	return DEFAULT_WORLD_ID
