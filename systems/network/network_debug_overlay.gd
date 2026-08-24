class_name NetworkDebugOverlay
extends CanvasLayer

## Developer Network Debug Overlay (toggle with F6 or programmatic toggle).

var label: Label
var panel: PanelContainer

func _ready() -> void:
	layer = 120
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	visible = false # Hidden by default, toggleable

func _create_ui() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(8, 40)
	panel.custom_minimum_size = Vector2(160, 90)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.85)
	style.border_color = Color(0.3, 0.6, 0.5, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	
	label = Label.new()
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9))
	panel.add_child(label)
	add_child(panel)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F6:
			visible = not visible

func _process(_delta: float) -> void:
	if not visible: return
	
	var nm = get_node_or_null("/root/NetworkManager")
	var wm = get_node_or_null("/root/WorldManager")
	if not nm: return
	
	var mode_str = nm.get_connection_status()
	var peer_id = nm.get_local_peer_id()
	var peer_count = nm.get_connected_peers().size()
	var world_id = wm.get_current_world() if wm else "farm"
	var auth_str = "Host" if nm.is_host() else ("Client" if nm.is_client() else "Local")
	
	label.text = "🌐 NETWORK DEBUG (F6)\nMode: %s\nPeer ID: %d\nPeers: %d / 4\nWorld: %s\nAuthority: %s" % [
		mode_str, peer_id, peer_count, world_id.capitalize(), auth_str
	]
