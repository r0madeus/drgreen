class_name NPCInstance
extends Node2D

## Data-driven living NPC node with obstacle-aware world-space path navigation,
## behavior controller integration, 4-directional facing, activity animation mapping,
## and smooth Stardew-style presentation.

signal destination_reached(npc_id: String, location_id: String)
signal state_changed(old_state: String, new_state: String)
signal navigation_failed(npc_id: String, location_id: String)

const NPC_BEHAVIOR_CONTROLLER_SCRIPT = preload("res://systems/npc/npc_behavior_controller.gd")

@export var npc_id: String = "rowan"
@export var display_name: String = "Rowan"
@export var grid_position: Vector2i = Vector2i(15, 3)
@export var role: String = "seed_merchant"
@export var dialogue_id: String = "rowan"
@export var shop_id: String = "rowan_seed_shop"
@export var sprite_name: String = "merchant"
@export var target_world: String = "farm"
@export var walk_speed: float = 38.0

# Components & Subsystems
var behavior_controller = NPC_BEHAVIOR_CONTROLLER_SCRIPT.new()

# Navigation & Movement state
var current_state: String = "IDLE"
var current_activity: String = "home"
var current_location_id: String = ""
var target_location_id: String = ""
var target_world_pos: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var velocity: Vector2 = Vector2.ZERO
var is_interacting: bool = false
var is_moving: bool = false
var nav_path: Array = []
var current_waypoint_index: int = 0
var nav_failed: bool = false

# Visuals & Components
var idle_frame: int = 0
var walk_frame: int = 0
var anim_frame: int = 0
var current_anim_name: String = "idle"
var anim_timer: Timer
var sprite: Sprite2D
var prompt_label: Label

func _get_tree_root() -> Window:
	var tree = get_tree()
	if tree and tree.root: return tree.root
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root: return loop.root
	return null

func _ready() -> void:
	_setup_nodes()
	_update_position_from_grid()
	if behavior_controller:
		behavior_controller.setup(self)
		
	EventBus.player_interacted.connect(_on_player_interacted)
	var dm = get_node_or_null("/root/DialogueManager")
	if dm and dm.has_signal("dialogue_ended"):
		dm.dialogue_ended.connect(_on_dialogue_ended)

func setup(p_data: Dictionary) -> void:
	npc_id = str(p_data.get("id", p_data.get("npc_id", "rowan")))
	display_name = str(p_data.get("display_name", p_data.get("name", npc_id.capitalize())))
	var pos_arr = p_data.get("position", [15, 3])
	grid_position = Vector2i(int(pos_arr[0]), int(pos_arr[1]))
	role = str(p_data.get("role", "seed_merchant"))
	dialogue_id = str(p_data.get("dialogue_id", npc_id))
	shop_id = str(p_data.get("shop_id", ""))
	sprite_name = str(p_data.get("sprite", npc_id))
	target_world = str(p_data.get("world", "farm"))
	_update_visuals()
	_update_position_from_grid()
	if behavior_controller:
		behavior_controller.setup(self)

func _setup_nodes() -> void:
	if not sprite:
		sprite = Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(sprite)
		
	if not prompt_label:
		prompt_label = Label.new()
		prompt_label.text = "💬 [E] Talk"
		prompt_label.add_theme_font_size_override("font_size", 9)
		prompt_label.modulate = Color(1.0, 1.0, 0.6)
		prompt_label.position = Vector2(-22, -26)
		prompt_label.visible = false
		add_child(prompt_label)
		
	if not anim_timer:
		anim_timer = Timer.new()
		anim_timer.wait_time = 0.35
		anim_timer.timeout.connect(_on_anim_timeout)
		add_child(anim_timer)
		anim_timer.start()

func get_facing_direction_string() -> String:
	if abs(facing_direction.x) > abs(facing_direction.y):
		return "right" if facing_direction.x > 0.0 else "left"
	else:
		return "down" if facing_direction.y >= 0.0 else "up"

func get_current_animation_name() -> String:
	if is_interacting:
		return "talk"
	if is_moving and (current_state in ["NAVIGATING", "TRAVELING", "WALKING", "WANDERING"] or (behavior_controller and behavior_controller.current_state in ["NAVIGATING", "TRAVELING", "WALKING", "WANDERING"])):
		return "walk"
		
	var state_to_check = behavior_controller.current_state if (behavior_controller and behavior_controller.current_state != "IDLE") else current_state
	var act_to_check = behavior_controller.current_activity if behavior_controller else current_activity
	
	match state_to_check:
		"WORKING": return "work"
		"EATING": return "eat"
		"RESTING": return "rest"
		"SITTING": return "sit"
		"SLEEPING": return "sleep"
		"TALKING", "SOCIALIZING", "PLAYER_INTERACTION": return "talk"
		"NAVIGATING", "TRAVELING", "WALKING", "WANDERING": return "walk"
		_:
			match act_to_check:
				"work": return "work"
				"eat": return "eat"
				"rest": return "rest"
				"sit": return "sit"
				"sleep": return "sleep"
				_: return "idle"


