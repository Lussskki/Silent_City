extends Control

const MAIN_SCENE := "res://Scenes/main.tscn"
const MEDIUM_SCENE := "res://Scenes/MainMedium.tscn"
const HARD_SCENE := "res://Scenes/MainHard.tscn"
const ONLINE_PORT := 8910
const ROOM_NAME := "Silent City Room"
const MAX_ROOM_PLAYERS := 2
const LANG_ENG := "eng"
const LANG_GEO := "geo"
const CHARACTER_DISPLAY_NAMES := {
	"player": "Ash Golem",
	"golem": "Stone Golem"
}
const TEXT := {
	LANG_ENG: {
		"language_button": "GEO",
		"subtitle": "Choose your fight",
		"start": "Start",
		"choose_level": "Choose Level",
		"easy": "Easy",
		"medium": "Medium",
		"hard": "Hard",
		"choose_character": "Choose Character",
		"online_room": "Online",
		"exit": "Exit",
		"select": "Select",
		"choose_first": "Choose a character before starting.",
		"start_game": "Start Game",
		"back": "Back",
		"host_room": "Host Online",
		"join": "Join",
		"start_online_room": "Start Online",
		"tutorial_title": "Online Tutorial",
		"skip": "Skip",
		"next": "Next",
		"done": "Done",
		"selected_online": "Selected: %s. Press Start Game to enter online room.",
		"selected": "Selected: %s",
		"host_failed": "Host failed: %s",
		"room_open": "Online room is open. Give your public IP to the other player.",
		"hosting_device": "This device is hosting. Use another device to join by IP.",
		"no_room_selected": "Enter the host IP address to join.",
		"join_failed": "Join failed: %s",
		"joining": "Joining room...",
		"connected_choose": "Connected. Choose your character.",
		"waiting_for_host_start": "Character selected. Waiting for host to start.",
		"waiting_for_player_choice": "Waiting for the other player to choose a character.",
		"player_connected": "Player connected.\nPress Start Online.",
		"room_waiting": "Online room is open. Waiting for player to connect.",
		"connection_failed": "Connection failed",
		"online_status_default": "Host online or enter the host IP to join.",
		"invalid_address": "Enter a valid host IP address.",
		"room_players": "%s - %d/%d players"
	},
	LANG_GEO: {
		"language_button": "ENG",
		"subtitle": "áƒáƒ˜áƒ áƒ©áƒ˜áƒ” áƒ‘áƒ áƒ«áƒáƒšáƒ",
		"start": "áƒ“áƒáƒ¬áƒ§áƒ”áƒ‘áƒ",
		"choose_character": "áƒžáƒ”áƒ áƒ¡áƒáƒœáƒáƒŸáƒ˜",
		"online_room": "Online",
		"exit": "áƒ’áƒáƒ¡áƒ•áƒšáƒ",
		"select": "áƒáƒ áƒ©áƒ”áƒ•áƒ",
		"choose_first": "áƒ¯áƒ”áƒ  áƒáƒ˜áƒ áƒ©áƒ˜áƒ” áƒžáƒ”áƒ áƒ¡áƒáƒœáƒáƒŸáƒ˜.",
		"start_game": "áƒ—áƒáƒ›áƒáƒ¨áƒ˜áƒ¡ áƒ“áƒáƒ¬áƒ§áƒ”áƒ‘áƒ",
		"back": "áƒ£áƒ™áƒáƒœ",
		"host_room": "áƒáƒ—áƒáƒ®áƒ˜áƒ¡ áƒ’áƒáƒ®áƒ¡áƒœáƒ",
		"join": "áƒ¨áƒ”áƒ¡áƒ•áƒšáƒ",
		"start_online_room": "Start Online",
		"tutorial_title": "Online Tutorial",
		"skip": "áƒ’áƒáƒ›áƒáƒ¢áƒáƒ•áƒ”áƒ‘áƒ",
		"next": "áƒ¨áƒ”áƒ›áƒ“áƒ”áƒ’áƒ˜",
		"done": "áƒ›áƒ–áƒáƒ“áƒáƒ",
		"selected_online": "áƒáƒ áƒ©áƒ”áƒ£áƒšáƒ˜áƒ: %s. áƒ“áƒáƒáƒ­áƒ˜áƒ áƒ” áƒ—áƒáƒ›áƒáƒ¨áƒ˜áƒ¡ áƒ“áƒáƒ¬áƒ§áƒ”áƒ‘áƒáƒ¡.",
		"selected": "áƒáƒ áƒ©áƒ”áƒ£áƒšáƒ˜áƒ: %s",
		"host_failed": "áƒáƒ—áƒáƒ®áƒ˜ áƒ•áƒ”áƒ  áƒ’áƒáƒ˜áƒ®áƒ¡áƒœáƒ: %s",
		"room_open": "áƒáƒ—áƒáƒ®áƒ˜ áƒ’áƒáƒ®áƒ¡áƒœáƒ˜áƒšáƒ˜áƒ. áƒ¡áƒ®áƒ•áƒ áƒ›áƒáƒ¬áƒ§áƒáƒ‘áƒ˜áƒšáƒáƒ‘áƒ áƒ¡áƒ˜áƒ˜áƒ“áƒáƒœ áƒáƒ˜áƒ áƒ©áƒ”áƒ•áƒ¡.",
		"hosting_device": "áƒ”áƒ¡ áƒ›áƒáƒ¬áƒ§áƒáƒ‘áƒ˜áƒšáƒáƒ‘áƒ áƒ›áƒáƒ¡áƒžáƒ˜áƒœáƒ«áƒšáƒáƒ‘áƒ¡. áƒ¨áƒ”áƒ¡áƒáƒ¡áƒ•áƒšáƒ”áƒšáƒáƒ“ áƒ’áƒáƒ›áƒáƒ˜áƒ§áƒ”áƒœáƒ” áƒ›áƒ”áƒáƒ áƒ” áƒ›áƒáƒ¬áƒ§áƒáƒ‘áƒ˜áƒšáƒáƒ‘áƒ.",
		"no_room_selected": "áƒáƒ—áƒáƒ®áƒ˜ áƒáƒ áƒ©áƒ”áƒ£áƒšáƒ˜ áƒáƒ  áƒáƒ áƒ˜áƒ¡. áƒ’áƒáƒ®áƒ¡áƒ”áƒœáƒ˜ áƒáƒ—áƒáƒ®áƒ˜ áƒáƒœ áƒ“áƒáƒ”áƒšáƒáƒ“áƒ”.",
		"join_failed": "áƒ¨áƒ”áƒ¡áƒ•áƒšáƒ áƒ•áƒ”áƒ  áƒ›áƒáƒ®áƒ”áƒ áƒ®áƒ“áƒ: %s",
		"joining": "áƒáƒ—áƒáƒ®áƒ¨áƒ˜ áƒ¨áƒ”áƒ¡áƒ•áƒšáƒ...",
		"connected_choose": "áƒ“áƒáƒ™áƒáƒ•áƒ¨áƒ˜áƒ áƒ”áƒ‘áƒ£áƒšáƒ˜áƒ. áƒáƒ˜áƒ áƒ©áƒ˜áƒ” áƒžáƒ”áƒ áƒ¡áƒáƒœáƒáƒŸáƒ˜.",
		"player_connected": "áƒ›áƒáƒ—áƒáƒ›áƒáƒ¨áƒ” áƒ¨áƒ”áƒ›áƒáƒ•áƒ˜áƒ“áƒ.\nPress Start Online.",
		"room_waiting": "áƒáƒ—áƒáƒ®áƒ˜ áƒ’áƒáƒ®áƒ¡áƒœáƒ˜áƒšáƒ˜áƒ. áƒ•áƒ”áƒšáƒáƒ“áƒ”áƒ‘áƒ˜áƒ— áƒ›áƒáƒ—áƒáƒ›áƒáƒ¨áƒ”áƒ”áƒ‘áƒ¡.",
		"connection_failed": "áƒ™áƒáƒ•áƒ¨áƒ˜áƒ áƒ˜ áƒ•áƒ”áƒ  áƒ›áƒáƒ®áƒ”áƒ áƒ®áƒ“áƒ",
		"online_status_default": "Host online or enter the host IP to join.",
		"invalid_address": "Enter a valid host IP address.",
		"room_players": "%s - %d/%d áƒ›áƒáƒ—áƒáƒ›áƒáƒ¨áƒ”"
	}
}
const ONLINE_TUTORIAL_STEPS := {
	LANG_ENG: [
		"Host opens a room.",
		"Join picks the room.",
		"Choose character, then start."
	],
	LANG_GEO: [
		"áƒ›áƒáƒ¡áƒžáƒ˜áƒœáƒ«áƒ”áƒšáƒ˜ áƒ®áƒ¡áƒœáƒ˜áƒ¡ áƒáƒ—áƒáƒ®áƒ¡.",
		"áƒ›áƒ”áƒáƒ áƒ” áƒ›áƒáƒ—áƒáƒ›áƒáƒ¨áƒ” áƒ˜áƒ áƒ©áƒ”áƒ•áƒ¡ áƒáƒ—áƒáƒ®áƒ¡.",
		"áƒáƒ˜áƒ áƒ©áƒ˜áƒ” áƒžáƒ”áƒ áƒ¡áƒáƒœáƒáƒŸáƒ˜ áƒ“áƒ áƒ“áƒáƒ˜áƒ¬áƒ§áƒ”."
	]
}

