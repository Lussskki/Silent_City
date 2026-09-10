extends Node

const MAIN_MENU_BUTTON_SIZE := Vector2(320.0, 46.0)
const HEADER_FONT_SIZE := 30
const BRIGHTNESS_STEPS := [25, 50, 75, 100]
const BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const BACK_PNG := "res://Resources/Buttons/menu_button_exit.png"

var show_page_callback
var translate_callback
var apply_button_sprite_callback

var brightness_page: VBoxContainer
var settings_page: VBoxContainer
var header: Label
var brightness_button: Button
var back_button: Button
var brightness_index := 3
var page_ready := false


func setup_runtime(services: Dictionary) -> void:
	show_page_callback = services.get("show_page")
	translate_callback = services.get("translate")
	apply_button_sprite_callback = services.get("apply_button_sprite")
	var manager := _brightness_manager()
	if manager:
		brightness_index = _find_step(int(manager.get_brightness()))


func open(pages: Control, settings_page_node: VBoxContainer) -> void:
	if not pages:
		return

	settings_page = settings_page_node
	_ensure_page(pages)
	refresh_language()
	_show_page(brightness_page)


func refresh_language() -> void:
	if not page_ready:
		return

	header.text = _t("brightness")
	var percent := 100
	var manager := _brightness_manager()
	if manager:
		percent = int(manager.get_brightness())

	brightness_button.text = "%s: %d%%" % [
		_t("brightness"),
		percent
	]
	back_button.text = _t("back")


func _ensure_page(pages: Control) -> void:
	if page_ready:
		return

	brightness_page = pages.get_node_or_null("Brightness") as VBoxContainer
	if not brightness_page:
		brightness_page = VBoxContainer.new()
		brightness_page.name = "Brightness"
		brightness_page.alignment = BoxContainer.ALIGNMENT_CENTER
		brightness_page.add_theme_constant_override("separation", 12)
		brightness_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		brightness_page.visible = false
		pages.add_child(brightness_page)

	header = Label.new()
	header.name = "Header"
	header.custom_minimum_size = Vector2(420.0, 54.0)
	header.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	header.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	header.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	header.add_theme_constant_override("shadow_offset_x", 2)
	header.add_theme_constant_override("shadow_offset_y", 2)
	brightness_page.add_child(header)

	brightness_button = Button.new()
	brightness_button.name = "BrightnessValueButton"
	brightness_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
	brightness_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	brightness_page.add_child(brightness_button)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	brightness_page.add_child(back_button)

	_apply_button_sprite(brightness_button, BUTTON_PNG, MAIN_MENU_BUTTON_SIZE)
	_apply_button_sprite(back_button, BACK_PNG, MAIN_MENU_BUTTON_SIZE)
	brightness_button.pressed.connect(_cycle_brightness)
	back_button.pressed.connect(_back_to_settings)
	page_ready = true


func _cycle_brightness() -> void:
	brightness_index = (brightness_index + 1) % BRIGHTNESS_STEPS.size()
	var manager := _brightness_manager()
	if manager:
		manager.set_brightness(int(BRIGHTNESS_STEPS[brightness_index]))
	refresh_language()


func _brightness_manager() -> Node:
	return get_node_or_null("/root/BrightnessManager")


func _find_step(percent: int) -> int:
	var closest_index := 0
	var closest_distance: int = absi(percent - int(BRIGHTNESS_STEPS[0]))
	for index in range(1, BRIGHTNESS_STEPS.size()):
		var distance: int = absi(percent - int(BRIGHTNESS_STEPS[index]))
		if distance < closest_distance:
			closest_index = index
			closest_distance = distance
	return closest_index


func _back_to_settings() -> void:
	_show_page(settings_page)


func _apply_button_sprite(button: Button, texture_path: String, size: Vector2) -> void:
	if apply_button_sprite_callback is Callable and apply_button_sprite_callback.is_valid():
		apply_button_sprite_callback.call(button, texture_path, size)


func _show_page(page: Control) -> void:
	if show_page_callback is Callable and show_page_callback.is_valid():
		show_page_callback.call(page)


func _t(key: String) -> String:
	if translate_callback is Callable and translate_callback.is_valid():
		return String(translate_callback.call(key))
	return key
