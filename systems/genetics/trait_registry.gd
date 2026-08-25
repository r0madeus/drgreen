extends Node

## Loads and provides validation for all base genetic traits.

const TRAITS_DATA_PATH = "res://data/genetics/traits.json"

var _traits_data: Dictionary = {}
var _color_ids: Array[String] = []
var _shape_ids: Array[String] = []

func _ready() -> void:
	load_traits_data()

func load_traits_data() -> bool:
	_traits_data.clear()
	_color_ids.clear()
	_shape_ids.clear()
	
	if not FileAccess.file_exists(TRAITS_DATA_PATH):
		push_error("Traits data file not found: " + TRAITS_DATA_PATH)
		return false
		
	var file = FileAccess.open(TRAITS_DATA_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open traits data: " + TRAITS_DATA_PATH)
		return false
		
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("JSON Parse Error in " + TRAITS_DATA_PATH + ": " + json.get_error_message())
		return false
		
	var data = json.data
	if typeof(data) == TYPE_DICTIONARY and data.has("traits"):
		_traits_data = data["traits"]
		
		# Extract valid IDs from color and shape arrays
		if _traits_data.has("color"):
			for c in _traits_data["color"]:
				_color_ids.append(str(c.get("id", "")))
				
		if _traits_data.has("shape"):
			for s in _traits_data["shape"]:
				_shape_ids.append(str(s.get("id", "")))
				
	print("[TraitRegistry] Successfully loaded genetic traits.")
	return true

func is_valid_size(size: String) -> bool:
	return size in _traits_data.get("size", [])

func is_valid_color(color_id: String) -> bool:
	return color_id in _color_ids

func is_valid_shape(shape_id: String) -> bool:
	return shape_id in _shape_ids

func is_valid_productivity(prod: int) -> bool:
	# JSON parses ints as floats in GDScript, so we check float values as well
	var prods = _traits_data.get("productivity", [])
	for p in prods:
		if int(p) == prod:
			return true
	return false

func is_valid_taste(taste: String) -> bool:
	return taste in _traits_data.get("taste_profile", [])

func is_valid_water_required(req: bool) -> bool:
	return req in _traits_data.get("water_required", [])

func is_valid_growth_speed(speed: String) -> bool:
	return speed in _traits_data.get("growth_speed", [])

func get_color_data(color_id: String) -> Dictionary:
	for c in _traits_data.get("color", []):
		if c.get("id", "") == color_id:
			return c
	return {}

func get_random_size(rng: RandomNumberGenerator = null) -> String:
	var arr = _traits_data.get("size", [])
	if arr.is_empty(): return "medium"
	var idx = rng.randi() % arr.size() if rng else randi() % arr.size()
	return str(arr[idx])

func get_random_color(rng: RandomNumberGenerator = null) -> String:
	if _color_ids.is_empty(): return "white"
	var idx = rng.randi() % _color_ids.size() if rng else randi() % _color_ids.size()
	return _color_ids[idx]

func get_random_shape(rng: RandomNumberGenerator = null) -> String:
	if _shape_ids.is_empty(): return "flower"
	var idx = rng.randi() % _shape_ids.size() if rng else randi() % _shape_ids.size()
	return _shape_ids[idx]

func get_random_productivity(rng: RandomNumberGenerator = null) -> int:
	var arr = _traits_data.get("productivity", [])
	if arr.is_empty(): return 1
	var idx = rng.randi() % arr.size() if rng else randi() % arr.size()
	return int(arr[idx])

func get_random_taste(rng: RandomNumberGenerator = null) -> String:
	var arr = _traits_data.get("taste_profile", [])
	if arr.is_empty(): return "sweet"
	var idx = rng.randi() % arr.size() if rng else randi() % arr.size()
	return str(arr[idx])

func get_random_water_required(rng: RandomNumberGenerator = null) -> bool:
	var arr = _traits_data.get("water_required", [])
	if arr.is_empty(): return false
	var idx = rng.randi() % arr.size() if rng else randi() % arr.size()
	return bool(arr[idx])

func get_random_growth_speed(rng: RandomNumberGenerator = null) -> String:
	var arr = _traits_data.get("growth_speed", [])
	if arr.is_empty(): return "medium"
	var idx = rng.randi() % arr.size() if rng else randi() % arr.size()
	return str(arr[idx])
