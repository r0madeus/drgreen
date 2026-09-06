class_name NPCBehaviorController
extends RefCounted

## Modular, data-driven NPC behavior and social simulation controller.
## Manages state transitions, daily activities (work, eat, rest, sleep, wander, sit, shop),
## schedule interrupts, NPC-NPC social interactions, and player proximity reactions.

# Behavior States
const STATE_IDLE: String = "IDLE"
const STATE_WALKING: String = "WALKING"
const STATE_TRAVELING: String = "TRAVELING"
const STATE_NAVIGATING: String = "NAVIGATING"
const STATE_WORKING: String = "WORKING"
const STATE_SOCIALIZING: String = "SOCIALIZING"
const STATE_EATING: String = "EATING"
const STATE_RESTING: String = "RESTING"
const STATE_SITTING: String = "SITTING"
const STATE_SHOPPING: String = "SHOPPING"
const STATE_TALKING: String = "TALKING"
const STATE_PLAYER_INTERACTION: String = "PLAYER_INTERACTION"
const STATE_SLEEPING: String = "SLEEPING"
const STATE_WANDERING: String = "WANDERING"
const STATE_AT_DESTINATION: String = "AT_DESTINATION"
const STATE_NAVIGATION_FAILED: String = "NAVIGATION_FAILED"

# Interrupt Priority Levels
const INTERRUPT_NONE: int = 0
const INTERRUPT_WANDER: int = 1
const INTERRUPT_SCHEDULE: int = 2
const INTERRUPT_SOCIAL: int = 3
const INTERRUPT_QUEST: int = 4
const INTERRUPT_EMERGENCY: int = 5
const INTERRUPT_PLAYER: int = 6

var npc: Node2D = null
var current_state: String = STATE_IDLE
var current_activity: String = "home"
var current_interrupt_level: int = INTERRUPT_NONE

# Location & Targets
var target_location_id: String = ""
var target_world_pos: Vector2 = Vector2.ZERO
var fallback_location_id: String = ""

# Wander behavior
var wander_center: Vector2 = Vector2.ZERO
var wander_radius: float = 48.0
var wander_timer: float = 0.0
var wander_interval: float = 4.0
var is_wandering_paused: bool = false

# Social interaction
var social_partner_id: String = ""
var social_timer: float = 0.0
var social_cooldown: float = 0.0
const DEFAULT_SOCIAL_COOLDOWN: float = 30.0

# Interrupt state storage
var saved_state: String = STATE_IDLE
var saved_activity: String = "home"
var saved_target_pos: Vector2 = Vector2.ZERO
var saved_location_id: String = ""

func setup(p_npc: Node2D) -> void:
	npc = p_npc
	if npc:
		wander_center = npc.global_position

func set_activity(p_activity: String, p_location_id: String, p_world_pos: Vector2, priority: int = 2, fallback_loc: String = "") -> bool:
	if current_interrupt_level > priority:
		# Lower priority cannot interrupt active higher priority behavior
		return false
		
	current_activity = p_activity
	target_location_id = p_location_id
	target_world_pos = p_world_pos
	fallback_location_id = fallback_loc
	current_interrupt_level = priority
	
	if npc and npc.has_method("set_destination"):
		npc.set_destination(p_location_id, p_world_pos, p_activity)
		current_state = STATE_NAVIGATING
	else:
		current_state = STATE_TRAVELING
		
	var eb = Engine.get_main_loop().root.get_node_or_null("/root/EventBus") if (Engine.get_main_loop() and "root" in Engine.get_main_loop() and Engine.get_main_loop().root) else null
	if eb: eb.npc_activity_started.emit(npc.npc_id if npc else "unknown", p_activity)
	return true

func on_destination_reached(loc_id: String) -> void:
	target_location_id = loc_id
	wander_center = npc.global_position if npc else target_world_pos
	if npc:
		npc.is_moving = false
		npc.velocity = Vector2.ZERO

	
	match current_activity:
		"work":
			current_state = STATE_WORKING
			_play_activity_audio_vfx("work")
		"eat":
			current_state = STATE_EATING
			_play_activity_audio_vfx("eat")
		"rest":
			current_state = STATE_RESTING
		"sit":
			current_state = STATE_SITTING
		"sleep":
			current_state = STATE_SLEEPING
		"shop":
			current_state = STATE_SHOPPING
		"wander":
			current_state = STATE_WANDERING
			wander_timer = 1.0
		_:
			current_state = STATE_AT_DESTINATION
			
	var eb = Engine.get_main_loop().root.get_node_or_null("/root/EventBus") if (Engine.get_main_loop() and "root" in Engine.get_main_loop() and Engine.get_main_loop().root) else null
	if eb: eb.npc_activity_finished.emit(npc.npc_id if npc else "unknown", current_activity)

func on_player_interaction_started() -> void:
	if current_state == STATE_SOCIALIZING:
		saved_state = STATE_IDLE
		if social_partner_id != "":
			var npcm = Engine.get_main_loop().root.get_node_or_null("/root/NPCManager") if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
			if npcm and npcm.has_method("get_active_npc_instance"):
				var partner_inst = npcm.get_active_npc_instance(social_partner_id)
				if partner_inst and partner_inst.get("behavior_controller") != null:
					partner_inst.behavior_controller.end_social_interaction_early()
			social_partner_id = ""
	else:
		saved_state = current_state
		
	saved_activity = current_activity
	saved_target_pos = target_world_pos
	saved_location_id = target_location_id
	
	current_state = STATE_PLAYER_INTERACTION
	current_interrupt_level = INTERRUPT_PLAYER
	
	if npc:
		npc.velocity = Vector2.ZERO
		npc.is_moving = false

