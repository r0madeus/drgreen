class_name TutorialGuide
extends Control

## Progressive, non-intrusive onboarding tutorial guide for new players.
## Automatically advances steps as gameplay actions are completed.

signal step_advanced(step_index: int, step_title: String)
signal tutorial_completed()

enum Step {
	MOVE,
	TALK_ROWAN,
	PLANT,
	WATER,
	HARVEST,
	COMMERCE,
	SYNTHESIS,
	EXPLORE_TOWN,
	COMPLETED
}

var current_step: Step = Step.MOVE
var step_move_counter: int = 0
var is_active: bool = true

@onready var banner_panel: PanelContainer
@onready var icon_label: Label
@onready var title_label: Label
@onready var instruction_label: Label
@onready var progress_label: Label

const STEP_DATA = {
	Step.MOVE: {
		"icon": "🚶",
		"title_key": "tutorial.move.title",
		"desc_key": "tutorial.move.desc",
		"title": "Welcome to Botanical Haven!",
		"desc": "Use [W, A, S, D] or [Arrow Keys] to walk around your farm.",
		"target": 3
	},
	Step.TALK_ROWAN: {
		"icon": "💬",
		"title_key": "tutorial.talk_rowan.title",
		"desc_key": "tutorial.talk_rowan.desc",
		"title": "Meet Rowan the Herbalist",
		"desc": "Approach Rowan near the market stall and press [Space] or [Enter] to talk.",
		"target": 1
	},
	Step.PLANT: {
		"icon": "🌱",
		"title_key": "tutorial.plant.title",
		"desc_key": "tutorial.plant.desc",
		"title": "Sow Your First Seeds",
		"desc": "Select Red Seeds in your hotbar (1-5) and press [Space] on tilled soil.",
		"target": 1
	},
	Step.WATER: {
		"icon": "💧",
		"title_key": "tutorial.water.title",
		"desc_key": "tutorial.water.desc",
		"title": "Nurture Your Crop",
		"desc": "Press [Space] in front of your planted seed to water the soil.",
		"target": 1
	},
	Step.HARVEST: {
		"icon": "🌾",
		"title_key": "tutorial.harvest.title",
		"desc_key": "tutorial.harvest.desc",
		"title": "Bountiful Harvest",
		"desc": "Click [Advance Day] or wait for growth, then press [Space] to harvest.",
		"target": 1
	},
	Step.COMMERCE: {
		"icon": "💰",
		"title_key": "tutorial.commerce.title",
		"desc_key": "tutorial.commerce.desc",
		"title": "Market Trade",
		"desc": "Talk to Rowan or click [Shop] to sell your crops and buy fresh seeds.",
		"target": 1
	},
	Step.SYNTHESIS: {
		"icon": "🧪",
		"title_key": "tutorial.synthesis.title",
		"desc_key": "tutorial.synthesis.desc",
		"title": "Botanical Alchemy",
		"desc": "Press [L] to open the Laboratory Station and combine two crops into a hybrid!",
		"target": 1
	},
	Step.EXPLORE_TOWN: {
		"icon": "🗺️",
		"title_key": "tutorial.explore.title",
		"desc_key": "tutorial.explore.desc",
		"title": "Expand Your Horizons",
		"desc": "Check your Quest Journal [Q] and follow the northern path to Botanist Village!",
		"target": 1
	}
}

func _ready() -> void:
	_build_ui()
	_connect_event_bus()
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(func(_l): _update_display())
	_update_display()


func _build_ui() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	var tw = 420.0
	offset_left = -tw / 2.0
	offset_right = tw / 2.0
	offset_bottom = -72
	offset_top = -124
	custom_minimum_size = Vector2(tw, 48)

	
	banner_panel = PanelContainer.new()
	banner_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.anchors_preset = Control.PRESET_FULL_RECT
	banner_panel.anchor_right = 1.0
	banner_panel.anchor_bottom = 1.0
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.13, 0.9)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.22, 0.42, 0.32, 0.95)
	sb.set_corner_radius_all(4)
	sb.shadow_size = 4
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	banner_panel.add_theme_stylebox_override("panel", sb)
	add_child(banner_panel)
	
	var margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	banner_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	# Top line: Icon + Title + Progress
	var top_hbox = HBoxContainer.new()
	top_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(top_hbox)
	
	icon_label = Label.new()
	icon_label.text = "🌿"
	icon_label.add_theme_font_size_override("font_size", 13)
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(icon_label)
	
	title_label = Label.new()
	title_label.text = "Tutorial Step"
	title_label.add_theme_font_size_override("font_size", 11)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(title_label)
	
	progress_label = Label.new()
	progress_label.text = "[ 1 / 8 ]"
	progress_label.add_theme_font_size_override("font_size", 10)
	progress_label.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0, 0.95))
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hbox.add_child(progress_label)
	
	# Bottom line: Instruction
	instruction_label = Label.new()
	instruction_label.text = "Instruction text goes here..."
	instruction_label.add_theme_font_size_override("font_size", 10)
	instruction_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 0.9))
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(instruction_label)

