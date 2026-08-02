extends Control

const MAIN_SCENE := "res://Scenes/main.tscn"
const MEDIUM_SCENE := "res://Scenes/MainMedium.tscn"
const HARD_SCENE := "res://Scenes/MainHard.tscn"
const ONLINE_PORT := 8910
const ROOM_NAME := "Silent City Room"
const MAX_ROOM_PLAYERS := 2
const STEAM_LOBBY_REFRESH_INTERVAL := 2.0
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
		"how_to_play": "How to Play",
		"how_to_play_text": "Move with Left/Right arrows or D.\nJump with Space.\nUse hands with A and S.\nDefeat enemies, avoid spikes, and collect hearts for health.\nFirst heart appears after 35 seconds, then every 90 seconds.",
		"how_attack": "Hands: A / S",
		"how_heart": "First heart: 35s, then 90s",
		"how_jump": "Jump: Space",
		"credits": "Credits",
		"credits_text": "Silent City\nCreated by Luka Guledani / SonnyRenderer\n\nCharacter and asset credits:\nKenney - Animated Characters Retro 1.1\nLicense: Creative Commons Zero (CC0)\nwww.kenney.nl\n\nGraveyard platform tileset\nGameArt2D / CraftPix freebie license\nhttps://www.gameart2d.com/free-graveyard-platformer-tileset.html\n\nThank you for playing.",
		"exit": "Exit",
		"select": "Select",
		"choose_first": "Choose a character before starting.",
		"start_game": "Start Game",
		"back": "Back",
		"host_room": "Create Room",
		"return_to_match": "Return to Game",
		"join": "Join",
		"start_online_room": "Start Match",
		"tutorial_title": "Steam Lobby",
		"skip": "Skip",
		"next": "Next",
		"done": "Done",
		"selected_online": "Selected: %s. Wait for the Steam lobby to start.",
		"selected": "Selected: %s",
		"host_failed": "Host failed: %s",
		"room_open": "Steam lobby is open. Invite a friend or let them press Join.",
		"steam_creating_lobby": "Creating Steam lobby...",
		"steam_finding_lobby": "Looking for rooms...",
		"steam_lobby_count": "Select a room to join.",
		"steam_no_lobby": "No rooms yet. Waiting for rooms...",
		"steam_transport_missing": "Steam lobby works, but Steam MultiplayerPeer addon is missing.",
		"hosting_device": "This device is already hosting a Steam lobby.",
		"hosting_active": "Your Steam room is still open.",
		"no_room_selected": "No Steam lobby selected.",
		"join_failed": "Join failed: %s",
		"joining": "Joining room...",
		"connected_choose": "Connected. Choose your character.",
		"waiting_for_host_start": "Character selected. Waiting for both players.",
		"waiting_for_player_choice": "Waiting for the other player to choose a character.",
		"player_connected": "Player connected.\nChoose characters to start.",
		"both_ready": "Both players ready. Starting match...",
		"room_waiting": "Steam lobby is open. Waiting for player to join.",
		"connection_failed": "Connection failed",
		"online_status_default": "Create a room or join a room that appears here.",
		"steam_not_ready": "Steam is not ready. Open Steam and restart the game.",
		"invalid_address": "No Steam lobby selected.",
		"room_players": "%s - %d/%d players"
	},
	LANG_GEO: {
		"language_button": "ENG",
		"subtitle": "აირჩიე ბრძოლა",
		"start": "დაწყება",
		"choose_level": "აირჩიე დონე",
		"easy": "მარტივი",
		"medium": "საშუალო",
		"hard": "რთული",
		"choose_character": "აირჩიე პერსონაჟი",
		"online_room": "ონლაინი",
		"how_to_play": "როგორ ვითამაშოთ",
		"how_to_play_text": "იმოძრავე მარცხენა/მარჯვენა ისრებით ან D-ით.\nახტომა: Space.\nხელებით დარტყმა: A და S.\nდაამარცხე მტრები, მოერიდე ეკლებს და აიღე გულები სიცოცხლისთვის.\nპირველი გული მოდის 35 წამში, შემდეგ ყოველ 90 წამში.",
		"how_attack": "ხელები: A / S",
		"how_heart": "პირველი: 35წმ, მერე 90წმ",
		"how_jump": "ახტომა: Space",
		"credits": "კრედიტები",
		"credits_text": "Silent City\nშექმნა: Luka Guledani / SonnyRenderer\n\nპერსონაჟებისა და ასეტების კრედიტები:\nKenney - Animated Characters Retro 1.1\nლიცენზია: Creative Commons Zero (CC0)\nwww.kenney.nl\n\nGraveyard platform tileset\nGameArt2D / CraftPix freebie license\nhttps://www.gameart2d.com/free-graveyard-platformer-tileset.html\n\nმადლობა თამაშისთვის.",
		"exit": "გასვლა",
		"select": "არჩევა",
		"choose_first": "ჯერ აირჩიე პერსონაჟი.",
		"start_game": "თამაშის დაწყება",
		"back": "უკან",
		"host_room": "ოთახის შექმნა",
		"return_to_match": "თამაშში დაბრუნება",
		"join": "შესვლა",
		"start_online_room": "მატჩის დაწყება",
		"tutorial_title": "Steam Lobby",
		"skip": "გამოტოვება",
		"next": "შემდეგი",
		"done": "მზადაა",
		"selected_online": "არჩეულია: %s. დაელოდე Steam ლობის დაწყებას.",
		"selected": "არჩეულია: %s",
		"host_failed": "ოთახი ვერ შეიქმნა: %s",
		"room_open": "Steam ლობი გახსნილია. მოიწვიე მეგობარი ან დააჭერინე Join.",
		"steam_creating_lobby": "Steam ლობი იქმნება...",
		"steam_finding_lobby": "ოთახების ძებნა...",
		"steam_lobby_count": "აირჩიე ოთახი შესასვლელად.",
		"steam_no_lobby": "ოთახები ჯერ არ არის. ველოდებით...",
		"steam_transport_missing": "Steam ლობი მუშაობს, მაგრამ Steam MultiplayerPeer addon აკლია.",
		"hosting_device": "ეს მოწყობილობა უკვე ქმნის Steam ლობის.",
		"hosting_active": "შენი Steam ოთახი ისევ ღიაა.",
		"no_room_selected": "Steam ლობი არჩეული არ არის.",
		"join_failed": "შესვლა ვერ მოხერხდა: %s",
		"joining": "ოთახში შესვლა...",
		"connected_choose": "დაკავშირებულია. აირჩიე პერსონაჟი.",
		"waiting_for_host_start": "პერსონაჟი არჩეულია. ველოდებით ორივე მოთამაშეს.",
		"waiting_for_player_choice": "ველოდებით მეორე მოთამაშის არჩევანს.",
		"player_connected": "მოთამაშე შემოვიდა.\nაირჩიეთ პერსონაჟები დასაწყებად.",
		"both_ready": "ორივე მოთამაშე მზადაა. მატჩი იწყება...",
		"room_waiting": "Steam ლობი ღიაა. ველოდებით მოთამაშეს.",
		"connection_failed": "კავშირი ვერ მოხერხდა",
		"online_status_default": "შექმენი ოთახი ან შედი აქ გამოჩენილ ოთახში.",
		"steam_not_ready": "Steam მზად არ არის. გახსენი Steam და თავიდან გაუშვი თამაში.",
		"invalid_address": "Steam ლობი არჩეული არ არის.",
		"room_players": "%s - %d/%d მოთამაშე"
	}
}
const ONLINE_TUTORIAL_STEPS := {
	LANG_ENG: [
		"Create Room opens a Steam room for other players.",
		"Open rooms appear automatically. Select one and press Join.",
		"Both players choose different characters. The match starts by itself.",
		"Host can leave to menu and press Return to Game to rejoin."
	],
	LANG_GEO: [
		"ოთახის შექმნა ხსნის Steam ოთახს სხვა მოთამაშეებისთვის.",
		"ღია ოთახები ავტომატურად გამოჩნდება. აირჩიე ოთახი და დააჭირე Join.",
		"ორივე მოთამაშე ირჩევს განსხვავებულ პერსონაჟს. მატჩი თვითონ იწყება.",
		"Host-ს შეუძლია მენიუში გასვლა და Return to Game-ით დაბრუნება."
	]
}

