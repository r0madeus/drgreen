class_name CreditsUI
extends Control

## Data-Driven Credits UI for Botanical Haven.
## Loads credit sections from res://data/credits.json, displays team acknowledgments,
## and provides localized return to Main Menu.

signal closed()

var title_label: Label
var scroll_container: ScrollContainer
var content_vbox: VBoxContainer
var close_button: Button

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()
	_load_and_populate_credits()

func open_credits() -> void:
	visible = true
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var player = root.find_child("Player", true, false) if root else null
	if player and player.has_method("set_movement_locked"):
		player.set_movement_locked(true)


func close_credits() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	var bg = ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.10, 0.14, 0.95)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 420)
	center.add_child(panel)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	title_label = Label.new()
	title_label.text = "🌿 " + tr("ui.credits.title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = SIZE_EXPAND_FILL
	scroll_container.custom_minimum_size = Vector2(450, 280)
	vbox.add_child(scroll_container)

	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 14)
	scroll_container.add_child(content_vbox)

	close_button = Button.new()
	close_button.text = tr("ui.credits.close")
	close_button.pressed.connect(close_credits)
	vbox.add_child(close_button)

func _load_and_populate_credits() -> void:
	var path = "res://data/credits.json"
	if not FileAccess.file_exists(path): return
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return
	var text = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY: return

	var sections = json.data.get("sections", [])
	for s in sections:
		var role = str(s.get("role", ""))
		var members = s.get("members", [])

		var sec_vbox = VBoxContainer.new()
		
		var role_lbl = Label.new()
		role_lbl.text = "✦ " + role
		role_lbl.modulate = Color(0.9, 0.8, 0.4)
		sec_vbox.add_child(role_lbl)

		for m in members:
			var m_lbl = Label.new()
			m_lbl.text = "    " + str(m)
			m_lbl.modulate = Color(0.85, 0.85, 0.9)
			sec_vbox.add_child(m_lbl)

		content_vbox.add_child(sec_vbox)