func _update_visuals() -> void:
	if not sprite: return
	
	var desired_anim = get_current_animation_name()
	current_anim_name = desired_anim
	var dir_str = get_facing_direction_string()
	var frame_idx = anim_frame
	
	var tex = AssetRegistry.get_npc_animation_texture(sprite_name, desired_anim, dir_str, frame_idx)
	if tex: sprite.texture = tex
	sprite.position = Vector2(0, -8)
	
	if dir_str == "left":
		sprite.flip_h = true
	elif dir_str == "right":
		sprite.flip_h = false

func _update_position_from_grid() -> void:
	var root = _get_tree_root()
	var gm = root.find_child("GridManager", true, false) if root else null
	if gm:
		position = gm.grid_to_world(grid_position, true)
	else:
		position = Vector2(grid_position.x * 16 + 8, grid_position.y * 16 + 8)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	
	if behavior_controller:
		behavior_controller.update(delta)
		
	var root = _get_tree_root()
	var player = root.find_child("Player", true, false) if root else null
	if player and prompt_label:
		var dist = global_position.distance_to(player.global_position)
		prompt_label.visible = (dist <= 28.0)
		
	if (current_state in ["NAVIGATING", "TRAVELING", "WALKING"]) and not is_interacting:
		_process_movement(delta)
	else:
		is_moving = false
		velocity = Vector2.ZERO

func _process_movement(delta: float) -> void:
	if nav_path.is_empty() or current_waypoint_index >= nav_path.size():
		var direct_dist = global_position.distance_to(target_world_pos)
		if direct_dist <= 4.0:
			_arrive_at_destination()
		else:
			is_moving = false
			velocity = Vector2.ZERO
			_update_visuals()
		return
		
	var target_wp = nav_path[current_waypoint_index]
	var dist = global_position.distance_to(target_wp)
	
	if dist > 3.5:
		var move_dir = (target_wp - global_position).normalized()
		var avoidance = _calculate_local_avoidance()
		var combined_dir = (move_dir + avoidance * 0.4).normalized()
		
		velocity = combined_dir * walk_speed
		global_position += velocity * delta
		facing_direction = move_dir
		is_moving = true
		
		var root = _get_tree_root()
		var gm = root.find_child("GridManager", true, false) if root else null
		if gm:
			grid_position = gm.world_to_grid(global_position)
		else:
			grid_position = Vector2i(int(floor(global_position.x / 16.0)), int(floor(global_position.y / 16.0)))
			
		_update_visuals()
	else:
		current_waypoint_index += 1
		if current_waypoint_index >= nav_path.size():
			_arrive_at_destination()

func _calculate_local_avoidance() -> Vector2:
	var npcm = get_node_or_null("/root/NPCManager")
	if not npcm: return Vector2.ZERO
	
	var separation = Vector2.ZERO
	var neighbor_count = 0
	
	for other_id in npcm.active_npc_instances.keys():
		if other_id == npc_id: continue
		var other = npcm.active_npc_instances[other_id]
		if is_instance_valid(other) and other is Node2D and other.visible:
			var d = global_position.distance_to(other.global_position)
			if d > 0.1 and d < 18.0:
				var push = (global_position - other.global_position).normalized()
				separation += push * (18.0 - d) / 18.0
				neighbor_count += 1
				
	if neighbor_count > 0:
		separation /= neighbor_count
	return separation

func _arrive_at_destination() -> void:
	global_position = target_world_pos
	velocity = Vector2.ZERO
	is_moving = false
	current_location_id = target_location_id
	var prev_state = current_state
	current_state = "AT_DESTINATION"
	nav_path.clear()
	current_waypoint_index = 0
	state_changed.emit(prev_state, current_state)
	destination_reached.emit(npc_id, target_location_id)
	if behavior_controller:
		behavior_controller.on_destination_reached(target_location_id)
	_update_visuals()

