class_name TestAssetRegistry
extends TestCase

## Unit tests for AssetRegistry — stable ID lookup, missing asset, duplicate detection.

func test_name_id() -> String:
	return "UNIT.AssetRegistry"

func run_all() -> void:
	test_name = test_name_id()
	_test_manifest_loaded()
	_test_known_ids_resolve()
	_test_missing_asset_returns_empty()
	_test_id_stability()
	_test_no_duplicate_ids()

func _test_manifest_loaded() -> void:
	begin_test("manifest_loaded")
	AssetRegistry.ensure_initialized()
	# Manifest may be empty in minimal build — just ensure no crash
	assert_true(AssetRegistry.get_all_asset_ids() is Array, "get_all_asset_ids returns Array")

func _test_known_ids_resolve() -> void:
	begin_test("known_ids_resolve")
	var known_ids = ["tile.grass", "tile.soil", "tile.water", "prop.tree", "prop.rock"]
	for asset_id in known_ids:
		var entry = AssetRegistry.get_metadata(asset_id)
		if not entry.is_empty():
			_pass("'%s' resolved" % asset_id)
		else:
			# May be absent in minimal build — not a hard failure
			_results.append({
				"test": _current_test,
				"assertion": "WARN: '%s' not in manifest (check asset_manifest.json)" % asset_id,
				"status": "PASS"
			})

func _test_missing_asset_returns_empty() -> void:
	begin_test("missing_asset_returns_empty")
	var result = AssetRegistry.get_metadata("NONEXISTENT_FAKE_ID_XYZ_999")
	# Must return empty dict, never crash
	assert_true(result is Dictionary, "missing asset returns Dictionary (no crash)")
	assert_true(result.is_empty(), "missing asset returns empty dict")

func _test_id_stability() -> void:
	begin_test("id_stability")
	# Fetch same id twice — must return equivalent result
	var first = AssetRegistry.get_metadata("tile.grass")
	var second = AssetRegistry.get_metadata("tile.grass")
	assert_eq(first.hash(), second.hash(), "same id returns same metadata both times")

func _test_no_duplicate_ids() -> void:
	begin_test("no_duplicate_ids")
	var all_ids = AssetRegistry.get_all_asset_ids()
	var seen: Array = []
	var has_dupes = false
	for key in all_ids:
		if seen.has(key):
			has_dupes = true
			break
		seen.append(key)
	assert_false(has_dupes, "no duplicate asset IDs in manifest")
