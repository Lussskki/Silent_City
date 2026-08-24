extends Node

const GRAPHICS_CONFIG_PATH := "user://graphics_settings.cfg"

const MAIN_MENU_BUTTON_SIZE := Vector2(320.0, 46.0)
const GRAPHICS_OPTION_BUTTON_SIZE := Vector2(320.0, 46.0)
const GRAPHICS_HEADER_FONT_SIZE := 30
const GRAPHICS_INFO_FONT_SIZE := 18
const GRAPHICS_PAGE_Y_OFFSET := -10.0
const NATIVE_WINDOWED_FIT_SCALE := 0.90

const BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const BACK_PNG := "res://Resources/Buttons/menu_button_exit.png"

const GRAPHICS_RESOLUTION_CANDIDATES := [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

const GRAPHICS_FPS_LIMITS := [30, 60, 120, 0]

var graphics_resolutions: Array[Vector2i] = []

var show_page_callback
var translate_callback
var apply_button_sprite_callback

var graphics_page: VBoxContainer = null
var settings_page: VBoxContainer = null
var graphics_header: Label = null
var fullscreen_button: Button = null
var vsync_button: Button = null
var resolution_button: Button = null
var fps_button: Button = null
var renderer_label: Label = null
var back_button: Button = null

var graphics_resolution_index := 0
var graphics_fps_index := 0
var graphics_fullscreen_transitioning := false
var graphics_borderless_fullscreen := false

var runtime_ready := false
var page_ready := false


func setup_runtime(services: Dictionary) -> void:
	if runtime_ready:
		return

	show_page_callback = services.get("show_page")
	translate_callback = services.get("translate")
	apply_button_sprite_callback = services.get("apply_button_sprite")

	# Apply saved VSync/FPS/fullscreen without building Graphics UI.
	_rebuild_supported_graphics_resolutions()
	_load_graphics_settings()

	runtime_ready = true


func open(
	pages: Control,
	settings_page_node: VBoxContainer
) -> void:
	if not runtime_ready or not pages:
		return

	settings_page = settings_page_node
	_ensure_page(pages)
	refresh_language()
	_show_page(graphics_page)


func refresh_language() -> void:
	if not page_ready:
		return

	if graphics_header:
		graphics_header.text = _t("graphics")

	if fullscreen_button:
		fullscreen_button.text = "%s: %s" % [
			_t("fullscreen"),
			_t("on") if _is_graphics_fullscreen() else _t("off")
		]

	if vsync_button:
		var vsync_on := (
			DisplayServer.window_get_vsync_mode()
			!= DisplayServer.VSYNC_DISABLED
		)

		vsync_button.text = "%s: %s" % [
			_t("vsync"),
			_t("on") if vsync_on else _t("off")
		]

	if resolution_button and not graphics_resolutions.is_empty():
		graphics_resolution_index = clampi(
			graphics_resolution_index,
			0,
			graphics_resolutions.size() - 1
		)

		var resolution: Vector2i = graphics_resolutions[
			graphics_resolution_index
		]

		var native_suffix := ""
		if resolution == _current_screen_size():
			native_suffix = " (Native)"

		resolution_button.text = "%s: %d x %d%s" % [
			_t("resolution"),
			resolution.x,
			resolution.y,
			native_suffix
		]

	if fps_button:
		var fps := int(
			GRAPHICS_FPS_LIMITS[graphics_fps_index]
		)
		var fps_text := (
			_t("unlimited")
			if fps == 0
			else str(fps)
		)

		fps_button.text = "%s: %s" % [
			_t("fps_limit"),
			fps_text
		]

	if renderer_label:
		renderer_label.text = "%s: %s" % [
			_t("renderer"),
			_current_renderer_text()
		]

	if back_button:
		back_button.text = _t("back")


func _ensure_page(pages: Control) -> void:
	if page_ready:
		return

	graphics_page = pages.get_node_or_null("Graphics") as VBoxContainer

	if not graphics_page:
		graphics_page = VBoxContainer.new()
		graphics_page.name = "Graphics"
		graphics_page.alignment = BoxContainer.ALIGNMENT_CENTER
		graphics_page.add_theme_constant_override("separation", 9)
		graphics_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		graphics_page.offset_top += GRAPHICS_PAGE_Y_OFFSET
		graphics_page.offset_bottom += GRAPHICS_PAGE_Y_OFFSET

		graphics_page.visible = false
		pages.add_child(graphics_page)

	graphics_header = graphics_page.get_node_or_null("Header") as Label

	if not graphics_header:
		graphics_header = Label.new()
		graphics_header.name = "Header"
		graphics_header.custom_minimum_size = Vector2(420.0, 52.0)
		graphics_header.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		graphics_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		graphics_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		graphics_header.add_theme_font_size_override(
			"font_size",
			GRAPHICS_HEADER_FONT_SIZE
		)
		graphics_header.add_theme_color_override(
			"font_color",
			Color(0.94, 0.98, 1.0, 1.0)
		)
		graphics_header.add_theme_color_override(
			"font_shadow_color",
			Color(0.0, 0.0, 0.0, 0.9)
		)
		graphics_header.add_theme_constant_override("shadow_offset_x", 2)
		graphics_header.add_theme_constant_override("shadow_offset_y", 2)
		graphics_page.add_child(graphics_header)

	fullscreen_button = _create_option_button(
		graphics_page,
		"FullscreenButton"
	)
	vsync_button = _create_option_button(
		graphics_page,
		"VSyncButton"
	)
	resolution_button = _create_option_button(
		graphics_page,
		"ResolutionButton"
	)
	fps_button = _create_option_button(
		graphics_page,
		"FPSButton"
	)

	renderer_label = graphics_page.get_node_or_null(
		"RendererLabel"
	) as Label

	if not renderer_label:
		renderer_label = Label.new()
		renderer_label.name = "RendererLabel"
		renderer_label.custom_minimum_size = Vector2(500.0, 42.0)
		renderer_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		renderer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		renderer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		renderer_label.add_theme_font_size_override(
			"font_size",
			GRAPHICS_INFO_FONT_SIZE
		)
		renderer_label.add_theme_color_override(
			"font_color",
			Color(0.78, 0.9, 0.95, 1.0)
		)
		renderer_label.add_theme_color_override(
			"font_shadow_color",
			Color(0.0, 0.0, 0.0, 0.85)
		)
		renderer_label.add_theme_constant_override("shadow_offset_x", 1)
		renderer_label.add_theme_constant_override("shadow_offset_y", 2)
		graphics_page.add_child(renderer_label)

	back_button = graphics_page.get_node_or_null("BackButton") as Button

	if not back_button:
		back_button = Button.new()
		back_button.name = "BackButton"
		back_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
		back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		graphics_page.add_child(back_button)

	for button in [
		fullscreen_button,
		vsync_button,
		resolution_button,
		fps_button
	]:
		_apply_button_sprite(
			button,
			BUTTON_PNG,
			GRAPHICS_OPTION_BUTTON_SIZE
		)

	_apply_button_sprite(
		back_button,
		BACK_PNG,
		MAIN_MENU_BUTTON_SIZE
	)

	fullscreen_button.pressed.connect(_toggle_graphics_fullscreen)
	vsync_button.pressed.connect(_toggle_graphics_vsync)
	resolution_button.pressed.connect(_cycle_graphics_resolution)
	fps_button.pressed.connect(_cycle_graphics_fps)
	back_button.pressed.connect(_back_to_settings)

	page_ready = true


func _create_option_button(
	parent: VBoxContainer,
	node_name: String
) -> Button:
	var button := parent.get_node_or_null(node_name) as Button

	if not button:
		button = Button.new()
		button.name = node_name
		button.custom_minimum_size = GRAPHICS_OPTION_BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		parent.add_child(button)

	return button


func _rebuild_supported_graphics_resolutions() -> void:
	graphics_resolutions.clear()

	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)

	for candidate in GRAPHICS_RESOLUTION_CANDIDATES:
		if (
			candidate.x <= screen_size.x
			and candidate.y <= screen_size.y
		):
			graphics_resolutions.append(candidate)

	if graphics_resolutions.is_empty():
		graphics_resolutions.append(
			Vector2i(
				mini(screen_size.x, 1280),
				mini(screen_size.y, 720)
			)
		)

	if not graphics_resolutions.has(screen_size):
		graphics_resolutions.append(screen_size)

	graphics_resolutions.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			return (a.x * a.y) < (b.x * b.y)
	)


