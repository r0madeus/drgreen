class_name GeneticsEditorPanel
extends EditorPanel

const TRAITS_DATA_PATH = "res://data/genetics/traits.json"
const CONFIG_PATH = "res://data/genetics/config.json"
const PLANTS_DATA_PATH = "res://data/plants/base_plants.json"

var main_tabs: TabContainer

# Data Cache
var traits_data: Dictionary = {}
var config_data: Dictionary = {}
var plants_data: Array = []

var current_plant_index: int = -1

# UI Elements
var plant_list: ItemList
var plant_form: VBoxContainer

var _ui_built = false

func _init() -> void:
	name = "GeneticsEditorPanel"
	set_anchors_preset(PRESET_FULL_RECT)

func open_panel() -> void:
	_load_all_data()
	if not _ui_built:
		_build_ui()
		_ui_built = true
	_refresh_ui()

func _load_all_data() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		var f = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			config_data = json.data
			if not config_data.has("inheritance"):
				config_data["inheritance"] = {"prob_parent_a": 0.7, "prob_parent_b": 0.2, "prob_mutation": 0.1}

	if FileAccess.file_exists(TRAITS_DATA_PATH):
		var f = FileAccess.open(TRAITS_DATA_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			traits_data = json.data.get("traits", {})

	if FileAccess.file_exists(PLANTS_DATA_PATH):
		var f = FileAccess.open(PLANTS_DATA_PATH, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			plants_data = json.data.get("plants", [])

func save() -> bool:
	var cf = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	cf.store_string(JSON.stringify(config_data, "\t"))
	cf.close()
	
	var tf = FileAccess.open(TRAITS_DATA_PATH, FileAccess.WRITE)
	tf.store_string(JSON.stringify({"traits": traits_data}, "\t"))
	tf.close()
	
	var pf = FileAccess.open(PLANTS_DATA_PATH, FileAccess.WRITE)
	pf.store_string(JSON.stringify({"plants": plants_data}, "\t"))
	pf.close()
	
	print("[GeneticsEditor] Saved config, traits, and plants.")
	panel_saved.emit()
	return true

func _build_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(PRESET_FULL_RECT)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	var toolbar = HBoxContainer.new()
	var save_btn = Button.new()
	save_btn.text = "[Save] Save Genetics & Plants"
	save_btn.pressed.connect(func(): save())
	toolbar.add_child(save_btn)
	vbox.add_child(toolbar)

	main_tabs = TabContainer.new()
	main_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(main_tabs)

	_build_config_tab()
	_build_traits_tab()
	_build_plants_tab()

func _refresh_ui() -> void:
	_populate_plant_list()

func _build_config_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Genetics Engine"
	main_tabs.add_child(scroll)

	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "Inheritance Probabilities"
	vbox.add_child(title)

	var pa_box = HBoxContainer.new()
	var pa_lbl = Label.new()
	pa_lbl.text = "Parent A (e.g. 0.7): "
	var pa_spin = SpinBox.new()
	pa_spin.min_value = 0.0
	pa_spin.max_value = 1.0
	pa_spin.step = 0.01
	pa_spin.value = config_data.get("inheritance", {}).get("prob_parent_a", 0.7)
	pa_spin.value_changed.connect(func(v): config_data["inheritance"]["prob_parent_a"] = v; _validate_probs(vbox))
	pa_box.add_child(pa_lbl)
	pa_box.add_child(pa_spin)
	vbox.add_child(pa_box)

	var pb_box = HBoxContainer.new()
	var pb_lbl = Label.new()
	pb_lbl.text = "Parent B (e.g. 0.2): "
	var pb_spin = SpinBox.new()
	pb_spin.min_value = 0.0
	pb_spin.max_value = 1.0
	pb_spin.step = 0.01
	pb_spin.value = config_data.get("inheritance", {}).get("prob_parent_b", 0.2)
	pb_spin.value_changed.connect(func(v): config_data["inheritance"]["prob_parent_b"] = v; _validate_probs(vbox))
	pb_box.add_child(pb_lbl)
	pb_box.add_child(pb_spin)
	vbox.add_child(pb_box)

	var pm_box = HBoxContainer.new()
	var pm_lbl = Label.new()
	pm_lbl.text = "Mutation (e.g. 0.1): "
	var pm_spin = SpinBox.new()
	pm_spin.min_value = 0.0
	pm_spin.max_value = 1.0
	pm_spin.step = 0.01
	pm_spin.value = config_data.get("inheritance", {}).get("prob_mutation", 0.1)
	pm_spin.value_changed.connect(func(v): config_data["inheritance"]["prob_mutation"] = v; _validate_probs(vbox))
	pm_box.add_child(pm_lbl)
	pm_box.add_child(pm_spin)
	vbox.add_child(pm_box)

	var error_lbl = Label.new()
	error_lbl.name = "ErrorLabel"
	error_lbl.modulate = Color.RED
	vbox.add_child(error_lbl)
	_validate_probs(vbox)

func _validate_probs(vbox: Node) -> void:
	var pa = config_data.get("inheritance", {}).get("prob_parent_a", 0.7)
	var pb = config_data.get("inheritance", {}).get("prob_parent_b", 0.2)
	var pm = config_data.get("inheritance", {}).get("prob_mutation", 0.1)
	var err = vbox.get_node_or_null("ErrorLabel")
	if err:
		if abs(pa + pb + pm - 1.0) > 0.01:
			err.text = "Error: Probabilities must sum to 1.0!"
		else:
			err.text = ""

func _build_traits_tab() -> void:
	var scroll = ScrollContainer.new()
	scroll.name = "Trait Registry"
	main_tabs.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)

	for key in traits_data.keys():
		var hbox = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = key + ": "
		lbl.custom_minimum_size = Vector2(150, 0)
		hbox.add_child(lbl)
		
		var line = LineEdit.new()
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Readonly representation for arrays and objects (simplification for phase 3B)
		line.text = JSON.stringify(traits_data[key])
		line.text_submitted.connect(func(t): _on_trait_edited(key, t))
		hbox.add_child(line)
		
		vbox.add_child(hbox)

func _on_trait_edited(key: String, text: String) -> void:
	var json = JSON.new()
	if json.parse(text) == OK:
		traits_data[key] = json.data
		print("Updated trait:", key)

func _build_plants_tab() -> void:
	var hsplit = HSplitContainer.new()
	hsplit.name = "Plant Authoring"
	main_tabs.add_child(hsplit)

	plant_list = ItemList.new()
	plant_list.custom_minimum_size = Vector2(200, 0)
	plant_list.item_selected.connect(_on_plant_selected)
	hsplit.add_child(plant_list)

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hsplit.add_child(scroll)

	plant_form = VBoxContainer.new()
	plant_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(plant_form)

func _populate_plant_list() -> void:
	plant_list.clear()
	for i in range(plants_data.size()):
		var p = plants_data[i]
		plant_list.add_item(p.get("name", "Unknown") + " (" + p.get("id", "") + ")")

func _on_plant_selected(index: int) -> void:
	current_plant_index = index
	_refresh_plant_form()

func _refresh_plant_form() -> void:
	for child in plant_form.get_children():
		child.queue_free()

	if current_plant_index < 0 or current_plant_index >= plants_data.size():
		return

	var plant = plants_data[current_plant_index]

	_add_form_string(plant, "id", "Plant ID")
	_add_form_string(plant, "name", "Name")
	_add_form_string(plant, "type", "Type")
	_add_form_string(plant, "rarity", "Rarity")
	_add_form_string(plant, "size", "Size")
	_add_form_string(plant, "shape", "Shape")
	
	var prod = plant.get("productivity", 1)
	_add_form_spin(plant, "productivity", "Productivity Level (1-3)", prod, 1, 3)
	
	_add_form_string(plant, "growth_speed", "Growth Speed")
	
	var wr = plant.get("water_required", false)
	_add_form_check(plant, "water_required", "Requires Water?", wr)
	
	var taste = plant.get("taste_profile", [])
	_add_form_array(plant, "taste_profile", "Taste Profile", taste)
	
	_add_form_dict(plant, "visual", "Visual Data")
	_add_form_dict(plant, "growth", "Growth Data")
	_add_form_dict(plant, "harvest", "Harvest Data")

func _add_form_string(plant: Dictionary, key: String, label: String) -> void:
	var box = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(150, 0)
	var edit = LineEdit.new()
	edit.text = plant.get(key, "")
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func(t): plant[key] = t)
	box.add_child(lbl)
	box.add_child(edit)
	plant_form.add_child(box)

