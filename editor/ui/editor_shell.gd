class_name EditorShell
extends Control

## Responsive In-Game Content Creation & Modding Editor Shell.
## Features Left Category Navigation, Center Workspace, Right Property Inspector,
## Top Command Bar (Undo/Redo/Save/Test/Reset), Bottom Status Bar, and Dirty Exit Confirmation.

signal exit_requested()
signal test_preview_requested()

var editor_service: EditorService = null

# Top Bar UI
var title_label: Label
var save_btn: Button
var undo_btn: Button
var redo_btn: Button
var discard_btn: Button
var reset_btn: Button
var test_btn: Button
var exit_btn: Button

# Nav UI
var nav_container: BoxContainer
var _nav_buttons: Dictionary = {}

# Main Workspace UI
var workspace_container: PanelContainer
var active_panel_container: Control
var current_panel_node: Control = null
var _panels_cache: Dictionary = {}

# Bottom Status UI
var status_label: Label
var dirty_label: Label
var validation_label: Label
var changes_label: Label

# Exit Confirmation Dialog
var exit_dialog: ConfirmationDialog
var reset_dialog: ConfirmationDialog
var _ui_built: bool = false

func _init() -> void:
	name = "EditorShell"
	editor_service = EditorService.get_instance()
	set_anchors_preset(PRESET_FULL_RECT)

	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH
	_build_ui()
	_connect_service_signals()

func _ready() -> void:
	if not _ui_built:
		_build_ui()
		_connect_service_signals()
	_refresh_all()

func _connect_service_signals() -> void:
	if not editor_service: return
	editor_service.dirty_state_changed.connect(func(_d): _update_status_and_buttons())
	editor_service.module_selected.connect(func(_m): _on_module_changed())
	editor_service.data_saved.connect(func(): _update_status_and_buttons())
	editor_service.data_reverted.connect(func(): _refresh_all())

func open_editor() -> void:
	visible = true
	if editor_service: editor_service.enter_editor_mode()
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	var player = root.find_child("Player", true, false) if root else null
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(true)
	_refresh_all()

func close_editor() -> void:
	visible = false
	if editor_service: editor_service.exit_editor_mode()
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	var player = root.find_child("Player", true, false) if root else null
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
	exit_requested.emit()

func _build_ui() -> void:
	if _ui_built: return
	_ui_built = true

	# Main Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.14, 0.16, 1.0)
	add_child(bg)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	add_child(main_vbox)

	# --- GLOBAL HEADER ---
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 32)
	main_vbox.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_bar.add_child(top_hbox)

	title_label = Label.new()
	title_label.text = " Botanical Haven Editor "
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.modulate = Color(0.6, 1.0, 0.7)
	top_hbox.add_child(title_label)

	var top_sep1 = VSeparator.new()
	top_hbox.add_child(top_sep1)

	nav_container = HBoxContainer.new()
	nav_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(nav_container)
	_build_nav_buttons()

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer)

	undo_btn = Button.new()
	undo_btn.text = "↶ Undo"
	undo_btn.tooltip_text = "Undo last change (Ctrl+Z)"
	undo_btn.add_theme_font_size_override("font_size", 12)
	undo_btn.pressed.connect(_on_undo_pressed)
	top_hbox.add_child(undo_btn)

	redo_btn = Button.new()
	redo_btn.text = "↷ Redo"
	redo_btn.tooltip_text = "Redo last undone change (Ctrl+Y)"
	redo_btn.add_theme_font_size_override("font_size", 12)
	redo_btn.pressed.connect(_on_redo_pressed)
	top_hbox.add_child(redo_btn)

	save_btn = Button.new()
	save_btn.text = "💾 Save"
	save_btn.tooltip_text = "Save all modifications (Ctrl+S)"
	save_btn.add_theme_font_size_override("font_size", 12)
	save_btn.pressed.connect(_on_save_pressed)
	top_hbox.add_child(save_btn)

	test_btn = Button.new()
	test_btn.text = "▶ Play"
	test_btn.tooltip_text = "Test current slice in live gameplay"
	test_btn.modulate = Color(0.4, 1.0, 0.5)
	test_btn.add_theme_font_size_override("font_size", 12)
	test_btn.pressed.connect(_on_test_preview_pressed)
	top_hbox.add_child(test_btn)

	var top_sep2 = VSeparator.new()
	top_hbox.add_child(top_sep2)

	exit_btn = Button.new()
	exit_btn.text = "✕ Exit"
	exit_btn.tooltip_text = "Return to Main Menu (Esc)"
	exit_btn.modulate = Color(1.0, 0.7, 0.7)
	exit_btn.add_theme_font_size_override("font_size", 12)
	exit_btn.pressed.connect(_on_exit_pressed)
	top_hbox.add_child(exit_btn)

	# --- MAIN WORKSPACE ---
	workspace_container = PanelContainer.new()
	workspace_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(workspace_container)

	active_panel_container = PanelContainer.new()
	active_panel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	active_panel_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace_container.add_child(active_panel_container)

	# --- BOTTOM STATUS BAR ---
	var bottom_bar = PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 22)
	main_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_bar.add_child(bottom_hbox)

	status_label = Label.new()
	status_label.text = "Status: Ready"
	status_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_label)

	var bspacer = Control.new()
	bspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(bspacer)

	changes_label = Label.new()
	changes_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(changes_label)

	dirty_label = Label.new()
	dirty_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(dirty_label)

	validation_label = Label.new()
	validation_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(validation_label)

	_build_exit_dialog()
	_build_reset_dialog()
	_build_validation_dialog()
	_build_onboarding_dialog()

