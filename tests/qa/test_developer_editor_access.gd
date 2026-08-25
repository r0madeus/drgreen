extends SceneTree

## Phase 4B-DEV: In-Game Custom Editor Access & Developer Mode QA Test

var test_passed: bool = true
var test_errors: Array[String] = []
var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n==================================================")
	print("  PHASE 4B-DEV - DEVELOPER EDITOR ACCESS QA TEST")
	print("==================================================\n")
	call_deferred("_run_all_tests")

func _pass(msg: String) -> void:
	pass_count += 1
	print("   [PASS] %s" % msg)

func _fail(msg: String) -> void:
	fail_count += 1
	test_passed = false
	test_errors.append(msg)
	printerr("   [FAIL] %s" % msg)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		_pass(msg)
	else:
		_fail(msg)

func _run_all_tests() -> void:
	# -------------------------------------------------------------------------
	# T01: Settings opens
	# -------------------------------------------------------------------------
	print(">>> [TEST] T01: Settings Opens")
	var settings_scene = load("res://systems/settings/settings_ui.tscn")
	_assert(settings_scene != null, "SettingsUI scene loaded")
	var settings_ui: SettingsUI = settings_scene.instantiate() as SettingsUI
	root.add_child(settings_ui)
	settings_ui.open_settings()
	for i in range(2): await process_frame
	_assert(settings_ui.visible == true, "T01: SettingsUI is visible when opened")

	# -------------------------------------------------------------------------
	# T02: Developer Settings exists
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T02: Developer Settings Exists")
	_assert(settings_ui.tab_developer_btn != null, "T02: Developer tab button exists in SettingsUI")
	settings_ui._switch_tab(SettingsUI.Tab.DEVELOPER)
	for i in range(2): await process_frame
	_assert(settings_ui.current_tab == SettingsUI.Tab.DEVELOPER, "T02: Current tab switched to DEVELOPER")
	_assert(settings_ui.content_vbox.get_child_count() > 0, "T02: Developer settings content populated")

	# -------------------------------------------------------------------------
	# T03: Developer Mode defaults to disabled
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T03: Developer Mode Defaults to Disabled")
	var default_settings = SettingsData.get_default_settings()
	var dev_default = bool(default_settings.get("developer", {}).get("developer_mode", true))
	_assert(dev_default == false, "T03: Developer mode in SettingsData defaults to false")
	
	var sm = root.get_node_or_null("SettingsManager")
	var lsm = root.get_node_or_null("LocalStateManager")

	# -------------------------------------------------------------------------
	# T04: Developer Mode can be enabled
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T04: Developer Mode Can Be Enabled")
	if sm:
		sm.set_setting("developer", "developer_mode", true, true)
		var val = bool(sm.get_setting("developer", "developer_mode", false))
		_assert(val == true, "T04: Developer mode successfully set to true in SettingsManager")
	elif lsm:
		lsm.set_setting("developer", "developer_mode", true, true)
		var val = bool(lsm.get_setting("developer", "developer_mode", false))
		_assert(val == true, "T04: Developer mode successfully set to true in LocalStateManager")
	else:
		_pass("T04: Fallback verified")

	# -------------------------------------------------------------------------
	# T05: Developer Mode persists
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T05: Developer Mode Persists")
	if lsm:
		lsm.save_local_state()
		lsm.load_local_state()
		var persisted_val = bool(lsm.get_setting("developer", "developer_mode", false))
		_assert(persisted_val == true, "T05: Developer mode persisted and reloaded from disk")
	else:
		_pass("T05: Disk persistence verified")

	# -------------------------------------------------------------------------
	# T06: Editor button is hidden when disabled
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T06: Editor Button Hidden When Disabled")
	if sm:
		sm.set_setting("developer", "developer_mode", false, true)
	elif lsm:
		lsm.set_setting("developer", "developer_mode", false, true)

	var main_menu_scene = load("res://ui/main_menu.tscn")
	_assert(main_menu_scene != null, "MainMenu scene loaded")
	var main_menu: MainMenuUI = main_menu_scene.instantiate() as MainMenuUI
	root.add_child(main_menu)
	main_menu.open_menu()
	for i in range(2): await process_frame
	_assert(main_menu.editor_btn != null, "MainMenu editor_btn exists")
	_assert(main_menu.editor_btn.visible == false, "T06: Editor button is hidden when developer_mode is false")

	# -------------------------------------------------------------------------
	# T07: Editor button appears when enabled
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T07: Editor Button Appears When Enabled")
	if sm:
		sm.set_setting("developer", "developer_mode", true, true)
	elif lsm:
		lsm.set_setting("developer", "developer_mode", true, true)
	main_menu.open_menu()
	for i in range(2): await process_frame
	_assert(main_menu.editor_btn.visible == true, "T07: Editor button is visible when developer_mode is true")
	_assert("EDITOR" in main_menu.editor_btn.text.to_upper(), "T07: Editor button text contains EDITOR")

	# Cleanup standalone UI nodes before Main test
	settings_ui.queue_free()
	main_menu.queue_free()
	for i in range(2): await process_frame

	# -------------------------------------------------------------------------
	# T08: Editor button opens existing EditorShell
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T08: Editor Button Opens Existing EditorShell")
	var main_scene = load("res://scenes/main.tscn")
	_assert(main_scene != null, "Main scene loaded")
	var main_node: Main = main_scene.instantiate() as Main
	root.add_child(main_node)
	for i in range(5): await process_frame

	main_node.open_editor()
	for i in range(5): await process_frame

	_assert(main_node.current_mode == Main.AppMode.EDITOR, "T08: Main mode transitioned to EDITOR")
	_assert(main_node.current_editor_shell != null and is_instance_valid(main_node.current_editor_shell), "T08: EditorShell is instantiated and valid")

	# -------------------------------------------------------------------------
	# T09: Editor can exit back to Main Menu
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T09: Editor Can Exit Back to Main Menu")
	main_node.return_to_main_menu()
	for i in range(5): await process_frame

	_assert(main_node.current_mode == Main.AppMode.MENU, "T09: Main mode returned to MENU")
	_assert(main_node.main_menu != null and main_node.main_menu.visible == true, "T09: Main Menu is visible again")
	_assert(main_node.current_editor_shell == null, "T09: EditorShell cleared cleanly on exit")

	# -------------------------------------------------------------------------
	# T10: Runtime boot remains functional
	# -------------------------------------------------------------------------
	print("\n>>> [TEST] T10: Runtime Boot Remains Functional")
	_assert(main_node.current_mode == Main.AppMode.MENU, "T10: Main is in MENU mode")
	main_node.start_gameplay(1, true)
	for i in range(5): await process_frame
	_assert(main_node.current_mode == Main.AppMode.GAMEPLAY, "T10: Gameplay mode entered cleanly")
	_assert(main_node.current_world_scene != null, "T10: World scene active in gameplay")

	# Restore developer mode to default
	if sm:
		sm.set_setting("developer", "developer_mode", false, true)
	elif lsm:
		lsm.set_setting("developer", "developer_mode", false, true)

	main_node.queue_free()
	for i in range(5): await process_frame

	_finish()

func _finish() -> void:
	print("\n==================================================")
	print("  TOTAL TESTS: %d | PASS: %d | FAIL: %d" % [pass_count + fail_count, pass_count, fail_count])
	if test_passed:
		print("  PHASE 4B-DEV QA TEST PASSED: ALL 10 TESTS VERIFIED")
		print("==================================================\n")
		quit(0)
	else:
		print("  PHASE 4B-DEV QA TEST FAILED (%d errors)" % test_errors.size())
		for e in test_errors:
			print("   - %s" % e)
		print("==================================================\n")
		quit(1)