func set_destination(loc_id: String, world_pos: Vector2, activity: String, default_facing: Vector2 = Vector2.DOWN) -> void:
	target_location_id = loc_id
	target_world_pos = world_pos
	current_activity = activity
	nav_failed = false
	
	var dist = global_position.distance_to(world_pos)
	if dist <= 4.0:
		global_position = world_pos
		current_location_id = loc_id
		current_state = "AT_DESTINATION"
		facing_direction = default_facing
		is_moving = false
		nav_path.clear()
		if behavior_controller:
			behavior_controller.on_destination_reached(loc_id)
		_update_visuals()
		return
		
	var root = _get_tree_root()
	var gm = root.find_child("GridManager", true, false) if root else null
	if gm and gm.has_method("find_path"):
		nav_path = gm.find_path(global_position, world_pos)
	else:
		nav_path = [world_pos]
		
	current_waypoint_index = 0
	
	if nav_path.is_empty():
		nav_failed = true
		var prev_state = current_state
		current_state = "NAVIGATION_FAILED"
		state_changed.emit(prev_state, current_state)
		navigation_failed.emit(npc_id, loc_id)
		is_moving = false
		velocity = Vector2.ZERO
		if behavior_controller:
			behavior_controller.on_navigation_failed(loc_id)
		else:
			current_state = "IDLE"
	else:
		var prev_state = current_state
		current_state = "NAVIGATING"
		is_moving = true
		state_changed.emit(prev_state, current_state)
	_update_visuals()

func teleport_to_location(loc_id: String, world_pos: Vector2, activity: String, default_facing: Vector2 = Vector2.DOWN) -> void:
	target_location_id = loc_id
	current_location_id = loc_id
	target_world_pos = world_pos
	global_position = world_pos
	current_activity = activity
	current_state = "AT_DESTINATION"
	facing_direction = default_facing
	is_moving = false
	velocity = Vector2.ZERO
	nav_path.clear()
	current_waypoint_index = 0
	var root = _get_tree_root()
	var gm = root.find_child("GridManager", true, false) if root else null
	if gm: grid_position = gm.world_to_grid(global_position)
	if behavior_controller:
		behavior_controller.on_destination_reached(loc_id)
	_update_visuals()

func turn_to_face(target_pos: Vector2) -> void:
	if target_pos.distance_to(global_position) > 0.001:
		facing_direction = (target_pos - global_position).normalized()
	_update_visuals()

func _on_anim_timeout() -> void:
	if not is_visible_in_tree(): return
	anim_frame = (anim_frame + 1) % 2
	if is_moving:
		walk_frame = anim_frame
	else:
		idle_frame = anim_frame
	_update_visuals()

func _on_player_interacted(target_pos: Vector2i) -> void:
	if not is_visible_in_tree(): return
	var root = _get_tree_root()
	var player = root.find_child("Player", true, false) if root else null
	if not player: return
	
	var dist_px = global_position.distance_to(player.global_position)
	var is_in_range = dist_px <= 32.0 or grid_position.distance_to(player.grid_position) <= 1.5 or target_pos == grid_position
	if is_in_range:
		interact()

func interact() -> void:
	is_interacting = true
	var root = _get_tree_root()
	var player = root.find_child("Player", true, false) if root else null
	if player:
		turn_to_face(player.global_position)
		
	if behavior_controller:
		behavior_controller.on_player_interaction_started()
		
	var wl = get_node_or_null("/root/WorldLoader")
	var cur_w = wl.get_current_world_id() if wl else target_world
	var net_npc = get_node_or_null("/root/NetworkNPC")
	if net_npc:
		net_npc.request_npc_interaction(cur_w, npc_id)
	else:
		var dm = get_node_or_null("/root/DialogueManager")
		if dm: dm.start_dialogue(dialogue_id, display_name, npc_id)
		
	var qm = get_node_or_null("/root/QuestManager")
	if qm:
		qm.advance_objective("talk_to_" + npc_id, 1)
		qm.advance_objective("talk", 1, npc_id)
	EventBus.npc_talked.emit(npc_id)
	_update_visuals()

func _on_dialogue_ended(_did: String = "") -> void:
	is_interacting = false
	if behavior_controller:
		behavior_controller.on_player_interaction_ended()
	if current_state in ["NAVIGATING", "TRAVELING", "WALKING"]:
		is_moving = true
	_update_visuals()

func reset_daily_schedule() -> void:
	is_interacting = false
	is_moving = false
	nav_path.clear()
	current_waypoint_index = 0
	current_state = "IDLE"
	if behavior_controller:
		behavior_controller.current_state = "IDLE"
	_update_visuals()

func get_navigation_debug_info() -> Dictionary:
	return {
		"npc_id": npc_id,
		"state": behavior_controller.current_state if behavior_controller else current_state,
		"activity": behavior_controller.current_activity if behavior_controller else current_activity,
		"animation": current_anim_name,
		"facing": get_facing_direction_string(),
		"location_id": target_location_id,
		"position": [global_position.x, global_position.y],
		"target_position": [target_world_pos.x, target_world_pos.y],
		"velocity": [velocity.x, velocity.y],
		"path_length": nav_path.size(),
		"waypoint_index": current_waypoint_index,
		"nav_failed": nav_failed,
		"social_partner": behavior_controller.social_partner_id if behavior_controller else "",
		"social_cooldown": behavior_controller.social_cooldown if behavior_controller else 0.0
	}
