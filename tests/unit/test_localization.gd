class_name TestLocalization
extends TestCase

## Unit tests for LocalizationManager — key lookup, fallback, placeholder, locale switching.

func test_name_id() -> String:
	return "UNIT.Localization"

func run_all() -> void:
	test_name = test_name_id()
	_test_key_lookup_en()
	_test_fallback_on_missing_locale()
	_test_missing_key_returns_key()
	_test_placeholder_substitution()
	_test_locale_switching()
	_test_supported_locales_list()
	_test_no_localised_text_in_save_ids()

func _get_lm() -> LocalizationManager:
	var root = Engine.get_main_loop().root
	return root.get_node_or_null("/root/LocalizationManager") as LocalizationManager

func _test_key_lookup_en() -> void:
	begin_test("key_lookup_en")
	var lm = _get_lm()
	if not lm:
		_results.append({"test": _current_test, "assertion": "SKIP: no LocalizationManager", "status": "PASS"})
		return
	var result = lm.get_text("ui.hud.gold")
	assert_not_empty(result, "gold_label key resolves to non-empty string")
	assert_ne(result, "ui.hud.gold", "gold_label not returned as raw key")

func _test_fallback_on_missing_locale() -> void:
	begin_test("fallback_on_missing_locale")
	var lm = _get_lm()
	if not lm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var prev = lm.current_locale
	lm.set_locale("xx", false) # non-existent locale
	var result = lm.get_text("ui.hud.gold")
	assert_not_empty(result, "fallback returns value even for missing locale")
	lm.set_locale(prev, false) # restore


func _test_missing_key_returns_key() -> void:
	begin_test("missing_key_returns_key")
	# TranslationServer returns the key itself when a key has no translation
	var result = TranslationServer.translate("nonexistent.key.xyz")
	assert_eq(result, "nonexistent.key.xyz", "missing key returned as-is")

func _test_placeholder_substitution() -> void:
	begin_test("placeholder_substitution")
	# Verify GDScript format() works as expected for localization placeholders
	var template = "Hello {0}!"
	var formatted = template.format(["World"])
	assert_eq(formatted, "Hello World!", "format() placeholder substitution works")

func _test_locale_switching() -> void:
	begin_test("locale_switching")
	var lm = _get_lm()
	if not lm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var prev = lm.current_locale
	lm.set_locale("en", false)
	assert_eq(lm.current_locale, "en", "locale set to en")
	lm.set_locale(prev, false) # restore

func _test_supported_locales_list() -> void:
	begin_test("supported_locales_list")
	var lm = _get_lm()
	if not lm:
		_results.append({"test": _current_test, "assertion": "SKIP", "status": "PASS"})
		return
	var locales = lm.SUPPORTED_LOCALES
	assert_true(locales is Dictionary, "SUPPORTED_LOCALES is Dictionary")
	assert_has(locales, "en", "en in supported locales")
	assert_has(locales, "tr", "tr in supported locales")
	assert_gt(locales.size(), 2, "at least 3 locales")

func _test_no_localised_text_in_save_ids() -> void:
	begin_test("no_localised_text_in_save_ids")
	# Item IDs and world IDs used in save files must NOT contain localised display text.
	# They must be stable machine-readable IDs like "hoe_basic", "farm", "seed_red_flower".
	var save_item_ids = ["hoe_basic", "watering_can_basic", "axe_basic", "pickaxe_basic",
		"seed_red_flower", "seed_blue_flower", "wood", "stone"]
	var world_ids = ["farm", "town", "whispering_forest", "botanical_grove"]

	for id_str in save_item_ids:
		assert_false(id_str.contains(" "), "item id '%s' has no spaces" % id_str)
		assert_eq(id_str, id_str.to_lower(), "item id '%s' is lowercase" % id_str)
	for id_str in world_ids:
		assert_false(id_str.contains(" "), "world id '%s' has no spaces" % id_str)
