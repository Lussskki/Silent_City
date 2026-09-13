extends Node

# Difficulty page is now isolated from main_menu.gd.
# It is created only when Difficulty is actually opened, so Easy/Medium/Hard
# card image processing no longer runs during the initial Main Menu startup.

signal level_selected(level: String)

const DIFFICULTY_CARD_SIZE := Vector2(190.0, 190.0)
const BACK_BUTTON_SIZE := Vector2(320.0, 46.0)
const LEVEL_START_WAIT_SECONDS := 2.0

const EASY_CARD_PNG := "res://Resources/Buttons/difficulty_card_easy.png"
const MEDIUM_CARD_PNG := "res://Resources/Buttons/difficulty_card_medium.png"
const HARD_CARD_PNG := "res://Resources/Buttons/difficulty_card_hard.png"
const SQUAD_CARD_PNG := "res://Resources/Buttons/character_card_stone.png"
const BACK_BUTTON_PNG := "res://Resources/Buttons/menu_button_start.png"

var level_page: VBoxContainer = null
var choose_page: VBoxContainer = null
var home_page: VBoxContainer = null

var easy_button: Button = null
var medium_button: Button = null
var hard_button: Button = null
var squad_button: Button = null
var map_title_label: Label = null
var map_gallery_hint: Label = null
var level_back_button: Button = null

var menu_texture_cache: Dictionary = {}

var show_page_callback
var translate_callback
var apply_button_sprite_callback
var remove_outer_white_background_callback
var remove_outer_white_fringe_callback

var preview_only := false
var start_game_after_selection := false
var selection_pending := false
var hovered_level := ""
var selected_level := ""
var configured := false


func setup(nodes: Dictionary, services: Dictionary) -> void:
	if configured:
		return

	level_page = nodes.get("level_page")
	choose_page = nodes.get("choose_page")
	home_page = nodes.get("home_page")

	easy_button = nodes.get("easy_button")
	medium_button = nodes.get("medium_button")
	hard_button = nodes.get("hard_button")
	squad_button = nodes.get("squad_button")
	map_title_label = nodes.get("map_title_label")
	map_gallery_hint = nodes.get("map_gallery_hint")
	level_back_button = nodes.get("level_back_button")

	var cache_value = services.get("menu_texture_cache", {})
	if cache_value is Dictionary:
		menu_texture_cache = cache_value

	show_page_callback = services.get("show_page")
	translate_callback = services.get("translate")
	apply_button_sprite_callback = services.get("apply_button_sprite")
	remove_outer_white_background_callback = services.get(
		"remove_outer_white_background"
	)
	remove_outer_white_fringe_callback = services.get(
		"remove_outer_white_fringe"
	)

	_layout_page()
	_apply_visuals()
	_connect_buttons()

	configured = true


func open_preview() -> void:
	preview_only = true
	start_game_after_selection = false
	selection_pending = false
	selected_level = ""
	hovered_level = ""

	for button in [easy_button, medium_button, hard_button]:
		if button:
			button.release_focus()

	if map_gallery_hint:
		map_gallery_hint.visible = true

	_apply_visuals()
	_update_cards()
	_show_page(level_page)


func open_playable() -> void:
	preview_only = false
	start_game_after_selection = true
	selection_pending = false
	selected_level = ""
	hovered_level = ""

	if map_gallery_hint:
		map_gallery_hint.visible = false

	_apply_visuals()
	_update_cards()
	_show_page(level_page)


func reset_for_start_flow() -> void:
	preview_only = false
	start_game_after_selection = false
	selection_pending = false
	selected_level = ""
	hovered_level = ""

	if map_gallery_hint:
		map_gallery_hint.visible = false

	_update_cards()


func clear_pending() -> void:
	selection_pending = false


func _connect_buttons() -> void:
	if easy_button:
		easy_button.pressed.connect(func(): _select_level("easy"))
		_connect_hover(easy_button, "easy")

	if medium_button:
		medium_button.pressed.connect(func(): _select_level("medium"))
		_connect_hover(medium_button, "medium")

	if hard_button:
		hard_button.pressed.connect(func(): _select_level("hard"))
		_connect_hover(hard_button, "hard")

	if squad_button:
		squad_button.pressed.connect(func(): _select_level("squad"))
		_connect_hover(squad_button, "squad")

	if level_back_button:
		level_back_button.pressed.connect(_on_back_pressed)


func _select_level(level: String) -> void:
	if preview_only:
		if map_gallery_hint:
			map_gallery_hint.text = _t("map_gallery_hint")
		return

	if selection_pending:
		return

	selected_level = level
	_update_cards()

	if start_game_after_selection:
		selection_pending = true
		if map_gallery_hint:
			map_gallery_hint.visible = true
			map_gallery_hint.text = "Wait, game has cooldown xD"

		# Give the menu/game cooldown time to settle before the level starts.
		await get_tree().process_frame
		await get_tree().create_timer(LEVEL_START_WAIT_SECONDS).timeout
		level_selected.emit(level)
		return

	_show_page(choose_page)


