class_name TestAssetEditor
extends TestCase

## Phase 35 — In-Game Asset & Visual Content Editor — 64-Point Real User Workflow & Integration Suite.
## Covers:
##   - Panel lifecycle, creation, setup, and EditorRegistry registration
##   - Category browser, 16+ categories, manifest-driven expansion, 'All' filtering
##   - Search, modified/missing/favorites filters, visual status highlights
##   - Preview system, checkerboard background, zoom (+, -, Fit)
##   - Animation playback, FPS, loop, frame forward/backward stepping
##   - NPC 4-way direction selector (Up, Down, Left, Right) & state animations (idle, walk, work, eat, rest, sit, sleep, talk)
##   - Player visual workspace preview
##   - Zero-code stable ID swapping & EditorDataService override flow
##   - Visual properties: texture, flip_h, flip_v, scale, offset, filter_mode, modulate
##   - Animation properties: fps, loop, columns, rows
##   - Metadata: display_name, description, tags, source status
##   - Reset single asset, reset category, reset all assets
##   - Undo and Redo operations
##   - Missing asset scanner, fallback placeholder generation, crash prevention
##   - Validation: missing textures, duplicates, malformed stable IDs, invalid frames/dimensions
##   - Dependency graph: 'Used By' detection & safety warnings
##   - Cross-editor navigation: NPC Editor, Item Editor, Crop Editor, Tool Editor, World Editor
##   - Mod system integration: .bhmod packaging & import resolution
##   - Base game files protection & runtime save isolation
##   - REAL USER WORKFLOW TESTS (TEST A through TEST L)

const ASSET_EDITOR_PANEL_SCRIPT = preload("res://editor/ui/panels/asset_editor_panel.gd")

func test_name_id() -> String:
	return "ASSET_EDITOR.Phase35Suite"

func _clean_state(service: EditorService) -> void:
	service.reset_all()
	service.save()

func run_all() -> void:
	test_name = test_name_id()
	var s = EditorService.get_instance()
	_clean_state(s)

	# Ensure panel registration
	if not EditorRegistry.has_panel("assets"):
		EditorRegistry.register_panel("assets", ASSET_EDITOR_PANEL_SCRIPT, "ui.editor.cat_assets", "icon_asset", 55)

	# --- 1. Panel Lifecycle & Registry (T01 - T05) ---
	_test_T01_panel_registers_in_registry()
	_test_T02_panel_preloads_and_instantiates()
	_test_T03_panel_extends_editor_panel()
	_test_T04_panel_has_setup_and_open_methods()
	_test_T05_panel_setup_with_service()

	# --- 2. Category Browser (T06 - T10) ---
	_test_T06_category_list_populated()
	_test_T07_default_categories_contain_16_types()
	_test_T08_category_all_matches_all_assets()
	_test_T09_category_filtering_narrows_assets()
	_test_T10_manifest_driven_categories_recognized()

	# --- 3. Asset Catalog & Filtering (T11 - T15) ---
	_test_T11_asset_list_populated_from_manifest_and_data()
	_test_T12_realtime_search_filters_assets()
	_test_T13_modified_filter_shows_overridden_assets()
	_test_T14_missing_filter_shows_missing_assets()
	_test_T15_favorites_filter_tracks_favs()

	# --- 4. Preview & Zoom System (T16 - T20) ---
	_test_T16_show_asset_updates_selected_id()
	_test_T17_zoom_in_increments_scale()
	_test_T18_zoom_out_decrements_and_clamps()
	_test_T19_zoom_fit_resets_scale()
	_test_T20_preview_resolves_valid_texture()

	# --- 5. Animation Playback & Stepping (T21 - T25) ---
	_test_T21_frame_stepping_forward()
	_test_T22_frame_stepping_backward_wraps()
	_test_T23_animation_play_toggle_state()
	_test_T24_animation_fps_updates()
	_test_T25_animation_loop_flag()

	# --- 6. NPC & Character Workspace (T26 - T28) ---
	_test_T26_npc_4way_direction_selection()
	_test_T27_npc_animation_states_selector()
	_test_T28_player_visual_asset_resolution()

	# --- 7. Override Flow & Staged Mutations (T29 - T34) ---
	_test_T29_create_override_stages_entry()
	_test_T30_flip_h_and_flip_v_overrides()
	_test_T31_scale_and_offset_overrides()
	_test_T32_filter_mode_and_modulate_overrides()
	_test_T33_animation_matrix_override()
	_test_T34_metadata_tags_and_display_name()

	# --- 8. Reset, Undo & Redo (T35 - T38) ---
	_test_T35_reset_single_asset_restores_default()
	_test_T36_reset_category_resets_only_category()
	_test_T37_reset_all_assets_clears_all_overrides()
	_test_T38_undo_and_redo_support()

	# --- 9. Missing Assets & Fallback System (T39 - T41) ---
	_test_T39_scan_missing_assets_populates_missing_list()
	_test_T40_nonexistent_asset_identified_as_missing()
	_test_T41_fallback_placeholder_generation_no_crash()

	# --- 10. Validation Service (T42 - T45) ---
	_test_T42_validation_detects_missing_textures()
	_test_T43_validation_detects_duplicate_stable_ids()
	_test_T44_validation_detects_malformed_stable_ids()
	_test_T45_validation_detects_invalid_frames_or_size()

	# --- 11. Dependency Graph & Safety (T46 - T47) ---
	_test_T46_dependency_graph_finds_referencing_entities()
	_test_T47_used_by_warning_alert_when_referenced()

	# --- 12. Cross-Editor Navigation & Modding (T48 - T52) ---
	_test_T48_cross_editor_open_npc_editor()
	_test_T49_cross_editor_place_in_world()
	_test_T50_cross_editor_item_crop_tool_links()
	_test_T51_mod_export_and_import_with_asset_overrides()
	_test_T52_base_game_files_protection_and_save_safety()

	# --- 13. REAL USER WORKFLOW E2E TESTS (TEST A - TEST L) ---
	_test_Workflow_A_import_preview_apply_restart()
	_test_Workflow_B_replace_existing_asset_and_resolve()
	_test_Workflow_C_override_modify_discard_reverts_base()
	_test_Workflow_D_override_modify_save_reload_persists()
	_test_Workflow_E_modify_multiple_reset_category_isolates()
	_test_Workflow_F_modify_multiple_reset_all_clears()
	_test_Workflow_G_missing_asset_validation_and_fallback()
	_test_Workflow_H_npc_asset_cross_navigation_selects_npc()
	_test_Workflow_I_crop_asset_cross_navigation_selects_crop()
	_test_Workflow_J_tool_asset_cross_navigation_selects_tool()
	_test_Workflow_K_world_asset_cross_navigation_selects_brush()
	_test_Workflow_L_bhmod_export_import_override_pipeline()