@onready var pages: Control = $Content/Root/Pages
@onready var language_button: Button = $LanguageButton
@onready var subtitle_label: Label = $Content/Root/Subtitle
@onready var home_page: VBoxContainer = $Content/Root/Pages/Home
@onready var level_page: VBoxContainer = $Content/Root/Pages/ChooseLevel
@onready var choose_page: VBoxContainer = $Content/Root/Pages/ChooseCharacter
@onready var how_to_play_page: VBoxContainer = $Content/Root/Pages/HowToPlay
@onready var credits_page: VBoxContainer = $Content/Root/Pages/Credits
@onready var online_page: VBoxContainer = $Content/Root/Pages/Online
@onready var home_start_button: Button = $Content/Root/Pages/Home/StartButton
@onready var home_choose_button: Button = $Content/Root/Pages/Home/ChooseButton
@onready var home_online_button: Button = $Content/Root/Pages/Home/OnlineButton
@onready var home_how_to_play_button: Button = $Content/Root/Pages/Home/HowToPlayButton
@onready var home_credits_button: Button = $Content/Root/Pages/Home/CreditsButton
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
@onready var how_to_play_header: Label = $Content/Root/Pages/HowToPlay/Header
@onready var how_to_play_instructions: Label = $Content/Root/Pages/HowToPlay/Instructions
@onready var how_attack_label: Label = $Content/Root/Pages/HowToPlay/Cards/AttackCard/Text
@onready var how_heart_label: Label = $Content/Root/Pages/HowToPlay/Cards/HeartCard/Text
@onready var how_jump_label: Label = $Content/Root/Pages/HowToPlay/Cards/JumpCard/Text
@onready var how_to_play_back_button: Button = $Content/Root/Pages/HowToPlay/BackButton
@onready var credits_header: Label = $Content/Root/Pages/Credits/Header
@onready var credits_text: Label = $Content/Root/Pages/Credits/CreditsText
@onready var credits_back_button: Button = $Content/Root/Pages/Credits/BackButton
@onready var online_tutorial_overlay: Control = $Content/Root/Pages/TutorialOverlay
@onready var online_tutorial_title: Label = $Content/Root/Pages/TutorialOverlay/Card/Box/Title
@onready var online_tutorial_text: Label = $Content/Root/Pages/TutorialOverlay/Card/Box/Text
@onready var online_tutorial_next: Button = $Content/Root/Pages/TutorialOverlay/Card/Box/Buttons/NextButton
@onready var online_tutorial_skip: Button = $Content/Root/Pages/TutorialOverlay/Card/Box/Buttons/SkipButton
@onready var online_tutorial_back: Button = $Content/Root/Pages/TutorialOverlay/Card/Box/Buttons/BackButton
@onready var online_address_input: LineEdit = $Content/Root/Pages/Online/AddressBox/AddressInput
@onready var room_name_input: LineEdit = $Content/Root/Pages/Online/RoomNameInput
@onready var online_header: Label = $Content/Root/Pages/Online/Header
@onready var online_status: Label = $Content/Root/Pages/Online/StatusLabel
@onready var lobby_select: ItemList = $Content/Root/Pages/Online/LobbySelect
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
var steam_lobbies: Array = []
var steam_lobby_refresh_timer := 0.0
var steam_lobby_searching := false
var steam_lobby_wide_searching := false
var online_match_starting := false
var pending_join_lobby: Dictionary = {}
var level_select_starts_game := false


