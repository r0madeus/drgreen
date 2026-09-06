class_name SeedMerchant
extends Node2D

## Seed Merchant NPC standing at a market stall, providing seed purchases, crop selling,
## obstacle-aware path navigation, 4-directional facing, and animation mapping.

signal destination_reached(npc_id: String, location_id: String)
signal state_changed(old_state: String, new_state: String)
signal navigation_failed(npc_id: String, location_id: String)

const NPC_BEHAVIOR_CONTROLLER_SCRIPT = preload("res://systems/npc/npc_behavior_controller.gd")

@export var grid_position: Vector2i = Vector2i(15, 3)
@export var shop_ui: ShopUI
@export var walk_speed: float = 38.0

@onready var stall_sprite: Sprite2D = get_node_or_null("StallSprite")
@onready var merchant_sprite: Sprite2D = get_node_or_null("MerchantSprite")
@onready var prompt_label: Label = get_node_or_null("PromptLabel")
@onready var anim_timer: Timer = get_node_or_null("AnimTimer")

var npc_id: String = "rowan"
var behavior_controller = NPC_BEHAVIOR_CONTROLLER_SCRIPT.new()

var current_state: String = "IDLE"
var current_activity: String = "work"
var current_location_id: String = "seed_shop"
var target_location_id: String = ""
var target_world_pos: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.DOWN
var velocity: Vector2 = Vector2.ZERO
var is_interacting: bool = false
var is_moving: bool = false
var anim_frame: int = 0
var current_anim_name: String = "idle"
var nav_path: Array = []
var current_waypoint_index: int = 0
var nav_failed: bool = false

func _get_tree_root() -> Window:
	var tree = get_tree()
	if tree and tree.root: return tree.root
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root: return loop.root
	return null

func _ready() -> void:
	_update_position()
	if behavior_controller:
		behavior_controller.setup(self)
		
	if stall_sprite:
		stall_sprite.texture = AssetRegistry.get_npc_texture("market_stall")
		stall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stall_sprite.position = Vector2(0, -6)

	if merchant_sprite:
		merchant_sprite.texture = AssetRegistry.get_npc_texture("merchant", 0)
		merchant_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		merchant_sprite.position = Vector2(0, -8)
		
	if prompt_label:
		prompt_label.text = "💬 [E] Talk"
		prompt_label.add_theme_font_size_override("font_size", 9)
		prompt_label.modulate = Color(1.0, 1.0, 0.6)
		prompt_label.position = Vector2(-22, -26)
		prompt_label.visible = false
		
	if anim_timer:
		anim_timer.wait_time = 0.35
		anim_timer.timeout.connect(_on_anim_timer_timeout)
		anim_timer.start()
		
	var eb = get_node_or_null("/root/EventBus")
	if eb:
		eb.player_interacted.connect(_on_player_interacted)
		eb.world_changed.connect(_on_world_changed)
	var wl = get_node_or_null("/root/WorldLoader")
	_check_world_visibility(wl.current_world_id if wl else "farm")
	var dm = get_node_or_null("/root/DialogueManager")
	if dm and dm.has_signal("dialogue_ended"):
		dm.dialogue_ended.connect(_on_dialogue_ended)

func _update_position() -> void:
	var root = _get_tree_root()
	var gm = root.find_child("GridManager", true, false) if root else null
	if gm:
		position = gm.grid_to_world(grid_position, true)
	else:
		position = Vector2(grid_position.x * 16 + 8, grid_position.y * 16 + 8)

func _on_world_changed(world_id: String, _data: Dictionary = {}) -> void:
	_check_world_visibility(world_id)

func _check_world_visibility(world_id: String) -> void:
	var is_farm = (world_id == "farm")
	visible = is_farm
	set_process(is_farm)

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


func _process(delta: float) -> void:
	if not visible: return
	
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
	destination_reached.emit("rowan", target_location_id)
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
		navigation_failed.emit("rowan", loc_id)
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

func _update_visuals() -> void:
	if not merchant_sprite: return
	
	var desired_anim = get_current_animation_name()
	current_anim_name = desired_anim
	var dir_str = get_facing_direction_string()
	var frame_idx = anim_frame
	
	var tex = AssetRegistry.get_npc_animation_texture("merchant", desired_anim, dir_str, frame_idx)
	if tex: merchant_sprite.texture = tex
	
	if dir_str == "left":
		merchant_sprite.flip_h = true
	elif dir_str == "right":
		merchant_sprite.flip_h = false

func _on_anim_timer_timeout() -> void:
	if not visible: return
	anim_frame = (anim_frame + 1) % 2
	_update_visuals()

func _on_player_interacted(target_pos: Vector2i) -> void:
	if not visible: return
	var root = _get_tree_root()
	var player = root.find_child("Player", true, false) if root else null
	if not player: return
	var dist_px = global_position.distance_to(player.global_position)
	var is_in_range = dist_px <= 32.0 or grid_position.distance_to(player.grid_position) <= 1.5 or target_pos == grid_position
	if is_in_range:
		interact()

func interact() -> void:
	if not visible: return
	is_interacting = true
	var root = _get_tree_root()
	var player = root.find_child("Player", true, false) if root else null
	if player:
		turn_to_face(player.global_position)

	if behavior_controller:
		behavior_controller.on_player_interaction_started()

	var pid: String = player.player_id if (player and "player_id" in player) else "player_001"

	var net_npc = get_node_or_null("/root/NetworkNPC")
	if net_npc:
		net_npc.request_npc_interaction("farm", "rowan")
	else:
		var dm = get_node_or_null("/root/DialogueManager")
		if dm: dm.start_dialogue(pid, "rowan", "Rowan the Herbalist", "rowan")
	
	var qm = get_node_or_null("/root/QuestManager")
	if qm:
		qm.advance_objective(pid, "talk_to_merchant", 1, "")
	var eb = get_node_or_null("/root/EventBus")
	if eb: eb.npc_talked.emit(pid, "rowan")
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
