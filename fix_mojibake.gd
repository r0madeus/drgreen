extends SceneTree

func _init():
	var dir = DirAccess.open("res://editor")
	if dir:
		_process_dir("res://editor")
	quit()

func _process_dir(path: String):
	var dir = DirAccess.open(path)
	if not dir: return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			_process_dir(path + "/" + file_name)
		elif file_name.ends_with(".gd"):
			_clean_file(path + "/" + file_name)
		file_name = dir.get_next()

func _clean_file(path: String):
	var f = FileAccess.open(path, FileAccess.READ)
	if not f: return
	var content = f.get_as_text()
	f.close()
	var original = content
	
	var reps = {
		"🌿": "", "💾": "[Save]", "🔄": "[Reset]", "� ": "[World]",
		"👤": "[NPC]", "💬": "[Dialogue]", "📜": "[Quest]", "�Z�": "[Item]",
		"🌱": "[Crop]", "� �": "[Shop]", "📦": "[Asset]", "🗺� ": "[Map]",
		"🗂� ": "[Layers]", "� ": "[Select]", "🖌� ": "[Paint]", "🧹": "[Erase]",
		"🪣": "[Fill]", "� ": "[Spawn]", "🚪": "[Transition]", "� � ": "[Vis]",
		"🔒": "[Lock]", "▭": "[Rect]", "╱": "[Line]", "✦": "[Scatter]",
		"⚡": "[Event]", "??": "[Settings]", "??": "[Transition]", "?": "[Scatter]",
		"??": "[Line]", "� �� ": "[Tile]", "âš™ï¸� ": "[Inspector]", "ğŸ“¦": "[Assets]",
		"ğŸ—‚ï¸� ": "[Layers]", "â–­": "[Rect]", "â•±": "[Line]", "âœ¦": "[Scatter]",
		"ğŸ� � ": "[Select]", "ğŸ–Œï¸� ": "[Paint]", "ğŸ§¹": "[Erase]", "ğŸª£": "[Fill]",
		"🧩": "[Component]", "â™›": "[Cog]"
	}
	
	for k in reps.keys():
		content = content.replace(k, reps[k])
		
	content = content.replace("[Save] Save", "[Save]")
	content = content.replace("[Reset] Reset All", "[Reset All]")
	
	if content != original:
		f = FileAccess.open(path, FileAccess.WRITE)
		f.store_string(content)
		f.close()
		print("Cleaned ", path)