func _build_nav_buttons() -> void:
	var categories = [
		{ "id": "world", "name": "🌍 World", "tooltip": "World & Map Editor", "prefix": "world." },
		{ "id": "npc", "name": "👤 NPCs", "tooltip": "NPC & Character Editor", "prefix": "npc." },
		{ "id": "dialogue", "name": "💬 Dialogue", "tooltip": "Dialogue Tree Editor", "prefix": "dialogue." },
		{ "id": "quest", "name": "📜 Quests", "tooltip": "Quest & Objective Editor", "prefix": "quest." },
		{ "id": "items", "name": "🎒 Items", "tooltip": "Item & Inventory Editor", "prefix": "item." },
		{ "id": "crops", "name": "🌱 Crops", "tooltip": "Plant & Crop Authoring", "prefix": "crop." },
		{ "id": "genetics", "name": "🧬 Genetics", "tooltip": "Genetics & Trait Editor", "prefix": "genetic." },
		{ "id": "combination", "name": "🔗 Synthesis", "tooltip": "Combination & Hybrid Lab", "prefix": "combination." },
		{ "id": "cutscene", "name": "🎬 Cutscenes", "tooltip": "Timeline Cutscene Editor", "prefix": "cutscene." },
		{ "id": "audio", "name": "🔊 Audio", "tooltip": "Audio & Music Bus Editor", "prefix": "audio." },
		{ "id": "progression", "name": "🗺 Progression", "tooltip": "Progression & Unlock Editor", "prefix": "progression." },
		{ "id": "discovery", "name": "📖 Codex", "tooltip": "Discovery Codex Editor", "prefix": "discovery." },
		{ "id": "assets", "name": "🎨 Assets", "tooltip": "Asset & Component Editor", "prefix": "asset." },
		{ "id": "mods", "name": "⚙️ Mods", "tooltip": "Mod Package Manager", "prefix": "mod." }
	]

	for c in categories:
		var btn = Button.new()
		btn.text = c.name
		btn.tooltip_text = c.tooltip
		btn.add_theme_font_size_override("font_size", 12)
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.pressed.connect(func(): _select_category(c.id, c.prefix))
		nav_container.add_child(btn)
		_nav_buttons[c.id] = btn

func _select_category(cat_id: String, prefix: String) -> void:
	if editor_service:
		editor_service.select_module(cat_id)

	for k in _nav_buttons.keys():
		if _nav_buttons[k]:
			_nav_buttons[k].modulate = Color(0.5, 1.0, 0.7) if k == cat_id else Color.WHITE

	var panel_id = cat_id
	if cat_id in ["items", "crops", "tools", "crop", "tool", "item", "shops", "schedules", "assets"]:
		# fallback to default generic panels if EditorRegistry is missing some, or route correctly
		if EditorRegistry.has_panel(panel_id): pass
		else: panel_id = "item"

	if EditorRegistry.has_panel(panel_id):
		if current_panel_node and is_instance_valid(current_panel_node):
			current_panel_node.visible = false
		if not _panels_cache.has(panel_id):
			var panel = EditorRegistry.create_panel(panel_id, editor_service)
			if panel:
				active_panel_container.add_child(panel)
				_panels_cache[panel_id] = panel
		current_panel_node = _panels_cache.get(panel_id, null)
		if current_panel_node:
			current_panel_node.visible = true
			if current_panel_node.has_method("open_panel"):
				current_panel_node.open_panel()
			if panel_id == "item" and current_panel_node.has_method("focus_entry"):
				current_panel_node.focus_entry("", cat_id)
		
		# Now that active_panel_container dominates, no other docks to toggle.
		return

	# Fallback if no panel registered
	if status_label:
		status_label.text = "No dedicated panel for category: " + cat_id

