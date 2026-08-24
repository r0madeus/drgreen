class_name ToolUseManager
extends RefCounted

## Central Data-Driven Tool & Item Action Execution Pipeline.
## Validates player energy, range, tool quality/power, dispatches world mutations,
## awards resource drops, and manages tool upgrades.

const TOOLS_JSON_PATH = "res://data/tools/tools.json"
const RESOURCES_JSON_PATH = "res://data/resources/resource_nodes.json"

static var _tools_data: Dictionary = {}
static var _resources_data: Dictionary = {}
static var _initialized: bool = false

static func ensure_initialized() -> void:
	if _initialized: return
	_load_data()
	_initialized = true

static func _load_data() -> void:
	# Load Tools Data
	if FileAccess.file_exists(TOOLS_JSON_PATH):
		var f = FileAccess.open(TOOLS_JSON_PATH, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				_tools_data = json.data.get("tools", {})
				
	# Load Resources Data
	if FileAccess.file_exists(RESOURCES_JSON_PATH):
		var f = FileAccess.open(RESOURCES_JSON_PATH, FileAccess.READ)
		if f:
			var text = f.get_as_text()
			f.close()
			var json = JSON.new()
			if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
				_resources_data = json.data.get("resources", {})

static func is_tool_item(tool_id: String) -> bool:
	ensure_initialized()
	if _tools_data.has(tool_id): return true
	var act = ItemRegistry.get_use_action(tool_id)
	return act in [ItemRegistry.UseAction.HOE, ItemRegistry.UseAction.WATER, ItemRegistry.UseAction.AXE, ItemRegistry.UseAction.PICKAXE]

static func get_tool_def(tool_id: String) -> Dictionary:

	ensure_initialized()
	if _tools_data.has(tool_id):
		return _tools_data[tool_id]
	# Fallback basic definition
	var use_act = ItemRegistry.get_use_action(tool_id)
	var type_str = "hoe"
	if use_act == ItemRegistry.UseAction.WATER: type_str = "watering_can"
	elif use_act == ItemRegistry.UseAction.AXE: type_str = "axe"
	elif use_act == ItemRegistry.UseAction.PICKAXE: type_str = "pickaxe"
	
	return {
		"id": tool_id,
		"type": type_str,
		"quality": "basic",
		"power": 1,
		"energy_cost": 2.0,
		"range": 1,
		"upgrade_level": 0,
		"sfx_id": "farming.plant" if type_str == "hoe" else "farming.water" if type_str == "watering_can" else "ui.select",
		"effect_id": "effect.farming.plant" if type_str == "hoe" else "effect.farming.water" if type_str == "watering_can" else "effect.farming.harvest"
	}

static func get_resource_def(resource_id: String) -> Dictionary:
	ensure_initialized()
	if _resources_data.has(resource_id):
		return _resources_data[resource_id]
	return {
		"id": resource_id,
		"name_key": "resource.node.name",
		"required_tool": "axe" if "tree" in resource_id or "wood" in resource_id else "pickaxe",
		"required_power": 1,
		"max_health": 2,
		"drops": [{ "item_id": "wood" if "tree" in resource_id else "stone", "min": 1, "max": 2, "chance": 1.0 }],
		"hit_sfx": "ui.select",
		"destroy_sfx": "farming.harvest",
		"hit_effect": "effect.farming.plant",
		"destroy_effect": "effect.farming.harvest"
	}

static func get_upgraded_tool_id(current_tool_id: String) -> String:
	var tool_def = get_tool_def(current_tool_id)
	var type_str = str(tool_def.get("type", "hoe"))
	var quality = str(tool_def.get("quality", "basic"))
	
	match quality:
		"basic": return "%s_copper" % type_str
		"copper": return "%s_iron" % type_str
		"iron": return "%s_gold" % type_str
		_: return current_tool_id

static func upgrade_tool(player_state: PlayerState, tool_type: String) -> String:
	if not player_state: return ""
	
	# Find current tool ID in inventory or hotbar
	var current_tool_id = ""
	for item_id in player_state.inventory.keys():
		if item_id.begins_with(tool_type + "_") or item_id == tool_type:
			current_tool_id = item_id
			break
			
	if current_tool_id.is_empty():
		current_tool_id = "%s_basic" % tool_type
		
	var next_tool_id = get_upgraded_tool_id(current_tool_id)
	if next_tool_id == current_tool_id:
		return current_tool_id # Max upgrade reached
		
	# Replace in inventory
	player_state.remove_item(current_tool_id, 1)
	player_state.add_item(next_tool_id, 1)
	
	# Replace in hotbar
	for i in range(player_state.hotbar_slots.size()):
		if player_state.hotbar_slots[i] == current_tool_id:
			player_state.hotbar_slots[i] = next_tool_id
			
	if player_state.selected_item_id == current_tool_id:
		player_state.selected_item_id = next_tool_id
		
	var next_def = get_tool_def(next_tool_id)
	var new_qual = str(next_def.get("quality", "copper"))
	
	var bus = Engine.get_main_loop().root.get_node_or_null("/root/EventBus")
	if bus:
		bus.tool_upgraded.emit(next_tool_id, new_qual)
		
	return next_tool_id

static func use_selected_item(player: Node2D, target_pos: Vector2i, item_id: String) -> bool:
	if not player: return false
	
	var gm = player.get("grid_manager") as GridManager
	if not gm and player.get_parent():
		gm = player.get_parent().get_node_or_null("GridManager") as GridManager
	if not gm: return false
	
	var tile = gm.get_tile(target_pos)
	if not tile: return false
	
	# Range validation
	var tool_def = get_tool_def(item_id)
	var max_range = int(tool_def.get("range", 1))
	var inter = player.get_node_or_null("Interaction")
	# Tool reach originates at the player's continuous physical position.
	if inter and not inter.is_world_position_in_range(player.global_position, target_pos, gm, max_range):
		return false
		
	var item_data = ItemRegistry.get_item(item_id)
	var use_action = item_data.get("use_action", ItemRegistry.UseAction.NONE)
	var energy_cost = float(tool_def.get("energy_cost", item_data.get("stamina_cost", 2.0)))
	var tool_power = int(tool_def.get("power", 1))
	
	var world_pos = gm.grid_to_world(target_pos, true)
	var spawner = EffectSpawner.get_instance()
	var am = player.get_node_or_null("/root/AudioManager")
	var player_state = player.player_state if "player_state" in player else null
	var wl = player.get_node_or_null("/root/WorldLoader")
	var current_world = wl.current_world_id if wl else "farm"
	var ng = player.get_node_or_null("/root/NetworkGameplay")
	var bus = player.get_node_or_null("/root/EventBus")
	
	# 1. Harvest is a universal tool interaction if plant is mature
	if gm.is_tile_harvestable(target_pos):
		if ng:
			var pid = player.player_id if "player_id" in player else ""
			ng.request_harvest(pid, current_world, target_pos)
		else:
			var res = gm.harvest_tile(target_pos)
			if not res.is_empty() and player_state:
				var crop_id = res.get("item_id", "")
				var count = res.get("yield", 1)
				player_state.add_item(crop_id, count)
				if am: am.play_sfx("farming.harvest")
				if spawner:
					spawner.spawn_harvest_effect(world_pos)
					spawner.spawn_floating_text(world_pos, "✨ +%d %s" % [count, crop_id.replace("_", " ").capitalize()], Color(1.0, 0.9, 0.3))
		return true
		
	# 2. Check Energy Sufficiency
	if player_state and player_state.energy < energy_cost:
		if spawner:
			spawner.spawn_floating_text(world_pos, "⚠️ Out of Energy!", Color(1.0, 0.3, 0.3))
		return false
		
	# 3. Dispatch based on Item UseAction
	match use_action:
		ItemRegistry.UseAction.HOE:
			if not gm.can_till_here(target_pos):
				_show_invalid_feedback(world_pos, spawner)
				return false
				
			if player_state: player_state.use_energy(energy_cost)
			if gm.till_tile(target_pos):
				if am: am.play_sfx(tool_def.get("sfx_id", "farming.plant"))
				if bus:
					bus.tool_used.emit("hoe", target_pos)
					bus.soil_tilled.emit(target_pos)
				if spawner:
					spawner.spawn_planting_effect(world_pos)
					spawner.spawn_floating_text(world_pos, "⛏️ Soil Tilled", Color(0.8, 0.6, 0.3))
			if ng and not ng.is_offline():
				var pid = player.player_id if "player_id" in player else ""
				ng.request_hoe(pid, current_world, target_pos, item_id)
			return true
			
		ItemRegistry.UseAction.WATER:
			if not (tile.type == "soil" and not tile.watered_today):
				_show_invalid_feedback(world_pos, spawner)
				return false
				
			if player_state: player_state.use_energy(energy_cost)
			if gm.water_tile(target_pos):
				if am: am.play_sfx(tool_def.get("sfx_id", "farming.water"))
				if bus:
					bus.tool_used.emit("watering_can", target_pos)
					bus.plant_watered.emit(target_pos)
				if spawner:
					spawner.spawn_watering_effect(world_pos)
					spawner.spawn_floating_text(world_pos, "💧 Watered", Color(0.4, 0.8, 1.0))
			if ng and not ng.is_offline():
				var pid = player.player_id if "player_id" in player else ""
				ng.request_water(pid, current_world, target_pos)
			return true
			
		ItemRegistry.UseAction.PLANT:
			if not gm.can_plant_here(target_pos):
				_show_invalid_feedback(world_pos, spawner)
				return false
				
			if not player_state or not player_state.has_item(item_id, 1):
				_show_invalid_feedback(world_pos, spawner)
				return false
				
			var crop_id = item_data.get("crop_id", item_id.trim_prefix("seed_"))
			if player_state.remove_item(item_id, 1):
				if gm.plant_seed(target_pos, crop_id):
					if am: am.play_sfx("farming.plant")
					if player_state: player_state.use_energy(1.0)
					if bus: bus.plant_planted.emit(target_pos, crop_id)
					if spawner:
						spawner.spawn_planting_effect(world_pos)
						spawner.spawn_floating_text(world_pos, "🌱 Planted %s" % crop_id.replace("_", " ").capitalize(), Color(0.6, 1.0, 0.5))
			if ng and not ng.is_offline():
				var pid = player.player_id if "player_id" in player else ""
				ng.request_plant(pid, current_world, target_pos, item_id)
			return true
			
		ItemRegistry.UseAction.AXE:
			if not gm.can_chop_here(target_pos):
				_show_invalid_feedback(world_pos, spawner)
				return false
				
			if player_state: player_state.use_energy(energy_cost)
			var res = gm.chop_tile(target_pos, tool_power)
			if res.get("success", false) and player_state:
				var sfx = str(res.get("sfx", "ui.select"))
				if am: am.play_sfx(sfx)
				if bus: bus.tool_used.emit("axe", target_pos)
				
				if res.get("destroyed", false):
					var drops = res.get("drops", [])
					for d in drops:
						var it_id = str(d.get("item_id", "wood"))
						var c = int(d.get("count", 1))
						player_state.add_item(it_id, c)
						if spawner:
							spawner.spawn_floating_text(world_pos, "🪓 +%d %s" % [c, it_id.capitalize()], Color(0.9, 0.7, 0.4))
				else:
					if spawner:
						spawner.spawn_floating_text(world_pos, "🪓 Chop! (HP: %d)" % int(res.get("remaining_hp", 1)), Color(0.9, 0.7, 0.4))
			if ng and not ng.is_offline():
				var pid = player.player_id if "player_id" in player else ""
				ng.request_axe(pid, current_world, target_pos, item_id)
			return true
			
		ItemRegistry.UseAction.PICKAXE:
			if not gm.can_mine_here(target_pos):
				_show_invalid_feedback(world_pos, spawner)
				return false
				
			if player_state: player_state.use_energy(energy_cost)
			var res = gm.mine_tile(target_pos, tool_power)
			if res.get("success", false) and player_state:
				var sfx = str(res.get("sfx", "ui.select"))
				if am: am.play_sfx(sfx)
				if bus: bus.tool_used.emit("pickaxe", target_pos)
				
				if res.get("destroyed", false):
					var drops = res.get("drops", [])
					for d in drops:
						var it_id = str(d.get("item_id", "stone"))
						var c = int(d.get("count", 1))
						player_state.add_item(it_id, c)
						if spawner:
							spawner.spawn_floating_text(world_pos, "⛏️ +%d %s" % [c, it_id.capitalize()], Color(0.8, 0.8, 0.9))
				else:
					if spawner:
						spawner.spawn_floating_text(world_pos, "⛏️ Mine! (HP: %d)" % int(res.get("remaining_hp", 1)), Color(0.8, 0.8, 0.9))
			if ng and not ng.is_offline():
				var pid = player.player_id if "player_id" in player else ""
				ng.request_pickaxe(pid, current_world, target_pos, item_id)
			return true

			
		_:
			_show_invalid_feedback(world_pos, spawner)
			return false

static func _show_invalid_feedback(world_pos: Vector2, spawner: EffectSpawner) -> void:
	if spawner:
		var feedback_text = TranslationServer.translate("farming.feedback.invalid")
		spawner.spawn_floating_text(world_pos, feedback_text, Color(0.85, 0.4, 0.4, 0.85))
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var am = root.get_node_or_null("/root/AudioManager") if root else null
	if am:
		am.play_sfx("ui.invalid_action")




	