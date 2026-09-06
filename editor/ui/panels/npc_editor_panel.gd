class_name NPCEditorPanel
extends EditorPanel

## In-Game NPC & Schedule Editor for Botanical Haven (Phase 29).
## Provides dynamic NPC management, character appearance customization via AssetRegistry,
## visual daily schedule timeline editing, location/waypoint routing, weather/social variants,
## overlap/integrity validation, and live runtime playtest simulation.

signal npc_selected(npc_id: String)
signal npc_playtest_requested(npc_id: String)
signal switch_to_world_editor(world_id: String)

var current_npc_id: String = "rowan"
var current_npc_data: Dictionary = {}
var current_schedule_data: Dictionary = {}
var current_social_data: Dictionary = {}

var selected_schedule_idx: int = 0
var selected_weather_variant: String = "default"
var preview_minute: int = 540 # Default to 09:00

# UI Controls
var npc_list_container: VBoxContainer
var schedule_list_container: VBoxContainer
var preview_sprite: Sprite2D
var preview_name_label: Label
var preview_activity_label: Label
var time_scrubber_slider: HSlider
var time_display_label: Label

# Inspector UI Fields
var id_edit: LineEdit
var display_name_edit: LineEdit
var role_edit: LineEdit
var world_opt: OptionButton
var home_loc_opt: OptionButton
var shop_edit: LineEdit
var dialogue_edit: LineEdit
var sprite_edit: LineEdit
var portrait_edit: LineEdit

# Schedule Inspector Fields
var entry_start_spin: SpinBox
var entry_end_spin: SpinBox
var entry_activity_opt: OptionButton
var entry_location_opt: OptionButton
var entry_priority_spin: SpinBox
var entry_weather_opt: OptionButton

# Social Inspector Fields
var friends_edit: LineEdit
var social_locs_edit: LineEdit
var talkative_spin: SpinBox

# Status labels
var status_world_label: Label
var status_changes_label: Label
var validation_status_label: Label

const SUPPORTED_ACTIVITIES = [
	"home", "work", "eat", "rest", "sit", "shop",
	"sleep", "wander", "social", "talk", "idle", "travel"
]

const SUPPORTED_WORLDS = ["farm", "town", "forest", "botanical_grove", "greenhouse"]

func _init() -> void:
	super._init("npc", "ui.editor.cat_npc", "icon_npc")

func setup(p_service: Variant) -> void:
	super.setup(p_service)
	_build_ui()
	_load_npc_list()
	_select_npc(current_npc_id)

func open_panel() -> void:
	super.open_panel()
	refresh()

func refresh() -> void:
	_load_npc_list()
	_select_npc(current_npc_id)

