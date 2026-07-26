extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
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


func _ready() -> void:
	menu_button.pressed.connect(_open_pause_menu)
	return_button.pressed.connect(_return_to_game)
	main_menu_button.pressed.connect(_go_to_main_menu)
	pause_menu.visible = false
	_create_match_popup()
	_connect_round_counter()
	_connect_local_player()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if pause_menu.visible:
			_return_to_game()
		else:
			_open_pause_menu()

	var local_player := get_tree().get_first_node_in_group("LocalPlayer")
	if local_player and local_player != player:
		_connect_local_player()


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
	match_label.text = "%s won!" % winner_name
	match_popup.visible = true
	get_tree().paused = true


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


