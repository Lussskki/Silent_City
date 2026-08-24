extends Node

# Settings coordinator.
# Only the visible HOME Settings button is created during Main Menu startup.
# The actual Settings page is created only when the player presses Settings.
# Audio/Graphics runtime preferences are applied without building their UI.

const AUDIO_MENU_PATH := "res://Scripts/Menus/settings/audio_menu.gd"
const GRAPHICS_MENU_PATH := "res://Scripts/Menus/settings/graphics_menu.gd"
const CREDIT_MENU_PATH := "res://Scripts/Menus/settings/credit_menu.gd"

const MAIN_MENU_BUTTON_SIZE := Vector2(320.0, 46.0)
const CHILD_BACK_BUTTON_SIZE := Vector2(260.0, 40.0)

const SETTINGS_BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const SETTINGS_BACK_PNG := "res://Resources/Buttons/menu_button_exit.png"
const HOW_TO_PLAY_BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const CREDITS_BUTTON_PNG := "res://Resources/Buttons/menu_button_credits.png"
const CHILD_BACK_PNG := "res://Resources/Buttons/menu_button_start.png"

const SETTINGS_HEADER_FONT_SIZE := 30
const SETTINGS_BUTTON_FONT_SIZE := 22
const AUDIO_BUTTON_FONT_SIZE := 24
const GRAPHICS_BUTTON_FONT_SIZE := 24

var pages: Control = null
var home_page: VBoxContainer = null

var settings_button: Button = null
var settings_page: VBoxContainer = null
var settings_header: Label = null
var settings_back_button: Button = null
var audio_button: Button = null
var graphics_button: Button = null

var how_to_play_button: Button = null
var credits_button: Button = null

var how_to_play_page: VBoxContainer = null
var how_to_play_header: Label = null
var how_to_play_instructions: Label = null
var how_attack_label: Label = null
var how_kick_label: Label = null
var how_heart_label: Label = null
var how_jump_label: Label = null
var how_to_play_back_button: Button = null

var audio_menu = null
var graphics_menu = null
var credit_menu = null

var show_page_callback
var translate_callback
var apply_button_sprite_callback

var runtime_ready := false
var page_ready := false


func setup_runtime(
	pages_node: Control,
	home_page_node: VBoxContainer,
	services: Dictionary
) -> void:
	if runtime_ready:
		return

	pages = pages_node
	home_page = home_page_node
	show_page_callback = services.get("show_page")
	translate_callback = services.get("translate")
	apply_button_sprite_callback = services.get("apply_button_sprite")

	if not pages or not home_page:
		return

	# HOME needs only one Settings button at startup.
	settings_button = home_page.get_node_or_null("SettingsButton") as Button

	if not settings_button:
		settings_button = Button.new()
		settings_button.name = "SettingsButton"
		settings_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
		settings_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		home_page.add_child(settings_button)

	var exit_button := home_page.get_node_or_null("ExitButton") as Button
	if exit_button:
		home_page.move_child(settings_button, exit_button.get_index())

	# These existing scene buttons belong inside Settings, but we do not create
	# the Settings page yet. Hide them until Settings is opened.
	how_to_play_button = home_page.get_node_or_null("HowToPlayButton") as Button
	credits_button = home_page.get_node_or_null("CreditsButton") as Button

	if how_to_play_button:
		how_to_play_button.visible = false
	if credits_button:
		credits_button.visible = false

	_apply_button_sprite(
		settings_button,
		SETTINGS_BUTTON_PNG,
		MAIN_MENU_BUTTON_SIZE
	)
	settings_button.add_theme_font_size_override(
		"font_size",
		SETTINGS_BUTTON_FONT_SIZE
	)

	# Saved Audio and Graphics preferences still need to apply at game startup.
	# Their PAGE/UI is not built here.
	_ensure_audio_runtime()
	_ensure_graphics_runtime()

	refresh_language()
	runtime_ready = true


func get_settings_button() -> Button:
	return settings_button


func open() -> void:
	if not runtime_ready:
		return

	_ensure_settings_page()
	refresh_language()
	_show_page(settings_page)


