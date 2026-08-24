extends Node

const AUDIO_CONFIG_PATH := "user://audio_settings.cfg"
const MAIN_MENU_BUTTON_SIZE := Vector2(320.0, 46.0)
const AUDIO_OPTION_BUTTON_SIZE := Vector2(320.0, 46.0)
const AUDIO_HEADER_FONT_SIZE := 30
const AUDIO_VOLUME_STEPS := [100, 75, 50, 25, 0]

const BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const BACK_PNG := "res://Resources/Buttons/menu_button_exit.png"

var show_page_callback
var translate_callback
var apply_button_sprite_callback

var audio_page: VBoxContainer = null
var audio_header: Label = null
var master_volume_button: Button = null
var back_button: Button = null
var settings_page: VBoxContainer = null

var audio_volume_index := 0
var runtime_ready := false
var page_ready := false


func setup_runtime(services: Dictionary) -> void:
	if runtime_ready:
		return

	show_page_callback = services.get("show_page")
	translate_callback = services.get("translate")
	apply_button_sprite_callback = services.get("apply_button_sprite")

	# Apply saved volume without creating Audio UI.
	_load_audio_settings()
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
	_show_page(audio_page)


func refresh_language() -> void:
	if not page_ready:
		return

	if audio_header:
		audio_header.text = _t("audio")

	if master_volume_button:
		var percent := int(AUDIO_VOLUME_STEPS[audio_volume_index])
		master_volume_button.text = "%s: %d%%" % [
			_t("master_volume"),
			percent
		]

	if back_button:
		back_button.text = _t("back")


func _ensure_page(pages: Control) -> void:
	if page_ready:
		return

	audio_page = pages.get_node_or_null("Audio") as VBoxContainer

	if not audio_page:
		audio_page = VBoxContainer.new()
		audio_page.name = "Audio"
		audio_page.alignment = BoxContainer.ALIGNMENT_CENTER
		audio_page.add_theme_constant_override("separation", 12)
		audio_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		audio_page.visible = false
		pages.add_child(audio_page)

	audio_header = audio_page.get_node_or_null("Header") as Label
	if not audio_header:
		audio_header = Label.new()
		audio_header.name = "Header"
		audio_header.custom_minimum_size = Vector2(420.0, 54.0)
		audio_header.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		audio_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		audio_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		audio_header.add_theme_font_size_override(
			"font_size",
			AUDIO_HEADER_FONT_SIZE
		)
		audio_header.add_theme_color_override(
			"font_color",
			Color(0.94, 0.98, 1.0, 1.0)
		)
		audio_header.add_theme_color_override(
			"font_shadow_color",
			Color(0.0, 0.0, 0.0, 0.9)
		)
		audio_header.add_theme_constant_override("shadow_offset_x", 2)
		audio_header.add_theme_constant_override("shadow_offset_y", 2)
		audio_page.add_child(audio_header)

	master_volume_button = audio_page.get_node_or_null(
		"MasterVolumeButton"
	) as Button

	if not master_volume_button:
		master_volume_button = Button.new()
		master_volume_button.name = "MasterVolumeButton"
		master_volume_button.custom_minimum_size = AUDIO_OPTION_BUTTON_SIZE
		master_volume_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		audio_page.add_child(master_volume_button)

	back_button = audio_page.get_node_or_null("BackButton") as Button

	if not back_button:
		back_button = Button.new()
		back_button.name = "BackButton"
		back_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
		back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		audio_page.add_child(back_button)

	_apply_button_sprite(
		master_volume_button,
		BUTTON_PNG,
		AUDIO_OPTION_BUTTON_SIZE
	)
	_apply_button_sprite(
		back_button,
		BACK_PNG,
		MAIN_MENU_BUTTON_SIZE
	)

	master_volume_button.pressed.connect(_cycle_master_volume)
	back_button.pressed.connect(_back_to_settings)

	page_ready = true


func _master_audio_bus_index() -> int:
	var index := AudioServer.get_bus_index("Master")
	if index < 0:
		return 0
	return index


func _cycle_master_volume() -> void:
	audio_volume_index += 1

	if audio_volume_index >= AUDIO_VOLUME_STEPS.size():
		audio_volume_index = 0

	_apply_master_volume()
	_save_audio_settings()
	refresh_language()


func _apply_master_volume() -> void:
	audio_volume_index = clampi(
		audio_volume_index,
		0,
		AUDIO_VOLUME_STEPS.size() - 1
	)

	var percent := int(AUDIO_VOLUME_STEPS[audio_volume_index])
	var bus_index := _master_audio_bus_index()

	if percent <= 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		var linear_volume := float(percent) / 100.0
		AudioServer.set_bus_volume_db(
			bus_index,
			linear_to_db(linear_volume)
		)


func _find_audio_volume_index(percent: int) -> int:
	for index in range(AUDIO_VOLUME_STEPS.size()):
		if int(AUDIO_VOLUME_STEPS[index]) == percent:
			return index

	return 0


func _load_audio_settings() -> void:
	var config := ConfigFile.new()
	var result := config.load(AUDIO_CONFIG_PATH)

	if result != OK:
		audio_volume_index = 0
		_apply_master_volume()
		_save_audio_settings()
		return

	var saved_percent := int(
		config.get_value(
			"audio",
			"master_volume_percent",
			100
		)
	)

	audio_volume_index = _find_audio_volume_index(saved_percent)
	_apply_master_volume()


func _save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.load(AUDIO_CONFIG_PATH)

	var percent := int(AUDIO_VOLUME_STEPS[audio_volume_index])

	config.set_value(
		"audio",
		"master_volume_percent",
		percent
	)
	config.save(AUDIO_CONFIG_PATH)


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