func _current_screen_size() -> Vector2i:
	var screen := DisplayServer.window_get_current_screen()
	return DisplayServer.screen_get_size(screen)


func _native_graphics_resolution_index() -> int:
	if graphics_resolutions.is_empty():
		_rebuild_supported_graphics_resolutions()

	var native_size := _current_screen_size()

	for index in range(graphics_resolutions.size()):
		if graphics_resolutions[index] == native_size:
			return index

	return maxi(graphics_resolutions.size() - 1, 0)


func _main_window() -> Window:
	return get_tree().root


func _is_graphics_fullscreen() -> bool:
	var window := _main_window()

	if window == null:
		return false

	return (
		window.mode == Window.MODE_FULLSCREEN
		or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
		or graphics_borderless_fullscreen
	)


func _toggle_graphics_fullscreen() -> void:
	if graphics_fullscreen_transitioning:
		return

	var window := _main_window()

	if window == null:
		return

	if window.is_embedded():
		print(
			"Fullscreen cannot switch while Godot Game Embedding is enabled."
		)
		return

	graphics_fullscreen_transitioning = true

	if _is_graphics_fullscreen():
		await _set_graphics_fullscreen(false)
	else:
		await _set_graphics_fullscreen(true)

	_save_graphics_settings()
	refresh_language()
	graphics_fullscreen_transitioning = false