func refresh_language() -> void:
	if settings_button:
		settings_button.text = _t("settings")

	if not page_ready:
		if audio_menu:
			audio_menu.refresh_language()
		if graphics_menu:
			graphics_menu.refresh_language()
		return

	if settings_header:
		settings_header.text = _t("settings")
	if audio_button:
		audio_button.text = _t("audio")
	if graphics_button:
		graphics_button.text = _t("graphics")
	if how_to_play_button:
		how_to_play_button.text = _t("how_to_play")
	if credits_button:
		credits_button.text = _t("credits")
	if settings_back_button:
		settings_back_button.text = _t("back")

	_refresh_how_to_play_language()

	if audio_menu:
		audio_menu.refresh_language()
	if graphics_menu:
		graphics_menu.refresh_language()
	if credit_menu:
		credit_menu.refresh_language()


func _ensure_settings_page() -> void:
	if page_ready:
		return

	settings_page = pages.get_node_or_null("Settings") as VBoxContainer

	if not settings_page:
		settings_page = VBoxContainer.new()
		settings_page.name = "Settings"
		settings_page.alignment = BoxContainer.ALIGNMENT_CENTER
		settings_page.add_theme_constant_override("separation", 12)
		settings_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		settings_page.visible = false
		pages.add_child(settings_page)

	settings_header = settings_page.get_node_or_null("Header") as Label

	if not settings_header:
		settings_header = Label.new()
		settings_header.name = "Header"
		settings_header.custom_minimum_size = Vector2(420.0, 54.0)
		settings_header.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		settings_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		settings_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		settings_header.add_theme_font_size_override(
			"font_size",
			SETTINGS_HEADER_FONT_SIZE
		)
		settings_header.add_theme_color_override(
			"font_color",
			Color(0.94, 0.98, 1.0, 1.0)
		)
		settings_header.add_theme_color_override(
			"font_shadow_color",
			Color(0.0, 0.0, 0.0, 0.9)
		)
		settings_header.add_theme_constant_override("shadow_offset_x", 2)
		settings_header.add_theme_constant_override("shadow_offset_y", 2)
		settings_page.add_child(settings_header)

	audio_button = settings_page.get_node_or_null("AudioButton") as Button
	if not audio_button:
		audio_button = Button.new()
		audio_button.name = "AudioButton"
		audio_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
		audio_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		settings_page.add_child(audio_button)

	graphics_button = settings_page.get_node_or_null("GraphicsButton") as Button
	if not graphics_button:
		graphics_button = Button.new()
		graphics_button.name = "GraphicsButton"
		graphics_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
		graphics_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		settings_page.add_child(graphics_button)

	# Move existing scene buttons into Settings only NOW.
	if how_to_play_button:
		if how_to_play_button.get_parent() != settings_page:
			how_to_play_button.reparent(settings_page)
		how_to_play_button.visible = true
		how_to_play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	if credits_button:
		if credits_button.get_parent() != settings_page:
			credits_button.reparent(settings_page)
		credits_button.visible = true
		credits_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	settings_back_button = settings_page.get_node_or_null("BackButton") as Button
	if not settings_back_button:
		settings_back_button = Button.new()
		settings_back_button.name = "BackButton"
		settings_back_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
		settings_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		settings_page.add_child(settings_back_button)

	_apply_button_sprite(
		audio_button,
		SETTINGS_BUTTON_PNG,
		MAIN_MENU_BUTTON_SIZE
	)
	audio_button.add_theme_font_size_override(
		"font_size",
		AUDIO_BUTTON_FONT_SIZE
	)

	_apply_button_sprite(
		graphics_button,
		SETTINGS_BUTTON_PNG,
		MAIN_MENU_BUTTON_SIZE
	)
	graphics_button.add_theme_font_size_override(
		"font_size",
		GRAPHICS_BUTTON_FONT_SIZE
	)

	_apply_button_sprite(
		how_to_play_button,
		HOW_TO_PLAY_BUTTON_PNG,
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		credits_button,
		CREDITS_BUTTON_PNG,
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		settings_back_button,
		SETTINGS_BACK_PNG,
		MAIN_MENU_BUTTON_SIZE
	)

	audio_button.pressed.connect(_open_audio)
	graphics_button.pressed.connect(_open_graphics)

	if how_to_play_button:
		how_to_play_button.pressed.connect(_open_how_to_play)

	if credits_button:
		credits_button.pressed.connect(_open_credits)

	settings_back_button.pressed.connect(_back_home)

	_setup_how_to_play_page()

	page_ready = true


