extends Control

const MAIN_SCENE := "res://Scenes/main.tscn"
const MEDIUM_SCENE := "res://Scenes/MainMedium.tscn"
const HARD_SCENE := "res://Scenes/MainHard.tscn"
const ONLINE_PORT := 8910
const ROOM_NAME := "Silent City Room"
const MAX_ROOM_PLAYERS := 2
const STEAM_LOBBY_REFRESH_INTERVAL := 2.0
const WIFI_DISCOVERY_PORT := 8911
const WIFI_DISCOVERY_INTERVAL := 1.0
const WIFI_DISCOVERY_TIMEOUT := 4.0
const WIFI_DISCOVERY_TAG := "silent_city_wifi_room"
const LANG_ENG := "eng"
const LANG_GEO := "geo"
const ONLINE_MODE_WIFI := "wifi"
const ONLINE_MODE_STEAM := "steam"
const ICE_GOLEM_UNLOCK_COINS := 2500
const CHARACTER_DISPLAY_NAMES := {
	"player": "Ash Golem",
	"golem": "Stone Golem",
	"ice_golem": "Ice Golem"
}
const TEXT := {
	LANG_ENG: {
		"language_button": "GEO",
		"subtitle": "Choose your fight",
		"start": "Start",
		"map": "Map",
		"choose_your_map": "Choose Your Map",
		"easy": "Easy Map",
		"medium": "Medium Map",
		"hard": "Hard Map",
		"map_gallery_hint": "Map preview only. To play, go back and press Start from the main menu.",
		"map_selected_wait": "Selected: %s. You have to wait 2 seconds because it has a time to wait xD",
		"choose_map_to_start": "Choose a map to start the match.",
		"choose_character": "Choose Character",
		"online_room": "Online",
		"wifi_multiplayer": "wifi",
		"steam_friend": "Steam Friend",
		"how_to_play": "How to Play",
		"how_to_play_text": "Move with Left/Right arrows.\nJump with Up Arrow.\nUse hands with A and foot kick with S.\nDefeat enemies, avoid spikes, and collect hearts for health.\nFirst heart appears after 35 seconds, then every 90 seconds.",
		"how_attack": "Hands: A",
		"how_kick": "Foot: S",
		"how_heart": "First heart: 35s, then 90s",
		"how_jump": "Jump: Up Arrow",
		"credits": "Credits",
		"credits_text": "Silent City\nCreated by Luka Guledani / SonnyRenderer\n\nCharacter and asset credits:\nKenney - Animated Characters Retro 1.1\nLicense: Creative Commons Zero (CC0)\nwww.kenney.nl\n\nGraveyard platform tileset\nGameArt2D / CraftPix freebie license\nhttps://www.gameart2d.com/free-graveyard-platformer-tileset.html\n\nThank you for playing.",
		"exit": "Exit",
		"select": "Select",
		"locked": "Locked %d/%d",
		"coins": "Coins: %d",
		"character_locked": "%s unlocks at %d coins. You have %d.",
		"choose_first": "Choose a character before starting.",
		"start_game": "Start Game",
		"back": "Back",
		"host_room": "Create Room",
		"wifi_create": "Start Wi-Fi",
		"return_to_match": "Return to Game",
		"join": "Join",
		"wifi_join": "Connect",
		"start_online_room": "Start Match",
		"tutorial_title": "Online Multiplayer",
		"skip": "Skip",
		"next": "Next",
		"done": "Done",
		"selected_online": "Selected: %s. Wait for the online match to start.",
		"selected": "Selected: %s",
		"host_failed": "Server failed: %s",
		"room_open": "Room is open. Invite a friend or let them press Join.",
		"wifi_room_open": "Wi-Fi connection is ready. Waiting for another player.",
		"steam_room_open": "Steam lobby is open. Invite a Steam friend or let them press Join.",
		"wifi_status_default": "Looking for nearby Wi-Fi connections.",
		"steam_status_default": "Create a Steam lobby or join a lobby that appears here.",
		"wifi_address_placeholder": "wifi",
		"room_name_hint": "You can change name of server",
		"default_connection_name": "Silent City",
		"steam_creating_lobby": "Creating Steam lobby...",
		"wifi_creating_room": "Starting Wi-Fi connection...",
		"steam_finding_lobby": "Looking for rooms...",
		"steam_lobby_count": "Select a room to join.",
		"steam_no_lobby": "No rooms yet. Waiting for rooms...",
		"steam_transport_missing": "Steam lobby works, but Steam MultiplayerPeer addon is missing.",
		"hosting_device": "This device is already hosting a room.",
		"hosting_active": "Your room is still open.",
		"no_room_selected": "No Steam lobby selected.",
		"join_failed": "Join failed: %s",
		"joining": "Joining room...",
		"connected_choose": "Connected. Choose your character.",
		"waiting_for_host_start": "Character selected. Waiting for both players.",
		"waiting_for_player_choice": "Waiting for the other player to choose a character.",
		"player_connected": "Player connected.\nChoose characters to start.",
		"both_ready": "Both players ready. Starting match...",
		"room_waiting": "Room is open. Waiting for player to join.",
		"wifi_room_waiting": "Wi-Fi connection is ready. Waiting for player to connect.",
		"steam_room_waiting": "Steam lobby is open. Waiting for player to join.",
		"connection_failed": "Connection failed",
		"online_status_default": "Choose wifi or Steam Friend.",
		"steam_not_ready": "Steam is not ready. Open Steam and restart the game.",
		"invalid_address": "No Wi-Fi connection found yet.",
		"wifi_room_found": "Select a Wi-Fi connection and press Connect.",
		"wifi_no_room": "No Wi-Fi connections found yet. Keep this screen open.",
		"wifi_no_room_list": "No Wi-Fi connections found yet",
		"wifi_connection_item": "%s - Wi-Fi connection",
		"room_players": "%s - %d/%d players"
	},
	LANG_GEO: {
		"language_button": "ENG",
		"subtitle": "აირჩიე ბრძოლა",
		"start": "დაწყება",
		"map": "რუკები",
		"choose_your_map": "აირჩიე რუკა",
		"easy": "მარტივი",
		"medium": "საშუალო",
		"hard": "რთული",
		"map_gallery_hint": "ეს მხოლოდ რუკების ნახვაა. სათამაშოდ დაბრუნდი მთავარ მენიუში და დააჭირე Start-ს.",
		"map_selected_wait": "არჩეულია: %s. უნდა დაელოდო 2 წამი, იმიტომ რომ ლოდინის დრო აქვს xD",
		"choose_map_to_start": "აირჩიე რუკა, რომ მატჩი დაიწყოს.",
		"choose_character": "აირჩიე პერსონაჟი",
		"online_room": "ონლაინი",
		"wifi_multiplayer": "ვაიფაი",
		"steam_friend": "სტიმ მეგობარი",
		"how_to_play": "როგორ ვითამაშოთ",
		"how_to_play_text": "იმოძრავე მარცხენა/მარჯვენა ისრებით.\nახტომა: Up Arrow.\nხელით დარტყმა: A, ფეხით დარტყმა: S.\nდაამარცხე მტრები, მოერიდე ეკლებს და აიღე გულები სიცოცხლისთვის.\nპირველი გული მოდის 35 წამში, შემდეგ ყოველ 90 წამში.",
		"how_attack": "ხელები: A",
		"how_kick": "ფეხი: S",
		"how_heart": "პირველი: 35წმ, მერე 90წმ",
		"how_jump": "ახტომა: Up Arrow",
		"credits": "კრედიტები",
		"credits_text": "Silent City\nშექმნა: Luka Guledani / SonnyRenderer\n\nპერსონაჟებისა და ასეტების კრედიტები:\nKenney - Animated Characters Retro 1.1\nლიცენზია: Creative Commons Zero (CC0)\nwww.kenney.nl\n\nGraveyard platform tileset\nGameArt2D / CraftPix freebie license\nhttps://www.gameart2d.com/free-graveyard-platformer-tileset.html\n\nმადლობა თამაშისთვის.",
		"exit": "გასვლა",
		"select": "არჩევა",
		"choose_first": "ჯერ აირჩიე პერსონაჟი.",
		"start_game": "თამაშის დაწყება",
		"back": "უკან",
		"host_room": "ოთახის შექმნა",
		"wifi_create": "Wi-Fi დაწყება",
		"return_to_match": "თამაშში დაბრუნება",
		"join": "შესვლა",
		"wifi_join": "დაკავშირება",
		"start_online_room": "მატჩის დაწყება",
		"tutorial_title": "ონლაინ თამაში",
		"skip": "გამოტოვება",
		"next": "შემდეგი",
		"done": "მზადაა",
		"selected_online": "არჩეულია: %s. დაელოდე ონლაინ მატჩის დაწყებას.",
		"selected": "არჩეულია: %s",
		"host_failed": "ოთახი ვერ შეიქმნა: %s",
		"room_open": "ოთახი ღიაა. მოიწვიე მეგობარი ან დააჭერინე შესვლა.",
		"wifi_room_open": "Wi-Fi კავშირი მზადაა. ველოდებით მეორე მოთამაშეს.",
		"steam_room_open": "სტიმ ლობი ღიაა. მოიწვიე სტიმ მეგობარი ან დააჭერინე შესვლა.",
		"wifi_status_default": "ვეძებთ ახლომდებარე Wi-Fi კავშირებს.",
		"steam_status_default": "შექმენი სტიმ ლობი ან შედი აქ გამოჩენილ ლობიში.",
		"wifi_address_placeholder": "ვაიფაი",
		"room_name_hint": "შეგიძლია შეცვალო სერვერის სახელი",
		"default_connection_name": "ჩუმი ქალაქი",
		"steam_creating_lobby": "სტიმ ლობი იქმნება...",
		"wifi_creating_room": "Wi-Fi კავშირი იწყება...",
		"steam_finding_lobby": "ოთახების ძებნა...",
		"steam_lobby_count": "აირჩიე ოთახი შესასვლელად.",
		"steam_no_lobby": "ოთახები ჯერ არ არის. ველოდებით...",
		"steam_transport_missing": "სტიმ ლობი მუშაობს, მაგრამ სტიმ MultiplayerPeer დამატება აკლია.",
		"hosting_device": "ეს მოწყობილობა უკვე ქმნის ოთახს.",
		"hosting_active": "შენი ოთახი ისევ ღიაა.",
		"no_room_selected": "სტიმ ლობი არჩეული არ არის.",
		"join_failed": "შესვლა ვერ მოხერხდა: %s",
		"joining": "ოთახში შესვლა...",
		"connected_choose": "დაკავშირებულია. აირჩიე პერსონაჟი.",
		"waiting_for_host_start": "პერსონაჟი არჩეულია. ველოდებით ორივე მოთამაშეს.",
		"waiting_for_player_choice": "ველოდებით მეორე მოთამაშის არჩევანს.",
		"player_connected": "მოთამაშე შემოვიდა.\nაირჩიეთ პერსონაჟები დასაწყებად.",
		"both_ready": "ორივე მოთამაშე მზადაა. მატჩი იწყება...",
		"room_waiting": "ოთახი ღიაა. ველოდებით მოთამაშეს.",
		"wifi_room_waiting": "Wi-Fi კავშირი მზადაა. ველოდებით მოთამაშეს.",
		"steam_room_waiting": "სტიმ ლობი ღიაა. ველოდებით მოთამაშეს.",
		"connection_failed": "კავშირი ვერ მოხერხდა",
		"online_status_default": "აირჩიე ვაიფაი ან სტიმ მეგობარი.",
		"steam_not_ready": "სტიმ მზად არ არის. გახსენი სტიმი და თავიდან გაუშვი თამაში.",
		"invalid_address": "Wi-Fi კავშირი ჯერ არ მოიძებნა.",
		"wifi_room_found": "აირჩიე Wi-Fi კავშირი და დააჭირე დაკავშირებას.",
		"wifi_no_room": "Wi-Fi კავშირი ჯერ არ მოიძებნა. დატოვე ეს ეკრანი ღია.",
		"wifi_no_room_list": "Wi-Fi კავშირი ჯერ არ მოიძებნა",
		"wifi_connection_item": "%s - Wi-Fi კავშირი",
		"room_players": "%s - %d/%d მოთამაშე"
	}
}
const ONLINE_TUTORIAL_STEPS := {
	LANG_ENG: [
		"Wi-Fi is for players on the same network.",
		"Steam Friend keeps the Steam lobby flow for Steam players.",
		"For Wi-Fi, start a connection and nearby players can find it automatically.",
		"For Steam, open rooms appear automatically. Select one and press Join.",
		"Both players choose different characters. The match starts by itself.",
		"The server player can leave to menu and press Return to Game to rejoin."
	],
	LANG_GEO: [
		"Wi-Fi არის ერთსა და იმავე ქსელში მოთამაშეებისთვის.",
		"სტიმ მეგობარი ინარჩუნებს სტიმ ლობის სისტემას სტიმ მოთამაშეებისთვის.",
		"Wi-Fi-ში დაიწყე კავშირი და ახლომდებარე მოთამაშეები ავტომატურად იპოვიან.",
		"სტიმში ღია ოთახები ავტომატურად გამოჩნდება. აირჩიე ოთახი და დააჭირე შესვლას.",
		"ორივე მოთამაშე ირჩევს განსხვავებულ პერსონაჟს. მატჩი თვითონ იწყება.",
		"სერვერის მოთამაშეს შეუძლია მენიუში გასვლა და თამაშში დაბრუნებით დაბრუნება."
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
@onready var home_map_button: Button = $Content/Root/Pages/Home/MapButton
@onready var home_choose_button: Button = $Content/Root/Pages/Home/ChooseButton
@onready var home_online_button: Button = $Content/Root/Pages/Home/OnlineButton
@onready var home_how_to_play_button: Button = $Content/Root/Pages/Home/HowToPlayButton
@onready var home_credits_button: Button = $Content/Root/Pages/Home/CreditsButton
@onready var home_exit_button: Button = $Content/Root/Pages/Home/ExitButton
@onready var easy_button: Button = $Content/Root/Pages/ChooseLevel/MapCards/EasyButton
@onready var medium_button: Button = $Content/Root/Pages/ChooseLevel/MapCards/MediumButton
@onready var hard_button: Button = $Content/Root/Pages/ChooseLevel/MapCards/HardButton
@onready var easy_map_label: Label = $Content/Root/Pages/ChooseLevel/MapCards/EasyButton/Title
@onready var medium_map_label: Label = $Content/Root/Pages/ChooseLevel/MapCards/MediumButton/Title
@onready var hard_map_label: Label = $Content/Root/Pages/ChooseLevel/MapCards/HardButton/Title
@onready var map_title_label: Label = $Content/Root/Pages/ChooseLevel/MapTitle
@onready var map_gallery_hint: Label = $Content/Root/Pages/ChooseLevel/GalleryHint
@onready var level_back_button: Button = $Content/Root/Pages/ChooseLevel/BackButton
@onready var choose_header: Label = $Content/Root/Pages/ChooseCharacter/Header
@onready var wallet_label: Label = $Content/Root/Pages/ChooseCharacter/WalletLabel
@onready var player_card: PanelContainer = $Content/Root/Pages/ChooseCharacter/Cards/PlayerCard
@onready var golem_card: PanelContainer = $Content/Root/Pages/ChooseCharacter/Cards/GolemCard
@onready var ice_golem_card: PanelContainer = $Content/Root/Pages/ChooseCharacter/Cards/IceGolemCard
@onready var player_select_button: Button = $Content/Root/Pages/ChooseCharacter/Cards/PlayerCard/Box/SelectButton
@onready var golem_select_button: Button = $Content/Root/Pages/ChooseCharacter/Cards/GolemCard/Box/SelectButton
@onready var ice_golem_select_button: Button = $Content/Root/Pages/ChooseCharacter/Cards/IceGolemCard/Box/SelectButton
@onready var character_status: Label = $Content/Root/Pages/ChooseCharacter/StatusLabel
@onready var choose_start_button: Button = $Content/Root/Pages/ChooseCharacter/StartButton
@onready var choose_online_button: Button = $Content/Root/Pages/ChooseCharacter/OnlineButton
@onready var choose_back_button: Button = $Content/Root/Pages/ChooseCharacter/BackButton
@onready var how_to_play_header: Label = $Content/Root/Pages/HowToPlay/Header
@onready var how_to_play_instructions: Label = $Content/Root/Pages/HowToPlay/Instructions
@onready var how_attack_label: Label = $Content/Root/Pages/HowToPlay/Cards/AttackCard/Text
@onready var how_kick_label: Label = $Content/Root/Pages/HowToPlay/Cards/KickCard/Text
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
@onready var wifi_mode_button: Button = $Content/Root/Pages/Online/ModeButtons/WifiButton
@onready var steam_mode_button: Button = $Content/Root/Pages/Online/ModeButtons/SteamButton
@onready var online_address_box: Control = $Content/Root/Pages/Online/AddressBox
@onready var online_address_input: LineEdit = $Content/Root/Pages/Online/AddressBox/AddressInput
@onready var room_name_input: LineEdit = $Content/Root/Pages/Online/RoomNameInput
@onready var room_name_hint: Label = $Content/Root/Pages/Online/RoomNameHint
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
var online_connection_mode := ONLINE_MODE_WIFI
var wifi_rooms: Array = []
var wifi_room_seen_at := {}
var wifi_discovery_listener: PacketPeerUDP
var wifi_discovery_broadcaster: PacketPeerUDP
var wifi_discovery_timer := 0.0
var level_select_starts_game := false
var level_page_preview_only := false
var level_start_pending := false
var hovered_level := ""


func _ready() -> void:
	_setup_language()
	language_button.pressed.connect(_toggle_language)
	home_start_button.pressed.connect(_open_start_flow)
	home_map_button.pressed.connect(_open_map_select_from_home)
	home_choose_button.pressed.connect(func(): _show_page(choose_page))
	home_online_button.pressed.connect(_open_online_page)
	home_how_to_play_button.pressed.connect(func(): _show_page(how_to_play_page))
	home_credits_button.pressed.connect(func(): _show_page(credits_page))
	home_exit_button.pressed.connect(_exit_game)
	easy_button.pressed.connect(func(): _select_level("easy"))
	medium_button.pressed.connect(func(): _select_level("medium"))
	hard_button.pressed.connect(func(): _select_level("hard"))
	_connect_map_card_hover(easy_button, "easy")
	_connect_map_card_hover(medium_button, "medium")
	_connect_map_card_hover(hard_button, "hard")
	level_back_button.pressed.connect(func(): _show_page(home_page))
	player_select_button.pressed.connect(func(): _select_character("player"))
	golem_select_button.pressed.connect(func(): _select_character("golem"))
	ice_golem_select_button.pressed.connect(func(): _select_character("ice_golem"))
	_make_character_card_tappable(player_card, "player")
	_make_character_card_tappable(golem_card, "golem")
	_make_character_card_tappable(ice_golem_card, "ice_golem")
	player_select_button.visible = true
	golem_select_button.visible = true
	ice_golem_select_button.visible = true
	choose_start_button.pressed.connect(_open_level_select_from_character)
	choose_online_button.pressed.connect(_open_online_page)
	choose_back_button.pressed.connect(_back_from_character_page)
	how_to_play_back_button.pressed.connect(func(): _show_page(home_page))
	credits_back_button.pressed.connect(func(): _show_page(home_page))
	wifi_mode_button.pressed.connect(func(): _set_online_connection_mode(ONLINE_MODE_WIFI))
	steam_mode_button.pressed.connect(func(): _set_online_connection_mode(ONLINE_MODE_STEAM))
	host_button.pressed.connect(_host_online_game)
	join_button.pressed.connect(_join_online_game)
	lobby_select.item_activated.connect(func(_index: int): _join_online_game())
	online_start_button.pressed.connect(_start_online_host_game)
	online_tutorial_next.pressed.connect(_advance_online_tutorial)
	online_tutorial_skip.pressed.connect(_finish_online_tutorial)
	online_tutorial_back.pressed.connect(_back_from_online)
	online_back_button.pressed.connect(_back_from_online)
	online_address_box.visible = false
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_connect_steam_manager()
	var settings := _settings()
	if settings and settings.has_signal("saved_coins_changed"):
		settings.saved_coins_changed.connect(func(_saved_coins: int): _update_character_cards())
	_apply_language()
	_update_character_cards()
	_update_online_room_text()
	_update_lobby_select()
	online_start_button.visible = false
	_update_room_buttons()
	_show_page(home_page)


func _process(delta: float) -> void:
	if wifi_discovery_broadcaster:
		_process_wifi_discovery(delta)
	if not online_page or not online_page.visible:
		return
	if online_connection_mode == ONLINE_MODE_WIFI:
		if not wifi_discovery_broadcaster:
			_process_wifi_discovery(delta)
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
	home_map_button.text = _t("map")
	home_choose_button.text = _t("choose_character")
	home_online_button.text = _t("online_room")
	home_how_to_play_button.text = _t("how_to_play")
	home_credits_button.text = _t("credits")
	home_exit_button.text = _t("exit")
	easy_button.tooltip_text = _t("easy")
	medium_button.tooltip_text = _t("medium")
	hard_button.tooltip_text = _t("hard")
	map_title_label.text = _t("choose_your_map")
	easy_map_label.text = _t("easy")
	medium_map_label.text = _t("medium")
	hard_map_label.text = _t("hard")
	map_gallery_hint.text = _t("map_gallery_hint")
	level_back_button.text = _t("back")
	choose_header.text = _t("choose_character")
	player_select_button.text = _t("select")
	golem_select_button.text = _t("select")
	ice_golem_select_button.text = _ice_golem_button_text()
	if wallet_label:
		wallet_label.text = _t("coins") % _saved_coins()
	choose_start_button.text = _t("start_game")
	choose_online_button.text = _t("online_room")
	choose_back_button.text = _t("back")
	how_to_play_header.text = _t("how_to_play")
	how_to_play_instructions.text = _t("how_to_play_text")
	how_attack_label.text = _t("how_attack")
	how_kick_label.text = _t("how_kick")
	how_heart_label.text = _t("how_heart")
	how_jump_label.text = _t("how_jump")
	how_to_play_back_button.text = _t("back")
	credits_header.text = _t("credits")
	credits_text.text = _t("credits_text")
	credits_back_button.text = _t("back")
	online_header.text = _t("online_room")
	wifi_mode_button.text = _t("wifi_multiplayer")
	steam_mode_button.text = _t("steam_friend")
	online_address_input.placeholder_text = _t("wifi_address_placeholder")
	room_name_hint.text = _t("room_name_hint")
	_apply_default_connection_name()
	_update_online_action_button_text()
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


func _apply_default_connection_name() -> void:
	if not room_name_input:
		return
	var current_name := room_name_input.text.strip_edges()
	var default_names := [TEXT[LANG_ENG].get("default_connection_name", "Silent City"), TEXT[LANG_GEO].get("default_connection_name", "ჩუმი ქალაქი"), "Silent City"]
	if current_name.is_empty() or default_names.has(current_name):
		room_name_input.text = _t("default_connection_name")


func _exit_game() -> void:
	_clear_peer()
	get_tree().quit()


func _open_online_page() -> void:
	_sync_online_state_with_peer()
	_update_online_room_text()
	_show_page(online_page)
	if online_connection_mode == ONLINE_MODE_STEAM:
		_request_steam_lobbies(true)
	else:
		_start_wifi_listener()
	_show_online_tutorial_once()


func _set_online_connection_mode(mode: String) -> void:
	if _is_hosting_room() or _is_joining_room():
		_update_online_mode_ui()
		return
	online_connection_mode = ONLINE_MODE_STEAM if mode == ONLINE_MODE_STEAM else ONLINE_MODE_WIFI
	steam_lobbies.clear()
	wifi_rooms.clear()
	wifi_room_seen_at.clear()
	steam_lobby_searching = false
	steam_lobby_wide_searching = false
	_stop_wifi_discovery()
	_update_online_room_text()
	if online_page and online_page.visible and online_connection_mode == ONLINE_MODE_STEAM:
		_request_steam_lobbies(true)
	elif online_page and online_page.visible:
		_start_wifi_listener()


func _update_online_mode_ui() -> void:
	if wifi_mode_button:
		wifi_mode_button.button_pressed = false
	if steam_mode_button:
		steam_mode_button.button_pressed = false
	if online_address_box:
		online_address_box.visible = false

func _open_start_flow() -> void:
	var settings := _settings()
	if settings:
		settings.set("character_chosen", false)
		settings.set("level_chosen", false)
	level_page_preview_only = false
	level_select_starts_game = false
	level_start_pending = false
	map_gallery_hint.visible = false
	_update_map_cards()
	_update_character_cards()
	_show_page(choose_page)


func _open_map_select_from_home() -> void:
	level_page_preview_only = true
	level_select_starts_game = false
	level_start_pending = false
	map_gallery_hint.visible = true
	_update_map_cards()
	_show_page(level_page)


func _select_level(level: String) -> void:
	if level_page_preview_only:
		map_gallery_hint.text = _t("map_gallery_hint")
		return
	if level_start_pending:
		return

	var settings := _settings()
	if settings:
		settings.set("selected_level", level)
		settings.set("level_chosen", true)
	_update_map_cards(level)
	if level_select_starts_game:
		level_start_pending = true
		map_gallery_hint.visible = true
		map_gallery_hint.text = _t("map_selected_wait") % _level_display_name(level)
		await get_tree().create_timer(2.0).timeout
		level_start_pending = false
		_start_game()
		return
	_show_page(choose_page)


func _connect_map_card_hover(button: Button, level: String) -> void:
	button.mouse_entered.connect(func():
		hovered_level = level
		_update_map_cards()
	)
	button.mouse_exited.connect(func():
		if hovered_level == level:
			hovered_level = ""
		_update_map_cards()
	)
	button.focus_entered.connect(func():
		hovered_level = level
		_update_map_cards()
	)
	button.focus_exited.connect(func():
		if hovered_level == level:
			hovered_level = ""
		_update_map_cards()
	)


func _update_map_cards(forced_selected_level: String = "") -> void:
	var selected_level := forced_selected_level
	var settings := _settings()
	if selected_level.is_empty() and settings and settings.get("level_chosen") == true:
		selected_level = String(settings.get("selected_level"))
	for level in ["easy", "medium", "hard"]:
		var button := _map_button(level)
		if not button:
			continue
		if level == selected_level:
			button.modulate = Color(0.72, 1.0, 0.72, 1.0)
		elif level == hovered_level:
			button.modulate = Color(1.18, 1.18, 1.18, 1.0)
		else:
			button.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _map_button(level: String) -> Button:
	match level:
		"medium":
			return medium_button
		"hard":
			return hard_button
		_:
			return easy_button


func _level_display_name(level: String) -> String:
	match level:
		"medium":
			return _t("medium")
		"hard":
			return _t("hard")
		_:
			return _t("easy")


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
		if String(settings.get("online_role")) == "host":
			_open_playable_level_select()
			return
		_start_game()
		return
	_open_playable_level_select()


func _open_playable_level_select() -> void:
	var settings := _settings()
	if settings:
		settings.set("level_chosen", false)
	level_page_preview_only = false
	level_start_pending = false
	level_select_starts_game = true
	map_gallery_hint.visible = false
	_update_map_cards()
	_show_page(level_page)


func _select_character(character: String) -> void:
	if _is_online_character_locked():
		return
	if not _is_character_unlocked(character):
		var character_name := String(CHARACTER_DISPLAY_NAMES.get(character, "Ice Golem"))
		var unlock_cost := _character_unlock_cost(character)
		character_status.text = _t("character_locked") % [character_name, unlock_cost, _saved_coins()]
		_update_character_cards()
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
	if not _is_character_unlocked(character):
		_select_character(character)
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
	if wallet_label:
		wallet_label.text = _t("coins") % _saved_coins()
	for character in ["player", "golem", "ice_golem"]:
		var card := _character_card(character)
		if not card:
			continue
		card.modulate = Color(1.0, 1.0, 1.0)
		_set_card_crossed(card, false)
		_set_character_card_available(card, _is_character_unlocked(character))
	_set_ice_golem_button_text()
	if joined_room_waiting_for_character and other_player_character_chosen:
		var taken_card := _character_card(other_player_character)
		if taken_card:
			taken_card.modulate = Color(0.45, 0.45, 0.45)
			_set_card_crossed(taken_card, true)
			_set_character_card_available(taken_card, false)
	var settings := _settings()
	if not settings or settings.get("character_chosen") != true:
		character_status.text = _t("choose_first")
		_set_character_buttons_enabled(true)
		_apply_taken_character_input_state()
		return
	var selected_card := _character_card(String(settings.get("selected_character")))
	if selected_card:
		selected_card.modulate = Color(0.65, 1.0, 0.65)
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


func _valid_online_scene_path(scene_path: String) -> String:
	match scene_path:
		MAIN_SCENE, MEDIUM_SCENE, HARD_SCENE:
			return scene_path
	return MAIN_SCENE


func _level_for_scene_path(scene_path: String) -> String:
	match _valid_online_scene_path(scene_path):
		HARD_SCENE:
			return "hard"
		MEDIUM_SCENE:
			return "medium"
	return "easy"


func _store_online_scene_path(scene_path: String) -> String:
	var valid_scene_path := _valid_online_scene_path(scene_path)
	var settings := _settings()
	if settings:
		settings.set("online_scene_path", valid_scene_path)
		settings.set("selected_level", _level_for_scene_path(valid_scene_path))
		settings.set("level_chosen", true)
	return valid_scene_path


func _online_scene_path_from_settings() -> String:
	var settings := _settings()
	if settings:
		return _valid_online_scene_path(String(settings.get("online_scene_path")))
	return MAIN_SCENE


func _pending_lobby_scene_path() -> String:
	return _valid_online_scene_path(String(pending_join_lobby.get("scene_path", MAIN_SCENE)))


func _host_online_game() -> void:
	if _is_hosting_room():
		online_status.text = _t("hosting_active")
		get_tree().change_scene_to_file(_online_scene_path_from_settings())
		return

	if online_connection_mode == ONLINE_MODE_WIFI:
		_host_wifi_game()
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


func _host_wifi_game() -> void:
	_clear_peer()
	steam_lobbies.clear()
	_update_lobby_select()
	online_status.text = _t("wifi_creating_room")
	host_button.disabled = true
	join_button.disabled = true
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(ONLINE_PORT, MAX_ROOM_PLAYERS - 1)
	if error != OK:
		online_status.text = _t("host_failed") % _error_message(error)
		_update_room_buttons()
		return
	_start_wifi_broadcaster()
	_prepare_online_host(peer)


func _finish_steam_host_lobby(_lobby_id: int) -> void:
	if online_connection_mode != ONLINE_MODE_STEAM:
		return
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
	wifi_rooms.clear()
	wifi_room_seen_at.clear()
	_update_lobby_select()
	_set_online_status_with_player_line(_online_room_open_text())
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
		_set_online_status_with_player_line(_online_room_waiting_text())
		return
	if not remote_client_character_chosen:
		character_status.text = _t("waiting_for_player_choice")
		online_status.text = _t("waiting_for_player_choice")
		return
	if settings.get("level_chosen") != true:
		character_status.text = _t("choose_map_to_start")
		online_status.text = _t("choose_map_to_start")
		_open_playable_level_select()
		return

	online_match_starting = true
	joined_room_waiting_for_character = false
	var host_character := String(settings.get("selected_character"))
	var scene_path := _store_online_scene_path(_selected_main_scene())
	var steam_manager := _steam_manager()
	if steam_manager and steam_manager.has_method("set_lobby_match_state"):
		steam_manager.set_lobby_match_state("playing", host_character, remote_client_character, scene_path)
	character_status.text = _t("both_ready")
	online_status.text = _t("both_ready")
	online_start_button.visible = false
	_update_room_buttons()
	_sync_online_character_state()
	rpc("_start_online_match", scene_path)
	get_tree().change_scene_to_file(scene_path)


func _join_online_game() -> void:
	if _is_hosting_room():
		online_status.text = _t("hosting_device")
		return

	if online_connection_mode == ONLINE_MODE_WIFI:
		_join_wifi_game()
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


func _join_wifi_game() -> void:
	if wifi_rooms.is_empty():
		online_status.text = _t("invalid_address")
		_start_wifi_listener()
		return
	var selected_items := lobby_select.get_selected_items()
	var selected_index := int(selected_items[0]) if not selected_items.is_empty() else 0
	if selected_index >= wifi_rooms.size():
		selected_index = 0
	var room = wifi_rooms[selected_index]
	var ip := String(room.get("ip", "")).strip_edges()
	if ip.is_empty():
		online_status.text = _t("invalid_address")
		return

	_clear_peer()
	pending_join_lobby.clear()
	var settings := _settings()
	if settings:
		settings.set("online_mode", true)
		settings.set("online_role", "client")
		settings.set("character_chosen", false)
		if settings.has_method("reset_online_rounds"):
			settings.reset_online_rounds()
	remote_client_character = "golem"
	remote_client_character_chosen = false
	other_player_character = ""
	other_player_character_chosen = false
	online_match_starting = false
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip, int(room.get("port", ONLINE_PORT)))
	if error != OK:
		online_status.text = _t("join_failed") % _error_message(error)
		if settings:
			settings.call("reset_online")
		_update_room_buttons()
		return
	multiplayer.multiplayer_peer = peer
	online_status.text = _t("joining")
	_update_room_buttons()


func _prepare_join_selected_lobby(lobby_data: Dictionary) -> void:
	_clear_peer()
	pending_join_lobby = lobby_data.duplicate(true)
	var settings := _settings()
	if settings:
		settings.set("online_mode", true)
		settings.set("online_role", "client")
		if _is_pending_join_lobby_playing():
			_store_online_scene_path(_pending_lobby_scene_path())
			var saved_client_character := String(pending_join_lobby.get("client_character", "")).strip_edges()
			var saved_host_character := String(pending_join_lobby.get("host_character", "")).strip_edges()
			if saved_client_character in ["player", "golem", "ice_golem"]:
				settings.set("selected_character", saved_client_character)
			settings.set("character_chosen", true)
			if saved_host_character in ["player", "golem", "ice_golem"]:
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
	if online_connection_mode != ONLINE_MODE_STEAM:
		return
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
		get_tree().change_scene_to_file(_store_online_scene_path(_pending_lobby_scene_path()))
	else:
		online_status.text = _t("joining")


func _on_steam_lobby_list_updated(lobbies: Array) -> void:
	steam_lobby_searching = false
	if online_connection_mode != ONLINE_MODE_STEAM:
		return
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
			get_tree().change_scene_to_file(_store_online_scene_path(_pending_lobby_scene_path()))
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
		_set_online_status_with_player_line(_t("player_connected"))
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
		_set_online_status_with_player_line(_online_room_waiting_text())
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
	if online_connection_mode == ONLINE_MODE_WIFI and online_page and online_page.visible:
		_start_wifi_listener()
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
	wifi_rooms.clear()
	wifi_room_seen_at.clear()
	_stop_wifi_discovery()
	_update_lobby_select()
	online_status.text = _online_default_status_text()
	_update_room_buttons()
	_show_page(home_page)


func _update_online_room_text() -> void:
	_sync_online_state_with_peer()
	_update_online_mode_ui()
	_update_lobby_select()
	_set_online_status_with_player_line(_online_default_status_text())
	_update_room_buttons()


func _request_steam_lobbies(show_search_text: bool, wide_search: bool = false) -> void:
	if online_connection_mode != ONLINE_MODE_STEAM or steam_lobby_searching or not _steam_ready() or _is_hosting_room() or _is_joining_room():
		return
	steam_lobby_searching = true
	steam_lobby_wide_searching = wide_search
	if show_search_text:
		online_status.text = _t("steam_finding_lobby")
	_steam_manager().request_lobbies(wide_search)


func _start_wifi_listener() -> void:
	if wifi_discovery_listener:
		return
	wifi_discovery_listener = PacketPeerUDP.new()
	var error := wifi_discovery_listener.bind(WIFI_DISCOVERY_PORT)
	if error != OK:
		wifi_discovery_listener = null
		online_status.text = _t("wifi_no_room")
		return
	wifi_discovery_timer = 0.0


func _start_wifi_broadcaster() -> void:
	_stop_wifi_listener()
	if wifi_discovery_broadcaster:
		return
	wifi_discovery_broadcaster = PacketPeerUDP.new()
	wifi_discovery_broadcaster.set_broadcast_enabled(true)
	wifi_discovery_broadcaster.set_dest_address("255.255.255.255", WIFI_DISCOVERY_PORT)
	wifi_discovery_timer = 0.0


func _stop_wifi_listener() -> void:
	if wifi_discovery_listener:
		wifi_discovery_listener.close()
	wifi_discovery_listener = null


func _stop_wifi_discovery() -> void:
	_stop_wifi_listener()
	if wifi_discovery_broadcaster:
		wifi_discovery_broadcaster.close()
	wifi_discovery_broadcaster = null


func _process_wifi_discovery(delta: float) -> void:
	if wifi_discovery_broadcaster:
		wifi_discovery_timer -= delta
		if wifi_discovery_timer <= 0.0:
			wifi_discovery_timer = WIFI_DISCOVERY_INTERVAL
			_broadcast_wifi_room()
	if wifi_discovery_listener:
		_read_wifi_discovery_packets()
		_prune_wifi_rooms()


func _broadcast_wifi_room() -> void:
	if not wifi_discovery_broadcaster:
		return
	var payload := {
		"tag": WIFI_DISCOVERY_TAG,
		"name": _room_name(),
		"port": ONLINE_PORT,
		"players": min(multiplayer.get_peers().size() + 1, MAX_ROOM_PLAYERS),
		"max_players": MAX_ROOM_PLAYERS,
	}
	wifi_discovery_broadcaster.put_packet(JSON.stringify(payload).to_utf8_buffer())


func _read_wifi_discovery_packets() -> void:
	while wifi_discovery_listener and wifi_discovery_listener.get_available_packet_count() > 0:
		var packet := wifi_discovery_listener.get_packet()
		var text := packet.get_string_from_utf8()
		var parsed = JSON.parse_string(text)
		if not (parsed is Dictionary):
			continue
		var data = parsed
		if String(data.get("tag", "")) != WIFI_DISCOVERY_TAG:
			continue
		var ip := wifi_discovery_listener.get_packet_ip()
		if ip.is_empty():
			continue
		var room := {
			"id": ip,
			"name": String(data.get("name", ROOM_NAME)),
			"ip": ip,
			"port": int(data.get("port", ONLINE_PORT)),
			"players": int(data.get("players", 1)),
			"max_players": int(data.get("max_players", MAX_ROOM_PLAYERS)),
		}
		_upsert_wifi_room(room)


func _upsert_wifi_room(room: Dictionary) -> void:
	var id := String(room.get("id", ""))
	if id.is_empty():
		return
	wifi_room_seen_at[id] = Time.get_ticks_msec()
	for index in wifi_rooms.size():
		var existing_room = wifi_rooms[index]
		if String(existing_room.get("id", "")) == id:
			wifi_rooms[index] = room
			_update_lobby_select()
			_update_wifi_search_status()
			_update_room_buttons()
			return
	wifi_rooms.append(room)
	_update_lobby_select()
	_update_wifi_search_status()
	_update_room_buttons()


func _prune_wifi_rooms() -> void:
	var now := Time.get_ticks_msec()
	var changed := false
	for index in range(wifi_rooms.size() - 1, -1, -1):
		var room = wifi_rooms[index]
		var id := String(room.get("id", ""))
		var last_seen := int(wifi_room_seen_at.get(id, 0))
		if now - last_seen > int(WIFI_DISCOVERY_TIMEOUT * 1000.0):
			wifi_rooms.remove_at(index)
			wifi_room_seen_at.erase(id)
			changed = true
	if changed:
		_update_lobby_select()
		_update_wifi_search_status()
		_update_room_buttons()


func _update_wifi_search_status() -> void:
	if not online_page or not online_page.visible or online_connection_mode != ONLINE_MODE_WIFI:
		return
	if _is_hosting_room() or _is_joining_room():
		return
	online_status.text = _t("wifi_room_found") if not wifi_rooms.is_empty() else _t("wifi_no_room")


func _online_default_status_text() -> String:
	return _t("steam_status_default") if online_connection_mode == ONLINE_MODE_STEAM else _t("wifi_status_default")


func _online_room_open_text() -> String:
	return _t("steam_room_open") if online_connection_mode == ONLINE_MODE_STEAM else _t("wifi_room_open")


func _online_room_waiting_text() -> String:
	return _t("steam_room_waiting") if online_connection_mode == ONLINE_MODE_STEAM else _t("wifi_room_waiting")


func _clear_peer() -> void:
	_stop_wifi_discovery()
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
	if online_connection_mode == ONLINE_MODE_WIFI:
		if wifi_rooms.is_empty():
			lobby_select.visible = true
			lobby_select.mouse_filter = Control.MOUSE_FILTER_IGNORE
			lobby_select.add_item(_t("wifi_no_room_list"))
			return
		lobby_select.visible = true
		lobby_select.mouse_filter = Control.MOUSE_FILTER_STOP
		for index in wifi_rooms.size():
			var room = wifi_rooms[index]
			var room_name := String(room.get("name", ROOM_NAME))
			lobby_select.add_item(_t("wifi_connection_item") % room_name)
		lobby_select.select(0)
		return
	if steam_lobbies.is_empty():
		lobby_select.visible = false
		lobby_select.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	lobby_select.visible = true
	lobby_select.mouse_filter = Control.MOUSE_FILTER_STOP
	for index in steam_lobbies.size():
		var lobby = steam_lobbies[index]
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
	return room_name if not room_name.is_empty() else _t("default_connection_name")


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
	if online_connection_mode == ONLINE_MODE_STEAM and online_page and online_page.visible:
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

	_sync_online_state_with_peer()
	_update_online_mode_ui()
	var hosting := _is_hosting_room()
	var joining := _is_joining_room()
	var has_peer := multiplayer.multiplayer_peer != null
	host_button.disabled = joining
	_update_online_action_button_text()
	if online_connection_mode == ONLINE_MODE_STEAM:
		join_button.disabled = hosting or steam_lobbies.is_empty() or (joining and has_peer)
	else:
		join_button.disabled = hosting or wifi_rooms.is_empty() or (joining and has_peer)
	online_start_button.visible = false
	online_start_button.disabled = true


func _update_online_action_button_text() -> void:
	if not host_button or not join_button:
		return
	if _is_hosting_room():
		host_button.text = _t("return_to_match")
	else:
		host_button.text = _t("host_room") if online_connection_mode == ONLINE_MODE_STEAM else _t("wifi_create")
	join_button.text = _t("join") if online_connection_mode == ONLINE_MODE_STEAM else _t("wifi_join")


func _lock_online_character_selection() -> void:
	_set_character_buttons_enabled(false)


func _set_character_buttons_enabled(enabled: bool) -> void:
	for character in ["player", "golem", "ice_golem"]:
		var card := _character_card(character)
		var select_button := _character_select_button(character)
		var available := enabled and _is_character_unlocked(character)
		if select_button:
			select_button.disabled = not available
		if card:
			card.mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE
	_set_ice_golem_button_text()


func _set_character_card_available(card: Control, available: bool) -> void:
	var select_button := card.get_node_or_null("Box/SelectButton") as Button
	if select_button:
		select_button.disabled = not available
	card.mouse_filter = Control.MOUSE_FILTER_STOP if available else Control.MOUSE_FILTER_IGNORE


func _apply_taken_character_input_state() -> void:
	if not joined_room_waiting_for_character or not other_player_character_chosen:
		return
	var card := _character_card(other_player_character)
	if card:
		_set_character_card_available(card, false)


func _character_card(character: String) -> PanelContainer:
	match character:
		"golem":
			return golem_card
		"ice_golem":
			return ice_golem_card
		_:
			return player_card


func _character_select_button(character: String) -> Button:
	match character:
		"golem":
			return golem_select_button
		"ice_golem":
			return ice_golem_select_button
		_:
			return player_select_button


func _saved_coins() -> int:
	var settings := _settings()
	if settings and settings.has_method("get_saved_coins"):
		return int(settings.call("get_saved_coins"))
	if settings:
		return int(settings.get("saved_coins"))
	return 0


func _character_unlock_cost(character: String) -> int:
	var settings := _settings()
	if settings and settings.has_method("get_character_unlock_cost"):
		return int(settings.call("get_character_unlock_cost", character))
	if character == "ice_golem":
		return ICE_GOLEM_UNLOCK_COINS
	return 0


func _is_character_unlocked(character: String) -> bool:
	var settings := _settings()
	if settings and settings.has_method("is_character_unlocked"):
		return bool(settings.call("is_character_unlocked", character))
	return _saved_coins() >= _character_unlock_cost(character)


func _ice_golem_button_text() -> String:
	if _is_character_unlocked("ice_golem"):
		return _t("select")
	return _t("locked") % [_saved_coins(), _character_unlock_cost("ice_golem")]


func _set_ice_golem_button_text() -> void:
	if ice_golem_select_button:
		ice_golem_select_button.text = _ice_golem_button_text()


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
	_set_online_status_with_player_line(_t("player_connected"))
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
func _start_online_match(scene_path: String = MAIN_SCENE) -> void:
	var settings := _settings()
	if settings:
		settings.set("character_chosen", true)
	joined_room_waiting_for_character = false
	online_match_starting = true
	get_tree().change_scene_to_file(_store_online_scene_path(scene_path))


func _make_room_id() -> String:
	return "%d-%d" % [Time.get_ticks_msec(), randi()]


func _sync_online_state_with_peer() -> void:
	var settings := _settings()
	if not settings:
		return
	if settings.get("online_mode") != true:
		return
	if multiplayer.has_multiplayer_peer():
		return
	settings.call("reset_online")
	joined_room_waiting_for_character = false
	remote_client_character = "golem"
	remote_client_character_chosen = false
	other_player_character = ""
	other_player_character_chosen = false
	online_match_starting = false
	pending_join_lobby.clear()


func _set_online_status_with_player_line(base_text: String) -> void:
	if not online_status:
		return
	online_status.text = base_text


func _error_message(error: int) -> String:
	if error == ERR_CANT_CREATE:
		return "20 no network permission/port busy"
	return str(error)
