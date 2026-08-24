class_name EditorRegistry
extends RefCounted

## Central Registry for In-Game Editor Panels.
## Allows modular registration of World, NPC, Dialogue, Quest, Item, Crop,
## Tool, Shop, Schedule, Event, Relationship, Asset, Audio, Localization, and Mod panels.

static var _panel_types: Dictionary = {} # panel_id -> Script or Callable
static var _panel_metadata: Dictionary = {} # panel_id -> Dictionary (name_key, icon, priority)

const EDITOR_PANEL_SCRIPT = preload("res://editor/core/editor_panel.gd")
const WORLD_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/world_editor_panel.gd")
const NPC_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/npc_editor_panel.gd")
const DIALOGUE_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/dialogue_editor_panel.gd")
const QUEST_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/quest_editor_panel.gd")
const ITEM_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/item_editor_panel.gd")
const MOD_MANAGER_PANEL_SCRIPT = preload("res://editor/ui/panels/mod_manager_panel.gd")
const ASSET_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/asset_editor_panel.gd")
const GAME_STUDIO_PANEL_SCRIPT = preload("res://editor/ui/panels/game_studio_panel.gd")
const GAMEPLAY_RULES_PANEL_SCRIPT = preload("res://editor/ui/panels/gameplay_rules_editor_panel.gd")
const CUSTOM_COMP_PANEL_SCRIPT = preload("res://editor/ui/panels/custom_component_editor_panel.gd")
const MECHANIC_GRAPH_PANEL_SCRIPT = preload("res://editor/ui/panels/mechanic_graph_editor_panel.gd")

static func _static_init() -> void:
	_ensure_defaults()

static func _ensure_defaults() -> void:
	if not _panel_types.has("studio"):
		register_panel("studio", GAME_STUDIO_PANEL_SCRIPT, "ui.editor.cat_studio", "icon_studio", 5)
	if not _panel_types.has("rules"):
		register_panel("rules", GAMEPLAY_RULES_PANEL_SCRIPT, "ui.editor.cat_rules", "icon_rules", 52)
	if not _panel_types.has("custom_components"):
		register_panel("custom_components", CUSTOM_COMP_PANEL_SCRIPT, "ui.editor.cat_components", "icon_component", 53)
	if not _panel_types.has("mechanics"):
		register_panel("mechanics", MECHANIC_GRAPH_PANEL_SCRIPT, "ui.editor.cat_mechanics", "icon_mechanics", 54)
	if not _panel_types.has("world"):
		register_panel("world", WORLD_EDITOR_PANEL_SCRIPT, "ui.editor.cat_world", "icon_world", 10)
	if not _panel_types.has("npc"):
		register_panel("npc", NPC_EDITOR_PANEL_SCRIPT, "ui.editor.cat_npc", "icon_npc", 20)
	if not _panel_types.has("dialogue"):
		register_panel("dialogue", DIALOGUE_EDITOR_PANEL_SCRIPT, "ui.editor.cat_dialogue", "icon_dialogue", 30)
	if not _panel_types.has("quest"):
		register_panel("quest", QUEST_EDITOR_PANEL_SCRIPT, "ui.editor.cat_quest", "icon_quest", 40)
	if not _panel_types.has("item"):
		register_panel("item", ITEM_EDITOR_PANEL_SCRIPT, "ui.editor.cat_item", "icon_item", 50)
	if not _panel_types.has("assets"):
		register_panel("assets", ASSET_EDITOR_PANEL_SCRIPT, "ui.editor.cat_assets", "icon_asset", 55)
	if not _panel_types.has("mods"):
		register_panel("mods", MOD_MANAGER_PANEL_SCRIPT, "ui.editor.cat_mods", "icon_mods", 60)

static func register_panel(panel_id: String, panel_factory: Variant, name_key: String = "", icon_id: String = "icon_editor", priority: int = 100) -> void:
	if panel_id == "": return
	_panel_types[panel_id] = panel_factory
	_panel_metadata[panel_id] = {
		"id": panel_id,
		"name_key": name_key if name_key != "" else ("ui.editor.cat_" + panel_id),
		"icon_id": icon_id,
		"priority": priority
	}

static func unregister_panel(panel_id: String) -> void:
	_panel_types.erase(panel_id)
	_panel_metadata.erase(panel_id)

static func has_panel(panel_id: String) -> bool:
	_ensure_defaults()
	return _panel_types.has(panel_id)

static func create_panel(panel_id: String, editor_service: Variant = null) -> Control:
	_ensure_defaults()
	if not _panel_types.has(panel_id):
		var meta = _panel_metadata.get(panel_id, {})
		var fallback = EDITOR_PANEL_SCRIPT.new(panel_id, str(meta.get("name_key", "ui.editor.cat_" + panel_id)), str(meta.get("icon_id", "icon_editor")))
		if editor_service and fallback.has_method("setup"):
			fallback.setup(editor_service)
		return fallback
		
	var factory = _panel_types[panel_id]
	var panel: Control = null
	if factory is Script:
		panel = factory.new() as Control
	elif factory is Callable:
		panel = factory.call() as Control
		
	if panel and editor_service and panel.has_method("setup"):
		panel.setup(editor_service)
	return panel

static func get_registered_panel_ids() -> Array[String]:
	_ensure_defaults()
	var list: Array[String] = []
	for k in _panel_types.keys():
		list.append(str(k))
	return list

static func get_registered_panels() -> Array[String]:
	return get_registered_panel_ids()

static func get_all_panel_metadata() -> Array[Dictionary]:
	_ensure_defaults()
	var list: Array[Dictionary] = []
	for k in _panel_metadata.keys():
		list.append(_panel_metadata[k])
	list.sort_custom(func(a, b): return int(a.get("priority", 100)) < int(b.get("priority", 100)))
	return list

static func clear() -> void:
	_panel_types.clear()
	_panel_metadata.clear()
