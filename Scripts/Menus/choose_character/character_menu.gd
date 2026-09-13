extends Node

# Character Select is isolated from main_menu.gd.
# The module is loaded only when Character Select is actually opened.
# All character cards are prepared synchronously BEFORE the page is shown,
# so sprites do not appear one-by-one.

signal character_selected(character: String)
signal start_requested
signal online_requested
signal back_requested

const ICE_GOLEM_UNLOCK_COINS := 2500

const CHARACTER_CARD_SIZE := Vector2(220.0, 190.0)
const CHARACTER_ACTION_BUTTON_SIZE := Vector2(260.0, 52.0)
const CHARACTER_ACTION_FONT_SIZE := 18

const CHARACTER_DIVIDER_PNG := "res://Resources/Buttons/character_header.png"
const CHARACTER_HEADER_ROW_SIZE := Vector2(680.0, 38.0)
const CHARACTER_DIVIDER_SIZE := Vector2(680.0, 28.0)
const CHARACTER_DIVIDER_SOURCE_Y := 0.43
const CHARACTER_DIVIDER_SOURCE_HEIGHT := 0.16
const CHARACTER_HEADER_FONT_SIZE := 27
const CHARACTER_COINS_FONT_SIZE := 20
const CHARACTER_HEADER_TEXT_Y_OFFSET := 18.0
const CHARACTER_CHOOSE_TEXT_X_OFFSET := 0.0
const CHARACTER_COINS_TEXT_X_OFFSET := 0.0

const CHARACTER_DISPLAY_NAMES := {
	"player": "Ash Golem",
	"golem": "Stone Golem",
	"ice_golem": "Ice Golem",
	"crusader": "Skeleton Crusader",
	"wraith": "Wraith",
	"minotaur": "Minotaur",
	"ranger": "Forest Ranger"
}

const STORY_CHARACTERS := ["player", "golem", "ice_golem"]
const SQUAD_CHARACTERS := ["crusader", "wraith", "minotaur", "ranger"]
const ASH_PREVIEW_PNG := "res://Resources/ash_golem_preview.png"
const STONE_PREVIEW_PNG := "res://Characters/Golem/PNG/PNG Sequences/Idle/0_Golem_Idle_000.png"
const ICE_PREVIEW_PNG := "res://Characters/Golem_1/PNG/PNG Sequences/Idle/0_Golem_Idle_000.png"
const CRUSADER_PREVIEW_PNG := "res://Characters/Skeleton_crusider/Skeleton_Crusader_1/PNG/PNG Sequences/Idle/0_Skeleton_Crusader_Idle_000.png"
const WRAITH_PREVIEW_PNG := "res://Characters/Wraithes/PNG/Wraith_01/PNG Sequences/Idle/Wraith_01_Idle_000.png"
const MINOTAUR_PREVIEW_PNG := "res://Characters/Minotaurs/Minotaur_3/PNG/PNG Sequences/Idle/0_Minotaur_Idle_000.png"
const RANGER_PREVIEW_PNG := "res://Characters/Forest_Ranger_2/PNG/PNG Sequences/Idle/0_Forest_Ranger_Idle_000.png"

const ASH_CARD_PNG := "res://Resources/Buttons/character_card_ash.png"
const STONE_CARD_PNG := "res://Resources/Buttons/character_card_stone.png"
const ICE_CARD_PNG := "res://Resources/Buttons/character_card_ice.png"

const START_BUTTON_PNG := "res://Resources/Buttons/menu_button_start.png"
const ONLINE_BUTTON_PNG := "res://Resources/Buttons/menu_button_how_to_play.png"
const BACK_BUTTON_PNG := "res://Resources/Buttons/menu_button_start.png"

var choose_page: VBoxContainer = null
var choose_header: Label = null
var wallet_label: Label = null
var player_card: PanelContainer = null
var golem_card: PanelContainer = null
var ice_golem_card: PanelContainer = null
var player_select_button: Button = null
var golem_select_button: Button = null
var ice_golem_select_button: Button = null
var minotaur_card: PanelContainer = null
var ranger_card: PanelContainer = null
var minotaur_select_button: Button = null
var ranger_select_button: Button = null
var character_status: Label = null
var choose_start_button: Button = null
var choose_online_button: Button = null
var choose_back_button: Button = null

