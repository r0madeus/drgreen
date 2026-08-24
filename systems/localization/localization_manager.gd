extends Node


## Central Localization & Internationalization Manager (Autoload Singleton).
## Manages TranslationServer locale synchronization, runtime language changes,
## placeholder templates, fallback key resolution, pseudo-localization and debug inspections.

signal locale_changed(locale_id: String)
signal pseudo_localization_toggled(enabled: bool)
signal debug_keys_toggled(enabled: bool)

const FALLBACK_LOCALE: String = "en"
const CSV_PATH: String = "res://localization/game.csv"

const SUPPORTED_LOCALES: Dictionary = {
	"en": "English",
	"tr": "Türkçe",
	"de": "Deutsch",
	"fr": "Français",
	"es": "Español",
	"pt_BR": "Português (Brasil)",
	"ja": "日本語",
	"ko": "한국어",
	"zh_CN": "简体中文",
	"ru": "Русский"
}

var current_locale: String = FALLBACK_LOCALE
var is_pseudo_localization: bool = false
var is_debug_keys: bool = false

# In-memory CSV cache for reliable fallback resolution and validator
var _translation_cache: Dictionary = {} # key -> { "en": "...", "tr": "..." }

func _init() -> void:
	_load_csv_cache()

func _ready() -> void:
	_load_csv_cache()
	
	# Bind with LocalStateManager if available
	var lsm = get_node_or_null("/root/LocalStateManager")
	if lsm:
		var saved_lang = str(lsm.get_setting("language", "current_language", FALLBACK_LOCALE))
		set_locale(saved_lang, false)
	else:
		set_locale(FALLBACK_LOCALE, false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			toggle_pseudo_localization()
			get_viewport().set_input_as_handled()

func _load_csv_cache() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		return
		
	var f_read = FileAccess.open(CSV_PATH, FileAccess.READ)
	if not f_read: return

	var header = f_read.get_csv_line()
	if header.is_empty():
		f_read.close()
		return
		
	var lang_cols: Array[String] = []
	var translations: Dictionary = {} # lang_code -> Translation
	for i in range(1, header.size()):
		var l_code = header[i].strip_edges()
		if l_code != "":
			lang_cols.append(l_code)
			var tr_obj = Translation.new()
			tr_obj.locale = l_code
			translations[l_code] = tr_obj
		
	_translation_cache.clear()
	
	while not f_read.eof_reached():
		var row = f_read.get_csv_line()
		if row.size() < 2: continue
		var key = row[0].strip_edges()
		if key == "" or key.begins_with("#"): continue
		
		_translation_cache[key] = {}
		for i in range(lang_cols.size()):
			var col_idx = i + 1
			if col_idx < row.size():
				var val = row[col_idx]
				_translation_cache[key][lang_cols[i]] = val
				translations[lang_cols[i]].add_message(StringName(key), StringName(val))
	f_read.close()

	
	for l_code in translations.keys():
		TranslationServer.add_translation(translations[l_code])


# ==============================================================================
# LOCALE CONTROL
# ==============================================================================

func get_current_locale() -> String:
	return current_locale

func has_key(key: String) -> bool:
	return _translation_cache.has(key)


func get_supported_languages() -> Dictionary:
	return SUPPORTED_LOCALES.duplicate()

func set_locale(locale_id: String, save_to_state: bool = true) -> void:
	if not SUPPORTED_LOCALES.has(locale_id):
		locale_id = FALLBACK_LOCALE
		
	current_locale = locale_id
	TranslationServer.set_locale(locale_id)
	
	if save_to_state:
		var lsm = get_node_or_null("/root/LocalStateManager")
		if lsm:
			lsm.set_setting("language", "current_language", locale_id)
			
	locale_changed.emit(locale_id)

func toggle_pseudo_localization() -> void:
	set_pseudo_localization(not is_pseudo_localization)

func set_pseudo_localization(enabled: bool) -> void:
	is_pseudo_localization = enabled
	pseudo_localization_toggled.emit(is_pseudo_localization)
	locale_changed.emit(current_locale)
	
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		var msg = "🌐 Pseudo-Localization: ON" if is_pseudo_localization else "🌐 Pseudo-Localization: OFF"
		spawner.spawn_floating_text(pos, msg, Color(0.9, 0.6, 1.0))

func toggle_debug_keys() -> void:
	is_debug_keys = not is_debug_keys
	debug_keys_toggled.emit(is_debug_keys)
	locale_changed.emit(current_locale)

# ==============================================================================
# TRANSLATION HELPERS
# ==============================================================================

func get_text(key: String, default_fallback: String = "") -> String:
	if is_debug_keys:
		return "[KEY: %s]" % key
		
	# 1. Check Godot TranslationServer
	var translated = tr(key)
	
	# 2. If translation not found (returns key itself), check cache fallback
	if translated == key and _translation_cache.has(key):
		var entry = _translation_cache[key]
		if entry.has(current_locale) and entry[current_locale] != "":
			translated = entry[current_locale]
		elif entry.has(FALLBACK_LOCALE) and entry[FALLBACK_LOCALE] != "":
			translated = entry[FALLBACK_LOCALE]
			
	# 3. If still unresolved, fallback to provided string or readable key
	if translated == key and default_fallback != "":
		translated = default_fallback
		
	# 4. Apply pseudo-localization if active
	if is_pseudo_localization:
		return pseudo_localize(translated)
		
	return translated

func format(key: String, params: Dictionary = {}) -> String:
	var template = get_text(key)
	for p_key in params.keys():
		var val_str = str(params[p_key])
		template = template.replace("{%s}" % p_key, val_str)
	return template

func get_plural(key_single: String, key_plural: String, count: int, params: Dictionary = {}) -> String:
	var target_key = key_single if count == 1 else key_plural
	var p = params.duplicate()
	p["count"] = count
	return format(target_key, p)

func pseudo_localize(input_str: String) -> String:
	if input_str == "": return ""
	var map = {
		"a": "ä", "A": "Å",
		"e": "ë", "E": "Ë",
		"i": "ï", "I": "Ï",
		"o": "ø", "O": "Ø",
		"u": "ü", "U": "Ü",
		"y": "ÿ", "Y": "Ÿ"
	}
	var out = ""
	for char in input_str:
		out += map.get(char, char)
	return "[%s ~!]" % out

# ==============================================================================
# SPECIALIZED HELPERS
# ==============================================================================

func get_item_name(item_id: String) -> String:
	var key = "item.%s.name" % item_id
	if item_id.begins_with("hoe_") or item_id.begins_with("watering_can_") or item_id.begins_with("axe_") or item_id.begins_with("pickaxe_"):
		key = "tool.%s.name" % item_id
	return get_text(key, item_id.replace("_", " ").capitalize())

func get_item_description(item_id: String) -> String:
	var key = "item.%s.desc" % item_id
	return get_text(key, "")

func get_world_name(world_id: String) -> String:
	var key = "world.%s.name" % world_id
	return get_text(key, world_id.replace("_", " ").capitalize())

func get_weather_name(weather_id: String) -> String:
	var key = "weather.%s.name" % weather_id.to_lower()
	return get_text(key, weather_id.capitalize())

func get_season_name(season_id: String) -> String:
	var key = "season.%s.name" % season_id.to_lower()
	return get_text(key, season_id.capitalize())
