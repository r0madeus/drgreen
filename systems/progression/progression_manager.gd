extends Node

## Central Progression Manager (Autoload) managing data-driven world unlocks, chapter story arcs and unlock banners.

signal world_unlocked(world_id: String, display_name: String)
signal chapter_advanced(chapter_id: String, chapter_title: String)

var unlocked_worlds: Dictionary = { "farm": true, "town": true }
var visited_worlds: Dictionary = { "farm": true }
var world_definitions: Dictionary = {}
var chapters: Array = []
var current_chapter_index: int = 0

func _ready() -> void:
	load_progression_data()
	_connect_event_bus()

func load_progression_data() -> void:
	var path_u = "res://data/progression/world_unlocks.json"
	if FileAccess.file_exists(path_u):
		var f = FileAccess.open(path_u, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				world_definitions = json.data.get("worlds", {})
				for wid in world_definitions.keys():
					if bool(world_definitions[wid].get("unlocked_by_default", false)):
						unlocked_worlds[wid] = true

	var path_p = "res://data/progression/progression.json"
	if FileAccess.file_exists(path_p):
		var f = FileAccess.open(path_p, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				chapters = json.data.get("chapters", [])
				
	print("[ProgressionManager] Loaded %d Worlds & %d Chapters." % [world_definitions.size(), chapters.size()])

func _connect_event_bus() -> void:
	EventBus.world_changed.connect(_on_world_changed)
	EventBus.quest_completed.connect(func(_pid, _qid = ""): check_unlock_conditions())
	EventBus.plant_discovered.connect(func(_pid, _plant_id = ""): check_unlock_conditions())

func _on_world_changed(new_world: String, _wdata: Dictionary = {}) -> void:
	visited_worlds[new_world] = true
	var qm = get_node_or_null("/root/QuestManager")
	if qm: qm.advance_objective("", "visit_world", 1, new_world)
	check_unlock_conditions()


func is_world_unlocked(world_id: String) -> bool:
	return bool(unlocked_worlds.get(world_id, false))

func unlock_world(world_id: String, show_banner: bool = true) -> void:
	if not unlocked_worlds.get(world_id, false):
		unlocked_worlds[world_id] = true
		var dname = world_definitions.get(world_id, {}).get("name", world_id.capitalize())
		world_unlocked.emit(world_id, dname)
		EventBus.world_unlocked.emit(world_id, dname)
		if show_banner:
			_show_world_unlock_feedback(dname)


func check_unlock_conditions() -> void:
	var qm = get_node_or_null("/root/QuestManager")
	var jm = get_node_or_null("/root/JournalManager")
	
	for wid in world_definitions.keys():
		if unlocked_worlds.get(wid, false):
			continue
			
		var conditions = world_definitions[wid].get("unlock_conditions", [])
		var all_met = true
		for cond in conditions:
			var ctype = str(cond.get("type", ""))
			if ctype == "quest_completed":
				var req_qid = str(cond.get("quest_id", ""))
				if qm and qm.get_quest_status("", req_qid) not in [QuestManager.STATUS_COMPLETED, QuestManager.STATUS_CLAIMED]:
					all_met = false
					break
			elif ctype == "plants_discovered":
				var req_cnt = int(cond.get("count", 1))
				var disc_cnt = jm.get_discovered_plant_count() if jm else 0
				if disc_cnt < req_cnt:
					all_met = false
					break
					
		if all_met and conditions.size() > 0:
			unlock_world(wid, true)

func _show_world_unlock_feedback(world_name: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("quest_complete")
	
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		spawner.spawn_floating_text(pos, "🌟 NEW AREA UNLOCKED: " + world_name + "!", Color(1.0, 0.85, 0.2))

func get_research_progress_percentage() -> int:
	var jm = get_node_or_null("/root/JournalManager")
	if not jm: return 0
	var disc = jm.get_discovered_plant_count()
	var total = 20 # 20 base + hybrid plants
	return clampi(int((float(disc) / float(total)) * 100.0), 0, 100)
