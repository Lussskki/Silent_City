extends CanvasLayer

@onready var health_bar: Range = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var enemy_count_label: Label = $EnemyCountLabel
@onready var lives_label: Label = $LivesLabel
@onready var round_label: Label = $RoundLabel
@onready var menu_button: Button = $MenuButton
@onready var pause_menu: Panel = $PauseMenu
@onready var online_status_label: Label = $PauseMenu/Box/OnlineStatusLabel
@onready var return_button: Button = $PauseMenu/Box/ReturnButton
@onready var main_menu_button: Button = $PauseMenu/Box/MainMenuButton
@onready var power_bar: Range = get_node_or_null("CoinPowerBar") as Range
@onready var power_label: Label = get_node_or_null("CoinPowerLabel") as Label
@onready var life_text: TextureRect = get_node_or_null("LifeText") as TextureRect
@onready var power_text: TextureRect = get_node_or_null("PowerText") as TextureRect
@onready var enemies_text: TextureRect = get_node_or_null("EnemiesText") as TextureRect
@onready var lives_text: TextureRect = get_node_or_null("LivesText") as TextureRect

var chat_button: Button
var chat_badge: Label
var chat_panel: Panel
var chat_messages: RichTextLabel
var chat_sprite_messages: VBoxContainer
var chat_placeholder_text: TextureRect
var chat_input_sprite_row: HBoxContainer
var chat_input_caret: TextureRect
var chat_input: LineEdit
var chat_send_button: Button
var player: Node
var match_popup: Panel
var match_label: Label
var match_restart_button: Button
var match_exit_button: Button
var match_box: VBoxContainer
var match_result_sprite: TextureRect
var second_player_label: Label
var enemy_value_row: HBoxContainer
var lives_value_row: HBoxContainer
var rounds_text: TextureRect
var rounds_value_row: HBoxContainer
var second_player_text: TextureRect
var second_player_status_text: TextureRect
var enemies_seen_once := false
var game_result_shown := false
var result_check_delay := 0.35
var death_recorded := false
var force_close_online_on_exit := false
var chat_caret_time := 0.0

var pause_title_sprite: TextureRect
var pause_audio_button: Button
var pause_master_volume_button: Button
var pause_audio_back_button: Button
var pause_audio_volume_index := 0
var pause_audio_submenu_open := false
var menu_texture_cache: Dictionary = {}
var menu_optimizer = null

const HUD_BAR_WIDTH := 150.0
const HUD_BAR_HEIGHT := 19.0
const HUD_VALUE_HEIGHT := 22.0
const HUD_HEART_SIZE := Vector2(38.0, 38.0)
const CHAT_MESSAGE_TEXT_HEIGHT := 16.0
const CHAT_MESSAGE_FIRST_LINE_WIDTH := 244.0
const CHAT_MESSAGE_NEXT_LINE_WIDTH := 266.0
const MENU_TEXTURE_CACHE_META := "_silent_city_menu_texture_cache_v1"

const HUD_HEART_FULL_PNG := "res://Resources/Deffence/heart_full.png"
const HUD_HEART_BROKEN_PNG := "res://Resources/Deffence/heart_broken.png"

# Pause-menu audio settings. Uses the SAME config file as Main Menu -> Settings -> Audio.
const AUDIO_CONFIG_PATH := "user://audio_settings.cfg"
const AUDIO_VOLUME_STEPS := [100, 75, 50, 25, 0]

# ESC / Pause menu sprite assets.
# Change only these paths if your PNG names/locations are different.
const PAUSE_TITLE_PNG := "res://Resources/Buttons/Paused.png"
const PAUSE_AUDIO_PNG := "res://Resources/Buttons/Audio.png"
const PAUSE_RETURN_PNG := "res://Resources/Buttons/return_to_game.png"
const PAUSE_MAIN_MENU_PNG := "res://Resources/Buttons/main_menu.png"

# Audio submenu sprites. Change only these paths if your file names differ.
const PAUSE_VOLUME_100_PNG := "res://Resources/Buttons/100.png"
const PAUSE_VOLUME_75_PNG := "res://Resources/Buttons/75.png"
const PAUSE_VOLUME_50_PNG := "res://Resources/Buttons/50.png"
const PAUSE_VOLUME_25_PNG := "res://Resources/Buttons/25.png"
const PAUSE_VOLUME_0_PNG := "res://Resources/Buttons/0.png"
const PAUSE_AUDIO_BACK_PNG := "res://Resources/Buttons/in_game_back.png"
const RESULT_LOSE_PNG := "res://Resources/Buttons/Game_Final.png"

const PAUSE_TITLE_SIZE := Vector2(330.0, 70.0)
const PAUSE_BUTTON_SIZE := Vector2(330.0, 56.0)
const PAUSE_AUDIO_SUB_BUTTON_SIZE := Vector2(330.0, 56.0)
const RESULT_BUTTON_SIZE := Vector2(260.0, 48.0)
const RESULT_SPRITE_POPUP_SIZE := Vector2(390.0, 220.0)


func _ready() -> void:
	add_to_group("PlayerHUD")
	_setup_runtime_texture_optimizer()
	_normalize_pause_menu_layout()
	menu_button.pressed.connect(_open_pause_menu)
	return_button.pressed.connect(_return_to_game)
	main_menu_button.pressed.connect(_go_to_main_menu)
	_setup_pause_audio_menu()
	_setup_pause_sprite_ui()
	_load_pause_audio_settings()
	pause_menu.visible = false
	_create_chat_ui()
	_create_match_popup()
	_create_second_player_label()
	_create_hud_value_rows()
	_create_online_hud_sprites()
	_connect_round_counter()
	_connect_local_player()
	_layout_status_hud()
	_update_enemy_count()
	_update_try_count()
	_update_second_player_status()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if pause_menu.visible:
			_return_to_game()
		else:
			_open_pause_menu()

	var local_player := get_tree().get_first_node_in_group("LocalPlayer")
	if local_player and local_player != player:
		_connect_local_player()
	_update_chat_visibility()
	_layout_status_hud()
	var enemies_left := _update_enemy_count()
	_update_second_player_status()
	_update_chat_input_caret(delta)
	_update_offline_result(delta, enemies_left)


func _normalize_pause_menu_layout() -> void:
	layer = 100
	menu_button.z_index = 100
	menu_button.visible = false
	menu_button.disabled = true
	menu_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.anchor_left = 1.0
	menu_button.anchor_top = 0.0
	menu_button.anchor_right = 1.0
	menu_button.anchor_bottom = 0.0
	menu_button.offset_left = -52.0
	menu_button.offset_top = 12.0
	menu_button.offset_right = -12.0
	menu_button.offset_bottom = 44.0

	pause_menu.z_index = 101
	pause_menu.anchor_left = 0.5
	pause_menu.anchor_top = 0.5
	pause_menu.anchor_right = 0.5
	pause_menu.anchor_bottom = 0.5
	pause_menu.offset_left = -205.0
	pause_menu.offset_top = -155.0
	pause_menu.offset_right = 205.0
	pause_menu.offset_bottom = 155.0

	# Remove the old black PauseMenu rectangle completely.
	pause_menu.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	var box := pause_menu.get_node_or_null("Box") as VBoxContainer
	if not box:
		return
	box.anchor_left = 0.0
	box.anchor_top = 0.0
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 18.0
	box.offset_top = 16.0
	box.offset_right = -18.0
	box.offset_bottom = -16.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	if online_status_label:
		online_status_label.visible = false
		online_status_label.custom_minimum_size = Vector2.ZERO
		online_status_label.text = ""


