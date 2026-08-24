class_name DialogueEditorPanel
extends EditorPanel

## In-Game Dialogue Editor Panel for Botanical Haven (Phase 30).
## Visual node-based dialogue creation, data-driven declarative condition builder,
## player branching choices, action execution, live interactive preview simulator,
## validation, and non-destructive mod override support.

signal dialogue_selected(npc_id: String, node_key: String)
signal switch_to_npc_editor(npc_id: String)
signal switch_to_world_editor(world_id: String)

var current_npc_id: String = "rowan"
var current_dialogue_data: Dictionary = {}
var current_node_key: String = "default"

# Simulated Condition Test State
var sim_weather: String = "clear"
var sim_season: String = "spring"
var sim_heart_level: int = 1
var sim_active_quest: String = ""
var sim_completed_quest: String = ""

# UI Controls
var npc_option: OptionButton
var dialogue_list_container: VBoxContainer
var search_line_edit: LineEdit
var tag_filter_opt: OptionButton
var node_graph_container: VBoxContainer
var preview_box: PanelContainer
var preview_portrait: TextureRect
var preview_speaker_label: Label
var preview_line_label: Label
var preview_choices_container: VBoxContainer
var sim_result_label: Label

# Node Inspector UI Fields
var node_key_edit: LineEdit
var priority_spin: SpinBox
var action_opt: OptionButton
var lines_text_edit: TextEdit
var emotion_opt: OptionButton
var condition_list_container: VBoxContainer
var choice_list_container: VBoxContainer

# Status Bar
var status_npc_label: Label
var status_changes_label: Label
var validation_status_label: Label

const CONDITION_TYPES = [
	"heart_level", "friendship", "weather", "season",
	"quest_active", "quest_completed", "world_unlocked",
	"plants_discovered", "dialogue_seen"
]

const ACTION_TYPES = [
	"none", "open_shop", "trigger_quest", "add_friendship",
	"give_item", "add_gold", "start_quest", "complete_quest", "set_flag"
]

const EMOTIONS = ["neutral", "happy", "sad", "thinking", "excited"]

func _init() -> void:
	super._init("dialogue", "ui.editor.cat_dialogue", "icon_dialogue")

func setup(p_service: Variant) -> void:
	super.setup(p_service)
	_build_ui()
	_load_npc_list()
	_load_dialogue_data(current_npc_id)

func open_panel() -> void:
	super.open_panel()
	refresh()