var character_header_group: VBoxContainer = null
var character_header_row: HBoxContainer = null
var character_divider_image: TextureRect = null

var settings: Node = null
var menu_texture_cache: Dictionary = {}

var show_page_callback
var translate_callback
var apply_button_sprite_callback
var remove_outer_white_background_callback
var remove_outer_white_fringe_callback
var remove_baked_checkerboard_background_callback

var joined_room_waiting_for_character := false
var other_player_character_chosen := false
var other_player_character := ""
var online_character_locked := false

var configured := false


func setup(page: VBoxContainer, services: Dictionary) -> void:
	if configured:
		return
	if not page:
		return

	choose_page = page

	choose_header = choose_page.get_node_or_null("Header") as Label
	wallet_label = choose_page.get_node_or_null("WalletLabel") as Label
	player_card = choose_page.get_node_or_null("Cards/PlayerCard") as PanelContainer
	golem_card = choose_page.get_node_or_null("Cards/GolemCard") as PanelContainer
	ice_golem_card = choose_page.get_node_or_null("Cards/IceGolemCard") as PanelContainer
	minotaur_card = choose_page.get_node_or_null("Cards/MinotaurCard") as PanelContainer
	ranger_card = choose_page.get_node_or_null("Cards/RangerCard") as PanelContainer

	if player_card:
		player_select_button = player_card.get_node_or_null("Box/SelectButton") as Button
	if golem_card:
		golem_select_button = golem_card.get_node_or_null("Box/SelectButton") as Button
	if ice_golem_card:
		ice_golem_select_button = ice_golem_card.get_node_or_null("Box/SelectButton") as Button
	if minotaur_card:
		minotaur_select_button = minotaur_card.get_node_or_null("Box/SelectButton") as Button
	if ranger_card:
		ranger_select_button = ranger_card.get_node_or_null("Box/SelectButton") as Button

	character_status = choose_page.get_node_or_null("StatusLabel") as Label
	choose_start_button = choose_page.get_node_or_null("StartButton") as Button
	choose_online_button = choose_page.get_node_or_null("OnlineButton") as Button
	choose_back_button = choose_page.get_node_or_null("BackButton") as Button

	settings = services.get("settings") as Node

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
	remove_baked_checkerboard_background_callback = services.get(
		"remove_baked_checkerboard_background"
	)

	# Build the complete Character page BEFORE it is shown.
	_layout_character_page()
	_apply_character_visuals()
	_configure_mode_cards()
	_connect_character_inputs()

	if player_select_button:
		player_select_button.visible = true
	if golem_select_button:
		golem_select_button.visible = true
	if ice_golem_select_button:
		ice_golem_select_button.visible = true
	if minotaur_select_button:
		minotaur_select_button.visible = true
	if ranger_select_button:
		ranger_select_button.visible = true

	refresh_language()
	refresh()

	configured = true


func open(status_override: String = "") -> void:
	_configure_mode_cards()
	refresh()
	if not status_override.is_empty():
		set_status(status_override)
	_show_page(choose_page)


func reset_for_start_flow() -> void:
	joined_room_waiting_for_character = false
	other_player_character_chosen = false
	other_player_character = ""
	online_character_locked = false
	refresh()


func set_online_state(
	joined_waiting: bool,
	other_chosen: bool,
	other_character: String,
	locked: bool
) -> void:
	joined_room_waiting_for_character = joined_waiting
	other_player_character_chosen = other_chosen
	other_player_character = other_character
	online_character_locked = locked


func set_status(text: String) -> void:
	if character_status:
		character_status.text = text


func set_buttons_enabled(enabled: bool) -> void:
	for character in _selectable_characters():
		var card := _character_card(character)
		var select_button := _character_select_button(character)
		var available := enabled and _is_character_unlocked(character)

		if select_button:
			select_button.disabled = not available
		if card:
			card.mouse_filter = (
				Control.MOUSE_FILTER_STOP
				if available
				else Control.MOUSE_FILTER_IGNORE
			)

	_set_ice_golem_button_text()


func display_name(character: String) -> String:
	return String(CHARACTER_DISPLAY_NAMES.get(character, "Ash Golem"))


