class_name EditorSession
extends RefCounted

## Central Editor Session manager for Botanical Haven.
## Tracks active editor module, focused entity/asset, active mod,
## dirty state, cross-editor navigation stack, and validation status.

signal module_changed(old_module: String, new_module: String)
signal entity_focused(module_id: String, entity_id: String)
signal mod_activated(mod_id: String)
signal dirty_state_changed(is_dirty: bool)
signal validation_updated(report: Dictionary)
signal navigation_occurred(from_target: Dictionary, to_target: Dictionary)

static var _instance = null

static func get_instance() -> Variant:
	if not _instance:
		_instance = load("res://editor/core/editor_session.gd").new()
	return _instance


var active_module: String = "world"
var active_entity_id: String = ""
var active_world: String = "farm"
var active_npc: String = "rowan"
var active_dialogue: String = "intro"
var active_quest: String = "quest_01"
var active_item: String = "plant_red_flower"
var active_mod: String = ""

var has_unsaved_changes: bool = false
var validation_report: Dictionary = {
	"valid": true,
	"errors": [],
	"warnings": [],
	"total_checked": 0
}

var _nav_history: Array[Dictionary] = []
var _nav_index: int = -1
const MAX_NAV_HISTORY = 50

func _init() -> void:
	pass

func set_active_module(module_id: String) -> void:
	if active_module == module_id: return
	var old_mod = active_module
	active_module = module_id
	module_changed.emit(old_mod, module_id)
	_record_navigation(module_id, active_entity_id)

func focus_entity(module_id: String, entity_id: String) -> void:
	active_module = module_id
	active_entity_id = entity_id
	
	match module_id:
		"world": active_world = entity_id
		"npc": active_npc = entity_id
		"dialogue": active_dialogue = entity_id
		"quest": active_quest = entity_id
		"item", "crop", "tool", "economy": active_item = entity_id

	entity_focused.emit(module_id, entity_id)
	_record_navigation(module_id, entity_id)

func set_active_mod(mod_id: String) -> void:
	active_mod = mod_id
	mod_activated.emit(mod_id)

func set_dirty(is_dirty: bool) -> void:
	if has_unsaved_changes != is_dirty:
		has_unsaved_changes = is_dirty
		dirty_state_changed.emit(is_dirty)

func update_validation(report: Dictionary) -> void:
	validation_report = report
	validation_updated.emit(report)

# --- Cross-Editor Navigation History ---

func _record_navigation(module_id: String, entity_id: String) -> void:
	var entry = { "module": module_id, "entity": entity_id, "timestamp": Time.get_unix_time_from_system() }
	if _nav_index >= 0 and _nav_index < _nav_history.size():
		var curr = _nav_history[_nav_index]
		if curr.get("module") == module_id and curr.get("entity") == entity_id:
			return
	
	# Trim future history if branching after back navigation
	if _nav_index < _nav_history.size() - 1:
		_nav_history = _nav_history.slice(0, _nav_index + 1)
		
	_nav_history.append(entry)
	if _nav_history.size() > MAX_NAV_HISTORY:
		_nav_history.pop_front()
	_nav_index = _nav_history.size() - 1

func can_navigate_back() -> bool:
	return _nav_index > 0

func can_navigate_forward() -> bool:
	return _nav_index < _nav_history.size() - 1

func navigate_back() -> Dictionary:
	if not can_navigate_back(): return {}
	var prev = _nav_history[_nav_index]
	_nav_index -= 1
	var target = _nav_history[_nav_index]
	active_module = target.get("module", "world")
	active_entity_id = target.get("entity", "")
	navigation_occurred.emit(prev, target)
	return target

func navigate_forward() -> Dictionary:
	if not can_navigate_forward(): return {}
	var prev = _nav_history[_nav_index]
	_nav_index += 1
	var target = _nav_history[_nav_index]
	active_module = target.get("module", "world")
	active_entity_id = target.get("entity", "")
	navigation_occurred.emit(prev, target)
	return target

func navigate_to(module_id: String, entity_id: String) -> void:
	focus_entity(module_id, entity_id)

func get_session_summary() -> Dictionary:
	return {
		"active_module": active_module,
		"active_entity": active_entity_id,
		"active_world": active_world,
		"active_npc": active_npc,
		"active_dialogue": active_dialogue,
		"active_quest": active_quest,
		"active_item": active_item,
		"active_mod": active_mod,
		"has_unsaved_changes": has_unsaved_changes,
		"validation_valid": validation_report.get("valid", true),
		"error_count": validation_report.get("errors", []).size(),
		"warning_count": validation_report.get("warnings", []).size()
	}