func _setup_pause_sprite_ui() -> void:
	var box := pause_menu.get_node_or_null("Box") as VBoxContainer
	if not box:
		return

	# Hide the old normal "Paused" Label if it exists in the scene.
	for child in box.get_children():
		if child is Label:
			var label := child as Label
			if label.text.strip_edges().to_lower() == "paused":
				label.visible = false
				label.custom_minimum_size = Vector2.ZERO

	pause_title_sprite = box.get_node_or_null("PauseTitleSprite") as TextureRect
	if not pause_title_sprite:
		pause_title_sprite = TextureRect.new()
		pause_title_sprite.name = "PauseTitleSprite"
		pause_title_sprite.custom_minimum_size = PAUSE_TITLE_SIZE
		pause_title_sprite.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pause_title_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pause_title_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pause_title_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pause_title_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
		box.add_child(pause_title_sprite)
		box.move_child(pause_title_sprite, 0)

	pause_title_sprite.texture = _load_clean_pause_texture(PAUSE_TITLE_PNG)

	_apply_pause_button_sprite(
		pause_audio_button,
		PAUSE_AUDIO_PNG,
		PAUSE_BUTTON_SIZE
	)
	_apply_pause_button_sprite(
		return_button,
		PAUSE_RETURN_PNG,
		PAUSE_BUTTON_SIZE
	)
	_apply_pause_button_sprite(
		main_menu_button,
		PAUSE_MAIN_MENU_PNG,
		PAUSE_BUTTON_SIZE
	)

	# Audio submenu also uses PNG sprites; no normal Godot text/buttons remain.
	_refresh_pause_audio_submenu_sprites()


func _apply_pause_button_sprite(
	button: Button,
	texture_path: String,
	minimum_size: Vector2
) -> void:
	if not button:
		return

	var texture := _load_clean_pause_texture(texture_path)
	if not texture:
		push_warning("Pause sprite not found or could not be loaded: " + texture_path)
		return

	# Text is already painted into the PNG itself.
	button.text = ""
	button.custom_minimum_size = minimum_size
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE

	button.add_theme_stylebox_override("normal", _pause_texture_style(texture))
	button.add_theme_stylebox_override("hover", _pause_texture_style(texture))
	button.add_theme_stylebox_override("pressed", _pause_texture_style(texture))
	button.add_theme_stylebox_override("disabled", _pause_texture_style(texture))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _pause_texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	return style


func _pause_volume_sprite_path() -> String:
	var percent: int = int(AUDIO_VOLUME_STEPS[pause_audio_volume_index])

	match percent:
		100:
			return PAUSE_VOLUME_100_PNG
		75:
			return PAUSE_VOLUME_75_PNG
		50:
			return PAUSE_VOLUME_50_PNG
		25:
			return PAUSE_VOLUME_25_PNG
		0:
			return PAUSE_VOLUME_0_PNG

	return PAUSE_VOLUME_100_PNG


func _refresh_pause_audio_submenu_sprites() -> void:
	if pause_master_volume_button:
		_apply_pause_button_sprite(
			pause_master_volume_button,
			_pause_volume_sprite_path(),
			PAUSE_AUDIO_SUB_BUTTON_SIZE
		)

	if pause_audio_back_button:
		_apply_pause_button_sprite(
			pause_audio_back_button,
			PAUSE_AUDIO_BACK_PNG,
			PAUSE_AUDIO_SUB_BUTTON_SIZE
		)


func _load_clean_pause_texture(texture_path: String, crop_transparent_margins := true) -> Texture2D:
	if not ResourceLoader.exists(texture_path):
		return null

	if menu_optimizer and menu_optimizer.has_method("load_clean_ui_texture"):
		var optimized: Texture2D = menu_optimizer.load_clean_ui_texture(
			texture_path,
			crop_transparent_margins,
			5,
			0.40,
			0.16
		)
		if optimized:
			return optimized

	var source := load(texture_path) as Texture2D
	if not source:
		return null

	var image := source.get_image()
	if not image or image.is_empty():
		return source

	image.convert(Image.FORMAT_RGBA8)

	# AI-generated PNGs sometimes contain a baked white / light-gray background.
	# Remove ONLY bright neutral pixels connected to the outside edges, so the
	# actual dark/icy sprite remains intact.
	_remove_outer_light_background(image)

	# Remove a few remaining bright neutral halo pixels next to transparency.
	_remove_light_edge_fringe(image, 5)

	var used_rect := image.get_used_rect()
	if (
		crop_transparent_margins
		and
		used_rect.size.x > 0
		and used_rect.size.y > 0
		and (
			used_rect.position != Vector2i.ZERO
			or used_rect.size != image.get_size()
		)
	):
		image = image.get_region(used_rect)

	return ImageTexture.create_from_image(image)


func _remove_outer_light_background(image: Image) -> void:
	var width := image.get_width()
	var height := image.get_height()
	if width <= 0 or height <= 0:
		return

	var stack: Array[Vector2i] = []

	for x in range(width):
		_try_queue_light_pixel(image, Vector2i(x, 0), stack)
		if height > 1:
			_try_queue_light_pixel(image, Vector2i(x, height - 1), stack)

	for y in range(1, height - 1):
		_try_queue_light_pixel(image, Vector2i(0, y), stack)
		if width > 1:
			_try_queue_light_pixel(image, Vector2i(width - 1, y), stack)

	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1)
	]

	while not stack.is_empty():
		var point: Vector2i = stack.pop_back()

		for direction: Vector2i in directions:
			var next: Vector2i = point + direction
			if (
				next.x < 0
				or next.y < 0
				or next.x >= width
				or next.y >= height
			):
				continue

			_try_queue_light_pixel(image, next, stack)


func _try_queue_light_pixel(
	image: Image,
	point: Vector2i,
	stack: Array[Vector2i]
) -> void:
	var color := image.get_pixelv(point)
	if not _is_pause_background_color(color, 0.68, 0.20):
		return

	# Mark immediately so the same pixel cannot be queued twice.
	image.set_pixelv(point, Color(0.0, 0.0, 0.0, 0.0))
	stack.append(point)


func _remove_light_edge_fringe(image: Image, passes: int) -> void:
	var width := image.get_width()
	var height := image.get_height()
	var directions: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
		Vector2i(1, 1),
		Vector2i(-1, 1),
		Vector2i(1, -1),
		Vector2i(-1, -1)
	]

	for _pass in range(passes):
		var to_clear: Array[Vector2i] = []

		for y in range(height):
			for x in range(width):
				var color := image.get_pixel(x, y)
				if not _is_pause_background_color(color, 0.76, 0.16):
					continue

				var touches_transparency := false
				for direction: Vector2i in directions:
					var next: Vector2i = Vector2i(x, y) + direction
					if (
						next.x < 0
						or next.y < 0
						or next.x >= width
						or next.y >= height
					):
						touches_transparency = true
						break

					if image.get_pixelv(next).a <= 0.02:
						touches_transparency = true
						break

				if touches_transparency:
					to_clear.append(Vector2i(x, y))

		if to_clear.is_empty():
			break

		for point: Vector2i in to_clear:
			image.set_pixelv(point, Color(0.0, 0.0, 0.0, 0.0))


func _is_pause_background_color(
	color: Color,
	min_brightness: float,
	neutral_tolerance: float
) -> bool:
	if color.a <= 0.02:
		return false

	var maximum: float = maxf(color.r, maxf(color.g, color.b))
	var minimum: float = minf(color.r, minf(color.g, color.b))
	var brightness: float = (color.r + color.g + color.b) / 3.0

	return (
		brightness >= min_brightness
		and (maximum - minimum) <= neutral_tolerance
	)