func _ready() -> void:
	_setup_language()
	language_button.pressed.connect(_toggle_language)
	home_start_button.pressed.connect(_open_start_flow)
	home_choose_button.pressed.connect(func(): _show_page(choose_page))
	home_online_button.pressed.connect(_open_online_page)
	home_how_to_play_button.pressed.connect(func(): _show_page(how_to_play_page))
	home_credits_button.pressed.connect(func(): _show_page(credits_page))
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
	choose_start_button.pressed.connect(_open_level_select_from_character)
	choose_online_button.pressed.connect(_open_online_page)
	choose_back_button.pressed.connect(_back_from_character_page)
	how_to_play_back_button.pressed.connect(func(): _show_page(home_page))
	credits_back_button.pressed.connect(func(): _show_page(home_page))
	host_button.pressed.connect(_host_online_game)
	join_button.pressed.connect(_join_online_game)
	lobby_select.item_activated.connect(func(_index: int): _join_online_game())
	online_start_button.pressed.connect(_start_online_host_game)
	online_tutorial_next.pressed.connect(_advance_online_tutorial)
	online_tutorial_skip.pressed.connect(_finish_online_tutorial)
	online_tutorial_back.pressed.connect(_back_from_online)
	online_back_button.pressed.connect(_back_from_online)
	var address_box := online_address_input.get_parent() as Control
	if address_box:
		address_box.visible = false
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_connect_steam_manager()
	_apply_language()
	_update_character_cards()
	_update_online_room_text()
	_update_lobby_select()
	online_start_button.visible = false
	_update_room_buttons()
	_show_page(home_page)


