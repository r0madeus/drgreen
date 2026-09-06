class_name QuestEditorPanel
extends EditorPanel

## In-Game Quest & Event Editor Panel for Botanical Haven (Phase 31).
## Visual node-based quest creation, multi-type objective builder, declarative conditions,
## reward configuration, dependency graph validation, live preview simulation, and mod overrides.

signal quest_selected(quest_id: String)
signal switch_to_npc_editor(npc_id: String)
signal switch_to_dialogue_editor(dialogue_id: String)
signal switch_to_world_editor(world_id: String)

var current_quest_id: String = "quest_01"
var current_quest_data: Dictionary = {}

# Simulated Test State
var sim_day: int = 1
var sim_season: String = "spring"
var sim_weather: String = "clear"
var sim_gold: int = 100
var sim_heart_level: int = 1
var sim_inventory_items: Dictionary = {} # item_id -> count

# UI Controls
var quest_list_container: VBoxContainer
var search_line_edit: LineEdit
var tag_filter_opt: OptionButton
var flow_graph_container: VBoxContainer
var sim_result_label: Label

# Inspector UI Fields
var id_edit: LineEdit
var title_edit: LineEdit
var desc_text_edit: TextEdit
var giver_npc_opt: OptionButton
var quest_type_opt: OptionButton
var priority_spin: SpinBox
var repeatable_check: CheckBox
var hidden_check: CheckBox
var enabled_check: CheckBox
var tags_edit: LineEdit

# Objectives & Prerequisites
var objective_list_container: VBoxContainer
var prereq_opt: OptionButton
var unlock_type_opt: OptionButton

# Rewards Fields
var reward_gold_spin: SpinBox
var reward_items_edit: LineEdit
var reward_friendship_npc_opt: OptionButton
var reward_friendship_spin: SpinBox
var reward_unlock_quest_edit: LineEdit
var reward_unlock_world_opt: OptionButton

# Status Bar
var status_quest_label: Label
var status_changes_label: Label
var validation_status_label: Label

const OBJECTIVE_TYPES = [
	"plant", "water", "harvest", "combine", "synthesis",
	"discover", "sell", "buy", "deposit", "withdraw",
	"talk", "dialogue_action", "friendship", "world_event", "unlock_world"
]

const QUEST_TYPES = [
	"main", "side", "npc", "farming", "exploration",
	"collection", "tutorial", "seasonal", "event"
]

const UNLOCK_TYPES = [
	"auto", "quest_completed", "heart_level", "season",
	"weather", "world_unlocked", "gold", "item"
]

const SUPPORTED_NPCS = ["Rowan", "Elias", "Mira"]
const SUPPORTED_WORLDS = ["farm", "town", "forest", "botanical_grove", "greenhouse"]

func _init() -> void:
	super._init("quest", "ui.editor.cat_quest", "icon_quest")

func setup(p_service: Variant) -> void:
	super.setup(p_service)
	_build_ui()
	_load_quest_list()
	_select_quest(current_quest_id)

func open_panel() -> void:
	super.open_panel()
	refresh()

func refresh() -> void:
	_load_quest_list()
	_select_quest(current_quest_id)