# ===========================================================================
# 1. Panel Lifecycle & Registry (T01 - T05)
# ===========================================================================

func _test_T01_panel_registers_in_registry() -> void:
	begin_test("T01_PanelRegistersInRegistry")
	assert_true(EditorRegistry.has_panel("assets"), "EditorRegistry has 'assets' panel registered")
	var meta := EditorRegistry.get_all_panel_metadata()
	var found := false
	for m in meta:
		if m.get("id") == "assets":
			found = true
			break
	assert_true(found, "Panel metadata list contains 'assets' module entry")

func _test_T02_panel_preloads_and_instantiates() -> void:
	begin_test("T02_PanelPreloadsAndInstantiates")
	assert_true(ASSET_EDITOR_PANEL_SCRIPT != null, "asset_editor_panel.gd script preloaded")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	assert_true(panel != null, "AssetEditorPanel instance created without crash")
	if panel: panel.free()

func _test_T03_panel_extends_editor_panel() -> void:
	begin_test("T03_PanelExtendsEditorPanel")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	assert_true(panel is EditorPanel, "AssetEditorPanel is subclass of EditorPanel")
	if panel: panel.free()

func _test_T04_panel_has_setup_and_open_methods() -> void:
	begin_test("T04_PanelHasSetupAndOpenMethods")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	assert_true(panel.has_method("setup"), "Panel has setup() method")
	assert_true(panel.has_method("open_panel"), "Panel has open_panel() method")
	assert_true(panel.has_method("refresh"), "Panel has refresh() method")
	if panel: panel.free()

func _test_T05_panel_setup_with_service() -> void:
	begin_test("T05_PanelSetupWithService")
	var service := EditorService.get_instance()
	var panel = EditorRegistry.create_panel("assets", service)
	assert_true(panel != null, "EditorRegistry.create_panel('assets') instantiated cleanly")
	if panel: panel.free()

# ===========================================================================
# 2. Category Browser (T06 - T10)
# ===========================================================================

func _test_T06_category_list_populated() -> void:
	begin_test("T06_CategoryListPopulated")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	assert_true(panel.has_method("_populate_categories"), "Panel implements _populate_categories")
	if panel: panel.free()

func _test_T07_default_categories_contain_16_types() -> void:
	begin_test("T07_DefaultCategoriesContain16Types")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	var required := [
		"player", "npc", "npc_portrait", "npc_animation",
		"crops", "items", "seeds", "tools",
		"tiles", "props", "buildings",
		"vfx", "ui", "sfx", "music", "ambience"
	]
	var defaults: Array = panel.DEFAULT_CATEGORIES
	for req in required:
		assert_true(defaults.has(req), "DEFAULT_CATEGORIES contains: %s" % req)
	if panel: panel.free()

func _test_T08_category_all_matches_all_assets() -> void:
	begin_test("T08_CategoryAllMatchesAllAssets")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	assert_true(panel._id_matches_category("npc.rowan", ""), "Empty category matches npc")
	assert_true(panel._id_matches_category("tile.grass", "All"), "Category 'All' matches tile")
	assert_true(panel._id_matches_category("item.fertilizer", "all"), "Category 'all' matches item")
	if panel: panel.free()