func _build_ui() -> void:
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(PRESET_FULL_RECT)
	main_vbox.grow_horizontal = GROW_DIRECTION_BOTH
	main_vbox.grow_vertical = GROW_DIRECTION_BOTH
	add_child(main_vbox)

	# --- TOP TOOLBAR ---
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(0, 40)
	main_vbox.add_child(top_bar)

	var top_hbox = HBoxContainer.new()
	top_bar.add_child(top_hbox)

	var top_title = Label.new()
	top_title.text = " In-Game NPC & Schedule Editor"
	top_title.add_theme_font_size_override("font_size", 13)
	top_title.modulate = Color(0.92, 0.94, 0.98)
	top_hbox.add_child(top_title)

	top_hbox.add_spacer(false)

	var add_npc_btn = Button.new()
	add_npc_btn.text = " Add NPC"
	add_npc_btn.pressed.connect(_on_add_new_npc)
	top_hbox.add_child(add_npc_btn)

	var dup_npc_btn = Button.new()
	dup_npc_btn.text = " Duplicate NPC"
	dup_npc_btn.pressed.connect(_on_duplicate_npc)
	top_hbox.add_child(dup_npc_btn)

	var sep1 = VSeparator.new()
	top_hbox.add_child(sep1)

	var route_btn = Button.new()
	route_btn.text = " Route in World"
	route_btn.pressed.connect(_on_view_in_world_editor)
	top_hbox.add_child(route_btn)

	var test_btn = Button.new()
	test_btn.text = " Test NPC"
	test_btn.pressed.connect(_on_playtest_npc)
	top_hbox.add_child(test_btn)

	# --- 3-COLUMN WORKSPACE ---
	var mid_hbox = HBoxContainer.new()
	mid_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(mid_hbox)

	# 1. LEFT: NPC List
	var left_panel = PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(170, 0)
	mid_hbox.add_child(left_panel)

	var left_vbox = VBoxContainer.new()
	left_panel.add_child(left_vbox)

	var list_title = Label.new()
	list_title.text = "NPC Characters"
	list_title.add_theme_font_size_override("font_size", 12)
	left_vbox.add_child(list_title)

	var left_scroll = ScrollContainer.new()
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(left_scroll)

	npc_list_container = VBoxContainer.new()
	npc_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.add_child(npc_list_container)

	# 2. CENTER: Preview & Schedule Timeline
	var center_panel = PanelContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_hbox.add_child(center_panel)

	var center_vbox = VBoxContainer.new()
	center_panel.add_child(center_vbox)

	# Center Preview Header (Sprite Preview & Time Scrubber)
	var char_prev_panel = PanelContainer.new()
	char_prev_panel.custom_minimum_size = Vector2(0, 100)
	center_vbox.add_child(char_prev_panel)

	var char_hbox = HBoxContainer.new()
	char_prev_panel.add_child(char_hbox)

	var sprite_box = Control.new()
	sprite_box.custom_minimum_size = Vector2(80, 80)
	char_hbox.add_child(sprite_box)

	preview_sprite = Sprite2D.new()
	preview_sprite.position = Vector2(40, 40)
	preview_sprite.scale = Vector2(2.0, 2.0)
	sprite_box.add_child(preview_sprite)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	char_hbox.add_child(info_vbox)

	preview_name_label = Label.new()
	preview_name_label.text = "Rowan the Herbalist"
	preview_name_label.add_theme_font_size_override("font_size", 14)
	preview_name_label.modulate = Color(0.8, 1.0, 0.8)
	info_vbox.add_child(preview_name_label)

	preview_activity_label = Label.new()
	preview_activity_label.text = "Activity: work | Location: seed_shop | World: farm"
	preview_activity_label.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(preview_activity_label)

	# Time Scrubber Controls
	var scrub_hbox = HBoxContainer.new()
	info_vbox.add_child(scrub_hbox)

	var scrub_lbl = Label.new()
	scrub_lbl.text = " Time:"
	scrub_lbl.add_theme_font_size_override("font_size", 11)
	scrub_hbox.add_child(scrub_lbl)

	time_scrubber_slider = HSlider.new()
	time_scrubber_slider.min_value = 360 # 06:00
	time_scrubber_slider.max_value = 1440 # 24:00
	time_scrubber_slider.step = 30
	time_scrubber_slider.value = preview_minute
	time_scrubber_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_scrubber_slider.value_changed.connect(_on_time_scrub_changed)
	scrub_hbox.add_child(time_scrubber_slider)

	time_display_label = Label.new()
	time_display_label.text = "09:00"
	time_display_label.add_theme_font_size_override("font_size", 12)
	time_display_label.modulate = Color(1.0, 0.9, 0.4)
	scrub_hbox.add_child(time_display_label)

	# Timeline Title & Actions
	var sched_header_hbox = HBoxContainer.new()
	center_vbox.add_child(sched_header_hbox)

	var sched_title = Label.new()
	sched_title.text = "Daily Schedule Timeline"
	sched_title.add_theme_font_size_override("font_size", 13)
	sched_header_hbox.add_child(sched_title)

	sched_header_hbox.add_spacer(false)

	var add_act_btn = Button.new()
	add_act_btn.text = " Add Activity"
	add_act_btn.pressed.connect(_on_add_schedule_entry)
	sched_header_hbox.add_child(add_act_btn)

	var del_act_btn = Button.new()
	del_act_btn.text = " Delete"
	del_act_btn.pressed.connect(_on_delete_schedule_entry)
	sched_header_hbox.add_child(del_act_btn)

	var up_act_btn = Button.new()
	up_act_btn.text = " Up"
	up_act_btn.pressed.connect(func(): _move_schedule_entry(-1))
	sched_header_hbox.add_child(up_act_btn)

	var down_act_btn = Button.new()
	down_act_btn.text = " Down"
	down_act_btn.pressed.connect(func(): _move_schedule_entry(1))
	sched_header_hbox.add_child(down_act_btn)

	# Schedule List Scroll
	var sched_scroll = ScrollContainer.new()
	sched_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_vbox.add_child(sched_scroll)

	schedule_list_container = VBoxContainer.new()
	schedule_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sched_scroll.add_child(schedule_list_container)

	# 3. RIGHT: Inspector Tabs (Identity, Schedule Entry, Social, Appearance)
	var right_panel = PanelContainer.new()
	right_panel.custom_minimum_size = Vector2(280, 0)
	mid_hbox.add_child(right_panel)

	var right_tabs = TabContainer.new()
	right_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(right_tabs)

	# Tab 1: Identity
	var id_scroll = ScrollContainer.new()
	id_scroll.name = "Identity"
	right_tabs.add_child(id_scroll)

	var id_vbox = VBoxContainer.new()
	id_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_scroll.add_child(id_vbox)

	_build_identity_tab(id_vbox)

	# Tab 2: Activity Editor
	var act_scroll = ScrollContainer.new()
	act_scroll.name = "Activity"
	right_tabs.add_child(act_scroll)

	var act_vbox = VBoxContainer.new()
	act_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_scroll.add_child(act_vbox)

	_build_activity_tab(act_vbox)

	# Tab 3: Social & Weather
	var soc_scroll = ScrollContainer.new()
	soc_scroll.name = "Social & Weather"
	right_tabs.add_child(soc_scroll)

	var soc_vbox = VBoxContainer.new()
	soc_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	soc_scroll.add_child(soc_vbox)

	_build_social_tab(soc_vbox)

	# --- BOTTOM STATUS BAR ---
	var bottom_bar = PanelContainer.new()
	bottom_bar.custom_minimum_size = Vector2(0, 26)
	main_vbox.add_child(bottom_bar)

	var bottom_hbox = HBoxContainer.new()
	bottom_bar.add_child(bottom_hbox)

	status_world_label = Label.new()
	status_world_label.text = "World: Farm"
	status_world_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_world_label)

	bottom_hbox.add_spacer(false)

	status_changes_label = Label.new()
	status_changes_label.text = "Changes: 0"
	status_changes_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(status_changes_label)

	bottom_hbox.add_spacer(false)

	validation_status_label = Label.new()
	validation_status_label.text = "Validation: OK"
	validation_status_label.modulate = Color(0.4, 0.9, 0.4)
	validation_status_label.add_theme_font_size_override("font_size", 11)
	bottom_hbox.add_child(validation_status_label)

