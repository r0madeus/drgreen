extends TestCase

## Unit tests for the Genetics Data Schema, Trait Registry, and Genetic Profile hashing.

var registry

func before_all() -> void:
	registry = preload("res://systems/genetics/trait_registry.gd").new()
	registry.load_traits_data()
	Engine.get_main_loop().root.add_child(registry)

func after_all() -> void:
	registry.queue_free()

func _test_T01_valid_genetic_profile() -> void:
	begin_test("T01_ValidGeneticProfile")
	var profile = GeneticProfile.new()
	profile.size = "large"
	profile.color = "red"
	profile.shape = "banana"
	profile.productivity = 3
	profile.taste_profile = Array(["sweet", "sour"], TYPE_STRING, &"", null)
	profile.water_required = true
	profile.growth_speed = "fast"
	
	assert_true(registry.is_valid_size(profile.size), "Size should be valid")
	assert_true(registry.is_valid_color(profile.color), "Color should be valid")
	assert_true(registry.is_valid_shape(profile.shape), "Shape should be valid")
	assert_true(registry.is_valid_productivity(profile.productivity), "Productivity should be valid")
	assert_true(registry.is_valid_growth_speed(profile.growth_speed), "Growth speed should be valid")
	
	for t in profile.taste_profile:
		assert_true(registry.is_valid_taste(t), "Taste %s should be valid" % t)
		

func _test_T02_invalid_traits() -> void:
	begin_test("T02_InvalidTraits")
	assert_false(registry.is_valid_size("huge"), "Invalid size should be rejected")
	assert_false(registry.is_valid_productivity(4), "Invalid productivity should be rejected")
	assert_false(registry.is_valid_growth_speed("instant"), "Invalid growth speed should be rejected")
	assert_false(registry.is_valid_taste("spicy"), "Invalid taste should be rejected")

func _test_T03_duplicate_taste_rejection() -> void:
	begin_test("T03_DuplicateTasteRejection")
	var dict = {
		"taste_profile": ["sweet", "sweet", "sour"]
	}
	var profile = GeneticProfile.from_dict(dict)
	assert_eq(profile.taste_profile.size(), 2, "Duplicates should be removed")
	assert_true(profile.taste_profile.has("sweet"), "Should have sweet")
	assert_true(profile.taste_profile.has("sour"), "Should have sour")

func _test_T04_taste_order_canonicalization() -> void:
	begin_test("T04_TasteOrderCanonicalization")
	var p1 = GeneticProfile.new()
	p1.taste_profile = Array(["sweet", "sour"], TYPE_STRING, &"", null)
	
	var p2 = GeneticProfile.new()
	p2.taste_profile = Array(["sour", "sweet"], TYPE_STRING, &"", null)
	
	assert_eq(p1.get_canonical_string(), p2.get_canonical_string(), "Taste order should not affect canonical string")

func _test_T05_identity_equality() -> void:
	begin_test("T05_IdentityEquality")
	var p1 = GeneticProfile.new()
	var p2 = GeneticProfile.new()
	
	assert_eq(p1.get_identity(), p2.get_identity(), "Same profiles should yield same identity")
	assert_true(p1.is_equal(p2), "Profiles should be equal")

func _test_T06_different_productivity_identity() -> void:
	begin_test("T06_DifferentProductivityIdentity")
	var p1 = GeneticProfile.new()
	p1.productivity = 1
	var p2 = GeneticProfile.new()
	p2.productivity = 2
	
	assert_ne(p1.get_identity(), p2.get_identity(), "Different productivity should yield different identity")
	assert_false(p1.is_equal(p2), "Profiles should not be equal")

func _test_T07_different_taste_identity() -> void:
	begin_test("T07_DifferentTasteIdentity")
	var p1 = GeneticProfile.new()
	p1.taste_profile = Array(["sweet"], TYPE_STRING, &"", null)
	var p2 = GeneticProfile.new()
	p2.taste_profile = Array(["sweet", "sour"], TYPE_STRING, &"", null)
	
	assert_ne(p1.get_identity(), p2.get_identity(), "Different tastes should yield different identity")
	assert_false(p1.is_equal(p2), "Profiles should not be equal")

func _test_T08_different_shape_identity() -> void:
	begin_test("T08_DifferentShapeIdentity")
	var p1 = GeneticProfile.new()
	p1.shape = "apple"
	var p2 = GeneticProfile.new()
	p2.shape = "banana"
	
	assert_ne(p1.get_identity(), p2.get_identity(), "Different shape should yield different identity")