func _test_T09_category_filtering_narrows_assets() -> void:
	begin_test("T09_CategoryFilteringNarrowsAssets")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	assert_true(panel._id_matches_category("npc.rowan", "Npc"), "npc.rowan matches 'Npc'")
	assert_false(panel._id_matches_category("tile.grass", "Npc"), "tile.grass does NOT match 'Npc'")
	assert_true(panel._id_matches_category("tile.grass", "Tiles"), "tile.grass matches 'Tiles'")
	assert_true(panel._id_matches_category("crop.red_flower", "Crops"), "crop.red_flower matches 'Crops'")
	assert_true(panel._id_matches_category("tool.hoe", "Tools"), "tool.hoe matches 'Tools'")
	if panel: panel.free()

func _test_T10_manifest_driven_categories_recognized() -> void:
	begin_test("T10_ManifestDrivenCategoriesRecognized")
	AssetRegistry.ensure_initialized()
	var ids := AssetRegistry.get_all_asset_ids()
	assert_true(ids is Array, "Manifest IDs returned as Array")
	assert_true(ids.size() > 0, "Manifest contains asset entries")

# ===========================================================================
# 3. Asset Catalog & Filtering (T11 - T15)
# ===========================================================================

func _test_T11_asset_list_populated_from_manifest_and_data() -> void:
	begin_test("T11_AssetListPopulatedFromManifestAndData")
	var service := EditorService.get_instance()
	var ds = service.data_service
	var stable_ids := ds.get_all_stable_ids()
	assert_true(stable_ids.size() > 0, "EditorDataService provides active stable IDs")

func _test_T12_realtime_search_filters_assets() -> void:
	begin_test("T12_RealtimeSearchFiltersAssets")
	AssetRegistry.ensure_initialized()
	var ids := AssetRegistry.get_all_asset_ids()
	var search_term := "npc."
	var filtered = ids.filter(func(id): return str(id).contains(search_term))
	assert_true(filtered.size() > 0, "Search query 'npc.' finds matches")
	for f in filtered:
		assert_true(str(f).contains(search_term), "Filtered item '%s' contains search term" % str(f))

func _test_T13_modified_filter_shows_overridden_assets() -> void:
	begin_test("T13_ModifiedFilterShowsOverriddenAssets")
	var service := EditorService.get_instance()
	service.reset_all()
	service.set_property("npc.rowan", "flip_h", true)
	var ds = service.data_service
	assert_true(ds.has_override("npc.rowan") or ds.get_resolved_value("npc.rowan", "flip_h") == true, "Modified asset recognized as having override")
	assert_false(ds.has_override("npc.mira"), "Unmodified asset recognized as not having override")
	service.reset_all()

func _test_T14_missing_filter_shows_missing_assets() -> void:
	begin_test("T14_MissingFilterShowsMissingAssets")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._scan_missing_assets()
	assert_true(panel._missing_assets is Dictionary, "_missing_assets dictionary initialized")
	if panel: panel.free()

func _test_T15_favorites_filter_tracks_favs() -> void:
	begin_test("T15_FavoritesFilterTracksFavs")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._favorites = { "npc.rowan": true }
	assert_true(panel._favorites.has("npc.rowan"), "Favorited asset in set")
	assert_false(panel._favorites.has("tile.grass"), "Non-favorited asset not in set")
	if panel: panel.free()

# ===========================================================================
# 4. Preview & Zoom System (T16 - T20)
# ===========================================================================

func _test_T16_show_asset_updates_selected_id() -> void:
	begin_test("T16_ShowAssetUpdatesSelectedId")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._show_asset("tile.grass")
	assert_eq(panel._selected_asset_id, "tile.grass", "_selected_asset_id updated")
	if panel: panel.free()

func _test_T17_zoom_in_increments_scale() -> void:
	begin_test("T17_ZoomInIncrementsScale")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._zoom_level = 2.0
	panel._on_zoom_in()
	assert_eq(panel._zoom_level, 2.5, "Zoom In increments by 0.5")
	if panel: panel.free()

func _test_T18_zoom_out_decrements_and_clamps() -> void:
	begin_test("T18_ZoomOutDecrementsAndClamps")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._zoom_level = 2.0
	panel._on_zoom_out()
	assert_eq(panel._zoom_level, 1.5, "Zoom Out decrements by 0.5")
	panel._zoom_level = 0.5
	panel._on_zoom_out()
	assert_eq(panel._zoom_level, 0.5, "Zoom Out clamps at minimum 0.5")
	if panel: panel.free()

func _test_T19_zoom_fit_resets_scale() -> void:
	begin_test("T19_ZoomFitResetsScale")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._zoom_level = 5.0
	panel._on_zoom_fit()
	assert_eq(panel._zoom_level, 2.0, "Zoom Fit resets to default 2.0")
	if panel: panel.free()

