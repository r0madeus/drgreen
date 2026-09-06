class_name QuestUI
extends Control

## Cozy Botanical Fantasy Quest Journal displaying active objectives and rewards.

enum Tab { ACTIVE, COMPLETED }
var current_tab: Tab = Tab.ACTIVE

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var active_tab_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/ActiveTabButton
@onready var completed_tab_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TabButtons/CompletedTabButton
@onready var close_btn: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton

@onready var active_scroll: ScrollContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Content/ActiveScroll
@onready var active_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Content/ActiveScroll/ActiveList
@onready var active_empty_lbl: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Content/ActiveEmptyLabel

@onready var completed_scroll: ScrollContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Content/CompletedScroll
@onready var completed_list: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Content/CompletedScroll/CompletedList
@onready var completed_empty_lbl: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Content/CompletedEmptyLabel

func _ready() -> void:
	visible = false
	theme = UIConstants.get_theme()
	if close_btn: close_btn.pressed.connect(toggle_visibility)
	if active_tab_btn: active_tab_btn.pressed.connect(func(): _switch_tab(Tab.ACTIVE))
	if completed_tab_btn: completed_tab_btn.pressed.connect(func(): _switch_tab(Tab.COMPLETED))
	
	var qm = get_node_or_null("/root/QuestManager")
	if qm and "quest_status_changed" in qm:
		qm.quest_status_changed.connect(func(_id, _st): refresh_ui())
		qm.quest_objective_updated.connect(func(_id, _c, _t): refresh_ui())
		qm.quest_reward_claimed.connect(func(_id, _rew): refresh_ui())
		
	var net_q = get_node_or_null("/root/NetworkQuests")
	if net_q and "shared_quest_objective_updated" in net_q:
		net_q.shared_quest_objective_updated.connect(func(_qid, _idx, _c, _r): refresh_ui())
		net_q.shared_quest_completed.connect(func(_qid): refresh_ui())
		net_q.personal_quest_reward_received.connect(func(_qid, _rew): refresh_ui())
		net_q.quest_snapshot_applied.connect(func(): refresh_ui())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quest"):
		toggle_visibility()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and visible:
			close_ui()
			get_viewport().set_input_as_handled()

func open_ui() -> void:
	UIConstants.close_all_modals(get_tree(), self)
	visible = true
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_open")
	UIConstants.update_player_lock(get_tree())
	refresh_ui()

func close_ui() -> void:
	visible = false
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_close")
	UIConstants.update_player_lock(get_tree())

func toggle_visibility() -> void:
	if visible:
		close_ui()
	else:
		open_ui()

func _switch_tab(tab: Tab) -> void:
	current_tab = tab
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	if active_tab_btn and completed_tab_btn:
		active_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.ACTIVE else Color.WHITE
		completed_tab_btn.modulate = Color(1.3, 1.3, 0.8) if tab == Tab.COMPLETED else Color.WHITE
		
	if active_scroll and completed_scroll:
		active_scroll.visible = (tab == Tab.ACTIVE)
		completed_scroll.visible = (tab == Tab.COMPLETED)
		
	refresh_ui()

func refresh_ui() -> void:
	if not visible:
		return
	if current_tab == Tab.ACTIVE:
		_populate_active()
	else:
		_populate_completed()

