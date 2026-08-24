class_name UIConstants
extends RefCounted

## Central design constants & StyleBox generators for Cozy Botanical Fantasy theme.

const COLOR_BG_PARCHMENT = Color(0.96, 0.93, 0.86, 0.96) # Warm parchment
const COLOR_BG_DARK_WOOD = Color(0.10, 0.12, 0.16, 0.92) # Cozy dark fantasy slate/wood
const COLOR_BG_CARD = Color(0.09, 0.11, 0.15, 0.88)
const COLOR_BG_PANEL_INNER = Color(0.12, 0.09, 0.06, 0.90)
const COLOR_BG_SLOT = Color(0.12, 0.14, 0.18, 0.85)
const COLOR_BG_SLOT_SELECTED = Color(0.24, 0.28, 0.36, 0.95)

const COLOR_BORDER_WOOD = Color(0.42, 0.28, 0.16) # Rich wood trim
const COLOR_BORDER_GOLD = Color(0.85, 0.68, 0.25) # Golden botanical rim
const COLOR_BORDER_GREEN = Color(0.24, 0.32, 0.28, 0.95) # Botanical forest green
const COLOR_BORDER_SLOT = Color(0.28, 0.32, 0.4, 0.7)
const COLOR_BORDER_SELECTED = Color(1.0, 0.85, 0.2, 1.0)

const COLOR_TEXT_LIGHT = Color(0.95, 0.93, 0.88)
const COLOR_TEXT_DARK = Color(0.20, 0.14, 0.10)
const COLOR_TEXT_GOLD = Color(1.00, 0.85, 0.30)
const COLOR_TEXT_MUTED = Color(0.72, 0.70, 0.65)
const COLOR_TEXT_GREEN = Color(0.55, 0.95, 0.45)
const COLOR_TEXT_ERROR = Color(1.00, 0.45, 0.45)
const COLOR_TEXT_INFO = Color(0.65, 0.85, 1.0, 0.9)

static func create_panel_stylebox(bg_color: Color = COLOR_BG_CARD, border_color: Color = COLOR_BORDER_GREEN, corner_radius: int = 4, border_width: int = 2) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.shadow_size = 4
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	return sb

static func create_button_stylebox(bg_color: Color = Color(0.16, 0.19, 0.25, 0.85), border_color: Color = Color(0.35, 0.4, 0.5, 0.6)) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
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
		sb.shadow_size = 3
		sb.shadow_color = Color(1.0, 0.8, 0.1, 0.35)
	else:
		sb.set_border_width_all(1)
		sb.bg_color = COLOR_BG_SLOT
		sb.border_color = quality_border if quality_border != Color.TRANSPARENT else COLOR_BORDER_SLOT
	return sb