func _process(delta: float) -> void:
	if not online_page or not online_page.visible:
		return
	if _is_hosting_room() or _is_joining_room() or not _steam_ready():
		return
	steam_lobby_refresh_timer -= delta
	if steam_lobby_refresh_timer <= 0.0:
		steam_lobby_refresh_timer = STEAM_LOBBY_REFRESH_INTERVAL
		_request_steam_lobbies(false)


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
	home_how_to_play_button.text = _t("how_to_play")
	home_credits_button.text = _t("credits")
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
	how_to_play_header.text = _t("how_to_play")
	how_to_play_instructions.text = _t("how_to_play_text")
	how_attack_label.text = _t("how_attack")
	how_heart_label.text = _t("how_heart")
	how_jump_label.text = _t("how_jump")
	how_to_play_back_button.text = _t("back")
	credits_header.text = _t("credits")
	credits_text.text = _t("credits_text")
	credits_back_button.text = _t("back")
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
	_request_steam_lobbies(true)
	_show_online_tutorial_once()


func _open_start_flow() -> void:
	var settings := _settings()
	if settings:
		settings.set("character_chosen", false)
		settings.set("level_chosen", false)
	level_select_starts_game = false
	_update_character_cards()
	_show_page(choose_page)


func _select_level(level: String) -> void:
	var settings := _settings()
	if settings:
		settings.set("selected_level", level)
		settings.set("level_chosen", true)
	if level_select_starts_game:
		_start_game()
		return
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


func _open_level_select_from_character() -> void:
	var settings := _settings()
	if not settings or settings.get("character_chosen") != true:
		character_status.text = _t("choose_first")
		return
	if settings.get("online_mode") == true:
		_start_game()
		return
	settings.set("level_chosen", false)
	level_select_starts_game = true
	_show_page(level_page)


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
			_try_auto_start_online_match()
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
	else:
		player_card.modulate = Color(0.65, 1.0, 0.65)
	_set_character_buttons_enabled(not _is_online_character_locked())
	_apply_taken_character_input_state()


