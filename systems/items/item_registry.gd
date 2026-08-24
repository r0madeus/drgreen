class_name ItemRegistry
extends RefCounted

## Central Data-Driven Item & Tool Registry.
## Defines categories, usage actions, quality levels, stack limits and tool efficiency.

enum Category { TOOL, SEED, RESOURCE, CONSUMABLE, QUEST, OTHER }
enum UseAction { NONE, HOE, WATER, PLANT, AXE, PICKAXE, INTERACT, CONSUME }
enum Quality { BASIC = 1, COPPER = 2, IRON = 3, GOLD = 4 }

const ITEMS: Dictionary = {
	# --- TOOLS: HOE ---
	"hoe_basic": { "display_name": "Basic Hoe", "category": Category.TOOL, "use_action": UseAction.HOE, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "⛏️", "stamina_cost": 2.0, "area": 1, "stackable": false, "max_stack": 1 },
	"hoe_copper": { "display_name": "Copper Hoe", "category": Category.TOOL, "use_action": UseAction.HOE, "quality": Quality.COPPER, "quality_name": "Copper", "icon": "⛏️", "stamina_cost": 1.8, "area": 1, "stackable": false, "max_stack": 1 },
	"hoe_iron": { "display_name": "Iron Hoe", "category": Category.TOOL, "use_action": UseAction.HOE, "quality": Quality.IRON, "quality_name": "Iron", "icon": "⛏️", "stamina_cost": 1.6, "area": 3, "stackable": false, "max_stack": 1 },
	"hoe_gold": { "display_name": "Gold Hoe", "category": Category.TOOL, "use_action": UseAction.HOE, "quality": Quality.GOLD, "quality_name": "Gold", "icon": "⛏️", "stamina_cost": 1.4, "area": 3, "stackable": false, "max_stack": 1 },
	"hoe": { "display_name": "Hoe", "category": Category.TOOL, "use_action": UseAction.HOE, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "⛏️", "stamina_cost": 2.0, "area": 1, "stackable": false, "max_stack": 1 },

	# --- TOOLS: WATERING CAN ---
	"watering_can_basic": { "display_name": "Basic Watering Can", "category": Category.TOOL, "use_action": UseAction.WATER, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "💧", "stamina_cost": 1.5, "area": 1, "stackable": false, "max_stack": 1 },
	"watering_can_copper": { "display_name": "Copper Watering Can", "category": Category.TOOL, "use_action": UseAction.WATER, "quality": Quality.COPPER, "quality_name": "Copper", "icon": "💧", "stamina_cost": 1.3, "area": 1, "stackable": false, "max_stack": 1 },
	"watering_can_iron": { "display_name": "Iron Watering Can", "category": Category.TOOL, "use_action": UseAction.WATER, "quality": Quality.IRON, "quality_name": "Iron", "icon": "💧", "stamina_cost": 1.1, "area": 3, "stackable": false, "max_stack": 1 },
	"watering_can_gold": { "display_name": "Gold Watering Can", "category": Category.TOOL, "use_action": UseAction.WATER, "quality": Quality.GOLD, "quality_name": "Gold", "icon": "💧", "stamina_cost": 0.9, "area": 3, "stackable": false, "max_stack": 1 },
	"watering_can": { "display_name": "Watering Can", "category": Category.TOOL, "use_action": UseAction.WATER, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "💧", "stamina_cost": 1.5, "area": 1, "stackable": false, "max_stack": 1 },

	# --- TOOLS: AXE ---
	"axe_basic": { "display_name": "Basic Axe", "category": Category.TOOL, "use_action": UseAction.AXE, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "🪓", "stamina_cost": 2.0, "area": 1, "stackable": false, "max_stack": 1 },
	"axe_copper": { "display_name": "Copper Axe", "category": Category.TOOL, "use_action": UseAction.AXE, "quality": Quality.COPPER, "quality_name": "Copper", "icon": "🪓", "stamina_cost": 1.8, "area": 1, "stackable": false, "max_stack": 1 },
	"axe_iron": { "display_name": "Iron Axe", "category": Category.TOOL, "use_action": UseAction.AXE, "quality": Quality.IRON, "quality_name": "Iron", "icon": "🪓", "stamina_cost": 1.6, "area": 1, "stackable": false, "max_stack": 1 },
	"axe_gold": { "display_name": "Gold Axe", "category": Category.TOOL, "use_action": UseAction.AXE, "quality": Quality.GOLD, "quality_name": "Gold", "icon": "🪓", "stamina_cost": 1.4, "area": 1, "stackable": false, "max_stack": 1 },
	"axe": { "display_name": "Axe", "category": Category.TOOL, "use_action": UseAction.AXE, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "🪓", "stamina_cost": 2.0, "area": 1, "stackable": false, "max_stack": 1 },

	# --- TOOLS: PICKAXE ---
	"pickaxe_basic": { "display_name": "Basic Pickaxe", "category": Category.TOOL, "use_action": UseAction.PICKAXE, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "⛏️", "stamina_cost": 2.0, "area": 1, "stackable": false, "max_stack": 1 },
	"pickaxe_copper": { "display_name": "Copper Pickaxe", "category": Category.TOOL, "use_action": UseAction.PICKAXE, "quality": Quality.COPPER, "quality_name": "Copper", "icon": "⛏️", "stamina_cost": 1.8, "area": 1, "stackable": false, "max_stack": 1 },
	"pickaxe_iron": { "display_name": "Iron Pickaxe", "category": Category.TOOL, "use_action": UseAction.PICKAXE, "quality": Quality.IRON, "quality_name": "Iron", "icon": "⛏️", "stamina_cost": 1.6, "area": 1, "stackable": false, "max_stack": 1 },
	"pickaxe_gold": { "display_name": "Gold Pickaxe", "category": Category.TOOL, "use_action": UseAction.PICKAXE, "quality": Quality.GOLD, "quality_name": "Gold", "icon": "⛏️", "stamina_cost": 1.4, "area": 1, "stackable": false, "max_stack": 1 },
	"pickaxe": { "display_name": "Pickaxe", "category": Category.TOOL, "use_action": UseAction.PICKAXE, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "⛏️", "stamina_cost": 2.0, "area": 1, "stackable": false, "max_stack": 1 },

	# --- SEEDS ---
	"seed_red_flower": { "display_name": "Red Flower Seed", "category": Category.SEED, "use_action": UseAction.PLANT, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "🌱", "crop_id": "red_flower", "stackable": true, "max_stack": 99 },
	"seed_blue_flower": { "display_name": "Blue Flower Seed", "category": Category.SEED, "use_action": UseAction.PLANT, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "🌱", "crop_id": "blue_flower", "stackable": true, "max_stack": 99 },
	"seed_yellow_herb": { "display_name": "Yellow Herb Seed", "category": Category.SEED, "use_action": UseAction.PLANT, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "🌱", "crop_id": "yellow_herb", "stackable": true, "max_stack": 99 },
	"seed_green_vine": { "display_name": "Green Vine Seed", "category": Category.SEED, "use_action": UseAction.PLANT, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "🌱", "crop_id": "green_vine", "stackable": true, "max_stack": 99 },
	"seed_white_lily": { "display_name": "White Lily Seed", "category": Category.SEED, "use_action": UseAction.PLANT, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "🌱", "crop_id": "white_lily", "stackable": true, "max_stack": 99 },

	# --- CROPS & HARVEST ---
	"red_flower": { "display_name": "Red Flower", "category": Category.RESOURCE, "use_action": UseAction.NONE, "quality": Quality.BASIC, "icon": "🌸", "stackable": true, "max_stack": 99 },
	"blue_flower": { "display_name": "Blue Flower", "category": Category.RESOURCE, "use_action": UseAction.NONE, "quality": Quality.BASIC, "icon": "🌺", "stackable": true, "max_stack": 99 },
	"yellow_herb": { "display_name": "Yellow Herb", "category": Category.RESOURCE, "use_action": UseAction.NONE, "quality": Quality.BASIC, "icon": "🌿", "stackable": true, "max_stack": 99 },
	"green_vine": { "display_name": "Green Vine", "category": Category.RESOURCE, "use_action": UseAction.NONE, "quality": Quality.BASIC, "icon": "🌾", "stackable": true, "max_stack": 99 },
	"white_lily": { "display_name": "White Lily", "category": Category.RESOURCE, "use_action": UseAction.NONE, "quality": Quality.BASIC, "icon": "🪷", "stackable": true, "max_stack": 99 },

	# --- RESOURCES ---
	"wood": { "display_name": "Wood", "category": Category.RESOURCE, "use_action": UseAction.NONE, "quality": Quality.BASIC, "icon": "🪵", "stackable": true, "max_stack": 999 },
	"stone": { "display_name": "Stone", "category": Category.RESOURCE, "use_action": UseAction.NONE, "quality": Quality.BASIC, "icon": "🪨", "stackable": true, "max_stack": 999 }
}

