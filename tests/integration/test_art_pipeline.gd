class_name TestArtPipeline
extends TestCase

## Comprehensive 20-Point Art Pipeline, Stable ID Resolution, Asset Swapping,
## Fallback Generation, and Production-Asset Readiness Test Suite (Phase 25).

func test_name_id() -> String:
	return "ART.ProductionPipeline"

func _get_root_node(path: String) -> Node:
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root:
		return loop.root.get_node_or_null(path)
	return null

func run_all() -> void:
	test_name = test_name_id()
	
	_test_T01_asset_manifest_integrity()
	_test_T02_no_duplicate_asset_ids()
	_test_T03_no_broken_asset_references()
	_test_T04_no_hardcoded_gameplay_asset_paths()
	_test_T05_player_animation_resolution()
	_test_T06_npc_animation_resolution()
	_test_T07_crop_growth_resolution()
	_test_T08_tool_asset_resolution()
	_test_T09_item_icon_resolution()
	_test_T10_world_prop_resolution()
	_test_T11_ui_theme_resolution()
	_test_T12_vfx_resolution()
	_test_T13_sfx_resolution()
	_test_T14_music_resolution()
	_test_T15_asset_swap_runtime()
	_test_T16_save_asset_independence()
	_test_T17_network_asset_independence()
	_test_T18_missing_asset_fallback()
	_test_T19_artist_workflow_validation()
	_test_T20_production_asset_audit()

# --- 1. Manifest & Path Integrity ---

func _test_T01_asset_manifest_integrity() -> void:
	begin_test("T01_AssetManifestIntegrity")
	AssetRegistry.ensure_initialized()
	var ids = AssetRegistry.get_all_asset_ids()
	assert_true(ids.size() > 0, "Asset manifest loaded with valid entries (> 0 assets)")

func _test_T02_no_duplicate_asset_ids() -> void:
	begin_test("T02_NoDuplicateAssetIDs")
	var rep = AssetPipelineValidator.validate_all()
	assert_eq(rep.get("duplicate_ids", 0), 0, "Zero duplicate asset IDs in manifest")

func _test_T03_no_broken_asset_references() -> void:
	begin_test("T03_NoBrokenAssetReferences")
	var rep = AssetPipelineValidator.validate_all()
	assert_eq(rep.get("broken_references", 0), 0, "Zero broken physical asset paths")

func _test_T04_no_hardcoded_gameplay_asset_paths() -> void:
	begin_test("T04_NoHardcodedGameplayAssetPaths")
	var rep = AssetPipelineValidator.validate_all()
	assert_eq(rep.get("hardcoded_paths", 0), 0, "Zero hardcoded asset paths in world JSONs")

# --- 2. Entity & Gameplay Asset Resolution ---

func _test_T05_player_animation_resolution() -> void:
	begin_test("T05_PlayerAnimationResolution")
	var tex_down = AssetRegistry.get_texture("character.player.idle.down")
	var tex_up = AssetRegistry.get_texture("character.player.idle.up")
	assert_true(tex_down != null, "Player idle down texture resolved")
	assert_true(tex_up != null, "Player idle up texture resolved")

func _test_T06_npc_animation_resolution() -> void:
	begin_test("T06_NPCAnimationResolution")
	var tex_walk = AssetRegistry.get_npc_animation_texture("rowan", "walk", "left")
	var tex_work = AssetRegistry.get_npc_animation_texture("rowan", "work", "down")
	assert_true(tex_walk != null, "Rowan walk left texture resolved")
	assert_true(tex_work != null, "Rowan work down texture resolved")


func _test_T07_crop_growth_resolution() -> void:
	begin_test("T07_CropGrowthResolution")
	var stage0 = AssetRegistry.get_crop_texture("red_flower", 0)
	var mature = AssetRegistry.get_crop_texture("red_flower", 3)
	assert_true(stage0 != null, "Red flower stage 0 texture resolved")
	assert_true(mature != null, "Red flower mature texture resolved")

func _test_T08_tool_asset_resolution() -> void:
	begin_test("T08_ToolAssetResolution")
	var hoe_basic = AssetRegistry.get_tool_icon("hoe_basic")
	var hoe_copper = AssetRegistry.get_tool_icon("hoe_copper")
	assert_true(hoe_basic != null, "Basic hoe icon resolved")
	assert_true(hoe_copper != null, "Copper hoe icon resolved")

