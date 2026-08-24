$content = Get-Content 'editor\world_builder\world_canvas.gd' -Raw

$collision_replace = "
	if show_collision_debug:
		for t in world_data.get('tiles', []):
			var rect = Rect2(pan_offset.x + int(t['x']) * ts, pan_offset.y + int(t['y']) * ts, ts, ts)
			if t.get('solid', false): draw_rect(rect, Color(1.0, 0.2, 0.2, 0.35))
			elif t.get('interactable', false): draw_rect(rect, Color(1.0, 0.9, 0.2, 0.35))
			else: draw_rect(rect, Color(0.2, 1.0, 0.2, 0.20))
		for o in world_data.get('objects', []):
			var props = o.get('properties', {})
			if ClassDB.class_exists('AssetDefinitionManager'): props = AssetDefinitionManager.resolve_instance_properties(o.get('asset_id', ''), props)
			var p = o.get('position', [0, 0])
			var rect = Rect2(pan_offset.x + int(p[0]) * ts, pan_offset.y + int(p[1]) * ts, ts, ts)
			if props.get('solid', false): draw_rect(rect, Color(1.0, 0.2, 0.2, 0.5))
"

$navigation_replace = "
	if show_navigation_debug:
		for t in world_data.get('tiles', []):
			var rect = Rect2(pan_offset.x + int(t['x']) * ts, pan_offset.y + int(t['y']) * ts, ts, ts)
			if t.get('solid', false): draw_rect(rect, Color(1.0, 0.1, 0.1, 0.30))
			elif t.get('walkable', true): draw_rect(rect, Color(0.2, 0.9, 0.2, 0.18))
		for o in world_data.get('objects', []):
			var props = o.get('properties', {})
			if ClassDB.class_exists('AssetDefinitionManager'): props = AssetDefinitionManager.resolve_instance_properties(o.get('asset_id', ''), props)
			var p = o.get('position', [0, 0])
			var rect = Rect2(pan_offset.x + int(p[0]) * ts, pan_offset.y + int(p[1]) * ts, ts, ts)
			if props.get('interactable', false):
				draw_rect(rect, Color(1.0, 0.85, 0.2, 0.4))
				draw_circle(rect.get_center(), 3.0, Color(1.0, 0.85, 0.2))
			if props.get('solid', false) or not props.get('walkable', true):
				draw_rect(rect, Color(1.0, 0.1, 0.1, 0.4))
"

$content = $content -replace '(?s)	if show_collision_debug:.*?draw_rect\(rect, Color\(0\.2, 1\.0, 0\.2, 0\.20\)\)', $collision_replace.TrimEnd()
$content = $content -replace '(?s)	if show_navigation_debug:.*?draw_circle\(rect\.get_center\(\), 3\.0, Color\(1\.0, 0\.85, 0\.2\)\)', $navigation_replace.TrimEnd()

Set-Content 'editor\world_builder\world_canvas.gd' -Value $content