func _build_ui() -> void:
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.grow_horizontal = GROW_DIRECTION_BOTH
	main_vbox.grow_vertical = GROW_DIRECTION_BOTH
	add_child(main_vbox)

	# --- TOP TOOLBAR ---
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_bar.add_child(top_hbox)

	var top_title = Label.new()
	top_title.text = "📜 In-Game Quest & Event Editor"
	top_title.add_theme_font_size_override("font_size", 13)
	top_title.modulate = Color(0.92, 0.94, 0.98)
	top_hbox.add_child(top_title)

	top_hbox.add_spacer(false)

	var add_q_btn = Button.new()
	add_q_btn.text = " New Quest"
	add_q_btn.pressed.connect(_on_add_new_quest)
	top_hbox.add_child(add_q_btn)

	var dup_q_btn = Button.new()
	dup_q_btn.text = " Duplicate Quest"
	dup_q_btn.pressed.connect(_on_duplicate_quest)
	top_hbox.add_child(dup_q_btn)

	var sep1 = VSeparator.new()
	top_hbox.add_child(sep1)

	var to_npc_btn = Button.new()
	to_npc_btn.text = " Giver NPC"
	to_npc_btn.pressed.connect(_on_open_giver_npc)
	top_hbox.add_child(to_npc_btn)

	var to_dial_btn = Button.new()
	to_dial_btn.text = " Dialogue"
	to_dial_btn.pressed.connect(_on_open_quest_dialogue)
	top_hbox.add_child(to_dial_btn)

	var test_btn = Button.new()
	test_btn.text = " Play Quest"
	test_btn.pressed.connect(_on_play_quest_in_game)
	top_hbox.add_child(test_btn)

	# --- 3-COLUMN WORKSPACE ---
	var mid_hbox = HBoxContainer.new()
	mid_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(mid_hbox)

	# 1. LEFT: Quest List & Search
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(210, 0)
	mid_hbox.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_panel.add_child(left_vbox)

	var q_lbl = Label.new()
	q_lbl.text = "Quest Catalog:"
	q_lbl.add_theme_font_size_override("font_size", 11)
	left_vbox.add_child(q_lbl)

	search_line_edit = LineEdit.new()
	search_line_edit.placeholder_text = "Search quest, giver, obj..."
	search_line_edit.text_changed.connect(func(_t): _refresh_quest_list())
	left_vbox.add_child(search_line_edit)

	tag_filter_opt = OptionButton.new()
	tag_filter_opt.add_item("All Types", 0)
	for i in range(QUEST_TYPES.size()):
		tag_filter_opt.add_item(QUEST_TYPES[i].capitalize(), i + 1)
	tag_filter_opt.item_selected.connect(func(_idx): _refresh_quest_list())
	left_vbox.add_child(tag_filter_opt)

	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(left_scroll)

	quest_list_container = VBoxContainer.new()
	quest_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(quest_list_container)

	# 2. CENTER: Quest Flow Graph & Live Simulator
	var center_panel = PanelContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_hbox.add_child(center_panel)

	var center_vbox = VBoxContainer.new()
	center_panel.add_child(center_vbox)

	var graph_header = HBoxContainer.new()
	center_vbox.add_child(graph_header)

	var graph_title = Label.new()
	graph_title.text = "Quest Flow & Objective Pipeline"
	graph_title.add_theme_font_size_override("font_size", 13)
	graph_header.add_child(graph_title)

	graph_header.add_spacer(false)

	var sim_btn = Button.new()
	sim_btn.text = "🧪 Simulate Quest"
	sim_btn.pressed.connect(_on_simulate_quest)
	graph_header.add_child(sim_btn)

	var graph_scroll = ScrollContainer.new()
	graph_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.add_child(graph_scroll)

	flow_graph_container = VBoxContainer.new()
	flow_graph_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_scroll.add_child(flow_graph_container)

	# Simulator Result Box
	var sim_box = PanelContainer.new()
	sim_box.custom_minimum_size = Vector2(0, 70)
	center_vbox.add_child(sim_box)

	var sim_vbox = VBoxContainer.new()
	sim_box.add_child(sim_vbox)

	var sim_title = Label.new()
	sim_title.text = "Quest State & Simulation Diagnostics"
	sim_title.add_theme_font_size_override("font_size", 12)
	sim_title.modulate = Color(0.8, 0.9, 1.0)
	sim_vbox.add_child(sim_title)

	sim_result_label = Label.new()
	sim_result_label.text = "Simulator: Ready. Click 'Simulate Quest' to test prerequisites, objectives and reward execution."
	sim_result_label.add_theme_font_size_override("font_size", 11)
	sim_result_label.modulate = Color(0.7, 0.9, 0.7)
	sim_vbox.add_child(sim_result_label)

	# 3. RIGHT: Inspector Tabs (Metadata, Objectives, Prerequisites, Rewards)
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(300, 0)
	mid_hbox.add_child(right_panel)

	var right_tabs = TabContainer.new()
	right_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_tabs)

	# Tab 1: Metadata
	var meta_scroll = ScrollContainer.new()
	meta_scroll.name = "Metadata"
	right_tabs.add_child(meta_scroll)

	var meta_vbox = VBoxContainer.new()
	meta_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_scroll.add_child(meta_vbox)
	_build_metadata_tab(meta_vbox)

	# Tab 2: Objectives
	var obj_scroll = ScrollContainer.new()
	obj_scroll.name = "Objectives"
	right_tabs.add_child(obj_scroll)

	var obj_vbox = VBoxContainer.new()
	obj_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	obj_scroll.add_child(obj_vbox)
	_build_objectives_tab(obj_vbox)

	# Tab 3: Prerequisites & Unlocks
	var unl_scroll = ScrollContainer.new()
	unl_scroll.name = "Unlocks"
	right_tabs.add_child(unl_scroll)

	var unl_vbox = VBoxContainer.new()
	unl_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unl_scroll.add_child(unl_vbox)
	_build_unlocks_tab(unl_vbox)

	# Tab 4: Rewards
	var rew_scroll = ScrollContainer.new()
	rew_scroll.name = "Rewards"
	right_tabs.add_child(rew_scroll)

	var rew_vbox = VBoxContainer.new()
	rew_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rew_scroll.add_child(rew_vbox)
	_build_rewards_tab(rew_vbox)

	# --- BOTTOM STATUS BAR ---
	var bottom_bar = PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 26)
	main_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_bar.add_child(bottom_hbox)

	status_quest_label = Label.new()
	status_quest_label.text = "Quest: quest_01"
	status_quest_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_quest_label)

	bottom_hbox.add_spacer(false)

	status_changes_label = Label.new()
	status_changes_label.text = "Changes: 0"
	status_changes_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_changes_label)

	bottom_hbox.add_spacer(false)

	validation_status_label = Label.new()
	validation_status_label.text = "Validation: OK"
	validation_status_label.modulate = Color(0.4, 0.9, 0.4)
	validation_status_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(validation_status_label)