func refresh() -> void:
	_load_npc_list()
	_load_dialogue_data(current_npc_id)

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
	top_title.text = " In-Game Dialogue Editor"
	top_title.add_theme_font_size_override("font_size", 13)
	top_title.modulate = Color(0.9, 0.85, 0.4)
	top_hbox.add_child(top_title)

	top_hbox.add_spacer(false)

	var add_node_btn = Button.new()
	add_node_btn.text = " New Dialogue Node"
	add_node_btn.pressed.connect(_on_add_new_node)
	top_hbox.add_child(add_node_btn)

	var dup_node_btn = Button.new()
	dup_node_btn.text = " Duplicate Node"
	dup_node_btn.pressed.connect(_on_duplicate_node)
	top_hbox.add_child(dup_node_btn)

	var sep1 = VSeparator.new()
	top_hbox.add_child(sep1)

	var to_npc_btn = Button.new()
	to_npc_btn.text = " Open NPC Editor"
	to_npc_btn.pressed.connect(func(): switch_to_npc_editor.emit(current_npc_id))
	top_hbox.add_child(to_npc_btn)

	var test_btn = Button.new()
	test_btn.text = " Play Dialogue"
	test_btn.modulate = Color(0.5, 1.0, 0.6)
	test_btn.pressed.connect(_on_play_dialogue_in_game)
	top_hbox.add_child(test_btn)

	# --- 3-COLUMN WORKSPACE ---
	var mid_hbox = HBoxContainer.new()
	mid_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(mid_hbox)

	# 1. LEFT: NPC & Dialogue Tree List
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(200, 0)
	mid_hbox.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_panel.add_child(left_vbox)

	var npc_lbl = Label.new()
	npc_lbl.text = "Target NPC:"
	npc_lbl.add_theme_font_size_override("font_size", 11)
	left_vbox.add_child(npc_lbl)

	npc_option = OptionButton.new()
	npc_option.item_selected.connect(_on_npc_selected)
	left_vbox.add_child(npc_option)

	var search_lbl = Label.new()
	search_lbl.text = "Search / Filter:"
	search_lbl.add_theme_font_size_override("font_size", 11)
	left_vbox.add_child(search_lbl)

	search_line_edit = LineEdit.new()
	search_line_edit.placeholder_text = "Search text, key, tag..."
	search_line_edit.text_changed.connect(func(_t): _refresh_dialogue_list())
	left_vbox.add_child(search_line_edit)

	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(left_scroll)

	dialogue_list_container = VBoxContainer.new()
	dialogue_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(dialogue_list_container)

	# 2. CENTER: Visual Dialogue Graph / Flow & Simulator
	var center_panel = PanelContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_hbox.add_child(center_panel)

	var center_vbox = VBoxContainer.new()
	center_panel.add_child(center_vbox)

	var graph_header_hbox = HBoxContainer.new()
	center_vbox.add_child(graph_header_hbox)

	var graph_title = Label.new()
	graph_title.text = "Visual Dialogue Flow"
	graph_title.add_theme_font_size_override("font_size", 13)
	graph_header_hbox.add_child(graph_title)

	graph_header_hbox.add_spacer(false)

	var prev_btn = Button.new()
	prev_btn.text = " Interactive Preview"
	prev_btn.pressed.connect(_on_run_interactive_preview)
	graph_header_hbox.add_child(prev_btn)

	var sim_btn = Button.new()
	sim_btn.text = "🧪 Simulate Evaluation"
	sim_btn.pressed.connect(_on_simulate_evaluation)
	graph_header_hbox.add_child(sim_btn)

	# Graph Nodes Scroll View
	var graph_scroll = ScrollContainer.new()
	graph_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.add_child(graph_scroll)

	node_graph_container = VBoxContainer.new()
	node_graph_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_scroll.add_child(node_graph_container)

	# Bottom Simulation / Live Preview Box
	preview_box = PanelContainer.new()
	preview_box.custom_minimum_size = Vector2(0, 110)
	center_vbox.add_child(preview_box)

	var prev_hbox = HBoxContainer.new()
	preview_box.add_child(prev_hbox)

	preview_portrait = TextureRect.new()
	preview_portrait.custom_minimum_size = Vector2(70, 70)
	preview_portrait.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	prev_hbox.add_child(preview_portrait)

	var prev_vbox = VBoxContainer.new()
	prev_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prev_hbox.add_child(prev_vbox)

	preview_speaker_label = Label.new()
	preview_speaker_label.text = "Rowan"
	preview_speaker_label.add_theme_font_size_override("font_size", 13)
	preview_speaker_label.modulate = Color(0.8, 1.0, 0.8)
	prev_vbox.add_child(preview_speaker_label)

	preview_line_label = Label.new()
	preview_line_label.text = "Select a dialogue node to preview lines and test condition branches."
	preview_line_label.add_theme_font_size_override("font_size", 11)
	preview_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prev_vbox.add_child(preview_line_label)

	preview_choices_container = VBoxContainer.new()
	prev_vbox.add_child(preview_choices_container)

	sim_result_label = Label.new()
	sim_result_label.text = "Simulator: Ready"
	sim_result_label.add_theme_font_size_override("font_size", 10)
	sim_result_label.modulate = Color(0.9, 0.9, 0.5)
	prev_vbox.add_child(sim_result_label)

	# 3. RIGHT: Node Inspector Tabs
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(300, 0)
	mid_hbox.add_child(right_panel)

	var right_tabs = TabContainer.new()
	right_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_tabs)

	# Tab 1: Node & Lines
	var node_scroll = ScrollContainer.new()
	node_scroll.name = "Node & Lines"
	right_tabs.add_child(node_scroll)

	var node_vbox = VBoxContainer.new()
	node_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node_scroll.add_child(node_vbox)
	_build_node_tab(node_vbox)

	# Tab 2: Conditions
	var cond_scroll = ScrollContainer.new()
	cond_scroll.name = "Conditions"
	right_tabs.add_child(cond_scroll)

	var cond_vbox = VBoxContainer.new()
	cond_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cond_scroll.add_child(cond_vbox)
	_build_conditions_tab(cond_vbox)

	# Tab 3: Choices & Actions
	var act_scroll = ScrollContainer.new()
	act_scroll.name = "Choices & Actions"
	right_tabs.add_child(act_scroll)

	var act_vbox = VBoxContainer.new()
	act_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_scroll.add_child(act_vbox)
	_build_choices_and_actions_tab(act_vbox)

	# --- BOTTOM STATUS BAR ---
	var bottom_bar = PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 26)
	main_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_bar.add_child(bottom_hbox)

	status_npc_label = Label.new()
	status_npc_label.text = "NPC: Rowan"
	status_npc_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_npc_label)

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

