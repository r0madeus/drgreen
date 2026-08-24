class_name WorldGraphDialog
extends Window

## Interactive visual node-link graph showing all world connections and transitions.

signal world_selected(world_id: String)

var graph_canvas: Control

func _ready() -> void:
	title = " World Connection Graph"
	size = Vector2i(640, 420)
	exclusive = false
	visible = false
	close_requested.connect(hide)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "Click a world node below to switch to that map:"
	lbl.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(lbl)
	
	graph_canvas = Control.new()
	graph_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_canvas.draw.connect(_on_draw_graph)
	vbox.add_child(graph_canvas)
	
	var close_b = Button.new()
	close_b.text = "Close Graph"
	close_b.pressed.connect(hide)
	vbox.add_child(close_b)

func open_graph() -> void:
	popup_centered()
	if graph_canvas: graph_canvas.queue_redraw()

func _on_draw_graph() -> void:
	if not graph_canvas: return
	var worlds = _scan_all_worlds()
	if worlds.is_empty(): return
	
	var spacing = graph_canvas.size.x / maxf(1.0, float(worlds.size()))
	var node_positions: Dictionary = {}
	
	# Layout nodes in sequence/grid
	for i in range(worlds.size()):
		var w = worlds[i]
		var wid = str(w.get("world_id", "world"))
		var center = Vector2((i + 0.5) * spacing, graph_canvas.size.y * 0.5)
		if i % 2 == 1: center.y += 40
		else: center.y -= 40
		node_positions[wid] = center

	# Draw Directed Transition Arrows
	for w in worlds:
		var wid = str(w.get("world_id", ""))
		var p1 = node_positions.get(wid, Vector2.ZERO)
		for tr in w.get("transitions", []):
			var twid = str(tr.get("target_world", ""))
			if node_positions.has(twid):
				var p2 = node_positions[twid]
				graph_canvas.draw_line(p1, p2, Color(0.3, 0.8, 1.0, 0.7), 2.0)
				# Draw arrow head
				var dir = (p2 - p1).normalized()
				var arrow_p = p2 - dir * 35.0
				graph_canvas.draw_line(arrow_p, arrow_p - dir.rotated(0.5) * 10.0, Color.GOLD, 2.0)
				graph_canvas.draw_line(arrow_p, arrow_p - dir.rotated(-0.5) * 10.0, Color.GOLD, 2.0)

	# Draw World Nodes
	for wid in node_positions.keys():
		var pos = node_positions[wid]
		var rect = Rect2(pos - Vector2(60, 24), Vector2(120, 48))
		graph_canvas.draw_rect(rect, Color(0.18, 0.14, 0.10, 0.95))
		graph_canvas.draw_rect(rect, Color.GOLD, false, 2.0)
		graph_canvas.draw_string(ThemeDB.fallback_font, pos - Vector2(48, -4), wid.capitalize(), HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color.WHITE)

func _scan_all_worlds() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir = DirAccess.open("res://data/worlds/")
	if dir:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if not dir.current_is_dir() and fn.ends_with(".json") and not fn.ends_with(".tmp"):
				var data = WorldSerializer.load_world("res://data/worlds/" + fn)
				if not data.is_empty(): result.append(data)
			fn = dir.get_next()
		dir.list_dir_end()
	return result
