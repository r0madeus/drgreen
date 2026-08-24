class_name ModManagerPanel
extends EditorPanel

## In-Game Mod Management, Packaging, Conflict Resolution & Project Overview Panel (Phase 33).
## Enables players and creators to create, export (.bhmod), import, enable/disable, preview,
## and resolve conflicts for game modifications inside Botanical Haven.

var mod_list_container: VBoxContainer
var preview_label: Label
var conflict_label: Label
var mod_manager: ModManager
var session: Variant


var create_mod_dialog: ConfirmationDialog
var mod_id_edit: LineEdit
var mod_name_edit: LineEdit
var mod_author_edit: LineEdit
var mod_desc_edit: LineEdit

var selected_mod_id: String = ""

func _init() -> void:
	super._init("mods", "ui.editor.cat_mods", "icon_mods")

func setup(p_service: Variant) -> void:
	super.setup(p_service)
	if editor_service:
		mod_manager = editor_service.mod_manager
		session = editor_service.session
	_build_ui()
	refresh()

func refresh() -> void:
	_populate_mod_list()
	_update_conflict_view()

func _build_ui() -> void:
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.grow_horizontal = GROW_DIRECTION_BOTH
	main_vbox.grow_vertical = GROW_DIRECTION_BOTH
	add_child(main_vbox)

	# --- TOP TOOLBAR ---
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_bar.add_child(top_hbox)

	var title_lbl = Label.new()
	title_lbl.text = " Mod Manager & Project Packaging"
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.modulate = Color(0.4, 0.9, 1.0)
	top_hbox.add_child(title_lbl)

	top_hbox.add_spacer(false)

	var new_mod_btn = Button.new()
	new_mod_btn.text = " Create Mod"
	new_mod_btn.pressed.connect(_on_create_mod_pressed)
	top_hbox.add_child(new_mod_btn)

	var export_btn = Button.new()
	export_btn.text = " Export Mod (.bhmod)"
	export_btn.pressed.connect(_on_export_mod_pressed)
	top_hbox.add_child(export_btn)

	var import_btn = Button.new()
	import_btn.text = " Import Mod"
	import_btn.pressed.connect(_on_import_mod_pressed)
	top_hbox.add_child(import_btn)

	var refresh_btn = Button.new()
	refresh_btn.text = " Refresh"
	refresh_btn.pressed.connect(refresh)
	top_hbox.add_child(refresh_btn)

	# --- MAIN 2-COLUMN SPLIT ---
	var split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(split)

	# Left Column: Installed Mods
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(300, 0)
	split.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_panel.add_child(left_vbox)

	var list_header = Label.new()
	list_header.text = "INSTALLED MODS"
	list_header.add_theme_font_size_override("font_size", 11)
	list_header.modulate = Color(0.7, 0.7, 0.7)
	left_vbox.add_child(list_header)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(scroll)

	mod_list_container = VBoxContainer.new()
	mod_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(mod_list_container)

	# Right Column: Mod Details, Preview & Conflicts
	var right_panel = PanelContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right_panel)

	var right_vbox = VBoxContainer.new()
	right_panel.add_child(right_vbox)

	var details_header = Label.new()
	details_header.text = "MOD PREVIEW & CONFLICT DIAGNOSTICS"
	details_header.add_theme_font_size_override("font_size", 11)
	details_header.modulate = Color(0.7, 0.7, 0.7)
	right_vbox.add_child(details_header)

	preview_label = Label.new()
	preview_label.text = "Select a mod to inspect overrides and package details."
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(preview_label)

	var sep = HSeparator.new()
	right_vbox.add_child(sep)

	conflict_label = Label.new()
	conflict_label.text = "Conflicts: None detected (100% clean override pipeline)"
	conflict_label.modulate = Color(0.5, 1.0, 0.5)
	right_vbox.add_child(conflict_label)

	_build_create_mod_dialog()

