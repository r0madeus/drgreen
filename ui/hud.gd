class_name HUD
extends Control

## Polished Stardew-Style Game HUD with Top-Left World/Time Card, Top-Right Stats/Quick Actions Card, and Bottom-Center 10-Slot Hotbar.

@export var grid_manager: GridManager
@export var inventory_ui: InventoryUI
@export var combination_ui: CombinationUI
@export var journal_ui: JournalUI
@export var quest_ui: QuestUI

var current_day: int = 1

# UI Nodes
var top_left_card: PanelContainer
var loc_label: Label
var date_label: Label
var weather_label: Label

var top_right_card: PanelContainer
var gold_label: Label
var stamina_bar: ProgressBar
var stamina_label: Label
var quick_buttons: Dictionary = {}

var hotbar_ui: HotbarUI

func _ready() -> void:
	# Configure root HUD to span the full viewport with ignore filter
	theme = UIConstants.get_theme()
	anchors_preset = PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH
	mouse_filter = MOUSE_FILTER_IGNORE
	
	if not grid_manager:
		grid_manager = get_tree().root.find_child("GridManager", true, false) as GridManager
	if not inventory_ui and get_parent():
		inventory_ui = get_parent().get_node_or_null("InventoryUI") as InventoryUI
	if not combination_ui and get_parent():
		combination_ui = get_parent().get_node_or_null("CombinationUI") as CombinationUI
	if not journal_ui and get_parent():
		journal_ui = get_parent().get_node_or_null("JournalUI") as JournalUI
	if not quest_ui and get_parent():
		quest_ui = get_parent().get_node_or_null("QuestUI") as QuestUI
		
	_create_top_left_card()
	_create_top_right_card()
	_create_hotbar()
	
	_connect_managers()
	
	update_day_display()
	update_gold_display()
	update_stamina_display()

func _create_top_left_card() -> void:
	top_left_card = PanelContainer.new()
	top_left_card.name = "TopLeftCard"
	top_left_card.set_anchors_preset(PRESET_TOP_LEFT)
	top_left_card.position = Vector2(20, 16)
	top_left_card.mouse_filter = MOUSE_FILTER_PASS
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.15, 0.90)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.24, 0.32, 0.28, 0.95)
	sb.set_corner_radius_all(5)
	sb.shadow_size = 5
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	top_left_card.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	top_left_card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	margin.add_child(vbox)
	
	# Location Badge
	loc_label = Label.new()
	loc_label.add_theme_font_size_override("font_size", 14)
	loc_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
	loc_label.text = "📍 Peaceful Farm"
	vbox.add_child(loc_label)
	
	# Date & Season
	date_label = Label.new()
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 0.9))
	date_label.text = "📅 Day 1 • Spring"
	vbox.add_child(date_label)
	
	# Weather & Clock
	weather_label = Label.new()
	weather_label.add_theme_font_size_override("font_size", 12)
	weather_label.add_theme_color_override("font_color", Color(0.65, 0.85, 1.0, 0.9))
	weather_label.text = "☀️ Clear • 06:00 AM"
	vbox.add_child(weather_label)
	
	add_child(top_left_card)

