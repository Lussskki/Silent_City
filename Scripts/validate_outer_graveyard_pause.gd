extends SceneTree

const SCENE_PATH := "res://Scenes/OuterGraveyardMoonlit.tscn"


func _init() -> void:
	call_deferred(&"_run_validation")


func _run_validation() -> void:
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		_fail("could not load level scene")
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame

	var hud := scene.get_node("PlayerHUD")
	var pause_menu := scene.get_node("PlayerHUD/PauseMenu") as Control
	var main_menu_button := scene.get_node(
		"PlayerHUD/PauseMenu/Box/MainMenuButton"
	) as Button

	Input.action_press(&"ui_cancel")
	await process_frame
	Input.action_release(&"ui_cancel")
	await process_frame

	if not pause_menu.visible or not paused:
		_fail("Escape did not open and pause the game")
		return
	if main_menu_button == null or main_menu_button.pressed.get_connections().is_empty():
		_fail("Main Menu button is not connected")
		return

	hud.call(&"_return_to_game")
	await process_frame
	if pause_menu.visible or paused:
		_fail("Return to Game did not close and unpause")
		return

	Input.action_press(&"ui_cancel")
	await process_frame
	Input.action_release(&"ui_cancel")
	await process_frame
	main_menu_button.emit_signal(&"pressed")
	await process_frame
	await process_frame
	if current_scene == null or current_scene.scene_file_path != "res://Scenes/MainMenu.tscn":
		_fail("Main Menu button did not leave the level")
		return

	print("Outer Graveyard pause validation passed: Escape, resume, and Main Menu exit work")
	current_scene.queue_free()
	await process_frame
	quit()


func _fail(message: String) -> void:
	paused = false
	push_error("Outer Graveyard pause validation failed: %s" % message)
	quit(1)
