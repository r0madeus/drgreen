class_name GreenhouseBuilding
extends Node2D

## Interactive Greenhouse Building switching between Ruined and Repaired visuals and handling repair/entry.

@export var grid_position: Vector2i = Vector2i(23, 6)

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	update_visuals()
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	if gm_mgr: gm_mgr.greenhouse_state_changed.connect(func(_s, _r): update_visuals())
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
		if dist <= 2.2:
			prompt_label.visible = true
			var gm_mgr = get_node_or_null("/root/GreenhouseManager")
			if gm_mgr and not gm_mgr.is_repaired:
				prompt_label.text = "💬 [E] Repair Greenhouse (%d G)" % gm_mgr.repair_cost
			else:
				prompt_label.text = "🌿 [E] Greenhouse (Repaired)"
		else:
			prompt_label.visible = false

func update_visuals() -> void:
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	var is_rep = gm_mgr.is_repaired if gm_mgr else false
	if sprite:
		var asset_id = "greenhouse_repaired" if is_rep else "greenhouse_ruined"
		sprite.texture = AssetRegistry.get_asset_texture(asset_id)


func _on_player_interacted(target_pos: Vector2i) -> void:
	if not visible: return
	var player = get_tree().root.find_child("Player", true, false)
	if not player: return
	if grid_position.distance_to(player.grid_position) <= 2.2 and (target_pos == grid_position or target_pos == grid_position + Vector2i.DOWN):
		interact()

func interact() -> void:
	if not visible: return
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	if not gm_mgr: return
	if not gm_mgr.is_repaired:
		if gm_mgr.can_repair():
			gm_mgr.repair_greenhouse()
			update_visuals()
			_enable_greenhouse_beds()
		else:
			var spawner = EffectSpawner.get_instance()
			var player = get_tree().root.find_child("Player", true, false)
			var pos = player.global_position if player else Vector2(240, 180)
			if spawner:
				spawner.spawn_floating_text(pos, "❌ Need %d Gold to Repair!" % gm_mgr.repair_cost, Color(1.0, 0.4, 0.4))
	else:
		var spawner = EffectSpawner.get_instance()
		var player = get_tree().root.find_child("Player", true, false)
		var pos = player.global_position if player else Vector2(240, 180)
		if spawner:
			spawner.spawn_floating_text(pos, "🌿 Greenhouse is active! +25% growth & Winter protection.", Color(0.4, 1.0, 0.6))

func _enable_greenhouse_beds() -> void:
	var gm = get_tree().root.find_child("GridManager", true, false)
	var gm_mgr = get_node_or_null("/root/GreenhouseManager")
	if gm and gm_mgr:
		for pos in gm_mgr.greenhouse_tiles:
			gm.set_tile_type(pos, "soil")
