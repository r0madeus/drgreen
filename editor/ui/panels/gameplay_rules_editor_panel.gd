class_name GameplayRulesEditorPanel
extends Control

## In-Game Gameplay Rules & Event Trigger Editor with Live Simulator (Phase 39).
## Allows game developers and modders to author triggers, conditions, and action chains with real-time sandboxed dry-runs.

const SIMULATOR_SCRIPT = preload("res://core/gameplay/gameplay_simulator.gd")
const TRIG_SCRIPT = preload("res://core/gameplay/gameplay_trigger.gd")
const RULE_MGR_SCRIPT = preload("res://core/gameplay/gameplay_rule_manager.gd")

var editor_service: Variant = null
var current_rule_id: String = ""

# UI Controls
var rule_list: ItemList
var id_edit: LineEdit
var name_edit: LineEdit
var event_edit: LineEdit
var priority_spin: SpinBox
var cooldown_spin: SpinBox
var once_check: CheckBox
var enabled_check: CheckBox
var condition_edit: TextEdit
var actions_edit: TextEdit

var simulate_btn: Button
var sim_event_edit: LineEdit
var sim_context_edit: TextEdit
var sim_output_label: RichTextLabel

func _init(p_service: Variant = null) -> void:
	editor_service = p_service
	custom_minimum_size = Vector2(800, 500)
	_build_ui()

func _build_ui() -> void:
	var hsplit = HSplitContainer.new()
	hsplit.set_anchors_preset(PRESET_FULL_RECT)
	add_child(hsplit)
	
	# Left: Rule List
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(240, 0)
	hsplit.add_child(left_vbox)
	
	var list_hdr = Label.new()
	list_hdr.text = " Gameplay Triggers & Rules"
	left_vbox.add_child(list_hdr)
	
	var add_btn = Button.new()
	add_btn.text = "+ New Rule"
	add_btn.pressed.connect(_on_create_new_rule)
	left_vbox.add_child(add_btn)
	
	rule_list = ItemList.new()
	rule_list.size_flags_vertical = SIZE_EXPAND_FILL
	rule_list.item_selected.connect(_on_rule_selected)
	left_vbox.add_child(rule_list)
	
	# Right: Inspector & Simulator Tabs
	var tab_container = TabContainer.new()
	tab_container.size_flags_horizontal = SIZE_EXPAND_FILL
	tab_container.size_flags_vertical = SIZE_EXPAND_FILL
	hsplit.add_child(tab_container)
	
	# Tab 1: Rule Inspector
	var insp_vbox = VBoxContainer.new()
	insp_vbox.name = "Rule Inspector"
	tab_container.add_child(insp_vbox)
	
	var id_box = HBoxContainer.new()
	id_box.add_child(Label.new())
	(id_box.get_child(0) as Label).text = "Rule ID: "
	id_edit = LineEdit.new()
	id_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	id_box.add_child(id_edit)
	insp_vbox.add_child(id_box)
	
	var name_box = HBoxContainer.new()
	name_box.add_child(Label.new())
	(name_box.get_child(0) as Label).text = "Name: "
	name_edit = LineEdit.new()
	name_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	name_box.add_child(name_edit)
	insp_vbox.add_child(name_box)
	
	var evt_box = HBoxContainer.new()
	evt_box.add_child(Label.new())
	(evt_box.get_child(0) as Label).text = "Trigger Event: "
	event_edit = LineEdit.new()
	event_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	evt_box.add_child(event_edit)
	insp_vbox.add_child(evt_box)
	
	var opts_box = HBoxContainer.new()
	priority_spin = SpinBox.new()
	priority_spin.min_value = 0
	priority_spin.max_value = 1000
	priority_spin.value = 100
	opts_box.add_child(Label.new())
	(opts_box.get_child(0) as Label).text = "Priority: "
	opts_box.add_child(priority_spin)
	
	cooldown_spin = SpinBox.new()
	cooldown_spin.min_value = 0
	cooldown_spin.max_value = 3600
	cooldown_spin.step = 0.5
	opts_box.add_child(Label.new())
	(opts_box.get_child(2) as Label).text = " Cooldown (s): "
	opts_box.add_child(cooldown_spin)
	
	once_check = CheckBox.new()
	once_check.text = "Once"
	opts_box.add_child(once_check)
	
	enabled_check = CheckBox.new()
	enabled_check.text = "Enabled"
	enabled_check.button_pressed = true
	opts_box.add_child(enabled_check)
	insp_vbox.add_child(opts_box)
	
	var cond_lbl = Label.new()
	cond_lbl.text = "Conditions (JSON):"
	insp_vbox.add_child(cond_lbl)
	condition_edit = TextEdit.new()
	condition_edit.custom_minimum_size = Vector2(0, 100)
	insp_vbox.add_child(condition_edit)
	
	var act_lbl = Label.new()
	act_lbl.text = "Actions Sequence (JSON Array):"
	insp_vbox.add_child(act_lbl)
	actions_edit = TextEdit.new()
	actions_edit.custom_minimum_size = Vector2(0, 120)
	actions_edit.size_flags_vertical = SIZE_EXPAND_FILL
	insp_vbox.add_child(actions_edit)
	
	var save_rule_btn = Button.new()
	save_rule_btn.text = "Apply Rule Changes"
	save_rule_btn.pressed.connect(_on_apply_rule_changes)
	insp_vbox.add_child(save_rule_btn)
	
	# Tab 2: Live Simulator
	var sim_vbox = VBoxContainer.new()
	sim_vbox.name = " Live Simulator"
	tab_container.add_child(sim_vbox)
	
	var sim_evt_box = HBoxContainer.new()
	sim_evt_box.add_child(Label.new())
	(sim_evt_box.get_child(0) as Label).text = "Simulated Event Type: "
	sim_event_edit = LineEdit.new()
	sim_event_edit.size_flags_horizontal = SIZE_EXPAND_FILL
	sim_event_edit.text = "player_entered_world"
	sim_evt_box.add_child(sim_event_edit)
	sim_vbox.add_child(sim_evt_box)
	
	var sim_ctx_lbl = Label.new()
	sim_ctx_lbl.text = "Mock Context (JSON):"
	sim_vbox.add_child(sim_ctx_lbl)
	sim_context_edit = TextEdit.new()
	sim_context_edit.custom_minimum_size = Vector2(0, 100)
	sim_context_edit.text = '{\n  "current_world": "forest",\n  "gold": 250,\n  "flags": { "has_key": true }\n}'
	sim_vbox.add_child(sim_context_edit)
	
	simulate_btn = Button.new()
	simulate_btn.text = " Run Dry-Run Simulation"
	simulate_btn.pressed.connect(_on_run_simulation)
	sim_vbox.add_child(simulate_btn)
	
	var out_lbl = Label.new()
	out_lbl.text = "Simulation Trace Log:"
	sim_vbox.add_child(out_lbl)
	sim_output_label = RichTextLabel.new()
	sim_output_label.custom_minimum_size = Vector2(0, 140)
	sim_output_label.size_flags_vertical = SIZE_EXPAND_FILL
	sim_output_label.bbcode_enabled = true
	sim_vbox.add_child(sim_output_label)