func _populate_active() -> void:
	if not active_list:
		return
	for c in active_list.get_children():
		c.queue_free()
		
	var qm = get_node_or_null("/root/QuestManager")
	if not qm:
		return
		
	var active_quest_ids = qm.get_active_quests()
	var has_quests = active_quest_ids.size() > 0
	
	for q_item in active_quest_ids:
		var qid = q_item if typeof(q_item) == TYPE_STRING else q_item.get("id", "")
		var q = qm.get_quest(qid) if typeof(q_item) == TYPE_STRING else q_item
		if q.is_empty():
			continue
		var title_key = q.get("title_key", "")
		var title = tr(title_key) if title_key != "" else q.get("title", "")
		var desc_key = q.get("description_key", "")
		var desc = tr(desc_key) if desc_key != "" else q.get("description", "")
		var giver = q.get("giver", "Villager")
		var is_shared = bool(q.get("scope", "personal") == "shared")
		var rewards = q.get("rewards", {})
		var gold = int(rewards.get("gold", 0))
		var objectives = q.get("objectives", [])
		var progress = qm.get_quest_progress(qid)
		var status = qm.get_quest_status(qid)
		var is_ready_to_claim = (status == "completed")
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(460, 95)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		card.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		margin.add_child(vbox)
		
		# Title, Badge & Giver HBox
		var title_hbox = HBoxContainer.new()
		var badge_lbl = Label.new()
		badge_lbl.text = "[CO-OP SHARED] " if is_shared else "[PERSONAL] "
		badge_lbl.modulate = Color(0.4, 0.9, 1.0) if is_shared else Color(0.8, 0.8, 1.0)
		title_hbox.add_child(badge_lbl)
		
		var title_lbl = Label.new()
		title_lbl.text = "📜 " + title
		title_lbl.modulate = Color(1.0, 0.95, 0.4)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_hbox.add_child(title_lbl)
		
		var giver_lbl = Label.new()
		giver_lbl.text = "Giver: " + giver
		giver_lbl.modulate = Color(0.7, 0.7, 0.7)
		title_hbox.add_child(giver_lbl)
		vbox.add_child(title_hbox)
		
		# Description
		var desc_lbl = Label.new()
		desc_lbl.text = desc
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.modulate = Color(0.9, 0.9, 0.9)
		vbox.add_child(desc_lbl)
		
		# Objectives
		for i in range(objectives.size()):
			var obj = objectives[i]
			var obj_key = obj.get("text_key", "")
			var obj_desc = tr(obj_key) if obj_key != "" else obj.get("description", "Objective")
			var req = int(obj.get("amount", 1))
			var cur = int(progress[i]) if i < progress.size() else 0
			var obj_lbl = Label.new()
			obj_lbl.text = " • %s: [ %d / %d ]" % [obj_desc, cur, req]
			obj_lbl.modulate = Color(0.5, 1.0, 0.5) if cur >= req else Color(0.8, 0.8, 0.8)
			vbox.add_child(obj_lbl)
			
		# Bottom Row: Reward & Claim Button
		var bot_hbox = HBoxContainer.new()
		bot_hbox.add_theme_constant_override("separation", 10)
		
		var rew_text = "Reward: "
		if gold > 0: rew_text += "💰 %d G  " % gold
		var rew_items = rewards.get("items", [])
		for itm in rew_items:
			var itm_name = ItemRegistry.get_localized_name(str(itm.get("item_id", "")))
			rew_text += "🎁 %dx %s  " % [int(itm.get("count", 1)), itm_name]
		var rew_unlock = str(rewards.get("world_unlock", rewards.get("unlock_world", "")))

		if rew_unlock != "": rew_text += "🌟 Unlock %s" % rew_unlock.capitalize()
		
		var rew_lbl = Label.new()
		rew_lbl.text = rew_text
		rew_lbl.modulate = Color(1.0, 0.85, 0.2)
		rew_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bot_hbox.add_child(rew_lbl)
		
		if is_ready_to_claim:
			var claim_btn = Button.new()
			claim_btn.text = "🎁 Claim Reward"
			claim_btn.modulate = Color(1.2, 1.2, 0.6)
			claim_btn.pressed.connect(func():
				var net_q2 = get_node_or_null("/root/NetworkQuests")
				if net_q2:
					net_q2.request_claim_quest_reward(qid)
				else:
					qm.claim_reward(qid)
				refresh_ui()
			)
			bot_hbox.add_child(claim_btn)
			
		vbox.add_child(bot_hbox)
		active_list.add_child(card)

		
	if active_empty_lbl: active_empty_lbl.visible = not has_quests
	if active_scroll: active_scroll.visible = has_quests

func _populate_completed() -> void:
	if not completed_list:
		return
	for c in completed_list.get_children():
		c.queue_free()
		
	var qm = get_node_or_null("/root/QuestManager")
	if not qm:
		return
		
	var comp_quest_ids = qm.get_completed_quests()
	var has_comp = comp_quest_ids.size() > 0
	
	for q_item in comp_quest_ids:
		var qid = q_item if typeof(q_item) == TYPE_STRING else q_item.get("id", "")
		var q = qm.get_quest(qid) if typeof(q_item) == TYPE_STRING else q_item
		if q.is_empty():
			continue
		var title = q.get("title", "")
		var desc = q.get("description", "")
		var rewards = q.get("rewards", {})
		var gold = int(rewards.get("gold", 0))
		
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(460, 60)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_top", 6)
		margin.add_theme_constant_override("margin_bottom", 6)
		card.add_child(margin)
		
		var vbox = VBoxContainer.new()
		margin.add_child(vbox)
		
		var hbox = HBoxContainer.new()
		var title_lbl = Label.new()
		title_lbl.text = "✅ " + title
		title_lbl.modulate = Color(0.6, 1.0, 0.6)
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(title_lbl)
		
		var rew_lbl = Label.new()
		rew_lbl.text = "Claimed: 💰 %d G" % gold
		rew_lbl.modulate = Color(0.7, 0.7, 0.7)
		hbox.add_child(rew_lbl)
		vbox.add_child(hbox)
		
		var desc_lbl = Label.new()
		desc_lbl.text = desc
		desc_lbl.modulate = Color(0.6, 0.6, 0.6)
		vbox.add_child(desc_lbl)
		
		completed_list.add_child(card)
		
	if completed_empty_lbl: completed_empty_lbl.visible = not has_comp
	if completed_scroll: completed_scroll.visible = has_comp
