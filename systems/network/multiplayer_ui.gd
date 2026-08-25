class_name MultiplayerUI
extends Control

## Cozy Botanical Fantasy Co-op Multiplayer Lobby Menu.
## Manages Hosting, Joining, IP/Port validation, Connection Lifecycle,
## and clean transitions to Gameplay or Main Menu.

signal back_pressed()
signal closed()
signal host_started(port: int)
signal client_connected(peer_id: int)
signal session_disconnected()

enum ConnectionState {
	IDLE,
	HOSTING,
	CONNECTING,
	CONNECTED,
	DISCONNECTED,
	CONNECTION_FAILED
}

var current_state: ConnectionState = ConnectionState.IDLE
var is_busy: bool = false

var panel: PanelContainer
var title_label: Label
var subtitle_label: Label
var status_label: Label
var name_lbl: Label
var ip_lbl: Label
var port_lbl: Label
var name_input: LineEdit
var ip_input: LineEdit
var port_input: LineEdit
var host_btn: Button
var join_btn: Button
var disconnect_btn: Button
var back_btn: Button

func _init() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	grow_horizontal = GROW_DIRECTION_BOTH
	grow_vertical = GROW_DIRECTION_BOTH

func _ready() -> void:
	_build_ui()
	_bind_network_events()
	_update_localized_texts()
	
	var lm = get_node_or_null("/root/LocalizationManager")
	if lm:
		lm.locale_changed.connect(func(_l): _update_localized_texts())
		
	visible = false

func _build_ui() -> void:
	# 1. Background Dim
	var bg = ColorRect.new()
	bg.name = "BackgroundDim"
	bg.color = Color(0.04, 0.07, 0.05, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bg.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(bg)
	
	# 2. Center Container
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(center)
	
	# 3. Main Panel Container
	panel = PanelContainer.new()
	panel.name = "PanelContainer"
	panel.custom_minimum_size = Vector2(420, 380)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.12, 0.95)
	style.border_color = Color(0.35, 0.65, 0.45, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# 4. Header Labels
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "🌿 CO-OP MULTIPLAYER"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.modulate = Color(0.5, 1.0, 0.6, 1.0)
	vbox.add_child(title_label)
	
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.text = "Host or join a cooperative botanical haven"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 11)
	subtitle_label.modulate = Color(0.8, 0.9, 0.8, 0.8)
	vbox.add_child(subtitle_label)
	
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# 5. Status Label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Status: Offline"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.modulate = Color(0.7, 0.85, 0.75, 1.0)
	vbox.add_child(status_label)
	
	# 6. Player Name Row
	var name_box = HBoxContainer.new()
	name_lbl = Label.new()
	name_lbl.text = "Player Name:"
	name_lbl.custom_minimum_size = Vector2(100, 0)
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_input = LineEdit.new()
	name_input.text = "Botanist"
	name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_box.add_child(name_lbl)
	name_box.add_child(name_input)
	vbox.add_child(name_box)
	
	# 7. IP Address Row
	var ip_box = HBoxContainer.new()
	ip_lbl = Label.new()
	ip_lbl.text = "IP Address:"
	ip_lbl.custom_minimum_size = Vector2(100, 0)
	ip_lbl.add_theme_font_size_override("font_size", 12)
	ip_input = LineEdit.new()
	ip_input.text = "127.0.0.1"
	ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip_box.add_child(ip_lbl)
	ip_box.add_child(ip_input)
	vbox.add_child(ip_box)
	
	# 8. Port Row
	var port_box = HBoxContainer.new()
	port_lbl = Label.new()
	port_lbl.text = "Port:"
	port_lbl.custom_minimum_size = Vector2(100, 0)
	port_lbl.add_theme_font_size_override("font_size", 12)
	port_input = LineEdit.new()
	port_input.text = "7000"
	port_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	port_box.add_child(port_lbl)
	port_box.add_child(port_input)
	vbox.add_child(port_box)
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# 9. Action Buttons
	host_btn = Button.new()
	host_btn.name = "HostButton"
	host_btn.custom_minimum_size = Vector2(0, 32)
	host_btn.text = "✨ Host Game (Server)"
	host_btn.pressed.connect(_on_host_pressed)
	vbox.add_child(host_btn)
	
	join_btn = Button.new()
	join_btn.name = "JoinButton"
	join_btn.custom_minimum_size = Vector2(0, 32)
	join_btn.text = "🌱 Join Game (Client)"
	join_btn.pressed.connect(_on_join_pressed)
	vbox.add_child(join_btn)
	
	disconnect_btn = Button.new()
	disconnect_btn.name = "DisconnectButton"
	disconnect_btn.custom_minimum_size = Vector2(0, 30)
	disconnect_btn.text = "❌ Disconnect / Cancel"
	disconnect_btn.pressed.connect(_on_disconnect_pressed)
	disconnect_btn.visible = false
	vbox.add_child(disconnect_btn)
	
	back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.custom_minimum_size = Vector2(0, 30)
	back_btn.text = "⬅️ Back to Main Menu"
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)
	
	center.add_child(panel)