func _build_identity_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("NPC ID:"))
	id_edit = LineEdit.new()
	id_edit.text_submitted.connect(func(t): _on_npc_field_changed("id", t))
	container.add_child(id_edit)

	container.add_child(_create_field_label("Display Name:"))
	display_name_edit = LineEdit.new()
	display_name_edit.text_changed.connect(func(t): _on_npc_field_changed("display_name", t))
	container.add_child(display_name_edit)

	container.add_child(_create_field_label("Role:"))
	role_edit = LineEdit.new()
	role_edit.text_changed.connect(func(t): _on_npc_field_changed("role", t))
	container.add_child(role_edit)

	container.add_child(_create_field_label("Home World:"))
	world_opt = OptionButton.new()
	for i in range(SUPPORTED_WORLDS.size()):
		world_opt.add_item(SUPPORTED_WORLDS[i].capitalize(), i)
	world_opt.item_selected.connect(func(idx): _on_npc_field_changed("world", SUPPORTED_WORLDS[idx]))
	container.add_child(world_opt)

	container.add_child(_create_field_label("Home Location:"))
	home_loc_opt = OptionButton.new()
	_populate_location_options(home_loc_opt)
	home_loc_opt.item_selected.connect(func(idx): _on_npc_field_changed("home_location", home_loc_opt.get_item_text(idx)))
	container.add_child(home_loc_opt)

	container.add_child(_create_field_label("Dialogue ID:"))
	dialogue_edit = LineEdit.new()
	dialogue_edit.text_changed.connect(func(t): _on_npc_field_changed("dialogue_id", t))
	container.add_child(dialogue_edit)

	container.add_child(_create_field_label("Shop ID:"))
	shop_edit = LineEdit.new()
	shop_edit.text_changed.connect(func(t): _on_npc_field_changed("shop_id", t))
	container.add_child(shop_edit)

	container.add_child(_create_field_label("Sprite Name (AssetRegistry):"))
	sprite_edit = LineEdit.new()
	sprite_edit.text_changed.connect(func(t): _on_npc_field_changed("sprite", t))
	container.add_child(sprite_edit)

	var reset_npc_btn = Button.new()
	reset_npc_btn.text = "↺ Reset NPC to Default"
	reset_npc_btn.pressed.connect(reset_current_npc)
	container.add_child(reset_npc_btn)

