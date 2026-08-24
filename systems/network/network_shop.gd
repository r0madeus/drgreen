extends Node
## Host-authoritative shop purchase/sell synchronization.
## Shop STOCK is shared world state. Player GOLD/INVENTORY is player state.

signal purchase_completed(shop_id: String, item_id: String, quantity: int, gold_spent: int)
signal sale_completed(item_id: String, quantity: int, gold_earned: int)
signal shop_stock_updated(world_id: String, shop_id: String, stock: Dictionary)
signal shop_error(reason: String)

func is_host() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_host() if nm else true

func is_offline() -> bool:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.is_offline() if nm else true

func get_local_peer_id() -> int:
	var nm = get_node_or_null("/root/NetworkManager")
	return nm.get_local_peer_id() if nm else 1

# ---------------------------------------------------------------
# CLIENT APIS
# ---------------------------------------------------------------

func request_buy(world_id: String, shop_id: String, item_id: String, quantity: int) -> void:
	if is_offline():
		_local_buy(world_id, shop_id, item_id, quantity)
		return
	rpc("host_buy", get_local_peer_id(), world_id, shop_id, item_id, quantity)

func request_sell(world_id: String, shop_id: String, item_id: String, quantity: int) -> void:
	if is_offline():
		_local_sell(world_id, shop_id, item_id, quantity)
		return
	rpc("host_sell", get_local_peer_id(), world_id, shop_id, item_id, quantity)

# ---------------------------------------------------------------
# HOST HELPERS
# ---------------------------------------------------------------

func _get_world_state(world_id: String) -> SharedWorldState:
	var wm = get_node_or_null("/root/WorldManager")
	return wm.get_shared_world_state(world_id) if wm else null

func _get_player_state(peer_id: int) -> PlayerState:
	var ng = get_node_or_null("/root/NetworkGameplay")
	return ng._get_player_state_for_peer(peer_id) if ng else null

func _send_error(peer_id: int, reason: String) -> void:
	if peer_id == 1 or is_offline() or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(peer_id):
		shop_error.emit(reason)
		var spawner = EffectSpawner.get_instance()
		var player = get_tree().root.find_child("Player", true, false)
		var pos2 = player.global_position if player else Vector2(240, 180)
		if spawner: spawner.spawn_floating_text(pos2, "❌ %s" % reason, Color(1.0, 0.4, 0.4))
	else:
		rpc_id(peer_id, "client_receive_shop_error", reason)

func _get_shop_catalog_item(shop_id: String, item_id: String) -> Dictionary:
	var sm = get_node_or_null("/root/ShopManager")
	if not sm: return {}
	var shop = sm.get_shop(shop_id)
	for itm in shop.get("items", []):
		# Support both "item_id" and "id" keys in catalog JSON
		var cid = str(itm.get("item_id", itm.get("id", "")))
		if cid == item_id:
			# Normalize price key to "buy_price"
			var result = itm.duplicate(true)
			if not result.has("buy_price") and result.has("price"):
				result["buy_price"] = result["price"]
			if not result.has("sell_price"):
				result["sell_price"] = int(result.get("buy_price", result.get("price", 10))) / 2
			return result
	return {}

func _get_shop_stock(ws: SharedWorldState, shop_id: String) -> Dictionary:
	# Stock stored in containers dict with a special key prefix for shops
	return ws.get_container_items("shop_stock:" + shop_id)

func _set_shop_stock(ws: SharedWorldState, shop_id: String, stock: Dictionary) -> void:
	ws.set_container_items("shop_stock:" + shop_id, stock)

func _init_shop_stock(ws: SharedWorldState, shop_id: String) -> Dictionary:
	var stock = _get_shop_stock(ws, shop_id)
	if not stock.is_empty(): return stock
	var sm = get_node_or_null("/root/ShopManager")
	if not sm: return {}

	var shop = sm.get_shop(shop_id)
	for itm in shop.get("items", []):
		var iid = str(itm.get("item_id", ""))
		var qty = int(itm.get("stock", 99))
		if iid != "":
			stock[iid] = qty
	_set_shop_stock(ws, shop_id, stock)
	return stock

# ---------------------------------------------------------------
# HOST RPC HANDLERS
# ---------------------------------------------------------------

@rpc("any_peer", "call_local", "reliable")
func host_buy(requester_peer: int, world_id: String, shop_id: String, item_id: String, quantity: int) -> void:
	if not is_host(): return
	if quantity <= 0:
		_send_error(requester_peer, "INVALID_QUANTITY")
		return
	
	var ws = _get_world_state(world_id)
	if not ws:
		_send_error(requester_peer, "INVALID_WORLD")
		return
	
	var player_state = _get_player_state(requester_peer)
	if not player_state:
		_send_error(requester_peer, "INVALID_PLAYER")
		return
	
	var catalog_item = _get_shop_catalog_item(shop_id, item_id)
	if catalog_item.is_empty():
		_send_error(requester_peer, "ITEM_NOT_IN_SHOP")
		return
	
	var stock = _init_shop_stock(ws, shop_id)
	var current_stock = int(stock.get(item_id, 99))
	if current_stock >= 0 and current_stock < quantity:
		_send_error(requester_peer, "OUT_OF_STOCK")
		return
	
	var unit_price = int(catalog_item.get("buy_price", 20))
	var total_cost = unit_price * quantity
	
	if player_state.gold < total_cost:
		_send_error(requester_peer, "NOT_ENOUGH_GOLD")
		return
	
	# Atomic transaction
	player_state.gold -= total_cost
	player_state.gold_changed.emit(player_state.gold, -total_cost)
	player_state.add_item(item_id, quantity)
	
	if current_stock >= 0:
		stock[item_id] = current_stock - quantity
		_set_shop_stock(ws, shop_id, stock)
		rpc("client_receive_shop_stock_update", world_id, shop_id, stock)
	
	if requester_peer == 1 or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(requester_peer):
		client_receive_purchase_result(shop_id, item_id, quantity, total_cost)
	else:
		rpc_id(requester_peer, "client_receive_purchase_result", shop_id, item_id, quantity, total_cost)
	
	print("[NetShop] Peer %d bought %dx %s from %s for %dg" % [requester_peer, quantity, item_id, shop_id, total_cost])