func _bind_network_events() -> void:
	var nm = get_node_or_null("/root/NetworkManager")
	if nm:
		if not nm.host_started.is_connected(_on_network_host_started):
			nm.host_started.connect(_on_network_host_started)
		if not nm.connected.is_connected(_on_network_connected):
			nm.connected.connect(_on_network_connected)
		if not nm.disconnected.is_connected(_on_network_disconnected):
			nm.disconnected.connect(_on_network_disconnected)
		if not nm.connection_failed.is_connected(_on_network_connection_failed):
			nm.connection_failed.connect(_on_network_connection_failed)

func _update_localized_texts() -> void:
	if title_label: title_label.text = "🌿 " + tr("multiplayer.title")
	if subtitle_label: subtitle_label.text = tr("multiplayer.subtitle")
	if name_lbl: name_lbl.text = tr("multiplayer.player_name")
	if ip_lbl: ip_lbl.text = tr("multiplayer.ip")
	if port_lbl: port_lbl.text = tr("multiplayer.port")
	if host_btn: host_btn.text = tr("multiplayer.host")
	if join_btn: join_btn.text = tr("multiplayer.join")
	if disconnect_btn: disconnect_btn.text = tr("multiplayer.disconnect")
	if back_btn: back_btn.text = tr("multiplayer.back")
	_update_state_ui()

func _update_state_ui() -> void:
	if not status_label: return
	
	match current_state:
		ConnectionState.IDLE:
			status_label.text = tr("multiplayer.status_offline")
			status_label.modulate = Color(0.7, 0.85, 0.75)
			if host_btn: host_btn.disabled = false
			if join_btn: join_btn.disabled = false
			if disconnect_btn: disconnect_btn.visible = false
			_set_inputs_enabled(true)
		ConnectionState.HOSTING:
			var port = port_input.text if port_input else "7000"
			status_label.text = tr("multiplayer.status_hosting").replace("{ip}", "127.0.0.1").replace("{port}", port)
			status_label.modulate = Color(0.4, 1.0, 0.6)
			if host_btn: host_btn.disabled = true
			if join_btn: join_btn.disabled = true
			if disconnect_btn: disconnect_btn.visible = true
			_set_inputs_enabled(false)
		ConnectionState.CONNECTING:
			var ip = ip_input.text if ip_input else "127.0.0.1"
			var port = port_input.text if port_input else "7000"
			status_label.text = tr("multiplayer.status_connecting").replace("{ip}", ip).replace("{port}", port)
			status_label.modulate = Color(1.0, 0.85, 0.4)
			if host_btn: host_btn.disabled = true
			if join_btn: join_btn.disabled = true
			if disconnect_btn: disconnect_btn.visible = true
			_set_inputs_enabled(false)
		ConnectionState.CONNECTED:
			var nm = get_node_or_null("/root/NetworkManager")
			var pid = str(nm.get_local_peer_id()) if nm else "1"
			status_label.text = tr("multiplayer.status_connected").replace("{peer_id}", pid)
			status_label.modulate = Color(0.3, 1.0, 0.5)
			if host_btn: host_btn.disabled = true
			if join_btn: join_btn.disabled = true
			if disconnect_btn: disconnect_btn.visible = true
			_set_inputs_enabled(false)
		ConnectionState.DISCONNECTED:
			status_label.text = tr("multiplayer.status_disconnected")
			status_label.modulate = Color(0.8, 0.8, 0.8)
			if host_btn: host_btn.disabled = false
			if join_btn: join_btn.disabled = false
			if disconnect_btn: disconnect_btn.visible = false
			_set_inputs_enabled(true)
		ConnectionState.CONNECTION_FAILED:
			status_label.modulate = Color(1.0, 0.4, 0.4)
			if host_btn: host_btn.disabled = false
			if join_btn: join_btn.disabled = false
			if disconnect_btn: disconnect_btn.visible = false
			_set_inputs_enabled(true)

func _set_inputs_enabled(enabled: bool) -> void:
	if name_input: name_input.editable = enabled
	if ip_input: ip_input.editable = enabled
	if port_input: port_input.editable = enabled