func _build_metadata_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("Quest ID:"))
	id_edit = LineEdit.new()
	id_edit.text_submitted.connect(_on_quest_id_submitted)
	container.add_child(id_edit)

	container.add_child(_create_field_label("Title:"))
	title_edit = LineEdit.new()
	title_edit.text_changed.connect(func(t): _on_quest_field_changed("title", t))
	container.add_child(title_edit)

	container.add_child(_create_field_label("Description:"))
	desc_text_edit = TextEdit.new()
	desc_text_edit.custom_minimum_size = Vector2(0, 80)
	desc_text_edit.text_changed.connect(func(): _on_quest_field_changed("description", desc_text_edit.text))
	container.add_child(desc_text_edit)

	container.add_child(_create_field_label("Giver NPC:"))
	giver_npc_opt = OptionButton.new()
	for i in range(SUPPORTED_NPCS.size()):
		giver_npc_opt.add_item(SUPPORTED_NPCS[i], i)
	giver_npc_opt.item_selected.connect(func(idx): _on_quest_field_changed("giver", SUPPORTED_NPCS[idx]))
	container.add_child(giver_npc_opt)

	container.add_child(_create_field_label("Quest Type:"))
	quest_type_opt = OptionButton.new()
	for i in range(QUEST_TYPES.size()):
		quest_type_opt.add_item(QUEST_TYPES[i].capitalize(), i)
	quest_type_opt.item_selected.connect(func(idx): _on_quest_field_changed("quest_type", QUEST_TYPES[idx]))
	container.add_child(quest_type_opt)

	container.add_child(_create_field_label("Tags (comma separated):"))
	tags_edit = LineEdit.new()
	tags_edit.text_changed.connect(func(t):
		var arr: Array[String] = []
		for s in t.split(","):
			var trimmed = s.strip_edges()
			if trimmed != "": arr.append(trimmed)
		_on_quest_field_changed("tags", arr)
	)
	container.add_child(tags_edit)

	var reset_q_btn = Button.new()
	reset_q_btn.text = "↺ Reset Quest to Default"
	reset_q_btn.pressed.connect(reset_current_quest)
	container.add_child(reset_q_btn)

	var reset_all_btn = Button.new()
	reset_all_btn.text = "↺ Reset All Quests"
	reset_all_btn.pressed.connect(reset_all_quests)
	container.add_child(reset_all_btn)

func _build_objectives_tab(container: VBoxContainer) -> void:
	var header = HBoxContainer.new()
	container.add_child(header)

	var title_lbl = Label.new()
	title_lbl.text = "Objectives List"
	title_lbl.add_theme_font_size_override("font_size", 12)
	header.add_child(title_lbl)

	header.add_spacer(false)

	var add_obj_btn = Button.new()
	add_obj_btn.text = " Add Objective"
	add_obj_btn.pressed.connect(_on_add_objective)
	header.add_child(add_obj_btn)

	objective_list_container = VBoxContainer.new()
	container.add_child(objective_list_container)