@onready var pages: Control = $Content/Root/Pages
@onready var language_button: Button = $LanguageButton
@onready var subtitle_label: Label = $Content/Root/Subtitle
@onready var home_page: VBoxContainer = $Content/Root/Pages/Home
@onready var level_page: VBoxContainer = $Content/Root/Pages/ChooseLevel
@onready var choose_page: VBoxContainer = $Content/Root/Pages/ChooseCharacter
@onready var online_page: VBoxContainer = $Content/Root/Pages/Online
@onready var home_start_button: Button = $Content/Root/Pages/Home/StartButton
@onready var home_choose_button: Button = $Content/Root/Pages/Home/ChooseButton
@onready var home_online_button: Button = $Content/Root/Pages/Home/OnlineButton
@onready var home_exit_button: Button = $Content/Root/Pages/Home/ExitButton
@onready var level_header: Label = $Content/Root/Pages/ChooseLevel/Header
@onready var easy_button: Button = $Content/Root/Pages/ChooseLevel/EasyButton
@onready var medium_button: Button = $Content/Root/Pages/ChooseLevel/MediumButton
@onready var hard_button: Button = $Content/Root/Pages/ChooseLevel/HardButton
@onready var level_back_button: Button = $Content/Root/Pages/ChooseLevel/BackButton
@onready var choose_header: Label = $Content/Root/Pages/ChooseCharacter/Header
@onready var player_card: PanelContainer = $Content/Root/Pages/ChooseCharacter/Cards/PlayerCard
@onready var golem_card: PanelContainer = $Content/Root/Pages/ChooseCharacter/Cards/GolemCard
@onready var player_select_button: Button = $Content/Root/Pages/ChooseCharacter/Cards/PlayerCard/Box/SelectButton
@onready var golem_select_button: Button = $Content/Root/Pages/ChooseCharacter/Cards/GolemCard/Box/SelectButton
@onready var character_status: Label = $Content/Root/Pages/ChooseCharacter/StatusLabel
@onready var choose_start_button: Button = $Content/Root/Pages/ChooseCharacter/StartButton
@onready var choose_online_button: Button = $Content/Root/Pages/ChooseCharacter/OnlineButton
@onready var choose_back_button: Button = $Content/Root/Pages/ChooseCharacter/BackButton
@onready var online_tutorial_overlay: Control = $Content/Root/Pages/TutorialOverlay
@onready var online_tutorial_title: Label = $Content/Root/Pages/TutorialOverlay/Card/Box/Title
@onready var online_tutorial_text: Label = $Content/Root/Pages/TutorialOverlay/Card/Box/Text
@onready var online_tutorial_next: Button = $Content/Root/Pages/TutorialOverlay/Card/Box/Buttons/NextButton
@onready var online_tutorial_skip: Button = $Content/Root/Pages/TutorialOverlay/Card/Box/Buttons/SkipButton
@onready var online_tutorial_back: Button = $Content/Root/Pages/TutorialOverlay/Card/Box/Buttons/BackButton
@onready var online_address_input: LineEdit = $Content/Root/Pages/Online/AddressBox/AddressInput
@onready var online_header: Label = $Content/Root/Pages/Online/Header
@onready var online_status: Label = $Content/Root/Pages/Online/StatusLabel
@onready var host_button: Button = $Content/Root/Pages/Online/Buttons/HostButton
@onready var join_button: Button = $Content/Root/Pages/Online/Buttons/JoinButton
@onready var online_start_button: Button = $Content/Root/Pages/Online/StartOnlineButton
@onready var online_back_button: Button = $Content/Root/Pages/Online/BackButton