func _start_game() -> void:
	var settings := _settings()
	if not settings or settings.get("character_chosen") != true:
		character_status.text = _t("choose_first")
		return

	if settings.get("level_chosen") != true:
		_open_level_select_from_character()
		return

	if settings.get("online_mode") == true:
		if String(settings.get("online_role")) == "host":
			_start_online_host_game()
		elif String(settings.get("online_role")) == "client":
			character_status.text = _t("waiting_for_host_start")
		return

	settings.call("reset_online")
	settings.call("start_offline_level", String(settings.get("selected_level")))
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
		online_status.text = _t("hosting_active")
		get_tree().change_scene_to_file(MAIN_SCENE)
		return

	_clear_peer()
	steam_lobbies.clear()
	_update_lobby_select()
	if not _steam_ready():
		online_status.text = _steam_not_ready_message()
		return
	online_status.text = _t("steam_creating_lobby")
	host_button.disabled = true
	join_button.disabled = true
	_steam_manager().create_lobby(_room_name())


func _finish_steam_host_lobby(_lobby_id: int) -> void:
	var peer := _steam_manager().create_host_peer() as MultiplayerPeer
	if not peer:
		online_status.text = _t("steam_transport_missing")
		_update_room_buttons()
		return

	_prepare_online_host(peer)


func _prepare_online_host(peer: MultiplayerPeer) -> void:
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
	online_match_starting = false
	steam_lobbies.clear()
	_update_lobby_select()
	online_status.text = "Steam lobby is open. Invite a friend or let them press Join."
	online_start_button.visible = false
	_update_room_buttons()
	joined_room_waiting_for_character = true
	character_status.text = _t("connected_choose")
	_update_character_cards()
	_show_page(choose_page)


func _start_online_host_game() -> void:
	_try_auto_start_online_match()


func _try_auto_start_online_match() -> void:
	var settings := _settings()
	if online_match_starting:
		return
	if not settings or settings.get("online_mode") != true or String(settings.get("online_role")) != "host":
		return
	if settings.get("character_chosen") != true:
		joined_room_waiting_for_character = true
		character_status.text = _t("connected_choose")
		_update_character_cards()
		return
	if multiplayer.get_peers().is_empty():
		online_status.text = _t("room_waiting")
		return
	if not remote_client_character_chosen:
		character_status.text = _t("waiting_for_player_choice")
		online_status.text = _t("waiting_for_player_choice")
		return

	online_match_starting = true
	joined_room_waiting_for_character = false
	var host_character := String(settings.get("selected_character"))
	var steam_manager := _steam_manager()
	if steam_manager and steam_manager.has_method("set_lobby_match_state"):
		steam_manager.set_lobby_match_state("playing", host_character, remote_client_character)
	character_status.text = _t("both_ready")
	online_status.text = _t("both_ready")
	online_start_button.visible = false
	_update_room_buttons()
	_sync_online_character_state()
	rpc("_start_online_match")
	get_tree().change_scene_to_file(MAIN_SCENE)


func _join_online_game() -> void:
	if _is_hosting_room():
		online_status.text = _t("hosting_device")
		return

	if not _steam_ready():
		online_status.text = _steam_not_ready_message()
		return

	if not steam_lobbies.is_empty():
		var selected_items := lobby_select.get_selected_items()
		var selected_index := int(selected_items[0]) if not selected_items.is_empty() else 0
		if selected_index >= steam_lobbies.size():
			selected_index = 0
		var lobby_id := int(steam_lobbies[selected_index].get("id", 0))
		_prepare_join_selected_lobby(steam_lobbies[selected_index])
		_steam_manager().join_lobby(lobby_id)
		online_status.text = _t("joining")
		return

	online_status.text = _t("steam_no_lobby")
	_request_steam_lobbies(true)