func _create_top_right_card() -> void:
	top_right_card = PanelContainer.new()
	top_right_card.name = "TopRightCard"
	top_right_card.set_anchors_preset(PRESET_TOP_RIGHT)
	top_right_card.anchor_left = 1.0
	top_right_card.anchor_right = 1.0
	top_right_card.anchor_top = 0.0
	top_right_card.anchor_bottom = 0.0
	top_right_card.grow_horizontal = GROW_DIRECTION_BEGIN
	top_right_card.grow_vertical = GROW_DIRECTION_END
	top_right_card.offset_right = -20
	top_right_card.offset_top = 16
	top_right_card.offset_left = -280
	top_right_card.mouse_filter = MOUSE_FILTER_PASS

	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.11, 0.15, 0.90)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.32, 0.28, 0.22, 0.95)
	sb.set_corner_radius_all(5)
	sb.shadow_size = 5
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	top_right_card.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	top_right_card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)
	
	# Top Line: Gold & Stamina Header
	var stats_hbox = HBoxContainer.new()
	stats_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(stats_hbox)
	
	# Gold Display
	gold_label = Label.new()
	gold_label.add_theme_font_size_override("font_size", 14)
	gold_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	gold_label.text = "🪙 100 G"
	stats_hbox.add_child(gold_label)
	
	# Stamina Label
	stamina_label = Label.new()
	stamina_label.add_theme_font_size_override("font_size", 12)
	stamina_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6, 1.0))
	stamina_label.text = "⚡ 100 / 100"
	stamina_label.size_flags_horizontal = SIZE_EXPAND_FILL
	stamina_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_hbox.add_child(stamina_label)
	
	# Stamina Progress Bar
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(230, 8)
	stamina_bar.show_percentage = false
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.18, 0.2, 0.8)
	bar_bg.set_corner_radius_all(3)
	stamina_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.2, 0.85, 0.45, 0.95)
	bar_fill.set_corner_radius_all(3)
	stamina_bar.add_theme_stylebox_override("fill", bar_fill)
	vbox.add_child(stamina_bar)
	
	# Compact Action Buttons Bar
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 4)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_hbox)
	
	_add_quick_btn(btn_hbox, "bag", "🎒 Bag [I]", "Bag (I)", toggle_inventory)
	_add_quick_btn(btn_hbox, "quest", "📜 Quests [Q]", "Quests (Q)", toggle_quest)
	_add_quick_btn(btn_hbox, "journal", "📖 Codex [J]", "Codex (J)", toggle_journal)
	_add_quick_btn(btn_hbox, "lab", "⚗️ Lab [C]", "Lab (C)", toggle_lab)
	_add_quick_btn(btn_hbox, "day", "⏩ Sleep [T]", "Next Day (T)", advance_day)
	_add_quick_btn(btn_hbox, "menu", "⚙️ Menu [Esc]", "Menu (Esc)", toggle_pause_menu)
	
	add_child(top_right_card)

func _add_quick_btn(container: HBoxContainer, btn_key: String, title: String, tooltip: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = title
	btn.tooltip_text = tooltip
	btn.custom_minimum_size = Vector2(34, 24)
	btn.add_theme_font_size_override("font_size", 11)
	btn.mouse_filter = MOUSE_FILTER_STOP
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.16, 0.19, 0.25, 0.85)
	btn_style.set_border_width_all(1)
	btn_style.border_color = Color(0.35, 0.4, 0.5, 0.6)
	btn_style.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", btn_style)
	
	var hover_style = btn_style.duplicate()
	hover_style.bg_color = Color(0.25, 0.3, 0.4, 0.95)
	hover_style.border_color = Color(1.0, 0.85, 0.2, 0.8)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	btn.pressed.connect(callback)
	container.add_child(btn)
	quick_buttons[btn_key] = btn
	return btn

func _create_hotbar() -> void:
	hotbar_ui = HotbarUI.new()
	hotbar_ui.name = "HotbarUI"
	add_child(hotbar_ui)

func _connect_managers() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.day_started.connect(func(_d): update_day_display())
		tm.time_changed.connect(func(_m, _t): update_time_display())
		tm.day_phase_changed.connect(func(_o, _n): update_time_display())
		
	var sm = get_node_or_null("/root/SeasonManager")
	if sm: sm.season_changed.connect(func(_o, _n): update_day_display())
		
	var wm = get_node_or_null("/root/WeatherManager")
	if wm: wm.weather_changed.connect(func(_o, _n): update_day_display())
		
		
	var eb = get_node_or_null("/root/EventBus")
	if eb: eb.world_changed.connect(func(_wid, _wdata = {}): _bind_and_refresh())
	
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(func(_l): 
			update_day_display()
			update_gold_display()
			update_stamina_display()
			_update_quick_buttons()
		)
	
	
	_bind_player_state()

func _update_quick_buttons() -> void:
	if quick_buttons.has("bag"): quick_buttons["bag"].text = tr("ui.hud.btn.bag")
	if quick_buttons.has("quest"): quick_buttons["quest"].text = tr("ui.hud.btn.quest")
	if quick_buttons.has("journal"): quick_buttons["journal"].text = tr("ui.hud.btn.journal")
	if quick_buttons.has("lab"): quick_buttons["lab"].text = tr("ui.hud.btn.lab")
	if quick_buttons.has("day"): quick_buttons["day"].text = tr("ui.hud.btn.day")
	if quick_buttons.has("menu"): quick_buttons["menu"].text = tr("ui.hud.btn.menu")

func _get_local_state() -> PlayerState:
	if not is_inside_tree(): return null
	var player = get_tree().get_first_node_in_group("local_player")
	if player and "player_state" in player: return player.player_state
	return null

func _bind_and_refresh() -> void:
	_bind_player_state()
	update_day_display()
	update_stamina_display()
	update_gold_display()