func _build_node_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("Node Key / ID:"))
	node_key_edit = LineEdit.new()
	node_key_edit.text_submitted.connect(_on_node_key_submitted)
	container.add_child(node_key_edit)

	container.add_child(_create_field_label("Priority (0 = lowest, 100 = urgent):"))
	priority_spin = SpinBox.new()
	priority_spin.min_value = 0
	priority_spin.max_value = 100
	priority_spin.value_changed.connect(func(v): _on_node_prop_changed("priority", int(v)))
	container.add_child(priority_spin)

	container.add_child(_create_field_label("Emotion / Expression:"))
	emotion_opt = OptionButton.new()
	for i in range(EMOTIONS.size()):
		emotion_opt.add_item(EMOTIONS[i].capitalize(), i)
	emotion_opt.item_selected.connect(func(idx): _on_node_prop_changed("emotion", EMOTIONS[idx]))
	container.add_child(emotion_opt)

	container.add_child(_create_field_label("Dialogue Lines (One per line):"))
	lines_text_edit = TextEdit.new()
	lines_text_edit.custom_minimum_size = Vector2(0, 100)
	lines_text_edit.text_changed.connect(_on_lines_text_changed)
	container.add_child(lines_text_edit)

	container.add_child(_create_field_label("Node Action (On Dialogue End):"))
	action_opt = OptionButton.new()
	for i in range(ACTION_TYPES.size()):
		action_opt.add_item(ACTION_TYPES[i], i)
	action_opt.item_selected.connect(func(idx): _on_node_prop_changed("action", ACTION_TYPES[idx]))
	container.add_child(action_opt)

	var reset_node_btn = Button.new()
	reset_node_btn.text = "↺ Reset Node to Default"
	reset_node_btn.pressed.connect(reset_current_node)
	container.add_child(reset_node_btn)

	var reset_all_btn = Button.new()
	reset_all_btn.text = "↺ Reset All NPC Dialogues"
	reset_all_btn.pressed.connect(reset_all_npc_dialogues)
	container.add_child(reset_all_btn)

func _build_conditions_tab(container: VBoxContainer) -> void:
	var cond_header = HBoxContainer.new()
	container.add_child(cond_header)

	var cond_title = Label.new()
	cond_title.text = "Entry Conditions"
	cond_title.add_theme_font_size_override("font_size", 12)
	cond_header.add_child(cond_title)

	cond_header.add_spacer(false)

	var add_cond_btn = Button.new()
	add_cond_btn.text = " Add Condition"
	add_cond_btn.pressed.connect(_on_add_condition)
	cond_header.add_child(add_cond_btn)

	condition_list_container = VBoxContainer.new()
	container.add_child(condition_list_container)

