extends Node

## Facade / Adapter for economy and wallet operations, delegating true data ownership to PlayerState.

signal gold_changed(player_id: String, new_gold: int, delta: int)
signal upgrade_purchased(player_id: String, upgrade_id: String)

var starting_gold: int = 100
var currency_name: String = "Gold"
var currency_symbol: String = "G"

func _ready() -> void:
	pass

func _get_player_state(player_id: String) -> PlayerState:
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var psm = root.get_node_or_null("PlayerRegistry") if root else null
	if psm and psm.has_method("get_player_state"):
		return psm.get_player_state(player_id)
	return null

func get_gold(player_id: String) -> int:
	var state = _get_player_state(player_id)
	return state.gold if state else starting_gold

func can_afford(player_id: String, amount: int) -> bool:
	var state = _get_player_state(player_id)
	return state.can_afford(amount) if state else false

func add_gold(player_id: String, amount: int) -> void:
	var state = _get_player_state(player_id)
	if state: 
		state.add_gold(amount)
		gold_changed.emit(player_id, state.gold, amount)

func spend_gold(player_id: String, amount: int) -> bool:
	var state = _get_player_state(player_id)
	if state and state.spend_gold(amount):
		gold_changed.emit(player_id, state.gold, -amount)
		return true
	return false

func set_gold(player_id: String, amount: int) -> void:
	var state = _get_player_state(player_id)
	if state: 
		var delta = amount - state.gold
		state.set_gold(amount)
		gold_changed.emit(player_id, state.gold, delta)

# --- Upgrades API ---
func has_upgrade(player_id: String, upgrade_id: String) -> bool:
	var state = _get_player_state(player_id)
	return upgrade_id in state.purchased_upgrades if state else false

func get_purchased_upgrades(player_id: String) -> Array[String]:
	var state = _get_player_state(player_id)
	return state.purchased_upgrades.duplicate() if state else []

func purchase_upgrade(player_id: String, upgrade_id: String, price: int) -> bool:
	if has_upgrade(player_id, upgrade_id):
		return false
	if not spend_gold(player_id, price):
		return false
		
	var state = _get_player_state(player_id)
	if state:
		state.purchased_upgrades.append(upgrade_id)
	
	upgrade_purchased.emit(player_id, upgrade_id)
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("upgrade_purchase")
	
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		spawner.spawn_floating_text(pos, "⭐ UPGRADE ACQUIRED!
-%d Gold" % price, Color(1.0, 0.9, 0.2))
		
	return true

func get_sell_price_multiplier(player_id: String, plant_id: String) -> float:
	if has_upgrade(player_id, "botanists_notebook"):
		# Hybrid/rare flora yield +10% bonus gold
		if plant_id not in ["red_flower", "blue_flower", "yellow_herb", "green_vine", "white_lily"]:
			return 1.10
	return 1.0