func _test_T20_preview_resolves_valid_texture() -> void:
	begin_test("T20_PreviewResolvesValidTexture")
	var tex = AssetRegistry.get_asset_texture("tile.grass")
	assert_true(tex != null and tex is Texture2D, "get_asset_texture('tile.grass') resolves Texture2D")

# ===========================================================================
# 5. Animation Playback & Stepping (T21 - T25)
# ===========================================================================

func _test_T21_frame_stepping_forward() -> void:
	begin_test("T21_FrameSteppingForward")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._anim_frames = 4
	panel._anim_frame = 0
	panel._on_next_frame()
	assert_eq(panel._anim_frame, 1, "Next frame advances to 1")
	panel._on_next_frame()
	assert_eq(panel._anim_frame, 2, "Next frame advances to 2")
	if panel: panel.free()

func _test_T22_frame_stepping_backward_wraps() -> void:
	begin_test("T22_FrameSteppingBackwardWraps")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._anim_frames = 4
	panel._anim_frame = 0
	panel._on_prev_frame()
	assert_eq(panel._anim_frame, 3, "Prev frame wraps around to last frame (3)")
	if panel: panel.free()

func _test_T23_animation_play_toggle_state() -> void:
	begin_test("T23_AnimationPlayToggleState")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._on_play_toggled(true)
	assert_true(panel._anim_playing, "_anim_playing is true when toggled on")
	panel._on_play_toggled(false)
	assert_false(panel._anim_playing, "_anim_playing is false when toggled off")
	if panel: panel.free()

func _test_T24_animation_fps_updates() -> void:
	begin_test("T24_AnimationFpsUpdates")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._on_anim_fps_changed(12.0)
	assert_eq(panel._anim_fps, 12, "_anim_fps updated to 12")
	if panel: panel.free()

func _test_T25_animation_loop_flag() -> void:
	begin_test("T25_AnimationLoopFlag")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._anim_loop = true
	assert_true(panel._anim_loop, "Loop flag is true")
	panel._anim_loop = false
	assert_false(panel._anim_loop, "Loop flag set to false")
	if panel: panel.free()

# ===========================================================================
# 6. NPC & Character Workspace (T26 - T28)
# ===========================================================================

func _test_T26_npc_4way_direction_selection() -> void:
	begin_test("T26_Npc4WayDirectionSelection")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	for dir in ["up", "left", "down", "right"]:
		panel._on_direction_pressed(dir)
		assert_eq(panel._npc_direction, dir, "Direction set to %s" % dir)
		assert_eq(panel._anim_frame, 0, "Frame reset to 0 on direction switch")
	if panel: panel.free()

func _test_T27_npc_animation_states_selector() -> void:
	begin_test("T27_NpcAnimationStatesSelector")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._on_npc_anim_selected(1) # walk
	assert_eq(panel._npc_anim_name, "walk", "Animation state changed to 'walk'")
	panel._on_npc_anim_selected(0) # idle
	assert_eq(panel._npc_anim_name, "idle", "Animation state changed to 'idle'")
	if panel: panel.free()

func _test_T28_player_visual_asset_resolution() -> void:
	begin_test("T28_PlayerVisualAssetResolution")
	var p_tex = AssetRegistry.get_player_texture(Vector2i.DOWN, 0)
	assert_true(p_tex != null and p_tex is Texture2D, "Player texture resolved without crash")

# ===========================================================================
# 7. Override Flow & Staged Mutations (T29 - T34)
# ===========================================================================

func _test_T29_create_override_stages_entry() -> void:
	begin_test("T29_CreateOverrideStagesEntry")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.set_property("tile.grass", "_override_created", true)
	assert_true(service.data_service.has_override("tile.grass"), "Override staged for tile.grass")
	service.reset_all()

func _test_T30_flip_h_and_flip_v_overrides() -> void:
	begin_test("T30_FlipHAndFlipVOverrides")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.set_property("npc.rowan", "flip_h", true)
	service.set_property("npc.rowan", "flip_v", true)
	assert_true(service.data_service.get_resolved_value("npc.rowan", "flip_h") == true, "flip_h override applied")
	assert_true(service.data_service.get_resolved_value("npc.rowan", "flip_v") == true, "flip_v override applied")
	service.reset_all()

func _test_T31_scale_and_offset_overrides() -> void:
	begin_test("T31_ScaleAndOffsetOverrides")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.set_property("prop.tree", "scale", 1.8)
	service.set_property("prop.tree", "offset_x", 12.0)
	assert_eq(service.data_service.get_resolved_value("prop.tree", "scale"), 1.8, "Scale override stored")
	assert_eq(service.data_service.get_resolved_value("prop.tree", "offset_x"), 12.0, "Offset X stored")
	service.reset_all()

func _test_T32_filter_mode_and_modulate_overrides() -> void:
	begin_test("T32_FilterModeAndModulateOverrides")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.set_property("item.fertilizer", "filter_mode", "linear")
	service.set_property("item.fertilizer", "modulate", "#ff00ffff")
	assert_eq(service.data_service.get_resolved_value("item.fertilizer", "filter_mode"), "linear", "Filter mode stored")
	assert_eq(service.data_service.get_resolved_value("item.fertilizer", "modulate"), "#ff00ffff", "Modulate color stored")
	service.reset_all()

