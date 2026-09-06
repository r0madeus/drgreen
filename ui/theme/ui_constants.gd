class_name UIConstants
extends RefCounted

## Modern Studio Dark theme constants & StyleBox generators.
## Clean neutral slates, refined studio blue/emerald accents, zero harsh neon.

const COLOR_BG_DARK = Color(0.09, 0.10, 0.12, 1.0) # #17191f
const COLOR_BG_PANEL = Color(0.12, 0.13, 0.16, 0.98) # #1f2129
const COLOR_BG_CARD = Color(0.10, 0.11, 0.14, 0.95) # #1a1c24
const COLOR_BG_INPUT = Color(0.08, 0.09, 0.11, 0.95) # #14171c
const COLOR_BG_SLOT = Color(0.14, 0.15, 0.18, 0.90)
const COLOR_BG_SLOT_SELECTED = Color(0.20, 0.25, 0.35, 0.98)

const COLOR_BORDER_SUBTLE = Color(0.22, 0.24, 0.28, 0.8) # #383d47
const COLOR_BORDER_FOCUSED = Color(0.25, 0.50, 0.90, 1.0) # Modern studio blue
const COLOR_BORDER_SELECTED = Color(0.25, 0.55, 0.95, 1.0)
const COLOR_BORDER_SLOT = Color(0.25, 0.28, 0.34, 0.7)

const COLOR_ACCENT_PRIMARY = Color(0.23, 0.51, 0.96, 1.0) # #3b82f6
const COLOR_ACCENT_SUCCESS = Color(0.20, 0.75, 0.45, 1.0) # Calm mint/green
const COLOR_ACCENT_WARNING = Color(0.95, 0.65, 0.20, 1.0) # Warm amber
const COLOR_ACCENT_DANGER = Color(0.92, 0.35, 0.35, 1.0) # Muted crimson

const COLOR_TEXT_LIGHT = Color(0.94, 0.95, 0.97) # Crisp clean white
const COLOR_TEXT_MUTED = Color(0.62, 0.65, 0.72) # Refined secondary text
const COLOR_TEXT_DARK = Color(0.12, 0.14, 0.16)

static func create_panel_stylebox(bg_color: Color = COLOR_BG_PANEL, border_color: Color = COLOR_BORDER_SUBTLE, corner_radius: int = 4, border_width: int = 1) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.shadow_size = 2
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	return sb

static func create_button_stylebox(bg_color: Color = Color(0.16, 0.17, 0.21, 0.95), border_color: Color = Color(0.24, 0.26, 0.31, 0.9), corner_radius: int = 4) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(corner_radius)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func create_active_button_stylebox() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.18, 0.23, 0.32, 0.98)
	sb.border_color = Color(0.30, 0.55, 0.95, 0.95)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb

