$content = Get-Content 'editor\world_builder\world_canvas.gd' -Raw

$insert = "
	# Lighting Debug Overlay
	if show_lighting_debug:
		for o in world_data.get('objects', []):
			var overrides = o.get('properties', {})
			var props = overrides
			if ClassDB.class_exists('AssetDefinitionManager'):
				props = AssetDefinitionManager.resolve_instance_properties(o.get('asset_id', ''), overrides)
			if props.get('emits_light', false):
				var p = o.get('position', [0, 0])
				var center = pan_offset + Vector2(int(p[0]) * ts + ts * 0.5, int(p[1]) * ts + ts * 0.5)
				var radius = float(props.get('light_radius', 64)) * zoom_level
				var col_hex = props.get('light_color', '#FFFFFF')
				var col = Color(col_hex)
				col.a = 0.2
				draw_circle(center, radius, col)
				col.a = 0.8
				draw_arc(center, radius, 0, TAU, 32, col, 2.0)
"
$content = $content -replace 'var show_navigation_debug: bool = false', "var show_navigation_debug: bool = false
var show_lighting_debug: bool = false"
$content = $content.Replace("	# Autotile Debug Overlay", $insert + "

	# Autotile Debug Overlay")

Set-Content 'editor\world_builder\world_canvas.gd' -Value $content
