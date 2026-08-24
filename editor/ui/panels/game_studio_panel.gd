class_name GameStudioPanel
extends Control

## In-Game Game Studio Hub, New Game Wizard & Project Overview Dashboard (Phase 40).
## Enables creators to author, manage, validate, duplicate, export, import, and playtest standalone game packages.

const PKG_MGR_SCRIPT = preload("res://core/game_package_manager.gd")
const GAME_PACKAGE_SCRIPT = preload("res://core/game_package.gd")

var editor_service: Variant = null

# UI Tabs & Views
var tab_container: TabContainer
var package_list: ItemList

# Project Overview Metrics
var lbl_game_title: Label
var lbl_game_id: Label
var lbl_game_version: Label
var lbl_game_desc: Label
var lbl_metric_worlds: Label
var lbl_metric_entities: Label
var lbl_metric_items: Label
var lbl_metric_dialogues: Label
var lbl_metric_quests: Label
var lbl_metric_rules: Label
var lbl_metric_assets: Label
var lbl_validation_status: Label

# Wizard Controls
var wizard_id_edit: LineEdit
var wizard_name_edit: LineEdit
var wizard_author_edit: LineEdit
var wizard_version_edit: LineEdit
var wizard_desc_edit: TextEdit
var wizard_template_option: OptionButton
var wizard_status_lbl: Label

# Action Buttons
var btn_playtest: Button
var btn_validate: Button
var btn_export: Button
var btn_duplicate: Button
var btn_delete: Button
var btn_switch: Button

func _init(p_service: Variant = null) -> void:
	editor_service = p_service
	custom_minimum_size = Vector2(800, 520)
	_build_ui()

func _build_ui() -> void:
	tab_container = TabContainer.new()
	tab_container.set_anchors_preset(PRESET_FULL_RECT)
	add_child(tab_container)
	
	_build_dashboard_tab()
	_build_hub_tab()
	_build_wizard_tab()

func _build_dashboard_tab() -> void:
	var dash_vbox = VBoxContainer.new()
	dash_vbox.name = " Project Dashboard"
	tab_container.add_child(dash_vbox)
	
	# Header
	var hdr_panel = PanelContainer.new()
	var hdr_vbox = VBoxContainer.new()
	hdr_panel.add_child(hdr_vbox)
	
	lbl_game_title = Label.new()
	lbl_game_title.text = "Botanical Haven"
	lbl_game_title.add_theme_font_size_override("font_size", 20)
	hdr_vbox.add_child(lbl_game_title)
	
	var meta_hbox = HBoxContainer.new()
	lbl_game_id = Label.new()
	lbl_game_id.text = "ID: botanical_haven"
	meta_hbox.add_child(lbl_game_id)
	
	meta_hbox.add_child(VSeparator.new())
	lbl_game_version = Label.new()
	lbl_game_version.text = "v1.0.0"
	meta_hbox.add_child(lbl_game_version)
	
	meta_hbox.add_child(VSeparator.new())
	lbl_validation_status = Label.new()
	lbl_validation_status.text = " Status: VALID"
	meta_hbox.add_child(lbl_validation_status)
	hdr_vbox.add_child(meta_hbox)
	
	lbl_game_desc = Label.new()
	lbl_game_desc.text = "Official farming and exploration game package."
	lbl_game_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hdr_vbox.add_child(lbl_game_desc)
	dash_vbox.add_child(hdr_panel)
	
	# Metrics Grid
	var grid_hdr = Label.new()
	grid_hdr.text = " Package Content Metrics:"
	dash_vbox.add_child(grid_hdr)
	
	var grid = GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	
	lbl_metric_worlds = _create_metric_card(grid, " Worlds", "0")
	lbl_metric_entities = _create_metric_card(grid, " Entities / NPCs", "0")
	lbl_metric_items = _create_metric_card(grid, " Items", "0")
	lbl_metric_rules = _create_metric_card(grid, " Gameplay Rules", "0")
	lbl_metric_dialogues = _create_metric_card(grid, " Dialogues", "0")
	lbl_metric_quests = _create_metric_card(grid, " Quests", "0")
	lbl_metric_assets = _create_metric_card(grid, " Assets", "0")
	dash_vbox.add_child(grid)
	
	# Action Bar
	var act_hbox = HBoxContainer.new()
	act_hbox.custom_minimum_size = Vector2(0, 45)
	
	btn_playtest = Button.new()
	btn_playtest.text = " PLAYTEST GAME"
	btn_playtest.custom_minimum_size = Vector2(160, 40)
	btn_playtest.pressed.connect(_on_playtest_clicked)
	act_hbox.add_child(btn_playtest)
	
	btn_validate = Button.new()
	btn_validate.text = " Validate Project"
	btn_validate.pressed.connect(_on_validate_clicked)
	act_hbox.add_child(btn_validate)
	
	btn_export = Button.new()
	btn_export.text = " Export .bhgame"
	btn_export.pressed.connect(_on_export_clicked)
	act_hbox.add_child(btn_export)
	
	dash_vbox.add_child(act_hbox)