func _populate_item_list(prefix: String) -> void:
	pass

func _inspect_object(stable_id: String) -> void:
	pass

func _on_property_changed(stable_id: String, key: String, new_val_str: String) -> void:
	var parsed_val: Variant = new_val_str
	if new_val_str.is_valid_int():
		parsed_val = int(new_val_str)
	elif new_val_str.is_valid_float():
		parsed_val = float(new_val_str)
	elif new_val_str.to_lower() == "true":
		parsed_val = true
	elif new_val_str.to_lower() == "false":
		parsed_val = false

	editor_service.set_property(stable_id, key, parsed_val)
	_update_status_and_buttons()

func _refresh_all() -> void:
	_update_status_and_buttons()
	var active_cat = editor_service.active_module if editor_service else "world"
	var prefix = "world." if active_cat == "world" else ("npc." if active_cat == "npc" else "")
	_select_category(active_cat, prefix)

func _update_status_and_buttons() -> void:
	if not editor_service: return
	var dirty = editor_service.is_dirty()
	
	
	
	
	if dirty_label:
		dirty_label.text = "UNSAVED CHANGES" if dirty else "SAVED"
		dirty_label.modulate = Color(1.0, 0.65, 0.2) if dirty else Color(0.4, 0.9, 0.4)

	var change_count = editor_service.data_service.get_change_count() if (editor_service and editor_service.data_service) else 0
	if changes_label:
		changes_label.text = "Changes: %d" % change_count

	var val_report = editor_service.validate() if editor_service else {}
	var errors: Array = val_report.get("errors", [])
	var warnings: Array = val_report.get("warnings", [])
	if validation_label:
		if errors.size() > 0:
			validation_label.text = "ERROR (%d)" % errors.size()
			validation_label.modulate = Color(1.0, 0.35, 0.35)
		elif warnings.size() > 0:
			validation_label.text = "WARNING (%d)" % warnings.size()
			validation_label.modulate = Color(1.0, 0.85, 0.2)
		else:
			validation_label.text = "VALID"
			validation_label.modulate = Color(0.4, 0.9, 0.4)

func _on_module_changed() -> void:
	pass

func _build_exit_dialog() -> void:
	exit_dialog = ConfirmationDialog.new()
	exit_dialog.title = "Unsaved Changes"
	exit_dialog.dialog_text = "You have unsaved changes in the editor. Save before exiting?"
	exit_dialog.ok_button_text = "Save & Exit"
	exit_dialog.cancel_button_text = "Discard & Exit"
	exit_dialog.confirmed.connect(func(): editor_service.save(); close_editor())
	exit_dialog.canceled.connect(func(): editor_service.discard(); close_editor())
	add_child(exit_dialog)

func _build_reset_dialog() -> void:
	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = "Reset All Modifications"
	reset_dialog.dialog_text = "Are you sure you want to reset all modifications back to base game defaults?"
	reset_dialog.ok_button_text = "Reset Everything"
	reset_dialog.confirmed.connect(func(): editor_service.reset_all(); _refresh_all())
	add_child(reset_dialog)

func _on_exit_pressed() -> void:
	if editor_service and editor_service.is_dirty():
		exit_dialog.popup_centered()
	else:
		close_editor()

func _on_reset_pressed() -> void:
	reset_dialog.popup_centered()

func _on_test_preview_pressed() -> void:
	test_preview_requested.emit()
	if editor_service:
		editor_service.start_test_preview()

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	var focus_owner = get_viewport().gui_get_focus_owner() if get_viewport() else null
	if focus_owner and (focus_owner is LineEdit or focus_owner is TextEdit):
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z and event.ctrl_pressed:
			if event.shift_pressed:
				editor_service.redo()
			else:
				editor_service.undo()
			_refresh_all()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_Y and event.ctrl_pressed:
			editor_service.redo()
			_refresh_all()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_S and event.ctrl_pressed:
			editor_service.save()
			_update_status_and_buttons()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_exit_pressed()
			get_viewport().set_input_as_handled()