func _build_choices_and_actions_tab(container: VBoxContainer) -> void:
	var choice_header = HBoxContainer.new()
	container.add_child(choice_header)

	var choice_title = Label.new()
	choice_title.text = "Player Choices & Branching"
	choice_title.add_theme_font_size_override("font_size", 12)
	choice_header.add_child(choice_title)

	choice_header.add_spacer(false)

	var add_choice_btn = Button.new()
	add_choice_btn.text = " Add Choice"
	add_choice_btn.pressed.connect(_on_add_choice)
	choice_header.add_child(add_choice_btn)

	choice_list_container = VBoxContainer.new()
	container.add_child(choice_list_container)

func _create_field_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(0.8, 0.8, 0.8)
	return l

func _load_npc_list() -> void:
	if not npc_option: return
	npc_option.clear()

	var npcs: Array[String] = ["rowan", "elias", "mira"]
	if editor_service and editor_service.data_service:
		var keys = editor_service.data_service.get_all_stable_ids("dialogue.")
		for k in keys:
			var n = k.replace("dialogue.", "")
			if not npcs.has(n): npcs.append(n)

	for i in range(npcs.size()):
		npc_option.add_item(npcs[i].capitalize(), i)
		npc_option.set_item_metadata(i, npcs[i])
		if npcs[i] == current_npc_id:
			npc_option.selected = i

func _on_npc_selected(idx: int) -> void:
	var nid = str(npc_option.get_item_metadata(idx))
	if nid != "":
		_load_dialogue_data(nid)

func _load_dialogue_data(npc_id: String) -> void:
	current_npc_id = npc_id
	if editor_service and editor_service.data_service:
		current_dialogue_data = editor_service.data_service.get_resolved_object("dialogue." + npc_id)

	if current_dialogue_data.is_empty():
		current_dialogue_data = {
			"npc_id": npc_id,
			"nodes": {
				"default": {
					"priority": 0,
					"action": "open_shop",
					"lines": ["Hello! How can I help you today?"],
					"lines_keys": ["dialogue." + npc_id + ".default_1"]
				}
			}
		}

	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has(current_node_key):
		var keys = nodes.keys()
		current_node_key = keys[0] if keys.size() > 0 else "default"

	_refresh_dialogue_list()
	_refresh_node_graph()
	_populate_node_inspector()
	_update_preview_display()
	validate()
	dialogue_selected.emit(current_npc_id, current_node_key)

func _refresh_dialogue_list() -> void:
	if not dialogue_list_container: return
	for c in dialogue_list_container.get_children(): c.queue_free()

	var nodes = current_dialogue_data.get("nodes", {})
	var filter_text = search_line_edit.text.to_lower() if search_line_edit else ""

	for k in nodes.keys():
		var node = nodes[k]
		var lines = node.get("lines", [])
		var line_str = " ".join(lines).to_lower()
		if filter_text != "" and not k.to_lower().contains(filter_text) and not line_str.contains(filter_text):
			continue

		var btn = Button.new()
		var is_sel = (k == current_node_key)
		var prio = int(node.get("priority", 0))
		btn.text = "%s [%d] %s" % [(" " if is_sel else " "), prio, k]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_sel:
			btn.modulate = Color(1.0, 0.9, 0.5)
		btn.pressed.connect(func(): _select_node(k))
		dialogue_list_container.add_child(btn)