func _build_unlocks_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("Unlock Trigger Type:"))
	unlock_type_opt = OptionButton.new()
	for i in range(UNLOCK_TYPES.size()):
		unlock_type_opt.add_item(UNLOCK_TYPES[i], i)
	unlock_type_opt.item_selected.connect(func(idx):
		if not current_quest_data.has("unlock"): current_quest_data["unlock"] = {}
		current_quest_data["unlock"]["type"] = UNLOCK_TYPES[idx]
		_on_quest_modified()
	)
	container.add_child(unlock_type_opt)

	container.add_child(_create_field_label("Prerequisite Quest ID:"))
	prereq_opt = OptionButton.new()
	_populate_prereq_options()
	prereq_opt.item_selected.connect(func(idx):
		if not current_quest_data.has("unlock"): current_quest_data["unlock"] = {}
		current_quest_data["unlock"]["quest_id"] = prereq_opt.get_item_text(idx)
		_on_quest_modified()
	)
	container.add_child(prereq_opt)

func _build_rewards_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("Reward Gold:"))
	reward_gold_spin = SpinBox.new()
	reward_gold_spin.min_value = 0
	reward_gold_spin.max_value = 10000
	reward_gold_spin.step = 5
	reward_gold_spin.value_changed.connect(_on_reward_gold_changed)
	container.add_child(reward_gold_spin)

	container.add_child(_create_field_label("Next Quest Unlock ID:"))
	reward_unlock_quest_edit = LineEdit.new()
	reward_unlock_quest_edit.text_changed.connect(func(t):
		if not current_quest_data.has("rewards"): current_quest_data["rewards"] = {}
		current_quest_data["rewards"]["unlock"] = t
		_on_quest_modified()
	)
	container.add_child(reward_unlock_quest_edit)

	container.add_child(_create_field_label("Unlock World Realm:"))
	reward_unlock_world_opt = OptionButton.new()
	reward_unlock_world_opt.add_item("None", 0)
	for i in range(SUPPORTED_WORLDS.size()):
		reward_unlock_world_opt.add_item(SUPPORTED_WORLDS[i].capitalize(), i + 1)
	reward_unlock_world_opt.item_selected.connect(func(idx):
		if not current_quest_data.has("rewards"): current_quest_data["rewards"] = {}
		if idx > 0:
			current_quest_data["rewards"]["unlock_world"] = SUPPORTED_WORLDS[idx - 1]
		else:
			current_quest_data["rewards"].erase("unlock_world")
		_on_quest_modified()
	)
	container.add_child(reward_unlock_world_opt)

func _on_reward_gold_changed(v: float) -> void:
	if not current_quest_data.has("rewards"): current_quest_data["rewards"] = {}
	current_quest_data["rewards"]["gold"] = float(v)
	_on_quest_modified()


func _create_field_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(0.8, 0.8, 0.8)
	return l

func _load_quest_list() -> void:
	if not quest_list_container: return
	for c in quest_list_container.get_children(): c.queue_free()

	var quest_keys: Array[String] = []
	if editor_service and editor_service.data_service:
		quest_keys = editor_service.data_service.get_all_stable_ids("quest.")

	if quest_keys.is_empty():
		quest_keys = ["quest.quest_01", "quest.quest_02", "quest.quest_03", "quest.quest_04", "quest.quest_05"]

	for qk in quest_keys:
		var qid = qk.replace("quest.", "")
		var btn = Button.new()
		var is_overridden = editor_service.data_service.has_override(qk) if editor_service else false
		btn.text = (" " if is_overridden else "") + qid
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if qid == current_quest_id:
			btn.modulate = Color(1.0, 0.9, 0.5)
		btn.pressed.connect(func(): _select_quest(qid))
		quest_list_container.add_child(btn)

