class_name EditorPanel
extends Control

## Unified Base Class for In-Game Editor Panels.
## Standardizes opening, closing, refreshing, saving, discarding, and validation across all editor categories.

signal panel_dirtied()
signal panel_saved()
signal panel_validated(results: Dictionary)

var panel_id: String = "base_panel"
var display_name_key: String = "ui.editor.cat_base"
var icon_asset_id: String = "icon_editor"
var is_active: bool = false
var editor_service: Variant = null

func _init(p_id: String = "base_panel", p_name_key: String = "ui.editor.cat_base", p_icon: String = "icon_editor") -> void:
	panel_id = p_id
	display_name_key = p_name_key
	icon_asset_id = p_icon
	set_anchors_preset(PRESET_FULL_RECT)
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH

func setup(p_service: Variant) -> void:
	editor_service = p_service

func open_panel() -> void:
	is_active = true
	visible = true
	refresh()

func close_panel() -> void:
	is_active = false
	visible = false

func refresh() -> void:
	pass

func validate() -> Dictionary:
	return { "valid": true, "errors": [], "warnings": [] }

func has_unsaved_changes() -> bool:
	if editor_service and editor_service.has_method("is_dirty"):
		return editor_service.is_dirty()
	return false

func save() -> bool:
	if editor_service and editor_service.has_method("save"):
		return editor_service.save()
	return true

func discard_changes() -> void:
	if editor_service and editor_service.has_method("discard"):
		editor_service.discard()
