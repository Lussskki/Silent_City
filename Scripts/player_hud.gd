extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var enemy_count_label: Label = $EnemyCountLabel
@onready var lives_label: Label = $LivesLabel
@onready var round_label: Label = $RoundLabel
@onready var menu_button: Button = $MenuButton
@onready var pause_menu: Panel = $PauseMenu
@onready var online_status_label: Label = $PauseMenu/Box/OnlineStatusLabel
@onready var return_button: Button = $PauseMenu/Box/ReturnButton
@onready var main_menu_button: Button = $PauseMenu/Box/MainMenuButton

var chat_button: Button
var chat_badge: Label
var chat_panel: Panel
var chat_messages: RichTextLabel
var chat_input: LineEdit
var chat_send_button: Button
var player: Node
var match_popup: Panel
var match_label: Label
var match_restart_button: Button
var match_exit_button: Button
var second_player_label: Label
var enemies_seen_once := false
var game_result_shown := false
var result_check_delay := 0.35
var death_recorded := false


func _ready() -> void:
	add_to_group("PlayerHUD")
	_normalize_pause_menu_layout()
	menu_button.pressed.connect(_open_pause_menu)
	return_button.pressed.connect(_return_to_game)
	main_menu_button.pressed.connect(_go_to_main_menu)
	pause_menu.visible = false
	_create_chat_ui()
	_create_match_popup()
	_create_second_player_label()
	_connect_round_counter()
	_connect_local_player()
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
	var enemies_left := _update_enemy_count()
	_update_second_player_status()
	_update_offline_result(delta, enemies_left)


func _normalize_pause_menu_layout() -> void:
	layer = 100
	menu_button.z_index = 100
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
	pause_menu.offset_left = -170.0
	pause_menu.offset_top = -105.0
	pause_menu.offset_right = 170.0
	pause_menu.offset_bottom = 105.0

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.025, 0.03, 0.98)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.34, 0.39, 0.43, 1.0)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.corner_radius_bottom_left = 4
	pause_menu.add_theme_stylebox_override("panel", panel_style)

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
	box.add_theme_constant_override("separation", 12)


func _connect_local_player() -> void:
	if player and player.has_signal("life_changed"):
		if player.life_changed.is_connected(_on_player_life_changed):
			player.life_changed.disconnect(_on_player_life_changed)

	player = get_tree().get_first_node_in_group("LocalPlayer")
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	if player and player.has_signal("life_changed"):
		player.life_changed.connect(_on_player_life_changed)
		_on_player_life_changed(int(player.get("life")), int(player.get("max_life")))


func _on_player_life_changed(life: int, max_life: int) -> void:
	health_bar.max_value = max_life
	health_bar.value = life
	health_label.text = "Life: %d" % life
	if life > 0:
		death_recorded = false
	elif _is_offline_game():
		_handle_offline_death()


func _update_enemy_count() -> int:
	var enemies_left := 0
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy is CanvasItem and not enemy.visible:
			continue
		if enemy.get("dead") == true:
			continue
		enemies_left += 1
	enemy_count_label.text = "Enemies: %d" % enemies_left
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
	lives_label.visible = _is_offline_game()
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("offline_tries_text"):
		lives_label.text = String(settings.call("offline_tries_text"))
	else:
		lives_label.text = "Lives: 0/5"


func _connect_round_counter() -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if not settings:
		round_label.visible = false
		return

	round_label.visible = multiplayer.has_multiplayer_peer()
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


func _on_online_match_finished(winner_name: String) -> void:
	if winner_name.is_empty():
		winner_name = "Winner"
	_show_result_popup("%s won!" % winner_name, "Exit Online", true)


func _show_result_popup(result_text: String, button_text: String, pause_game := true, show_restart := false) -> void:
	if game_result_shown:
		return
	game_result_shown = true
	match_label.text = result_text
	match_restart_button.visible = show_restart
	match_exit_button.text = button_text
	match_popup.visible = true
	if pause_game:
		get_tree().paused = true
	else:
		_stop_local_player_control()


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
	match_popup.offset_left = -170.0
	match_popup.offset_top = -95.0
	match_popup.offset_right = 170.0
	match_popup.offset_bottom = 95.0
	add_child(match_popup)

	var box := VBoxContainer.new()
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 18.0
	box.offset_top = 16.0
	box.offset_right = -18.0
	box.offset_bottom = -16.0
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	match_popup.add_child(box)

	match_label = Label.new()
	match_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match_label.add_theme_font_size_override("font_size", 28)
	box.add_child(match_label)

	match_restart_button = Button.new()
	match_restart_button.text = "Restart"
	match_restart_button.visible = false
	match_restart_button.pressed.connect(_restart_current_level)
	box.add_child(match_restart_button)

	match_exit_button = Button.new()
	match_exit_button.text = "Exit Online"
	match_exit_button.pressed.connect(_exit_online_match)
	box.add_child(match_exit_button)


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