var hosted_player_count := 1
var hosted_room_id := ""
var joined_room_waiting_for_character := false
var online_tutorial_step := 0
var remote_client_character := "golem"
var remote_client_character_chosen := false
var other_player_character := ""
var other_player_character_chosen := false


func _ready() -> void:
	_setup_language()
	language_button.pressed.connect(_toggle_language)
	home_start_button.pressed.connect(_open_start_flow)
	home_choose_button.pressed.connect(func(): _show_page(choose_page))
	home_online_button.pressed.connect(_open_online_page)
	home_exit_button.pressed.connect(_exit_game)
	easy_button.pressed.connect(func(): _select_level("easy"))
	medium_button.pressed.connect(func(): _select_level("medium"))
	hard_button.pressed.connect(func(): _select_level("hard"))
	level_back_button.pressed.connect(func(): _show_page(home_page))
	player_select_button.pressed.connect(func(): _select_character("player"))
	golem_select_button.pressed.connect(func(): _select_character("golem"))
	_make_character_card_tappable(player_card, "player")
	_make_character_card_tappable(golem_card, "golem")
	player_select_button.visible = true
	golem_select_button.visible = true
	choose_start_button.pressed.connect(_start_game)
	choose_online_button.pressed.connect(_open_online_page)
	choose_back_button.pressed.connect(_back_from_character_page)
	host_button.pressed.connect(_host_online_game)
	join_button.pressed.connect(_join_online_game)
	online_start_button.pressed.connect(_start_online_host_game)
	online_tutorial_next.pressed.connect(_advance_online_tutorial)
	online_tutorial_skip.pressed.connect(_finish_online_tutorial)
	online_tutorial_back.pressed.connect(_back_from_online)
	online_back_button.pressed.connect(_back_from_online)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_apply_language()
	_update_character_cards()
	_update_online_room_text()
	online_start_button.visible = false
	_update_room_buttons()
	_show_page(home_page)