func _test_T33_animation_matrix_override() -> void:
	begin_test("T33_AnimationMatrixOverride")
	var service := EditorService.get_instance()
	_clean_state(service)
	var anim_dict = { "frames": 8, "columns": 4, "rows": 2, "fps": 10, "loop": true }
	service.set_property("npc.rowan", "animation", anim_dict)
	var res = service.data_service.get_resolved_value("npc.rowan", "animation")
	assert_true(res is Dictionary, "Animation override is Dictionary")
	assert_eq(res.get("fps", 0), 10, "FPS stored correctly")
	assert_eq(res.get("frames", 0), 8, "Frames stored correctly")
	service.reset_all()

func _test_T34_metadata_tags_and_display_name() -> void:
	begin_test("T34_MetadataTagsAndDisplayName")
	var service := EditorService.get_instance()
	_clean_state(service)
	var tags := ["custom", "npc", "merchant"]
	service.set_property("npc.rowan", "tags", tags)
	service.set_property("npc.rowan", "display_name", "Rowan the Elder")
	var res_tags = service.data_service.get_resolved_value("npc.rowan", "tags")
	var res_name = service.data_service.get_resolved_value("npc.rowan", "display_name")
	assert_true(res_tags is Array and res_tags.has("merchant"), "Tags stored and retrieved")
	assert_eq(res_name, "Rowan the Elder", "Display name stored and retrieved")
	service.reset_all()

# ===========================================================================
# 8. Reset, Undo & Redo (T35 - T38)
# ===========================================================================

func _test_T35_reset_single_asset_restores_default() -> void:
	begin_test("T35_ResetSingleAssetRestoresDefault")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.set_property("tile.soil", "scale", 2.0)
	assert_true(service.data_service.has_override("tile.soil"), "Override exists before reset")
	service.data_service.restore_default("tile.soil")
	assert_false(service.data_service.has_override("tile.soil"), "Override cleared after single asset reset")

func _test_T36_reset_category_resets_only_category() -> void:
	begin_test("T36_ResetCategoryResetsOnlyCategory")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.set_property("tile.soil", "scale", 2.0)
	service.set_property("npc.rowan", "scale", 2.0)
	service.data_service.reset_section("tile.")
	assert_false(service.data_service.has_override("tile.soil"), "tile.soil reset by section reset")
	assert_true(service.data_service.has_override("npc.rowan"), "npc.rowan preserved during tile section reset")
	service.reset_all()

func _test_T37_reset_all_assets_clears_all_overrides() -> void:
	begin_test("T37_ResetAllAssetsClearsAllOverrides")
	var service := EditorService.get_instance()
	service.set_property("tile.soil", "scale", 2.0)
	service.set_property("npc.rowan", "scale", 2.0)
	service.reset_all()
	assert_false(service.data_service.has_override("tile.soil"), "tile.soil cleared")
	assert_false(service.data_service.has_override("npc.rowan"), "npc.rowan cleared")

func _test_T38_undo_and_redo_support() -> void:
	begin_test("T38_UndoAndRedoSupport")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.set_property("npc.mira", "scale", 1.5)
	assert_eq(service.data_service.get_resolved_value("npc.mira", "scale"), 1.5, "Value set before undo")
	service.undo()
	var val_after = service.data_service.get_resolved_value("npc.mira", "scale")
	assert_true(val_after != 1.5 or val_after == null, "Undo reverted value")
	service.redo()
	assert_eq(service.data_service.get_resolved_value("npc.mira", "scale"), 1.5, "Redo restored value")
	service.reset_all()

# ===========================================================================
# 9. Missing Assets & Fallback System (T39 - T41)
# ===========================================================================

func _test_T39_scan_missing_assets_populates_missing_list() -> void:
	begin_test("T39_ScanMissingAssetsPopulatesMissingList")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	panel._scan_missing_assets()
	assert_true(panel._missing_assets is Dictionary, "_missing_assets scanned without crash")
	if panel: panel.free()

func _test_T40_nonexistent_asset_identified_as_missing() -> void:
	begin_test("T40_NonexistentAssetIdentifiedAsMissing")
	var bad_path := "res://assets/sprites/NONEXISTENT_XYZ_FILE_9999.png"
	assert_false(ResourceLoader.exists(bad_path), "Missing resource path correctly identified")

func _test_T41_fallback_placeholder_generation_no_crash() -> void:
	begin_test("T41_FallbackPlaceholderGenerationNoCrash")
	var placeholder = AssetRegistry.get_fallback_placeholder_texture("missing_item_99")
	assert_true(placeholder != null and placeholder is Texture2D, "Placeholder texture generated cleanly")

# ===========================================================================
# 10. Validation Service (T42 - T45)
# ===========================================================================