func _build_create_mod_dialog() -> void:
	create_mod_dialog = ConfirmationDialog.new()
	create_mod_dialog.title = "Create New Botanical Haven Mod"
	create_mod_dialog.confirmed.connect(_on_confirm_create_mod)
	add_child(create_mod_dialog)

	var vbox = VBoxContainer.new()
	create_mod_dialog.add_child(vbox)

	var l_id = Label.new(); l_id.text = "Mod ID (slug):"
	vbox.add_child(l_id)
	mod_id_edit = LineEdit.new()
	mod_id_edit.placeholder_text = "e.g. mystical_grove_overhaul"
	vbox.add_child(mod_id_edit)

	var l_name = Label.new(); l_name.text = "Mod Display Name:"
	vbox.add_child(l_name)
	mod_name_edit = LineEdit.new()
	mod_name_edit.placeholder_text = "e.g. Mystical Grove Overhaul"
	vbox.add_child(mod_name_edit)

	var l_auth = Label.new(); l_auth.text = "Author:"
	vbox.add_child(l_auth)
	mod_author_edit = LineEdit.new()
	mod_author_edit.placeholder_text = "e.g. Master Botanist"
	vbox.add_child(mod_author_edit)

	var l_desc = Label.new(); l_desc.text = "Description:"
	vbox.add_child(l_desc)
	mod_desc_edit = LineEdit.new()
	mod_desc_edit.placeholder_text = "e.g. Expands the forest with magical flora and new NPCs."
	vbox.add_child(mod_desc_edit)

func _populate_mod_list() -> void:
	if not mod_list_container or not mod_manager: return
	for child in mod_list_container.get_children():
		child.queue_free()

	var all_mods = mod_manager.get_all_mods()
	if all_mods.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No mods installed. Click ' Create Mod' to start!"
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		mod_list_container.add_child(empty_lbl)
		return

	for m in all_mods:
		var card = PanelContainer.new()
		var hbox = HBoxContainer.new()
		card.add_child(hbox)

		var chk = CheckBox.new()
		chk.button_pressed = m.enabled
		var mod_id_ref = m.id
		chk.toggled.connect(func(enabled):
			if enabled: mod_manager.enable_mod(mod_id_ref)
			else: mod_manager.disable_mod(mod_id_ref)
			_update_conflict_view()
		)
		hbox.add_child(chk)

		var btn = Button.new()
		btn.text = "%s (v%s)" % [m.name, m.version]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _select_mod(mod_id_ref))
		hbox.add_child(btn)

		mod_list_container.add_child(card)

func _select_mod(mod_id: String) -> void:
	selected_mod_id = mod_id
	if session: session.set_active_mod(mod_id)
	var m = mod_manager.get_mod(mod_id)
	if not m: return

	var prev = mod_manager.generate_mod_preview(m)
	var text = " MOD: %s (ID: %s)\n" % [m.name, m.id]
	text += "Author: %s | Version: %s | Enabled: %s\n" % [m.author, m.version, str(m.enabled)]
	text += "Description: %s\n\n" % [m.description if m.description != "" else "(No description)"]
	text += "OVERRIDE BREAKDOWN:\n"
	text += "• Changed Worlds: %d\n" % prev.get("changed_worlds", 0)
	text += "• Modified NPCs: %d\n" % prev.get("changed_npcs", 0)
	text += "• Dialogue Nodes: %d\n" % prev.get("changed_dialogues", 0)
	text += "• Custom Quests: %d\n" % prev.get("changed_quests", 0)
	text += "• Custom Items: %d\n" % prev.get("changed_items", 0)
	text += "• Total Overrides: %d\n" % prev.get("total_overrides", 0)

	preview_label.text = text

func _update_conflict_view() -> void:
	if not mod_manager: return
	var conflicts = mod_manager.detect_conflicts()
	if conflicts.is_empty():
		conflict_label.text = " Conflicts: None detected (100% clean override pipeline)"
		conflict_label.modulate = Color(0.4, 1.0, 0.4)
	else:
		var c_text = " %d CONFLICTS DETECTED:\n" % conflicts.size()
		for c in conflicts:
			c_text += "• %s.%s -> Competing: %s (Winning: %s)\n" % [
				c.get("stable_id", ""),
				c.get("property_key", ""),
				str(c.get("competing_mods", [])),
				c.get("winning_mod", "")
			]
		conflict_label.text = c_text
		conflict_label.modulate = Color(1.0, 0.8, 0.2)