func _process(delta: float) -> void:
	pass


func _setup_language() -> void:
	var settings := _settings()
	if settings and not [LANG_ENG, LANG_GEO].has(String(settings.get("language"))):
		settings.set("language", LANG_ENG)


func _language() -> String:
	var settings := _settings()
	if settings:
		var language := String(settings.get("language"))
		if [LANG_ENG, LANG_GEO].has(language):
			return language
	return LANG_ENG


func _t(key: String) -> String:
	var language := _language()
	var table: Dictionary = TEXT.get(language, TEXT[LANG_ENG])
	return String(table.get(key, TEXT[LANG_ENG].get(key, key)))


func _toggle_language() -> void:
	var settings := _settings()
	if settings:
		var next_language := LANG_GEO
		if _language() == LANG_GEO:
			next_language = LANG_ENG
		settings.set("language", next_language)
	_apply_language()
	_update_character_cards()


func _apply_language() -> void:
	language_button.text = _t("language_button")
	subtitle_label.text = _t("subtitle")
	home_start_button.text = _t("start")
	home_choose_button.text = _t("choose_character")
	home_online_button.text = _t("online_room")
	home_exit_button.text = _t("exit")
	level_header.text = _t("choose_level")
	easy_button.text = _t("easy")
	medium_button.text = _t("medium")
	hard_button.text = _t("hard")
	level_back_button.text = _t("back")
	choose_header.text = _t("choose_character")
	player_select_button.text = _t("select")
	golem_select_button.text = _t("select")
	choose_start_button.text = _t("start_game")
	choose_online_button.text = _t("online_room")
	choose_back_button.text = _t("back")
	online_header.text = _t("online_room")
	host_button.text = _t("host_room")
	join_button.text = _t("join")
	online_start_button.text = _t("start_online_room")
	online_back_button.text = _t("back")
	online_tutorial_title.text = _t("tutorial_title")
	online_tutorial_back.text = _t("back")
	online_tutorial_skip.text = _t("skip")
	_update_online_tutorial()