func _build_hub_tab() -> void:
	var hub_vbox = VBoxContainer.new()
	hub_vbox.name = " My Games & Packages"
	tab_container.add_child(hub_vbox)
	
	var top_bar = HBoxContainer.new()
	var new_btn = Button.new()
	new_btn.text = "+ New Game Wizard"
	new_btn.pressed.connect(func(): tab_container.current_tab = 2)
	top_bar.add_child(new_btn)
	
	var import_btn = Button.new()
	import_btn.text = " Import .bhgame"
	import_btn.pressed.connect(_on_import_clicked)
	top_bar.add_child(import_btn)
	
	btn_duplicate = Button.new()
	btn_duplicate.text = " Duplicate Game"
	btn_duplicate.pressed.connect(_on_duplicate_clicked)
	top_bar.add_child(btn_duplicate)
	
	btn_delete = Button.new()
	btn_delete.text = " Delete Game"
	btn_delete.pressed.connect(_on_delete_clicked)
	top_bar.add_child(btn_delete)
	
	btn_switch = Button.new()
	btn_switch.text = " Set as Active Game"
	btn_switch.pressed.connect(_on_switch_active_clicked)
	top_bar.add_child(btn_switch)
	
	hub_vbox.add_child(top_bar)
	
	package_list = ItemList.new()
	package_list.size_flags_vertical = SIZE_EXPAND_FILL
	package_list.item_selected.connect(_on_package_selected)
	hub_vbox.add_child(package_list)

func _build_wizard_tab() -> void:
	var wiz_vbox = VBoxContainer.new()
	wiz_vbox.name = "[Scatter] New Game Wizard"
	tab_container.add_child(wiz_vbox)
	
	var wiz_title = Label.new()
	wiz_title.text = "Create a New Standalone Game Package"
	wiz_title.add_theme_font_size_override("font_size", 16)
	wiz_vbox.add_child(wiz_title)
	
	var form_grid = GridContainer.new()
	form_grid.columns = 2
	wiz_vbox.add_child(form_grid)
	
	form_grid.add_child(Label.new())
	(form_grid.get_child(0) as Label).text = "Game Identifier (ID):"
	wizard_id_edit = LineEdit.new()
	wizard_id_edit.placeholder_text = "my_custom_game"
	wizard_id_edit.custom_minimum_size = Vector2(300, 0)
	form_grid.add_child(wizard_id_edit)
	
	var lbl2 = Label.new()
	lbl2.text = "Display Name:"
	form_grid.add_child(lbl2)
	wizard_name_edit = LineEdit.new()
	wizard_name_edit.placeholder_text = "My Custom Adventure"
	form_grid.add_child(wizard_name_edit)
	
	var lbl3 = Label.new()
	lbl3.text = "Author / Creator:"
	form_grid.add_child(lbl3)
	wizard_author_edit = LineEdit.new()
	wizard_author_edit.text = "Author"
	form_grid.add_child(wizard_author_edit)
	
	var lbl4 = Label.new()
	lbl4.text = "Version:"
	form_grid.add_child(lbl4)
	wizard_version_edit = LineEdit.new()
	wizard_version_edit.text = "1.0.0"
	form_grid.add_child(wizard_version_edit)
	
	var lbl5 = Label.new()
	lbl5.text = "Template:"
	form_grid.add_child(lbl5)
	wizard_template_option = OptionButton.new()
	wizard_template_option.add_item("Empty (Clean Canvas, 0 Botanical dependencies)", 0)
	wizard_template_option.add_item("RPG / Dungeon Template", 1)
	wizard_template_option.add_item("Farming Template", 2)
	wizard_template_option.add_item("Adventure Template", 3)
	form_grid.add_child(wizard_template_option)
	
	var lbl6 = Label.new()
	lbl6.text = "Description:"
	wiz_vbox.add_child(lbl6)
	wizard_desc_edit = TextEdit.new()
	wizard_desc_edit.custom_minimum_size = Vector2(0, 80)
	wizard_desc_edit.text = "A brand new standalone adventure."
	wiz_vbox.add_child(wizard_desc_edit)
	
	var create_btn = Button.new()
	create_btn.text = "[Scatter] Create Game Package & Open in Studio"
	create_btn.custom_minimum_size = Vector2(0, 40)
	create_btn.pressed.connect(_on_create_game_confirmed)
	wiz_vbox.add_child(create_btn)
	
	wizard_status_lbl = Label.new()
	wizard_status_lbl.text = ""
	wiz_vbox.add_child(wizard_status_lbl)

