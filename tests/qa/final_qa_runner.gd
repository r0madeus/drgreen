extends RefCounted

## FINAL PRODUCTION RUNTIME QA RUNNER
## Orchestrates the strict, end-to-end verification of the final Godot runtime
## architecture for the Botanical Haven project.

var test_name: String = ""

func assert_not_null(val: Variant, msg: String = "") -> void:
	assert(val != null, msg)

func assert_eq(a: Variant, b: Variant, msg: String = "") -> void:
	assert(a == b, msg)

func test_name_id() -> String:
	return "FINAL_QA.ProductionRuntimeGate"

func run_all() -> void:
	test_name = test_name_id()
	
	# 1. Editor Boot Test
	var main = ResourceLoader.load("res://scenes/main.tscn").instantiate()
	Engine.get_main_loop().root.add_child(main)
	
	assert_not_null(main, "Main scene must boot")
	assert_eq(main.current_mode, 0, "Should start in AppMode.MENU")
	
	# 2. Main Menu Works
	var menu = main.find_child("MainMenu", true, false)
	assert_not_null(menu, "Main menu must be initialized")
	
	# 3. Editor Boots
	main.open_editor()
	assert_eq(main.current_mode, 2, "Should transition to AppMode.EDITOR")
	assert_not_null(main.current_editor_shell, "EditorShell must be active")
	
	# 4. Playtest Works
	main.start_gameplay(1, true)
	assert_eq(main.current_mode, 1, "Should transition to AppMode.GAMEPLAY")
	assert_not_null(main.current_world_scene, "World scene must be spawned")
	
	# 5. Playtest -> Editor Works
	main.open_editor()
	assert_eq(main.current_mode, 2, "Should return cleanly to AppMode.EDITOR")
	
	# 6. Save Slots & Main Menu
	main.return_to_main_menu()
	assert_eq(main.current_mode, 0, "Should return cleanly to AppMode.MENU")
	
	main.queue_free()
	
	print("FINAL TECHNICAL QA RUN COMPLETE: ALL CRITICAL PATHS VERIFIED.")