func _show_page(page: Control) -> void:
	for child in pages.get_children():
		if child is Control:
			child.visible = child == page


func _exit_game() -> void:
	_clear_peer()
	get_tree().quit()


func _open_online_page() -> void:
	_update_online_room_text()
	_show_page(online_page)
	_show_online_tutorial_once()


func _open_start_flow() -> void:
	_show_page(level_page)


func _select_level(level: String) -> void:
	var settings := _settings()
	if settings:
		settings.set("selected_level", level)
		settings.set("level_chosen", true)
	_show_page(choose_page)


func _show_online_tutorial_once() -> void:
	var settings := _settings()
	if settings and settings.get("online_tutorial_seen") == true:
		online_tutorial_overlay.visible = false
		return

	online_tutorial_step = 0
	online_tutorial_overlay.visible = true
	_update_online_tutorial()


func _update_online_tutorial() -> void:
	var steps: Array = ONLINE_TUTORIAL_STEPS.get(_language(), ONLINE_TUTORIAL_STEPS[LANG_ENG])
	online_tutorial_text.text = String(steps[online_tutorial_step])
	online_tutorial_next.text = _t("done") if online_tutorial_step >= steps.size() - 1 else _t("next")


func _advance_online_tutorial() -> void:
	var steps: Array = ONLINE_TUTORIAL_STEPS.get(_language(), ONLINE_TUTORIAL_STEPS[LANG_ENG])
	if online_tutorial_step >= steps.size() - 1:
		_finish_online_tutorial()
		return

	online_tutorial_step += 1
	_update_online_tutorial()


func _finish_online_tutorial() -> void:
	var settings := _settings()
	if settings:
		settings.set("online_tutorial_seen", true)
	online_tutorial_overlay.visible = false


func _back_from_character_page() -> void:
	if joined_room_waiting_for_character:
		var settings := _settings()
		if settings:
			settings.call("reset_online")
			settings.set("character_chosen", false)
		_clear_peer()
		joined_room_waiting_for_character = false
		other_player_character = ""
		other_player_character_chosen = false
		_show_page(home_page)
		return

	_show_page(home_page)


func _select_character(character: String) -> void:
	if _is_online_character_locked():
		return
	if _is_character_taken_by_other_player(character):
		return

	var settings := _settings()
	if settings:
		settings.set("selected_character", character)
		settings.set("character_chosen", true)
	var character_name := String(CHARACTER_DISPLAY_NAMES.get(character, "Ash Golem"))
	if joined_room_waiting_for_character:
		_lock_online_character_selection()
		if _is_joining_room():
			rpc_id(1, "_client_online_character_selected", character)
			character_status.text = _t("waiting_for_host_start")
			online_status.text = _t("waiting_for_host_start")
		else:
			character_status.text = _t("selected_online") % character_name
			online_status.text = _t("selected_online") % character_name
			_sync_online_character_state()
	else:
		character_status.text = _t("selected") % character_name
	_update_character_cards()
	_update_room_buttons()