static func get_item(item_id: String) -> Dictionary:
	if ITEMS.has(item_id):
		return ITEMS[item_id].duplicate()
	if item_id.begins_with("seed_"):
		var crop_name = item_id.trim_prefix("seed_").replace("_", " ").capitalize()
		return { "display_name": crop_name + " Seed", "category": Category.SEED, "use_action": UseAction.PLANT, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "🌱", "crop_id": item_id.trim_prefix("seed_"), "stackable": true, "max_stack": 99 }
	return { "display_name": item_id.replace("_", " ").capitalize(), "category": Category.OTHER, "use_action": UseAction.NONE, "quality": Quality.BASIC, "quality_name": "Basic", "icon": "📦", "stackable": true, "max_stack": 99 }

static func get_use_action(item_id: String) -> UseAction:
	var d = get_item(item_id)
	return d.get("use_action", UseAction.NONE)

static func get_use_action_name(item_id: String) -> String:
	match get_use_action(item_id):
		UseAction.HOE: return "HOE"
		UseAction.WATER: return "WATER"
		UseAction.PLANT: return "PLANT"
		UseAction.AXE: return "AXE"
		UseAction.PICKAXE: return "PICKAXE"
		UseAction.CONSUME: return "CONSUME"
		UseAction.INTERACT: return "INTERACT"
		_: return "NONE"

