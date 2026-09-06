class_name HotbarUI
extends Control

## 10-Slot Pixel-Art Hotbar UI positioned at the bottom center of the HUD.
## Displays item icons, stack counts, slot numbers, tool quality, active selection and tooltips.

const SLOT_COUNT: int = 10
const SLOT_SIZE: Vector2 = Vector2(46, 46)
const SLOT_GAP: int = 5

var slot_container: HBoxContainer
var slot_panels: Array[PanelContainer] = []
var tooltip_card: PanelContainer
var tooltip_label: Label

func _ready() -> void:
	# Configure root container anchored bottom-center of viewport
	set_anchors_preset(PRESET_CENTER_BOTTOM)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BEGIN
	
	var total_w = SLOT_COUNT * SLOT_SIZE.x + (SLOT_COUNT - 1) * SLOT_GAP + 18
	offset_left = -total_w / 2.0
	offset_right = total_w / 2.0
	offset_bottom = -16
	offset_top = -76
	custom_minimum_size = Vector2(total_w, 58)
	mouse_filter = MOUSE_FILTER_PASS

	
	# Background Frame Panel
	var bg_panel = PanelContainer.new()
	bg_panel.anchors_preset = PRESET_FULL_RECT
	bg_panel.anchor_right = 1.0
	bg_panel.anchor_bottom = 1.0
	bg_panel.mouse_filter = MOUSE_FILTER_PASS
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.08, 0.09, 0.12, 0.90)
	bg_style.set_border_width_all(2)
	bg_style.border_color = Color(0.24, 0.28, 0.35, 0.95)
	bg_style.set_corner_radius_all(5)
	bg_style.shadow_size = 5
	bg_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	add_child(bg_panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	margin.mouse_filter = MOUSE_FILTER_PASS
	bg_panel.add_child(margin)
	
	# Create Slot Container
	slot_container = HBoxContainer.new()
	slot_container.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_container.add_theme_constant_override("separation", SLOT_GAP)
	slot_container.mouse_filter = MOUSE_FILTER_PASS
	margin.add_child(slot_container)
	
	_create_slots()
	_create_tooltip()
	
	# Connect to PlayerState
	var bus = get_node_or_null("/root/EventBus")
	if bus: bus.world_changed.connect(func(_w, _d={}): _on_world_changed())
	_bind_player_state()
	_refresh_hotbar()

func _create_slots() -> void:
	for i in range(SLOT_COUNT):
		var panel = PanelContainer.new()
		panel.custom_minimum_size = SLOT_SIZE
		panel.mouse_filter = MOUSE_FILTER_STOP
		panel.gui_input.connect(_on_slot_gui_input.bind(i))
		panel.mouse_entered.connect(_on_slot_mouse_entered.bind(i))
		panel.mouse_exited.connect(_on_slot_mouse_exited.bind(i))
		
		# Slot Number Label (1..9, 0)
		var num_lbl = Label.new()
		num_lbl.name = "Num"
		num_lbl.text = str((i + 1) % 10)
		num_lbl.add_theme_font_size_override("font_size", 11)
		num_lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85, 0.8))
		num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		num_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		num_lbl.position = Vector2(4, 2)
		
		# Icon Label (Centered)
		var icon_lbl = Label.new()
		icon_lbl.name = "Icon"
		icon_lbl.text = ""
		icon_lbl.add_theme_font_size_override("font_size", 22)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		icon_lbl.anchors_preset = PRESET_FULL_RECT
		icon_lbl.anchor_right = 1.0
		icon_lbl.anchor_bottom = 1.0
		
		# Count Label (Bottom Right)
		var count_lbl = Label.new()
		count_lbl.name = "Count"
		count_lbl.text = ""
		count_lbl.add_theme_font_size_override("font_size", 11)
		count_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.4, 1.0))
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		count_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		count_lbl.anchors_preset = PRESET_FULL_RECT
		count_lbl.anchor_right = 1.0
		count_lbl.anchor_bottom = 1.0
		count_lbl.offset_right = -3
		count_lbl.offset_bottom = -2
		
		panel.add_child(icon_lbl)
		panel.add_child(num_lbl)
		panel.add_child(count_lbl)
		
		slot_container.add_child(panel)
		slot_panels.append(panel)

func _create_tooltip() -> void:
	tooltip_card = PanelContainer.new()
	tooltip_card.mouse_filter = MOUSE_FILTER_IGNORE
	tooltip_card.visible = false
	tooltip_card.set_anchors_preset(PRESET_CENTER_TOP)
	tooltip_card.position = Vector2(0, -32)
	tooltip_card.grow_horizontal = GROW_DIRECTION_BOTH
	tooltip_card.custom_minimum_size = Vector2(220, 24)
	
	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.1, 0.12, 0.15, 0.95)
	card_sb.set_border_width_all(1)
	card_sb.border_color = Color(0.4, 0.45, 0.55, 0.9)
	card_sb.set_corner_radius_all(3)
	card_sb.shadow_size = 3
	card_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	tooltip_card.add_theme_stylebox_override("panel", card_sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.mouse_filter = MOUSE_FILTER_IGNORE
	tooltip_card.add_child(margin)
	
	tooltip_label = Label.new()
	tooltip_label.add_theme_font_size_override("font_size", 10)
	tooltip_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8, 1.0))
	tooltip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tooltip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tooltip_label.mouse_filter = MOUSE_FILTER_IGNORE
	margin.add_child(tooltip_label)
	
	add_child(tooltip_card)