func refresh_language() -> void:
	if not configured and not choose_page:
		return

	# The upper artwork already contains the title.
	if choose_header:
		choose_header.text = ""
		choose_header.visible = false

	if player_select_button:
		player_select_button.text = _t("select")
	if golem_select_button:
		golem_select_button.text = _t("select")

	_set_ice_golem_button_text()
	_update_wallet_label()

	if choose_start_button:
		choose_start_button.text = _t("start_game")
	if choose_online_button:
		choose_online_button.text = _t("online_room")
	if choose_back_button:
		choose_back_button.text = _t("back")

	_update_character_header_image()


func refresh() -> void:
	_configure_mode_cards()
	_update_wallet_label()

	for character in _selectable_characters():
		var card := _character_card(character)
		if not card:
			continue

		card.modulate = Color(1.0, 1.0, 1.0)
		_set_card_crossed(card, false)
		_set_character_card_available(
			card,
			_is_character_unlocked(character)
		)

	_set_ice_golem_button_text()

	if joined_room_waiting_for_character and other_player_character_chosen:
		var taken_card := _character_card(other_player_character)
		if taken_card:
			taken_card.modulate = Color(0.45, 0.45, 0.45)
			_set_card_crossed(taken_card, true)
			_set_character_card_available(taken_card, false)

	if not settings or settings.get("character_chosen") != true:
		set_status(_t("choose_first"))
		set_buttons_enabled(true)
		_apply_taken_character_input_state()
		return

	var selected_character := String(settings.get("selected_character"))
	var selected_card := _character_card(selected_character)
	if selected_card:
		selected_card.modulate = Color(0.65, 1.0, 0.65)

	set_buttons_enabled(not online_character_locked)
	_apply_taken_character_input_state()


func _connect_character_inputs() -> void:
	if player_select_button:
		player_select_button.pressed.connect(
			func(): _select_character(_character_for_slot(0))
		)
	if golem_select_button:
		golem_select_button.pressed.connect(
			func(): _select_character(_character_for_slot(1))
		)
	if ice_golem_select_button:
		ice_golem_select_button.pressed.connect(
			func(): _select_character(_character_for_slot(2))
		)
	if minotaur_select_button:
		minotaur_select_button.pressed.connect(
			func(): _select_character(_character_for_slot(2))
		)
	if ranger_select_button:
		ranger_select_button.pressed.connect(
			func(): _select_character(_character_for_slot(3))
		)

	_make_character_card_tappable(player_card, 0)
	_make_character_card_tappable(golem_card, 1)
	_make_character_card_tappable(ice_golem_card, 2)
	_make_character_card_tappable(minotaur_card, 2)
	_make_character_card_tappable(ranger_card, 3)

	if choose_start_button:
		choose_start_button.pressed.connect(
			func(): start_requested.emit()
		)

	if choose_online_button:
		choose_online_button.pressed.connect(
			func(): online_requested.emit()
		)

	if choose_back_button:
		choose_back_button.pressed.connect(
			func(): back_requested.emit()
		)


func _select_character(character: String) -> void:
	if character.is_empty():
		return
	if online_character_locked:
		return

	if not _is_character_unlocked(character):
		var character_name := display_name(character)
		var unlock_cost := _character_unlock_cost(character)

		refresh()
		set_status(
			_t("character_locked") % [
				character_name,
				unlock_cost,
				_saved_coins()
			]
		)
		return

	if _is_character_taken_by_other_player(character):
		return

	if settings:
		settings.set("selected_character", character)
		settings.set("character_chosen", true)

	var character_name := display_name(character)
	set_status(_t("selected") % character_name)

	# Online character selection becomes locked immediately after choosing.
	if joined_room_waiting_for_character:
		online_character_locked = true

	refresh()
	character_selected.emit(character)


func _make_character_card_tappable(
	card: Control,
	character_slot: int
) -> void:
	if not card:
		return

	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	card.gui_input.connect(
		func(event: InputEvent):
			_select_character_from_card_input(
				event,
				_character_for_slot(character_slot),
				card
			)
	)

	for child in card.find_children("*", "Control"):
		var control := child as Control
		control.mouse_filter = Control.MOUSE_FILTER_PASS
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _select_character_from_card_input(
	event: InputEvent,
	character: String,
	card: Control
) -> void:
	if online_character_locked:
		return

	if not _is_character_unlocked(character):
		_select_character(character)
		return

	if _is_character_taken_by_other_player(character):
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and mouse_event.pressed
		):
			_select_character(character)
			card.accept_event()

	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_select_character(character)
			card.accept_event()


