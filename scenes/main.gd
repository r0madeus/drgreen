@tool
class_name Main
extends Node

## Central application coordinator for Botanical Haven.
## Manages App Mode (MENU, GAMEPLAY, EDITOR), Bootstrap Flow,
## Scene Containers, and Transitions without race conditions.

enum AppMode {
	MENU,
	GAMEPLAY,
	EDITOR
}

var current_mode: AppMode = AppMode.MENU
var is_transitioning: bool = false

@onready var scene_container: Node2D = get_node_or_null("SceneContainer")
@onready var editor_container: CanvasLayer = get_node_or_null("EditorContainer")
@onready var ui_container: CanvasLayer = get_node_or_null("UIContainer")
@onready var main_menu: Control = get_node_or_null("UIContainer/MainMenu")

var current_world_scene: Node = null
var current_editor_shell: EditorShell = null

func _ready() -> void:
	_setup_nodes()
	_connect_menu_signals()
	enter_menu_mode()

func _setup_nodes() -> void:
	if not scene_container:
		scene_container = get_node_or_null("SceneContainer")
		if not scene_container:
			scene_container = find_child("SceneContainer", true, false) as Node2D
		if not scene_container:
			scene_container = Node2D.new()
			scene_container.name = "SceneContainer"
			add_child(scene_container)
		
	if not editor_container:
		editor_container = get_node_or_null("EditorContainer")
		if not editor_container:
			editor_container = find_child("EditorContainer", true, false) as CanvasLayer
		if not editor_container:
			editor_container = CanvasLayer.new()
			editor_container.name = "EditorContainer"
			editor_container.layer = 80
			add_child(editor_container)
		
	if not ui_container:
		ui_container = get_node_or_null("UIContainer")
		if not ui_container:
			ui_container = find_child("UIContainer", true, false) as CanvasLayer
		if not ui_container:
			ui_container = CanvasLayer.new()
			ui_container.name = "UIContainer"
			ui_container.layer = 50
			add_child(ui_container)

	if not main_menu or not is_instance_valid(main_menu):
		main_menu = get_node_or_null("UIContainer/MainMenu")
		if not main_menu:
			main_menu = find_child("MainMenu", true, false)
		if not main_menu and ui_container:
			main_menu = ui_container.find_child("MainMenu", true, false)
		if not main_menu:
			var scene = ResourceLoader.load("res://ui/main_menu.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
			if scene:
				main_menu = scene.instantiate()
				if ui_container:
					ui_container.add_child(main_menu)
				else:
					add_child(main_menu)
	_connect_menu_signals()

func _connect_menu_signals() -> void:
	if not main_menu: return
	if main_menu.has_signal("new_game_started") and not main_menu.new_game_started.is_connected(_on_new_game_started):
		main_menu.new_game_started.connect(_on_new_game_started)
	if main_menu.has_signal("game_continued") and not main_menu.game_continued.is_connected(_on_game_continued):
		main_menu.game_continued.connect(_on_game_continued)
	if main_menu.has_signal("editor_requested") and not main_menu.editor_requested.is_connected(_on_editor_requested):
		main_menu.editor_requested.connect(_on_editor_requested)

func _get_safe_node(node_name: String) -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null(node_name)
	return null

func enter_menu_mode() -> void:
	current_mode = AppMode.MENU
	is_transitioning = false
	var tm = _get_safe_node("TimeManager")
	if tm and "is_paused" in tm: tm.is_paused = true
	
	_clear_gameplay()
	_clear_editor()
	
	if main_menu and is_instance_valid(main_menu) and main_menu.has_method("open_menu"):
		main_menu.open_menu()

func start_gameplay(slot_idx: int = 1, is_new: bool = false) -> void:
	if not editor_container or not scene_container:
		_setup_nodes()
	if is_transitioning: return
	is_transitioning = true
	
	if main_menu and is_instance_valid(main_menu):
		main_menu.visible = false
		
	_clear_editor()
	_clear_gameplay()
	
	var farm_scene = ResourceLoader.load("res://scenes/farm.tscn", "", ResourceLoader.CACHE_MODE_IGNORE)
	if farm_scene:
		current_world_scene = farm_scene.instantiate()
		scene_container.add_child(current_world_scene)
		
		var nested_menu = current_world_scene.find_child("MainMenu", true, false)
		if nested_menu:
			nested_menu.visible = false
			
	var sm = _get_safe_node("SaveManager")
	if is_new:
		if sm and sm.has_method("new_game"): sm.new_game(slot_idx)
	else:
		if sm and sm.has_method("load_game"): sm.load_game(slot_idx)
		
	var tm = _get_safe_node("TimeManager")
	if tm and "is_paused" in tm: tm.is_paused = false
	
	var player = current_world_scene.find_child("Player", true, false) if current_world_scene else null
	if not player:
		player = find_child("Player", true, false)
	if player and is_instance_valid(player) and player.has_method("set_movement_locked"):
		player.set_movement_locked(false)
		
	current_mode = AppMode.GAMEPLAY
	is_transitioning = false

func open_editor() -> void:
	if not editor_container or not scene_container:
		_setup_nodes()
	if is_transitioning: return
	is_transitioning = true
	
	if main_menu and is_instance_valid(main_menu):
		main_menu.visible = false
		
	_clear_gameplay()
	_clear_editor()
	
	var tm = _get_safe_node("TimeManager")
	if tm and "is_paused" in tm: tm.is_paused = true
	
	current_editor_shell = EditorShell.new()
	current_editor_shell.name = "EditorShell"
	editor_container.add_child(current_editor_shell)

	if not current_editor_shell.exit_requested.is_connected(return_to_main_menu):
		current_editor_shell.exit_requested.connect(return_to_main_menu)
		
	if current_editor_shell.has_method("open_editor"):
		current_editor_shell.open_editor()
		
	current_mode = AppMode.EDITOR
	is_transitioning = false

func return_to_main_menu() -> void:
	if not editor_container or not scene_container:
		_setup_nodes()
	if is_transitioning: return
	is_transitioning = true
	
	_clear_editor()
	_clear_gameplay()
	
	var tm = _get_safe_node("TimeManager")
	if tm and "is_paused" in tm: tm.is_paused = true
	
	if main_menu and is_instance_valid(main_menu):
		main_menu.visible = true
		if main_menu.has_method("open_menu"):
			main_menu.open_menu()
		
	current_mode = AppMode.MENU
	is_transitioning = false

func _clear_gameplay() -> void:
	if scene_container:
		for c in scene_container.get_children():
			if is_instance_valid(c):
				c.queue_free()
	current_world_scene = null

func _clear_editor() -> void:
	if editor_container:
		for c in editor_container.get_children():
			if is_instance_valid(c):
				c.queue_free()
	current_editor_shell = null

func _on_new_game_started(slot_idx: int) -> void:
	start_gameplay(slot_idx, true)

func _on_game_continued(slot_idx: int) -> void:
	start_gameplay(slot_idx, false)

func _on_editor_requested() -> void:
	open_editor()