func _set_graphics_fullscreen(enable: bool) -> void:
	var window := _main_window()

	if window == null:
		return

	if not enable:
		graphics_borderless_fullscreen = false
		window.mode = Window.MODE_WINDOWED
		window.borderless = false

		await get_tree().process_frame
		await get_tree().process_frame

		_apply_selected_windowed_resolution()
		window.borderless = false
		return

	graphics_borderless_fullscreen = false
	window.borderless = false
	window.mode = Window.MODE_FULLSCREEN

	await get_tree().process_frame
	await get_tree().process_frame

	if (
		window.mode == Window.MODE_FULLSCREEN
		or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	):
		return

	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var screen_position := DisplayServer.screen_get_position(screen)

	window.mode = Window.MODE_WINDOWED
	window.borderless = true
	window.position = screen_position
	window.size = screen_size

	graphics_borderless_fullscreen = true

	await get_tree().process_frame

	print(
		"Fullscreen fallback active. Window=",
		window.size,
		" Screen=",
		screen_size
	)


func _restore_saved_fullscreen_state(enable: bool) -> void:
	var window := _main_window()

	if window == null or window.is_embedded():
		return

	await _set_graphics_fullscreen(enable)
	refresh_language()


func _toggle_graphics_vsync() -> void:
	var current := DisplayServer.window_get_vsync_mode()

	if current == DisplayServer.VSYNC_DISABLED:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED
		)
	else:
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_DISABLED
		)

	_save_graphics_settings()
	refresh_language()


func _cycle_graphics_resolution() -> void:
	if graphics_resolutions.is_empty():
		_rebuild_supported_graphics_resolutions()

	graphics_resolution_index += 1

	if graphics_resolution_index >= graphics_resolutions.size():
		graphics_resolution_index = 0

	if not _is_graphics_fullscreen():
		_apply_selected_windowed_resolution()

	_save_graphics_settings()
	refresh_language()


func _apply_selected_windowed_resolution() -> void:
	if graphics_resolutions.is_empty():
		_rebuild_supported_graphics_resolutions()

	graphics_resolution_index = clampi(
		graphics_resolution_index,
		0,
		graphics_resolutions.size() - 1
	)

	var window := _main_window()

	if window == null:
		return

	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)

	var selected_resolution: Vector2i = graphics_resolutions[
		graphics_resolution_index
	]

	selected_resolution.x = mini(
		selected_resolution.x,
		screen_size.x
	)
	selected_resolution.y = mini(
		selected_resolution.y,
		screen_size.y
	)

	var window_size := selected_resolution

	if (
		selected_resolution.x >= usable_rect.size.x
		or selected_resolution.y >= usable_rect.size.y
	):
		var max_window := Vector2i(
			maxi(
				int(
					float(usable_rect.size.x)
					* NATIVE_WINDOWED_FIT_SCALE
				),
				1
			),
			maxi(
				int(
					float(usable_rect.size.y)
					* NATIVE_WINDOWED_FIT_SCALE
				),
				1
			)
		)

		var aspect := (
			float(selected_resolution.x)
			/ float(maxi(selected_resolution.y, 1))
		)

		window_size.x = max_window.x
		window_size.y = int(
			round(float(window_size.x) / aspect)
		)

		if window_size.y > max_window.y:
			window_size.y = max_window.y
			window_size.x = int(
				round(float(window_size.y) * aspect)
			)

	window.mode = Window.MODE_WINDOWED
	window.borderless = false
	window.size = window_size
	window.move_to_center()

	print(
		"Windowed: selected resolution=",
		selected_resolution,
		" physical window=",
		window_size
	)


func _cycle_graphics_fps() -> void:
	graphics_fps_index += 1

	if graphics_fps_index >= GRAPHICS_FPS_LIMITS.size():
		graphics_fps_index = 0

	Engine.max_fps = int(
		GRAPHICS_FPS_LIMITS[graphics_fps_index]
	)

	_save_graphics_settings()
	refresh_language()


func _find_graphics_resolution_index(
	size: Vector2i
) -> int:
	for index in range(graphics_resolutions.size()):
		if graphics_resolutions[index] == size:
			return index

	return _native_graphics_resolution_index()