func _setup_how_to_play_page() -> void:
	how_to_play_page = pages.get_node_or_null("HowToPlay") as VBoxContainer
	if not how_to_play_page:
		return

	how_to_play_header = how_to_play_page.get_node_or_null("Header") as Label
	how_to_play_instructions = how_to_play_page.get_node_or_null(
		"Instructions"
	) as Label
	how_attack_label = how_to_play_page.get_node_or_null(
		"Cards/AttackCard/Text"
	) as Label
	how_kick_label = how_to_play_page.get_node_or_null(
		"Cards/KickCard/Text"
	) as Label
	how_heart_label = how_to_play_page.get_node_or_null(
		"Cards/HeartCard/Text"
	) as Label
	how_jump_label = how_to_play_page.get_node_or_null(
		"Cards/JumpCard/Text"
	) as Label
	how_to_play_back_button = how_to_play_page.get_node_or_null(
		"BackButton"
	) as Button

	if how_to_play_back_button:
		_apply_button_sprite(
			how_to_play_back_button,
			CHILD_BACK_PNG,
			CHILD_BACK_BUTTON_SIZE
		)
		how_to_play_back_button.pressed.connect(open)


func _refresh_how_to_play_language() -> void:
	if how_to_play_header:
		how_to_play_header.text = _t("how_to_play")
	if how_to_play_instructions:
		how_to_play_instructions.text = _t("how_to_play_text")
	if how_attack_label:
		how_attack_label.text = _t("how_attack")
	if how_kick_label:
		how_kick_label.text = _t("how_kick")
	if how_heart_label:
		how_heart_label.text = _t("how_heart")
	if how_jump_label:
		how_jump_label.text = _t("how_jump")
	if how_to_play_back_button:
		how_to_play_back_button.text = _t("back")


func _open_how_to_play() -> void:
	if how_to_play_page:
		_refresh_how_to_play_language()
		_show_page(how_to_play_page)


func _open_audio() -> void:
	var menu = _ensure_audio_runtime()
	if menu:
		menu.open(pages, settings_page)


func _open_graphics() -> void:
	var menu = _ensure_graphics_runtime()
	if menu:
		menu.open(pages, settings_page)


func _open_credits() -> void:
	var menu = _ensure_credit_menu()
	if menu:
		menu.open()


func _ensure_audio_runtime():
	if audio_menu:
		return audio_menu

	if not ResourceLoader.exists(AUDIO_MENU_PATH):
		push_error("Audio menu file not found: " + AUDIO_MENU_PATH)
		return null

	var script = load(AUDIO_MENU_PATH)
	if script == null:
		push_error("Audio menu could not be loaded: " + AUDIO_MENU_PATH)
		return null

	audio_menu = script.new()
	audio_menu.name = "AudioMenuModule"
	add_child(audio_menu)

	audio_menu.setup_runtime({
		"show_page": show_page_callback,
		"translate": translate_callback,
		"apply_button_sprite": apply_button_sprite_callback
	})

	return audio_menu


func _ensure_graphics_runtime():
	if graphics_menu:
		return graphics_menu

	if not ResourceLoader.exists(GRAPHICS_MENU_PATH):
		push_error("Graphics menu file not found: " + GRAPHICS_MENU_PATH)
		return null

	var script = load(GRAPHICS_MENU_PATH)
	if script == null:
		push_error("Graphics menu could not be loaded: " + GRAPHICS_MENU_PATH)
		return null

	graphics_menu = script.new()
	graphics_menu.name = "GraphicsMenuModule"
	add_child(graphics_menu)

	graphics_menu.setup_runtime({
		"show_page": show_page_callback,
		"translate": translate_callback,
		"apply_button_sprite": apply_button_sprite_callback
	})

	return graphics_menu


func _ensure_credit_menu():
	if credit_menu:
		return credit_menu

	if not ResourceLoader.exists(CREDIT_MENU_PATH):
		push_error("Credit menu file not found: " + CREDIT_MENU_PATH)
		return null

	var script = load(CREDIT_MENU_PATH)
	if script == null:
		push_error("Credit menu could not be loaded: " + CREDIT_MENU_PATH)
		return null

	credit_menu = script.new()
	credit_menu.name = "CreditMenuModule"
	add_child(credit_menu)

	credit_menu.setup(
		pages,
		settings_page,
		{
			"show_page": show_page_callback,
			"translate": translate_callback,
			"apply_button_sprite": apply_button_sprite_callback
		}
	)

	return credit_menu


func _back_home() -> void:
	_show_page(home_page)


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
