extends Control

const MAIN_MENU_CONTROLLER_PATH := "res://Scripts/Menus/main_menu/main_menu_controller.gd"
const DIFFICULTY_MENU_PATH := "res://Scripts/Menus/difficulty/difficulty_menu.gd"
const CHARACTER_MENU_PATH := "res://Scripts/Menus/choose_character/character_menu.gd"
const ONLINE_MENU_PATH := "res://Scripts/Menus/online/online_menu.gd"
const SETTINGS_MENU_PATH := "res://Scripts/Menus/settings/settings_menu.gd"

const MAIN_SCENE := "res://Scenes/main.tscn"
const SQUAD_SCENE := "res://Scenes/SquadArena.tscn"
const MEDIUM_SCENE := "res://Scenes/MainMedium.tscn"
const HARD_SCENE := "res://Scenes/MainHard.tscn"
const LANG_ENG := "eng"
const LANG_GEO := "geo"
const MAIN_MENU_BUTTON_SIZE := Vector2(320.0, 46.0)

const DIFFICULTY_CARD_SIZE := Vector2(190.0, 190.0)
const LANGUAGE_BUTTON_SIZE := Vector2(86.0, 36.0)

# Bottom-right community links. Replace STEAM_STORE_URL with the final app page
# once the Steam store listing has an app ID.
const COMMUNITY_BUTTON_SHEET := "res://Resources/Buttons/join_no_white.png"
const DISCORD_SERVER_URL := "https://discord.gg/DNUu88kwwd"
const STEAM_STORE_URL := "https://store.steampowered.com/search/?term=Silent%20City"
const COMMUNITY_ICON_SIZE := Vector2(104.0, 104.0)
const COMMUNITY_HOVER_SIZE := Vector2(208.0, 104.0)
const COMMUNITY_DOCK_MARGIN := 24.0
const COMMUNITY_DOCK_GAP := 12
const COMMUNITY_ICON_TINT := Color.WHITE

# ONLINE BACK:
# The previous online_back_button.png is the cropped asset.
# Reuse the complete Back sprite that already works on the Character page.

# -----------------------------------------------------------------------------
# MAIN TITLE / SUBTITLE PNG SETTINGS
# Change ONLY these paths to your PNG files.
# The PNGs should have transparent backgrounds.
# -----------------------------------------------------------------------------
const MENU_TITLE_PNG := "res://Resources/Buttons/Silent_City_fixed.png"
const MENU_SUBTITLE_ENG_PNG := "res://Resources/Buttons/Silent_City_Title.png"

# Use the same subtitle sprite for Georgian instead of falling back to text.
const MENU_SUBTITLE_GEO_PNG := MENU_SUBTITLE_ENG_PNG

# Main title/subtitle display sizes.
const MENU_TITLE_IMAGE_SIZE := Vector2(560.0, 105.0)
const MENU_SUBTITLE_IMAGE_SIZE := Vector2(420.0, 72.0)

# Runtime transparency cleanup used by the MAIN title/subtitle PNGs.
const MENU_ALPHA_BRIGHTNESS_THRESHOLD := 0.72
const MENU_ALPHA_NEUTRAL_TOLERANCE := 0.16

# -----------------------------------------------------------------------------
# MAIN MENU PERFORMANCE
# -----------------------------------------------------------------------------
# The menu cleans/crops several PNGs at runtime. Those operations scan image
# pixels and are expensive. The cache is stored on the persistent GameSettings
# autoload so returning from gameplay does NOT process all PNGs again.
const MENU_TEXTURE_CACHE_META := "_silent_city_menu_texture_cache_v1"

# -----------------------------------------------------------------------------
# FAST SINGLE-PLAYER START
# -----------------------------------------------------------------------------
# Load the three gameplay scenes in the background while the player is using
# the menu. This prevents synchronous scene loading from blocking the main
# thread for several seconds after selecting a difficulty.
const BACKGROUND_GAME_SCENES := [
	MAIN_SCENE,
	MEDIUM_SCENE,
	HARD_SCENE
]

