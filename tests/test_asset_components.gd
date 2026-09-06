extends RefCounted

func assert_eq(a: Variant, b: Variant, msg: String = "") -> void:
	assert(a == b, msg)

func before_all():
	if not ClassDB.class_exists("AssetDefinitionManager"):
		push_error("AssetDefinitionManager missing!")
		
	# Create a dummy definition
	AssetDefinitionManager.definitions["test_tree"] = {
		"identity": { "display_name": "Test Tree", "type": "environment" },
		"components": {
			"visual": { "texture": "tree.png" },
			"collision": { "solid": true },
			"lighting": { "enabled": true, "radius": 128 }
		}
	}
	AssetDefinitionManager._initialized = true

func test_inheritance():
	var overrides = {}
	var resolved = AssetDefinitionManager.resolve_instance_properties("test_tree", overrides)
	
	assert_eq(resolved.get("display_name"), "Test Tree")
	assert_eq(resolved.get("solid"), true)
	assert_eq(resolved.get("emits_light"), true)
	assert_eq(resolved.get("light_radius"), 128)

func test_instance_override():
	var overrides = {
		"solid": false,
		"light_radius": 256
	}
	var resolved = AssetDefinitionManager.resolve_instance_properties("test_tree", overrides)
	
	assert_eq(resolved.get("solid"), false, "Override should disable solid")
	assert_eq(resolved.get("light_radius"), 256, "Override should change radius")
	assert_eq(resolved.get("emits_light"), true, "Base properties should remain intact")

func test_undefined_asset():
	var overrides = { "custom_val": 42 }
	var resolved = AssetDefinitionManager.resolve_instance_properties("does_not_exist", overrides)
	
	assert_eq(resolved.get("custom_val"), 42, "Should return overrides cleanly if no def exists")
