extends Node

# Settings coordinator.
# Only the visible HOME Settings button is created during Main Menu startup.
# The actual Settings page is created only when the player presses Settings.
# Audio/Graphics runtime preferences are applied without building their UI.

const AUDIO_MENU_PATH := "res://Scripts/Menus/settings/audio_menu.gd"
const GRAPHICS_MENU_PATH := "res://Scripts/Menus/settings/graphics_menu.gd"
const BRIGHTNESS_MENU_PATH := "res://Scripts/Menus/brightness/brightness_menu.gd"
const CREDIT_MENU_PATH := "res://Scripts/Menus/settings/credit_menu.gd"

const MAIN_MENU_BUTTON_SIZE := Vector2(320.0, 46.0)
const CHILD_BACK_BUTTON_SIZE := Vector2(260.0, 40.0)

const SETTINGS_BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const SETTINGS_BACK_PNG := "res://Resources/Buttons/menu_button_exit.png"
const HOW_TO_PLAY_BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const CREDITS_BUTTON_PNG := "res://Resources/Buttons/menu_button_credits.png"
const CHILD_BACK_PNG := "res://Resources/Buttons/menu_button_start.png"
const HOW_TO_PLAY_BORDER_PNG := "res://Resources/Buttons/border.png"
const JUMP_WIND_PNG := "res://Resources/Buttons/wind_clean.png"
const DEFENCE_NOTICE_PNG := "res://Resources/Deffence/defence_is_coming_fixed.png"
const HEALTH_NOTICE_PNG := "res://Resources/Deffence/health_is_coming_clean.png"
const HOW_TO_PLAY_IMAGE_SIZE := Vector2(84.0, 84.0)

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
var brightness_button: Button = null

var how_to_play_button: Button = null
var credits_button: Button = null

var how_to_play_page: VBoxContainer = null
var how_to_play_header: Label = null
var how_to_play_instructions: Label = null
var how_attack_label: Label = null
var how_kick_label: Label = null
var how_jump_label: Label = null
var how_defence_notice_label: Label = null
var how_health_notice_label: Label = null
var how_to_play_back_button: Button = null

var audio_menu = null
var graphics_menu = null
var brightness_menu = null
var credit_menu = null

var show_page_callback
var translate_callback
var apply_button_sprite_callback
var menu_optimizer = null

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
	menu_optimizer = services.get("menu_optimizer")

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
	if brightness_button:
		brightness_button.text = _t("brightness")
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
	if brightness_menu:
		brightness_menu.refresh_language()
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

	brightness_button = settings_page.get_node_or_null("BrightnessButton") as Button
	if not brightness_button:
		brightness_button = Button.new()
		brightness_button.name = "BrightnessButton"
		brightness_button.custom_minimum_size = MAIN_MENU_BUTTON_SIZE
		brightness_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		settings_page.add_child(brightness_button)

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
		brightness_button,
		SETTINGS_BUTTON_PNG,
		MAIN_MENU_BUTTON_SIZE
	)
	brightness_button.add_theme_font_size_override("font_size", GRAPHICS_BUTTON_FONT_SIZE)

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
	brightness_button.pressed.connect(_open_brightness)

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
	how_jump_label = how_to_play_page.get_node_or_null(
		"Cards/JumpCard/Text"
	) as Label
	how_defence_notice_label = how_to_play_page.get_node_or_null(
		"NoticeCards/DefenceNotice/Text"
	) as Label
	how_health_notice_label = how_to_play_page.get_node_or_null(
		"NoticeCards/HealthNotice/Text"
	) as Label
	how_to_play_back_button = how_to_play_page.get_node_or_null(
		"BackButton"
	) as Button
	_setup_how_to_play_frames()
	_clean_how_to_play_notice_edges()

	if how_to_play_back_button:
		_apply_button_sprite(
			how_to_play_back_button,
			CHILD_BACK_PNG,
			CHILD_BACK_BUTTON_SIZE
		)
		how_to_play_back_button.pressed.connect(open)


func _setup_how_to_play_frames() -> void:
	if menu_optimizer == null or not ResourceLoader.exists(HOW_TO_PLAY_BORDER_PNG):
		return

	var border_texture: Texture2D = menu_optimizer.load_menu_texture(
		HOW_TO_PLAY_BORDER_PNG,
		0.68,
		0.20
	)
	if border_texture == null:
		return

	# The source frame is large, so mipmaps keep its thin edges smooth in the
	# compact tutorial cards.
	var border_image := border_texture.get_image()
	if border_image and not border_image.is_empty():
		border_image.generate_mipmaps()
		border_texture = ImageTexture.create_from_image(border_image)

	for card_name in ["AttackCard", "KickCard", "JumpCard"]:
		var image := how_to_play_page.get_node_or_null(
			"Cards/%s/Image" % card_name
		) as TextureRect
		if image == null:
			continue

		image.custom_minimum_size = HOW_TO_PLAY_IMAGE_SIZE
		image.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

		var border := image.get_node_or_null("Border") as TextureRect
		if border == null:
			border = TextureRect.new()
			border.name = "Border"
			image.add_child(border)

		border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		border.texture = border_texture
		border.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		border.stretch_mode = TextureRect.STRETCH_SCALE
		border.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.z_index = 1

	_setup_jump_motion_trail()