const TEXT := {
	LANG_ENG: {
		"language_button": "GEO",
		"subtitle": "Choose your fight",
		"start": "Start",
		"story_mode": "Story Mode",
		"squad": "Squad",
		"choose_mode": "Choose Mode",
		"map": "Difficulty",
		"choose_your_map": "Choose Your Difficulty",
		"easy": "Easy",
		"medium": "Medium",
		"hard": "Hard",
		"map_gallery_hint": "Preview only. To play, go back and press Start from the main menu.",
		"map_selected_wait": "Selected: %s. You have to wait 2 seconds because there’s a cooldown xD",
		"choose_map_to_start": "Choose a map to start the match.",
		"choose_character": "Characters",
		"online_room": "Squad",
		"settings": "Settings",
		"audio": "Audio",
		"master_volume": "Master Volume",
		"graphics": "Graphics",
		"brightness": "Brightness",
		"fullscreen": "Fullscreen",
		"vsync": "VSync",
		"resolution": "Resolution",
		"apply": "Apply",
		"fps_limit": "FPS Limit",
		"renderer": "Renderer",
		"on": "On",
		"off": "Off",
		"unlimited": "Unlimited",
		"wifi_multiplayer": "WIFI",
		"steam_friend": "Steam Friend",
		"how_to_play": "How to Play",
		"how_to_play_text": "Move with Left/Right arrows.\nJump with Up Arrow.\nUse hands with A and foot kick with S.\nDefeat enemies, avoid spikes, and collect falling bonuses.",
		"how_attack": "Hands: A",
		"how_kick": "Foot: S",
		"how_jump": "Jump: Up Arrow",
		"how_defence_notice": "A shield will fall soon. Collect it for temporary defence.",
		"how_health_notice": "A health heart will fall soon. Collect it to heal.",
		"credits": "Credits",
		"credits_text": "Silent City\nCreated by Luka Guledani / SonnyRenderer\n\nCharacter and asset credits:\nKenney - Animated Characters Retro 1.1\nLicense: Creative Commons Zero (CC0)\nwww.kenney.nl\n\nGraveyard platform tileset\nGameArt2D / CraftPix freebie license\nhttps://www.gameart2d.com/free-graveyard-platformer-tileset.html\n\nQA/Testers:\n1. Giorgi Gugunava\n2. Nikoloz Lekishvili\n3. Iakob Janiashvili\n4. Discord/Sonny'sGaming server community\n\n[url=https://discord.gg/DNUu88kwwd]Join Discord Server[/url]\n\nThank you for playing.",
		"exit": "Exit",
		"select": "Select",
		"locked": "Locked %d/%d",
		"coins": "Coins: %d",
		"character_locked": "%s unlocks at %d coins. You have %d.",
		"choose_first": "Choose a character before starting.",
		"start_game": "Start Game",
		"back": "Back",
		"host_room": "Create Room",
		"wifi_create": "Start WiFi",
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
		"story_mode": "სიუჟეტური რეჟიმი",
		"squad": "რაზმი",
		"choose_mode": "აირჩიე რეჟიმი",
		"map": "სირთულე",
		"choose_your_map": "აირჩიე სირთულე",
		"easy": "მარტივი",
		"medium": "საშუალო",
		"hard": "რთული",
		"map_gallery_hint": "ეს მხოლოდ სირთულის ნახვაა. სათამაშოდ დაბრუნდი მთავარ მენიუში და დააჭირე Start-ს.",
		"map_selected_wait": "არჩეულია: %s. უნდა დაელოდო 2 წამი, იმიტომ რომ ლოდინის დრო აქვს xD",
		"choose_map_to_start": "აირჩიე სიძლიერე, რომ მატჩი დაიწყოს.",
		"choose_character": "აირჩიე პერსონაჟი",
		"online_room": "ონლაინი",
		"settings": "პარამეტრები",
		"audio": "ხმა",
		"master_volume": "მთავარი ხმა",
		"graphics": "გრაფიკა",
		"brightness": "სიკაშკაშე",
		"fullscreen": "სრული ეკრანი",
		"vsync": "VSync",
		"resolution": "რეზოლუცია",
		"apply": "გამოყენება",
		"fps_limit": "FPS ლიმიტი",
		"renderer": "რენდერი",
		"on": "ჩართული",
		"off": "გამორთული",
		"unlimited": "ულიმიტო",
		"wifi_multiplayer": "ვაიფაი",
		"steam_friend": "სტიმ მეგობარი",
		"how_to_play": "როგორ ვითამაშოთ",
		"how_to_play_text": "მოძრაობა: მარცხენა/მარჯვენა ისრები.\nახტომა: Up Arrow.\nხელით დარტყმა: A, ფეხით: S.\nდაამარცხე მტრები, მოერიდე ეკლებს და აიღე ბონუსები.",
		"how_attack": "ხელები: A",
		"how_kick": "ფეხი: S",
		"how_jump": "ახტომა: Up Arrow",
		"how_defence_notice": "ფარი ჩამოვარდება. აიღე დაცვისთვის.",
		"how_health_notice": "გული ჩამოვარდება. აიღე სიცოცხლისთვის.",
		"credits": "კრედიტები",
		"credits_text": "Silent City\nშექმნა: Luka Guledani / SonnyRenderer\n\nპერსონაჟებისა და ასეტების კრედიტები:\nKenney - Animated Characters Retro 1.1\nლიცენზია: Creative Commons Zero (CC0)\nwww.kenney.nl\n\nGraveyard platform tileset\nGameArt2D / CraftPix freebie license\nhttps://www.gameart2d.com/free-graveyard-platformer-tileset.html\n\nQA/ტესტერები:\n1. Giorgi Gugunava\n2. Iakob Janiashvili\n3. Discord/Sonny'sGaming server community\n\n[url=https://discord.gg/DNUu88kwwd]Discord სერვერზე შესვლა[/url]\n\nმადლობა თამაშისთვის.",
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
@onready var pages: Control = $Content/Root/Pages
@onready var language_button: Button = $LanguageButton
@onready var subtitle_label: Label = $Content/Root/Subtitle

# The original scene already contains the text title. We find it at runtime
# and draw the PNG inside the same UI slot, so you do NOT need to rebuild
# the scene tree.
var menu_title_label: Label = null
var menu_title_image: TextureRect = null
var menu_subtitle_image: TextureRect = null

# Character-select header.

# Points to a persistent Dictionary stored on /root/GameSettings.
# It survives MainMenu scene destruction/recreation while gameplay is running.
var menu_texture_cache: Dictionary = {}

# Native C++ GDExtension helper. Owns the complete runtime texture pipeline.
var menu_optimizer = null
@onready var home_page: VBoxContainer = $Content/Root/Pages/Home
@onready var level_page: VBoxContainer = $Content/Root/Pages/ChooseLevel
@onready var choose_page: VBoxContainer = $Content/Root/Pages/ChooseCharacter
@onready var online_page: VBoxContainer = $Content/Root/Pages/Online

@onready var home_start_button: Button = $Content/Root/Pages/Home/StartButton
@onready var mode_page: VBoxContainer = $Content/Root/Pages/ModeSelect
@onready var mode_story_button: Button = $Content/Root/Pages/ModeSelect/StoryModeButton
@onready var mode_squad_button: Button = $Content/Root/Pages/ModeSelect/SquadButton
@onready var mode_back_button: Button = $Content/Root/Pages/ModeSelect/BackButton
@onready var home_map_button: Button = $Content/Root/Pages/Home/MapButton
@onready var home_choose_button: Button = $Content/Root/Pages/Home/ChooseButton
@onready var home_online_button: Button = $Content/Root/Pages/Home/OnlineButton
@onready var home_exit_button: Button = $Content/Root/Pages/Home/ExitButton
@onready var easy_button: Button = $Content/Root/Pages/ChooseLevel/MapCards/EasyButton
@onready var medium_button: Button = $Content/Root/Pages/ChooseLevel/MapCards/MediumButton
@onready var hard_button: Button = $Content/Root/Pages/ChooseLevel/MapCards/HardButton
@onready var squad_button: Button = $Content/Root/Pages/ChooseLevel/MapCards/SquadButton
@onready var easy_map_label: Label = $Content/Root/Pages/ChooseLevel/MapCards/EasyButton/Title
@onready var medium_map_label: Label = $Content/Root/Pages/ChooseLevel/MapCards/MediumButton/Title
@onready var hard_map_label: Label = $Content/Root/Pages/ChooseLevel/MapCards/HardButton/Title
@onready var map_title_label: Label = $Content/Root/Pages/ChooseLevel/MapTitle
@onready var map_gallery_hint: Label = $Content/Root/Pages/ChooseLevel/GalleryHint
@onready var level_back_button: Button = $Content/Root/Pages/ChooseLevel/BackButton

# Difficulty state/UI now lives in difficulty_menu.gd and is loaded lazily.
var difficulty_menu = null

# Character Select state/UI now lives in character_menu.gd and is loaded lazily.
var character_menu = null

# Online Wi-Fi/Steam state/UI now lives in online_menu.gd and is loaded lazily.
var online_menu = null

# Settings coordinator owns Settings/Audio/Graphics/Credits.
var settings_menu = null

# Kept only because the threaded gameplay scene loader clears this flag.
var level_start_pending := false

# Top-level Home / Settings navigation now lives in:
# res://Scripts/Menus/main_menu/main_menu_controller.gd
var main_menu_controller = null


func _ready() -> void:
	# Must be first because shared PNG cleanup uses this persistent cache.
	_attach_persistent_menu_texture_cache()
	menu_optimizer = MenuOptimizer.new()
	menu_optimizer.set_texture_cache(menu_texture_cache)

	_setup_language()
	_setup_menu_header_images()
	_setup_community_buttons()

	# Settings code is split out. Startup creates ONLY the visible Home
	# Settings button and applies saved Audio/Graphics preferences.
	_setup_settings_runtime()

	# Home-only artwork. Hidden Settings/Audio/Graphics/Credits sprites are
	# no longer processed during application startup.
	_apply_main_menu_button_sprites()

	language_button.pressed.connect(_toggle_language)

	_setup_main_menu_controller()

	var settings := _settings()
	if settings and settings.has_signal("saved_coins_changed"):
		settings.saved_coins_changed.connect(
			func(_saved_coins: int):
				_update_character_cards()
		)

	_apply_language()
	_show_page(home_page)


func _setup_community_buttons() -> void:
	# The generated sprite sheet contains a baked white/gray checkerboard.
	# Convert that connected neutral background to alpha before atlas slicing.
	var sheet: Texture2D = menu_optimizer.load_menu_texture(
		COMMUNITY_BUTTON_SHEET,
		0.68,
		0.20
	)
	if not sheet:
		push_warning("Community button sheet not found: " + COMMUNITY_BUTTON_SHEET)
		return

	# Build mipmaps for the cleaned runtime image so the thin frame details stay
	# smooth when the 512 px source regions are displayed at 104 px.
	var sheet_image := sheet.get_image()
	if sheet_image and not sheet_image.is_empty():
		sheet_image.generate_mipmaps()
		sheet = ImageTexture.create_from_image(sheet_image)

	var dock := HBoxContainer.new()
	dock.name = "CommunityLinks"
	dock.z_index = 20
	add_child(dock)
	dock.anchor_left = 1.0
	dock.anchor_top = 1.0
	dock.anchor_right = 1.0
	dock.anchor_bottom = 1.0
	dock.offset_left = -(
		COMMUNITY_ICON_SIZE.x * 2.0
		+ COMMUNITY_DOCK_GAP
		+ COMMUNITY_DOCK_MARGIN
	)
	dock.offset_top = -(COMMUNITY_ICON_SIZE.y + COMMUNITY_DOCK_MARGIN)
	dock.offset_right = -COMMUNITY_DOCK_MARGIN
	dock.offset_bottom = -COMMUNITY_DOCK_MARGIN
	dock.add_theme_constant_override("separation", COMMUNITY_DOCK_GAP)

	_add_community_button(
		dock,
		"DiscordButton",
		sheet,
		Rect2(0.0, 0.0, 512.0, 512.0),
		Rect2(512.0, 0.0, 1024.0, 512.0),
		DISCORD_SERVER_URL,
		"Join our Discord server"
	)
	_add_community_button(
		dock,
		"SteamStoreButton",
		sheet,
		Rect2(0.0, 512.0, 512.0, 512.0),
		Rect2(512.0, 512.0, 1024.0, 512.0),
		STEAM_STORE_URL,
		"View Silent City on Steam"
	)


func _add_community_button(
	parent: HBoxContainer,
	button_name: String,
		sheet: Texture2D,
	normal_region: Rect2,
	hover_region: Rect2,
	url: String,
	accessible_text: String
) -> void:
	var normal_texture := AtlasTexture.new()
	normal_texture.atlas = sheet
	normal_texture.region = normal_region

	var hover_texture := AtlasTexture.new()
	hover_texture.atlas = sheet
	hover_texture.region = hover_region

	var row := Control.new()
	row.custom_minimum_size = COMMUNITY_ICON_SIZE
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)

	var artwork := TextureRect.new()
	artwork.name = "Artwork"
	artwork.texture = normal_texture
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Preserve the source PNG's intended color and contrast.
	artwork.self_modulate = COMMUNITY_ICON_TINT
	row.add_child(artwork)
	artwork.anchor_left = 1.0
	artwork.anchor_top = 0.5
	artwork.anchor_right = 1.0
	artwork.anchor_bottom = 0.5
	artwork.offset_left = -COMMUNITY_ICON_SIZE.x
	artwork.offset_top = -COMMUNITY_ICON_SIZE.y * 0.5
	artwork.offset_right = 0.0
	artwork.offset_bottom = COMMUNITY_ICON_SIZE.y * 0.5

	var button := Button.new()
	button.name = button_name
	button.flat = true
	button.text = ""
	button.tooltip_text = accessible_text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	row.add_child(button)
	button.anchor_left = 1.0
	button.anchor_top = 0.5
	button.anchor_right = 1.0
	button.anchor_bottom = 0.5
	button.offset_left = -COMMUNITY_ICON_SIZE.x
	button.offset_top = -COMMUNITY_ICON_SIZE.y * 0.5
	button.offset_right = 0.0
	button.offset_bottom = COMMUNITY_ICON_SIZE.y * 0.5

	var show_hover := func() -> void:
		row.z_index = 1
		artwork.texture = hover_texture
		artwork.offset_left = -COMMUNITY_HOVER_SIZE.x
		artwork.offset_top = -COMMUNITY_HOVER_SIZE.y * 0.5
		artwork.offset_right = 0.0
		artwork.offset_bottom = COMMUNITY_HOVER_SIZE.y * 0.5
	var show_normal := func() -> void:
		row.z_index = 0
		artwork.texture = normal_texture
		artwork.offset_left = -COMMUNITY_ICON_SIZE.x
		artwork.offset_top = -COMMUNITY_ICON_SIZE.y * 0.5
		artwork.offset_right = 0.0
		artwork.offset_bottom = COMMUNITY_ICON_SIZE.y * 0.5

	button.mouse_entered.connect(show_hover)
	button.mouse_exited.connect(show_normal)
	button.focus_entered.connect(show_hover)
	button.focus_exited.connect(show_normal)
	button.pressed.connect(func() -> void: OS.shell_open(url))






























func _setup_menu_header_images() -> void:
	menu_title_label = get_node_or_null("Content/Root/Title") as Label

	if menu_title_label:
		menu_title_image = _create_image_inside_label(
			menu_title_label,
			"MenuTitleImage",
			MENU_TITLE_IMAGE_SIZE
		)

	if subtitle_label:
		menu_subtitle_image = _create_image_inside_label(
			subtitle_label,
			"MenuSubtitleImage",
			MENU_SUBTITLE_IMAGE_SIZE
		)

	_update_menu_header_images()



func _create_image_inside_label(label: Label, node_name: String, image_size: Vector2) -> TextureRect:
	if not label:
		return null

	# Keep enough room in the VBox/Container for the PNG.
	label.custom_minimum_size = image_size

	var image := label.get_node_or_null(node_name) as TextureRect
	if not image:
		image = TextureRect.new()
		image.name = node_name
		label.add_child(image)

	# Fill the Label's complete rectangle but preserve the PNG's aspect ratio.
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.show_behind_parent = false
	return image



func _update_menu_header_images() -> void:
	# -----------------------
	# SILENT CITY title image
	# -----------------------
	if menu_title_label and menu_title_image:
		var title_texture: Texture2D = menu_optimizer.load_menu_texture(
			MENU_TITLE_PNG,
			MENU_ALPHA_BRIGHTNESS_THRESHOLD,
			MENU_ALPHA_NEUTRAL_TOLERANCE
		)
		if title_texture:
			menu_title_image.texture = title_texture
			menu_title_image.visible = true
			# Remove the old normal text, while keeping the Label itself in the
			# layout so the PNG stays in exactly the same menu position.
			menu_title_label.text = ""
		else:
			menu_title_image.texture = null
			menu_title_image.visible = false
			# Fallback if the PNG path is wrong/missing.
			menu_title_label.text = "Silent City"

	# -----------------------------
	# CHOOSE YOUR FIGHT subtitle PNG
	# -----------------------------
	if subtitle_label and menu_subtitle_image:
		var subtitle_path := MENU_SUBTITLE_ENG_PNG
		if _language() == LANG_GEO:
			subtitle_path = MENU_SUBTITLE_GEO_PNG

		var subtitle_texture: Texture2D = menu_optimizer.load_menu_texture(
			subtitle_path,
			MENU_ALPHA_BRIGHTNESS_THRESHOLD,
			MENU_ALPHA_NEUTRAL_TOLERANCE
		)
		if subtitle_texture:
			menu_subtitle_image.texture = subtitle_texture
			menu_subtitle_image.visible = true
			subtitle_label.text = ""
		else:
			menu_subtitle_image.texture = null
			menu_subtitle_image.visible = false
			# If no PNG exists for the current language, keep your old translated
			# subtitle text instead of showing nothing.
			subtitle_label.text = _t("subtitle")


func _apply_main_menu_button_sprites() -> void:
	_apply_button_sprite(
		home_start_button,
		"res://Resources/Buttons/menu_button_start.png",
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		mode_story_button,
		"res://Resources/Buttons/menu_button_start.png",
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		mode_squad_button,
		"res://Resources/Buttons/menu_button_online.png",
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		mode_back_button,
		"res://Resources/Buttons/menu_button_exit.png",
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		home_map_button,
		"res://Resources/Buttons/menu_button_difficulty.png",
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		home_choose_button,
		"res://Resources/Buttons/menu_button_choose_character.png",
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		home_online_button,
		"res://Resources/Buttons/menu_button_online.png",
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		home_exit_button,
		"res://Resources/Buttons/menu_button_exit.png",
		MAIN_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		language_button,
		"res://Resources/Buttons/menu_button_geo.png",
		LANGUAGE_BUTTON_SIZE
	)

func _apply_button_sprite(button: Button, texture_path: String, minimum_size: Vector2) -> void:
	if not button:
		return

	var texture: Texture2D = menu_optimizer.load_clean_ui_texture(
		texture_path,
		true,
		10,
		0.38,
		0.20
	)
	if not texture:
		return

	button.custom_minimum_size = minimum_size
	button.add_theme_stylebox_override("normal", _button_texture_style(texture))
	button.add_theme_stylebox_override("hover", _button_texture_style(texture))
	button.add_theme_stylebox_override("pressed", _button_texture_style(texture))
	button.add_theme_stylebox_override("disabled", _button_texture_style(texture))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.78, 1.0, 0.94, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.62, 0.88, 0.82, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.66, 0.68, 0.9))
	button.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)