func _setup_pause_audio_menu() -> void:
	var box := pause_menu.get_node_or_null("Box") as VBoxContainer
	if not box:
		return

	pause_audio_button = box.get_node_or_null("AudioButton") as Button
	if not pause_audio_button:
		pause_audio_button = Button.new()
		pause_audio_button.name = "AudioButton"
		pause_audio_button.custom_minimum_size = Vector2(260.0, 40.0)
		pause_audio_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pause_audio_button.process_mode = Node.PROCESS_MODE_ALWAYS
		box.add_child(pause_audio_button)
		if return_button and return_button.get_parent() == box:
			box.move_child(pause_audio_button, return_button.get_index())

	pause_master_volume_button = box.get_node_or_null("MasterVolumeButton") as Button
	if not pause_master_volume_button:
		pause_master_volume_button = Button.new()
		pause_master_volume_button.name = "MasterVolumeButton"
		pause_master_volume_button.custom_minimum_size = Vector2(260.0, 40.0)
		pause_master_volume_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pause_master_volume_button.process_mode = Node.PROCESS_MODE_ALWAYS
		box.add_child(pause_master_volume_button)

	pause_audio_back_button = box.get_node_or_null("AudioBackButton") as Button
	if not pause_audio_back_button:
		pause_audio_back_button = Button.new()
		pause_audio_back_button.name = "AudioBackButton"
		pause_audio_back_button.custom_minimum_size = Vector2(260.0, 40.0)
		pause_audio_back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pause_audio_back_button.process_mode = Node.PROCESS_MODE_ALWAYS
		box.add_child(pause_audio_back_button)

	if not pause_audio_button.pressed.is_connected(_open_pause_audio):
		pause_audio_button.pressed.connect(_open_pause_audio)
	if not pause_master_volume_button.pressed.is_connected(_cycle_pause_master_volume):
		pause_master_volume_button.pressed.connect(_cycle_pause_master_volume)
	if not pause_audio_back_button.pressed.is_connected(_return_to_game):
		pause_audio_back_button.pressed.connect(_return_to_game)

	_show_pause_root()
	_refresh_pause_audio_text()


func _show_pause_root() -> void:
	pause_audio_submenu_open = false
	if pause_title_sprite:
		pause_title_sprite.visible = true
	if pause_audio_button:
		pause_audio_button.visible = true
	if return_button:
		return_button.visible = true
	if main_menu_button:
		main_menu_button.visible = true
	if pause_master_volume_button:
		pause_master_volume_button.visible = false
	if pause_audio_back_button:
		pause_audio_back_button.visible = false
	_refresh_pause_audio_text()


func _open_pause_audio() -> void:
	pause_audio_submenu_open = true
	if pause_title_sprite:
		pause_title_sprite.visible = false
	if pause_audio_button:
		pause_audio_button.visible = false
	if return_button:
		return_button.visible = false
	if main_menu_button:
		main_menu_button.visible = false
	if pause_master_volume_button:
		pause_master_volume_button.visible = true
	if pause_audio_back_button:
		pause_audio_back_button.visible = true
	_refresh_pause_audio_text()


func _refresh_pause_audio_text() -> void:
	# All pause-menu text is painted into PNG sprites now.
	if pause_audio_button:
		pause_audio_button.text = ""
	if pause_master_volume_button:
		pause_master_volume_button.text = ""
	if pause_audio_back_button:
		pause_audio_back_button.text = ""

	_refresh_pause_audio_submenu_sprites()


func _master_audio_bus_index() -> int:
	var index := AudioServer.get_bus_index("Master")
	if index < 0:
		return 0
	return index


func _cycle_pause_master_volume() -> void:
	pause_audio_volume_index += 1
	if pause_audio_volume_index >= AUDIO_VOLUME_STEPS.size():
		pause_audio_volume_index = 0
	_apply_pause_master_volume()
	_save_pause_audio_settings()
	_refresh_pause_audio_text()


func _apply_pause_master_volume() -> void:
	pause_audio_volume_index = clampi(pause_audio_volume_index, 0, AUDIO_VOLUME_STEPS.size() - 1)
	var percent := int(AUDIO_VOLUME_STEPS[pause_audio_volume_index])
	var bus_index := _master_audio_bus_index()
	if percent <= 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(float(percent) / 100.0))


func _find_pause_audio_volume_index(percent: int) -> int:
	for index in range(AUDIO_VOLUME_STEPS.size()):
		if int(AUDIO_VOLUME_STEPS[index]) == percent:
			return index
	return 0


func _load_pause_audio_settings() -> void:
	var config := ConfigFile.new()
	var result := config.load(AUDIO_CONFIG_PATH)
	if result != OK:
		pause_audio_volume_index = 0
		_apply_pause_master_volume()
		_save_pause_audio_settings()
		_refresh_pause_audio_text()
		return
	var saved_percent := int(config.get_value("audio", "master_volume_percent", 100))
	pause_audio_volume_index = _find_pause_audio_volume_index(saved_percent)
	_apply_pause_master_volume()
	_refresh_pause_audio_text()


func _save_pause_audio_settings() -> void:
	var config := ConfigFile.new()
	config.load(AUDIO_CONFIG_PATH)
	var percent := int(AUDIO_VOLUME_STEPS[pause_audio_volume_index])
	config.set_value("audio", "master_volume_percent", percent)
	config.save(AUDIO_CONFIG_PATH)


func _connect_local_player() -> void:
	if player and player.has_signal("life_changed"):
		if player.life_changed.is_connected(_on_player_life_changed):
			player.life_changed.disconnect(_on_player_life_changed)
	if player and player.has_signal("power_changed"):
		if player.power_changed.is_connected(_on_player_power_changed):
			player.power_changed.disconnect(_on_player_power_changed)

	player = get_tree().get_first_node_in_group("LocalPlayer")
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	if player and player.has_signal("life_changed"):
		player.life_changed.connect(_on_player_life_changed)
		_on_player_life_changed(int(player.get("life")), int(player.get("max_life")))
	if player and player.has_signal("power_changed"):
		player.power_changed.connect(_on_player_power_changed)
		var max_power := 100
		if player.has_method("get_max_coin_power"):
			max_power = int(player.call("get_max_coin_power"))
		_on_player_power_changed(int(player.get("coin_power")), max_power)


func _on_player_life_changed(life: int, max_life: int) -> void:
	health_bar.max_value = max_life
	health_bar.value = life
	health_label.text = "Life:"
	health_label.visible = false
	if life > 0:
		death_recorded = false
	elif _is_offline_game():
		_handle_offline_death()


func _on_player_power_changed(power: int, max_power: int) -> void:
	if not power_bar or not power_label:
		return
	power_bar.max_value = max_power
	power_bar.value = power
	power_label.text = "Power:"
	power_label.visible = false
	power_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.32) if power >= max_power else Color.WHITE)