func _apply_character_visuals() -> void:
	_apply_character_card_sprite(player_card, ASH_CARD_PNG)
	_apply_character_card_sprite(golem_card, STONE_CARD_PNG)
	_apply_character_card_sprite(ice_golem_card, ICE_CARD_PNG)
	_apply_character_card_sprite(minotaur_card, STONE_CARD_PNG)
	_apply_character_card_sprite(ranger_card, ASH_CARD_PNG)

	_apply_flat_text_button(player_select_button)
	_apply_flat_text_button(golem_select_button)
	_apply_flat_text_button(ice_golem_select_button)
	_apply_flat_text_button(minotaur_select_button)
	_apply_flat_text_button(ranger_select_button)

	if (
		apply_button_sprite_callback is Callable
		and apply_button_sprite_callback.is_valid()
	):
		apply_button_sprite_callback.call(
			choose_start_button,
			START_BUTTON_PNG,
			CHARACTER_ACTION_BUTTON_SIZE
		)
		apply_button_sprite_callback.call(
			choose_online_button,
			ONLINE_BUTTON_PNG,
			CHARACTER_ACTION_BUTTON_SIZE
		)
		apply_button_sprite_callback.call(
			choose_back_button,
			BACK_BUTTON_PNG,
			CHARACTER_ACTION_BUTTON_SIZE
		)

	_fix_character_action_button_sizes()


func _fix_character_action_button_sizes() -> void:
	for button in [
		choose_start_button,
		choose_online_button,
		choose_back_button
	]:
		if not button:
			continue

		button.custom_minimum_size = CHARACTER_ACTION_BUTTON_SIZE
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.add_theme_font_size_override(
			"font_size",
			CHARACTER_ACTION_FONT_SIZE
		)


func _apply_character_card_sprite(
	card: PanelContainer,
	texture_path: String
) -> void:
	if not card or not ResourceLoader.exists(texture_path):
		return

	var texture := _load_character_card_texture(texture_path)
	if not texture:
		return

	card.custom_minimum_size = CHARACTER_CARD_SIZE

	var style := StyleBoxTexture.new()
	style.texture = texture
	card.add_theme_stylebox_override("panel", style)

	var box := card.get_node_or_null("Box") as VBoxContainer
	if box:
		box.add_theme_constant_override("separation", 2)


func _load_character_card_texture(texture_path: String) -> Texture2D:
	var cache_key := "character_card_clean::" + texture_path

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


func _apply_flat_text_button(button: Button) -> void:
	if not button:
		return

	var empty := StyleBoxEmpty.new()

	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_stylebox_override("focus", empty)

	button.add_theme_color_override(
		"font_color",
		Color(0.94, 0.98, 1.0, 1.0)
	)
	button.add_theme_color_override(
		"font_hover_color",
		Color(0.78, 1.0, 0.94, 1.0)
	)
	button.add_theme_color_override(
		"font_pressed_color",
		Color(0.62, 0.88, 0.82, 1.0)
	)
	button.add_theme_color_override(
		"font_disabled_color",
		Color(0.58, 0.66, 0.68, 0.9)
	)