func _build_activity_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("Start Minute (e.g. 540 = 09:00):"))
	entry_start_spin = SpinBox.new()
	entry_start_spin.min_value = 0
	entry_start_spin.max_value = 1440
	entry_start_spin.step = 15
	entry_start_spin.value_changed.connect(func(v): _on_schedule_prop_changed("start_minute", int(v)))
	container.add_child(entry_start_spin)

	container.add_child(_create_field_label("End Minute (e.g. 750 = 12:30):"))
	entry_end_spin = SpinBox.new()
	entry_end_spin.min_value = 0
	entry_end_spin.max_value = 1440
	entry_end_spin.step = 15
	entry_end_spin.value_changed.connect(func(v): _on_schedule_prop_changed("end_minute", int(v)))
	container.add_child(entry_end_spin)

	container.add_child(_create_field_label("Activity Type:"))
	entry_activity_opt = OptionButton.new()
	for i in range(SUPPORTED_ACTIVITIES.size()):
		entry_activity_opt.add_item(SUPPORTED_ACTIVITIES[i].capitalize(), i)
	entry_activity_opt.item_selected.connect(func(idx): _on_schedule_prop_changed("activity", SUPPORTED_ACTIVITIES[idx]))
	container.add_child(entry_activity_opt)

	container.add_child(_create_field_label("Target Location:"))
	entry_location_opt = OptionButton.new()
	_populate_location_options(entry_location_opt)
	entry_location_opt.item_selected.connect(func(idx): _on_schedule_prop_changed("location_id", entry_location_opt.get_item_text(idx)))
	container.add_child(entry_location_opt)

	container.add_child(_create_field_label("Priority (1 to 5):"))
	entry_priority_spin = SpinBox.new()
	entry_priority_spin.min_value = 1
	entry_priority_spin.max_value = 5
	entry_priority_spin.value = 2
	entry_priority_spin.value_changed.connect(func(v): _on_schedule_prop_changed("priority", int(v)))
	container.add_child(entry_priority_spin)

	var reset_sched_btn = Button.new()
	reset_sched_btn.text = "↺ Reset Schedule to Default"
	reset_sched_btn.pressed.connect(reset_schedule)
	container.add_child(reset_sched_btn)

func _build_social_tab(container: VBoxContainer) -> void:
	container.add_child(_create_field_label("Weather Variant:"))
	entry_weather_opt = OptionButton.new()
	var weathers = ["default", "rain", "storm", "snow"]
	for i in range(weathers.size()):
		entry_weather_opt.add_item(weathers[i].capitalize(), i)
	entry_weather_opt.item_selected.connect(func(idx):
		selected_weather_variant = weathers[idx]
		_refresh_schedule_timeline()
	)
	container.add_child(entry_weather_opt)

	var sep = HSeparator.new()
	container.add_child(sep)

	container.add_child(_create_field_label("Friends (comma separated IDs):"))
	friends_edit = LineEdit.new()
	friends_edit.text_changed.connect(_on_social_friends_changed)
	container.add_child(friends_edit)

	container.add_child(_create_field_label("Social Gathering Locations:"))
	social_locs_edit = LineEdit.new()
	social_locs_edit.text_changed.connect(_on_social_locations_changed)
	container.add_child(social_locs_edit)

	container.add_child(_create_field_label("Talkative Chance (0.0 - 1.0):"))
	talkative_spin = SpinBox.new()
	talkative_spin.min_value = 0.0
	talkative_spin.max_value = 1.0
	talkative_spin.step = 0.05
	talkative_spin.value_changed.connect(func(v): _on_social_field_changed("talkative_chance", v))
	container.add_child(talkative_spin)

func _create_field_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.modulate = Color(0.8, 0.8, 0.8)
	return l

