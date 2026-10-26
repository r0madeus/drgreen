extends TestCase

func get_name() -> String:
	return "GeneticsEngine"

func run_tests() -> void:
	_test_E01_deterministic_breeding()
	_test_E02_statistical_distribution()
	_test_E03_taste_normalization()
	_test_E04_parent_immutability()
	_test_E05_save_load_integration()

func _test_E01_deterministic_breeding() -> void:
	begin_test("E01_DeterministicBreeding")
	var p1 = GeneticProfile.new()
	p1.size = "small"
	p1.color = "red"
	
	var p2 = GeneticProfile.new()
	p2.size = "large"
	p2.color = "blue"
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	var engine = GeneticsEngine.new()
	var offspring1 = engine.breed(p1, p2, rng)
	
	rng.seed = 12345
	var offspring2 = engine.breed(p1, p2, rng)
	
	assert_eq(offspring1.get_canonical_string(), offspring2.get_canonical_string(), "Identical seed should yield identical offspring")

func _test_E02_statistical_distribution() -> void:
	begin_test("E02_StatisticalDistribution")
	var root = Engine.get_main_loop().root if Engine.get_main_loop() else null
	var tr = root.get_node_or_null("TraitRegistry") if root else null
	if tr and root:
		root.remove_child(tr)
	seed(42)
	var p1 = GeneticProfile.new()
	p1.size = "small"
	var p2 = GeneticProfile.new()
	p2.size = "large"
	
	var engine = GeneticsEngine.new()
	var count_a = 0
	var count_b = 0
	var count_mut = 0
	
	for i in range(10000):
		var off = engine.breed(p1, p2)
		if off.size == "small": count_a += 1
		elif off.size == "large": count_b += 1
		else: count_mut += 1
	
	var ratio_a = float(count_a) / 10000.0
	var ratio_b = float(count_b) / 10000.0
	var ratio_m = float(count_mut) / 10000.0
	
	if tr and root:
		root.add_child(tr)
	
	# Verify within 5% tolerance
	assert_true(abs(ratio_a - 0.70) < 0.05, "Parent A ratio approx 70%")
	assert_true(abs(ratio_b - 0.20) < 0.05, "Parent B ratio approx 20%")
	assert_true(abs(ratio_m - 0.10) < 0.05, "Mutation ratio approx 10%")

func _test_E03_taste_normalization() -> void:
	begin_test("E03_TasteNormalization")
	var p1 = GeneticProfile.new()
	p1.taste_profile = Array(["sweet"], TYPE_STRING, &"", null)
	var p2 = GeneticProfile.new()
	p2.taste_profile = Array(["sweet"], TYPE_STRING, &"", null)
	
	var engine = GeneticsEngine.new()
	var off = engine.breed(p1, p2)
	
	var count_sweet = 0
	for t in off.taste_profile:
		if t == "sweet": count_sweet += 1
		
	assert_eq(count_sweet, 1, "Duplicate tastes must be inherently prevented during engine mixing")

func _test_E04_parent_immutability() -> void:
	begin_test("E04_ParentImmutability")
	var p1 = GeneticProfile.new()
	p1.size = "small"
	var p2 = GeneticProfile.new()
	p2.size = "large"
	
	var engine = GeneticsEngine.new()
	engine.breed(p1, p2)
	
	assert_eq(p1.size, "small", "Parent A should not be mutated")
	assert_eq(p2.size, "large", "Parent B should not be mutated")

func _test_E05_save_load_integration() -> void:
	begin_test("E05_SaveLoadIntegration")
	var p1 = GeneticProfile.new()
	var engine = GeneticsEngine.new()
	var offspring = engine.breed(p1, p1)
	
	var ps = PlayerState.new("p1", "Test")
	ps.add_item("seed_red_flower", 1, offspring)
	
	var data = ps.to_dict()
	var ps2 = PlayerState.from_dict(data)
	
	var key = PlayerState.new().get_stack_key("seed_red_flower", offspring)
	assert_true(ps2.has_item("seed_red_flower", 1, offspring), "Offspring must survive save/load")
	
	var hash_part = PlayerState.get_genetic_hash(key)
	assert_true(ps2.genetic_instances.has(hash_part), "Genetic instance dictionary must retain offspring")
