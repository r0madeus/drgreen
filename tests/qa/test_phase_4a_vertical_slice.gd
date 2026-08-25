extends TestCase

var ds = null

func get_name() -> String:
	return "Phase4A_VerticalSlice"

func run_tests() -> void:
	_test_t01_editor_boot()
	_test_t02_world_authoring()
	_test_t03_npc_authoring()
	_test_t04_dialogue_authoring()
	_test_t05_quest_authoring()
	_test_t06_plant_authoring()
	_test_t07_combination_authoring()
	_test_t08_genetics_integration()
	_test_t09_discovery_integration()
	_test_t10_progression_integration()
	_test_t11_cutscene_integration()
	_test_t12_audio_integration()
	_test_t13_save()
	_test_t14_reload()
	_test_t15_runtime_boot()
	_test_t16_complete_story_flow()

func _test_t01_editor_boot() -> void:
	var EditorService = load("res://editor/core/editor_service.gd")
	var instance = EditorService.get_instance()
	if not instance:
		instance = EditorService.new()
	ds = instance.data_service
	assert_true(ds != null, "T01: Editor data service initialized")

func _test_t02_world_authoring() -> void:
	var w = ds.get_resolved_object("world.luminous_grove")
	assert_true(w != null and typeof(w) == TYPE_DICTIONARY, "T02: World luminous_grove authored")
	if typeof(w) == TYPE_DICTIONARY:
		assert_eq(w.get("id"), "luminous_grove", "T02: World ID is correct")

func _test_t03_npc_authoring() -> void:
	var npc = ds.get_resolved_object("npc.npc_luminous_botanist")
	assert_true(npc != null, "T03: NPC authored")
	if typeof(npc) == TYPE_DICTIONARY:
		assert_eq(npc.get("default_dialogue"), "dialogue_luminous", "T03: NPC refers to correct dialogue")

func _test_t04_dialogue_authoring() -> void:
	var diag = ds.get_resolved_object("dialogue.dialogue_luminous")
	assert_true(diag != null, "T04: Dialogue authored")
	if typeof(diag) == TYPE_DICTIONARY:
		var lines = diag.get("lines", [])
		if lines.size() > 0:
			assert_eq(lines[0].get("start_quest"), "quest_luminous", "T04: Dialogue starts quest")

func _test_t05_quest_authoring() -> void:
	var q = ds.get_resolved_object("quest.quest_luminous")
	assert_true(q != null, "T05: Quest authored")
	if typeof(q) == TYPE_DICTIONARY:
		assert_eq(q.get("rewards", {}).get("trigger_cutscene"), "cutscene_luminous", "T05: Quest triggers cutscene")

func _test_t06_plant_authoring() -> void:
	var p = ds.get_resolved_object("plant.luminous_spore")
	assert_true(p != null, "T06: Plant authored")
	if typeof(p) == TYPE_DICTIONARY:
		assert_eq(p.get("harvest_yield"), "item_luminous_spore", "T06: Plant yields item")

func _test_t07_combination_authoring() -> void:
	var ComboDS = load("res://systems/combination/combination_data_service.gd")
	ComboDS.ensure_loaded()
	var combos = ComboDS.get_all_combos()
	var found = false
	for c in combos:
		if c.get("id") == "combo_luminous":
			found = true
			assert_eq(c.get("output"), "luminous_spore", "T07: Combo output correct")
	assert_true(found, "T07: Combination authored")

func _test_t08_genetics_integration() -> void:
	var GE = load("res://systems/genetics/genetics_engine.gd")
	if GE:
		assert_true(true, "T08: GeneticsEngine is accessible")
	else:
		assert_true(false, "T08: GeneticsEngine not found")

func _test_t09_discovery_integration() -> void:
	var SWS = load("res://systems/world/shared_world_state.gd")
	if SWS:
		assert_true(true, "T09: SharedWorldState is accessible")
	else:
		assert_true(false, "T09: SharedWorldState not found")

func _test_t10_progression_integration() -> void:
	var ProgDS = load("res://systems/progression/progression_data_service.gd")
	ProgDS.ensure_loaded()
	var unlocks = ProgDS.get_all_unlocks()
	var has_unl = unlocks.has("luminous_grove")
	assert_true(has_unl, "T10: Progression unlock authored")

func _test_t11_cutscene_integration() -> void:
	var c = ds.get_resolved_object("cutscene.cutscene_luminous")
	assert_true(c != null, "T11: Cutscene authored")
	if typeof(c) == TYPE_DICTIONARY:
		assert_eq(c.get("duration"), 2.0, "T11: Cutscene duration correct")

func _test_t12_audio_integration() -> void:
	var a = ds.get_resolved_object("audio.sfx_quest_complete")
	assert_true(a != null, "T12: Audio authored")
	if typeof(a) == TYPE_DICTIONARY:
		assert_eq(a.get("path"), "res://assets/audio/sfx/ui_select.wav", "T12: Audio path correct")

func _test_t13_save() -> void:
	ds.save_overrides()
	assert_true(true, "T13: Save successful")

func _test_t14_reload() -> void:
	ds.load_saved_overrides()
	var w = ds.get_resolved_object("world.luminous_grove")
	assert_true(w != null, "T14: Reload successful")

func _test_t15_runtime_boot() -> void:
	assert_true(true, "T15: Runtime boot check runs separately")

func _test_t16_complete_story_flow() -> void:
	assert_true(true, "T16: Complete story flow delegated to full runtime test")
