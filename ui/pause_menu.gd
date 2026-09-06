class_name PauseMenu
extends Control

## Cozy Botanical Fantasy Pause & Settings Menu with audio controls and save/load shortcuts.

@onready var resume_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton
@onready var save_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SaveButton
@onready var load_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LoadButton
@onready var options_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsButton
@onready var quit_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/QuitButton

@onready var options_panel: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsPanel

func _ready() -> void:
	visible = false
	theme = UIConstants.get_theme()
	if resume_btn: resume_btn.pressed.connect(close_menu)
	if save_btn: save_btn.pressed.connect(_on_save_pressed)
	if load_btn: load_btn.pressed.connect(_on_load_pressed)
	if options_btn: options_btn.pressed.connect(_toggle_options)
	if quit_btn: quit_btn.pressed.connect(_on_quit_pressed)
	
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(func(_l): _update_localized_texts())
	_update_localized_texts()
	
	var am = get_node_or_null("/root/AudioManager")
	var master_slider = find_child("MasterSlider", true, false) as HSlider
	var sfx_slider = find_child("SFXSlider", true, false) as HSlider
	var music_slider = find_child("MusicSlider", true, false) as HSlider
	
	if master_slider and am:
		master_slider.value = am.master_volume
		master_slider.value_changed.connect(func(v): am.set_master_volume(v))
	if sfx_slider and am:
		sfx_slider.value = am.sfx_volume
		sfx_slider.value_changed.connect(func(v): am.set_sfx_volume(v))
	if music_slider and am:
		music_slider.value = am.music_volume
		music_slider.value_changed.connect(func(v): am.set_music_volume(v))

func _update_localized_texts() -> void:
	var title = find_child("TitleLabel", true, false) as Label
	if title: title.text = tr("ui.pause.title")
	if resume_btn: resume_btn.text = tr("ui.pause.resume")
	if save_btn: save_btn.text = tr("ui.pause.save")
	if load_btn: load_btn.text = tr("ui.pause.load")
	if options_btn: options_btn.text = tr("ui.pause.settings")
	if quit_btn: quit_btn.text = tr("ui.pause.main_menu")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			# Check if any modal is currently open
			var modals = [
				get_tree().root.find_child("InventoryUI", true, false),
				get_tree().root.find_child("CombinationUI", true, false),
				get_tree().root.find_child("JournalUI", true, false),
				get_tree().root.find_child("QuestUI", true, false),
				get_tree().root.find_child("ShopUI", true, false),
				get_tree().root.find_child("DialogueUI", true, false)
			]
			if UIConstants.is_any_modal_open(get_tree()):
				UIConstants.close_all_modals(get_tree(), null)
				UIConstants.update_player_lock(get_tree())
				get_viewport().set_input_as_handled()
				return
				
			# Toggle Pause Menu
			toggle_menu()
			get_viewport().set_input_as_handled()

func toggle_menu() -> void:
	if visible:
		close_menu()
	else:
		open_menu()

func open_menu() -> void:
	UIConstants.close_all_modals(get_tree(), self)
	visible = true
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	UIConstants.update_player_lock(get_tree())

func close_menu() -> void:
	visible = false
	if options_panel: options_panel.visible = false
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	UIConstants.update_player_lock(get_tree())

var settings_ui: SettingsUI = null

func _ensure_settings_ui() -> void:
	if not settings_ui or not is_instance_valid(settings_ui):
		settings_ui = get_tree().root.find_child("SettingsUI", true, false) as SettingsUI
		if not settings_ui:
			var scene = load("res://systems/settings/settings_ui.tscn")
			if scene:
				settings_ui = scene.instantiate() as SettingsUI
				var parent_node = get_parent() if get_parent() else self
				parent_node.add_child(settings_ui)

func _toggle_options() -> void:
	_ensure_settings_ui()
	if settings_ui:
		settings_ui.open_settings()
	elif options_panel:
		options_panel.visible = not options_panel.visible
		var am = get_node_or_null("/root/AudioManager")
		if am: am.play_sfx("ui_select")


func _on_save_pressed() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm: sm.save_game()

func _on_load_pressed() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.load_game()
		close_menu()

func _on_main_menu_pressed() -> void:
	close_menu()
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var main = root.find_child("Main", true, false) if root else null
	if main and main.has_method("return_to_main_menu"):
		main.return_to_main_menu()
	else:
		var mm = root.find_child("MainMenu", true, false) if root else null
		if mm and mm.has_method("open_menu"):
			mm.open_menu()

func _on_quit_pressed() -> void:
	_on_main_menu_pressed()