func _layout_status_hud() -> void:
	var online := _is_online_game()
	_show_texture_label(life_text)
	_show_texture_label(power_text)
	_show_texture_label(enemies_text)
	_show_texture_label(lives_text)
	health_label.visible = false
	power_label.visible = false
	_place_control(life_text, 16.0, 4.0, 72.0, 36.0)
	_place_control(health_bar, 16.0, 34.0, 16.0 + HUD_BAR_WIDTH, 34.0 + HUD_BAR_HEIGHT)
	_place_control(power_text, 16.0, 58.0, 96.0, 87.0)
	_place_control(power_bar, 16.0, 88.0, 16.0 + HUD_BAR_WIDTH, 88.0 + HUD_BAR_HEIGHT)

	if online:
		enemy_count_label.visible = false
		lives_label.visible = false
		_set_row_visible(enemy_value_row, false)
		_set_row_visible(lives_value_row, false)
		_set_row_visible(rounds_value_row, true)
		_show_texture_label(rounds_text)
		_show_texture_label(second_player_text)
		_show_texture_label(second_player_status_text)
		_hide_texture_label(enemies_text)
		_hide_texture_label(lives_text)
		round_label.visible = false
		_place_control(rounds_text, 16.0, 116.0, 105.0, 143.0)
		_place_control(rounds_value_row, 110.0, 119.0, 190.0, 145.0)
		_place_control(second_player_text, 16.0, 148.0, 145.0, 174.0)
		_place_control(second_player_status_text, 150.0, 148.0, 190.0, 174.0)
		if second_player_label:
			second_player_label.visible = false
	else:
		enemy_count_label.visible = false
		lives_label.visible = false
		_set_row_visible(enemy_value_row, true)
		_set_row_visible(lives_value_row, true)
		_set_row_visible(rounds_value_row, false)
		_hide_texture_label(rounds_text)
		_hide_texture_label(second_player_text)
		_hide_texture_label(second_player_status_text)
		round_label.visible = false
		if second_player_label:
			second_player_label.visible = false
		_place_control(enemies_text, 16.0, 116.0, 110.0, 145.0)
		_place_control(enemy_value_row, 116.0, 119.0, 190.0, 145.0)
		_hide_texture_label(lives_text)
		_place_control(lives_value_row, 16.0, 158.0, 275.0, 198.0)


func _hide_texture_label(label: TextureRect) -> void:
	if label:
		label.visible = false


func _show_texture_label(label: TextureRect) -> void:
	if label:
		label.visible = true
		label.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		label.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _set_row_visible(row: Control, is_visible: bool) -> void:
	if row:
		row.visible = is_visible


func _set_hud_value(row: HBoxContainer, value: String, online_style := false) -> void:
	if not row:
		return
	if String(row.get_meta("hud_value", "")) == value and bool(row.get_meta("online_style", false)) == online_style:
		return
	row.set_meta("hud_value", value)
	row.set_meta("online_style", online_style)
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()

	var index := 0
	while index < value.length():
		var character := value.substr(index, 1)
		var texture := _hud_value_texture(character, online_style)
		if texture:
			var character_rect := TextureRect.new()
			character_rect.texture = texture
			character_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			character_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			character_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var texture_size := texture.get_size()
			var width := HUD_VALUE_HEIGHT
			if texture_size.y > 0:
				width = max(8.0, HUD_VALUE_HEIGHT * texture_size.x / texture_size.y)
			character_rect.custom_minimum_size = Vector2(width, HUD_VALUE_HEIGHT)
			row.add_child(character_rect)
		index += 1


func _hud_value_texture(character: String, online_style := false) -> Texture2D:
	match character:
		":":
			return load("res://Sprites/Hud/online_colon.png" if online_style else "res://Sprites/Hud/hud_colon.png") as Texture2D
		"/":
			return load("res://Sprites/Hud/online_slash.png" if online_style else "res://Sprites/Hud/hud_slash.png") as Texture2D
		"0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
			return load("res://Sprites/Hud/hud_num_%s.png" % character) as Texture2D
		_:
			return null


