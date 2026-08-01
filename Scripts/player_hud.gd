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

var player: Node
var match_popup: Panel
var match_label: Label
var match_exit_button: Button
var enemies_seen_once := false
var game_result_shown := false
var result_check_delay := 0.35
var death_recorded := false


func _ready() -> void:
	_normalize_pause_menu_layout()
	menu_button.pressed.connect(_open_pause_menu)
	return_button.pressed.connect(_return_to_game)
	main_menu_button.pressed.connect(_go_to_main_menu)
	pause_menu.visible = false
	_create_match_popup()
	_connect_round_counter()
	_connect_local_player()
	_update_enemy_count()
	_update_try_count()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if pause_menu.visible:
			_return_to_game()
		else:
			_open_pause_menu()

	var local_player := get_tree().get_first_node_in_group("LocalPlayer")
	if local_player and local_player != player:
		_connect_local_player()
	var enemies_left := _update_enemy_count()
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
		_show_result_popup("You Win", "Main Menu", false)


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
			_show_result_popup("You Lose", "Main Menu", false)
		return

	_show_result_popup("You Lose", "Main Menu", false)


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
	round_label.text = "%d/%d" % [rounds_played, max_rounds]


func _on_online_match_finished(winner_name: String) -> void:
	if winner_name.is_empty():
		winner_name = "Winner"
	_show_result_popup("%s won!" % winner_name, "Exit Online", true)


func _show_result_popup(result_text: String, button_text: String, pause_game := true) -> void:
	if game_result_shown:
		return
	game_result_shown = true
	match_label.text = result_text
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
	match_popup.offset_top = -70.0
	match_popup.offset_right = 170.0
	match_popup.offset_bottom = 70.0
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

	match_exit_button = Button.new()
	match_exit_button.text = "Exit Online"
	match_exit_button.pressed.connect(_exit_online_match)
	box.add_child(match_exit_button)


func _open_pause_menu() -> void:
	online_status_label.text = "Online: connected" if multiplayer.has_multiplayer_peer() else "Online: offline"
	pause_menu.visible = true
	get_tree().paused = true


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
