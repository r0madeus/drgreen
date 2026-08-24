class_name EditorService
extends RefCounted

## Central In-Game Editor Service for Botanical Haven.
## Coordinates Lifecycle, Data Mutations, Multi-layered Overrides, Undo/Redo,
## Mod Management, Editor Settings, and Test Preview Mode.

signal editor_opened()
signal editor_closed()
signal dirty_state_changed(is_dirty: bool)
signal module_selected(module_id: String)
signal data_saved()
signal data_reverted()

const SETTINGS_FILE_PATH: String = "user://editor_settings.json"

static var _instance: EditorService = null

static func get_instance() -> EditorService:
	if not _instance:
		_instance = EditorService.new()
	return _instance

const EDITOR_SESSION_SCRIPT = preload("res://editor/core/editor_session.gd")

var data_service: EditorDataService
var undo_manager: EditorUndoManager
var mod_manager: ModManager
var session: Variant
var is_editor_active: bool = false
var active_module: String = "world"
var selected_object_id: String = ""

# Editor settings (independent of gameplay saves)
var settings: Dictionary = {
	"grid_visibility": true,
	"snap_to_grid": true,
	"inspector_width": 320,
	"last_opened_panel": "world",
	"theme": "dark_cozy",
	"autosave": false
}

func _init() -> void:
	session = EDITOR_SESSION_SCRIPT.get_instance()
	undo_manager = EditorUndoManager.new()
	mod_manager = ModManager.new()

	data_service = EditorDataService.new(undo_manager, mod_manager)
	
	load_editor_settings()

	data_service.dirty_state_changed.connect(func(d): 
		session.set_dirty(d)
		dirty_state_changed.emit(d)
	)
	data_service.data_saved.connect(func(): data_saved.emit())
	data_service.data_reverted.connect(func(): data_reverted.emit())


func enter_editor_mode() -> void:
	is_editor_active = true
	editor_opened.emit()

func exit_editor_mode() -> void:
	is_editor_active = false
	save_editor_settings()
	editor_closed.emit()

func select_module(module_id: String) -> void:
	active_module = module_id
	selected_object_id = ""
	settings["last_opened_panel"] = module_id
	module_selected.emit(module_id)

func select_object(object_id: String) -> void:
	selected_object_id = object_id

func navigate_to(module_id: String, entity_id: String, sub_mode: String = "") -> void:
	if session and session.has_method("navigate_to"):
		session.navigate_to(module_id, entity_id)
	select_module(module_id)
	select_object(entity_id)

func set_property(stable_id: String, property_key: String, new_val: Variant) -> void:
	data_service.set_staged_override(stable_id, property_key, new_val, true)

func restore_property_default(stable_id: String, property_key: String = "") -> void:
	data_service.restore_default(stable_id, property_key, true)

func reset_section(category_prefix: String) -> void:
	data_service.reset_section(category_prefix)

func reset_all() -> void:
	data_service.reset_all_modifications()

func undo() -> bool:
	return undo_manager.undo()

func redo() -> bool:
	return undo_manager.redo()

func can_undo() -> bool:
	return undo_manager.can_undo()

func can_redo() -> bool:
	return undo_manager.can_redo()

func is_dirty() -> bool:
	return data_service.is_dirty()

func save() -> bool:
	return data_service.save_overrides()

func save_changes() -> bool:
	return save()

func save_as(filepath: String) -> bool:
	return data_service.save_overrides(filepath)

func create_backup() -> String:
	return data_service.create_backup()

func restore_backup(backup_path: String) -> bool:
	return data_service.restore_backup(backup_path)

func list_backups() -> Array[String]:
	return data_service.list_backups()

func get_diff_summary() -> Dictionary:
	return data_service.get_diff_summary()

func get_pending_reset_diff(target_id_or_prefix: String = "") -> Dictionary:
	return data_service.get_pending_reset_diff(target_id_or_prefix)

func discard() -> void:
	data_service.discard_changes()

func validate() -> Dictionary:
	var val_script = ResourceLoader.load("res://editor/core/editor_validation_service.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	var report = val_script.validate_data(data_service) if val_script else EditorValidationService.validate_data(data_service)
	session.update_validation(report)
	return report


func start_test_preview() -> void:
	if data_service:
		data_service.apply_to_gameplay_managers()
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	var main = root.find_child("Main", true, false) if (root and not Engine.is_editor_hint()) else null
	if main and main.has_method("start_gameplay"):
		main.start_gameplay(1, false)

func load_editor_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_FILE_PATH): return
	var f = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not f: return
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
		settings.merge(json.data, true)

func save_editor_settings() -> bool:
	var f = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if not f: return false
	f.store_string(JSON.stringify(settings, "\t"))
	f.close()
	return true