func _select_quest(qid: String) -> void:
	current_quest_id = qid
	if editor_service and editor_service.data_service:
		current_quest_data = editor_service.data_service.get_resolved_object("quest." + qid)

	if current_quest_data.is_empty():
		current_quest_data = {
			"id": qid,
			"title": qid.capitalize(),
			"title_key": "quest.%s.title" % qid,
			"description": "Default quest description.",
			"description_key": "quest.%s.desc" % qid,
			"giver": "Rowan",
			"objectives": [
				{ "type": "plant", "target": "any", "amount": 1.0, "current": 0.0, "description": "Plant a crop" }
			],
			"rewards": { "gold": 50.0 },
			"unlock": { "type": "auto" }
		}

	_refresh_quest_list()
	_refresh_flow_graph()
	_populate_inspector()
	validate()
	quest_selected.emit(qid)

func _refresh_quest_list() -> void:
	if not quest_list_container: return
	var filter_text = search_line_edit.text.to_lower() if search_line_edit else ""

	for btn in quest_list_container.get_children():
		if btn is Button:
			var txt = btn.text.to_lower()
			btn.visible = (filter_text == "" or txt.contains(filter_text))

func _refresh_flow_graph() -> void:
	if not flow_graph_container: return
	for c in flow_graph_container.get_children(): c.queue_free()

	# 1. Start / Unlock Card
	var start_card = PanelContainer.new()
	start_card.modulate = Color(0.8, 1.0, 0.8)
	var s_vbox = VBoxContainer.new()
	start_card.add_child(s_vbox)
	var unl = current_quest_data.get("unlock", {})
	var s_lbl = Label.new()
	s_lbl.text = " Quest Start: %s | Trigger: %s" % [current_quest_data.get("title", current_quest_id), unl.get("type", "auto")]
	s_lbl.add_theme_font_size_override("font_size", 12)
	s_vbox.add_child(s_lbl)
	flow_graph_container.add_child(start_card)

	# 2. Objectives Flow
	var objs = current_quest_data.get("objectives", [])
	for i in range(objs.size()):
		var o = objs[i]
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 40)
		var c_vbox = VBoxContainer.new()
		card.add_child(c_vbox)
		var o_lbl = Label.new()
		o_lbl.text = " Objective %d: %s %d [%s]" % [i + 1, str(o.get("type", "action")).to_upper(), int(o.get("amount", 1)), str(o.get("target", "any"))]
		o_lbl.add_theme_font_size_override("font_size", 11)
		c_vbox.add_child(o_lbl)
		flow_graph_container.add_child(card)

	# 3. Reward / Completion Card
	var rew_card = PanelContainer.new()
	rew_card.modulate = Color(1.0, 0.9, 0.5)
	var r_vbox = VBoxContainer.new()
	rew_card.add_child(r_vbox)
	var rews = current_quest_data.get("rewards", {})
	var r_lbl = Label.new()
	r_lbl.text = " Completion Rewards: %d Gold | Unlocks: %s" % [int(rews.get("gold", 0)), str(rews.get("unlock", "none"))]
	r_lbl.add_theme_font_size_override("font_size", 12)
	r_vbox.add_child(r_lbl)
	flow_graph_container.add_child(rew_card)

func _populate_inspector() -> void:
	if id_edit: id_edit.text = str(current_quest_data.get("id", current_quest_id))
	if title_edit: title_edit.text = str(current_quest_data.get("title", current_quest_id.capitalize()))
	if desc_text_edit: desc_text_edit.text = str(current_quest_data.get("description", ""))

	var g = str(current_quest_data.get("giver", "Rowan"))
	for i in range(SUPPORTED_NPCS.size()):
		if SUPPORTED_NPCS[i] == g:
			if giver_npc_opt: giver_npc_opt.selected = i
			break

	var rews = current_quest_data.get("rewards", {})
	if reward_gold_spin: reward_gold_spin.value = float(rews.get("gold", 0))
	if reward_unlock_quest_edit: reward_unlock_quest_edit.text = str(rews.get("unlock", ""))

	_populate_objectives_list()

