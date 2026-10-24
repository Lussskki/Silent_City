extends SceneTree

const LEVEL_PATH := "res://Scenes/OuterGraveyardMoonlit.tscn"
const TIMEOUT_MSEC := 30000
const MENU_TEXTURE_CACHE_META := "_silent_city_menu_texture_cache_v1"
const PAUSE_TEXTURES := [
	"res://Resources/Buttons/Paused.png",
	"res://Resources/Buttons/Audio.png",
	"res://Resources/Buttons/return_to_game.png",
	"res://Resources/Buttons/main_menu.png",
	"res://Resources/Buttons/100.png",
	"res://Resources/Buttons/75.png",
	"res://Resources/Buttons/50.png",
	"res://Resources/Buttons/25.png",
	"res://Resources/Buttons/0.png",
	"res://Resources/Buttons/in_game_back.png"
]


func _init() -> void:
	call_deferred(&"_run_validation")


func _run_validation() -> void:
	if not ClassDB.class_exists("MenuOptimizer"):
		_fail("MenuOptimizer C++ class is unavailable")
		return

	var optimizer = MenuOptimizer.new()
	var shared_texture_cache: Dictionary = {}
	var settings := root.get_node_or_null("GameSettings")
	if settings:
		settings.set_meta(MENU_TEXTURE_CACHE_META, shared_texture_cache)
	optimizer.set_texture_cache(shared_texture_cache)
	for method_name in [
		"request_level_preload",
		"get_level_preload_status",
		"get_level_preload_progress",
		"get_preloaded_level"
	]:
		if not optimizer.has_method(method_name):
			_fail("native method is missing: %s" % method_name)
			return

	var started_at := Time.get_ticks_msec()
	var request_error: int = optimizer.request_level_preload(LEVEL_PATH)
	if request_error != OK:
		_fail("native preload request failed with error %d" % request_error)
		return

	while optimizer.get_level_preload_status(LEVEL_PATH) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if Time.get_ticks_msec() - started_at > TIMEOUT_MSEC:
			_fail("native preload timed out")
			return
		await process_frame

	if optimizer.get_level_preload_status(LEVEL_PATH) != ResourceLoader.THREAD_LOAD_LOADED:
		_fail("native preload did not reach the loaded state")
		return

	var packed := optimizer.get_preloaded_level(LEVEL_PATH) as PackedScene
	if packed == null:
		_fail("native cache did not return a PackedScene")
		return
	if not optimizer.has_preloaded_level(LEVEL_PATH):
		_fail("native cache did not retain the loaded scene")
		return
	if optimizer.get_preloaded_level_count() != 1:
		_fail("native cache contains an unexpected scene count")
		return

	var preload_msec := Time.get_ticks_msec() - started_at
	var ui_warm_started := Time.get_ticks_msec()
	for texture_path: String in PAUSE_TEXTURES:
		optimizer.load_clean_ui_texture(texture_path, true, 5, 0.40, 0.16)
	var ui_warm_msec := Time.get_ticks_msec() - ui_warm_started
	var instantiate_started := Time.get_ticks_msec()
	var scene := packed.instantiate()
	var instantiate_msec := Time.get_ticks_msec() - instantiate_started
	if scene.name != "OuterGraveyardMoonlit":
		_fail("cached scene instantiated with the wrong root")
		return
	var ready_started := Time.get_ticks_msec()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var ready_msec := Time.get_ticks_msec() - ready_started

	print(
		"Native level preload passed: load=%d ms ui_warm=%d ms instantiate=%d ms ready=%d ms"
		% [preload_msec, ui_warm_msec, instantiate_msec, ready_msec]
	)
	scene.queue_free()
	await process_frame
	quit()


func _fail(message: String) -> void:
	push_error("Native level preload validation failed: %s" % message)
	quit(1)