func _refresh_node_graph() -> void:
	if not node_graph_container: return
	for c in node_graph_container.get_children(): c.queue_free()

	var nodes = current_dialogue_data.get("nodes", {})
	for k in nodes.keys():
		var node = nodes[k]
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 50)
		if k == current_node_key:
			card.modulate = Color(1.0, 0.95, 0.7)

		var card_vbox = VBoxContainer.new()
		card.add_child(card_vbox)

		var card_top = HBoxContainer.new()
		card_vbox.add_child(card_top)

		var node_lbl = Label.new()
		node_lbl.text = " Node: %s (Priority %d)" % [k, int(node.get("priority", 0))]
		node_lbl.add_theme_font_size_override("font_size", 12)
		card_top.add_child(node_lbl)

		card_top.add_spacer(false)

		var edit_btn = Button.new()
		edit_btn.text = "Inspect"
		edit_btn.pressed.connect(func(): _select_node(k))
		card_top.add_child(edit_btn)

		var preview_lbl = Label.new()
		var lines = node.get("lines", [])
		preview_lbl.text = lines[0] if lines.size() > 0 else "..."
		preview_lbl.add_theme_font_size_override("font_size", 11)
		preview_lbl.modulate = Color(0.7, 0.8, 0.7)
		card_vbox.add_child(preview_lbl)

		node_graph_container.add_child(card)

func _select_node(k: String) -> void:
	current_node_key = k
	_refresh_dialogue_list()
	_refresh_node_graph()
	_populate_node_inspector()
	_update_preview_display()
	dialogue_selected.emit(current_npc_id, current_node_key)

func _populate_node_inspector() -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	var node = nodes.get(current_node_key, {})

	if node_key_edit: node_key_edit.text = current_node_key
	if priority_spin: priority_spin.value = int(node.get("priority", 0))

	var raw_lines = node.get("lines", [])
	if lines_text_edit:
		lines_text_edit.text = "\n".join(raw_lines)

	var act = str(node.get("action", "none"))
	if action_opt:
		for i in range(ACTION_TYPES.size()):
			if ACTION_TYPES[i] == act:
				action_opt.selected = i
				break

	_populate_conditions_list(node.get("conditions", []))
	_populate_choices_list(node.get("choices", []))

func _populate_conditions_list(conditions: Array) -> void:
	if not condition_list_container: return
	for c in condition_list_container.get_children(): c.queue_free()

	if conditions.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No conditions (Always active)."
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		condition_list_container.add_child(empty_lbl)
		return

	for i in range(conditions.size()):
		var cond = conditions[i]
		var hbox = HBoxContainer.new()

		var type_lbl = Label.new()
		type_lbl.text = "• %s: %s" % [cond.get("type", "condition"), str(cond)]
		type_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		type_lbl.add_theme_font_size_override("font_size", 11)
		hbox.add_child(type_lbl)

		var del_btn = Button.new()
		del_btn.text = ""
		del_btn.pressed.connect(func(): _remove_condition(i))
		hbox.add_child(del_btn)

		condition_list_container.add_child(hbox)

func _populate_choices_list(choices: Array) -> void:
	if not choice_list_container: return
	for c in choice_list_container.get_children(): c.queue_free()

	if choices.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No branching choices (Linear advance)."
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		choice_list_container.add_child(empty_lbl)
		return

	for i in range(choices.size()):
		var choice = choices[i]
		var hbox = HBoxContainer.new()

		var text_edit = LineEdit.new()
		text_edit.text = str(choice.get("text", "Option"))
		text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_edit.text_changed.connect(func(t): choice["text"] = t; _on_dialogue_modified())
		hbox.add_child(text_edit)

		var target_edit = LineEdit.new()
		target_edit.text = str(choice.get("target_node", "default"))
		target_edit.custom_minimum_size = Vector2(80, 0)
		target_edit.text_changed.connect(func(t): choice["target_node"] = t; _on_dialogue_modified())
		hbox.add_child(target_edit)

		var del_btn = Button.new()
		del_btn.text = ""
		del_btn.pressed.connect(func(): _remove_choice(i))
		hbox.add_child(del_btn)

		choice_list_container.add_child(hbox)

func _on_lines_text_changed() -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has(current_node_key): return
	var lines_arr: Array[String] = []
	for l in lines_text_edit.text.split("\n"):
		lines_arr.append(l)
	nodes[current_node_key]["lines"] = lines_arr

	var keys: Array[String] = []
	for i in range(lines_arr.size()):
		keys.append("dialogue.%s.%s_%d" % [current_npc_id, current_node_key, i + 1])
	nodes[current_node_key]["lines_keys"] = keys

	_on_dialogue_modified()
	_update_preview_display()