@rpc("any_peer", "call_local", "reliable")
func host_sell(requester_peer: int, world_id: String, shop_id: String, item_id: String, quantity: int) -> void:
	if not is_host(): return
	if quantity <= 0:
		_send_error(requester_peer, "INVALID_QUANTITY")
		return
	
	var ws = _get_world_state(world_id)
	if not ws:
		_send_error(requester_peer, "INVALID_WORLD")
		return
	
	var player_state = _get_player_state(requester_peer)
	if not player_state:
		_send_error(requester_peer, "INVALID_PLAYER")
		return
	
	if not player_state.has_item(item_id, quantity):
		_send_error(requester_peer, "NOT_ENOUGH_ITEMS")
		return
	
	# Sell price: look up catalog or use a default 50% of buy price
	var catalog_item = _get_shop_catalog_item(shop_id, item_id)
	var sell_price = int(catalog_item.get("sell_price", 10))
	var total_earn = sell_price * quantity
	
	# Atomic transaction
	player_state.remove_item(item_id, quantity)
	player_state.gold += total_earn
	player_state.gold_changed.emit(player_state.gold, total_earn)
	
	if requester_peer == 1 or not multiplayer.has_multiplayer_peer() or not multiplayer.get_peers().has(requester_peer):
		client_receive_sale_result(item_id, quantity, total_earn)
	else:
		rpc_id(requester_peer, "client_receive_sale_result", item_id, quantity, total_earn)
	
	print("[NetShop] Peer %d sold %dx %s for %dg" % [requester_peer, quantity, item_id, total_earn])

# ---------------------------------------------------------------
# CLIENT RECEIVERS
# ---------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func client_receive_shop_stock_update(world_id: String, shop_id: String, stock: Dictionary) -> void:
	var ws = _get_world_state(world_id)
	if ws: ws.set_container_items("shop_stock:" + shop_id, stock)
	shop_stock_updated.emit(world_id, shop_id, stock)

@rpc("authority", "call_remote", "reliable")
func client_receive_purchase_result(shop_id: String, item_id: String, quantity: int, gold_spent: int) -> void:
	purchase_completed.emit(shop_id, item_id, quantity, gold_spent)
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("purchase")
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos2 = player.global_position if player else Vector2(240, 180)
	var dname = item_id.replace("_", " ").capitalize()
	if spawner: spawner.spawn_floating_text(pos2, "🛒 +%d %s (-%dg)" % [quantity, dname, gold_spent], Color(1.0, 0.9, 0.2))

@rpc("authority", "call_remote", "reliable")
func client_receive_sale_result(item_id: String, quantity: int, gold_earned: int) -> void:
	sale_completed.emit(item_id, quantity, gold_earned)
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("purchase")
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos2 = player.global_position if player else Vector2(240, 180)
	var dname = item_id.replace("_", " ").capitalize()
	if spawner: spawner.spawn_floating_text(pos2, "💰 +%dg (-%d %s)" % [gold_earned, quantity, dname], Color(0.4, 1.0, 0.5))

@rpc("authority", "call_remote", "reliable")
func client_receive_shop_error(reason: String) -> void:
	shop_error.emit(reason)
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos2 = player.global_position if player else Vector2(240, 180)
	if spawner: spawner.spawn_floating_text(pos2, "❌ %s" % reason, Color(1.0, 0.4, 0.4))

# ---------------------------------------------------------------
# OFFLINE FALLBACKS
# ---------------------------------------------------------------

func _local_buy(world_id: String, shop_id: String, item_id: String, quantity: int) -> void:
	# Offline: use existing ShopManager directly
	var sm = get_node_or_null("/root/ShopManager")
	if sm:
		var result = sm.buy_item(shop_id, item_id, quantity)
		if result.get("success", false):
			purchase_completed.emit(shop_id, item_id, quantity, result.get("total_price", 0))
		else:
			shop_error.emit(result.get("message", "Purchase failed"))

func _local_sell(world_id: String, shop_id: String, item_id: String, quantity: int) -> void:
	var sm = get_node_or_null("/root/ShopManager")
	if sm:
		var result = sm.sell_crop(item_id, quantity)
		if result.get("success", false):
			sale_completed.emit(item_id, quantity, result.get("total_earned", 0))
		else:
			shop_error.emit(result.get("message", "Sale failed"))
