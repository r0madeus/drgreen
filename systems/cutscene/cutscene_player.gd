extends Node
class_name CutscenePlayer

const CutsceneManagerScript = preload("res://systems/cutscene/cutscene_manager.gd")

signal finished(cutscene_id: String)
signal event_triggered(event: Dictionary)

var _cutscene_data: Dictionary = {}
var _is_playing: bool = false
var _is_paused: bool = false
var _current_time: float = 0.0
var _duration: float = 0.0

var _events: Array = []
var _active_tweens: Array = []
var _waiting_for_dialogue: bool = false

var cutscene_manager: Node = null

func _ready() -> void:
	var dm = get_node_or_null("/root/DialogueManager")
	if dm:
		dm.dialogue_ended.connect(_on_dialogue_ended)

func play(cid: String) -> bool:
	if not cutscene_manager:
		cutscene_manager = CutsceneManagerScript.new()
		add_child(cutscene_manager)
		
	var data = cutscene_manager.get_cutscene(cid)
	if data.is_empty():
		push_error("[CutscenePlayer] Cutscene not found: " + cid)
		return false
		
	_cutscene_data = data
	_duration = float(data.get("duration", 5.0))
	_current_time = 0.0
	_is_playing = true
	_is_paused = false
	_waiting_for_dialogue = false
	
	_build_event_queue()
	
	if cutscene_manager.has_user_signal("cutscene_started"):
		cutscene_manager.cutscene_started.emit(cid)
		
	return true

func stop() -> void:
	if not _is_playing: return
	_is_playing = false
	_is_paused = false
	for t in _active_tweens:
		if is_instance_valid(t):
			t.kill()
	_active_tweens.clear()
	_waiting_for_dialogue = false
	
	var cid = _cutscene_data.get("id", "")
	finished.emit(cid)
	if cutscene_manager and cutscene_manager.has_user_signal("cutscene_finished"):
		cutscene_manager.cutscene_finished.emit(cid)

func pause() -> void:
	_is_paused = true
	for t in _active_tweens:
		if is_instance_valid(t):
			t.pause()

func resume() -> void:
	_is_paused = false
	for t in _active_tweens:
		if is_instance_valid(t):
			t.play()

func _build_event_queue() -> void:
	_events.clear()
	for track in _cutscene_data.get("tracks", []):
		var actor_id = track.get("actor_id", "")
		for evt in track.get("events", []):
			var e = evt.duplicate(true)
			e["actor_id"] = actor_id
			_events.append(e)
	
	_events.sort_custom(func(a, b): return float(a.get("start", 0)) < float(b.get("start", 0)))

func _process(delta: float) -> void:
	if not _is_playing or _is_paused:
		return
		
	if _waiting_for_dialogue:
		return
		
	var old_time = _current_time
	_current_time += delta
	
	# Check for events that should trigger between old_time and _current_time
	var i = 0
	while i < _events.size():
		var e = _events[i]
		var start_t = float(e.get("start", 0))
		if start_t <= _current_time:
			_trigger_event(e)
			_events.remove_at(i)
		else:
			i += 1
			
	if _current_time >= _duration and _events.size() == 0 and not _waiting_for_dialogue:
		stop()

func _trigger_event(e: Dictionary) -> void:
	event_triggered.emit(e)
	var type = e.get("type", "")
	var actor_id = e.get("actor_id", "")
	var params = e.get("params", {})
	var dur = float(e.get("duration", 0.0))
	
	var actor_node = _resolve_actor(actor_id)
	
	match type:
		"dialogue":
			var did = params.get("dialogue_id", "")
			var dm = get_node_or_null("/root/DialogueManager")
			if dm and did != "":
				dm.start_dialogue("player_001", did, actor_id, actor_id)
				_waiting_for_dialogue = true
		"move":
			if actor_node and dur > 0:
				var tpos = params.get("target_pos", [0, 0])
				var target = Vector2(tpos[0], tpos[1])
				var t = create_tween()
				t.tween_property(actor_node, "global_position", target, dur)
				_active_tweens.append(t)
				t.finished.connect(func(): _active_tweens.erase(t))
		"camera_move":
			var cam = _get_camera()
			if cam and dur > 0:
				var target_node_id = params.get("target_node", "")
				var tpos = cam.global_position
				if target_node_id != "":
					var target_node = _resolve_actor(target_node_id)
					if target_node:
						tpos = target_node.global_position
				elif params.has("target_pos"):
					var ppos = params.get("target_pos", [0,0])
					tpos = Vector2(ppos[0], ppos[1])
				
				var t = create_tween()
				# If camera is attached to player, we might need to detach it or override
				# For now, just tween global_position
				t.tween_property(cam, "global_position", tpos, dur)
				if params.has("zoom"):
					t.parallel().tween_property(cam, "zoom", Vector2.ONE * float(params.get("zoom")), dur)
				_active_tweens.append(t)
				t.finished.connect(func(): _active_tweens.erase(t))
		"play_animation":
			if actor_node:
				var anim_name = params.get("anim_name", "")
				var ap = _get_animation_player(actor_node)
				if ap and ap.has_animation(anim_name):
					ap.play(anim_name)
		"play_music":
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_music"):
				am.play_music(params.get("track", ""))
		"play_sound":
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"):
				am.play_sfx(params.get("sound", ""))
		"wait":
			pass # Waiting is naturally handled by duration and timeline spacing, no strict block needed unless specifically requested

func _on_dialogue_ended(_dialogue_id: String) -> void:
	_waiting_for_dialogue = false

func _resolve_actor(actor_id: String) -> Node:
	var tree = get_tree()
	if not tree or not tree.root: return null
	
	if actor_id == "player":
		return tree.root.find_child("Player", true, false)
	
	# Look for specific NPC
	var npcs = tree.get_nodes_in_group("npc")
	for n in npcs:
		if n.name.to_lower() == actor_id.to_lower():
			return n
		if "npc_id" in n and n.npc_id == actor_id:
			return n
	
	# Fallback to general find
	return tree.root.find_child(actor_id, true, false)

func _get_camera() -> Camera2D:
	var tree = get_tree()
	if not tree or not tree.root: return null
	var cam = tree.root.find_child("Camera2D", true, false)
	if cam is Camera2D: return cam
	return null

func _get_animation_player(actor: Node) -> AnimationPlayer:
	if not actor: return null
	var ap = actor.find_child("AnimationPlayer", true, false)
	if ap is AnimationPlayer: return ap
	return null
