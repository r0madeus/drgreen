class_name EditorUndoManager
extends RefCounted

## Command-Pattern Undo / Redo Manager for the Botanical Haven In-Game Editor.
## Encapsulates reversible editor modifications across World, NPC, Dialogue, Quest, Items, and Properties.

class EditorAction extends RefCounted:
	var name: String = "Modify Property"
	var stable_id: String = ""
	var property_key: String = ""
	var old_value: Variant = null
	var new_value: Variant = null
	var apply_callback: Callable

	func _init(p_name: String, p_stable_id: String, p_prop: String, p_old: Variant, p_new: Variant, p_callback: Callable = Callable()) -> void:
		name = p_name
		stable_id = p_stable_id
		property_key = p_prop
		old_value = p_old
		new_value = p_new
		apply_callback = p_callback

	func execute() -> void:
		if apply_callback.is_valid():
			apply_callback.call(stable_id, property_key, new_value)

	func undo() -> void:
		if apply_callback.is_valid():
			apply_callback.call(stable_id, property_key, old_value)

	func redo() -> void:
		execute()

var _undo_stack: Array[EditorAction] = []
var _redo_stack: Array[EditorAction] = []
var max_history: int = 50

func push_action(action: EditorAction) -> void:
	if not action: return
	_undo_stack.append(action)
	if _undo_stack.size() > max_history:
		_undo_stack.pop_front()
	_redo_stack.clear()

func undo() -> bool:
	if _undo_stack.is_empty(): return false
	var action = _undo_stack.pop_back()
	action.undo()
	_redo_stack.append(action)
	return true

func redo() -> bool:
	if _redo_stack.is_empty(): return false
	var action = _redo_stack.pop_back()
	action.redo()
	_undo_stack.append(action)
	return true

func can_undo() -> bool:
	return not _undo_stack.is_empty()

func can_redo() -> bool:
	return not _redo_stack.is_empty()

func get_undo_action_name() -> String:
	return _undo_stack.back().name if not _undo_stack.is_empty() else ""

func get_redo_action_name() -> String:
	return _redo_stack.back().name if not _redo_stack.is_empty() else ""

func get_undo_count() -> int:
	return _undo_stack.size()

func get_redo_count() -> int:
	return _redo_stack.size()

func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