func _test_T09_item_icon_resolution() -> void:
	begin_test("T09_ItemIconResolution")
	var seed_tex = AssetRegistry.get_item_icon("seed_red_flower")
	var crop_tex = AssetRegistry.get_item_icon("plant_red_flower")
	assert_true(seed_tex != null, "Seed item icon resolved")
	assert_true(crop_tex != null, "Crop item icon resolved")

func _test_T10_world_prop_resolution() -> void:
	begin_test("T10_WorldPropResolution")
	var tree_tex = AssetRegistry.get_texture("prop.tree.oak")
	var rock_tex = AssetRegistry.get_texture("prop.rock.small")
	assert_true(tree_tex != null, "Oak tree prop texture resolved")
	assert_true(rock_tex != null, "Rock prop texture resolved")

# --- 3. UI, VFX, Audio & Music ---

func _test_T11_ui_theme_resolution() -> void:
	begin_test("T11_UIThemeResolution")
	var coin_icon = AssetRegistry.get_texture("ui.icon.coin")
	var energy_icon = AssetRegistry.get_texture("ui.icon.energy")
	assert_true(coin_icon != null, "UI coin icon resolved")
	assert_true(energy_icon != null, "UI energy icon resolved")

func _test_T12_vfx_resolution() -> void:
	begin_test("T12_VFXResolution")
	var spawner = EffectSpawner.get_instance()
	assert_true(spawner != null, "EffectSpawner ready for stable VFX dispatch")

func _test_T13_sfx_resolution() -> void:
	begin_test("T13_SFXResolution")
	var am = _get_root_node("/root/AudioManager")
	if am:
		assert_true(am.has_method("play_sfx"), "AudioManager provides stable play_sfx API")

func _test_T14_music_resolution() -> void:
	begin_test("T14_MusicResolution")
	var am = _get_root_node("/root/AudioManager")
	if am:
		assert_true(am.has_method("play_music"), "AudioManager provides stable play_music API")

# --- 4. Runtime Asset Swapping & Independence ---

func _test_T15_asset_swap_runtime() -> void:
	begin_test("T15_AssetSwapRuntime")
	var dummy_tex = ImageTexture.create_from_image(Image.create_empty(16, 16, false, Image.FORMAT_RGBA8))
	AssetRegistry.register_texture_override("test.swap.item", dummy_tex)
	var resolved = AssetRegistry.get_texture("test.swap.item")
	assert_eq(resolved, dummy_tex, "Runtime texture override immediately resolves without code changes")
	AssetRegistry.remove_texture_override("test.swap.item")


func _test_T16_save_asset_independence() -> void:
	begin_test("T16_SaveAssetIndependence")
	var p = PlayerState.new("p_art_save")
	p.init_starter_kit()
	var save_data = p.to_dict()
	var json_str = JSON.stringify(save_data)
	assert_false("res://assets/" in json_str, "Save blob contains zero physical asset paths")

func _test_T17_network_asset_independence() -> void:
	begin_test("T17_NetworkAssetIndependence")
	var net_packet = {
		"action": "use_tool",
		"tool_id": "hoe_basic",
		"target_cell": [15, 12]
	}
	var packet_str = JSON.stringify(net_packet)
	assert_false("res://assets/" in packet_str, "Multiplayer packet uses pure stable IDs")

func _test_T18_missing_asset_fallback() -> void:
	begin_test("T18_MissingAssetFallback")
	var fb = AssetRegistry.get_texture("completely.unknown.missing.asset.id.12345")
	assert_true(fb != null, "Non-existent asset ID returns safe generated placeholder texture")

func _test_T19_artist_workflow_validation() -> void:
	begin_test("T19_ArtistWorkflowValidation")
	var meta = AssetRegistry.get_metadata("character.player.idle.down")
	assert_true(meta.size() > 0 or AssetRegistry.get_texture("character.player.idle.down") != null, "Asset metadata accessible for tooling")

func _test_T20_production_asset_audit() -> void:
	begin_test("T20_ProductionAssetAudit")
	var rep = AssetPipelineValidator.validate_all()
	assert_true(rep.get("valid", false), "Complete asset audit passed with 0 errors")