func _bind_player_state() -> void:
	var p_state = _get_local_state()
	if p_state:
		if not p_state.energy_changed.is_connected(_on_energy_changed):
			p_state.energy_changed.connect(_on_energy_changed)
		if not p_state.gold_changed.is_connected(func(_g): update_gold_display()):
			p_state.gold_changed.connect(func(_g): update_gold_display())

func _on_energy_changed(_cur: float, _max_val: float) -> void:
	update_stamina_display()

func advance_day() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	if tm:
		tm.request_sleep()
	else:
		current_day += 1
		update_day_display()

func update_time_display() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	var wm = get_node_or_null("/root/WeatherManager")
	var lm = get_node_or_null("/root/LocalizationManager")
	
	var w_icon = wm.get_weather_icon() if wm else "☀️"
	var w_raw = wm.current_weather if wm else "clear"
	var w_name = lm.get_weather_name(str(w_raw)) if lm else str(w_raw).capitalize()
	var time_str = tm.get_time_formatted() if (tm and tm.has_method("get_time_formatted")) else "06:00 AM"
	
	if weather_label:
		if lm:
			weather_label.text = "%s " % w_icon + lm.format("ui.hud.weather_time", { "weather": w_name, "time": time_str })
		else:
			weather_label.text = "%s %s • %s" % [w_icon, w_name, time_str]

func update_day_display() -> void:
	var tm = get_node_or_null("/root/TimeManager")
	var sm = get_node_or_null("/root/SeasonManager")
	var wl = get_node_or_null("/root/WorldLoader")
	var lm = get_node_or_null("/root/LocalizationManager")
	
	var d = tm.get_current_day() if tm else current_day
	var s_raw = sm.get_season_id() if sm else "spring"
	var s_name = lm.get_season_name(str(s_raw)) if lm else str(s_raw).capitalize()
	var cur_world = wl.current_world_id if wl else "farm"
	var loc_name = lm.get_world_name(cur_world) if lm else "Peaceful Farm"
	
	if loc_label: loc_label.text = "📍 %s" % loc_name
	if date_label: 
		if lm:
			date_label.text = "📅 " + lm.format("ui.hud.day_season", { "day": d, "season": s_name })
		else:
			date_label.text = "📅 Day %d • %s" % [d, s_name]
	update_time_display()


func update_gold_display() -> void:
	var em = get_node_or_null("/root/EconomyManager")
	var _lp = get_tree().get_first_node_in_group("local_player")
	var pid = _lp.player_id if _lp and "player_id" in _lp else "player_001"
	var gold = em.get_gold(pid) if em else 100
	var lm = get_node_or_null("/root/LocalizationManager")
	if gold_label:
		if lm: gold_label.text = "🪙 " + lm.format("ui.hud.gold", { "gold": gold })
		else: gold_label.text = "🪙 %d G" % gold

func update_stamina_display() -> void:
	var p_state = _get_local_state()
	var cur = p_state.energy if p_state else 100.0
	var max_val = p_state.max_energy if p_state else 100.0
	var lm = get_node_or_null("/root/LocalizationManager")
	
	if stamina_bar:
		stamina_bar.max_value = max_val
		stamina_bar.value = cur
	if stamina_label:
		if lm: stamina_label.text = lm.format("ui.hud.stamina_format", { "cur": int(cur), "max": int(max_val) })
		else: stamina_label.text = "⚡ %d / %d" % [int(cur), int(max_val)]


func toggle_inventory() -> void:
	if not inventory_ui: inventory_ui = get_tree().root.find_child("InventoryUI", true, false)
	if inventory_ui: inventory_ui.toggle_visibility()

func toggle_lab() -> void:
	if not combination_ui: combination_ui = get_tree().root.find_child("CombinationUI", true, false)
	if combination_ui: combination_ui.toggle_visibility()

func toggle_journal() -> void:
	if not journal_ui: journal_ui = get_tree().root.find_child("JournalUI", true, false)
	if journal_ui: journal_ui.toggle_visibility()

func toggle_quest() -> void:
	if not quest_ui: quest_ui = get_tree().root.find_child("QuestUI", true, false)
	if quest_ui: quest_ui.toggle_visibility()

func toggle_pause_menu() -> void:
	var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
	if pause_menu and pause_menu.has_method("toggle_menu"):
		pause_menu.toggle_menu()
	elif pause_menu and pause_menu.has_method("toggle_pause"):
		pause_menu.toggle_pause()
	elif pause_menu:
		pause_menu.visible = not pause_menu.visible
