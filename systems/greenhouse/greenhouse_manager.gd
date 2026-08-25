extends Node

## Central Greenhouse system managing repair stages, greenhouse tiles and growth bonuses.

signal greenhouse_state_changed(stage: int, is_repaired: bool)
signal player_zone_changed(zone_name: String)

var repair_cost: int = 500
var growth_bonus: float = 0.25
var current_stage: int = 0 # 0 = Ruined, 1 = Repaired, 2 = Upgraded
var is_repaired: bool = false
var current_zone: String = "farm" # "farm", "botanical_grove", "greenhouse"

# Special greenhouse soil grid coordinates (e.g. within greenhouse interior or designated area)
var greenhouse_tiles: Dictionary = {} # Vector2i -> true

func _ready() -> void:
	load_config()

func load_config() -> void:
	var path = "res://data/world/greenhouse.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				repair_cost = int(json.data.get("repair_cost", 500))
				growth_bonus = float(json.data.get("growth_bonus", 0.25))

func can_repair(player_id: String = "player_001") -> bool:
	if is_repaired:
		return false
	var em = get_node_or_null("/root/EconomyManager")
	return em != null and em.can_afford(player_id, repair_cost)

func repair_greenhouse(player_id: String = "player_001") -> bool:
	if is_repaired:
		return false
		
	var em = get_node_or_null("/root/EconomyManager")
	if not em or not em.spend_gold(player_id, repair_cost):
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("insufficient_gold")
		return false
		
	current_stage = 1
	is_repaired = true
	greenhouse_state_changed.emit(current_stage, is_repaired)
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("greenhouse_repair")
	
	var bus = get_node_or_null("/root/EventBus")
	if bus and bus.has_signal("greenhouse_repaired"):
		bus.emit_signal("greenhouse_repaired", current_stage)
		
	var qm = get_node_or_null("/root/QuestManager")
	if qm:
		qm.advance_objective("", "repair_greenhouse", 1, "greenhouse")
		
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		spawner.spawn_floating_text(pos, "🌿 GREENHOUSE REPAIRED!\n-%d Gold" % repair_cost, Color(0.4, 1.0, 0.4))
		
	return true

func set_zone(zone_name: String) -> void:
	current_zone = zone_name
	player_zone_changed.emit(zone_name)
	
	var qm = get_node_or_null("/root/QuestManager")
	if qm and zone_name == "botanical_grove":
		qm.advance_objective("", "explore_zone", 1, "botanical_grove")

func is_greenhouse_tile(pos: Vector2i) -> bool:
	return greenhouse_tiles.has(pos)

func register_greenhouse_tile(pos: Vector2i) -> void:
	greenhouse_tiles[pos] = true

# --- State Persistence ---
func get_greenhouse_state() -> Dictionary:
	return {
		"stage": current_stage,
		"repaired": is_repaired,
		"zone": current_zone
	}

func load_greenhouse_state(data: Dictionary) -> void:
	current_stage = int(data.get("stage", 0))
	is_repaired = bool(data.get("repaired", false))
	current_zone = str(data.get("zone", "farm"))
	greenhouse_state_changed.emit(current_stage, is_repaired)
