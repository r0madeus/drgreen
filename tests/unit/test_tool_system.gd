class_name TestToolSystem
extends TestCase

## Unit tests for the Tool System — type, quality, power, stamina cost, range, upgrade chain.
## Fully isolated: exercises ToolUseManager and ItemRegistry static APIs only.

func test_name_id() -> String:
	return "UNIT.ToolSystem"

func run_all() -> void:
	test_name = test_name_id()
	_test_is_tool_item()
	_test_not_tool_item()
	_test_tool_def_hoe()
	_test_tool_def_watering_can()
	_test_tool_def_axe()
	_test_tool_def_pickaxe()
	_test_tool_upgrade_chain()
	_test_max_upgrade()
	_test_tool_power_increases_with_quality()
	_test_tool_stamina_cost()
	_test_tool_range()

func _test_is_tool_item() -> void:
	begin_test("is_tool_item_hoe")
	assert_true(ToolUseManager.is_tool_item("hoe_basic"), "hoe_basic is a tool")
	assert_true(ToolUseManager.is_tool_item("watering_can_basic"), "watering_can_basic is a tool")
	assert_true(ToolUseManager.is_tool_item("axe_basic"), "axe_basic is a tool")
	assert_true(ToolUseManager.is_tool_item("pickaxe_basic"), "pickaxe_basic is a tool")

func _test_not_tool_item() -> void:
	begin_test("not_tool_item")
	assert_false(ToolUseManager.is_tool_item("seed_red_flower"), "seed is not a tool")
	assert_false(ToolUseManager.is_tool_item("red_flower"), "crop is not a tool")
	assert_false(ToolUseManager.is_tool_item("wood"), "wood is not a tool")
	assert_false(ToolUseManager.is_tool_item(""), "empty string is not a tool")

func _test_tool_def_hoe() -> void:
	begin_test("tool_def_hoe")
	var def = ToolUseManager.get_tool_def("hoe_basic")
	assert_eq(def.get("type", ""), "hoe", "hoe type")
	assert_eq(def.get("quality", ""), "basic", "hoe basic quality")
	assert_gt(def.get("power", 0), 0, "hoe power > 0")
	assert_gt(def.get("energy_cost", 0.0), 0.0, "hoe energy_cost > 0")
	assert_gt(def.get("range", 0), 0, "hoe range > 0")

func _test_tool_def_watering_can() -> void:
	begin_test("tool_def_watering_can")
	var def = ToolUseManager.get_tool_def("watering_can_basic")
	assert_eq(def.get("type", ""), "watering_can", "watering_can type")

func _test_tool_def_axe() -> void:
	begin_test("tool_def_axe")
	var def = ToolUseManager.get_tool_def("axe_basic")
	assert_eq(def.get("type", ""), "axe", "axe type")

func _test_tool_def_pickaxe() -> void:
	begin_test("tool_def_pickaxe")
	var def = ToolUseManager.get_tool_def("pickaxe_basic")
	assert_eq(def.get("type", ""), "pickaxe", "pickaxe type")

func _test_tool_upgrade_chain() -> void:
	begin_test("upgrade_chain_hoe")
	var basic_next = ToolUseManager.get_upgraded_tool_id("hoe_basic")
	assert_eq(basic_next, "hoe_copper", "basic -> copper")
	var copper_next = ToolUseManager.get_upgraded_tool_id("hoe_copper")
	assert_eq(copper_next, "hoe_iron", "copper -> iron")
	var iron_next = ToolUseManager.get_upgraded_tool_id("hoe_iron")
	assert_eq(iron_next, "hoe_gold", "iron -> gold")

func _test_max_upgrade() -> void:
	begin_test("max_upgrade")
	var gold_next = ToolUseManager.get_upgraded_tool_id("hoe_gold")
	assert_eq(gold_next, "hoe_gold", "gold stays gold (max)")

func _test_tool_power_increases_with_quality() -> void:
	begin_test("power_increases_with_quality")
	var basic_def = ToolUseManager.get_tool_def("axe_basic")
	var gold_def = ToolUseManager.get_tool_def("axe_gold")
	assert_gt(int(gold_def.get("power", 0)), int(basic_def.get("power", 0)), "gold power > basic power")

func _test_tool_stamina_cost() -> void:
	begin_test("stamina_cost")
	var def = ToolUseManager.get_tool_def("hoe_basic")
	var cost = float(def.get("energy_cost", 0.0))
	assert_gt(cost, 0.0, "stamina cost > 0")
	assert_lt(cost, 100.0, "stamina cost < 100 (sane value)")

func _test_tool_range() -> void:
	begin_test("tool_range")
	var def = ToolUseManager.get_tool_def("hoe_basic")
	var r = int(def.get("range", 0))
	assert_gt(r, 0, "range > 0")
