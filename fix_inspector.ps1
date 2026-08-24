$content = Get-Content 'editor\world_builder\world_inspector.gd' -Raw

$replace = "
		var overrides = data.get('properties', {})
		var asset_id = data.get('asset_id', '')
		var props = overrides
		if ClassDB.class_exists('AssetDefinitionManager'):
			props = AssetDefinitionManager.resolve_instance_properties(asset_id, overrides)
			
		var indicate_override = func(chk: CheckBox, p_name: String, def_val: bool, label_text: String):
			if not chk: return
			chk.button_pressed = bool(props.get(p_name, def_val))
			if overrides.has(p_name):
				chk.text = label_text + ' [Override]'
				chk.modulate = Color(1.0, 0.8, 0.2)
			else:
				chk.text = label_text
				chk.modulate = Color.WHITE

		indicate_override.call(walkable_check, 'walkable', false, 'Walkable')
		indicate_override.call(solid_check, 'solid', true, 'Solid')
		indicate_override.call(interactable_check, 'interactable', true, 'Interactable')
"

$content = $content -replace '(?s)		var props = data\.get\("properties", \{\}\).*?if interactable_check: interactable_check\.button_pressed = bool\(props\.get\("interactable", true\)\)', $replace.TrimEnd()

Set-Content 'editor\world_builder\world_inspector.gd' -Value $content