func _find_graphics_fps_index(fps: int) -> int:
	for index in range(GRAPHICS_FPS_LIMITS.size()):
		if int(GRAPHICS_FPS_LIMITS[index]) == fps:
			return index

	return 0


func _load_graphics_settings() -> void:
	if graphics_resolutions.is_empty():
		_rebuild_supported_graphics_resolutions()

	var config := ConfigFile.new()
	var load_result := config.load(GRAPHICS_CONFIG_PATH)

	if load_result != OK:
		graphics_resolution_index = (
			_native_graphics_resolution_index()
		)

		var current_fps := Engine.max_fps

		if (
			current_fps != 30
			and current_fps != 60
			and current_fps != 120
			and current_fps != 0
		):
			current_fps = 60

		graphics_fps_index = _find_graphics_fps_index(
			current_fps
		)

		_save_graphics_settings()
		return

	var fullscreen := bool(
		config.get_value(
			"graphics",
			"fullscreen",
			_is_graphics_fullscreen()
		)
	)

	var vsync := bool(
		config.get_value(
			"graphics",
			"vsync",
			DisplayServer.window_get_vsync_mode()
				!= DisplayServer.VSYNC_DISABLED
		)
	)

	var native_size := _current_screen_size()

	var saved_width := int(
		config.get_value(
			"graphics",
			"resolution_width",
			native_size.x
		)
	)
	var saved_height := int(
		config.get_value(
			"graphics",
			"resolution_height",
			native_size.y
		)
	)

	var saved_resolution := Vector2i(
		saved_width,
		saved_height
	)

	graphics_resolution_index = (
		_find_graphics_resolution_index(saved_resolution)
	)

	graphics_fps_index = clampi(
		int(
			config.get_value(
				"graphics",
				"fps_index",
				0
			)
		),
		0,
		GRAPHICS_FPS_LIMITS.size() - 1
	)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED
		if vsync
		else DisplayServer.VSYNC_DISABLED
	)

	Engine.max_fps = int(
		GRAPHICS_FPS_LIMITS[graphics_fps_index]
	)

	var window := _main_window()

	if window and not window.is_embedded():
		call_deferred(
			"_restore_saved_fullscreen_state",
			fullscreen
		)


func _save_graphics_settings() -> void:
	var config := ConfigFile.new()
	config.load(GRAPHICS_CONFIG_PATH)

	config.set_value(
		"graphics",
		"fullscreen",
		_is_graphics_fullscreen()
	)

	config.set_value(
		"graphics",
		"vsync",
		DisplayServer.window_get_vsync_mode()
			!= DisplayServer.VSYNC_DISABLED
	)

	var selected_resolution := _current_screen_size()

	if not graphics_resolutions.is_empty():
		graphics_resolution_index = clampi(
			graphics_resolution_index,
			0,
			graphics_resolutions.size() - 1
		)
		selected_resolution = graphics_resolutions[
			graphics_resolution_index
		]

	config.set_value(
		"graphics",
		"resolution_width",
		selected_resolution.x
	)
	config.set_value(
		"graphics",
		"resolution_height",
		selected_resolution.y
	)
	config.set_value(
		"graphics",
		"fps_index",
		graphics_fps_index
	)

	config.save(GRAPHICS_CONFIG_PATH)


func _current_renderer_text() -> String:
	var method := RenderingServer.get_current_rendering_method()
	var driver := RenderingServer.get_current_rendering_driver_name()

	var pretty_method := method

	match method:
		"forward_plus":
			pretty_method = "Forward+"
		"mobile":
			pretty_method = "Mobile"
		"gl_compatibility":
			pretty_method = "Compatibility"

	var pretty_driver := driver

	match driver.to_lower():
		"vulkan":
			pretty_driver = "Vulkan"
		"opengl3":
			pretty_driver = "OpenGL 3"
		"d3d12":
			pretty_driver = "Direct3D 12"
		"metal":
			pretty_driver = "Metal"

	return "%s / %s" % [
		pretty_method,
		pretty_driver
	]


func _back_to_settings() -> void:
	_show_page(settings_page)


func _apply_button_sprite(
	button: Button,
	texture_path: String,
	size: Vector2
) -> void:
	if (
		apply_button_sprite_callback is Callable
		and apply_button_sprite_callback.is_valid()
	):
		apply_button_sprite_callback.call(button, texture_path, size)


func _show_page(page: Control) -> void:
	if (
		show_page_callback is Callable
		and show_page_callback.is_valid()
	):
		show_page_callback.call(page)


func _t(key: String) -> String:
	if (
		translate_callback is Callable
		and translate_callback.is_valid()
	):
		return String(translate_callback.call(key))

	return key