func _connect_hover(button: Button, level: String) -> void:
	button.mouse_entered.connect(func():
		hovered_level = level
		_update_cards()
	)

	button.mouse_exited.connect(func():
		if hovered_level == level:
			hovered_level = ""
		_update_cards()
	)

	button.focus_entered.connect(func():
		hovered_level = level
		_update_cards()
	)

	button.focus_exited.connect(func():
		if hovered_level == level:
			hovered_level = ""
		_update_cards()
	)


func _update_cards() -> void:
	for level in ["easy", "medium", "hard", "squad"]:
		var button := _button_for_level(level)
		if not button:
			continue

		if level == selected_level:
			button.modulate = Color(0.72, 1.0, 0.72, 1.0)
		elif level == hovered_level:
			button.modulate = Color(1.18, 1.18, 1.18, 1.0)
		else:
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _button_for_level(level: String) -> Button:
	match level:
		"medium":
			return medium_button
		"hard":
			return hard_button
		"squad":
			return squad_button
		_:
			return easy_button


func _on_back_pressed() -> void:
	selection_pending = false
	selected_level = ""
	hovered_level = ""
	_update_cards()
	_show_page(home_page)


func _show_page(page: Control) -> void:
	if show_page_callback is Callable and show_page_callback.is_valid():
		show_page_callback.call(page)


func _t(key: String) -> String:
	if translate_callback is Callable and translate_callback.is_valid():
		return String(translate_callback.call(key))
	return key


func _layout_page() -> void:
	if not level_page:
		return

	level_page.offset_top = -185.0
	level_page.offset_bottom = 230.0
	level_page.add_theme_constant_override("separation", 8)

	if map_title_label:
		map_title_label.custom_minimum_size = Vector2(610.0, 38.0)

	if map_gallery_hint:
		map_gallery_hint.custom_minimum_size = Vector2(560.0, 44.0)


func _apply_visuals() -> void:
	_apply_difficulty_card_sprite(easy_button, EASY_CARD_PNG)
	_apply_difficulty_card_sprite(medium_button, MEDIUM_CARD_PNG)
	_apply_difficulty_card_sprite(hard_button, HARD_CARD_PNG)
	_apply_difficulty_card_sprite(squad_button, SQUAD_CARD_PNG)

	# Back uses the shared Main Menu button renderer so its appearance remains
	# exactly the same as before.
	if (
		apply_button_sprite_callback is Callable
		and apply_button_sprite_callback.is_valid()
	):
		apply_button_sprite_callback.call(
			level_back_button,
			BACK_BUTTON_PNG,
			BACK_BUTTON_SIZE
		)


func _load_difficulty_card_texture(texture_path: String) -> Texture2D:
	var cache_key := "difficulty_card_clean::" + texture_path

	if menu_texture_cache.has(cache_key):
		return menu_texture_cache[cache_key] as Texture2D

	var source_texture := load(texture_path) as Texture2D
	if not source_texture:
		return null

	var image := source_texture.get_image()
	if not image or image.is_empty():
		return source_texture

	if image.get_format() != Image.FORMAT_RGBA8:
		image.convert(Image.FORMAT_RGBA8)

	# Preserve the exact cleanup behavior from the old main_menu.gd.
	if (
		remove_outer_white_background_callback is Callable
		and remove_outer_white_background_callback.is_valid()
	):
		remove_outer_white_background_callback.call(image)

	if (
		remove_outer_white_fringe_callback is Callable
		and remove_outer_white_fringe_callback.is_valid()
	):
		remove_outer_white_fringe_callback.call(image, 3)

	var cleaned_texture := ImageTexture.create_from_image(image)
	menu_texture_cache[cache_key] = cleaned_texture
	return cleaned_texture


func _apply_difficulty_card_sprite(
	button: Button,
	texture_path: String
) -> void:
	if not button or not ResourceLoader.exists(texture_path):
		return

	var texture := _load_difficulty_card_texture(texture_path)
	if not texture:
		return

	button.custom_minimum_size = DIFFICULTY_CARD_SIZE

	var style := StyleBoxTexture.new()
	style.texture = texture

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	button.add_theme_color_override(
		"font_color",
		Color(0.94, 0.98, 1.0, 1.0)
	)
	button.add_theme_color_override(
		"font_hover_color",
		Color(0.78, 1.0, 0.94, 1.0)
	)
	button.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.9)
	)
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

	var preview := button.get_node_or_null("Preview") as TextureRect
	if preview:
		preview.visible = false

	var title := button.get_node_or_null("Title") as Label
	if title:
		title.z_index = 2
		title.offset_top = -50.0
		title.offset_bottom = -15.0
		title.add_theme_font_size_override("font_size", 20)