func refresh_rule_list() -> void:
	if not rule_list: return
	rule_list.clear()
	
	var ids: Array[String] = []
	if editor_service and editor_service.data_service:
		ids = editor_service.data_service.get_all_stable_ids("rule.")
	elif ClassDB.class_exists("GameplayRuleManager"):
		var mgr = RULE_MGR_SCRIPT.get_instance()
		for t in mgr.get_all_triggers():
			ids.append("rule." + t.trigger_id)
			
	for rid in ids:
		var display = rid.trim_prefix("rule.")
		rule_list.add_item(display)

func _on_rule_selected(index: int) -> void:
	if index < 0 or index >= rule_list.item_count: return
	var rule_name = rule_list.get_item_text(index)
	current_rule_id = "rule." + rule_name
	
	var data: Dictionary = {}
	if editor_service and editor_service.data_service:
		data = editor_service.data_service.get_resolved_object(current_rule_id)
		
	id_edit.text = rule_name
	name_edit.text = str(data.get("name", rule_name.capitalize()))
	event_edit.text = str(data.get("event_type", data.get("event", "player_entered_world")))
	priority_spin.value = int(data.get("priority", 100))
	cooldown_spin.value = float(data.get("cooldown", 0.0))
	once_check.button_pressed = bool(data.get("once", false))
	enabled_check.button_pressed = bool(data.get("enabled", true))
	condition_edit.text = JSON.stringify(data.get("condition", {}), "  ")
	actions_edit.text = JSON.stringify(data.get("actions", []), "  ")

func _on_create_new_rule() -> void:
	var clean_id = "custom_rule_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	var new_data = {
		"id": clean_id,
		"name": clean_id.capitalize(),
		"event_type": "player_entered_world",
		"priority": 100,
		"cooldown": 0.0,
		"once": false,
		"enabled": true,
		"condition": { "path": "current_world", "op": "==", "value": "forest" },
		"actions": [
			{ "type": "show_message", "text": "Welcome to the forest!" }
		]
	}
	if editor_service and editor_service.data_service:
		editor_service.data_service.create_entity("rule." + clean_id, new_data)
	refresh_rule_list()

func _on_apply_rule_changes() -> void:
	if current_rule_id == "": return
	var cond_json = JSON.parse_string(condition_edit.text)
	var act_json = JSON.parse_string(actions_edit.text)
	
	var updated_data = {
		"id": id_edit.text,
		"name": name_edit.text,
		"event_type": event_edit.text,
		"priority": int(priority_spin.value),
		"cooldown": float(cooldown_spin.value),
		"once": once_check.button_pressed,
		"enabled": enabled_check.button_pressed,
		"condition": cond_json if cond_json != null else {},
		"actions": act_json if act_json != null else []
	}
	
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override(current_rule_id, "name", updated_data["name"])
		editor_service.data_service.set_staged_override(current_rule_id, "event_type", updated_data["event_type"])
		editor_service.data_service.set_staged_override(current_rule_id, "priority", updated_data["priority"])
		editor_service.data_service.set_staged_override(current_rule_id, "condition", updated_data["condition"])
		editor_service.data_service.set_staged_override(current_rule_id, "actions", updated_data["actions"])

func _on_run_simulation() -> void:
	var trig_data = {
		"id": id_edit.text,
		"event_type": event_edit.text,
		"condition": JSON.parse_string(condition_edit.text) if condition_edit.text != "" else {},
		"actions": JSON.parse_string(actions_edit.text) if actions_edit.text != "" else []
	}
	var mock_evt = { "event_type": sim_event_edit.text }
	var mock_ctx = JSON.parse_string(sim_context_edit.text)
	if mock_ctx == null: mock_ctx = {}
	
	var sim_result = SIMULATOR_SCRIPT.simulate(trig_data, mock_evt, mock_ctx)
	var trace: Array = sim_result.get("trace", [])
	
	var output_text = "[b]Simulation Output:[/b]\n"
	for line in trace:
		if line.begins_with(""):
			output_text += "[color=green]" + line + "[/color]\n"
		elif line.begins_with(""):
			output_text += "[color=red]" + line + "[/color]\n"
		elif line.begins_with(""):
			output_text += "[color=yellow]" + line + "[/color]\n"
		else:
			output_text += line + "\n"
			
	sim_output_label.text = output_text