func _create_metric_card(parent: Control, title: String, default_val: String) -> Label:
	var p = PanelContainer.new()
	p.size_flags_horizontal = SIZE_EXPAND_FILL
	var v = VBoxContainer.new()
	p.add_child(v)
	
	var t = Label.new()
	t.text = title
	v.add_child(t)
	
	var val = Label.new()
	val.text = default_val
	val.add_theme_font_size_override("font_size", 16)
	v.add_child(val)
	
	parent.add_child(p)
	return val

func refresh_dashboard() -> void:
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var active_pkg = mgr.get_active_game_package()
	if not active_pkg: return
	
	lbl_game_title.text = active_pkg.name
	lbl_game_id.text = "ID: " + active_pkg.game_id
	lbl_game_version.text = "v" + active_pkg.version
	lbl_game_desc.text = active_pkg.description
	
	var summary = mgr.get_package_summary(active_pkg.game_id)
	lbl_metric_worlds.text = str(summary.get("worlds", 0))
	lbl_metric_entities.text = str(summary.get("entities", 0))
	lbl_metric_items.text = str(summary.get("items", 0))
	lbl_metric_dialogues.text = str(summary.get("dialogues", 0))
	lbl_metric_quests.text = str(summary.get("quests", 0))
	lbl_metric_rules.text = str(summary.get("rules", 0))
	
	refresh_hub_list()

func refresh_hub_list() -> void:
	if not package_list: return
	package_list.clear()
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var active_id = mgr.get_active_game_id()
	
	for pkg in mgr.get_available_game_packages():
		var prefix = " [ACTIVE] " if pkg.game_id == active_id else "  "
		package_list.add_item("%s%s (%s v%s)" % [prefix, pkg.name, pkg.game_id, pkg.version])

func _on_package_selected(idx: int) -> void:
	pass

func _on_switch_active_clicked() -> void:
	var sel = package_list.get_selected_items()
	if sel.is_empty(): return
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var pkgs = mgr.get_available_game_packages()
	var target_idx = sel[0]
	if target_idx < pkgs.size():
		var target_pkg = pkgs[target_idx]
		mgr.load_game_package(target_pkg.game_id)
		if editor_service and editor_service.data_service:
			editor_service.data_service.reload_for_package(target_pkg)
		refresh_dashboard()

func _on_create_game_confirmed() -> void:
	var gid = wizard_id_edit.text.strip_edges().to_lower().replace(" ", "_")
	var gname = wizard_name_edit.text.strip_edges()
	var gauthor = wizard_author_edit.text.strip_edges()
	var gver = wizard_version_edit.text.strip_edges()
	var gdesc = wizard_desc_edit.text.strip_edges()
	
	if gid == "":
		wizard_status_lbl.text = "Error: Game Identifier cannot be empty."
		return
		
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var created_pkg = mgr.create_game_package(gid, gname, "empty", gauthor, gver, gdesc)
	if created_pkg:
		mgr.load_game_package(gid)
		if editor_service and editor_service.data_service:
			editor_service.data_service.reload_for_package(created_pkg)
		refresh_dashboard()
		tab_container.current_tab = 0
		wizard_status_lbl.text = "Game '%s' created successfully!" % gname

func _on_playtest_clicked() -> void:
	if editor_service:
		editor_service.test_preview_mode()

func _on_validate_clicked() -> void:
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var pkg = mgr.get_active_game_package()
	var res = mgr.validate_game_package(pkg)
	if res.get("valid", true):
		lbl_validation_status.text = " Status: VALID"
	else:
		lbl_validation_status.text = " Status: WARNING (%d issues)" % res.get("errors", []).size()

func _on_export_clicked() -> void:
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var path = mgr.export_game_package(mgr.get_active_game_id())
	if path != "":
		lbl_validation_status.text = " Exported: " + path.get_file()

func _on_import_clicked() -> void:
	pass

func _on_duplicate_clicked() -> void:
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var cur_id = mgr.get_active_game_id()
	var new_id = cur_id + "_copy"
	var new_name = mgr.get_active_game_package().name + " (Copy)"
	var dup = mgr.duplicate_game_package(cur_id, new_id, new_name)
	if dup:
		refresh_dashboard()

func _on_delete_clicked() -> void:
	var mgr = PKG_MGR_SCRIPT.get_instance()
	var cur_id = mgr.get_active_game_id()
	if cur_id == "botanical_haven": return
	mgr.delete_game_package(cur_id)
	refresh_dashboard()