func _button_texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	return style


func _apply_line_edit_sprite(line_edit: LineEdit, texture_path: String, minimum_size: Vector2) -> void:
	if not line_edit:
		return
	var texture: Texture2D = menu_optimizer.load_clean_ui_texture(texture_path, false)
	if not texture:
		return
	line_edit.custom_minimum_size = minimum_size
	line_edit.add_theme_stylebox_override("normal", _button_texture_style(texture))
	line_edit.add_theme_stylebox_override("focus", _button_texture_style(texture))
	line_edit.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	line_edit.add_theme_color_override("font_placeholder_color", Color(0.7, 0.8, 0.82, 0.9))
	line_edit.add_theme_color_override("caret_color", Color(0.78, 1.0, 0.94, 1.0))


func _apply_panel_sprite(panel: Control, texture_path: String, minimum_size: Vector2) -> void:
	if not panel:
		return
	var texture: Texture2D = menu_optimizer.load_clean_ui_texture(texture_path, false)
	if not texture:
		return
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _button_texture_style(texture))


func _apply_item_list_sprite(item_list: ItemList, texture_path: String, minimum_size: Vector2) -> void:
	if not item_list:
		return
	var texture: Texture2D = menu_optimizer.load_clean_ui_texture(texture_path, false)
	if not texture:
		return
	item_list.custom_minimum_size = minimum_size
	item_list.add_theme_stylebox_override("panel", _button_texture_style(texture))
	item_list.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	item_list.add_theme_color_override("font_color", Color(0.82, 0.9, 0.92, 1.0))
	item_list.add_theme_color_override("font_selected_color", Color(0.94, 0.98, 1.0, 1.0))