func _bind_player_state() -> void:
	var state = _get_active_state()
	if state:
		if not state.hotbar_changed.is_connected(_refresh_hotbar):
			state.hotbar_changed.connect(_refresh_hotbar)
		if not state.hotbar_slot_selected.is_connected(_on_slot_selected):
			state.hotbar_slot_selected.connect(_on_slot_selected)
		if not state.inventory_changed.is_connected(_refresh_hotbar):
			state.inventory_changed.connect(_refresh_hotbar)
			
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm and not lm.locale_changed.is_connected(_on_locale_changed):
		lm.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_locale_id: String) -> void:
	_refresh_hotbar()

func _on_world_changed() -> void:
	_bind_player_state()
	_refresh_hotbar()

func _get_active_state() -> PlayerState:
	if not is_inside_tree(): return null
	var player = get_tree().get_first_node_in_group("local_player")
	if player and "player_state" in player: return player.player_state
	return null

func _refresh_hotbar() -> void:
	var state = _get_active_state()
	if not state: return
	
	var sel_idx = state.selected_hotbar_slot
	for i in range(SLOT_COUNT):
		var panel = slot_panels[i]
		var item_id = state.get_hotbar_slot(i)
		var icon_lbl = panel.find_child("Icon", true, false) as Label
		var count_lbl = panel.find_child("Count", true, false) as Label
		var num_lbl = panel.find_child("Num", true, false) as Label
		
		if item_id != "" and state.has_item(item_id):
			var data = ItemRegistry.get_item(item_id)
			if icon_lbl: icon_lbl.text = data.get("icon", "📦")
			var cnt = state.get_item_count(item_id)
			if count_lbl: count_lbl.text = "x%d" % cnt if cnt > 1 else ""
		else:
			if icon_lbl: icon_lbl.text = ""
			if count_lbl: count_lbl.text = ""
			
		var is_selected = (i == sel_idx)
		if num_lbl:
			num_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if is_selected else Color(0.7, 0.75, 0.8, 0.7))
			
		_style_slot(panel, is_selected, item_id)

func _style_slot(panel: PanelContainer, is_selected: bool, item_id: String) -> void:
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(3)
	
	var lsm = get_node_or_null("/root/LocalStateManager")
	var high_contrast = lsm and lsm.get_setting("accessibility", "high_contrast", false)
	
	if is_selected:
		sb.set_border_width_all(2)
		sb.bg_color = Color(0.24, 0.28, 0.36, 0.95)
		sb.border_color = Color(1.0, 0.85, 0.2, 1.0) if not high_contrast else Color(1.0, 1.0, 0.0, 1.0)
		sb.shadow_size = 3
		sb.shadow_color = Color(1.0, 0.8, 0.1, 0.35)
	else:
		sb.set_border_width_all(1)
		sb.bg_color = Color(0.12, 0.14, 0.18, 0.85)
		sb.border_color = Color(0.28, 0.32, 0.4, 0.7)
		
		# Quality tint when not selected
		if item_id != "":
			var qual = ItemRegistry.get_quality(item_id)
			match qual:
				ItemRegistry.Quality.COPPER:
					sb.border_color = Color(0.85, 0.45, 0.2, 0.85)
				ItemRegistry.Quality.IRON:
					sb.border_color = Color(0.75, 0.82, 0.92, 0.9)
				ItemRegistry.Quality.GOLD:
					sb.border_color = Color(1.0, 0.85, 0.3, 0.95)
					
	panel.add_theme_stylebox_override("panel", sb)

func _on_slot_selected(_idx: int, _item_id: String) -> void:
	_refresh_hotbar()

func _on_slot_gui_input(event: InputEvent, slot_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var state = _get_active_state()
		if state:
			state.select_hotbar_slot(slot_idx)
		accept_event()

func _on_slot_mouse_entered(slot_idx: int) -> void:
	var state = _get_active_state()
	if not state: return
	var item_id = state.get_hotbar_slot(slot_idx)
	if item_id != "" and state.has_item(item_id):
		var data = ItemRegistry.get_item(item_id)
		var dname = ItemRegistry.get_localized_name(item_id)
		var qname = ItemRegistry.get_quality_name(item_id)
		var cnt = state.get_item_count(item_id)
		var lm = get_node_or_null("/root/LocalizationManager")
		
		if data.get("category") == ItemRegistry.Category.TOOL:
			var cost = data.get("stamina_cost", 1.5)
			if lm:
				tooltip_label.text = lm.format("ui.hotbar.tooltip_tool", { "name": dname, "quality": qname, "cost": "%.1f" % cost })
			else:
				tooltip_label.text = "%s [%s] • Stamina: -%.1f" % [dname, qname, cost]
		elif cnt > 1:
			if lm:
				tooltip_label.text = lm.format("ui.hotbar.tooltip_stack", { "name": dname, "count": cnt })
			else:
				tooltip_label.text = "%s (x%d)" % [dname, cnt]
		else:
			tooltip_label.text = dname
			
		if tooltip_card:
			tooltip_card.visible = true

func _on_slot_mouse_exited(_slot_idx: int) -> void:
	if tooltip_card:
		tooltip_card.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventKey and event.pressed and not event.echo:
		var code = event.keycode
		if code == KEY_NONE or code == 0:
			code = event.physical_keycode
		if code == KEY_NONE or code == 0:
			code = event.key_label
			
		var slot = -1
		if code >= KEY_1 and code <= KEY_9:
			slot = code - KEY_1
		elif code == KEY_0:
			slot = 9
		elif code >= KEY_KP_1 and code <= KEY_KP_9:
			slot = code - KEY_KP_1
		elif code == KEY_KP_0:
			slot = 9
		elif event.unicode >= 49 and event.unicode <= 57:
			slot = event.unicode - 49
		elif event.unicode == 48:
			slot = 9
			
		if slot >= 0 and slot < SLOT_COUNT:
			var state = _get_active_state()
			if state:
				state.select_hotbar_slot(slot)
				get_viewport().set_input_as_handled()