func _make_character_card_tappable(card: Control, character: String) -> void:
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(func(event: InputEvent): _select_character_from_card_input(event, character))
	for child in card.find_children("*", "Control"):
		var control := child as Control
		control.mouse_filter = Control.MOUSE_FILTER_PASS
		control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _select_character_from_card_input(event: InputEvent, character: String) -> void:
	if _is_online_character_locked():
		return
	if _is_character_taken_by_other_player(character):
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_select_character(character)
			accept_event()
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_select_character(character)
			accept_event()


func _update_character_cards() -> void:
	player_card.modulate = Color(1.0, 1.0, 1.0)
	golem_card.modulate = Color(1.0, 1.0, 1.0)
	_set_card_crossed(player_card, false)
	_set_card_crossed(golem_card, false)
	_set_character_card_available(player_card, true)
	_set_character_card_available(golem_card, true)
	if joined_room_waiting_for_character and other_player_character_chosen:
		if other_player_character == "golem":
			golem_card.modulate = Color(0.45, 0.45, 0.45)
			_set_card_crossed(golem_card, true)
			_set_character_card_available(golem_card, false)
		else:
			player_card.modulate = Color(0.45, 0.45, 0.45)
			_set_card_crossed(player_card, true)
			_set_character_card_available(player_card, false)
	var settings := _settings()
	if not settings or settings.get("character_chosen") != true:
		character_status.text = _t("choose_first")
		_set_character_buttons_enabled(true)
		_apply_taken_character_input_state()
		return
	if String(settings.get("selected_character")) == "golem":
		golem_card.modulate = Color(0.65, 1.0, 0.65)
		_set_card_crossed(golem_card, true)
	else:
		player_card.modulate = Color(0.65, 1.0, 0.65)
		_set_card_crossed(player_card, true)
	_set_character_buttons_enabled(not _is_online_character_locked())
	_apply_taken_character_input_state()


func _start_game() -> void:
	var settings := _settings()
	if not settings or settings.get("character_chosen") != true:
		character_status.text = _t("choose_first")
		return

	if settings.get("online_mode") == true:
		if String(settings.get("online_role")) == "host":
			_start_online_host_game()
		elif String(settings.get("online_role")) == "client":
			character_status.text = _t("waiting_for_host_start")
		return

	settings.call("reset_online")
	_clear_peer()
	get_tree().change_scene_to_file(_selected_main_scene())


func _selected_main_scene() -> String:
	var settings := _settings()
	if settings:
		var selected_level := String(settings.get("selected_level"))
		if selected_level == "hard":
			return HARD_SCENE
		if selected_level == "medium":
			return MEDIUM_SCENE
	return MAIN_SCENE


func _host_online_game() -> void:
	if _is_hosting_room():
		return

	_clear_peer()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(ONLINE_PORT, 1)
	if error != OK:
		online_status.text = _t("host_failed") % _error_message(error)
		return

	var settings := _settings()
	if settings:
		settings.set("online_mode", true)
		settings.set("online_role", "host")
		settings.set("character_chosen", false)
		if settings.has_method("reset_online_rounds"):
			settings.reset_online_rounds()
	multiplayer.multiplayer_peer = peer
	hosted_player_count = 1
	hosted_room_id = _make_room_id()
	remote_client_character = "golem"
	remote_client_character_chosen = false
	other_player_character = ""
	other_player_character_chosen = false
	online_status.text = _t("room_open")
	online_start_button.visible = true
	_update_room_buttons()
	joined_room_waiting_for_character = true
	character_status.text = _t("connected_choose")
	_update_character_cards()
	_show_page(choose_page)