func on_player_interaction_ended() -> void:
	current_interrupt_level = INTERRUPT_NONE
	current_state = saved_state if saved_state != STATE_SOCIALIZING else STATE_IDLE
	current_activity = saved_activity
	
	if current_state in [STATE_NAVIGATING, STATE_TRAVELING, STATE_WALKING]:
		if npc and npc.has_method("set_destination") and saved_target_pos != Vector2.ZERO:
			npc.set_destination(saved_location_id, saved_target_pos, saved_activity)

func end_social_interaction_early() -> void:
	if current_state == STATE_SOCIALIZING:
		var partner = social_partner_id
		social_partner_id = ""
		current_interrupt_level = INTERRUPT_NONE
		var eb = Engine.get_main_loop().root.get_node_or_null("/root/EventBus") if (Engine.get_main_loop() and "root" in Engine.get_main_loop() and Engine.get_main_loop().root) else null
		if eb: eb.npc_social_finished.emit(npc.npc_id if npc else "unknown", partner)

func can_start_social_interaction() -> bool:
	if current_interrupt_level >= INTERRUPT_QUEST: return false
	if current_state in [STATE_PLAYER_INTERACTION, STATE_SLEEPING, STATE_NAVIGATION_FAILED, STATE_SOCIALIZING]: return false
	return social_cooldown <= 0.0 and social_partner_id == ""

func start_social_interaction(partner_id: String, duration: float = 4.0) -> void:
	saved_state = current_state if current_state != STATE_SOCIALIZING else STATE_IDLE
	saved_activity = current_activity
	social_partner_id = partner_id
	social_timer = duration
	social_cooldown = DEFAULT_SOCIAL_COOLDOWN
	current_state = STATE_SOCIALIZING
	current_interrupt_level = INTERRUPT_SOCIAL
	
	if npc:
		npc.velocity = Vector2.ZERO
		npc.is_moving = false
		
	var eb = Engine.get_main_loop().root.get_node_or_null("/root/EventBus") if (Engine.get_main_loop() and "root" in Engine.get_main_loop() and Engine.get_main_loop().root) else null
	if eb: eb.npc_social_started.emit(npc.npc_id if npc else "unknown", partner_id, "casual_greeting")

func update(delta: float) -> void:
	if social_cooldown > 0.0:
		social_cooldown = max(0.0, social_cooldown - delta)
		
	# Process Social Interaction Timer
	if current_state == STATE_SOCIALIZING:
		social_timer -= delta
		if social_timer <= 0.0:
			var finished_partner = social_partner_id
			social_partner_id = ""
			current_interrupt_level = INTERRUPT_NONE
			current_state = saved_state if saved_state != STATE_SOCIALIZING else STATE_IDLE
			var eb = Engine.get_main_loop().root.get_node_or_null("/root/EventBus") if (Engine.get_main_loop() and "root" in Engine.get_main_loop() and Engine.get_main_loop().root) else null
			if eb: eb.npc_social_finished.emit(npc.npc_id if npc else "unknown", finished_partner)
		return

		
	# Process Wander Behavior
	if current_state == STATE_WANDERING and current_interrupt_level <= INTERRUPT_WANDER:
		_process_wander(delta)

func _process_wander(delta: float) -> void:
	if not npc: return
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = wander_interval + randf_range(-1.0, 1.5)
		var offset = Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
		var candidate_pos = wander_center + offset
		
		var loop = Engine.get_main_loop()
		var gm = loop.root.find_child("GridManager", true, false) if (loop and "root" in loop and loop.root) else null
		if gm and gm.has_method("is_world_position_walkable") and gm.is_world_position_walkable(candidate_pos):
			if npc.has_method("set_destination"):
				npc.set_destination("wander_spot", candidate_pos, "wander")

func _play_activity_audio_vfx(act: String) -> void:
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var am = root.get_node_or_null("/root/AudioManager") if root else null
	var spawner = EffectSpawner.get_instance() if root else null
	var pos = npc.global_position if npc else Vector2(240, 180)
	
	match act:
		"work":
			if am and am.has_method("play_sfx"): am.play_sfx("tool_till")
			if spawner and spawner.has_method("spawn_floating_text"): spawner.spawn_floating_text(pos, "🔨", Color(0.9, 0.9, 1.0))
		"eat":
			if am and am.has_method("play_sfx"): am.play_sfx("item_harvest")
			if spawner and spawner.has_method("spawn_floating_text"): spawner.spawn_floating_text(pos, "🍎", Color(1.0, 0.9, 0.5))


func on_navigation_failed(loc_id: String) -> void:
	print("[NPCBehaviorController] Navigation failed to location: " + loc_id)
	
	# Execute deterministic fallback
	if fallback_location_id != "" and fallback_location_id != loc_id:
		var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
		var npcm = root.get_node_or_null("/root/NPCManager") if root else null
		var fb_pos = npcm.get_location_world_pos(fallback_location_id) if (npcm and npcm.has_method("get_location_world_pos")) else Vector2(224, 56)
		current_state = STATE_NAVIGATING
		if npc and npc.has_method("set_destination"):
			npc.set_destination(fallback_location_id, fb_pos, "fallback")
		return
				
	current_state = STATE_IDLE


func get_debug_dict() -> Dictionary:
	return {
		"state": current_state,
		"activity": current_activity,
		"interrupt_level": current_interrupt_level,
		"location_id": target_location_id,
		"social_partner": social_partner_id,
		"social_cooldown": social_cooldown
	}