static func get_display_name(item_id: String) -> String:
	return get_localized_name(item_id)

static func get_localized_name(item_id: String) -> String:
	var lm = Engine.get_main_loop().root.get_node_or_null("/root/LocalizationManager")
	if lm:
		return lm.get_item_name(item_id)
	var key = "item.%s.name" % item_id
	if item_id.begins_with("hoe_") or item_id.begins_with("watering_can_") or item_id.begins_with("axe_") or item_id.begins_with("pickaxe_"):
		key = "tool.%s.name" % item_id
	var trans = TranslationServer.translate(key)
	if trans != key:
		return trans
	return str(get_item(item_id).get("display_name", item_id))

static func get_localized_description(item_id: String) -> String:
	var lm = Engine.get_main_loop().root.get_node_or_null("/root/LocalizationManager")
	if lm:
		return lm.get_item_description(item_id)
	return ""

static func get_icon(item_id: String) -> String:
	return str(get_item(item_id).get("icon", "📦"))

static func get_quality(item_id: String) -> Quality:
	return get_item(item_id).get("quality", Quality.BASIC)

static func get_quality_name(item_id: String) -> String:
	var q = get_quality(item_id)
	match q:
		Quality.COPPER: return TranslationServer.translate("tool.quality.copper")
		Quality.IRON: return TranslationServer.translate("tool.quality.iron")
		Quality.GOLD: return TranslationServer.translate("tool.quality.gold")
		_: return TranslationServer.translate("tool.quality.basic")

static func is_tool_item(item_id: String) -> bool:
	return get_item(item_id).get("category") == Category.TOOL


static func is_seed(item_id: String) -> bool:
	return get_item(item_id).get("category") == Category.SEED


	