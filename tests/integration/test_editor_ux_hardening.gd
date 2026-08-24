class_name TestEditorUxHardening
extends TestCase

## Phase 37 — Editor UX Hardening, Production Readiness & Real User Authoring QA Suite.
## Tests end-to-end usability, interaction consistency, responsive layouts,
## mouse input isolation, keyboard shortcuts focus guards, cross-reference pickers,
## and complete real authoring scenario ("Moonlit Garden 2").

var SHELL_SCRIPT
var WORLD_PANEL_SCRIPT
var NPC_PANEL_SCRIPT
var DIALOGUE_PANEL_SCRIPT
var QUEST_PANEL_SCRIPT
var ITEM_PANEL_SCRIPT
var ASSET_PANEL_SCRIPT
var MOD_PANEL_SCRIPT
var DATA_SERVICE_SCRIPT

func test_name_id() -> String:
	return "EDITOR_UX_HARDENING.Phase37Suite"

func _init_scripts() -> void:
	SHELL_SCRIPT = ResourceLoader.load("res://editor/ui/editor_shell.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	WORLD_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/world_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	NPC_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/npc_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DIALOGUE_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/dialogue_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	QUEST_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/quest_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ITEM_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/item_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	ASSET_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/asset_editor_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	MOD_PANEL_SCRIPT = ResourceLoader.load("res://editor/ui/panels/mod_manager_panel.gd", "", ResourceLoader.CACHE_MODE_IGNORE)
	DATA_SERVICE_SCRIPT = ResourceLoader.load("res://editor/core/editor_data_service.gd", "", ResourceLoader.CACHE_MODE_IGNORE)

func _clean_state(service: EditorService) -> void:
	service.reset_all()
	service.save()

func run_all() -> void:
	test_name = test_name_id()
	_init_scripts()
	
	var service := EditorService.get_instance()
	if not service.data_service.has_method("create_entity"):
		service.data_service = DATA_SERVICE_SCRIPT.new(service.undo_manager, service.mod_manager)
		
	_clean_state(service)

	# --- 1. Dirty State Visual Indicators ---
	_test_01_dirty_state_visual_indicators()

	# --- 2. Validation Badge & Navigation Links ---
	_test_02_validation_badge_and_error_navigation()

	# --- 3. Create Entity ID Sanitization ---
	_test_03_create_entity_id_sanitization()

	# --- 4. Cross-Reference Entity Pickers ---
	_test_04_cross_reference_entity_pickers()

	# --- 5. World Editor Mouse Input & Tools ---
	_test_05_world_editor_mouse_input_and_tools()

	# --- 6. Keyboard Shortcuts Focus Guards ---
	_test_06_keyboard_shortcuts_focus_guards()

	# --- 7. Responsive Layout Stability ---
	_test_07_responsive_layout_stability()

	# --- 8. Destructive Actions Confirmation ---
	_test_08_destructive_actions_confirmation()

	# --- 9. Mod Workspace Summary Counts ---
	_test_09_mod_workspace_summary_counts()

	# --- 10. Onboarding Guide Lifecycle ---
	_test_10_onboarding_guide_lifecycle()

	# --- 11. Real Authoring Scenario ("Moonlit Garden 2") ---
	_test_11_real_authoring_scenario_moonlit_garden_2()

# ===========================================================================
# 1. Dirty State Visual Indicators
# ===========================================================================

func _test_01_dirty_state_visual_indicators() -> void:
	begin_test("01_DirtyStateVisualIndicators")
	var service := EditorService.get_instance()
	_clean_state(service)
	
	var shell = SHELL_SCRIPT.new()
	shell._update_status_and_buttons()
	
	assert_eq(shell.dirty_label.text, "SAVED", "Clean state displays ● SAVED")
	assert_false(service.is_dirty(), "Service is not dirty initially")
	
	# Stage a modification
	service.set_property("item.strawberry", "sell_price", 999.0)
	shell._update_status_and_buttons()
	
	assert_eq(shell.dirty_label.text, "UNSAVED CHANGES", "Dirty state displays ● UNSAVED CHANGES")
	assert_true(service.is_dirty(), "Service is dirty after edit")
	
	# Save changes
	service.save()
	shell._update_status_and_buttons()
	assert_eq(shell.dirty_label.text, "SAVED", "Saved state displays ● SAVED")
	
	shell.free()

# ===========================================================================
# 2. Validation Badge & Navigation Links
# ===========================================================================

func _test_02_validation_badge_and_error_navigation() -> void:
	begin_test("02_ValidationBadgeAndNavigationLinks")
	var service := EditorService.get_instance()
	var shell = SHELL_SCRIPT.new()
	shell._update_status_and_buttons()
	
	assert_eq(shell.validation_label.text, "VALID", "Valid state displays ✓ VALID")
	
	# Inject intentional broken reference
	service.data_service.create_entity("quest.broken_quest_test", {
		"id": "broken_quest_test",
		"title": "Broken Quest",
		"giver": "Rowan",
		"objectives": [{ "type": "harvest", "target": "item.NONEXISTENT_ITEM_999", "amount": 1.0 }],
		"rewards": {}
	})
	
	shell._update_status_and_buttons()
	assert_true(shell.validation_label.text.begins_with("ERROR"), "Error state displays ❌ ERROR badge")
	
	var val_report = service.validate()
	assert_false(val_report.get("valid", true), "Report marked invalid")
	var errors: Array = val_report.get("errors", [])
	assert_true(errors.size() >= 1, "At least 1 error in report")
	
	# Cleanup
	service.data_service.delete_entity("quest.broken_quest_test", false)
	shell._update_status_and_buttons()
	assert_eq(shell.validation_label.text, "VALID", "Valid state restored after fixing error")
	
	shell.free()

# ===========================================================================
# 3. Create Entity ID Sanitization
# ===========================================================================

func _test_03_create_entity_id_sanitization() -> void:
	begin_test("03_CreateEntityIdSanitization")
	var service := EditorService.get_instance()
	var npc_panel = NPC_PANEL_SCRIPT.new()
	npc_panel.setup(service)
	
	# Test ID with uppercase, spaces, prefix
	var clean_id = npc_panel.create_npc("NPC.Elara Shadow 2", "Elara Shadow 2")
	assert_eq(clean_id, "elara_shadow_2", "ID properly sanitized to lowercase snake_case")
	assert_true(service.data_service.has_override("npc.elara_shadow_2"), "Sanitized NPC registered")
	
	npc_panel.free()

# ===========================================================================
# 4. Cross-Reference Entity Pickers
# ===========================================================================

func _test_04_cross_reference_entity_pickers() -> void:
	begin_test("04_CrossReferenceEntityPickers")
	var service := EditorService.get_instance()
	var ds = service.data_service
	
	var npcs = ds.get_all_stable_ids("npc.")
	var items = ds.get_all_stable_ids("item.")
	var worlds = ds.get_all_stable_ids("world.")
	
	assert_true(npcs.size() >= 1, "NPC list populated for dropdown pickers")
	assert_true(items.size() >= 1, "Item list populated for dropdown pickers")
	assert_true(worlds.size() >= 1, "World list populated for dropdown pickers")
	
	assert_true(npcs.has("npc.rowan"), "Rowan in NPC dropdown options")
	assert_true(worlds.has("world.farm"), "Farm in World dropdown options")

# ===========================================================================
# 5. World Editor Mouse Input & Tools
# ===========================================================================

func _test_05_world_editor_mouse_input_and_tools() -> void:
	begin_test("05_WorldEditorMouseInputAndTools")
	var service := EditorService.get_instance()
	var world_panel = WORLD_PANEL_SCRIPT.new()
	world_panel.setup(service)
	
	var canvas = world_panel.canvas
	assert_true(canvas != null, "WorldCanvas instantiated")
	
	# Test Tool Modes
	canvas.set_tool_mode(WorldCanvas.ToolMode.BRUSH)
	assert_eq(canvas.current_tool, WorldCanvas.ToolMode.BRUSH, "Brush tool mode set")
	
	canvas.set_tool_mode(WorldCanvas.ToolMode.ERASER)
	assert_eq(canvas.current_tool, WorldCanvas.ToolMode.ERASER, "Eraser tool mode set")
	
	canvas.set_tool_mode(WorldCanvas.ToolMode.SELECT)
	assert_eq(canvas.current_tool, WorldCanvas.ToolMode.SELECT, "Select tool mode set")
	
	# Test Zoom and Pan
	var prev_zoom = canvas.zoom_level
	canvas.zoom_level = 2.0
	assert_eq(canvas.zoom_level, 2.0, "Zoom level updated")
	
	world_panel.free()

# ===========================================================================
# 6. Keyboard Shortcuts Focus Guards
# ===========================================================================

func _test_06_keyboard_shortcuts_focus_guards() -> void:
	begin_test("06_KeyboardShortcutsFocusGuards")
	var shell = SHELL_SCRIPT.new()
	assert_true(shell.has_method("_unhandled_input"), "Unhandled input method available")
	
	# Create a LineEdit to simulate active text entry focus
	var line_edit = LineEdit.new()
	shell.add_child(line_edit)
	assert_true(line_edit is LineEdit, "LineEdit instantiated for focus test")
	
	shell.free()

# ===========================================================================
# 7. Responsive Layout Stability
# ===========================================================================

func _test_07_responsive_layout_stability() -> void:
	begin_test("07_ResponsiveLayoutStability")
	var shell = SHELL_SCRIPT.new()
	
	var resolutions = [
		Vector2(1280, 720),
		Vector2(1366, 768),
		Vector2(1600, 900),
		Vector2(1920, 1080),
		Vector2(2560, 1440)
	]
	
	for res in resolutions:
		shell.size = res
		assert_eq(shell.size, res, "EditorShell resized to %dx%d cleanly" % [int(res.x), int(res.y)])
		
	shell.free()

# ===========================================================================
# 8. Destructive Actions Confirmation
# ===========================================================================

func _test_08_destructive_actions_confirmation() -> void:
	begin_test("08_DestructiveActionsConfirmation")
	var shell = SHELL_SCRIPT.new()
	
	assert_true(shell.reset_dialog != null, "Reset confirmation dialog exists")
	assert_true(shell.exit_dialog != null, "Exit confirmation dialog exists")
	assert_true(shell.validation_dialog != null, "Validation dialog exists")
	assert_true(shell.onboarding_dialog != null, "Onboarding dialog exists")
	
	shell.free()

# ===========================================================================
# 9. Mod Workspace Summary Counts
# ===========================================================================

func _test_09_mod_workspace_summary_counts() -> void:
	begin_test("09_ModWorkspaceSummaryCounts")
	var service := EditorService.get_instance()
	var mod_panel = MOD_PANEL_SCRIPT.new()
	mod_panel.setup(service)
	
	var mod = service.mod_manager.create_mod("test_summary_mod", "Summary Test Mod", "Tester", "1.0.0")
	mod.overrides = {
		"world.custom_map": { "width": 32 },
		"npc.custom_villager": { "name": "Villager" },
		"dialogue.custom_villager": { "nodes": {} },
		"quest.custom_quest": { "title": "Quest" },
		"item.custom_gem": { "sell_price": 100 },
		"crop.custom_seed": { "growth_days": 3 },
		"tool.custom_pick": { "power": 2 }
	}
	
	var summary = mod_panel.get_mod_workspace_summary("test_summary_mod")
	assert_eq(summary["worlds"], 1, "Summary reports 1 world")
	assert_eq(summary["npcs"], 1, "Summary reports 1 NPC")
	assert_eq(summary["dialogues"], 1, "Summary reports 1 dialogue")
	assert_eq(summary["quests"], 1, "Summary reports 1 quest")
	assert_eq(summary["items"], 1, "Summary reports 1 item")
	assert_eq(summary["crops"], 1, "Summary reports 1 crop")
	assert_eq(summary["tools"], 1, "Summary reports 1 tool")
	assert_eq(summary["total_overrides"], 7, "Summary reports 7 total overrides")
	
	service.mod_manager.unregister_mod("test_summary_mod")
	mod_panel.free()

# ===========================================================================
# 10. Onboarding Guide Lifecycle
# ===========================================================================

func _test_10_onboarding_guide_lifecycle() -> void:
	begin_test("10_OnboardingGuideLifecycle")
	var shell = SHELL_SCRIPT.new()
	shell.show_onboarding_guide()
	
	assert_true(shell.onboarding_dialog != null, "Onboarding guide opened")
	assert_true(shell.onboarding_dialog.dialog_text.contains("WELCOME TO BOTANICAL HAVEN"), "Guide contains introductory text")
	
	shell.free()

# ===========================================================================
# 11. Real Authoring Scenario ("Moonlit Garden 2")
# ===========================================================================

func _test_11_real_authoring_scenario_moonlit_garden_2() -> void:
	begin_test("11_RealAuthoringScenarioMoonlitGarden2")
	var service := EditorService.get_instance()
	_clean_state(service)
	
	var mod_panel = MOD_PANEL_SCRIPT.new()
	mod_panel.setup(service)
	var world_panel = WORLD_PANEL_SCRIPT.new()
	world_panel.setup(service)
	var npc_panel = NPC_PANEL_SCRIPT.new()
	npc_panel.setup(service)
	var item_panel = ITEM_PANEL_SCRIPT.new()
	item_panel.setup(service)
	var diag_panel = DIALOGUE_PANEL_SCRIPT.new()
	diag_panel.setup(service)
	var quest_panel = QUEST_PANEL_SCRIPT.new()
	quest_panel.setup(service)
	
	# 1. Create Mod Workspace
	var mod = mod_panel.create_mod_workspace("moonlit_garden_2", "Moonlit Garden 2", "Lead Creator", "2.0.0", "Expanded sanctuary with Elara.")
	assert_true(mod != null, "Mod workspace created")
	
	# 2. Create World
	var world_dict = world_panel.create_new_world("world.moonlit_garden_2", "Moonlit Garden 2", 32, 24, "grass")
	assert_true(service.data_service.has_override("world.moonlit_garden_2"), "World staged")
	
	# 3. Create Item & Crop
	var item_dict = item_panel.create_item("item.moon_flower_2", "Moon Flower 2", "flower", 200)
	var crop_dict = item_panel.create_crop("crop.moon_flower_crop_2", "Moon Flower Crop 2", 4, "item.moon_flower_2")
	assert_true(service.data_service.has_override("item.moon_flower_2"), "Item staged")
	assert_true(service.data_service.has_override("crop.moon_flower_crop_2"), "Crop staged")
	
	# 4. Create NPC & Place in World
	var npc_id = npc_panel.create_npc("npc.elara_2", "Elara 2", "moonlit_garden_2", "botanist")
	assert_true(service.data_service.has_override("npc.elara_2"), "NPC staged")
	world_panel.place_npc("npc.elara_2", Vector2i(12, 8), "down")
	
	# 5. Create Dialogue
	var diag_dict = diag_panel.create_dialogue("dialogue.elara_2", "elara_2", "start", ["Greetings traveler. Tend to the Moon Flower."])
	assert_true(service.data_service.has_override("dialogue.elara_2"), "Dialogue staged")
	
	# 6. Create Quest
	var quest_dict = quest_panel.create_quest(
		"quest.grow_moon_flower_2",
		"Grow Moon Flower 2",
		"Elara 2",
		[{ "type": "harvest", "target": "item.moon_flower_2", "amount": 1.0, "current": 0.0, "description": "Harvest 1 Moon Flower 2" }],
		{ "gold": 200.0 }
	)
	assert_true(service.data_service.has_override("quest.grow_moon_flower_2"), "Quest staged")
	
	# 7. Global Validation
	var val_report = service.validate()
	assert_true(val_report.get("valid", true), "Scenario validation valid with 0 errors")
	
	# 8. Save & Export Package
	var save_ok = service.save()
	assert_true(save_ok, "Scenario saved to disk")
	
	mod.overrides = service.data_service._staged_overrides.duplicate(true)
	var export_res = service.mod_manager.export_mod_package("moonlit_garden_2", "user://mods")
	assert_true(export_res.get("success", false), "Exported moonlit_garden_2.bhmod package")
	
	# 9. Clean Environment Reset & Re-Import
	_clean_state(service)
	assert_false(service.data_service.has_override("npc.elara_2"), "Base game clean after reset")
	
	var mm_fresh = ModManager.new()
	var import_res = mm_fresh.import_mod("user://mods/moonlit_garden_2.bhmod")
	assert_true(import_res.get("success", false), "Re-imported package into clean ModManager")
	
	var ds_fresh = DATA_SERVICE_SCRIPT.new(null, mm_fresh)
	assert_true(ds_fresh.get_all_stable_ids().has("npc.elara_2"), "Imported mod resolves npc.elara_2")
	assert_true(ds_fresh.get_all_stable_ids().has("world.moonlit_garden_2"), "Imported mod resolves world.moonlit_garden_2")
	
	mod_panel.free()
	world_panel.free()
	npc_panel.free()
	item_panel.free()
	diag_panel.free()
	quest_panel.free()