static func create_slot_stylebox(is_selected: bool = false, quality_border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(3)
	if is_selected:
		sb.set_border_width_all(2)
		sb.bg_color = COLOR_BG_SLOT_SELECTED
		sb.border_color = COLOR_BORDER_SELECTED
		sb.shadow_size = 2
		sb.shadow_color = Color(0.25, 0.55, 0.95, 0.3)
	else:
		sb.set_border_width_all(1)
		sb.bg_color = COLOR_BG_SLOT
		sb.border_color = quality_border if quality_border != Color.TRANSPARENT else COLOR_BORDER_SLOT
	return sb

static var _global_theme_cache: Theme = null
static var _icon_cache_dict: Dictionary = {}

static func get_theme() -> Theme:
	if _global_theme_cache != null:
		return _global_theme_cache
		
	var th := Theme.new()
	
	# Load high-contrast CheckBox icons
	var icon_unchecked = _load_or_create_icon("res://assets/sprites/ui/checkbox_unchecked.png", false, false)
	var icon_unchecked_hover = _load_or_create_icon("res://assets/sprites/ui/checkbox_unchecked_hover.png", false, true)
	var icon_checked = _load_or_create_icon("res://assets/sprites/ui/checkbox_checked.png", true, false)
	var icon_checked_hover = _load_or_create_icon("res://assets/sprites/ui/checkbox_checked_hover.png", true, true)
	var icon_disabled = _load_or_create_icon("res://assets/sprites/ui/checkbox_disabled.png", false, false)

	th.set_icon("unchecked", "CheckBox", icon_unchecked)
	th.set_icon("unchecked_hover", "CheckBox", icon_unchecked_hover)
	th.set_icon("checked", "CheckBox", icon_checked)
	th.set_icon("checked_hover", "CheckBox", icon_checked_hover)
	th.set_icon("unchecked_disabled", "CheckBox", icon_disabled)
	th.set_icon("checked_disabled", "CheckBox", icon_disabled)

	# CheckBox Colors & Spacing (Clean, no neon)
	th.set_color("font_color", "CheckBox", Color(0.90, 0.92, 0.95))
	th.set_color("font_hover_color", "CheckBox", Color(1.0, 1.0, 1.0))
	th.set_color("font_pressed_color", "CheckBox", Color(0.90, 0.92, 0.95))
	th.set_color("font_focus_color", "CheckBox", Color(1.0, 1.0, 1.0))
	th.set_constant("h_separation", "CheckBox", 8)
	th.set_constant("check_v_offset", "CheckBox", 0)

	# Buttons (Modern Studio Slate)
	th.set_stylebox("normal", "Button", create_button_stylebox())
	th.set_stylebox("hover", "Button", create_button_stylebox(Color(0.22, 0.24, 0.29, 0.98), Color(0.38, 0.42, 0.50, 0.95)))
	th.set_stylebox("pressed", "Button", create_button_stylebox(Color(0.13, 0.14, 0.17, 0.98), Color(0.23, 0.51, 0.96, 0.9)))
	th.set_stylebox("disabled", "Button", create_button_stylebox(Color(0.10, 0.11, 0.13, 0.5), Color(0.18, 0.19, 0.22, 0.4)))
	th.set_color("font_color", "Button", Color(0.90, 0.92, 0.95))
	th.set_color("font_hover_color", "Button", Color(1.0, 1.0, 1.0))
	th.set_color("font_pressed_color", "Button", Color(0.60, 0.80, 1.0))

	# PanelContainer
	th.set_stylebox("panel", "PanelContainer", create_panel_stylebox())

	_global_theme_cache = th
	return _global_theme_cache

static func apply_checkbox_style(chk: CheckBox) -> void:
	if not chk: return
	var icon_unchecked = _load_or_create_icon("res://assets/sprites/ui/checkbox_unchecked.png", false, false)
	var icon_unchecked_hover = _load_or_create_icon("res://assets/sprites/ui/checkbox_unchecked_hover.png", false, true)
	var icon_checked = _load_or_create_icon("res://assets/sprites/ui/checkbox_checked.png", true, false)
	var icon_checked_hover = _load_or_create_icon("res://assets/sprites/ui/checkbox_checked_hover.png", true, true)
	
	chk.add_theme_icon_override("unchecked", icon_unchecked)
	chk.add_theme_icon_override("unchecked_hover", icon_unchecked_hover)
	chk.add_theme_icon_override("checked", icon_checked)
	chk.add_theme_icon_override("checked_hover", icon_checked_hover)
	
	chk.add_theme_color_override("font_color", Color(0.90, 0.92, 0.95))
	chk.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	chk.add_theme_color_override("font_pressed_color", Color(0.90, 0.92, 0.95))
	chk.add_theme_constant_override("h_separation", 8)

static func _load_or_create_icon(res_path: String, is_checked: bool, is_hover: bool = false) -> Texture2D:
	if _icon_cache_dict.has(res_path):
		return _icon_cache_dict[res_path]
		
	if ResourceLoader.exists(res_path) or FileAccess.file_exists(res_path):
		var tex = ResourceLoader.load(res_path)
		if tex and tex is Texture2D:
			_icon_cache_dict[res_path] = tex
			return tex

	# Procedural fallback icon generator (20x20)
	var sz := 20
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var border_col := Color(0.38, 0.45, 0.55, 1.0)
	var bg_col := Color(0.11, 0.13, 0.18, 0.95)
	
	if is_checked:
		border_col = Color(0.45, 0.95, 0.65, 1.0) if is_hover else Color(0.20, 0.85, 0.45, 1.0)
		bg_col = Color(0.12, 0.65, 0.35, 1.0) if is_hover else Color(0.08, 0.55, 0.28, 1.0)
	elif is_hover:
		border_col = Color(0.35, 0.75, 1.0, 1.0)
		bg_col = Color(0.15, 0.20, 0.28, 0.98)
		
	for y in range(sz):
		for x in range(sz):
			if (x == 0 or x == sz - 1) and (y == 0 or y == 1 or y == sz - 2 or y == sz - 1): continue
			if (y == 0 or y == sz - 1) and (x == 0 or x == 1 or x == sz - 2 or x == sz - 1): continue
			if x <= 1 or x >= sz - 2 or y <= 1 or y >= sz - 2:
				img.set_pixel(x, y, border_col)
			else:
				img.set_pixel(x, y, bg_col)
				
	if is_checked:
		var points = [
			Vector2i(4, 9), Vector2i(4, 10), Vector2i(4, 11),
			Vector2i(5, 10), Vector2i(5, 11), Vector2i(5, 12),
			Vector2i(6, 11), Vector2i(6, 12), Vector2i(6, 13),
			Vector2i(7, 12), Vector2i(7, 13), Vector2i(7, 14),
			Vector2i(8, 13), Vector2i(8, 14), Vector2i(8, 15),
			Vector2i(9, 12), Vector2i(9, 13), Vector2i(9, 14),
			Vector2i(10, 10), Vector2i(10, 11), Vector2i(10, 12),
			Vector2i(11, 8), Vector2i(11, 9), Vector2i(11, 10),
			Vector2i(12, 6), Vector2i(12, 7), Vector2i(12, 8),
			Vector2i(13, 5), Vector2i(13, 6), Vector2i(13, 7),
			Vector2i(14, 4), Vector2i(14, 5), Vector2i(14, 6),
			Vector2i(15, 3), Vector2i(15, 4), Vector2i(15, 5)
		]
		for p in points:
			if p.x >= 0 and p.x < sz and p.y >= 0 and p.y < sz:
				img.set_pixel(p.x, p.y, Color.WHITE)
				
	var res_tex = ImageTexture.create_from_image(img)
	_icon_cache_dict[res_path] = res_tex
	return res_tex


## --- Centralized Modal Exclusivity & State Coordinator ---

static var MODAL_NAMES: Array[String] = [
	"InventoryUI",
	"QuestUI",
	"JournalUI",
	"CombinationUI",
	"ShopUI",
	"DialogueUI",
	"RelationshipUI",
	"SettingsUI",
	"PauseMenu",
	"SleepConfirmationUI"
]

static func close_all_modals(tree: SceneTree, except_node: Node = null) -> void:
	if not tree or not tree.root:
		return
	for m_name in MODAL_NAMES:
		var node = tree.root.find_child(m_name, true, false)
		if node and is_instance_valid(node) and node != except_node:
			if node.has_method("close_dialogue") and node.visible:
				node.close_dialogue()
			elif node.has_method("close_shop") and node.visible:
				node.close_shop()
			elif node.has_method("close_ui") and node.visible:
				node.close_ui()
			elif node.has_method("close_inventory") and node.visible:
				node.close_inventory()
			elif node.has_method("close_settings") and node.visible:
				node.close_settings()
			elif node.has_method("close_menu") and node.visible:
				node.close_menu()
			elif node.has_method("close") and node.visible:
				node.close()
			elif node.has_method("hide_dialog") and node.visible:
				node.hide_dialog()
			elif "visible" in node and node.visible:
				node.visible = false

static func is_any_modal_open(tree: SceneTree) -> bool:
	if not tree or not tree.root:
		return false
	for m_name in MODAL_NAMES:
		var node = tree.root.find_child(m_name, true, false)
		if node and is_instance_valid(node) and node.visible:
			return true
	return false

static func update_player_lock(tree: SceneTree) -> void:
	if not tree or not tree.root:
		return
	var player = tree.root.find_child("Player", true, false)
	if player and is_instance_valid(player) and player.has_method("set_movement_locked"):
		player.set_movement_locked(is_any_modal_open(tree))