func _apply_label_panel_sprite(label: Label, texture_path: String, minimum_size: Vector2) -> void:
	if not label:
		return
	var texture: Texture2D = menu_optimizer.load_clean_ui_texture(texture_path, false)
	if not texture:
		return
	label.custom_minimum_size = minimum_size
	label.add_theme_stylebox_override("normal", _button_texture_style(texture))





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
	mode_page.get_node("Header").text = _t("choose_mode")
	mode_story_button.text = _t("story_mode")
	mode_squad_button.text = _t("squad")
	mode_back_button.text = _t("back")
	home_map_button.text = _t("map")
	home_choose_button.text = _t("choose_character")
	home_online_button.text = _t("online_room")
	home_exit_button.text = _t("exit")

	if settings_menu:
		settings_menu.refresh_language()

	easy_button.tooltip_text = _t("easy")
	medium_button.tooltip_text = _t("medium")
	hard_button.tooltip_text = _t("hard")
	map_title_label.text = _t("choose_your_map")
	easy_map_label.text = _t("easy")
	medium_map_label.text = _t("medium")
	hard_map_label.text = _t("hard")
	map_gallery_hint.text = _t("map_gallery_hint")
	level_back_button.text = _t("back")

	if character_menu:
		character_menu.refresh_language()

	if online_menu:
		online_menu.refresh_language()

	_update_menu_header_images()


