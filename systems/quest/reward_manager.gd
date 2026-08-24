class_name RewardManager
extends RefCounted

## Central static distributor for quest rewards (gold, items, seeds, discoveries).

static func grant_rewards(rewards: Dictionary, target_pstate = null) -> Dictionary:
	var granted_summary = {
		"gold": 0,
		"items": [],
		"friendship": {},
		"recipes": [],
		"world_unlock": ""
	}
	
	var p_state: PlayerState = target_pstate
	if not p_state:
		var psm = Engine.get_main_loop().root.get_node_or_null("PlayerRegistry")
		if psm: p_state = psm.get_active_player_state()
		
	# 1. Gold
	var gold_amt = int(rewards.get("gold", 0))
	if gold_amt > 0:
		if p_state:
			p_state.add_gold(gold_amt)
		else:
			var em = Engine.get_main_loop().root.get_node_or_null("EconomyManager")
			if em: em.add_gold(gold_amt)
		granted_summary["gold"] = gold_amt
			
	# 2. Items / Seeds
	var items_arr = rewards.get("items", [])
	if typeof(items_arr) == TYPE_ARRAY:
		for itm in items_arr:
			var item_id = str(itm.get("item_id", ""))
			var count = int(itm.get("amount", itm.get("count", 1)))
			if item_id != "" and count > 0:
				if p_state:
					p_state.add_item(item_id, count)
				else:
					var im = Engine.get_main_loop().root.get_node_or_null("InventoryManager")
					if im: im.add_item(item_id, count)
				granted_summary["items"].append({ "item_id": item_id, "amount": count })
				
	# 3. Friendship
	var friend_data = rewards.get("friendship", {})
	if typeof(friend_data) == TYPE_DICTIONARY and not friend_data.is_empty():
		var npc_id = str(friend_data.get("npc_id", ""))
		var pts = int(friend_data.get("points", 10))
		if npc_id != "" and pts > 0:
			if p_state: p_state.add_friendship(npc_id, pts)
			granted_summary["friendship"] = { "npc_id": npc_id, "points": pts }
			
	# 4. Recipe / Formula Unlock
	var recipes = rewards.get("recipes", rewards.get("recipe", []))
	if typeof(recipes) == TYPE_STRING: recipes = [recipes]
	if typeof(recipes) == TYPE_ARRAY:
		for r in recipes:
			var rid = str(r)
			if rid != "":
				var wm = Engine.get_main_loop().root.get_node_or_null("WorldManager")
				if wm:
					var cur_w = wm.get_current_world()
					wm.get_shared_world_state(cur_w).register_discovery(rid, rid)
				granted_summary["recipes"].append(rid)
				
	# 5. World / Progression Unlock
	var unlock_w = str(rewards.get("world_unlock", rewards.get("unlock_world", "")))
	if unlock_w != "":
		var pm = Engine.get_main_loop().root.get_node_or_null("ProgressionManager")
		if pm: pm.unlock_world(unlock_w, true)
		granted_summary["world_unlock"] = unlock_w
				
	# 6. Audio & Floating Text feedback
	var am = Engine.get_main_loop().root.get_node_or_null("AudioManager")
	if am: am.play_sfx("quest_complete")
		
	var spawner = EffectSpawner.get_instance()
	var player = Engine.get_main_loop().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		var txt = "🎁 QUEST REWARD!"
		if gold_amt > 0: txt += "\n+ %d Gold" % gold_amt
		for itm in granted_summary["items"]:
			var dname = itm["item_id"].replace("_", " ").capitalize()
			txt += "\n+ %d %s" % [itm["amount"], dname]
		if not granted_summary["friendship"].is_empty():
			txt += "\n+ %d Friendship (%s)" % [granted_summary["friendship"]["points"], granted_summary["friendship"]["npc_id"].capitalize()]
		if unlock_w != "":
			txt += "\n🌟 Unlocked Area: %s" % unlock_w.capitalize()
		spawner.spawn_floating_text(pos, txt, Color(1.0, 0.9, 0.2))
		
	return granted_summary