func _on_node_prop_changed(prop: String, val: Variant) -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has(current_node_key): return
	nodes[current_node_key][prop] = val
	_on_dialogue_modified()

func _on_node_key_submitted(new_key: String) -> void:
	if new_key == "" or new_key == current_node_key: return
	var nodes = current_dialogue_data.get("nodes", {})
	if nodes.has(current_node_key):
		var data = nodes[current_node_key]
		nodes.erase(current_node_key)
		nodes[new_key] = data
		current_node_key = new_key
		_on_dialogue_modified()
		_refresh_dialogue_list()
		_refresh_node_graph()

func _on_add_condition() -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has(current_node_key): return
	if not nodes[current_node_key].has("conditions"):
		nodes[current_node_key]["conditions"] = []
	var new_c = { "type": "heart_level", "min": 2 }
	nodes[current_node_key]["conditions"].append(new_c)
	_populate_conditions_list(nodes[current_node_key]["conditions"])
	_on_dialogue_modified()

func _remove_condition(idx: int) -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has(current_node_key): return
	var conds = nodes[current_node_key].get("conditions", [])
	if idx < conds.size():
		conds.remove_at(idx)
		_populate_conditions_list(conds)
		_on_dialogue_modified()

func _on_add_choice() -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has(current_node_key): return
	if not nodes[current_node_key].has("choices"):
		nodes[current_node_key]["choices"] = []
	var new_ch = {
		"text": "I will help with that.",
		"text_key": "dialogue.%s.choice_%d" % [current_npc_id, nodes[current_node_key]["choices"].size() + 1],
		"target_node": "default"
	}
	nodes[current_node_key]["choices"].append(new_ch)
	_populate_choices_list(nodes[current_node_key]["choices"])
	_on_dialogue_modified()

func _remove_choice(idx: int) -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has(current_node_key): return
	var chs = nodes[current_node_key].get("choices", [])
	if idx < chs.size():
		chs.remove_at(idx)
		_populate_choices_list(chs)
		_on_dialogue_modified()

func _on_add_new_node() -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	var new_k = "dialogue_branch_%d" % (int(Time.get_unix_time_from_system()) % 1000)
	nodes[new_k] = {
		"priority": 10,
		"action": "none",
		"lines": ["New custom dialogue node."],
		"lines_keys": ["dialogue.%s.%s_1" % [current_npc_id, new_k]]
	}
	current_node_key = new_k
	_on_dialogue_modified()
	_refresh_dialogue_list()
	_refresh_node_graph()
	_populate_node_inspector()
	_update_preview_display()

func _on_duplicate_node() -> void:
	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has(current_node_key): return
	var dup_k = "%s_copy_%d" % [current_node_key, (int(Time.get_unix_time_from_system()) % 1000)]
	nodes[dup_k] = nodes[current_node_key].duplicate(true)
	current_node_key = dup_k
	_on_dialogue_modified()
	_refresh_dialogue_list()
	_refresh_node_graph()
	_populate_node_inspector()
	_update_preview_display()

func _on_dialogue_modified() -> void:
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("dialogue." + current_npc_id, "nodes", current_dialogue_data.get("nodes", {}))
	validate()
	panel_dirtied.emit()

func _update_preview_display() -> void:
	if preview_portrait:
		preview_portrait.texture = AssetRegistry.get_npc_portrait(current_npc_id)
	if preview_speaker_label:
		preview_speaker_label.text = current_npc_id.capitalize()

	var nodes = current_dialogue_data.get("nodes", {})
	var node = nodes.get(current_node_key, {})
	var lines = node.get("lines", [])
	if preview_line_label:
		preview_line_label.text = "\n".join(lines) if lines.size() > 0 else "..."

