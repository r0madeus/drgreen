class_name GeneticsEngine
extends RefCounted

const CONFIG_PATH = "res://data/genetics/config.json"

var prob_parent_a: float = 0.70
var prob_parent_b: float = 0.20
var prob_mutation: float = 0.10

func _init() -> void:
	_load_config()

func _load_config() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		var content = file.get_as_text()
		var json = JSON.new()
		if json.parse(content) == OK:
			var data = json.data
			if typeof(data) == TYPE_DICTIONARY and data.has("inheritance"):
				var inh = data["inheritance"]
				prob_parent_a = float(inh.get("prob_parent_a", prob_parent_a))
				prob_parent_b = float(inh.get("prob_parent_b", prob_parent_b))
				prob_mutation = float(inh.get("prob_mutation", prob_mutation))

func _randf(rng: RandomNumberGenerator) -> float:
	if rng != null:
		return rng.randf()
	return randf()

func breed(parent_a: GeneticProfile, parent_b: GeneticProfile, rng: RandomNumberGenerator = null) -> GeneticProfile:
	var offspring = GeneticProfile.new()
	var tr = Engine.get_main_loop().root.get_node_or_null("TraitRegistry")
	
	offspring.size = _inherit_trait(parent_a.size, parent_b.size, tr.get_random_size(rng) if tr else "medium", rng)
	offspring.color = _inherit_trait(parent_a.color, parent_b.color, tr.get_random_color(rng) if tr else "white", rng)
	offspring.shape = _inherit_trait(parent_a.shape, parent_b.shape, tr.get_random_shape(rng) if tr else "flower", rng)
	offspring.productivity = _inherit_trait(parent_a.productivity, parent_b.productivity, tr.get_random_productivity(rng) if tr else 1, rng)
	offspring.water_required = _inherit_trait(parent_a.water_required, parent_b.water_required, tr.get_random_water_required(rng) if tr else false, rng)
	offspring.growth_speed = _inherit_trait(parent_a.growth_speed, parent_b.growth_speed, tr.get_random_growth_speed(rng) if tr else "medium", rng)
	
	offspring.taste_profile = _inherit_taste(parent_a.taste_profile, parent_b.taste_profile, tr, rng)
	
	return offspring

func _inherit_trait(a: Variant, b: Variant, mutation: Variant, rng: RandomNumberGenerator) -> Variant:
	var r = _randf(rng)
	if r < prob_parent_a:
		return a
	elif r < prob_parent_a + prob_parent_b:
		return b
	else:
		return mutation

func _inherit_taste(a: Array[String], b: Array[String], tr: Node, rng: RandomNumberGenerator) -> Array[String]:
	var combined: Array[String] = []
	for t in a:
		if _randf(rng) < prob_parent_a:
			if t not in combined:
				combined.append(t)
	for t in b:
		if _randf(rng) < prob_parent_b:
			if t not in combined:
				combined.append(t)
	
	if combined.is_empty():
		combined.append(tr.get_random_taste(rng) if tr else "sweet")
		
	return combined