func _setup_settings_runtime() -> void:
	if settings_menu:
		return

	if not ResourceLoader.exists(SETTINGS_MENU_PATH):
		push_error("Settings menu file not found: " + SETTINGS_MENU_PATH)
		return

	var script = load(SETTINGS_MENU_PATH)
	if script == null:
		push_error("Settings menu could not be loaded: " + SETTINGS_MENU_PATH)
		return

	settings_menu = script.new()
	settings_menu.name = "SettingsMenuModule"
	add_child(settings_menu)

	settings_menu.setup_runtime(
		pages,
		home_page,
		{
			"show_page": Callable(self, "_show_page"),
			"translate": Callable(self, "_t"),
			"menu_optimizer": menu_optimizer,
			"apply_button_sprite": Callable(
				self,
				"_apply_button_sprite"
			)
		}
	)


func _open_settings_page() -> void:
	if not settings_menu:
		_setup_settings_runtime()

	if settings_menu:
		settings_menu.open()



func _setup_main_menu_controller() -> void:
	if main_menu_controller:
		return

	if not ResourceLoader.exists(MAIN_MENU_CONTROLLER_PATH):
		push_error(
			"Main menu controller file not found: "
			+ MAIN_MENU_CONTROLLER_PATH
		)
		return

	var controller_script = load(MAIN_MENU_CONTROLLER_PATH)

	if controller_script == null:
		push_error(
			"Main menu controller could not be loaded: "
			+ MAIN_MENU_CONTROLLER_PATH
		)
		return

	main_menu_controller = controller_script.new()
	add_child(main_menu_controller)

	var settings_button: Button = null
	if settings_menu:
		settings_button = settings_menu.get_settings_button()

	main_menu_controller.setup({
		"pages": pages,
		"home_page": home_page,
		"home_start_button": home_start_button,
		"mode_story_button": mode_story_button,
		"mode_squad_button": mode_squad_button,
		"mode_back_button": mode_back_button,
		"home_map_button": home_map_button,
		"home_choose_button": home_choose_button,
		"home_online_button": home_online_button,
		"settings_button": settings_button,
		"exit_button": home_exit_button,
		"language_button": language_button
	})

	main_menu_controller.start_requested.connect(_open_mode_select)
	main_menu_controller.story_mode_requested.connect(_open_start_flow)
	main_menu_controller.squad_requested.connect(_open_squad_mode)
	main_menu_controller.character_requested.connect(
		_open_character_page_from_home
	)
	main_menu_controller.difficulty_preview_requested.connect(
		_open_map_select_from_home
	)
	main_menu_controller.online_requested.connect(_open_online_page)
	main_menu_controller.settings_requested.connect(_open_settings_page)
	main_menu_controller.exit_requested.connect(_exit_game)


