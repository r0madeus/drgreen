class_name WoodenGate
extends Node2D

## Interactive gate connecting the Farm to the Botanical Grove.

@export var grid_position: Vector2i = Vector2i(31, 12)

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	EventBus.player_interacted.connect(_on_player_interacted)
	EventBus.world_changed.connect(_on_world_changed)
	var wl = get_node_or_null("/root/WorldLoader")
	_check_world_visibility(wl.current_world_id if wl else "farm")

func _on_world_changed(world_id: String, _data: Dictionary) -> void:
	_check_world_visibility(world_id)

func _check_world_visibility(world_id: String) -> void:
	var is_farm = (world_id == "farm")
	visible = is_farm
	set_process(is_farm)

func _process(_delta: float) -> void:
	if not visible: return
	var player = get_tree().root.find_child("Player", true, false)
	if player and prompt_label:
		var dist = grid_position.distance_to(player.grid_position)
		prompt_label.visible = (dist <= 1.8)

func _on_player_interacted(target_pos: Vector2i) -> void:
	if not visible: return
	var player = get_tree().root.find_child("Player", true, false)
	if not player: return
	if grid_position.distance_to(player.grid_position) <= 1.8 and target_pos.x >= 30 and (target_pos.y == 11 or target_pos.y == 12):
		interact()

func interact() -> void:
	if not visible: return
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("gate_open")
	
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	if gm_mgr: gm_mgr.set_zone("botanical_grove")
		
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner: spawner.spawn_floating_text(pos, "🌿 Botanical Grove Gate!", Color(0.4, 1.0, 0.4))
