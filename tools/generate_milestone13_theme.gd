@tool
extends SceneTree

func _init() -> void:
	generate_ui_system()
	quit()

static func generate_ui_system() -> void:
	DirAccess.make_dir_recursive_absolute("res://ui/theme")
	DirAccess.make_dir_recursive_absolute("res://assets/sprites/ui")

	# 1. Generate 16x16 Pixel-Art UI Icons
	var icons = [
		{ "name": "icon_inventory", "c1": Color("8c5e37"), "c2": Color("d4a359") },
		{ "name": "icon_lab", "c1": Color("2a9d8f"), "c2": Color("a8dadc") },
		{ "name": "icon_journal", "c1": Color("3a5a40"), "c2": Color("a3b18a") },
		{ "name": "icon_quest", "c1": Color("e76f51"), "c2": Color("f4a261") },
		{ "name": "icon_shop", "c1": Color("e9c46a"), "c2": Color("f4a261") },
		{ "name": "icon_save", "c1": Color("457b9d"), "c2": Color("a8dadc") },
		{ "name": "icon_load", "c1": Color("1d3557"), "c2": Color("457b9d") },
		{ "name": "icon_settings", "c1": Color("6c757d"), "c2": Color("adb5bd") },
		{ "name": "icon_gold", "c1": Color("ffb703"), "c2": Color("fb8500") },
		{ "name": "icon_day", "c1": Color("588157"), "c2": Color("dad7cd") }
	]

	for ic in icons:
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var c1: Color = ic["c1"]
		var c2: Color = ic["c2"]
		# Outer frame
		for y in range(3, 13):
			for x in range(3, 13):
				img.set_pixel(x, y, c1)
		# Inner trim
		for y in range(5, 11):
			for x in range(5, 11):
				img.set_pixel(x, y, c2)
		# Highlight
		img.set_pixel(6, 6, Color.WHITE)
		img.save_png("res://assets/sprites/ui/%s.png" % ic["name"])

	# 2. UI Style Constants: res://ui/theme/ui_constants.gd
	var const_code = """class_name UIConstants
extends RefCounted

## Central design constants for Cozy Botanical Fantasy theme.

const COLOR_BG_PARCHMENT = Color(0.96, 0.93, 0.86, 0.96) # Warm parchment
const COLOR_BG_DARK_WOOD = Color(0.18, 0.12, 0.08, 0.94) # Dark walnut wood
const COLOR_BG_PANEL_INNER = Color(0.12, 0.09, 0.06, 0.90)

const COLOR_BORDER_WOOD = Color(0.42, 0.28, 0.16) # Rich wood trim
const COLOR_BORDER_GOLD = Color(0.85, 0.68, 0.25) # Golden botanical rim
const COLOR_BORDER_GREEN = Color(0.24, 0.42, 0.22) # Botanical forest green

const COLOR_TEXT_LIGHT = Color(0.95, 0.93, 0.88)
const COLOR_TEXT_DARK = Color(0.20, 0.14, 0.10)
const COLOR_TEXT_GOLD = Color(1.00, 0.85, 0.30)
const COLOR_TEXT_MUTED = Color(0.72, 0.70, 0.65)
const COLOR_TEXT_GREEN = Color(0.55, 0.95, 0.45)
const COLOR_TEXT_ERROR = Color(1.00, 0.45, 0.45)
const COLOR_TEXT_INFO = Color(0.55, 0.80, 1.00)

static func create_panel_stylebox(bg_color: Color = COLOR_BG_DARK_WOOD, border_color: Color = COLOR_BORDER_GOLD, corner_radius: int = 4, border_width: int = 2) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(corner_radius)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func create_button_stylebox(bg_color: Color, border_color: Color = COLOR_BORDER_GOLD) -> StyleBoxFlat:
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
"""
	var f_c = FileAccess.open("res://ui/theme/ui_constants.gd", FileAccess.WRITE)
	if f_c:
		f_c.store_string(const_code)
		f_c.close()

	# 3. Create res://milestone13_ui_audit.md
	var audit_text = """# Milestone 13 UI/UX Audit Report

## 1. Executive Summary
An in-depth audit of all UI components (HUD, Inventory, Combination/Lab, Codex/Journal, Quest Log, Shop, Dialogue, Greenhouse, Time/Weather) was conducted.

## 2. Issues Identified
1. **Inconsistent Visual Language**: Mix of plain flat panels, differing border widths, and mismatched margins across modal windows.
2. **Text Readability & Padding**: Several buttons had cramped text padding and low contrast on bright background tiles.
3. **Emoji Overuse**: Headers used placeholder unicode characters instead of structured thematic icons.
4. **Modal Exclusivity & ESC Handling**: Modals handled ESC independently, risking overlapping window states.
5. **Missing Unified Theme**: Godot Theme resource was absent, leading to scattered style overrides in `.tscn` files.

## 3. Unification Plan
- Introduce centralized `UIConstants` and Godot `Theme` resource.
- Standardize all modal headers with uniform close button, gold title, and dark walnut backdrop.
- Implement unified `PauseMenu` with Master/SFX/Music audio sliders and Save/Load.
- Provide smooth micro-animations for open/close and hover states.
"""
	var f_a = FileAccess.open("res://milestone13_ui_audit.md", FileAccess.WRITE)
	if f_a:
		f_a.store_string(audit_text)
		f_a.close()

	print("[Milestone13ThemeGenerator] Generated UI constants, icons, and audit report!")