func _open_mode_select() -> void:
	_show_page(mode_page)


func _open_squad_mode() -> void:
	var settings := _settings()
	if settings:
		settings.set("game_mode", "squad")
		settings.set("character_chosen", false)
		if String(settings.get("selected_character")) not in [
			"crusader",
			"wraith",
			"minotaur",
			"ranger"
		]:
			settings.set("selected_character", "crusader")
		settings.set("online_scene_path", SQUAD_SCENE)
		settings.set("level_chosen", true)
	# Squad uses the existing two-player room flow with its own roster.
	_open_online_page()

func _show_page(page: Control) -> void:
	if main_menu_controller:
		main_menu_controller.show_page(page)
		return

	# Safe fallback if the controller has not been created yet.
	for child in pages.get_children():
		if child is Control:
			child.visible = child == page



func _exit_game() -> void:
	_clear_peer()
	get_tree().quit()



func _ensure_online_menu():
	if online_menu:
		return online_menu

	if not ResourceLoader.exists(ONLINE_MENU_PATH):
		push_error("Online menu file not found: " + ONLINE_MENU_PATH)
		return null

	var online_script = load(ONLINE_MENU_PATH)
	if online_script == null:
		push_error("Online menu could not be loaded: " + ONLINE_MENU_PATH)
		return null

	online_menu = online_script.new()

	# RPC node paths must be identical on both peers.
	online_menu.name = "OnlineMenuModule"
	add_child(online_menu)

	online_menu.setup(
		pages,
		online_page,
		{
			"settings": _settings(),
			"show_page": Callable(self, "_show_page"),
			"translate": Callable(self, "_t"),
			"language": Callable(self, "_language"),
			"apply_button_sprite": Callable(
				self,
				"_apply_button_sprite"
			),
			"apply_line_edit_sprite": Callable(
				self,
				"_apply_line_edit_sprite"
			),
			"apply_panel_sprite": Callable(
				self,
				"_apply_panel_sprite"
			),
			"apply_label_panel_sprite": Callable(
				self,
				"_apply_label_panel_sprite"
			),
			"apply_item_list_sprite": Callable(
				self,
				"_apply_item_list_sprite"
			),
			"selected_main_scene": Callable(
				self,
				"_selected_main_scene"
			)
		}
	)

	online_menu.character_page_requested.connect(
		_open_character_page
	)
	online_menu.character_status_requested.connect(
		_set_character_status
	)
	online_menu.character_refresh_requested.connect(
		_update_character_cards
	)
	online_menu.playable_level_requested.connect(
		_open_playable_level_select
	)

	return online_menu


func _open_online_page() -> void:
	var menu = _ensure_online_menu()
	if menu:
		menu.open()


func _online_character_state() -> Dictionary:
	if online_menu:
		return online_menu.get_character_state()

	return {
		"joined_waiting": false,
		"other_chosen": false,
		"other_character": ""
	}