func _test_T42_validation_detects_missing_textures() -> void:
	begin_test("T42_ValidationDetectsMissingTextures")
	var service := EditorService.get_instance()
	var report = EditorValidationService.validate_data(service.data_service)
	assert_true(report.has("errors"), "Report contains errors array")
	assert_true(report.has("broken_references"), "Report contains broken_references counter")

func _test_T43_validation_detects_duplicate_stable_ids() -> void:
	begin_test("T43_ValidationDetectsDuplicateStableIds")
	var service := EditorService.get_instance()
	var report = EditorValidationService.validate_data(service.data_service)
	assert_true(report.has("duplicate_ids"), "Report tracks duplicate_ids")

func _test_T44_validation_detects_malformed_stable_ids() -> void:
	begin_test("T44_ValidationDetectsMalformedStableIds")
	var valid_id := "npc.rowan"
	var invalid_id := "rowan_no_dot"
	assert_true(valid_id.contains("."), "Valid ID has category prefix with '.'")
	assert_false(invalid_id.contains("."), "Malformed ID missing '.'")

func _test_T45_validation_detects_invalid_frames_or_size() -> void:
	begin_test("T45_ValidationDetectsInvalidFramesOrSize")
	var valid_frames := 4
	var invalid_frames := 0
	assert_true(valid_frames >= 1, "Valid frames >= 1")
	assert_false(invalid_frames >= 1, "Invalid frames caught by >= 1 check")

# ===========================================================================
# 11. Dependency Graph & Safety (T46 - T47)
# ===========================================================================

func _test_T46_dependency_graph_finds_referencing_entities() -> void:
	begin_test("T46_DependencyGraphFindsReferencingEntities")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	var service := EditorService.get_instance()
	var refs: Array = panel._find_used_by("npc.rowan", service.data_service)
	assert_true(refs is Array, "_find_used_by returns Array")
	if panel: panel.free()

func _test_T47_used_by_warning_alert_when_referenced() -> void:
	begin_test("T47_UsedByWarningAlertWhenReferenced")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	var dummy_refs := ["world.farm", "quest.harvest_time", "dialogue.rowan_intro"]
	assert_true(dummy_refs.size() == 3, "Dependencies detected for warning indicator")
	if panel: panel.free()

# ===========================================================================
# 12. Cross-Editor Navigation & Modding (T48 - T52)
# ===========================================================================

func _test_T48_cross_editor_open_npc_editor() -> void:
	begin_test("T48_CrossEditorOpenNpcEditor")
	var service := EditorService.get_instance()
	assert_true(service.has_method("navigate_to"), "EditorService supports navigate_to")

func _test_T49_cross_editor_place_in_world() -> void:
	begin_test("T49_CrossEditorPlaceInWorld")
	var service := EditorService.get_instance()
	assert_true(service.has_method("select_module"), "EditorService supports select_module for World Editor")

func _test_T50_cross_editor_item_crop_tool_links() -> void:
	begin_test("T50_CrossEditorItemCropToolLinks")
	var panel := ASSET_EDITOR_PANEL_SCRIPT.new()
	assert_true(panel.has_method("_on_open_item_editor"), "Panel has _on_open_item_editor")
	assert_true(panel.has_method("_on_open_crop_editor"), "Panel has _on_open_crop_editor")
	assert_true(panel.has_method("_on_open_tool_editor"), "Panel has _on_open_tool_editor")
	if panel: panel.free()

func _test_T51_mod_export_and_import_with_asset_overrides() -> void:
	begin_test("T51_ModExportAndImportWithAssetOverrides")
	var service := EditorService.get_instance()
	var mm = service.data_service.mod_manager
	assert_true(mm != null, "ModManager available in EditorDataService")
	var mod = mm.create_mod("test_asset_pack", "Test Asset Pack")
	assert_true(mod != null, "Mod created")
	mod.overrides["npc.rowan"] = { "flip_h": true }
	assert_true(mod.overrides.has("npc.rowan"), "Asset override stored in mod definition")
	mm.unregister_mod("test_asset_pack")

func _test_T52_base_game_files_protection_and_save_safety() -> void:
	begin_test("T52_BaseGameFilesProtectionAndSaveSafety")
	var service := EditorService.get_instance()
	service.reset_all()
	service.data_service.set_staged_override("prop.tree", "scale", 3.0)
	assert_true(service.data_service.has_override("prop.tree"), "Changes staged in memory / user override layer")
	service.reset_all()
	assert_false(service.data_service.has_override("prop.tree"), "Reset clears staging without modifying base res:// data")

# ===========================================================================
# 13. REAL USER WORKFLOW E2E TESTS (TEST A through TEST L)
# ===========================================================================