func _prepare_join_selected_lobby(lobby_data: Dictionary) -> void:
	_clear_peer()
	pending_join_lobby = lobby_data.duplicate(true)
	var settings := _settings()
	if settings:
		settings.set("online_mode", true)
		settings.set("online_role", "client")
		if _is_pending_join_lobby_playing():
			var saved_client_character := String(pending_join_lobby.get("client_character", "")).strip_edges()
			var saved_host_character := String(pending_join_lobby.get("host_character", "")).strip_edges()
			if saved_client_character in ["player", "golem"]:
				settings.set("selected_character", saved_client_character)
			settings.set("character_chosen", true)
			if saved_host_character in ["player", "golem"]:
				settings.set("online_remote_character", saved_host_character)
		else:
			settings.set("character_chosen", false)
		if settings.has_method("reset_online_rounds"):
			settings.reset_online_rounds()
	remote_client_character = "golem"
	remote_client_character_chosen = false
	other_player_character = ""
	other_player_character_chosen = false
	online_match_starting = false
	steam_lobbies.clear()
	_update_lobby_select()


func _finish_steam_join_lobby(lobby_id: int) -> void:
	if not _is_joining_room():
		return
	var peer := _steam_manager().create_client_peer_for_lobby(lobby_id) as MultiplayerPeer
	if not peer:
		online_status.text = _t("steam_transport_missing")
		_update_room_buttons()
		return
	multiplayer.multiplayer_peer = peer
	if _is_pending_join_lobby_playing():
		online_status.text = "Rejoining match..."
		get_tree().change_scene_to_file(MAIN_SCENE)
	else:
		online_status.text = _t("joining")


func _on_steam_lobby_list_updated(lobbies: Array) -> void:
	steam_lobby_searching = false
	if _is_hosting_room() or (_is_joining_room() and multiplayer.multiplayer_peer != null):
		return
	if lobbies.is_empty() and not steam_lobby_wide_searching:
		online_status.text = "Still searching Steam rooms..."
		_request_steam_lobbies(false, true)
		return
	steam_lobby_wide_searching = false
	if lobbies.is_empty() and not steam_lobbies.is_empty():
		online_status.text = "Steam refresh missed the room. Select it and press Join."
		_update_lobby_select()
		_update_room_buttons()
		return
	steam_lobbies = lobbies.duplicate(true)
	_update_lobby_select()
	if lobbies.is_empty():
		online_status.text = _t("steam_no_lobby")
		_update_room_buttons()
		return
	online_status.text = _t("steam_lobby_count")
	_update_room_buttons()


func _on_connected_to_server() -> void:
	var settings := _settings()
	if settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "client":
		if _is_pending_join_lobby_playing():
			online_status.text = "Rejoining match..."
			get_tree().change_scene_to_file(MAIN_SCENE)
			return
		joined_room_waiting_for_character = true
		other_player_character = ""
		other_player_character_chosen = false
		online_match_starting = false
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
		online_match_starting = false
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
		online_match_starting = false
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
	online_match_starting = false
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
	online_match_starting = false
	pending_join_lobby.clear()
	online_start_button.visible = false
	steam_lobbies.clear()
	_update_lobby_select()
	online_status.text = _t("online_status_default")
	_update_room_buttons()
	_show_page(home_page)


func _update_online_room_text() -> void:
	online_status.text = _t("online_status_default")
	_update_room_buttons()


func _request_steam_lobbies(show_search_text: bool, wide_search: bool = false) -> void:
	if steam_lobby_searching or not _steam_ready() or _is_hosting_room() or _is_joining_room():
		return
	steam_lobby_searching = true
	steam_lobby_wide_searching = wide_search
	if show_search_text:
		online_status.text = _t("steam_finding_lobby")
	_steam_manager().request_lobbies(wide_search)


func _clear_peer() -> void:
	var steam_manager := _steam_manager()
	if steam_manager and steam_manager.has_method("leave_lobby"):
		steam_manager.leave_lobby()
	var peer := multiplayer.multiplayer_peer
	if peer and peer.has_method("close"):
		peer.close()
	multiplayer.multiplayer_peer = null


