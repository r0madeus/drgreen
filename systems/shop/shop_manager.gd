extends Node

## Central shop management singleton controlling catalog stock, buy/sell pricing and transactions.

var shop_catalogs: Dictionary = {} # shop_id -> Dictionary

signal item_purchased(item_id: String, count: int, total_price: int)
signal item_sold(item_id: String, count: int, total_earnings: int)

func _ready() -> void:
	load_all_shops()

func load_all_shops() -> void:
	shop_catalogs.clear()
	var files = DirAccess.get_files_at("res://data/shops/")
	for file_name in files:
		if file_name.ends_with(".json"):
			var path = "res://data/shops/" + file_name
			var f = FileAccess.open(path, FileAccess.READ)
			if f:
				var text = f.get_as_text()
				f.close()
				var json = JSON.new()
				if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
					var sid = str(json.data.get("id", file_name.trim_suffix(".json")))
					shop_catalogs[sid] = json.data
	print("[ShopManager] Loaded %d Shop catalogs." % shop_catalogs.size())


func get_shop(shop_id: String) -> Dictionary:
	return shop_catalogs.get(shop_id, {})

func buy_item(player_id: String, shop_id: String, item_id: String, count: int = 1) -> Dictionary:
	var shop = get_shop(shop_id)
	if shop.is_empty():
		return { "success": false, "message": "Shop not found." }
		
	var item_entry: Dictionary = {}
	for itm in shop.get("items", []):
		if itm.get("item_id") == item_id:
			item_entry = itm
			break
			
	if item_entry.is_empty():
		return { "success": false, "message": "Item not in shop catalog." }
		
	var unit_price = int(item_entry.get("buy_price", 20))
	var total_price = unit_price * count
	
	var em = get_node_or_null("/root/EconomyManager")
	if not em or not em.can_afford(total_price):
		return { "success": false, "message": "Not enough Gold!" }
		
	var im = get_node_or_null("/root/InventoryManager")
	if not im:
		return { "success": false, "message": "InventoryManager not available." }
		
	if not em.spend_gold(player_id, total_price):
		return { "success": false, "message": "Transaction failed." }
		
	im.add_item(player_id, item_id, count)
	item_purchased.emit(item_id, count, total_price)
	EventBus.item_bought.emit(item_id, count, total_price)
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("purchase")
		
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		var dname = item_id.replace("_", " ").capitalize()
		spawner.spawn_floating_text(pos, "🛒 +%d %s (-%d G)" % [count, dname, total_price], Color(1.0, 0.9, 0.2))
		
	return { "success": true, "message": "Purchase successful!", "total_price": total_price }

func sell_crop(player_id: String, item_id: String, count: int = 1) -> Dictionary:
	var im = get_node_or_null("/root/InventoryManager")
	if not im or not im.has_item(item_id, count):
		return { "success": false, "message": "Not enough items in inventory." }
		
	var pm = get_node_or_null("/root/PlantManager")
	var base_sell_price = 20
	if pm:
		var pinfo = pm.get_plant(item_id)
		if not pinfo.is_empty():
			base_sell_price = int(pinfo.get("sell_price", 20))
			
	var em = get_node_or_null("/root/EconomyManager")
	var mult = em.get_sell_price_multiplier(item_id) if em else 1.0
	var unit_price = int(round(base_sell_price * mult))
	var total_earnings = unit_price * count
	
	if not im.remove_item(item_id, count):
		return { "success": false, "message": "Failed to remove item from inventory." }
		
	if em: em.add_gold(player_id, total_earnings)
		
	item_sold.emit(item_id, count, total_earnings)
	EventBus.item_sold.emit(item_id, count, total_earnings)
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("sell")
		
	var spawner = EffectSpawner.get_instance()
	var player = get_tree().root.find_child("Player", true, false)
	var pos = player.global_position if player else Vector2(240, 180)
	if spawner:
		var dname = item_id.replace("_", " ").capitalize()
		spawner.spawn_floating_text(pos, "💰 Sold %dx %s (+%d G)" % [count, dname, total_earnings], Color(0.4, 1.0, 0.4))
		
	return { "success": true, "message": "Sold successfully!", "total_earnings": total_earnings }
