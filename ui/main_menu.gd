@tool
class_name MainMenuUI
extends Control

## Cozy Botanical Fantasy Main Menu controller.
## Manages Continue, New Game, Saves, Editor, Multiplayer, Settings, Credits, and Quit.

signal new_game_started(slot_idx: int)
signal game_continued(slot_idx: int)
signal editor_requested()
signal settings_requested()
signal credits_requested()
signal multiplayer_requested()
signal saves_requested()
signal quit_requested()

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var continue_btn: Button = find_child("ContinueButton", true, false)
@onready var new_game_btn: Button = find_child("NewGameButton", true, false)
@onready var saves_btn: Button = find_child("SavesButton", true, false)
@onready var editor_btn: Button = find_child("EditorButton", true, false)
@onready var multiplayer_btn: Button = find_child("MultiplayerButton", true, false)
@onready var settings_btn: Button = find_child("SettingsButton", true, false)
@onready var credits_btn: Button = find_child("CreditsButton", true, false)
@onready var quit_btn: Button = find_child("QuitButton", true, false)

var save_select_ui: SaveSelectUI = null
var credits_ui: CreditsUI = null
var editor_shell: Node = null
var settings_ui: SettingsUI = null
var multiplayer_ui: MultiplayerUI = null

var _is_transitioning: bool = false

func _init() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH

func _ready() -> void:
	_bind_buttons()
	var lm = _get_localization_manager()
	if lm:
		lm.locale_changed.connect(func(_l): _update_localized_texts())
	var sm = _get_settings_manager()
	if sm:
		if sm.has_signal("setting_changed") and not sm.setting_changed.is_connected(_on_setting_changed):
			sm.setting_changed.connect(_on_setting_changed)
		if sm.has_signal("settings_applied") and not sm.settings_applied.is_connected(_on_settings_applied):
			sm.settings_applied.connect(_on_settings_applied)
	_update_localized_texts()
	_update_continue_button()
	_update_editor_button_visibility()

func _on_setting_changed(category: String, key: String, _value: Variant) -> void:
	if category == "developer" or key == "developer_mode":
		_update_editor_button_visibility()

func _on_settings_applied() -> void:
	_update_editor_button_visibility()

func _bind_buttons() -> void:
	if continue_btn and not continue_btn.pressed.is_connected(_on_continue):
		continue_btn.pressed.connect(_on_continue)
	if new_game_btn and not new_game_btn.pressed.is_connected(_on_new_game):
		new_game_btn.pressed.connect(_on_new_game)
	if saves_btn and not saves_btn.pressed.is_connected(_on_saves):
		saves_btn.pressed.connect(_on_saves)
	if editor_btn and not editor_btn.pressed.is_connected(_on_editor):
		editor_btn.pressed.connect(_on_editor)
	if multiplayer_btn and not multiplayer_btn.pressed.is_connected(_on_multiplayer):
		multiplayer_btn.pressed.connect(_on_multiplayer)
	if settings_btn and not settings_btn.pressed.is_connected(_on_settings):
		settings_btn.pressed.connect(_on_settings)
	if credits_btn and not credits_btn.pressed.is_connected(_on_credits):
		credits_btn.pressed.connect(_on_credits)
	if quit_btn and not quit_btn.pressed.is_connected(_on_quit):
		quit_btn.pressed.connect(_on_quit)

func _update_localized_texts() -> void:
	if continue_btn: continue_btn.text = "📂 " + tr("ui.menu.continue")
	if new_game_btn: new_game_btn.text = "🌱 " + tr("ui.menu.new_game")
	if saves_btn: saves_btn.text = "💾 " + tr("ui.menu.saves")
	if editor_btn: editor_btn.text = "🛠️ EDITOR"
	if multiplayer_btn: multiplayer_btn.text = "🌐 " + tr("ui.menu.multiplayer")
	if settings_btn: settings_btn.text = "⚙️ " + tr("ui.menu.settings")
	if credits_btn: credits_btn.text = "📜 " + tr("ui.menu.credits")
	if quit_btn: quit_btn.text = "✕ " + tr("ui.menu.quit")

func _get_player() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("Player", true, false)
	return null

func _get_audio_manager() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("AudioManager")
	return null

func _get_save_manager() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("SaveManager")
	return null

func _get_localization_manager() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("LocalizationManager")
	return null

func _get_settings_manager() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("SettingsManager")
	return null

func _get_local_state_manager() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("LocalStateManager")
	return null

func _update_continue_button() -> void:
	if continue_btn:
		var sm = _get_save_manager()
		var has_save = sm.has_any_save() if sm else false
		continue_btn.disabled = not has_save
		continue_btn.modulate = Color(1.0, 1.0, 1.0) if has_save else Color(0.6, 0.6, 0.6, 0.5)

func _update_editor_button_visibility() -> void:
	if not editor_btn: return
	var is_dev_mode = false
	var sm = _get_settings_manager()
	if sm:
		is_dev_mode = bool(sm.get_setting("developer", "developer_mode", false))
	else:
		var lsm = _get_local_state_manager()
		if lsm:
			is_dev_mode = bool(lsm.get_setting("developer", "developer_mode", false))
		else:
			var defs = SettingsData.get_default_settings()
			is_dev_mode = bool(defs.get("developer", {}).get("developer_mode", false))
	editor_btn.visible = is_dev_mode

