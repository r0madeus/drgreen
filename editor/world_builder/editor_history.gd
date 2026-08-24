class_name EditorHistory
extends RefCounted

## Undo/Redo action manager for the World Builder.

signal history_changed()

var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
const MAX_HISTORY = 100

func push_action(action: Dictionary) -> void:
	undo_stack.append(action)
	if undo_stack.size() > MAX_HISTORY:
		undo_stack.pop_front()
	redo_stack.clear()
	history_changed.emit()

func can_undo() -> bool:
	return undo_stack.size() > 0

func can_redo() -> bool:
	return redo_stack.size() > 0

func undo() -> Dictionary:
	if not can_undo():
		return {}
	var action = undo_stack.pop_back()
	redo_stack.append(action)
	history_changed.emit()
	return action

func redo() -> Dictionary:
	if not can_redo():
		return {}
	var action = redo_stack.pop_back()
	undo_stack.append(action)
	history_changed.emit()
	return action

func clear() -> void:
	undo_stack.clear()
	redo_stack.clear()
	history_changed.emit()