func _populate_location_options(opt: OptionButton) -> void:
	if not opt: return
	opt.clear()
	var loc_ids: Array[String] = []
	if editor_service and editor_service.data_service:
		var all_loc_keys = editor_service.data_service.get_all_stable_ids("location.")
		for k in all_loc_keys:
			loc_ids.append(k.replace("location.", ""))
	if loc_ids.is_empty():
		loc_ids = ["rowan_home", "seed_shop", "farm_porch", "town_square", "elias_home", "elias_shop", "mira_grove_lab"]
	for i in range(loc_ids.size()):
		opt.add_item(loc_ids[i], i)

func _load_npc_list() -> void:
	if not npc_list_container: return
	for c in npc_list_container.get_children(): c.queue_free()

	var npc_ids: Array[String] = []
	if editor_service and editor_service.data_service:
		var keys = editor_service.data_service.get_all_stable_ids("npc.")
		for k in keys:
			npc_ids.append(k.replace("npc.", ""))

	if npc_ids.is_empty():
		npc_ids = ["rowan", "elias", "mira"]

	for nid in npc_ids:
		var btn = Button.new()
		var is_overridden = editor_service.data_service.has_override("npc." + nid) if editor_service else false
		btn.text = (" " if is_overridden else "") + nid.capitalize()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _select_npc(nid))
		if nid == current_npc_id:
			btn.modulate = Color(0.7, 1.0, 0.7)
		npc_list_container.add_child(btn)

func _select_npc(nid: String) -> void:
	current_npc_id = nid
	selected_schedule_idx = 0
	
	if editor_service and editor_service.data_service:
		current_npc_data = editor_service.data_service.get_resolved_object("npc." + nid)
		current_schedule_data = editor_service.data_service.get_resolved_object("schedule." + nid)
		current_social_data = editor_service.data_service.get_resolved_object("social." + nid)
	
	if current_npc_data.is_empty():
		current_npc_data = {
			"id": nid,
			"name": nid.capitalize(),
			"display_name": nid.capitalize() + " the Villager",
			"world": "farm" if nid == "rowan" else "town",
			"role": "villager",
			"dialogue_id": nid,
			"sprite": "merchant" if nid == "rowan" else ("blacksmith" if nid == "elias" else "researcher")
		}

	_populate_inspector_fields()
	_refresh_schedule_timeline()
	_update_appearance_preview()
	_evaluate_time_scrubber()
	validate()
	npc_selected.emit(nid)

func _populate_inspector_fields() -> void:
	if id_edit: id_edit.text = str(current_npc_data.get("id", current_npc_id))
	if display_name_edit: display_name_edit.text = str(current_npc_data.get("display_name", current_npc_id.capitalize()))
	if role_edit: role_edit.text = str(current_npc_data.get("role", "villager"))
	if dialogue_edit: dialogue_edit.text = str(current_npc_data.get("dialogue_id", current_npc_id))
	if shop_edit: shop_edit.text = str(current_npc_data.get("shop_id", ""))
	if sprite_edit: sprite_edit.text = str(current_npc_data.get("sprite", "merchant"))

	var w = str(current_npc_data.get("world", "farm"))
	for i in range(SUPPORTED_WORLDS.size()):
		if SUPPORTED_WORLDS[i] == w:
			if world_opt: world_opt.selected = i
			break

	if friends_edit and current_social_data:
		var fr = current_social_data.get("friends", [])
		friends_edit.text = ", ".join(fr)

	if social_locs_edit and current_social_data:
		var locs = current_social_data.get("social_locations", [])
		social_locs_edit.text = ", ".join(locs)

	if talkative_spin and current_social_data:
		talkative_spin.value = float(current_social_data.get("talkative_chance", 0.7))

func _get_active_schedule_entries() -> Array:
	if current_schedule_data.has(selected_weather_variant):
		var v = current_schedule_data[selected_weather_variant]
		if v is Array: return v
	if current_schedule_data.has("default"):
		var v = current_schedule_data["default"]
		if v is Array: return v
	return []