func _start_online_host_game() -> void:
	var settings := _settings()
	if settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "host":
		if settings.get("character_chosen") != true:
			joined_room_waiting_for_character = true
			character_status.text = _t("connected_choose")
			_update_character_cards()
			_show_page(choose_page)
			return
		if multiplayer.get_peers().is_empty():
			online_status.text = _t("room_waiting")
			_show_page(online_page)
			return
		if not remote_client_character_chosen:
			character_status.text = _t("waiting_for_player_choice")
			online_status.text = _t("waiting_for_player_choice")
			_show_page(online_page)
			return
		rpc("_start_online_match")
		get_tree().change_scene_to_file(MAIN_SCENE)


func _join_online_game() -> void:
	if _is_hosting_room():
		online_status.text = _t("hosting_device")
		return

	var address := _get_entered_online_address()
	if String(address["ip"]).is_empty():
		online_status.text = _t("invalid_address")
		return

	_clear_peer()
	host_button.disabled = true
	join_button.disabled = true
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address["ip"], address["port"])
	if error != OK:
		online_status.text = _t("join_failed") % _error_message(error)
		_update_room_buttons()
		return

	var settings := _settings()
	if settings:
		settings.set("online_mode", true)
		settings.set("online_role", "client")
		settings.set("character_chosen", false)
		if settings.has_method("reset_online_rounds"):
			settings.reset_online_rounds()
	multiplayer.multiplayer_peer = peer
	remote_client_character = "golem"
	remote_client_character_chosen = false
	other_player_character = ""
	other_player_character_chosen = false
	online_status.text = _t("joining")


func _on_connected_to_server() -> void:
	var settings := _settings()
	if settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "client":
		joined_room_waiting_for_character = true
		other_player_character = ""
		other_player_character_chosen = false
		settings.set("character_chosen", false)
		character_status.text = _t("connected_choose")
		_update_character_cards()
		_show_page(choose_page)


func _on_peer_connected(peer_id: int) -> void:
	var settings := _settings()
	if settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "host":
		hosted_player_count = min(multiplayer.get_peers().size() + 1, MAX_ROOM_PLAYERS)
		remote_client_character_chosen = false
		other_player_character = ""
		other_player_character_chosen = false
		online_status.text = _t("player_connected")
		_update_room_buttons()
		_sync_online_character_state.call_deferred()


func _on_peer_disconnected(_peer_id: int) -> void:
	var settings := _settings()
	if settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "host":
		hosted_player_count = min(multiplayer.get_peers().size() + 1, MAX_ROOM_PLAYERS)
		remote_client_character_chosen = false
		other_player_character = ""
		other_player_character_chosen = false
		online_status.text = _t("room_waiting")
		_update_character_cards()
		_update_room_buttons()


func _on_connection_failed() -> void:
	online_status.text = _t("connection_failed")
	var settings := _settings()
	if settings:
		settings.call("reset_online")
	other_player_character = ""
	other_player_character_chosen = false
	_clear_peer()
	online_start_button.visible = false
	_update_room_buttons()


func _back_from_online() -> void:
	var settings := _settings()
	if settings:
		settings.call("reset_online")
	_clear_peer()
	hosted_player_count = 1
	hosted_room_id = ""
	joined_room_waiting_for_character = false
	remote_client_character = "golem"
	remote_client_character_chosen = false
	other_player_character = ""
	other_player_character_chosen = false
	online_start_button.visible = false
	online_status.text = _t("online_status_default")
	_update_room_buttons()
	_show_page(home_page)


func _update_online_room_text() -> void:
	online_status.text = _t("online_status_default")
	_update_room_buttons()


func _clear_peer() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer:
		peer.close()
	multiplayer.multiplayer_peer = null


func _settings() -> Node:
	return get_node_or_null("/root/GameSettings")


func _get_entered_online_address() -> Dictionary:
	var result := {
		"ip": "",
		"port": ONLINE_PORT
	}
	var address := online_address_input.text.strip_edges()
	if address.is_empty():
		return result
	var parts := address.split(":", false, 1)
	result["ip"] = String(parts[0]).strip_edges()
	if parts.size() > 1 and String(parts[1]).is_valid_int():
		result["port"] = int(parts[1])
	return result


func _is_hosting_room() -> bool:
	var settings := _settings()
	return settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "host"