func _clear_peer() -> void:
	if online_menu:
		online_menu.clear_peer()
		return

	# Fallback for Exit / offline flow when Online was never opened.
	var steam_manager := get_node_or_null("/root/SteamManager")
	if steam_manager and steam_manager.has_method("leave_lobby"):
		steam_manager.leave_lobby()

	var peer := multiplayer.multiplayer_peer
	if peer and peer.has_method("close"):
		peer.close()

	multiplayer.multiplayer_peer = null



func _open_start_flow() -> void:
	# The player has committed to Single Player now.
	# Use the time spent choosing character/difficulty to load levels quietly.
	_preload_game_scenes_in_background()

	var settings := _settings()
	if settings:
		settings.set("game_mode", "story")
		settings.set("character_chosen", false)
		settings.set("level_chosen", false)
	level_start_pending = false
	map_gallery_hint.visible = false
	if difficulty_menu:
		difficulty_menu.reset_for_start_flow()

	var menu = _ensure_character_menu()
	if menu:
		menu.reset_for_start_flow()
		_sync_character_menu_state()
		menu.open()





func _ensure_character_menu():
	if character_menu:
		return character_menu

	if not ResourceLoader.exists(CHARACTER_MENU_PATH):
		push_error("Character menu file not found: " + CHARACTER_MENU_PATH)
		return null

	var character_script = load(CHARACTER_MENU_PATH)
	if character_script == null:
		push_error("Character menu could not be loaded: " + CHARACTER_MENU_PATH)
		return null

	character_menu = character_script.new()
	add_child(character_menu)

	character_menu.setup(
		choose_page,
		{
			"settings": _settings(),
			"menu_texture_cache": menu_texture_cache,
			"show_page": Callable(self, "_show_page"),
			"translate": Callable(self, "_t"),
			"apply_button_sprite": Callable(self, "_apply_button_sprite"),
			"remove_outer_white_background": Callable(
				menu_optimizer,
				"remove_outer_white_background"
			),
			"remove_outer_white_fringe": Callable(
				menu_optimizer,
				"remove_white_fringe"
			),
			"remove_baked_checkerboard_background": Callable(
				menu_optimizer,
				"remove_baked_checkerboard_background"
			)
		}
	)

	character_menu.character_selected.connect(_on_character_selected)
	character_menu.start_requested.connect(_open_level_select_from_character)
	character_menu.online_requested.connect(_open_online_page)
	character_menu.back_requested.connect(_back_from_character_page)

	_sync_character_menu_state()
	return character_menu


func _sync_character_menu_state() -> void:
	if not character_menu:
		return

	var state := _online_character_state()
	var joined_waiting := bool(state.get("joined_waiting", false))
	var other_chosen := bool(state.get("other_chosen", false))
	var other_character := String(state.get("other_character", ""))

	var settings := _settings()
	var locked: bool = (
		joined_waiting
		and settings != null
		and bool(settings.get("online_mode")) == true
		and bool(settings.get("character_chosen")) == true
	)

	character_menu.set_online_state(
		joined_waiting,
		other_chosen,
		other_character,
		locked
	)



func _open_character_page(status_override: String = "") -> void:
	var menu = _ensure_character_menu()
	if not menu:
		return

	_sync_character_menu_state()
	menu.open(status_override)


func _open_character_page_from_home() -> void:
	_open_character_page()


func _set_character_status(text: String) -> void:
	if character_menu:
		character_menu.set_status(text)
		return

	# Cheap fallback: do not force Character sprites to load only to update
	# a hidden status Label.
	var status := choose_page.get_node_or_null("StatusLabel") as Label
	if status:
		status.text = text


func _on_character_selected(character: String) -> void:
	var menu = _ensure_character_menu()
	if not menu:
		return

	var character_name: String = String(menu.display_name(character))

	if online_menu and online_menu.is_waiting_for_character():
		_sync_character_menu_state()
		menu.set_buttons_enabled(false)
		online_menu.local_character_selected(character)
	else:
		_set_character_status(_t("selected") % character_name)

	_update_character_cards()



func _ensure_difficulty_menu():
	if difficulty_menu:
		return difficulty_menu

	if not ResourceLoader.exists(DIFFICULTY_MENU_PATH):
		push_error("Difficulty menu file not found: " + DIFFICULTY_MENU_PATH)
		return null

	var difficulty_script = load(DIFFICULTY_MENU_PATH)
	if difficulty_script == null:
		push_error("Difficulty menu could not be loaded: " + DIFFICULTY_MENU_PATH)
		return null

	difficulty_menu = difficulty_script.new()
	add_child(difficulty_menu)

	difficulty_menu.setup(
		{
			"level_page": level_page,
			"choose_page": choose_page,
			"home_page": home_page,
			"easy_button": easy_button,
			"medium_button": medium_button,
			"hard_button": hard_button,
			"squad_button": squad_button,
			"map_title_label": map_title_label,
			"map_gallery_hint": map_gallery_hint,
			"level_back_button": level_back_button
		},
		{
			"menu_texture_cache": menu_texture_cache,
			"show_page": Callable(self, "_show_page"),
			"translate": Callable(self, "_t"),
			"apply_button_sprite": Callable(self, "_apply_button_sprite"),
			"remove_outer_white_background": Callable(
				menu_optimizer,
				"remove_outer_white_background"
			),
			"remove_outer_white_fringe": Callable(
				menu_optimizer,
				"remove_white_fringe"
			)
		}
	)

	difficulty_menu.level_selected.connect(_on_difficulty_level_selected)
	return difficulty_menu