func _refresh_schedule_timeline() -> void:
	if not schedule_list_container: return
	for c in schedule_list_container.get_children(): c.queue_free()

	var entries = _get_active_schedule_entries()
	if entries.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No schedule entries for this variant."
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		schedule_list_container.add_child(empty_lbl)
		return

	for i in range(entries.size()):
		var entry = entries[i]
		var s_min = int(entry.get("start_minute", 360))
		var e_min = int(entry.get("end_minute", 480))
		var s_str = "%02d:%02d" % [s_min / 60, s_min % 60]
		var e_str = "%02d:%02d" % [e_min / 60, e_min % 60]
		var act = str(entry.get("activity", "home")).to_upper()
		var loc = str(entry.get("location_id", "home"))

		var btn = Button.new()
		btn.text = "%s  %s  [%s]   %s (Priority %s)" % [s_str, e_str, act, loc, str(entry.get("priority", 2))]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.modulate = Color.WHITE
		if i == selected_schedule_idx:
			btn.add_theme_stylebox_override("normal", UIConstants.create_active_button_stylebox())
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_color_override("font_color")
		btn.pressed.connect(func(): _select_schedule_entry(i))
		schedule_list_container.add_child(btn)

	if selected_schedule_idx < entries.size():
		_populate_schedule_entry_fields(entries[selected_schedule_idx])

func _select_schedule_entry(idx: int) -> void:
	selected_schedule_idx = idx
	_refresh_schedule_timeline()
	var entries = _get_active_schedule_entries()
	if idx < entries.size():
		_populate_schedule_entry_fields(entries[idx])

func _populate_schedule_entry_fields(entry: Dictionary) -> void:
	if entry_start_spin: entry_start_spin.value = int(entry.get("start_minute", 360))
	if entry_end_spin: entry_end_spin.value = int(entry.get("end_minute", 480))
	if entry_priority_spin: entry_priority_spin.value = int(entry.get("priority", 2))

	var act = str(entry.get("activity", "home")).to_lower()
	for i in range(SUPPORTED_ACTIVITIES.size()):
		if SUPPORTED_ACTIVITIES[i] == act:
			if entry_activity_opt: entry_activity_opt.selected = i
			break

	var loc = str(entry.get("location_id", ""))
	if entry_location_opt:
		for i in range(entry_location_opt.item_count):
			if entry_location_opt.get_item_text(i) == loc:
				entry_location_opt.selected = i
				break

func _update_appearance_preview() -> void:
	if not preview_sprite: return
	var sprite_id = str(current_npc_data.get("sprite", "merchant"))
	var tex = AssetRegistry.get_texture("npc_" + sprite_id)
	if not tex:
		tex = AssetRegistry.get_texture(sprite_id)
	if tex:
		preview_sprite.texture = tex

	if preview_name_label:
		preview_name_label.text = str(current_npc_data.get("display_name", current_npc_id.capitalize()))

func _on_time_scrub_changed(val: float) -> void:
	preview_minute = int(val)
	if time_display_label:
		time_display_label.text = "%02d:%02d" % [preview_minute / 60, preview_minute % 60]
	_evaluate_time_scrubber()

func _evaluate_time_scrubber() -> void:
	var entries = _get_active_schedule_entries()
	var active_entry: Dictionary = {}
	for e in entries:
		var sm = int(e.get("start_minute", 0))
		var em = int(e.get("end_minute", 1440))
		if preview_minute >= sm and preview_minute < em:
			active_entry = e
			break

	if preview_activity_label:
		if not active_entry.is_empty():
			preview_activity_label.text = "Activity: %s | Location: %s | Priority: %s" % [
				active_entry.get("activity", "idle"),
				active_entry.get("location_id", "unknown"),
				str(active_entry.get("priority", 2))
			]
		else:
			preview_activity_label.text = "Activity: IDLE | No active schedule entry at this time"

func _on_npc_field_changed(field: String, val: Variant) -> void:
	current_npc_data[field] = val
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("npc." + current_npc_id, field, val)
	_update_appearance_preview()
	panel_dirtied.emit()

func _on_schedule_prop_changed(field: String, val: Variant) -> void:
	var entries = _get_active_schedule_entries()
	if selected_schedule_idx < entries.size():
		entries[selected_schedule_idx][field] = val
		if field == "start_minute":
			var sm = int(val)
			entries[selected_schedule_idx]["start_time"] = "%02d:%02d" % [sm / 60, sm % 60]
		elif field == "end_minute":
			var em = int(val)
			entries[selected_schedule_idx]["end_time"] = "%02d:%02d" % [em / 60, em % 60]

		if editor_service and editor_service.data_service:
			editor_service.data_service.set_staged_override("schedule." + current_npc_id, selected_weather_variant, entries)
		_refresh_schedule_timeline()
		_evaluate_time_scrubber()
		panel_dirtied.emit()