func _layout_character_page() -> void:
	if not choose_page or not choose_header or not wallet_label:
		return

	character_header_group = (
		choose_page.get_node_or_null("CharacterHeaderGroup")
		as VBoxContainer
	)

	if not character_header_group:
		character_header_group = VBoxContainer.new()
		character_header_group.name = "CharacterHeaderGroup"
		character_header_group.alignment = BoxContainer.ALIGNMENT_CENTER
		character_header_group.add_theme_constant_override("separation", 0)
		character_header_group.custom_minimum_size = Vector2(
			CHARACTER_HEADER_ROW_SIZE.x,
			CHARACTER_HEADER_ROW_SIZE.y + CHARACTER_DIVIDER_SIZE.y
		)
		character_header_group.size_flags_horizontal = (
			Control.SIZE_SHRINK_CENTER
		)
		choose_page.add_child(character_header_group)
		choose_page.move_child(character_header_group, 0)

	character_header_row = (
		character_header_group.get_node_or_null("HeaderRow")
		as HBoxContainer
	)

	if not character_header_row:
		character_header_row = HBoxContainer.new()
		character_header_row.name = "HeaderRow"
		character_header_row.alignment = BoxContainer.ALIGNMENT_CENTER
		character_header_row.add_theme_constant_override("separation", 35)
		character_header_row.custom_minimum_size = CHARACTER_HEADER_ROW_SIZE
		character_header_group.add_child(character_header_row)

	var choose_slot := (
		character_header_row.get_node_or_null("ChooseTextSlot")
		as Control
	)

	if not choose_slot:
		choose_slot = Control.new()
		choose_slot.name = "ChooseTextSlot"
		choose_slot.custom_minimum_size = Vector2(
			430.0,
			CHARACTER_HEADER_ROW_SIZE.y
		)
		choose_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		choose_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		character_header_row.add_child(choose_slot)
		choose_header.reparent(choose_slot)

	var coins_slot := (
		character_header_row.get_node_or_null("CoinsTextSlot")
		as Control
	)

	if not coins_slot:
		coins_slot = Control.new()
		coins_slot.name = "CoinsTextSlot"
		coins_slot.custom_minimum_size = Vector2(
			170.0,
			CHARACTER_HEADER_ROW_SIZE.y
		)
		coins_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		coins_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		character_header_row.add_child(coins_slot)
		wallet_label.reparent(coins_slot)

	choose_header.set_anchors_preset(Control.PRESET_TOP_LEFT)
	choose_header.position = Vector2(
		CHARACTER_CHOOSE_TEXT_X_OFFSET,
		CHARACTER_HEADER_TEXT_Y_OFFSET
	)
	choose_header.size = Vector2(430.0, CHARACTER_HEADER_ROW_SIZE.y)
	choose_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	choose_header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	wallet_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	wallet_label.position = Vector2(
		CHARACTER_COINS_TEXT_X_OFFSET,
		CHARACTER_HEADER_TEXT_Y_OFFSET
	)
	wallet_label.size = Vector2(170.0, CHARACTER_HEADER_ROW_SIZE.y)
	wallet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	choose_header.add_theme_font_size_override(
		"font_size",
		CHARACTER_HEADER_FONT_SIZE
	)
	choose_header.add_theme_color_override(
		"font_color",
		Color(0.96, 0.99, 1.0, 1.0)
	)
	choose_header.add_theme_color_override(
		"font_shadow_color",
		Color(0.20, 0.78, 1.0, 0.65)
	)
	choose_header.add_theme_constant_override("shadow_offset_x", 0)
	choose_header.add_theme_constant_override("shadow_offset_y", 2)

	wallet_label.add_theme_font_size_override(
		"font_size",
		CHARACTER_COINS_FONT_SIZE
	)
	wallet_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.78, 0.06, 1.0)
	)
	wallet_label.add_theme_color_override(
		"font_shadow_color",
		Color(0.0, 0.0, 0.0, 0.85)
	)
	wallet_label.add_theme_constant_override("shadow_offset_x", 1)
	wallet_label.add_theme_constant_override("shadow_offset_y", 2)

	var divider_slot := (
		character_header_group.get_node_or_null("DividerSlot")
		as Control
	)

	if not divider_slot:
		divider_slot = Control.new()
		divider_slot.name = "DividerSlot"
		divider_slot.custom_minimum_size = CHARACTER_DIVIDER_SIZE
		divider_slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		divider_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		character_header_group.add_child(divider_slot)

	character_divider_image = (
		divider_slot.get_node_or_null("DividerImage")
		as TextureRect
	)

	if not character_divider_image:
		character_divider_image = TextureRect.new()
		character_divider_image.name = "DividerImage"
		divider_slot.add_child(character_divider_image)

	character_divider_image.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	character_divider_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character_divider_image.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	character_divider_image.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# This setup runs only once because the whole Character module is lazy.
	choose_page.position.y += 8.0
	choose_page.add_theme_constant_override("separation", 5)


