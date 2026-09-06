class_name RelationshipUI
extends Control

## UI Panel displaying player's NPC relationship statuses, heart gauges,
## and daily gift availability with full localization and AssetRegistry support.

signal gift_submitted(npc_id: String, item_id: String)
signal panel_closed()

@onready var container: VBoxContainer = VBoxContainer.new()
@onready var title_label: Label = Label.new()
@onready var close_btn: Button = Button.new()

var is_open: bool = false

func _ready() -> void:
	theme = UIConstants.get_theme()
	_setup_ui()
	visible = false

func _setup_ui() -> void:
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH
	mouse_filter = MOUSE_FILTER_PASS
	
	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.grow_horizontal = GROW_DIRECTION_BOTH
	center.grow_vertical = GROW_DIRECTION_BOTH
	center.mouse_filter = MOUSE_FILTER_PASS
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 240)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	var header = HBoxContainer.new()
	vbox.add_child(header)
	
	title_label.text = "❤️ " + tr("social.ui.relationships")
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)
	
	close_btn.text = "✖"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)
	
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(320, 160)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(container)

func open() -> void:
	UIConstants.close_all_modals(get_tree(), self)
	refresh()
	visible = true
	is_open = true
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_open")
	UIConstants.update_player_lock(get_tree())

func close() -> void:
	visible = false
	is_open = false
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_close")
	UIConstants.update_player_lock(get_tree())
	panel_closed.emit()

func refresh() -> void:
	if container:
		for c in container.get_children():
			c.queue_free()
		
	var p_state: PlayerState = null
	if is_inside_tree():
		var player = get_tree().get_first_node_in_group("local_player")
		if player and "player_state" in player:
			p_state = player.player_state
	if not p_state:
		var psm = get_node_or_null("/root/PlayerRegistry")
		if psm and psm.has_method("get_player_state"):
			var pid = psm.local_player_id if "local_player_id" in psm and psm.local_player_id != "" else "player_001"
			p_state = psm.get_player_state(pid)
	if not p_state: return
	
	var npcs = ["rowan", "elias", "mira"]
	for nid in npcs:
		var state = p_state.get_relationship_state(nid)
		var card = _create_npc_card(nid, state)
		container.add_child(card)

func _create_npc_card(npc_id: String, rel_state: Dictionary) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(280, 36)
	
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(32, 32)
	tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var port = AssetRegistry.get_npc_portrait(npc_id)
	if port: tex_rect.texture = port
	row.add_child(tex_rect)
	
	var info_box = VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_lbl = Label.new()
	name_lbl.text = npc_id.capitalize()
	name_lbl.add_theme_font_size_override("font_size", 11)
	info_box.add_child(name_lbl)
	
	var hearts_str = ""
	var h_lvl = int(rel_state.get("heart_level", 0))
	for i in range(5):
		hearts_str += "♥" if i < h_lvl else "♡"
		
	var prog = rel_state.get("progress", {})
	var pts = int(prog.get("total_points", 0))
	var next_t = int(prog.get("next_threshold", 100))
	
	var gauge_lbl = Label.new()
	gauge_lbl.text = "%s  (%d / %d pts)" % [hearts_str, pts, next_t]
	gauge_lbl.add_theme_font_size_override("font_size", 9)
	gauge_lbl.modulate = Color(1.0, 0.4, 0.6)
	info_box.add_child(gauge_lbl)
	row.add_child(info_box)
	
	var gift_icon = Label.new()
	var can_g = bool(rel_state.get("can_gift", true))
	gift_icon.text = "🎁 Ready" if can_g else "✓ Gifted"
	gift_icon.add_theme_font_size_override("font_size", 9)
	gift_icon.modulate = Color(0.4, 1.0, 0.4) if can_g else Color(0.7, 0.7, 0.7)
	row.add_child(gift_icon)
	
	return row