func open_ui() -> void:
	visible = true
	_update_localized_texts()
	
	# Pre-populate name if available
	var psm = get_node_or_null("/root/PlayerRegistry")
	if psm and name_input:
		var st = psm.get_local_player_state()
		if st and st.display_name != "":
			name_input.text = st.display_name
			
	var nm = get_node_or_null("/root/NetworkManager")
	if nm and not nm.is_offline():
		if nm.is_host():
			current_state = ConnectionState.HOSTING
		else:
			current_state = ConnectionState.CONNECTED
	else:
		current_state = ConnectionState.IDLE
	_update_state_ui()

func close_ui() -> void:
	visible = false
	closed.emit()

func toggle_visibility() -> void:
	if visible: close_ui()
	else: open_ui()

func _on_host_pressed() -> void:
	if is_busy: return
	is_busy = true
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	var port_str = port_input.text.strip_edges() if port_input else "7000"
	if not port_str.is_valid_int():
		current_state = ConnectionState.CONNECTION_FAILED
		if status_label:
			status_label.text = tr("multiplayer.error.invalid_address")
		_update_state_ui()
		is_busy = false
		return
	var port = int(port_str)
	if port <= 1024 or port > 65535:
		current_state = ConnectionState.CONNECTION_FAILED
		if status_label:
			status_label.text = tr("multiplayer.error.invalid_address")
		_update_state_ui()
		is_busy = false
		return
		
	_apply_player_name()
	
	var nm = get_node_or_null("/root/NetworkManager")
	if nm:
		var ok = nm.create_host(port)
		if ok:
			current_state = ConnectionState.HOSTING
			host_started.emit(port)
			_update_state_ui()
			_enter_multiplayer_gameplay()
		else:
			current_state = ConnectionState.CONNECTION_FAILED
			if status_label:
				status_label.text = tr("multiplayer.error.server_creation_failed").replace("{port}", str(port))
			_update_state_ui()
	is_busy = false

func _on_join_pressed() -> void:
	if is_busy: return
	is_busy = true
	
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	var ip_str = ip_input.text.strip_edges() if ip_input else "127.0.0.1"
	var port_str = port_input.text.strip_edges() if port_input else "7000"
	if ip_str == "" or not port_str.is_valid_int():
		current_state = ConnectionState.CONNECTION_FAILED
		if status_label:
			status_label.text = tr("multiplayer.error.invalid_address")
		_update_state_ui()
		is_busy = false
		return
	var port = int(port_str)
	if port <= 1024 or port > 65535:
		current_state = ConnectionState.CONNECTION_FAILED
		if status_label:
			status_label.text = tr("multiplayer.error.invalid_address")
		_update_state_ui()
		is_busy = false
		return

		
	_apply_player_name()
	
	current_state = ConnectionState.CONNECTING
	_update_state_ui()
	
	var nm = get_node_or_null("/root/NetworkManager")
	if nm:
		var ok = nm.join_host(ip_str, port)
		if not ok:
			current_state = ConnectionState.CONNECTION_FAILED
			if status_label:
				status_label.text = tr("multiplayer.error.connection_failed")
			_update_state_ui()
	is_busy = false

func _on_disconnect_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	var nm = get_node_or_null("/root/NetworkManager")
	if nm:
		nm.disconnect_session()
		
	current_state = ConnectionState.DISCONNECTED
	_update_state_ui()
	session_disconnected.emit()

func _on_back_pressed() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.play_sfx("ui_select")
	
	close_ui()
	back_pressed.emit()

func _apply_player_name() -> void:
	var p_name = name_input.text.strip_edges() if name_input else "Botanist"
	if p_name == "": p_name = "Botanist"
	
	var psm = get_node_or_null("/root/PlayerRegistry")
	if psm:
		var st = psm.get_local_player_state()
		if st: st.display_name = p_name

func _enter_multiplayer_gameplay() -> void:
	var loop = Engine.get_main_loop()
	var root = loop.root if (loop and "root" in loop) else null
	var main = root.find_child("Main", true, false) if root else null
	if main and main.has_method("start_gameplay"):
		visible = false
		main.start_gameplay(1, false)

func _on_network_host_started() -> void:
	current_state = ConnectionState.HOSTING
	_update_state_ui()

func _on_network_connected() -> void:
	current_state = ConnectionState.CONNECTED
	_update_state_ui()
	client_connected.emit(1)
	_enter_multiplayer_gameplay()

func _on_network_disconnected() -> void:
	current_state = ConnectionState.DISCONNECTED
	_update_state_ui()
	session_disconnected.emit()

func _on_network_connection_failed(reason: String) -> void:
	current_state = ConnectionState.CONNECTION_FAILED
	if status_label:
		var err_text = tr("multiplayer.error.connection_failed")
		if reason != "":
			err_text += " (" + reason + ")"
		status_label.text = err_text
	_update_state_ui()