func open_menu() -> void:
	visible = true
	_update_continue_button()
	_update_editor_button_visibility()
	var player = _get_player()
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(true)

func close_menu() -> void:
	visible = false
	var player = _get_player()
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)

func _on_continue() -> void:
	var am = _get_audio_manager()
	if am: am.play_sfx("ui_select")
	
	var sm = _get_save_manager()
	var has_save = sm.has_any_save() if sm else false
	if has_save:
		var latest_slot = sm.get_latest_save_slot() if sm and sm.has_method("get_latest_save_slot") else 1
		if latest_slot <= 0: latest_slot = 1
		game_continued.emit(latest_slot)
		close_menu()
	else:
		_update_continue_button()

func _on_new_game() -> void:
	var am = _get_audio_manager()
	if am: am.play_sfx("ui_select")
	
	_ensure_save_select_ui()
	if save_select_ui:
		visible = false
		save_select_ui.open_ui()
	else:
		new_game_started.emit(1)
		close_menu()

func _on_saves() -> void:
	saves_requested.emit()
	var am = _get_audio_manager()
	if am: am.play_sfx("ui_select")
	
	_ensure_save_select_ui()
	if save_select_ui:
		visible = false
		save_select_ui.open_ui()

func _on_editor() -> void:
	var am = _get_audio_manager()
	if am and am.has_method("play_sfx"): am.play_sfx("ui_select")
	
	editor_requested.emit()
	close_menu()
	
	var main = get_tree().root.find_child("Main", true, false) if (is_inside_tree() and get_tree() and get_tree().root) else null
	if not main and get_parent() and get_parent().get_parent() and get_parent().get_parent().has_method("open_editor"):
		main = get_parent().get_parent()
	if main and main.has_method("open_editor") and main.current_mode != 2:
		main.open_editor()

func _on_settings() -> void:
	var am = _get_audio_manager()
	if am: am.play_sfx("ui_select")
	
	settings_requested.emit()
	
	if not settings_ui or not is_instance_valid(settings_ui):
		var scene = load("res://systems/settings/settings_ui.tscn")
		if scene:
			settings_ui = scene.instantiate() as SettingsUI
			var parent_node = get_parent() if get_parent() else self
			parent_node.add_child(settings_ui)
			if not settings_ui.back_pressed.is_connected(open_menu):
				settings_ui.back_pressed.connect(open_menu)
			
	if settings_ui:
		visible = false
		settings_ui.open_settings()

func _on_credits() -> void:
	var am = _get_audio_manager()
	if am: am.play_sfx("ui_select")
	
	credits_requested.emit()
	
	if not credits_ui or not is_instance_valid(credits_ui):
		credits_ui = CreditsUI.new()
		var parent_node = get_parent() if get_parent() else self
		parent_node.add_child(credits_ui)
		if not credits_ui.closed.is_connected(open_menu):
			credits_ui.closed.connect(open_menu)
			
	if credits_ui:
		visible = false
		credits_ui.open_credits()

func _on_multiplayer() -> void:
	var am = _get_audio_manager()
	if am: am.play_sfx("ui_select")
	
	multiplayer_requested.emit()
	
	if not multiplayer_ui or not is_instance_valid(multiplayer_ui):
		multiplayer_ui = MultiplayerUI.new()
		var parent_node = get_parent() if get_parent() else self
		parent_node.add_child(multiplayer_ui)
		if not multiplayer_ui.back_pressed.is_connected(open_menu):
			multiplayer_ui.back_pressed.connect(open_menu)
			
	if multiplayer_ui:
		visible = false
		multiplayer_ui.open_ui()

func _on_quit() -> void:
	var am = _get_audio_manager()
	if am: am.play_sfx("ui_select")
	quit_requested.emit()
	if is_inside_tree() and get_tree():
		get_tree().quit()

func _ensure_save_select_ui() -> void:
	if not save_select_ui or not is_instance_valid(save_select_ui):
		var scene = load("res://ui/save_select_ui.tscn")
		if scene:
			save_select_ui = scene.instantiate() as SaveSelectUI
			var parent_node = get_parent() if get_parent() else self
			parent_node.add_child(save_select_ui)
		if save_select_ui:
			if not save_select_ui.slot_loaded.is_connected(_on_slot_loaded):
				save_select_ui.slot_loaded.connect(_on_slot_loaded)
			if not save_select_ui.slot_new_game_started.is_connected(_on_slot_new_game):
				save_select_ui.slot_new_game_started.connect(_on_slot_new_game)
			if not save_select_ui.back_pressed.is_connected(open_menu):
				save_select_ui.back_pressed.connect(open_menu)

func _on_slot_loaded(slot_idx: int) -> void:
	game_continued.emit(slot_idx)
	close_menu()

func _on_slot_new_game(slot_idx: int) -> void:
	new_game_started.emit(slot_idx)
	close_menu()