func _on_session_entity_focused(module_id: String, entity_id: String) -> void:
	_select_category(module_id, "")
	if current_panel_node:
		if module_id in ["item", "items", "crop", "crops", "tool", "tools"] and current_panel_node.has_method("focus_entry"):
			current_panel_node.focus_entry(entity_id, module_id)
		elif module_id == "npc" and current_panel_node.has_method("focus_npc"):
			current_panel_node.focus_npc(entity_id)
		elif module_id == "world" and current_panel_node.has_method("focus_asset_for_placement"):
			current_panel_node.focus_asset_for_placement(entity_id)


## Public project outline & hierarchy inspection for Authoring Workspace (Phase 36)
func get_project_outline() -> Dictionary:
	var ds = editor_service.data_service if editor_service else null
	AssetRegistry.ensure_initialized()
	var outline = {
		"assets": AssetRegistry.get_all_asset_ids(),
		"worlds": ds.get_all_stable_ids("world.") if ds else [],
		"npcs": ds.get_all_stable_ids("npc.") if ds else [],
		"items": ds.get_all_stable_ids("item.") if ds else [],
		"crops": ds.get_all_stable_ids("crop.") if ds else [],
		"tools": ds.get_all_stable_ids("tool.") if ds else [],
		"dialogues": ds.get_all_stable_ids("dialogue.") if ds else [],
		"quests": ds.get_all_stable_ids("quest.") if ds else []
	}
	return outline

var validation_dialog: AcceptDialog
var onboarding_dialog: AcceptDialog
var help_btn: Button

func _build_validation_dialog() -> void:
	validation_dialog = AcceptDialog.new()
	validation_dialog.title = "Global Project Validation Report"
	validation_dialog.size = Vector2i(500, 350)
	add_child(validation_dialog)

func show_validation_report() -> void:
	if not validation_dialog or not editor_service: return
	var val_report = editor_service.validate()
	var errors: Array = val_report.get("errors", [])
	var warnings: Array = val_report.get("warnings", [])
	
	var msg = "Checked %d stable entities.\n\n" % val_report.get("total_checked", 0)
	if errors.is_empty() and warnings.is_empty():
		msg += " All entities, worlds, dialogues, quests, and assets are 100% VALID!\nNo broken references detected."
	else:
		if errors.size() > 0:
			msg += "=== ERRORS (%d) ===\n" % errors.size()
			for e in errors:
				if typeof(e) == TYPE_DICTIONARY:
					msg += "â€¢ [%s] %s\n" % [e.get("category", "General").to_upper(), e.get("message", "")]
				else:
					msg += "â€¢ %s\n" % str(e)
			msg += "\n"
		if warnings.size() > 0:
			msg += "=== WARNINGS (%d) ===\n" % warnings.size()
			for w in warnings:
				if typeof(w) == TYPE_DICTIONARY:
					msg += "â€¢ [%s] %s\n" % [w.get("category", "General").to_upper(), w.get("message", "")]
				else:
					msg += "â€¢ %s\n" % str(w)
	validation_dialog.dialog_text = msg
	if is_inside_tree():
		validation_dialog.popup_centered()

func _build_onboarding_dialog() -> void:
	onboarding_dialog = AcceptDialog.new()
	onboarding_dialog.title = "Getting Started: Content Authoring Guide"
	onboarding_dialog.size = Vector2i(520, 360)
	onboarding_dialog.dialog_text = """WELCOME TO BOTANICAL HAVEN IN-GAME CONTENT AUTHORING!

Follow these 8 steps to build and publish your custom expansion:

1.  Mod Workspace: Open Mod Manager and click '+ Create Mod'.
2.  Import Assets: Add custom textures in the Asset Editor.
3.  Build Worlds: Create maps and paint terrain with brushes.
4.  Author NPCs: Create characters and define their schedules.
5.  Branching Dialogue: Build conversations and trigger quests.
6.  Quests & Rewards: Configure objectives, rewards, and world unlocks.
7.  Validate & Playtest: Verify zero errors and test live in-game!
8.  Export .bhmod: Package into a portable archive for players.

Press F12 anytime to toggle the In-Game Editor."""
	add_child(onboarding_dialog)

func show_onboarding_guide() -> void:
	if onboarding_dialog and is_inside_tree():
		onboarding_dialog.popup_centered()


func _on_save_pressed() -> void:
	if current_panel_node and current_panel_node.has_method("save"):
		current_panel_node.save()
	elif editor_service and editor_service.has_method("save"):
		editor_service.save()

func _on_undo_pressed() -> void:
	if editor_service: editor_service.undo()

func _on_redo_pressed() -> void:
	if editor_service: editor_service.redo()
	
