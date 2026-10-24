extends SceneTree

const SCENE_PATH := "res://Scenes/OuterGraveyardMoonlit.tscn"
const OUTPUT_ROOT := "res://tmp/second_prompt_visuals"


func _init() -> void:
	call_deferred(&"_capture")


func _capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT))
	root.size = Vector2i(1280, 720)
	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("Could not load story scene for visual capture")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame

	var player := scene.get_node("Player") as CharacterBody2D
	var camera := player.get_node("Camera2D") as Camera2D
	root.size = Vector2i(1366, 768)
	await _capture_at(player, camera, Vector2(460.0, 540.0), "00-camera-1366x768.png")
	root.size = Vector2i(1280, 720)
	await _capture_at(player, camera, Vector2(460.0, 540.0), "00-manor-stairs.png")
	await _capture_at(player, camera, Vector2(1540.0, 540.0), "01-road-arrow.png")

	var tutorial := scene.get_node("GraveEncounters/TutorialZombieGrave")
	tutorial.call("activate")
	await create_timer(2.0).timeout
	await _capture_at(player, camera, Vector2(2670.0, 540.0), "02-zombie-grave.png")

	await _capture_at(player, camera, Vector2(3420.0, 540.0), "03-empty-crypt.png")

	await _capture_at(player, camera, Vector2(4608.0, 520.0), "04-bridge-waterfall.png")
	await _capture_at(player, camera, Vector2(5650.0, 540.0), "05-final-burial-row.png")

	root.size = Vector2i(1920, 1080)
	await _capture_at(player, camera, Vector2(5650.0, 540.0), "06-ground-1920x1080.png")
	root.size = Vector2i(2560, 1440)
	await _capture_at(player, camera, Vector2(4608.0, 520.0), "07-ground-2560x1440.png")

	scene.queue_free()
	await process_frame
	print("Second prompt visual captures saved to ", OUTPUT_ROOT)
	quit()


func _capture_at(
	player: CharacterBody2D,
	camera: Camera2D,
	world_position: Vector2,
	file_name: String
) -> void:
	player.global_position = world_position
	player.velocity = Vector2.ZERO
	var smoothing_was_enabled := camera.position_smoothing_enabled
	camera.position_smoothing_enabled = false
	camera.reset_smoothing()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := OUTPUT_ROOT.path_join(file_name)
	var error := image.save_png(ProjectSettings.globalize_path(path))
	camera.position_smoothing_enabled = smoothing_was_enabled
	if error != OK:
		push_error("Failed saving visual capture %s: %s" % [path, error])
