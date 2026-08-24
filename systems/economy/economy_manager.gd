extends Node

## Facade / Adapter for economy and wallet operations, delegating true data ownership to PlayerState.

signal gold_changed(new_gold: int, delta: int)
signal upgrade_purchased(upgrade_id: String)

var current_gold: int:
	get:
		var state = _get_active_state()
		return state.gold if state else 100
	set(val):
		var state = _get_active_state()
		if state: state.gold = val

var starting_gold: int = 100
var currency_name: String = "Gold"
var currency_symbol: String = "G"
var purchased_upgrades: Array[String] = []

func _ready() -> void:
	var psm = get_node_or_null("/root/PlayerStateManager")
	if psm and "active_player_changed" in psm:
		psm.active_player_changed.connect(_on_active_player_changed)
	_bind_active_state_signals()

func _get_active_state() -> PlayerState:
	var root = Engine.get_main_loop().root if (Engine.get_main_loop() and "root" in Engine.get_main_loop()) else null
	var psm = root.get_node_or_null("PlayerStateManager") if root else null
	if psm and psm.has_method("get_active_player_state"):
		return psm.get_active_player_state()
	return null

func _on_active_player_changed(_pid: String) -> void:
	_bind_active_state_signals()
	gold_changed.emit(current_gold, 0)

func _bind_active_state_signals() -> void:
	var state = _get_active_state()
	if state:
		if not state.gold_changed.is_connected(_on_state_gold_changed):
			state.gold_changed.connect(_on_state_gold_changed)

func _on_state_gold_changed(new_gold: int, delta: int = 0) -> void:
	gold_changed.emit(new_gold, delta)

func get_gold() -> int:
	return current_gold

func can_afford(amount: int) -> bool:
	var state = _get_active_state()
	return state.can_afford(amount) if state else false

func add_gold(amount: int) -> void:
	var state = _get_active_state()
	if state: state.add_gold(amount)

func spend_gold(amount: int) -> bool:
	var state = _get_active_state()
	return state.spend_gold(amount) if state else false

func set_gold(amount: int) -> void:
	var state = _get_active_state()
	if state: state.set_gold(amount)


# --- Upgrades API ---
func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in purchased_upgrades

func get_purchased_upgrades() -> Array[String]:
	return purchased_upgrades.duplicate()

func purchase_upgrade(upgrade_id: String, price: int) -> bool:
	if has_upgrade(upgrade_id):
		return false
	if not spend_gold(price):
		return false
		
	purchased_upgrades.append(upgrade_id)
	upgrade_purchased.emit(upgrade_id)
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("upgrade_purchase")
	
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		spawner.spawn_floating_text(pos, "⭐ UPGRADE ACQUIRED!\n-%d Gold" % price, Color(1.0, 0.9, 0.2))
		
	return true

func get_sell_price_multiplier(plant_id: String) -> float:
	if has_upgrade("botanists_notebook"):
		# Hybrid/rare flora yield +10% bonus gold
		if plant_id not in ["red_flower", "blue_flower", "yellow_herb", "green_vine", "white_lily"]:
			return 1.10
	return 1.0

# --- State Persistence ---
func get_economy_state() -> Dictionary:
	return {
		"gold": current_gold,
		"purchased_upgrades": purchased_upgrades.duplicate()
	}

func load_economy_state(data: Dictionary) -> void:
	current_gold = int(data.get("gold", 100))
	purchased_upgrades.clear()
	var up_list = data.get("purchased_upgrades", [])
	for u in up_list:
		purchased_upgrades.append(str(u))
	gold_changed.emit(current_gold, 0)