func _settings() -> Node:
	return get_node_or_null("/root/GameSettings")


func _update_lobby_select() -> void:
	if not lobby_select:
		return
	lobby_select.clear()
	if steam_lobbies.is_empty():
		lobby_select.visible = false
		lobby_select.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	lobby_select.visible = true
	lobby_select.mouse_filter = Control.MOUSE_FILTER_STOP
	for index in steam_lobbies.size():
		var lobby: Dictionary = steam_lobbies[index]
		var lobby_name := String(lobby.get("name", "Silent City"))
		if String(lobby.get("state", "waiting")) == "playing":
			lobby_name = "%s - Playing" % lobby_name
		lobby_select.add_item(lobby_name)
	lobby_select.select(0)


func _is_pending_join_lobby_playing() -> bool:
	return String(pending_join_lobby.get("state", "waiting")) == "playing"


func _steam_manager() -> Node:
	return get_node_or_null("/root/SteamManager")


func _room_name() -> String:
	var room_name := room_name_input.text.strip_edges()
	return room_name if not room_name.is_empty() else "Silent City"


func _steam_ready() -> bool:
	var steam_manager := _steam_manager()
	return steam_manager and steam_manager.has_method("is_ready") and steam_manager.is_ready()


func _steam_not_ready_message() -> String:
	var steam_manager := _steam_manager()
	if steam_manager and steam_manager.has_method("get_last_error"):
		var message := String(steam_manager.get_last_error())
		if not message.is_empty():
			return message
	return _t("steam_not_ready")


func _connect_steam_manager() -> void:
	var steam_manager := _steam_manager()
	if not steam_manager:
		return
	if steam_manager.has_signal("lobby_created") and not steam_manager.lobby_created.is_connected(_finish_steam_host_lobby):
		steam_manager.lobby_created.connect(_finish_steam_host_lobby)
	if steam_manager.has_signal("lobby_joined") and not steam_manager.lobby_joined.is_connected(_finish_steam_join_lobby):
		steam_manager.lobby_joined.connect(_finish_steam_join_lobby)
	if steam_manager.has_signal("lobby_list_updated") and not steam_manager.lobby_list_updated.is_connected(_on_steam_lobby_list_updated):
		steam_manager.lobby_list_updated.connect(_on_steam_lobby_list_updated)
	if steam_manager.has_signal("steam_failed") and not steam_manager.steam_failed.is_connected(_on_steam_failed):
		steam_manager.steam_failed.connect(_on_steam_failed)


func _on_steam_failed(message: String) -> void:
	if online_page and online_page.visible:
		online_status.text = message
	_update_room_buttons()


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
	return settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "host" and multiplayer.has_multiplayer_peer()


func _is_joining_room() -> bool:
	var settings := _settings()
	return settings and settings.get("online_mode") == true and String(settings.get("online_role")) == "client"


func _update_room_buttons() -> void:
	if not host_button or not join_button or not online_start_button:
		return

	var hosting := _is_hosting_room()
	var joining := _is_joining_room()
	var has_peer := multiplayer.multiplayer_peer != null
	host_button.disabled = joining
	host_button.text = _t("return_to_match") if hosting else _t("host_room")
	join_button.disabled = hosting or steam_lobbies.is_empty() or (joining and has_peer)
	online_start_button.visible = false
	online_start_button.disabled = true


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
	_try_auto_start_online_match()


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
	online_match_starting = true
	get_tree().change_scene_to_file(MAIN_SCENE)


func _make_room_id() -> String:
	return "%d-%d" % [Time.get_ticks_msec(), randi()]


func _error_message(error: int) -> String:
	if error == ERR_CANT_CREATE:
		return "20 no network permission/port busy"
	return str(error)