func _connect_event_bus() -> void:
	EventBus.player_moved.connect(_on_player_moved)
	EventBus.npc_talked.connect(_on_npc_talked)
	EventBus.plant_planted.connect(_on_plant_planted)
	EventBus.plant_watered.connect(_on_plant_watered)
	EventBus.plant_harvested.connect(_on_plant_harvested)
	EventBus.item_sold.connect(_on_item_sold)
	EventBus.item_bought.connect(_on_item_bought)
	EventBus.synthesis_performed.connect(_on_synthesis_performed)
	EventBus.plant_combined.connect(func(_a, _b, _o): _on_synthesis_performed("", "", 1))
	EventBus.world_unlocked.connect(_on_world_unlocked)
	EventBus.world_changed.connect(_on_world_changed)

func start_tutorial() -> void:
	current_step = Step.MOVE
	step_move_counter = 0
	is_active = true
	visible = true
	_update_display()

func complete_step(step: Step) -> void:
	if current_step == step:
		var next = int(current_step) + 1
		if next < int(Step.COMPLETED):
			current_step = next as Step
			_show_step_feedback()
			_update_display()
			step_advanced.emit(int(current_step), STEP_DATA[current_step]["title"])
		else:
			current_step = Step.COMPLETED
			is_active = false
			visible = false
			tutorial_completed.emit()
			var am = get_node_or_null("/root/AudioManager")
			if am: am.play_sfx("quest_complete")

func _show_step_feedback() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("dialogue_next")
	
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner and STEP_DATA.has(current_step):
		spawner.spawn_floating_text(pos, "✨ " + STEP_DATA[current_step]["title"], Color(0.5, 1.0, 0.6))

func _update_display() -> void:
	if not is_active or current_step == Step.COMPLETED:
		visible = false
		return
		
	visible = true
	var data = STEP_DATA.get(current_step, {})
	if icon_label: icon_label.text = str(data.get("icon", "🌿"))
	var title_key = data.get("title_key", "")
	if title_label: title_label.text = tr(title_key) if title_key != "" else str(data.get("title", "Tutorial"))
	var desc_key = data.get("desc_key", "")
	if instruction_label: instruction_label.text = tr(desc_key) if desc_key != "" else str(data.get("desc", ""))
	if progress_label: progress_label.text = "[ %d / %d ]" % [int(current_step) + 1, STEP_DATA.size()]


func _on_player_moved(_pos: Vector2i) -> void:
	if current_step == Step.MOVE:
		step_move_counter += 1
		if step_move_counter >= 3:
			complete_step(Step.MOVE)

func _on_npc_talked(npc_id: String) -> void:
	if current_step == Step.TALK_ROWAN and npc_id == "rowan":
		complete_step(Step.TALK_ROWAN)

func _on_plant_planted(_pos: Vector2i, _plant_id: String) -> void:
	if current_step == Step.PLANT:
		complete_step(Step.PLANT)

func _on_plant_watered(_pos: Vector2i) -> void:
	if current_step == Step.WATER:
		complete_step(Step.WATER)

func _on_plant_harvested(_pos: Vector2i, _plant_id: String, _cnt: int) -> void:
	if current_step == Step.HARVEST:
		complete_step(Step.HARVEST)

func _on_item_sold(_item_id: String, _count: int, _gold: int) -> void:
	if current_step == Step.COMMERCE:
		complete_step(Step.COMMERCE)

func _on_item_bought(_item_id: String, _count: int, _price: int) -> void:
	if current_step == Step.COMMERCE:
		complete_step(Step.COMMERCE)

func _on_synthesis_performed(_f_id: String, _res_id: String, _cnt: int) -> void:
	if current_step == Step.SYNTHESIS:
		complete_step(Step.SYNTHESIS)

func _on_world_unlocked(_wid: String, _dname: String) -> void:
	if current_step == Step.EXPLORE_TOWN:
		complete_step(Step.EXPLORE_TOWN)

func _on_world_changed(wid: String, _wdata: Dictionary = {}) -> void:
	if current_step == Step.EXPLORE_TOWN and wid != "farm":
		complete_step(Step.EXPLORE_TOWN)