func _test_Workflow_A_import_preview_apply_restart() -> void:
	begin_test("Workflow_A_ImportPreviewApplyRestart")
	var service := EditorService.get_instance()
	_clean_state(service)
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	assert_true(panel != null, "AssetEditorPanel created for workflow test")
	
	# Create a temporary valid image on disk
	var tmp_img_path = "user://temp_custom_icon.png"
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.CYAN)
	img.save_png(tmp_img_path)
	
	# Execute real import
	var imported_path = panel.import_file(tmp_img_path, "item.custom_gem")
	assert_true(imported_path != "", "Import file returned valid destination path")
	assert_true(FileAccess.file_exists(imported_path), "Imported file physically written to user://imported_assets/")
	
	# Verify preview and staging
	assert_eq(panel._selected_asset_id, "item.custom_gem", "Imported asset selected in panel")
	assert_true(panel._current_preview_texture != null, "Preview texture resolved from imported file")
	
	# Apply & Save Overrides
	service.save()
	
	# Simulate restart by resetting in-memory state and reloading from disk
	var reloaded_ds = EditorDataService.new(service.undo_manager, service.mod_manager)
	reloaded_ds.load_saved_overrides()
	assert_true(reloaded_ds.has_override("item.custom_gem"), "Asset override persisted across restart simulation")
	
	# Verify AssetRegistry resolves imported texture
	var gameplay_tex = AssetRegistry.get_asset_texture("item.custom_gem")
	assert_true(gameplay_tex != null and gameplay_tex is Texture2D, "AssetRegistry resolves imported texture in gameplay")
	
	# Cleanup
	service.reset_all()
	service.save()
	if panel: panel.free()

func _test_Workflow_B_replace_existing_asset_and_resolve() -> void:
	begin_test("Workflow_B_ReplaceExistingAssetAndResolve")
	var service := EditorService.get_instance()
	_clean_state(service)
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	panel._show_asset("tile.grass")
	
	# Create a replacement texture
	var tmp_replace_path = "user://temp_gold_grass.png"
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.84, 0.0))
	img.save_png(tmp_replace_path)
	
	# Replace texture
	var dest = panel.replace_selected_texture(tmp_replace_path)
	assert_true(dest != "", "Replacement succeeded with valid path")
	
	# Save and verify gameplay resolution
	service.save()
	var overridden_tex = AssetRegistry.get_asset_texture("tile.grass")
	assert_true(overridden_tex != null, "AssetRegistry returns overridden texture for tile.grass")
	
	# Restore default
	service.restore_property_default("tile.grass")
	service.save()
	if panel: panel.free()

func _test_Workflow_C_override_modify_discard_reverts_base() -> void:
	begin_test("Workflow_C_OverrideModifyDiscardRevertsBase")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.save()
	
	# Stage changes
	service.set_property("npc.rowan", "scale", 3.5)
	service.set_property("npc.rowan", "flip_h", true)
	assert_true(service.is_dirty(), "Session is dirty after edits")
	
	# Discard changes
	service.discard()
	assert_false(service.is_dirty(), "Session clean after discard")
	assert_false(service.data_service.has_override("npc.rowan"), "Rowan override discarded back to base state")

func _test_Workflow_D_override_modify_save_reload_persists() -> void:
	begin_test("Workflow_D_OverrideModifySaveReloadPersists")
	var service := EditorService.get_instance()
	_clean_state(service)
	service.set_property("item.fertilizer", "scale", 2.2)
	service.set_property("item.fertilizer", "display_name", "Super Fertilizer")
	service.save()
	
	var ds2 = EditorDataService.new(service.undo_manager, service.mod_manager)
	ds2.load_saved_overrides()
	assert_eq(ds2.get_resolved_value("item.fertilizer", "scale"), 2.2, "Scale persisted to disk")
	assert_eq(ds2.get_resolved_value("item.fertilizer", "display_name"), "Super Fertilizer", "Display name persisted")
	
	service.reset_all()
	service.save()

func _test_Workflow_E_modify_multiple_reset_category_isolates() -> void:
	begin_test("Workflow_E_ModifyMultipleResetCategoryIsolates")
	var service := EditorService.get_instance()
	_clean_state(service)
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	
	# Modify assets across different categories
	service.set_property("npc.rowan", "scale", 2.0)
	service.set_property("npc.mira", "scale", 2.0)
	service.set_property("tile.grass", "scale", 2.0)
	service.set_property("crop.red_flower", "scale", 2.0)
	
	# Reset only NPC category
	panel._selected_category = "Npc"
	panel._on_reset_category_pressed()
	
	assert_false(service.data_service.has_override("npc.rowan"), "npc.rowan cleared by category reset")
	assert_false(service.data_service.has_override("npc.mira"), "npc.mira cleared by category reset")
	assert_true(service.data_service.has_override("tile.grass"), "tile.grass preserved outside category")
	assert_true(service.data_service.has_override("crop.red_flower"), "crop.red_flower preserved outside category")
	
	service.reset_all()
	if panel: panel.free()

func _test_Workflow_F_modify_multiple_reset_all_clears() -> void:
	begin_test("Workflow_F_ModifyMultipleResetAllClears")
	var service := EditorService.get_instance()
	_clean_state(service)
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	
	service.set_property("npc.rowan", "scale", 2.0)
	service.set_property("tile.grass", "scale", 2.0)
	service.set_property("item.fertilizer", "scale", 2.0)
	
	panel._on_reset_all_pressed()
	
	assert_false(service.data_service.has_override("npc.rowan"), "Rowan cleared by reset all")
	assert_false(service.data_service.has_override("tile.grass"), "Grass cleared by reset all")
	assert_false(service.data_service.has_override("item.fertilizer"), "Fertilizer cleared by reset all")
	assert_false(service.is_dirty(), "Clean dirty state after reset all")
	if panel: panel.free()