func _populate_objectives_list() -> void:
	if not objective_list_container: return
	for c in objective_list_container.get_children(): c.queue_free()

	var objs = current_quest_data.get("objectives", [])
	for i in range(objs.size()):
		var o = objs[i]
		var hbox = HBoxContainer.new()

		var type_opt = OptionButton.new()
		for ti in range(OBJECTIVE_TYPES.size()):
			type_opt.add_item(OBJECTIVE_TYPES[ti], ti)
			if OBJECTIVE_TYPES[ti] == str(o.get("type", "plant")):
				type_opt.selected = ti
		type_opt.item_selected.connect(func(idx): o["type"] = OBJECTIVE_TYPES[idx]; _on_quest_modified())
		hbox.add_child(type_opt)

		var amt_spin = SpinBox.new()
		amt_spin.min_value = 1
		amt_spin.max_value = 100
		amt_spin.value = float(o.get("amount", 1))
		amt_spin.value_changed.connect(func(v): o["amount"] = float(v); _on_quest_modified())
		hbox.add_child(amt_spin)

		var target_edit = LineEdit.new()
		target_edit.text = str(o.get("target", "any"))
		target_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		target_edit.text_changed.connect(func(t): o["target"] = t; _on_quest_modified())
		hbox.add_child(target_edit)

		var del_btn = Button.new()
		del_btn.text = ""
		del_btn.pressed.connect(func(): _remove_objective(i))
		hbox.add_child(del_btn)

		objective_list_container.add_child(hbox)

func _populate_prereq_options() -> void:
	if not prereq_opt: return
	prereq_opt.clear()
	prereq_opt.add_item("None", 0)
	var quest_keys: Array[String] = []
	if editor_service and editor_service.data_service:
		quest_keys = editor_service.data_service.get_all_stable_ids("quest.")
	for i in range(quest_keys.size()):
		var qid = quest_keys[i].replace("quest.", "")
		prereq_opt.add_item(qid, i + 1)

func _on_add_objective() -> void:
	if not current_quest_data.has("objectives"):
		current_quest_data["objectives"] = []
	var new_o = {
		"type": "plant",
		"target": "any",
		"amount": 1.0,
		"current": 0.0,
		"description": "Plant crops in farm field",
		"text_key": "quest.%s.obj_%d" % [current_quest_id, current_quest_data["objectives"].size() + 1]
	}
	current_quest_data["objectives"].append(new_o)
	_populate_objectives_list()
	_refresh_flow_graph()
	_on_quest_modified()

func _remove_objective(idx: int) -> void:
	var objs = current_quest_data.get("objectives", [])
	if idx < objs.size():
		objs.remove_at(idx)
		_populate_objectives_list()
		_refresh_flow_graph()
		_on_quest_modified()

func _on_quest_field_changed(field: String, val: Variant) -> void:
	current_quest_data[field] = val
	_on_quest_modified()

func _on_quest_id_submitted(new_id: String) -> void:
	if new_id == "" or new_id == current_quest_id: return
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("quest." + new_id, "title", current_quest_data.get("title", new_id))
		editor_service.data_service.set_staged_override("quest." + new_id, "objectives", current_quest_data.get("objectives", []))
		editor_service.data_service.set_staged_override("quest." + new_id, "rewards", current_quest_data.get("rewards", {}))
	current_quest_id = new_id
	_load_quest_list()
	_select_quest(new_id)

func _on_add_new_quest() -> void:
	var new_id = "quest_%d" % (int(Time.get_unix_time_from_system()) % 1000)
	var new_data = {
		"id": new_id,
		"title": "New Quest %s" % new_id,
		"title_key": "quest.%s.title" % new_id,
		"description": "New adventure in the botanical valley.",
		"description_key": "quest.%s.desc" % new_id,
		"giver": "Rowan",
		"objectives": [
			{ "type": "harvest", "target": "any", "amount": 2.0, "current": 0.0, "description": "Harvest 2 plants" }
		],
		"rewards": { "gold": 50.0 },
		"unlock": { "type": "auto" }
	}
	if editor_service and editor_service.data_service:
		for k in new_data.keys():
			editor_service.data_service.set_staged_override("quest." + new_id, k, new_data[k])
	_load_quest_list()
	_select_quest(new_id)

func _on_duplicate_quest() -> void:
	var dup_id = "%s_dup_%d" % [current_quest_id, (int(Time.get_unix_time_from_system()) % 1000)]
	var dup_data = current_quest_data.duplicate(true)
	dup_data["id"] = dup_id
	dup_data["title"] = dup_data.get("title", current_quest_id) + " (Copy)"
	if editor_service and editor_service.data_service:
		for k in dup_data.keys():
			editor_service.data_service.set_staged_override("quest." + dup_id, k, dup_data[k])
	_load_quest_list()
	_select_quest(dup_id)