func _load_character_divider_texture(
	texture_path: String
) -> Texture2D:
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null

	var cache_key := "character_divider::" + texture_path

	if menu_texture_cache.has(cache_key):
		return menu_texture_cache[cache_key] as Texture2D

	var source_texture := load(texture_path) as Texture2D
	if not source_texture:
		return null

	var source := source_texture.get_image()
	if not source or source.is_empty():
		return null

	if source.get_format() != Image.FORMAT_RGBA8:
		source.convert(Image.FORMAT_RGBA8)

	var source_width := source.get_width()
	var source_height := source.get_height()

	var crop_y := clampi(
		int(round(float(source_height) * CHARACTER_DIVIDER_SOURCE_Y)),
		0,
		maxi(source_height - 1, 0)
	)
	var crop_height := clampi(
		int(
			round(
				float(source_height)
				* CHARACTER_DIVIDER_SOURCE_HEIGHT
			)
		),
		1,
		maxi(source_height - crop_y, 1)
	)

	var cropped := Image.create(
		source_width,
		crop_height,
		false,
		Image.FORMAT_RGBA8
	)

	cropped.blit_rect(
		source,
		Rect2i(0, crop_y, source_width, crop_height),
		Vector2i.ZERO
	)

	if (
		remove_baked_checkerboard_background_callback is Callable
		and remove_baked_checkerboard_background_callback.is_valid()
	):
		remove_baked_checkerboard_background_callback.call(cropped)

	var used_rect := cropped.get_used_rect()
	if used_rect.size.x > 0 and used_rect.size.y > 0:
		var trimmed := Image.create(
			used_rect.size.x,
			used_rect.size.y,
			false,
			Image.FORMAT_RGBA8
		)
		trimmed.blit_rect(cropped, used_rect, Vector2i.ZERO)
		cropped = trimmed

	var result := ImageTexture.create_from_image(cropped)
	menu_texture_cache[cache_key] = result
	return result


func _update_character_header_image() -> void:
	if not choose_header or not wallet_label:
		return

	choose_header.visible = false
	choose_header.text = ""

	wallet_label.visible = not _is_squad_mode()
	wallet_label.text = _t("coins") % _saved_coins()

	if character_divider_image:
		var texture := _load_character_divider_texture(
			CHARACTER_DIVIDER_PNG
		)
		character_divider_image.texture = texture
		character_divider_image.visible = texture != null


func _update_wallet_label() -> void:
	if wallet_label:
		wallet_label.text = _t("coins") % _saved_coins()


func _set_character_card_available(
	card: Control,
	available: bool
) -> void:
	if not card:
		return

	var select_button := (
		card.get_node_or_null("Box/SelectButton")
		as Button
	)

	if select_button:
		select_button.disabled = not available

	card.mouse_filter = (
		Control.MOUSE_FILTER_STOP
		if available
		else Control.MOUSE_FILTER_IGNORE
	)


func _apply_taken_character_input_state() -> void:
	if (
		not joined_room_waiting_for_character
		or not other_player_character_chosen
	):
		return

	var card := _character_card(other_player_character)
	if card:
		_set_character_card_available(card, false)


func _is_squad_mode() -> bool:
	return settings != null and String(settings.get("game_mode")) == "squad"


func _selectable_characters() -> Array:
	return SQUAD_CHARACTERS if _is_squad_mode() else STORY_CHARACTERS


func _character_for_slot(slot: int) -> String:
	var characters := _selectable_characters()
	if slot < 0 or slot >= characters.size():
		return ""
	return String(characters[slot])