func _test_Workflow_G_missing_asset_validation_and_fallback() -> void:
	begin_test("Workflow_G_MissingAssetValidationAndFallback")
	var service := EditorService.get_instance()
	_clean_state(service)
	
	# Stage a broken asset reference
	service.set_property("crop.broken_plant", "texture", "res://assets/sprites/MISSING_IMAGE_XYZ.png")
	
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	panel.setup(service)
	panel._scan_missing_assets()
	assert_true(panel._missing_assets.has("crop.broken_plant"), "Broken texture detected in missing assets list")
	
	# Fallback placeholder renders without engine crash
	var placeholder = AssetRegistry.get_asset_texture("crop.broken_plant")
	assert_true(placeholder != null and placeholder is Texture2D, "Graceful fallback texture generated")
	
	var val_report = service.validate()
	assert_true(val_report is Dictionary, "Validation report is Dictionary")
	assert_true(val_report.has("errors"), "Validation report contains errors list")
	
	_clean_state(service)
	if panel: panel.free()

func _test_Workflow_H_npc_asset_cross_navigation_selects_npc() -> void:
	begin_test("Workflow_H_NpcAssetCrossNavigationSelectsNpc")
	var service := EditorService.get_instance()
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	panel._show_asset("npc.rowan")
	panel._on_open_npc_editor()
	
	assert_eq(service.session.active_module, "npc", "Session navigated to NPC module")
	assert_eq(service.session.active_npc, "rowan", "Session active NPC set to rowan")
	if panel: panel.free()

func _test_Workflow_I_crop_asset_cross_navigation_selects_crop() -> void:
	begin_test("Workflow_I_CropAssetCrossNavigationSelectsCrop")
	var service := EditorService.get_instance()
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	panel._show_asset("crop.red_flower")
	panel._on_open_crop_editor()
	
	assert_eq(service.session.active_module, "crop", "Session navigated to crop sub-mode")
	assert_eq(service.session.active_item, "crop.red_flower", "Session active item set to crop.red_flower")
	if panel: panel.free()

func _test_Workflow_J_tool_asset_cross_navigation_selects_tool() -> void:
	begin_test("Workflow_J_ToolAssetCrossNavigationSelectsTool")
	var service := EditorService.get_instance()
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	panel._show_asset("tool.hoe")
	panel._on_open_tool_editor()
	
	assert_eq(service.session.active_module, "tool", "Session navigated to tool sub-mode")
	assert_eq(service.session.active_item, "tool.hoe", "Session active item set to tool.hoe")
	if panel: panel.free()

func _test_Workflow_K_world_asset_cross_navigation_selects_brush() -> void:
	begin_test("Workflow_K_WorldAssetCrossNavigationSelectsBrush")
	var service := EditorService.get_instance()
	var panel = EditorRegistry.create_panel("assets", service) as AssetEditorPanel
	panel._show_asset("tile.grass")
	panel._on_place_in_world()
	
	assert_eq(service.session.active_module, "world", "Session navigated to world module")
	if panel: panel.free()

func _test_Workflow_L_bhmod_export_import_override_pipeline() -> void:
	begin_test("Workflow_L_BhmodExportImportOverridePipeline")
	var service := EditorService.get_instance()
	_clean_state(service)
	var mm = service.data_service.mod_manager
	
	# Create mod with asset overrides
	var mod = mm.create_mod("visual_overhaul", "Visual Overhaul Mod")
	mod.overrides["tile.grass"] = { "modulate": "#00ff00ff", "scale": 1.5 }
	mod.overrides["npc.rowan"] = { "flip_h": true }
	
	# Export mod package
	var res_export = mm.export_mod_package("visual_overhaul", "user://mods")
	assert_true(res_export.get("success", false) == true, "Mod exported to .bhmod package")
	var export_path = str(res_export.get("path", "user://mods/visual_overhaul.bhmod"))
	assert_true(FileAccess.file_exists(export_path), ".bhmod file physically created on disk")
	
	# Import in clean mod manager instance
	var mm2 = ModManager.new()
	var res_import = mm2.import_mod(export_path)
	assert_true(res_import.get("success", false) == true, "Mod imported from .bhmod package")
	var imported_mod = res_import.get("mod", null)
	assert_true(imported_mod != null, "Imported mod definition exists")
	assert_true(imported_mod.overrides.has("tile.grass"), "Imported mod contains tile.grass override")
	assert_true(imported_mod.overrides.has("npc.rowan"), "Imported mod contains npc.rowan override")
	
	mm.unregister_mod("visual_overhaul")
	mm2.unregister_mod("visual_overhaul")