func _test_T09_inventory_stacking() -> void:
	begin_test("T09_InventoryStacking")
	var ps = PlayerState.new("test_01", "Test")
	ps.inventory.clear()
	
	var p1 = GeneticProfile.new()
	p1.color = "red"
	p1.productivity = 2
	
	var p2 = GeneticProfile.new()
	p2.color = "red"
	p2.productivity = 2
	
	ps.add_item("seed_test", 1, p1)
	ps.add_item("seed_test", 2, p2) # Should stack
	
	assert_true(ps.has_item("seed_test", 3, p1), "Items with same genetic profile should stack")
	assert_eq(ps.get_item_count("seed_test", p1), 3, "Stack size should be 3")

func _test_T10_inventory_non_stacking() -> void:
	begin_test("T10_InventoryNonStacking")
	var ps = PlayerState.new("test_01", "Test")
	ps.inventory.clear()
	
	var p1 = GeneticProfile.new()
	p1.productivity = 1
	
	var p2 = GeneticProfile.new()
	p2.productivity = 2
	
	ps.add_item("seed_test", 1, p1)
	ps.add_item("seed_test", 2, p2) # Should NOT stack
	
	assert_eq(ps.get_item_count("seed_test", p1), 1, "Stack 1 should have 1 item")
	assert_eq(ps.get_item_count("seed_test", p2), 2, "Stack 2 should have 2 items")

func _test_T11_save_load_persistence() -> void:
	begin_test("T11_SaveLoadPersistence")
	var ps = PlayerState.new("test_01", "Test")
	ps.inventory.clear()
	
	var p1 = GeneticProfile.new()
	p1.size = "enormous"
	p1.taste_profile = Array(["sweet", "sour"], TYPE_STRING, &"", null)
	
	ps.add_item("seed_test", 5, p1)
	
	var dict = ps.to_dict()
	var ps2 = PlayerState.from_dict(dict)
	
	assert_true(ps2.has_item("seed_test", 5, p1), "Loaded state should have 5 items of the exact profile")
	
	var hash_key = PlayerState.get_genetic_hash(PlayerState.new().get_stack_key("seed_test", p1))
	assert_true(ps2.genetic_instances.has(hash_key), "Loaded state should have genetic instances dictionary populated")
	
	var loaded_profile_dict = ps2.genetic_instances[hash_key]
	var loaded_profile = GeneticProfile.from_dict(loaded_profile_dict)
	assert_eq(loaded_profile.size, "enormous", "Loaded profile should preserve size")
	assert_eq(loaded_profile.taste_profile.size(), 2, "Loaded profile should preserve taste profile")

func _test_T12_inventory_mixed_compatibility() -> void:
	begin_test("T12_InventoryMixedCompatibility")
	var ps = PlayerState.new("test_01", "Test")
	ps.inventory.clear()
	
	# Normal item
	ps.add_item("wood", 10)
	# Genetic item
	var p1 = GeneticProfile.new()
	ps.add_item("seed_test", 5, p1)
	
	assert_true(ps.has_item("wood", 10), "Normal item should exist")
	assert_true(ps.has_item("seed_test", 5, p1), "Genetic item should exist")

func _test_T13_base_item_id_helper() -> void:
	begin_test("T13_BaseItemIdHelper")
	var p1 = GeneticProfile.new()
	var key = PlayerState.new().get_stack_key("seed_test", p1)
	
	assert_eq(PlayerState.get_base_item_id(key), "seed_test", "Helper should extract base item id")
	assert_eq(PlayerState.get_base_item_id("wood"), "wood", "Helper should work on normal items")

func run_tests() -> void:
	before_all()
	_test_T01_valid_genetic_profile()
	_test_T02_invalid_traits()
	_test_T03_duplicate_taste_rejection()
	_test_T04_taste_order_canonicalization()
	_test_T05_identity_equality()
	_test_T06_different_productivity_identity()
	_test_T07_different_taste_identity()
	_test_T08_different_shape_identity()
	_test_T09_inventory_stacking()
	_test_T10_inventory_non_stacking()
	_test_T11_save_load_persistence()
	_test_T12_inventory_mixed_compatibility()
	_test_T13_base_item_id_helper()
	after_all()