func _add_form_spin(plant: Dictionary, key: String, label: String, val: int, min_val: int, max_val: int) -> void:
	var box = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(150, 0)
	var edit = SpinBox.new()
	edit.min_value = min_val
	edit.max_value = max_val
	edit.value = val
	edit.value_changed.connect(func(v): plant[key] = int(v))
	box.add_child(lbl)
	box.add_child(edit)
	plant_form.add_child(box)

func _add_form_check(plant: Dictionary, key: String, label: String, val: bool) -> void:
	var box = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(150, 0)
	var edit = CheckBox.new()
	edit.button_pressed = val
	edit.toggled.connect(func(v): plant[key] = v)
	box.add_child(lbl)
	box.add_child(edit)
	plant_form.add_child(box)

func _add_form_array(plant: Dictionary, key: String, label: String, val: Array) -> void:
	var box = HBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.custom_minimum_size = Vector2(150, 0)
	var edit = LineEdit.new()
	edit.text = ",".join(val)
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(func(t):
		var arr = []
		for s in t.split(","): arr.append(s.strip_edges())
		plant[key] = arr
	)
	box.add_child(lbl)
	box.add_child(edit)
	plant_form.add_child(box)

func _add_form_dict(plant: Dictionary, key: String, label: String) -> void:
	var box = VBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label
	lbl.modulate = Color.YELLOW
	box.add_child(lbl)
	var edit = TextEdit.new()
	edit.text = JSON.stringify(plant.get(key, {}), "\t")
	edit.custom_minimum_size = Vector2(0, 100)
	edit.text_changed.connect(func():
		var json = JSON.new()
		if json.parse(edit.text) == OK:
			plant[key] = json.data
	)
	box.add_child(edit)
	plant_form.add_child(box)
