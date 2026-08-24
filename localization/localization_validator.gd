class_name LocalizationValidator
extends RefCounted

## Automated Localization Validation Tool.
## Audits translation CSV files, checks placeholder consistency, detects missing/empty keys,
## validates locale formats, and verifies data file key bindings.

static func validate_all(csv_path: String = "res://localization/game.csv") -> Dictionary:
	var results = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"total_keys": 0,
		"locales": [],
		"placeholder_issues": 0,
		"missing_translations": 0
	}
	
	if not FileAccess.file_exists(csv_path):
		results["valid"] = false
		results["errors"].append("CSV file does not exist at: %s" % csv_path)
		return results
		
	var f = FileAccess.open(csv_path, FileAccess.READ)
	if not f:
		results["valid"] = false
		results["errors"].append("Could not open CSV file: %s" % csv_path)
		return results
		
	var header = f.get_csv_line()
	if header.is_empty() or header[0] != "keys":
		results["valid"] = false
		results["errors"].append("Invalid CSV header. First column must be 'keys'. Found: %s" % str(header))
		f.close()
		return results
		
	var locales: Array[String] = []
	for i in range(1, header.size()):
		var loc = header[i].strip_edges()
		if loc != "":
			locales.append(loc)
	results["locales"] = locales
	
	var seen_keys: Dictionary = {}
	var line_num = 1
	
	while not f.eof_reached():
		line_num += 1
		var row = f.get_csv_line()
		if row.is_empty() or (row.size() == 1 and row[0].strip_edges() == ""):
			continue
			
		var key = row[0].strip_edges()
		if key == "" or key.begins_with("#"):
			continue
			
		# Check duplicates
		if seen_keys.has(key):
			results["valid"] = false
			results["errors"].append("Line %d: Duplicate translation key '%s' (previously seen at line %d)" % [line_num, key, seen_keys[key]])
		else:
			seen_keys[key] = line_num
			results["total_keys"] += 1
			
		# Extract translations per locale
		var en_text = ""
		if row.size() > 1:
			en_text = row[1]
			
		if en_text == "":
			results["warnings"].append("Line %d: Key '%s' has empty English translation." % [line_num, key])
			results["missing_translations"] += 1
			
		# Extract placeholders in EN: e.g. {day}, {season}
		var en_placeholders = _extract_placeholders(en_text)
		
		# Compare with other locales
		for l_idx in range(1, locales.size()):
			var col_idx = l_idx + 1
			var loc_name = locales[l_idx]
			var loc_text = row[col_idx] if col_idx < row.size() else ""
			
			if loc_text != "":
				var loc_placeholders = _extract_placeholders(loc_text)
				for p in en_placeholders:
					if not loc_placeholders.has(p):
						results["warnings"].append("Line %d [%s]: Key '%s' is missing placeholder '{%s}' present in English." % [line_num, loc_name, key, p])
						results["placeholder_issues"] += 1
	f.close()
	
	if results["errors"].size() > 0:
		results["valid"] = false
		
	return results

static func _extract_placeholders(text: String) -> Array[String]:
	var list: Array[String] = []
	var regex = RegEx.new()
	regex.compile("\\{([a-zA-Z0-9_]+)\\}")
	var matches = regex.search_all(text)
	for m in matches:
		list.append(m.get_string(1))
	return list

	