func _configure_mode_cards() -> void:
	if not player_card or not golem_card or not ice_golem_card or not minotaur_card or not ranger_card:
		return

	var squad_mode := _is_squad_mode()
	ice_golem_card.visible = not squad_mode
	minotaur_card.visible = squad_mode
	ranger_card.visible = squad_mode
	var card_size := Vector2(220.0, 190.0) if not squad_mode else Vector2(160.0, 190.0)
	for card in [player_card, golem_card, ice_golem_card, minotaur_card, ranger_card]:
		card.custom_minimum_size = card_size
		var preview := card.get_node_or_null("Box/Preview") as TextureRect
		if preview:
			preview.custom_minimum_size = Vector2(card_size.x - 20.0, 115.0)
	if wallet_label:
		wallet_label.visible = not squad_mode

	if squad_mode:
		_set_card_identity(player_card, "Skeleton Crusader", CRUSADER_PREVIEW_PNG)
		_set_card_identity(golem_card, "Wraith", WRAITH_PREVIEW_PNG)
		_set_card_identity(minotaur_card, "Minotaur", MINOTAUR_PREVIEW_PNG)
		_set_card_identity(ranger_card, "Forest Ranger", RANGER_PREVIEW_PNG)
	else:
		_set_card_identity(player_card, "Ash Golem", ASH_PREVIEW_PNG)
		_set_card_identity(golem_card, "Stone Golem", STONE_PREVIEW_PNG)
		_set_card_identity(ice_golem_card, "Ice Golem", ICE_PREVIEW_PNG)
		_set_card_identity(minotaur_card, "Minotaur", MINOTAUR_PREVIEW_PNG)
		_set_card_identity(ranger_card, "Forest Ranger", RANGER_PREVIEW_PNG)


func _set_card_identity(
	card: PanelContainer,
	display_text: String,
	preview_path: String
) -> void:
	if not card:
		return
	var name_label := card.get_node_or_null("Box/Name") as Label
	if name_label:
		name_label.text = display_text
	var preview := card.get_node_or_null("Box/Preview") as TextureRect
	if preview and ResourceLoader.exists(preview_path):
		preview.texture = load(preview_path) as Texture2D


func _character_card(character: String) -> PanelContainer:
	match character:
		"golem", "wraith":
			return golem_card
		"ice_golem":
			return ice_golem_card
		"minotaur":
			return minotaur_card
		"ranger":
			return ranger_card
		_:
			return player_card


func _character_select_button(character: String) -> Button:
	match character:
		"golem", "wraith":
			return golem_select_button
		"ice_golem":
			return ice_golem_select_button
		"minotaur":
			return minotaur_select_button
		"ranger":
			return ranger_select_button
		_:
			return player_select_button


func _saved_coins() -> int:
	if settings and settings.has_method("get_saved_coins"):
		return int(settings.call("get_saved_coins"))

	if settings:
		return int(settings.get("saved_coins"))

	return 0


func _character_unlock_cost(character: String) -> int:
	if settings and settings.has_method("get_character_unlock_cost"):
		return int(
			settings.call(
				"get_character_unlock_cost",
				character
			)
		)

	if character == "ice_golem":
		return ICE_GOLEM_UNLOCK_COINS

	return 0


func _is_character_unlocked(character: String) -> bool:
	if settings and settings.has_method("is_character_unlocked"):
		return bool(
			settings.call(
				"is_character_unlocked",
				character
			)
		)

	return _saved_coins() >= _character_unlock_cost(character)


func _ice_golem_button_text() -> String:
	if _is_character_unlocked("ice_golem"):
		return _t("select")

	return _t("locked") % [
		_saved_coins(),
		_character_unlock_cost("ice_golem")
	]


func _set_ice_golem_button_text() -> void:
	if ice_golem_select_button:
		ice_golem_select_button.text = _ice_golem_button_text()


func _set_card_crossed(card: Control, crossed: bool) -> void:
	if not card:
		return

	var cross := card.get_node_or_null("SelectedCross") as Label

	if not crossed:
		if cross:
			cross.visible = false
		return

	if not cross:
		cross = Label.new()
		cross.name = "SelectedCross"
		cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cross.set_anchors_preset(Control.PRESET_FULL_RECT)
		cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cross.add_theme_font_size_override("font_size", 92)
		cross.add_theme_color_override(
			"font_color",
			Color(1.0, 0.12, 0.08, 0.86)
		)
		cross.text = "X"
		card.add_child(cross)

	cross.visible = true
	cross.move_to_front()


func _is_character_taken_by_other_player(
	character: String
) -> bool:
	if _is_squad_mode():
		return false
	return (
		joined_room_waiting_for_character
		and other_player_character_chosen
		and other_player_character == character
	)


func _show_page(page: Control) -> void:
	if show_page_callback is Callable and show_page_callback.is_valid():
		show_page_callback.call(page)


func _t(key: String) -> String:
	if translate_callback is Callable and translate_callback.is_valid():
		return String(translate_callback.call(key))
	return key