func _on_run_interactive_preview() -> void:
	_update_preview_display()
	if sim_result_label:
		sim_result_label.text = "Interactive Preview: Executing '%s'" % current_node_key

func _on_simulate_evaluation() -> void:
	# Evaluate simulated conditions against all nodes to find highest priority match
	var nodes = current_dialogue_data.get("nodes", {})
	var best_node = "default"
	var best_prio = -1

	for k in nodes.keys():
		var node = nodes[k]
		var prio = int(node.get("priority", 0))
		var conds = node.get("conditions", [])
		var matched = true

		for c in conds:
			var ctype = str(c.get("type", ""))
			if ctype == "heart_level" and sim_heart_level < int(c.get("min", 1)):
				matched = false; break
			elif ctype == "weather" and sim_weather != str(c.get("is", "rain")):
				matched = false; break
			elif ctype == "season" and sim_season != str(c.get("is", "spring")):
				matched = false; break
			elif ctype == "quest_active" and sim_active_quest != str(c.get("quest_id", "")):
				matched = false; break
			elif ctype == "quest_completed" and sim_completed_quest != str(c.get("quest_id", "")):
				matched = false; break

		if matched and prio > best_prio:
			best_prio = prio
			best_node = k

	if sim_result_label:
		sim_result_label.text = "Simulated Evaluation Result: Triggered Node '%s' (Priority %d)" % [best_node, best_prio]
		sim_result_label.modulate = Color(0.4, 1.0, 0.4)

func _on_play_dialogue_in_game() -> void:
	var dm = Engine.get_main_loop().root.get_node_or_null("/root/DialogueManager") if Engine.get_main_loop() else null
	if dm:
		dm.start_dialogue(current_npc_id)

func reset_current_node() -> void:
	if editor_service and editor_service.data_service:
		editor_service.data_service.restore_default("dialogue." + current_npc_id, "", true)
	_load_dialogue_data(current_npc_id)

func reset_all_npc_dialogues() -> void:
	if editor_service and editor_service.data_service:
		editor_service.data_service.restore_default("dialogue." + current_npc_id, "", true)
	_load_dialogue_data(current_npc_id)

func validate() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	var nodes = current_dialogue_data.get("nodes", {})
	if not nodes.has("default"):
		warnings.append("Missing 'default' fallback dialogue node.")

	for k in nodes.keys():
		var node = nodes[k]
		var lines = node.get("lines", [])
		if lines.is_empty():
			warnings.append("Node '%s' has no dialogue lines." % k)

		var choices = node.get("choices", [])
		for ch in choices:
			var target = str(ch.get("target_node", ""))
			if target != "" and not nodes.has(target):
				errors.append("Choice in node '%s' targets non-existent node '%s'." % [k, target])

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
		"total_checked": nodes.size()
	}


## Public programmatic and UI authoring entry point for creating new Dialogue trees (Phase 36)
func create_dialogue(dialogue_id: String, owner_npc: String, start_node_key: String = "start", lines: Array = ["Hello there!"]) -> Dictionary:
	var clean_id = dialogue_id.strip_edges().to_lower().replace(" ", "_").trim_prefix("dialogue.")
	if clean_id == "": clean_id = "custom_diag_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	var clean_npc = owner_npc.trim_prefix("npc.")
	
	var diag_data = {
		"id": clean_id,
		"npc_id": clean_npc,
		"nodes": {
			start_node_key: {
				"lines": lines,
				"speaker": clean_npc.capitalize(),
				"emotion": "neutral",
				"conditions": [],
				"choices": [],
				"action": "none"
			}
		}
	}
	
	if editor_service and editor_service.data_service:
		editor_service.data_service.create_entity("dialogue." + clean_id, diag_data)
		
	current_npc_id = clean_npc
	current_dialogue_data = diag_data
	current_node_key = start_node_key
	
	_load_npc_list()
	_load_dialogue_data(clean_npc)
	panel_dirtied.emit()
	return diag_data
