class_name MechanicGraphEditorPanel
extends Control

## Visual Mechanic Graph & Gameplay Logic Builder (Phase 42).
## Wires event triggers, declarative condition branches, action execution,
## state changes, and live dry-run simulation.

const GRAPH_SCRIPT = preload("res://core/gameplay/custom_mechanic_graph.gd")

var current_graph: Variant = null

var graph_list: ItemList
var id_edit: LineEdit
var name_edit: LineEdit
var event_edit: LineEdit
var nodes_tree: Tree
var sim_log: TextEdit
var status_label: Label

func _init() -> void:
	custom_minimum_size = Vector2(800, 500)
	_build_ui()

func _build_ui() -> void:
	var root_vbox = VBoxContainer.new()
	root_vbox.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root_vbox)
	
	var hdr = Label.new()
	hdr.text = "🧠 Mechanic Graph & Gameplay Logic Builder"
	hdr.add_theme_font_size_override("font_size", 14)
	root_vbox.add_child(hdr)
	
	var hsplit = HBoxContainer.new()
	hsplit.size_flags_vertical = SIZE_EXPAND_FILL
	root_vbox.add_child(hsplit)
	
	# Left: Graphs List
	var left_box = VBoxContainer.new()
	left_box.custom_minimum_size = Vector2(200, 0)
	var gl_hdr = Label.new()
	gl_hdr.text = "Mechanic Graphs:"
	left_box.add_child(gl_hdr)
	
	graph_list = ItemList.new()
	graph_list.size_flags_vertical = SIZE_EXPAND_FILL
	left_box.add_child(graph_list)
	
	var new_btn = Button.new()
	new_btn.text = "+ New Mechanic"
	new_btn.pressed.connect(_on_new_mechanic_clicked)
	left_box.add_child(new_btn)
	hsplit.add_child(left_box)
	
	# Center: Graph Sequence
	var center_box = VBoxContainer.new()
	center_box.size_flags_horizontal = SIZE_EXPAND_FILL
	
	id_edit = LineEdit.new()
	id_edit.placeholder_text = "Mechanic ID"
	center_box.add_child(id_edit)
	
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Mechanic Name"
	center_box.add_child(name_edit)
	
	event_edit = LineEdit.new()
	event_edit.placeholder_text = "Trigger Event (e.g. hunger.changed)"
	center_box.add_child(event_edit)
	
	nodes_tree = Tree.new()
	nodes_tree.size_flags_vertical = SIZE_EXPAND_FILL
	center_box.add_child(nodes_tree)
	
	var act_bar = HBoxContainer.new()
	var add_cond_btn = Button.new()
	add_cond_btn.text = "+ Condition Node"
	add_cond_btn.pressed.connect(_on_add_condition_clicked)
	act_bar.add_child(add_cond_btn)
	
	var add_act_btn = Button.new()
	add_act_btn.text = "+ Action Node"
	add_act_btn.pressed.connect(_on_add_action_clicked)
	act_bar.add_child(add_act_btn)
	center_box.add_child(act_bar)
	hsplit.add_child(center_box)
	
	# Right: Live Simulator
	var right_box = VBoxContainer.new()
	right_box.custom_minimum_size = Vector2(250, 0)
	var sim_hdr = Label.new()
	sim_hdr.text = " Live Simulator:"
	right_box.add_child(sim_hdr)
	
	var run_sim_btn = Button.new()
	run_sim_btn.text = " Simulate Run"
	run_sim_btn.pressed.connect(_on_run_sim_clicked)
	right_box.add_child(run_sim_btn)
	
	sim_log = TextEdit.new()
	sim_log.size_flags_vertical = SIZE_EXPAND_FILL
	sim_log.editable = false
	right_box.add_child(sim_log)
	hsplit.add_child(right_box)
	
	status_label = Label.new()
	status_label.text = ""
	root_vbox.add_child(status_label)

func _on_new_mechanic_clicked() -> void:
	current_graph = GRAPH_SCRIPT.new("hunger_drain", "Hunger Drain Mechanic", "hunger.changed")
	id_edit.text = current_graph.mechanic_id
	name_edit.text = current_graph.name
	event_edit.text = current_graph.trigger_event
	_refresh_nodes()
	status_label.text = "Created new mechanic graph."

func _refresh_nodes() -> void:
	nodes_tree.clear()
	var root = nodes_tree.create_item()
	nodes_tree.hide_root = true
	if not current_graph: return
	
	for n in current_graph.nodes:
		var item = nodes_tree.create_item(root)
		item.set_text(0, " " + JSON.stringify(n))

func _on_add_condition_clicked() -> void:
	if not current_graph: return
	current_graph.add_node({
		"type": "condition",
		"expression": { "left": "component.hunger.current", "op": "<=", "right": 25.0 },
		"if_true": [{ "type": "transition_state", "state": "hungry" }]
	})
	_refresh_nodes()

func _on_add_action_clicked() -> void:
	if not current_graph: return
	current_graph.add_node({
		"type": "damage_entity",
		"amount": 5.0
	})
	_refresh_nodes()

func _on_run_sim_clicked() -> void:
	if not current_graph:
		sim_log.text = "No mechanic graph loaded."
		return
		
	var test_ctx = {
		"component": { "hunger": { "current": 15.0, "maximum": 100.0 } },
		"state_machine": { "current_state": "normal" },
		"health": { "current_health": 100.0 }
	}
	
	var res = current_graph.execute(test_ctx)
	var output = "SIMULATION RESULT: %s\n\nTRACE:\n" % ("SUCCESS" if res.get("success", false) else "FAILED")
	for line in res.get("trace", []):
		output += line + "\n"
	output += "\nFINAL CONTEXT:\n" + JSON.stringify(test_ctx, "  ")
	sim_log.text = output