func _place_control(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	if not control:
		return
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = left
	control.offset_top = top
	control.offset_right = right
	control.offset_bottom = bottom


func _update_enemy_count() -> int:
	var enemies_left := 0
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy is CanvasItem and not enemy.visible:
			continue
		if enemy.get("dead") == true:
			continue
		enemies_left += 1
	enemy_count_label.text = str(enemies_left)
	enemy_count_label.visible = false
	_set_hud_value(enemy_value_row, ":%d" % enemies_left)
	return enemies_left


func _update_offline_result(delta: float, enemies_left: int) -> void:
	if game_result_shown or not _is_offline_game():
		return

	result_check_delay = max(result_check_delay - delta, 0.0)
	if enemies_left > 0:
		enemies_seen_once = true

	if result_check_delay <= 0.0 and enemies_seen_once and enemies_left <= 0:
		_show_result_popup("You Win", "Main Menu", false, true)


func _is_offline_game() -> bool:
	var settings := get_node_or_null("/root/GameSettings")
	var settings_online: bool = settings != null and settings.get("online_mode") == true
	return not multiplayer.has_multiplayer_peer() and not settings_online


func _is_online_game() -> bool:
	var settings := get_node_or_null("/root/GameSettings")
	return multiplayer.has_multiplayer_peer() or (settings != null and settings.get("online_mode") == true)


func _handle_offline_death() -> void:
	if death_recorded or game_result_shown:
		return

	death_recorded = true
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("consume_offline_try"):
		var tries_left := int(settings.call("consume_offline_try"))
		_update_try_count()
		if tries_left <= 0:
			_show_result_popup("You Lose", "Main Menu", false, true)
		return

	_show_result_popup("You Lose", "Main Menu", false, true)


func _update_try_count() -> void:
	if not lives_label:
		return
	lives_label.visible = false
	var settings := get_node_or_null("/root/GameSettings")
	var tries_left := 5
	var tries_max := 5
	if settings:
		tries_left = int(settings.get("offline_tries_left"))
		tries_max = int(settings.get("offline_tries_max"))
	lives_label.text = "%d/%d" % [tries_left, tries_max]
	_set_lives_hearts(lives_value_row, tries_left, tries_max)


func _set_lives_hearts(
	row: HBoxContainer,
	lives_left: int,
	lives_max: int
) -> void:

	if not row:
		return

	var value := "%d/%d" % [lives_left, lives_max]

	if String(row.get_meta("heart_value", "")) == value:
		return

	row.set_meta("heart_value", value)
	row.set_meta("hud_value", "")

	for child in row.get_children():

		row.remove_child(child)
		child.queue_free()

	var full_texture := _load_runtime_sprite_texture(HUD_HEART_FULL_PNG)
	var broken_texture := _load_runtime_sprite_texture(HUD_HEART_BROKEN_PNG)

	if not full_texture or not broken_texture:

		_set_hud_value(row, ":%s" % value)
		return

	for index in range(lives_max):

		var heart_rect := TextureRect.new()
		heart_rect.texture = (
			full_texture
			if index < lives_left
			else broken_texture
		)
		heart_rect.custom_minimum_size = HUD_HEART_SIZE
		heart_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(heart_rect)


func _number_text_after_colon(value: String) -> String:
	var colon := value.find(":")
	if colon == -1:
		return value
	return value.substr(colon + 1).strip_edges()


func _connect_round_counter() -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if not settings:
		round_label.visible = false
		return

	round_label.visible = false
	if settings.has_signal("online_rounds_changed") and not settings.online_rounds_changed.is_connected(_on_online_rounds_changed):
		settings.online_rounds_changed.connect(_on_online_rounds_changed)
	if settings.has_signal("online_match_finished") and not settings.online_match_finished.is_connected(_on_online_match_finished):
		settings.online_match_finished.connect(_on_online_match_finished)
	_on_online_rounds_changed(int(settings.get("online_rounds_played")), int(settings.get("online_max_rounds")))
	var winner_name := String(settings.get("online_match_winner"))
	if not winner_name.is_empty():
		_on_online_match_finished(winner_name)


func _on_online_rounds_changed(rounds_played: int, max_rounds: int) -> void:
	round_label.text = "Rounds: %d/%d" % [rounds_played, max_rounds]
	round_label.visible = false
	_set_hud_value(rounds_value_row, ":%d/%d" % [rounds_played, max_rounds], true)


func _on_online_match_finished(winner_name: String) -> void:
	if winner_name.is_empty():
		winner_name = "Winner"
	_show_result_popup("%s won!" % winner_name, "Exit Online", true)


func _show_result_popup(result_text: String, button_text: String, pause_game := true, show_restart := false) -> void:
	if game_result_shown:
		return
	game_result_shown = true
	var use_lose_sprite := (
		result_text == "You Lose"
		and button_text == "Main Menu"
		and show_restart
	)
	match_label.text = result_text
	match_restart_button.visible = show_restart
	match_exit_button.text = button_text
	_apply_result_exit_button_style(button_text)
	_set_result_popup_sprite_mode(use_lose_sprite)
	match_popup.visible = true
	if pause_game:
		get_tree().paused = true
	else:
		_stop_local_player_control()


func show_online_disconnect_popup(message: String) -> void:
	force_close_online_on_exit = true
	_show_result_popup(message, "Log Out", true, false)


func _stop_local_player_control() -> void:
	var local_player := get_tree().get_first_node_in_group("LocalPlayer")
	if not local_player:
		local_player = get_tree().get_first_node_in_group("Player")
	if local_player and local_player is Node2D:
		local_player.set_physics_process(false)
		local_player.set_process_input(false)
		local_player.set_process_unhandled_input(false)


func _create_match_popup() -> void:
	match_popup = Panel.new()
	match_popup.visible = false
	match_popup.process_mode = Node.PROCESS_MODE_ALWAYS
	match_popup.anchor_left = 0.5
	match_popup.anchor_top = 0.5
	match_popup.anchor_right = 0.5
	match_popup.anchor_bottom = 0.5
	match_popup.offset_left = -220.0
	match_popup.offset_top = -112.0
	match_popup.offset_right = 220.0
	match_popup.offset_bottom = 112.0
	match_popup.add_theme_stylebox_override("panel", _modal_panel_style())
	add_child(match_popup)

	match_result_sprite = TextureRect.new()
	match_result_sprite.name = "ResultSprite"
	match_result_sprite.visible = false
	match_result_sprite.anchor_left = 0.0
	match_result_sprite.anchor_top = 0.0
	match_result_sprite.anchor_right = 1.0
	match_result_sprite.anchor_bottom = 1.0
	match_result_sprite.texture = _load_clean_pause_texture(RESULT_LOSE_PNG, false)
	match_result_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	match_result_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	match_result_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match_popup.add_child(match_result_sprite)

	match_box = VBoxContainer.new()
	match_box.anchor_left = 0.0
	match_box.anchor_top = 0.0
	match_box.anchor_right = 1.0
	match_box.anchor_bottom = 1.0
	match_box.offset_left = 24.0
	match_box.offset_top = 22.0
	match_box.offset_right = -24.0
	match_box.offset_bottom = -22.0
	match_box.alignment = BoxContainer.ALIGNMENT_CENTER
	match_box.add_theme_constant_override("separation", 18)
	match_popup.add_child(match_box)

	match_label = Label.new()
	match_label.custom_minimum_size = Vector2(360.0, 62.0)
	match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	match_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	match_label.add_theme_font_size_override("font_size", 24)
	match_label.add_theme_color_override("font_color", Color(0.96, 0.99, 1.0, 1.0))
	match_box.add_child(match_label)

	match_restart_button = Button.new()
	match_restart_button.text = "Restart"
	match_restart_button.visible = false
	_apply_result_text_button_style(match_restart_button)
	match_restart_button.pressed.connect(_restart_current_level)
	match_box.add_child(match_restart_button)

	match_exit_button = Button.new()
	match_exit_button.text = "Exit Online"
	_apply_result_exit_button_style(match_exit_button.text)
	match_exit_button.pressed.connect(_exit_online_match)
	match_box.add_child(match_exit_button)


func _apply_result_exit_button_style(button_text: String) -> void:
	if button_text == "Main Menu":
		_apply_pause_button_sprite(
			match_exit_button,
			PAUSE_MAIN_MENU_PNG,
			RESULT_BUTTON_SIZE
		)
	else:
		match_exit_button.text = button_text
		_apply_result_text_button_style(match_exit_button)


func _set_result_popup_sprite_mode(enabled: bool) -> void:
	if enabled:
		match_popup.offset_left = -RESULT_SPRITE_POPUP_SIZE.x * 0.5
		match_popup.offset_top = -RESULT_SPRITE_POPUP_SIZE.y * 0.5
		match_popup.offset_right = RESULT_SPRITE_POPUP_SIZE.x * 0.5
		match_popup.offset_bottom = RESULT_SPRITE_POPUP_SIZE.y * 0.5
		match_popup.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

		if match_result_sprite:
			match_result_sprite.visible = true

		if match_box:
			match_box.visible = false

		_apply_result_sprite_hit_area(
			match_restart_button,
			-133.0,
			-26.0,
			133.0,
			26.0
		)
		_apply_result_sprite_hit_area(
			match_exit_button,
			-133.0,
			51.0,
			133.0,
			103.0
		)
		return

	match_popup.offset_left = -220.0
	match_popup.offset_top = -112.0
	match_popup.offset_right = 220.0
	match_popup.offset_bottom = 112.0
	match_popup.add_theme_stylebox_override("panel", _modal_panel_style())

	if match_result_sprite:
		match_result_sprite.visible = false

	if match_box:
		match_box.visible = true

		_restore_result_box_button(match_restart_button)
		_restore_result_box_button(match_exit_button)


func _restore_result_box_button(button: Button) -> void:
	if not button or not match_box:
		return

	if button.get_parent() != match_box:
		if button.get_parent():
			button.get_parent().remove_child(button)
		match_box.add_child(button)

	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0


func _apply_result_sprite_hit_area(
	button: Button,
	left: float,
	top: float,
	right: float,
	bottom: float
) -> void:
	if not button:
		return

	if button.get_parent() != match_popup:
		if button.get_parent():
			button.get_parent().remove_child(button)
		match_popup.add_child(button)

	button.visible = true
	button.text = ""
	button.anchor_left = 0.5
	button.anchor_top = 0.5
	button.anchor_right = 0.5
	button.anchor_bottom = 0.5
	button.offset_left = left
	button.offset_top = top
	button.offset_right = right
	button.offset_bottom = bottom
	button.custom_minimum_size = Vector2.ZERO
	button.size_flags_horizontal = Control.SIZE_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _apply_result_text_button_style(button: Button) -> void:
	if not button:
		return

	var texture := _load_clean_pause_texture(PAUSE_RETURN_PNG)
	if texture:
		var style := _pause_texture_style(texture)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		button.add_theme_stylebox_override("disabled", style)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	else:
		button.add_theme_stylebox_override("normal", _modal_button_style(Color(0.11, 0.13, 0.15, 0.96)))
		button.add_theme_stylebox_override("hover", _modal_button_style(Color(0.18, 0.21, 0.24, 1.0)))
		button.add_theme_stylebox_override("pressed", _modal_button_style(Color(0.07, 0.08, 0.095, 1.0)))

	button.custom_minimum_size = RESULT_BUTTON_SIZE
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.78, 1.0, 0.94, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.70, 0.92, 1.0, 1.0))
	button.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)


