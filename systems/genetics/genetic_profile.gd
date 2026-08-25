class_name GeneticProfile
extends RefCounted

## Represents the canonical genetic makeup of a seed or plant variant.
## Provides stable identity hashing for inventory stacking.

var size: String = "medium"
var color: String = "white"
var shape: String = "flower"
var productivity: int = 1
var taste_profile: Array[String] = []
var water_required: bool = true
var growth_speed: String = "normal"

func _init() -> void:
	pass

func get_canonical_string() -> String:
	# Sort the taste profile alphabetically so ["sweet", "sour"] == ["sour", "sweet"]
	var sorted_taste: Array[String] = []
	for t in taste_profile:
		if str(t) not in sorted_taste:
			sorted_taste.append(str(t))
	sorted_taste.sort()
	
	var taste_str = "[" + ",".join(sorted_taste) + "]"
	
	var parts = [
		"size:" + size,
		"color:" + color,
		"shape:" + shape,
		"prod:" + str(productivity),
		"taste:" + taste_str,
		"water:" + str(water_required),
		"speed:" + growth_speed
	]
	
	return "|".join(parts)

func get_identity() -> String:
	var can = get_canonical_string()
	return can.md5_text().substr(0, 10) # 10-char hash is plenty for inventory unique key

func to_dict() -> Dictionary:
	var sorted_taste: Array[String] = []
	for t in taste_profile:
		if str(t) not in sorted_taste:
			sorted_taste.append(str(t))
	sorted_taste.sort()
	return {
		"size": size,
		"color": color,
		"shape": shape,
		"productivity": productivity,
		"taste_profile": sorted_taste,
		"water_required": water_required,
		"growth_speed": growth_speed
	}

static func from_dict(data: Dictionary) -> GeneticProfile:
	var p = GeneticProfile.new()
	p.size = data.get("size", "medium")
	p.color = data.get("color", "white")
	p.shape = data.get("shape", "flower")
	p.productivity = int(data.get("productivity", 1))
	
	var taste_arr = data.get("taste_profile", [])
	var parsed_taste: Array[String] = []
	for t in taste_arr:
		if str(t) not in parsed_taste:
			parsed_taste.append(str(t))
	p.taste_profile = parsed_taste
	
	p.water_required = bool(data.get("water_required", true))
	p.growth_speed = data.get("growth_speed", "normal")
	return p

func is_equal(other: GeneticProfile) -> bool:
	if not other: return false
	return get_canonical_string() == other.get_canonical_string()