func _clean_how_to_play_notice_edges() -> void:
	if menu_optimizer == null:
		return

	for notice_data in [
		{
			"node": "NoticeCards/DefenceNotice/Image",
			"texture": DEFENCE_NOTICE_PNG
		},
		{
			"node": "NoticeCards/HealthNotice/Image",
			"texture": HEALTH_NOTICE_PNG
		}
	]:
		var notice := how_to_play_page.get_node_or_null(
			notice_data["node"]
		) as TextureRect
		if notice == null:
			continue

		var cleaned: Texture2D = menu_optimizer.load_clean_ui_texture(
			notice_data["texture"],
			false,
			8,
			0.55,
			0.12
		)
		if cleaned == null:
			continue

		var cleaned_image := cleaned.get_image()
		if cleaned_image and not cleaned_image.is_empty():
			cleaned_image.generate_mipmaps()
			cleaned = ImageTexture.create_from_image(cleaned_image)

		notice.texture = cleaned
		notice.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func _setup_jump_motion_trail() -> void:
	var jump_image := how_to_play_page.get_node_or_null(
		"Cards/JumpCard/Image"
	) as TextureRect
	if (
		jump_image == null
		or jump_image.has_node("JumpMotionTrail")
		or not ResourceLoader.exists(JUMP_WIND_PNG)
	):
		return

	var trail := Control.new()
	trail.name = "JumpMotionTrail"
	trail.show_behind_parent = true
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jump_image.add_child(trail)
	trail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var wind_texture := load(JUMP_WIND_PNG) as Texture2D
	for wind_data in [
		{"name": "LeftWind", "center_x": -9.0},
		{"name": "RightWind", "center_x": 1.0}
	]:
		var wind := TextureRect.new()
		wind.name = wind_data["name"]
		wind.texture = wind_texture
		wind.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		wind.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wind.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		wind.self_modulate = Color(1.0, 1.0, 1.0, 0.52)
		wind.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wind.anchor_left = 0.5
		wind.anchor_top = 0.5
		wind.anchor_right = 0.5
		wind.anchor_bottom = 0.5
		wind.offset_left = float(wind_data["center_x"]) - 9.0
		wind.offset_top = 15.0
		wind.offset_right = float(wind_data["center_x"]) + 9.0
		wind.offset_bottom = 41.0
		trail.add_child(wind)


func _refresh_how_to_play_language() -> void:
	var georgian_active := _t("language_button") == "ENG"

	if how_to_play_header:
		how_to_play_header.text = _t("how_to_play")
	if how_to_play_instructions:
		how_to_play_instructions.text = _t("how_to_play_text")
		how_to_play_instructions.add_theme_font_size_override(
			"font_size",
			15 if georgian_active else 17
		)
	if how_attack_label:
		how_attack_label.text = _t("how_attack")
	if how_kick_label:
		how_kick_label.text = _t("how_kick")
	if how_jump_label:
		how_jump_label.text = _t("how_jump")
	if how_defence_notice_label:
		how_defence_notice_label.text = _t("how_defence_notice")
		how_defence_notice_label.add_theme_font_size_override(
			"font_size",
			12 if georgian_active else 13
		)
	if how_health_notice_label:
		how_health_notice_label.text = _t("how_health_notice")
		how_health_notice_label.add_theme_font_size_override(
			"font_size",
			12 if georgian_active else 13
		)
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


func _open_brightness() -> void:
	var menu = _ensure_brightness_runtime()
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


func _ensure_brightness_runtime():
	if brightness_menu:
		return brightness_menu

	if not ResourceLoader.exists(BRIGHTNESS_MENU_PATH):
		push_error("Brightness menu file not found: " + BRIGHTNESS_MENU_PATH)
		return null

	var script = load(BRIGHTNESS_MENU_PATH)
	if script == null:
		push_error("Brightness menu could not be loaded: " + BRIGHTNESS_MENU_PATH)
		return null

	brightness_menu = script.new()
	brightness_menu.name = "BrightnessMenuModule"
	add_child(brightness_menu)
	brightness_menu.setup_runtime({
		"show_page": show_page_callback,
		"translate": translate_callback,
		"apply_button_sprite": apply_button_sprite_callback
	})
	return brightness_menu


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
