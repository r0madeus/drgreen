extends Node
class_name CutsceneManager

signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String)
signal catalog_updated

var cutscene_catalog: Dictionary = {}
var _data_dir: String = "res://data/cutscenes/"

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(_data_dir):
		DirAccess.make_dir_recursive_absolute(_data_dir)
	load_catalog()

func load_catalog() -> void:
	cutscene_catalog.clear()
	if not DirAccess.dir_exists_absolute(_data_dir):
		return
		
	var dir = DirAccess.open(_data_dir)
	if not dir:
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var p = _data_dir + file_name
			var f = FileAccess.open(p, FileAccess.READ)
			if f:
				var text = f.get_as_text()
				f.close()
				var json = JSON.new()
				if json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY:
					var cid = str(json.data.get("id", file_name.trim_suffix(".json")))
					cutscene_catalog[cid] = json.data
		file_name = dir.get_next()
	
	catalog_updated.emit()

func save_cutscene(cutscene_data: Dictionary) -> bool:
	var cid = cutscene_data.get("id", "")
	if cid == "":
		return false
		
	var p = _data_dir + cid + ".json"
	var f = FileAccess.open(p, FileAccess.WRITE)
	if not f:
		return false
		
	var json_str = JSON.stringify(cutscene_data, "	")
	f.store_string(json_str)
	f.close()
	
	cutscene_catalog[cid] = cutscene_data.duplicate(true)
	catalog_updated.emit()
	return true

func delete_cutscene(cid: String) -> bool:
	if not cutscene_catalog.has(cid):
		return false
	var p = _data_dir + cid + ".json"
	if FileAccess.file_exists(p):
		var err = DirAccess.remove_absolute(p)
		if err != OK:
			return false
	cutscene_catalog.erase(cid)
	catalog_updated.emit()
	return true

func get_cutscene(cid: String) -> Dictionary:
	return cutscene_catalog.get(cid, {}).duplicate(true)

func create_new_cutscene(cid: String, display_name: String = "") -> Dictionary:
	if display_name == "":
		display_name = cid.capitalize()
		
	var data = {
		"id": cid,
		"display_name": display_name,
		"description": "",
		"duration": 5.0,
		"trigger": {},
		"actors": ["player"],
		"tracks": [
			{
				"actor_id": "player",
				"events": []
			}
		]
	}
	save_cutscene(data)
	return data
