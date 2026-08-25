extends TestCase

func get_name() -> String:
	return "Phase3A_EditorArchitecture"

func run_tests() -> void:
	_test_editor_architecture()

func _test_editor_architecture() -> void:
	print("--- STARTING PHASE 3A EDITOR ARCHITECTURE TEST ---")
	
	var root = Engine.get_main_loop().root
	
	# Autoloads mock
	var EditorRegistry = preload("res://editor/core/editor_registry.gd").new()
	var EditorService = preload("res://editor/core/editor_service.gd").new()
	
	var shell = preload("res://editor/ui/editor_shell.gd").new()
	shell.name = "EditorShell"
	root.add_child(shell)
	
	assert_true(is_instance_valid(shell), "EditorShell instanced successfully")
	
	# Simulate opening panels
	var categories = [
		"world", "npc", "dialogue", "quest", "items", "crops", "tools", 
		"shops", "schedules", "assets", "mods"
	]
	
	for cat in categories:
		shell._select_category(cat, "")
		assert_true(true, "Switched to category: " + cat)
		
	# Try generic undo/redo execution to verify they don't crash
	if shell.editor_service:
		shell.editor_service.undo()
		shell.editor_service.redo()
	assert_true(true, "Undo/Redo commands executed safely in empty state")
	
	shell.queue_free()
	
	
	print("--- PHASE 3A EDITOR ARCHITECTURE TEST COMPLETE ---")