func _on_create_mod_pressed() -> void:
	if create_mod_dialog:
		create_mod_dialog.popup_centered(Vector2i(400, 300))

func _on_confirm_create_mod() -> void:
	var id = mod_id_edit.text.strip_edges()
	var mname = mod_name_edit.text.strip_edges()
	var auth = mod_author_edit.text.strip_edges()
	var desc = mod_desc_edit.text.strip_edges()
	if id == "": return
	
	var mod = mod_manager.create_mod(id, mname if mname != "" else id, auth if auth != "" else "Author", "1.0.0", desc)
	# Copy current staged overrides into mod
	if editor_service and editor_service.data_service:
		mod.overrides = editor_service.data_service._staged_overrides.duplicate(true)
	mod_manager.export_mod_package(id)
	refresh()
	_select_mod(id)

func _on_export_mod_pressed() -> void:
	if selected_mod_id != "":
		var res = mod_manager.export_mod_package(selected_mod_id)
		if res.get("success", false):
			preview_label.text += "\n Successfully exported .bhmod package to: " + str(res.get("path", ""))
	elif editor_service and editor_service.data_service:
		# Create quick mod from current staged changes
		var q_id = "custom_mod_%d" % (int(Time.get_unix_time_from_system()) % 10000)
		var mod = mod_manager.create_mod(q_id, "Custom Project Mod", "Local Player", "1.0.0")

		mod.overrides = editor_service.data_service._staged_overrides.duplicate(true)
		var res = mod_manager.export_mod_package(q_id)
		refresh()
		_select_mod(q_id)

func _on_import_mod_pressed() -> void:
	# Scan mods directory to pick up external .bhmod or folder mods
	mod_manager.scan_installed_mods()
	refresh()


## Public programmatic and UI authoring entry point for creating new Mod workspaces (Phase 36)
func create_mod_workspace(id: String, display_name: String, author: String = "Author", version: String = "1.0.0", description: String = "") -> Variant:
	var clean_id = id.strip_edges().to_lower().replace(" ", "_")
	if clean_id == "": clean_id = "mod_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	var title = display_name if display_name != "" else clean_id.capitalize().replace("_", " ")
	
	var mod = mod_manager.create_mod(clean_id, title, author, version, description)
	if editor_service and editor_service.data_service:
		mod.overrides = editor_service.data_service._staged_overrides.duplicate(true)
	refresh()
	_select_mod(clean_id)
	return mod


## Public workspace entity summary for Mod Authoring inspection (Phase 37)
func get_mod_workspace_summary(mod_id: String) -> Dictionary:
	var m = mod_manager.get_mod(mod_id) if mod_manager else null
	if not m: return {}
	
	var summary = {
		"id": m.id,
		"name": m.name,
		"author": m.author,
		"version": m.version,
		"description": m.description,
		"enabled": m.enabled,
		"worlds": 0,
		"npcs": 0,
		"dialogues": 0,
		"quests": 0,
		"items": 0,
		"crops": 0,
		"tools": 0,
		"assets": 0,
		"total_overrides": m.overrides.size()
	}
	
	for sid in m.overrides.keys():
		var s := str(sid)
		if s.begins_with("world."): summary["worlds"] += 1
		elif s.begins_with("npc."): summary["npcs"] += 1
		elif s.begins_with("dialogue."): summary["dialogues"] += 1
		elif s.begins_with("quest."): summary["quests"] += 1
		elif s.begins_with("item."): summary["items"] += 1
		elif s.begins_with("crop."): summary["crops"] += 1
		elif s.begins_with("tool."): summary["tools"] += 1
		elif s.begins_with("asset.") or s.begins_with("tile."): summary["assets"] += 1
		
	return summary