func _create_second_player_label() -> void:
	second_player_label = Label.new()
	second_player_label.name = "SecondPlayerStatusLabel"
	second_player_label.visible = false
	second_player_label.offset_left = round_label.offset_left
	second_player_label.offset_top = round_label.offset_top + 28.0
	second_player_label.offset_right = max(round_label.offset_right, round_label.offset_left + 220.0)
	second_player_label.offset_bottom = second_player_label.offset_top + 24.0
	second_player_label.text = "Second Player: Off"
	add_child(second_player_label)


func _create_hud_value_rows() -> void:
	enemy_value_row = HBoxContainer.new()
	enemy_value_row.name = "EnemyValueSprites"
	enemy_value_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_value_row.add_theme_constant_override("separation", 0)
	add_child(enemy_value_row)

	lives_value_row = HBoxContainer.new()
	lives_value_row.name = "LivesValueSprites"
	lives_value_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lives_value_row.add_theme_constant_override("separation", 2)
	add_child(lives_value_row)


func _create_online_hud_sprites() -> void:
	rounds_text = _new_hud_texture("RoundsText", "res://Sprites/Hud/online_rounds_label.png")
	add_child(rounds_text)

	rounds_value_row = HBoxContainer.new()
	rounds_value_row.name = "RoundsValueSprites"
	rounds_value_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rounds_value_row.add_theme_constant_override("separation", 0)
	add_child(rounds_value_row)

	second_player_text = _new_hud_texture("SecondPlayerText", "res://Sprites/Hud/online_second_player_label.png")
	add_child(second_player_text)

	second_player_status_text = _new_hud_texture("SecondPlayerStatusText", "res://Sprites/Hud/online_off_label.png")
	add_child(second_player_status_text)


func _new_hud_texture(node_name: String, texture_path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.name = node_name
	rect.visible = false
	rect.texture = _load_runtime_sprite_texture(texture_path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _setup_runtime_texture_optimizer() -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		if not settings.has_meta(MENU_TEXTURE_CACHE_META):
			settings.set_meta(MENU_TEXTURE_CACHE_META, {})

		var cached_value = settings.get_meta(MENU_TEXTURE_CACHE_META)
		if cached_value is Dictionary:
			menu_texture_cache = cached_value
		else:
			menu_texture_cache = {}
			settings.set_meta(MENU_TEXTURE_CACHE_META, menu_texture_cache)

	if ClassDB.class_exists("MenuOptimizer"):
		menu_optimizer = MenuOptimizer.new()
		menu_optimizer.set_texture_cache(menu_texture_cache)


func _load_runtime_sprite_texture(texture_path: String) -> Texture2D:
	if not ResourceLoader.exists(texture_path):
		return null

	if menu_optimizer and menu_optimizer.has_method("load_runtime_texture"):
		var optimized: Texture2D = menu_optimizer.load_runtime_texture(texture_path)
		if optimized:
			return optimized

	return load(texture_path) as Texture2D


func _create_chat_ui() -> void:
	chat_button = Button.new()
	chat_button.name = "ChatButton"
	chat_button.text = ""
	chat_button.tooltip_text = "Chat"
	chat_button.focus_mode = Control.FOCUS_NONE
	chat_button.z_index = 100
	chat_button.anchor_left = 1.0
	chat_button.anchor_top = 0.0
	chat_button.anchor_right = 1.0
	chat_button.anchor_bottom = 0.0
	chat_button.offset_left = -76.0
	chat_button.offset_top = 8.0
	chat_button.offset_right = -22.0
	chat_button.offset_bottom = 58.0
	chat_button.icon = load("res://Sprites/Hud/notification_chat_empty.png") as Texture2D
	chat_button.expand_icon = true
	chat_button.add_theme_stylebox_override("normal", _transparent_style())
	chat_button.add_theme_stylebox_override("hover", _transparent_style())
	chat_button.add_theme_stylebox_override("pressed", _transparent_style())
	chat_button.pressed.connect(_toggle_chat_panel)
	add_child(chat_button)

	chat_badge = Label.new()
	chat_badge.name = "ChatBadge"
	chat_badge.text = "!"
	chat_badge.visible = false
	chat_badge.z_index = 101
	chat_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chat_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chat_badge.anchor_left = 1.0
	chat_badge.anchor_top = 0.0
	chat_badge.anchor_right = 1.0
	chat_badge.anchor_bottom = 0.0
	chat_badge.offset_left = -52.0
	chat_badge.offset_top = 2.0
	chat_badge.offset_right = -28.0
	chat_badge.offset_bottom = 26.0
	chat_badge.add_theme_font_size_override("font_size", 18)
	chat_badge.add_theme_color_override("font_color", Color(1.0, 0.95, 0.18, 1.0))
	chat_badge.add_theme_stylebox_override("normal", _circle_button_style(Color(0.06, 0.06, 0.05, 0.96), Color(1.0, 0.95, 0.18, 1.0)))
	add_child(chat_badge)

	chat_panel = Panel.new()
	chat_panel.name = "ChatPanel"
	chat_panel.visible = false
	chat_panel.z_index = 102
	chat_panel.anchor_left = 1.0
	chat_panel.anchor_top = 0.0
	chat_panel.anchor_right = 1.0
	chat_panel.anchor_bottom = 0.0
	chat_panel.offset_left = -356.0
	chat_panel.offset_top = 62.0
	chat_panel.offset_right = -20.0
	chat_panel.offset_bottom = 301.0
	chat_panel.add_theme_stylebox_override("panel", _transparent_style())
	add_child(chat_panel)

	var chat_panel_texture := TextureRect.new()
	chat_panel_texture.name = "OnlineChatPanelTexture"
	chat_panel_texture.anchor_right = 1.0
	chat_panel_texture.anchor_bottom = 1.0
	chat_panel_texture.texture = load("res://Sprites/Hud/online2_chat_panel.png") as Texture2D
	chat_panel_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chat_panel_texture.stretch_mode = TextureRect.STRETCH_SCALE
	chat_panel_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_panel.add_child(chat_panel_texture)

	var box := VBoxContainer.new()
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 26.0
	box.offset_top = 54.0
	box.offset_right = -25.0
	box.offset_bottom = -22.0
	box.add_theme_constant_override("separation", 4)
	chat_panel.add_child(box)

	var close_button := Button.new()
	close_button.name = "OnlineChatCloseButton"
	close_button.text = ""
	close_button.anchor_left = 1.0
	close_button.anchor_top = 0.0
	close_button.anchor_right = 1.0
	close_button.anchor_bottom = 0.0
	close_button.offset_left = -42.0
	close_button.offset_top = 8.0
	close_button.offset_right = -6.0
	close_button.offset_bottom = 44.0
	close_button.add_theme_stylebox_override("normal", _transparent_style())
	close_button.add_theme_stylebox_override("hover", _transparent_style())
	close_button.add_theme_stylebox_override("pressed", _transparent_style())
	close_button.pressed.connect(func(): chat_panel.visible = false)
	chat_panel.add_child(close_button)

	chat_messages = RichTextLabel.new()
	chat_messages.bbcode_enabled = true
	chat_messages.scroll_following = true
	chat_messages.fit_content = false
	chat_messages.visible = false
	chat_messages.custom_minimum_size = Vector2.ZERO
	chat_messages.add_theme_stylebox_override("normal", _transparent_style())

	var message_scroll := ScrollContainer.new()
	message_scroll.name = "ChatSpriteScroll"
	message_scroll.custom_minimum_size = Vector2(0, 132)
	message_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_scroll.clip_contents = true
	message_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(message_scroll)

	chat_sprite_messages = VBoxContainer.new()
	chat_sprite_messages.name = "ChatSpriteMessages"
	chat_sprite_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_sprite_messages.add_theme_constant_override("separation", 1)
	message_scroll.add_child(chat_sprite_messages)

	var input_row := HBoxContainer.new()
	box.add_child(input_row)

	var input_stack := Control.new()
	input_stack.custom_minimum_size = Vector2(0, 36)
	input_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input_stack.clip_contents = true
	input_row.add_child(input_stack)

	chat_placeholder_text = TextureRect.new()
	chat_placeholder_text.name = "ChatPlaceholderText"
	chat_placeholder_text.anchor_right = 1.0
	chat_placeholder_text.anchor_bottom = 1.0
	chat_placeholder_text.offset_left = 4.0
	chat_placeholder_text.offset_top = 4.0
	chat_placeholder_text.offset_right = 132.0
	chat_placeholder_text.offset_bottom = 24.0
	chat_placeholder_text.texture = load("res://Sprites/Hud/online2_write_message_label_input.png") as Texture2D
	chat_placeholder_text.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chat_placeholder_text.stretch_mode = TextureRect.STRETCH_KEEP
	chat_placeholder_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_stack.add_child(chat_placeholder_text)

	chat_input_sprite_row = HBoxContainer.new()
	chat_input_sprite_row.name = "ChatInputSpriteText"
	chat_input_sprite_row.anchor_right = 1.0
	chat_input_sprite_row.anchor_bottom = 1.0
	chat_input_sprite_row.offset_left = 8.0
	chat_input_sprite_row.offset_top = 1.0
	chat_input_sprite_row.offset_right = -10.0
	chat_input_sprite_row.offset_bottom = -2.0
	chat_input_sprite_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chat_input_sprite_row.add_theme_constant_override("separation", -3)
	input_stack.add_child(chat_input_sprite_row)

	chat_input = LineEdit.new()
	chat_input.anchor_right = 1.0
	chat_input.anchor_bottom = 1.0
	chat_input.placeholder_text = ""
	chat_input.max_length = 120
	chat_input.add_theme_stylebox_override("normal", _transparent_style())
	chat_input.add_theme_stylebox_override("focus", _transparent_style())
	chat_input.add_theme_font_size_override("font_size", 16)
	chat_input.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.0))
	chat_input.add_theme_color_override("font_placeholder_color", Color(1.0, 1.0, 1.0, 0.0))
	chat_input.add_theme_color_override("caret_color", Color(1.0, 1.0, 1.0, 0.0))
	chat_input.text_changed.connect(_update_chat_input_sprites)
	chat_input.focus_entered.connect(_on_chat_input_focus_changed)
	chat_input.focus_exited.connect(_on_chat_input_focus_changed)
	chat_input.text_submitted.connect(func(_text: String): _send_chat_message())
	input_stack.add_child(chat_input)
	_attach_chat_input_caret()

	chat_send_button = Button.new()
	chat_send_button.text = ""
	chat_send_button.custom_minimum_size = Vector2(76.0, 36.0)
	chat_send_button.add_theme_stylebox_override("normal", _transparent_style())
	chat_send_button.add_theme_stylebox_override("hover", _transparent_style())
	chat_send_button.add_theme_stylebox_override("pressed", _transparent_style())
	chat_send_button.pressed.connect(_send_chat_message)
	input_row.add_child(chat_send_button)

	_update_chat_visibility()