func _on_social_friends_changed(text: String) -> void:
	var list: Array[String] = []
	for s in text.split(","):
		var trimmed = s.strip_edges()
		if trimmed != "": list.append(trimmed)
	current_social_data["friends"] = list
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("social." + current_npc_id, "friends", list)
	panel_dirtied.emit()

func _on_social_locations_changed(text: String) -> void:
	var list: Array[String] = []
	for s in text.split(","):
		var trimmed = s.strip_edges()
		if trimmed != "": list.append(trimmed)
	current_social_data["social_locations"] = list
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("social." + current_npc_id, "social_locations", list)
	panel_dirtied.emit()

func _on_social_field_changed(field: String, val: Variant) -> void:
	current_social_data[field] = val
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("social." + current_npc_id, field, val)
	panel_dirtied.emit()

func _on_add_schedule_entry() -> void:
	var entries = _get_active_schedule_entries()
	var new_entry = {
		"start_time": "12:00",
		"start_minute": 720,
		"end_time": "13:00",
		"end_minute": 780,
		"location_id": "town_square",
		"activity": "eat",
		"priority": 2,
		"facing": [0, 1]
	}
	entries.append(new_entry)
	selected_schedule_idx = entries.size() - 1
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("schedule." + current_npc_id, selected_weather_variant, entries)
	_refresh_schedule_timeline()
	panel_dirtied.emit()

func _on_delete_schedule_entry() -> void:
	var entries = _get_active_schedule_entries()
	if entries.is_empty(): return
	if selected_schedule_idx < entries.size():
		entries.remove_at(selected_schedule_idx)
		selected_schedule_idx = maxi(0, selected_schedule_idx - 1)
		if editor_service and editor_service.data_service:
			editor_service.data_service.set_staged_override("schedule." + current_npc_id, selected_weather_variant, entries)
		_refresh_schedule_timeline()
		panel_dirtied.emit()

func _move_schedule_entry(delta: int) -> void:
	var entries = _get_active_schedule_entries()
	var target_idx = selected_schedule_idx + delta
	if target_idx < 0 or target_idx >= entries.size(): return
	var item = entries[selected_schedule_idx]
	entries.remove_at(selected_schedule_idx)
	entries.insert(target_idx, item)
	selected_schedule_idx = target_idx
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("schedule." + current_npc_id, selected_weather_variant, entries)
	_refresh_schedule_timeline()
	panel_dirtied.emit()

func _on_add_new_npc() -> void:
	var new_id = "npc_custom_%d" % (int(Time.get_unix_time_from_system()) % 1000)
	var new_data = {
		"id": new_id,
		"name": new_id.capitalize(),
		"display_name": new_id.capitalize(),
		"world": "town",
		"role": "villager",
		"dialogue_id": new_id,
		"sprite": "merchant"
	}
	if editor_service and editor_service.data_service:
		editor_service.data_service.set_staged_override("npc." + new_id, "id", new_id)
		editor_service.data_service.set_staged_override("npc." + new_id, "display_name", new_data.display_name)
		editor_service.data_service.set_staged_override("npc." + new_id, "world", new_data.world)
		editor_service.data_service.set_staged_override("npc." + new_id, "role", new_data.role)
	_load_npc_list()
	_select_npc(new_id)

func _on_duplicate_npc() -> void:
	var dup_id = "%s_copy_%d" % [current_npc_id, (int(Time.get_unix_time_from_system()) % 1000)]
	var dup_data = current_npc_data.duplicate(true)


	dup_data["id"] = dup_id
	dup_data["display_name"] = dup_data.get("display_name", current_npc_id) + " (Copy)"
	
	if editor_service and editor_service.data_service:
		for k in dup_data.keys():
			editor_service.data_service.set_staged_override("npc." + dup_id, k, dup_data[k])
		if not current_schedule_data.is_empty():
			editor_service.data_service.set_staged_override("schedule." + dup_id, "default", current_schedule_data.get("default", []).duplicate(true))
	
	_load_npc_list()
	_select_npc(dup_id)

