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
	_setup_ui()
	visible = false

func _setup_ui() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -160
	offset_top = -110
	offset_right = 160
	offset_bottom = 110
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	
	title_label.text = tr("social.ui.relationships")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(0, 8)
	title_label.size = Vector2(320, 24)
	add_child(title_label)
	
	container.position = Vector2(16, 36)
	container.size = Vector2(288, 130)
	add_child(container)
	
	close_btn.text = "✖ Close"
	close_btn.position = Vector2(120, 175)
	close_btn.size = Vector2(80, 24)
	close_btn.pressed.connect(close)
	add_child(close_btn)

func open() -> void:
	refresh()
	visible = true
	is_open = true

func close() -> void:
	visible = false
	is_open = false
	panel_closed.emit()

func refresh() -> void:
	for c in container.get_children():
		c.queue_free()
		
	var psm = get_node_or_null("/root/PlayerStateManager")
	var p_state = psm.get_active_player_state() if psm else null
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