func _circle_button_style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	return style


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.025, 0.03, 0.94)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.34, 0.39, 0.43, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style


func _transparent_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()


func _modal_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.032, 0.038, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.32, 0.38, 0.42, 0.95)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	return style


func _modal_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.42, 0.48, 0.52, 0.9)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	return style


func _update_chat_visibility() -> void:
	if not chat_button:
		return
	var online := multiplayer.has_multiplayer_peer()
	chat_button.visible = online
	if chat_badge:
		chat_badge.visible = false
	if chat_panel:
		chat_panel.visible = chat_panel.visible and online


func _toggle_chat_panel() -> void:
	if not chat_panel:
		return
	chat_panel.visible = not chat_panel.visible
	if chat_panel.visible and chat_input:
		if chat_badge:
			chat_badge.visible = false
		_set_chat_notification(false)
		chat_caret_time = 0.0
		_update_chat_input_sprites(chat_input.text)


func _send_chat_message() -> void:
	if not chat_input:
		return
	var message := chat_input.text.strip_edges()
	if message.is_empty():
		return
	var online_manager := get_tree().get_first_node_in_group("OnlineManager")
	if online_manager and online_manager.has_method("send_chat_message"):
		online_manager.call("send_chat_message", message)
	chat_input.clear()
	_update_chat_input_sprites("")


func add_chat_message(author: String, message: String, notify := false) -> void:
	if not chat_sprite_messages:
		return
	var player_tag := "P2" if notify else "P1"
	_add_sprite_chat_line("%s: %s" % [player_tag, message], notify)
	if notify and chat_panel and not chat_panel.visible:
		_set_chat_notification(true)


func _update_chat_input_sprites(value: String) -> void:
	if not chat_input_sprite_row:
		return
	var input_active := _is_chat_input_active()
	if chat_placeholder_text:
		chat_placeholder_text.visible = value.is_empty() and not input_active
	chat_input_sprite_row.offset_top = 1.0 if value.is_empty() else -9.0
	_set_sprite_text(chat_input_sprite_row, _chat_input_visible_text(value), 13.0)
	if value.is_empty() and not input_active:
		var spacer := Control.new()
		spacer.name = "PlaceholderCaretSpacer"
		spacer.custom_minimum_size = Vector2(92.0, 13.0)
		chat_input_sprite_row.add_child(spacer)
	_attach_chat_input_caret()


func _attach_chat_input_caret() -> void:
	if not chat_input_sprite_row:
		return
	if not chat_input_caret:
		chat_input_caret = TextureRect.new()
		chat_input_caret.name = "InputCaret"
		chat_input_caret.texture = load("res://Sprites/Hud/hud_line.png") as Texture2D
		chat_input_caret.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		chat_input_caret.stretch_mode = TextureRect.STRETCH_SCALE
		chat_input_caret.custom_minimum_size = Vector2(4.0, 12.0)
		chat_input_caret.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chat_input_caret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var current_parent := chat_input_caret.get_parent()
	if current_parent:
		current_parent.remove_child(chat_input_caret)
	chat_input_sprite_row.add_child(chat_input_caret)


func _update_chat_input_caret(delta: float) -> void:
	if not chat_input_caret:
		return
	chat_caret_time += delta
	chat_input_caret.visible = _is_chat_input_active() and fposmod(chat_caret_time, 1.0) < 0.65


func _on_chat_input_focus_changed() -> void:
	chat_caret_time = 0.0
	if chat_input:
		_update_chat_input_sprites(chat_input.text)
	if chat_input_caret:
		chat_input_caret.visible = _is_chat_input_active()


func _is_chat_input_active() -> bool:
	return chat_panel != null and chat_panel.visible and chat_input != null and chat_input.has_focus()


func _set_chat_notification(has_unread: bool) -> void:
	if not chat_button:
		return
	chat_button.icon = load("res://Sprites/Hud/notification_chat_exclamation.png" if has_unread else "res://Sprites/Hud/notification_chat_empty.png") as Texture2D