func _is_joining_room() -> bool:
	var settings := _settings()
	return settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "client"


func _update_room_buttons() -> void:
	if not host_button or not join_button or not online_start_button:
		return

	var hosting := _is_hosting_room()
	var joining := _is_joining_room()
	host_button.disabled = hosting or joining
	join_button.disabled = hosting or joining
	online_start_button.visible = hosting
	if hosting:
		var settings := _settings()
		online_start_button.disabled = not settings or settings.get("character_chosen") != true or multiplayer.get_peers().is_empty() or not remote_client_character_chosen


func _lock_online_character_selection() -> void:
	_set_character_buttons_enabled(false)


func _set_character_buttons_enabled(enabled: bool) -> void:
	player_select_button.disabled = not enabled
	golem_select_button.disabled = not enabled
	player_card.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	golem_card.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _set_character_card_available(card: Control, available: bool) -> void:
	var select_button := card.get_node_or_null("Box/SelectButton") as Button
	if select_button:
		select_button.disabled = not available
	card.mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE


func _apply_taken_character_input_state() -> void:
	if not joined_room_waiting_for_character or not other_player_character_chosen:
		return
	if other_player_character == "golem":
		_set_character_card_available(golem_card, false)
	else:
		_set_character_card_available(player_card, false)


func _set_card_crossed(card: Control, crossed: bool) -> void:
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
		cross.add_theme_color_override("font_color", Color(1.0, 0.12, 0.08, 0.86))
		cross.text = "X"
		card.add_child(cross)
	cross.visible = true
	cross.move_to_front()


func _is_online_character_locked() -> bool:
	var settings := _settings()
	return joined_room_waiting_for_character and settings and settings.get("online_mode") == true and settings.get("character_chosen") == true


func _is_character_taken_by_other_player(character: String) -> bool:
	return joined_room_waiting_for_character and other_player_character_chosen and other_player_character == character


@rpc("any_peer", "reliable")
func _client_online_character_selected(character: String) -> void:
	if not _is_hosting_room():
		return

	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0 or not multiplayer.get_peers().has(sender_id):
		return
	var settings := _settings()
	if settings and settings.get("character_chosen") == true and String(settings.get("selected_character")) == character:
		_sync_online_character_state()
		return

	remote_client_character = character
	remote_client_character_chosen = true
	other_player_character = character
	other_player_character_chosen = true
	if settings:
		settings.set("online_remote_character", character)
	online_status.text = _t("player_connected")
	_update_character_cards()
	_update_room_buttons()
	_sync_online_character_state()


func _sync_online_character_state() -> void:
	if not _is_hosting_room():
		return
	var settings := _settings()
	var host_character := "player"
	var host_character_chosen := false
	if settings:
		host_character = String(settings.get("selected_character"))
		host_character_chosen = settings.get("character_chosen") == true
	rpc("_online_character_state_updated", host_character_chosen, host_character, remote_client_character_chosen, remote_client_character)


@rpc("authority", "reliable")
func _online_character_state_updated(host_character_chosen: bool, host_character: String, _client_character_chosen: bool, _client_character: String) -> void:
	if _is_hosting_room():
		return
	if not _is_joining_room():
		return

	other_player_character = host_character
	other_player_character_chosen = host_character_chosen
	var settings := _settings()
	if settings and settings.get("character_chosen") == true and host_character_chosen and String(settings.get("selected_character")) == host_character:
		settings.set("character_chosen", false)
		character_status.text = _t("connected_choose")
	_update_character_cards()
	_update_room_buttons()


@rpc("authority", "reliable")
func _start_online_match() -> void:
	var settings := _settings()
	if settings:
		settings.set("character_chosen", true)
	joined_room_waiting_for_character = false
	get_tree().change_scene_to_file(MAIN_SCENE)


func _make_room_id() -> String:
	return "%d-%d" % [Time.get_ticks_msec(), randi()]


func _error_message(error: int) -> String:
	if error == ERR_CANT_CREATE:
		return "20 no network permission/port busy"
	return str(error)