func _on_view_in_world_editor() -> void:
	var w = str(current_npc_data.get("world", "farm"))
	switch_to_world_editor.emit(w)

func _on_playtest_npc() -> void:
	npc_playtest_requested.emit(current_npc_id)
	if editor_service:
		editor_service.start_test_preview()

func reset_current_npc() -> void:
	if editor_service and editor_service.data_service:
		editor_service.data_service.restore_default("npc." + current_npc_id, "", true)
		editor_service.data_service.restore_default("schedule." + current_npc_id, "", true)
		editor_service.data_service.restore_default("social." + current_npc_id, "", true)
	_select_npc(current_npc_id)

func reset_schedule() -> void:
	if editor_service and editor_service.data_service:
		editor_service.data_service.restore_default("schedule." + current_npc_id, "", true)
	_select_npc(current_npc_id)

func validate() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	# Check NPC ID
	if current_npc_id == "":
		errors.append("NPC ID cannot be empty.")

	# Check Schedule Overlaps & Valid Intervals
	var entries = _get_active_schedule_entries()
	for i in range(entries.size()):
		var e1 = entries[i]
		var s1 = int(e1.get("start_minute", 0))
		var end1 = int(e1.get("end_minute", 0))
		if s1 >= end1:
			errors.append("Schedule entry %d has invalid time range (%d >= %d)." % [i, s1, end1])

		for j in range(i + 1, entries.size()):
			var e2 = entries[j]
			var s2 = int(e2.get("start_minute", 0))
			var end2 = int(e2.get("end_minute", 0))
			if (s1 < end2 and end1 > s2):
				warnings.append("Schedule entry %d overlaps with entry %d (%02d:%02d - %02d:%02d)." % [
					i, j, s1 / 60, s1 % 60, end1 / 60, end1 % 60
				])

	# Check Sleep Schedule Existence
	var has_sleep = entries.any(func(e): return e.get("activity") == "sleep" or e.get("activity") == "home")
	if not has_sleep and not entries.is_empty():
		warnings.append("NPC has no sleep or home schedule activity defined.")

	if validation_status_label:
		if errors.size() > 0:
			validation_status_label.text = "Validation: %d Errors" % errors.size()
			validation_status_label.modulate = Color(1.0, 0.4, 0.4)
		elif warnings.size() > 0:
			validation_status_label.text = "Validation: %d Warnings" % warnings.size()
			validation_status_label.modulate = Color(1.0, 0.8, 0.3)
		else:
			validation_status_label.text = "Validation: OK"
			validation_status_label.modulate = Color(0.4, 0.9, 0.4)

	return {
		"valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"total_checked": entries.size()
	}

func focus_npc(npc_id: String) -> void:
	var clean_id = npc_id.trim_prefix("npc.")
	_select_npc(clean_id)


## Public programmatic and UI authoring entry point for creating new NPCs (Phase 36)
func create_npc(npc_id: String, display_name: String, world: String = "farm", role: String = "villager", custom_data: Dictionary = {}) -> String:
	var clean_id = npc_id.strip_edges().to_lower().replace(" ", "_").trim_prefix("npc.")
	if clean_id == "": clean_id = "custom_npc_%d" % (int(Time.get_unix_time_from_system()) % 10000)
	
	var npc_dict = {
		"id": clean_id,
		"name": display_name if display_name != "" else clean_id.capitalize(),
		"display_name": display_name if display_name != "" else clean_id.capitalize(),
		"world": world,
		"role": role,
		"dialogue_id": clean_id,
		"sprite": "merchant",
		"interactable": true
	}
	npc_dict.merge(custom_data, true)
	
	if editor_service and editor_service.data_service:
		editor_service.data_service.create_entity("npc." + clean_id, npc_dict)
		editor_service.data_service.create_entity("schedule." + clean_id, {
			"default": [
				{ "time": "08:00", "location": "home", "action": "idle" },
				{ "time": "12:00", "location": "town_square", "action": "work" },
				{ "time": "18:00", "location": "home", "action": "rest" }
			]
		})
		editor_service.data_service.create_entity("social." + clean_id, {
			"likes": ["item.fertilizer", "crop.red_flower"],
			"dislikes": [],
			"starting_hearts": 0
		})
		
	_load_npc_list()
	_select_npc(clean_id)
	panel_dirtied.emit()
	return clean_id