func _chat_input_visible_text(value: String) -> String:
	var max_chars := 24
	if value.length() <= max_chars:
		return value
	return value.substr(value.length() - max_chars, max_chars)


func _add_sprite_chat_line(text: String, is_second_player: bool) -> void:
	var message_block := VBoxContainer.new()
	message_block.name = "ChatMessageBlock"
	message_block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_block.add_theme_constant_override("separation", 0)
	chat_sprite_messages.add_child(message_block)

	var lines := _wrap_sprite_text(text, CHAT_MESSAGE_TEXT_HEIGHT, CHAT_MESSAGE_FIRST_LINE_WIDTH, CHAT_MESSAGE_NEXT_LINE_WIDTH)
	for line_index in range(lines.size()):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", -2)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		message_block.add_child(row)

		if line_index == 0:
			var icon := TextureRect.new()
			icon.name = "PlayerIcon"
			icon.texture = load("res://Sprites/Hud/online_player_two_icon.png" if is_second_player else "res://Sprites/Hud/online_player_one_icon.png") as Texture2D
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(18, 18)
			row.add_child(icon)
		else:
			var indent := Control.new()
			indent.name = "PlayerIcon"
			indent.custom_minimum_size = Vector2(20.0, CHAT_MESSAGE_TEXT_HEIGHT)
			row.add_child(indent)

		_set_sprite_text(row, lines[line_index], CHAT_MESSAGE_TEXT_HEIGHT)

	while chat_sprite_messages.get_child_count() > 5:
		var old_message := chat_sprite_messages.get_child(0)
		chat_sprite_messages.remove_child(old_message)
		old_message.queue_free()


func _wrap_sprite_text(text: String, height: float, first_line_width: float, next_line_width: float) -> PackedStringArray:
	var lines := PackedStringArray()
	var current_line := ""
	var max_width := first_line_width
	var words := text.split(" ", false)
	for word in words:
		var candidate := word if current_line.is_empty() else "%s %s" % [current_line, word]
		if _sprite_text_width(candidate, height) <= max_width:
			current_line = candidate
			continue

		if not current_line.is_empty():
			lines.append(current_line)
			current_line = ""
			max_width = next_line_width

		var word_lines := _wrap_sprite_word(word, height, max_width, next_line_width)
		for index in range(word_lines.size()):
			if index < word_lines.size() - 1:
				lines.append(word_lines[index])
				max_width = next_line_width
			else:
				current_line = word_lines[index]

	if not current_line.is_empty() or lines.is_empty():
		lines.append(current_line)
	return lines


func _wrap_sprite_word(word: String, height: float, first_line_width: float, next_line_width: float) -> PackedStringArray:
	var lines := PackedStringArray()
	var current_line := ""
	var max_width := first_line_width
	for index in range(word.length()):
		var character := word.substr(index, 1)
		var candidate := current_line + character
		if not current_line.is_empty() and _sprite_text_width(candidate, height) > max_width:
			lines.append(current_line)
			current_line = character
			max_width = next_line_width
		else:
			current_line = candidate
	if not current_line.is_empty():
		lines.append(current_line)
	return lines


func _sprite_text_width(text: String, height: float) -> float:
	var width := 0.0
	for index in range(text.length()):
		width += _sprite_character_width(text.unicode_at(index), height)
		if index > 0:
			width -= 2.0
	return width


func _sprite_character_width(code: int, height: float) -> float:
	if code == 32:
		return height * 0.45
	var texture := _alphabet_texture(code)
	if not texture:
		return 0.0
	var texture_size := texture.get_size()
	if texture_size.y <= 0:
		return height
	return max(5.0, height * texture_size.x / texture_size.y)


func _set_sprite_text(row: HBoxContainer, text: String, height: float) -> void:
	for child in row.get_children():
		if child.name == "PlayerIcon":
			continue
		row.remove_child(child)
		child.queue_free()

	for index in range(text.length()):
		var code := text.unicode_at(index)
		if code == 32:
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(height * 0.45, height)
			row.add_child(spacer)
			continue
		var texture := _alphabet_texture(code)
		if not texture:
			continue
		var char_rect := TextureRect.new()
		char_rect.texture = texture
		char_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		char_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		char_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var texture_size := texture.get_size()
		var width := height
		if texture_size.y > 0:
			width = max(5.0, height * texture_size.x / texture_size.y)
		char_rect.custom_minimum_size = Vector2(width, height)
		row.add_child(char_rect)


func _alphabet_texture(code: int) -> Texture2D:
	var path := "res://Sprites/Hud/Alphabet/u%04X.png" % code
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _update_second_player_status() -> void:
	if not second_player_label:
		return
	second_player_label.visible = false
	var online := multiplayer.has_multiplayer_peer()
	_show_texture_label(second_player_status_text)
	if not online:
		_hide_texture_label(second_player_status_text)
		return
	var connected := _is_second_player_connected()
	second_player_label.text = "Second Player: %s" % ("On" if connected else "Off")
	if second_player_status_text:
		second_player_status_text.texture = load("res://Sprites/Hud/online_on_label.png" if connected else "res://Sprites/Hud/online_off_label.png") as Texture2D


func _is_second_player_connected() -> bool:
	var online_manager := get_tree().get_first_node_in_group("OnlineManager")
	if online_manager and online_manager.has_method("is_second_player_connected"):
		return bool(online_manager.call("is_second_player_connected"))
	if not multiplayer.has_multiplayer_peer():
		return false
	if multiplayer.is_server():
		return multiplayer.get_peers().size() > 0
	return true


func _restart_current_level() -> void:
	get_tree().paused = false
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("start_offline_level"):
		var level := String(settings.get("offline_tries_level"))
		if level.is_empty():
			level = String(settings.get("selected_level"))
		settings.call("start_offline_level", level)
	get_tree().reload_current_scene()


func _open_pause_menu() -> void:
	if online_status_label:
		online_status_label.visible = false
		online_status_label.text = ""
	_show_pause_root()
	pause_menu.visible = true
	get_tree().paused = true


func _online_status_text() -> String:
	var online_manager := get_tree().get_first_node_in_group("OnlineManager")
	if not multiplayer.has_multiplayer_peer():
		return "Online: offline\nSecond player: not connected"
	if multiplayer.is_server():
		var connected := false
		if online_manager and online_manager.has_method("is_second_player_connected"):
			connected = bool(online_manager.call("is_second_player_connected"))
		else:
			connected = multiplayer.get_peers().size() > 0
		return "Online: hosting\nSecond player: %s" % ("connected" if connected else "not connected")
	return "Online: connected\nHost: connected"


func _return_to_game() -> void:
	_show_pause_root()
	pause_menu.visible = false
	get_tree().paused = false


func _go_to_main_menu() -> void:
	_exit_online_match()


func _exit_online_match() -> void:
	get_tree().paused = false
	var settings := get_node_or_null("/root/GameSettings")
	var match_is_finished: bool = force_close_online_on_exit or (settings != null and settings.has_method("is_online_match_over") and settings.is_online_match_over())
	var online_manager := get_tree().get_first_node_in_group("OnlineManager")
	if online_manager and online_manager.has_method("close_online_session"):
		online_manager.close_online_session(match_is_finished)
		return
	var steam_manager := get_node_or_null("/root/SteamManager")
	if steam_manager and steam_manager.has_method("reset_session"):
		steam_manager.reset_session()
	var peer := multiplayer.multiplayer_peer
	if peer and peer.has_method("close"):
		peer.close()
	multiplayer.multiplayer_peer = null

	if settings:
		settings.call("reset_online")

	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