func _on_difficulty_level_selected(level: String) -> void:
	var settings := _settings()
	if settings:
		settings.set("game_mode", "squad" if level == "squad" else "story")
		settings.set("selected_level", level)
		settings.set("level_chosen", true)
		if level == "squad" and String(settings.get("selected_character")) not in [
			"crusader",
			"wraith",
			"minotaur",
			"ranger"
		]:
			settings.set("selected_character", "crusader")

	level_start_pending = true
	_start_game()


func _open_map_select_from_home() -> void:
	var menu = _ensure_difficulty_menu()
	if menu:
		menu.open_preview()


func _back_from_character_page() -> void:
	if online_menu and online_menu.is_waiting_for_character():
		online_menu.leave_from_character_page()
		_show_page(home_page)
		return

	_show_page(home_page)



func _open_level_select_from_character() -> void:
	var settings := _settings()
	if not settings or settings.get("character_chosen") != true:
		_set_character_status(_t("choose_first"))
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

	var menu = _ensure_difficulty_menu()
	if menu:
		menu.open_playable()







func _update_character_cards() -> void:
	if not character_menu:
		return

	var state := _online_character_state()
	var joined_waiting := bool(state.get("joined_waiting", false))
	var other_chosen := bool(state.get("other_chosen", false))
	var other_character := String(state.get("other_character", ""))

	var settings := _settings()
	var locked: bool = (
		joined_waiting
		and settings != null
		and bool(settings.get("online_mode")) == true
		and bool(settings.get("character_chosen")) == true
	)

	character_menu.set_online_state(
		joined_waiting,
		other_chosen,
		other_character,
		locked
	)
	character_menu.refresh()



func _start_game() -> void:
	var settings := _settings()
	if not settings or settings.get("character_chosen") != true:
		_set_character_status(_t("choose_first"))
		return

	if settings.get("level_chosen") != true:
		_open_level_select_from_character()
		return

	if settings.get("online_mode") == true:
		if String(settings.get("online_role")) == "host":
			var menu = _ensure_online_menu()
			if menu:
				menu.start_online_host_game()
		elif String(settings.get("online_role")) == "client":
			_set_character_status(_t("waiting_for_host_start"))
		return

	settings.call("reset_online")
	settings.call("start_offline_level", String(settings.get("selected_level")))
	_clear_peer()

	# Avoid a blocking synchronous scene load on the main thread.
	_change_to_preloaded_game_scene(_selected_main_scene())


func _preload_game_scenes_in_background() -> void:
	for scene_path: String in BACKGROUND_GAME_SCENES:
		var status := ResourceLoader.load_threaded_get_status(scene_path)

		if status != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			continue

		var error := ResourceLoader.load_threaded_request(
			scene_path,
			"PackedScene",
			true
		)

		if error != OK:
			print("Background scene preload failed to start: ", scene_path, " error=", error)


func _change_to_preloaded_game_scene(scene_path: String) -> void:
	var status := ResourceLoader.load_threaded_get_status(scene_path)

	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		var request_error := ResourceLoader.load_threaded_request(
			scene_path,
			"PackedScene",
			true
		)

		if request_error != OK:
			level_start_pending = false
			get_tree().change_scene_to_file(scene_path)
			return

	# Poll once per frame. The window remains responsive while resources load.
	while true:
		var progress: Array = []
		status = ResourceLoader.load_threaded_get_status(scene_path, progress)

		if not progress.is_empty() and map_gallery_hint:
			var percent := int(round(float(progress[0]) * 100.0))
			map_gallery_hint.text = "Loading... %d%%" % clampi(percent, 0, 100)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed_scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
			level_start_pending = false

			if packed_scene:
				get_tree().change_scene_to_packed(packed_scene)
			else:
				get_tree().change_scene_to_file(scene_path)
			return

		if status == ResourceLoader.THREAD_LOAD_FAILED:
			level_start_pending = false
			get_tree().change_scene_to_file(scene_path)
			return

		if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			level_start_pending = false
			get_tree().change_scene_to_file(scene_path)
			return

		await get_tree().process_frame


func _selected_main_scene() -> String:
	var settings := _settings()
	if settings:
		if String(settings.get("game_mode")) == "squad":
			return SQUAD_SCENE
		var selected_level := String(settings.get("selected_level"))
		if selected_level == "hard":
			return HARD_SCENE
		if selected_level == "medium":
			return MEDIUM_SCENE
	return MAIN_SCENE
	
func _attach_persistent_menu_texture_cache() -> void:
	var settings := get_node_or_null("/root/GameSettings")

	# Fallback for safety if the autoload is unavailable.
	if not settings:
		menu_texture_cache = {}
		return

	if not settings.has_meta(MENU_TEXTURE_CACHE_META):
		settings.set_meta(MENU_TEXTURE_CACHE_META, {})

	var cached_value = settings.get_meta(MENU_TEXTURE_CACHE_META)

	if cached_value is Dictionary:
		# Dictionaries are reference types, so every MainMenu instance now uses
		# the exact same cache stored on the persistent autoload.
		menu_texture_cache = cached_value
	else:
		menu_texture_cache = {}
		settings.set_meta(MENU_TEXTURE_CACHE_META, menu_texture_cache)


func _settings() -> Node:
	return get_node_or_null("/root/GameSettings")