func _create_chat_ui() -> void:
	chat_button = Button.new()
	chat_button.name = "ChatButton"
	chat_button.text = "Chat"
	chat_button.tooltip_text = "Chat"
	chat_button.focus_mode = Control.FOCUS_NONE
	chat_button.z_index = 100
	chat_button.anchor_left = 1.0
	chat_button.anchor_top = 0.0
	chat_button.anchor_right = 1.0
	chat_button.anchor_bottom = 0.0
	chat_button.offset_left = -104.0
	chat_button.offset_top = 12.0
	chat_button.offset_right = -64.0
	chat_button.offset_bottom = 52.0
	chat_button.add_theme_stylebox_override("normal", _circle_button_style(Color(0.04, 0.065, 0.08, 0.92), Color(0.70, 0.78, 0.84, 0.95)))
	chat_button.add_theme_stylebox_override("hover", _circle_button_style(Color(0.08, 0.14, 0.17, 0.96), Color(0.88, 0.96, 1.0, 1.0)))
	chat_button.add_theme_stylebox_override("pressed", _circle_button_style(Color(0.02, 0.045, 0.06, 1.0), Color(0.95, 1.0, 1.0, 1.0)))
	chat_button.add_theme_font_size_override("font_size", 12)
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
	chat_badge.offset_left = -72.0
	chat_badge.offset_top = 2.0
	chat_badge.offset_right = -48.0
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
	chat_panel.offset_bottom = 300.0
	chat_panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(chat_panel)

	var box := VBoxContainer.new()
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = 12.0
	box.offset_top = 12.0
	box.offset_right = -12.0
	box.offset_bottom = -12.0
	box.add_theme_constant_override("separation", 8)
	chat_panel.add_child(box)

	var title_row := HBoxContainer.new()
	box.add_child(title_row)

	var title := Label.new()
	title.text = "Online Chat"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	title_row.add_child(title)

	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = Vector2(32, 28)
	close_button.pressed.connect(func(): chat_panel.visible = false)
	title_row.add_child(close_button)

	chat_messages = RichTextLabel.new()
	chat_messages.bbcode_enabled = false
	chat_messages.scroll_following = true
	chat_messages.fit_content = false
	chat_messages.custom_minimum_size = Vector2(0, 132)
	chat_messages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(chat_messages)

	var input_row := HBoxContainer.new()
	box.add_child(input_row)

	chat_input = LineEdit.new()
	chat_input.placeholder_text = "Write message..."
	chat_input.max_length = 120
	chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_input.text_submitted.connect(func(_text: String): _send_chat_message())
	input_row.add_child(chat_input)

	chat_send_button = Button.new()
	chat_send_button.text = "Send"
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


func _update_chat_visibility() -> void:
	if not chat_button:
		return
	var online := multiplayer.has_multiplayer_peer()
	chat_button.visible = online
	if chat_badge:
		chat_badge.visible = chat_badge.visible and online
	if chat_panel:
		chat_panel.visible = chat_panel.visible and online


func _toggle_chat_panel() -> void:
	if not chat_panel:
		return
	chat_panel.visible = not chat_panel.visible
	if chat_panel.visible and chat_input:
		if chat_badge:
			chat_badge.visible = false
		chat_input.grab_focus()


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


func add_chat_message(author: String, message: String, notify := false) -> void:
	if not chat_messages:
		return
	chat_messages.append_text("%s: %s\n" % [author, message])
	if notify and chat_badge and chat_panel and not chat_panel.visible:
		chat_badge.visible = true


func _update_second_player_status() -> void:
	if not second_player_label:
		return
	second_player_label.visible = multiplayer.has_multiplayer_peer()
	if not second_player_label.visible:
		return
	second_player_label.text = "Second Player: %s" % ("On" if _is_second_player_connected() else "Off")


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
	online_status_label.text = _online_status_text()
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
	pause_menu.visible = false
	get_tree().paused = false


func _go_to_main_menu() -> void:
	_exit_online_match()


func _exit_online_match() -> void:
	get_tree().paused = false
	var settings := get_node_or_null("/root/GameSettings")
	var match_is_finished: bool = settings != null and settings.has_method("is_online_match_over") and settings.is_online_match_over()
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