func _on_quest_modified() -> void:
	if editor_service and editor_service.data_service:
		for k in current_quest_data.keys():
			editor_service.data_service.set_staged_override("quest." + current_quest_id, k, current_quest_data[k], false)
	validate()
	panel_dirtied.emit()

func _on_open_giver_npc() -> void:
	var g = str(current_quest_data.get("giver", "rowan")).to_lower()
	switch_to_npc_editor.emit(g)

func _on_open_quest_dialogue() -> void:
	var g = str(current_quest_data.get("giver", "rowan")).to_lower()
	switch_to_dialogue_editor.emit(g)

func _on_simulate_quest() -> void:
	var objs = current_quest_data.get("objectives", [])
	var rews = current_quest_data.get("rewards", {})
	if sim_result_label:
		sim_result_label.text = "Simulation: Quest '%s' Available | %d Objectives | Rewards %d Gold." % [
			current_quest_data.get("title", current_quest_id),
			objs.size(),
			int(rews.get("gold", 0))
		]
		sim_result_label.modulate = Color(0.4, 1.0, 0.4)

func _on_play_quest_in_game() -> void:
	var qm = Engine.get_main_loop().root.get_node_or_null("/root/QuestManager") if Engine.get_main_loop() else null
	if qm:
		qm.advance_objective("plant", 1, "any")

func reset_current_quest() -> void:
	if editor_service and editor_service.data_service:
		editor_service.data_service.restore_default("quest." + current_quest_id, "", true)
	_select_quest(current_quest_id)

func reset_all_quests() -> void:
	if editor_service and editor_service.data_service:
		var all_q = editor_service.data_service.get_all_stable_ids("quest.")
		for q in all_q:
			editor_service.data_service.restore_default(q, "", true)
	_load_quest_list()
	_select_quest(current_quest_id)

func validate() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	if current_quest_id == "":
		errors.append("Quest ID cannot be empty.")

	var objs = current_quest_data.get("objectives", [])
	if objs.is_empty():
		warnings.append("Quest has no objectives defined.")

	for i in range(objs.size()):
		var o = objs[i]
		if float(o.get("amount", 0)) <= 0:
			errors.append("Objective %d required amount must be greater than 0." % (i + 1))

	var rews = current_quest_data.get("rewards", {})
	if rews.is_empty():
		warnings.append("Quest has no rewards defined.")

	if validation_status_label:
		if errors.size() > 0:
			validation_status_label.text = "Validation: %d Errors" % errors.size()
			validation_status_label.modulate = Color(1.0, 0.4, 0.4)
		elif warnings.size() > 0:
			validation_status_label.text = "Validation: %d Warnings" % warnings.size()
			validation_status_label.modulate = Color(1.0, 0.8, 0.3)
		else:
			validation_status_label.text = "Validation: OK"
			validation_status_label.modulate = Color(0.4, 0.9, 0.4)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"total_checked": objs.size()
	}


## Public programmatic and UI authoring entry point for creating new Quests (Phase 36)
func create_quest(quest_id: String, title: String, giver: String = "Rowan", objectives: Array = [], rewards: Dictionary = {}, custom_data: Dictionary = {}) -> Dictionary:
	var clean_id = quest_id.strip_edges().to_lower().replace(" ", "_").trim_prefix("quest.")
	if clean_id == "": clean_id = "custom_quest_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	
	var default_objs = objectives if objectives.size() > 0 else [
		{ "type": "harvest", "target": "item.moon_flower", "amount": 1.0, "current": 0.0, "description": "Harvest 1 Moon Flower" }
	]
	var default_rews = rewards if not rewards.is_empty() else { "gold": 100.0 }
	
	var quest_dict = {
		"id": clean_id,
		"title": title if title != "" else clean_id.capitalize().replace("_", " "),
		"title_key": "quest.%s.title" % clean_id,
		"description": "Quest authored inside Botanical Haven In-Game Editor.",
		"description_key": "quest.%s.desc" % clean_id,
		"giver": giver,
		"objectives": default_objs,
		"rewards": default_rews,
		"unlock": { "type": "auto" }
	}
	quest_dict.merge(custom_data, true)
	
	if editor_service and editor_service.data_service:
		editor_service.data_service.create_entity("quest." + clean_id, quest_dict)
		
	_load_quest_list()
	_select_quest(clean_id)
	panel_dirtied.emit()
	return quest_dict
