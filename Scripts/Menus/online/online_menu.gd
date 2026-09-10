extends Node

# Online / Steam menu module.
# Wi-Fi/LAN discovery has been removed.
# This script is loaded only when the player actually opens Online.

signal character_page_requested(status_text: String)
signal character_status_requested(status_text: String)
signal character_refresh_requested
signal playable_level_requested

const MAIN_SCENE := "res://Scenes/main.tscn"
const SQUAD_SCENE := "res://Scenes/SquadArena.tscn"
const MEDIUM_SCENE := "res://Scenes/MainMedium.tscn"
const HARD_SCENE := "res://Scenes/MainHard.tscn"

const MAX_ROOM_PLAYERS := 4

const STEAM_LOBBY_REFRESH_INTERVAL := 2.0


const ONLINE_MODE_STEAM := "steam"

const ONLINE_MODE_BUTTON_SIZE := Vector2(183.0, 42.0)
const ONLINE_INPUT_SIZE := Vector2(380.0, 42.0)
const ONLINE_ACTION_BUTTON_SIZE := Vector2(183.0, 44.0)
const ONLINE_PANEL_SIZE := Vector2(380.0, 96.0)
const ONLINE_TUTORIAL_PANEL_SIZE := Vector2(320.0, 168.0)
const ONLINE_TUTORIAL_BUTTON_SIZE := Vector2(86.0, 34.0)
const CHARACTER_MENU_BUTTON_SIZE := Vector2(260.0, 40.0)

const ONLINE_BACK_PNG := "res://Resources/Buttons/menu_button_start.png"
const ONLINE_BACK_SIZE := Vector2(260.0, 40.0)

const ONLINE_TUTORIAL_STEPS := {
	"eng": [
		"Steam Friend uses Steam lobbies for online multiplayer.",
		"Create a room or select an open room and press Join.",
		"Four players choose Crusader or Wraith, then fight in two teams."
	],
	"geo": [
		"Steam Friend იყენებს Steam lobby-ს ონლაინ მულტიფლეერისთვის.",
		"შექმენი ოთახი ან აირჩიე ღია ოთახი და დააჭირე Join-ს.",
		"ოთხი მოთამაშე ირჩევს Crusader-ს ან Wraith-ს და თამაშობს 2v2 გუნდებად."
	]
}

var pages: Control = null
var online_page: VBoxContainer = null
var home_page: VBoxContainer = null

var tutorial_overlay: Control = null
var tutorial_card: PanelContainer = null
var tutorial_title: Label = null
var tutorial_text: Label = null
var tutorial_next: Button = null
var tutorial_skip: Button = null
var tutorial_back: Button = null

var legacy_wifi_mode_button: Button = null
var steam_mode_button: Button = null
var legacy_address_box: Control = null
var room_name_input: LineEdit = null
var room_name_hint: Label = null
var online_header: Label = null
var online_status: Label = null
var lobby_select: ItemList = null
var host_button: Button = null
var join_button: Button = null
var online_start_button: Button = null
var online_back_button: Button = null

var settings: Node = null

var show_page_callback
var translate_callback
var language_callback
var apply_button_sprite_callback
var apply_line_edit_sprite_callback
var apply_panel_sprite_callback
var apply_label_panel_sprite_callback
var apply_item_list_sprite_callback
var selected_main_scene_callback

var hosted_player_count := 1
var hosted_room_id := ""

var joined_room_waiting_for_character := false
var tutorial_step := 0

var remote_client_character := "golem"
var remote_client_character_chosen := false
var squad_character_choices: Dictionary = {}

var other_player_character := ""
var other_player_character_chosen := false

var steam_lobbies: Array = []
var steam_lobby_refresh_timer := 0.0
var steam_lobby_searching := false
var steam_lobby_wide_searching := false

var online_match_starting := false
var pending_join_lobby: Dictionary = {}
var online_connection_mode := ONLINE_MODE_STEAM

var configured := false


func setup(
	pages_node: Control,
	online_page_node: VBoxContainer,
	services: Dictionary
) -> void:
	if configured:
		return
	if not pages_node or not online_page_node:
		return

	pages = pages_node
	online_page = online_page_node
	home_page = pages.get_node_or_null("Home") as VBoxContainer

	settings = services.get("settings") as Node

	show_page_callback = services.get("show_page")
	translate_callback = services.get("translate")
	language_callback = services.get("language")
	apply_button_sprite_callback = services.get("apply_button_sprite")
	apply_line_edit_sprite_callback = services.get("apply_line_edit_sprite")
	apply_panel_sprite_callback = services.get("apply_panel_sprite")
	apply_label_panel_sprite_callback = services.get("apply_label_panel_sprite")
	apply_item_list_sprite_callback = services.get("apply_item_list_sprite")
	selected_main_scene_callback = services.get("selected_main_scene")

	_resolve_nodes()

	# Prepare the COMPLETE page before showing it.
	_layout_online_page()
	_apply_visuals()
	_connect_ui_signals()
	_connect_multiplayer_signals()
	_connect_steam_manager()

	if legacy_wifi_mode_button:
		legacy_wifi_mode_button.visible = false
	if legacy_address_box:
		legacy_address_box.visible = false
	online_start_button.visible = false

	_apply_default_connection_name()
	refresh_language()
	_update_online_room_text()

	configured = true


func open() -> void:
	if not configured:
		return

	_sync_online_state_with_peer()
	_update_online_room_text()

	# Wi-Fi/LAN mode was removed. Online opens directly in Steam mode.
	online_connection_mode = ONLINE_MODE_STEAM
	_show_page(online_page)
	_request_steam_lobbies(true)
	_show_online_tutorial_once()


func refresh_language() -> void:
	if not configured and not online_page:
		return

	if online_header:
		online_header.text = _t("online_room")
	if steam_mode_button:
		steam_mode_button.text = _t("steam_friend")
	if room_name_hint:
		room_name_hint.text = _t("room_name_hint")

	_apply_default_connection_name()
	_update_online_action_button_text()

	if online_start_button:
		online_start_button.text = _t("start_online_room")
	if online_back_button:
		online_back_button.text = _t("back")
	if tutorial_title:
		tutorial_title.text = _t("tutorial_title")
	if tutorial_back:
		tutorial_back.text = _t("back")
	if tutorial_skip:
		tutorial_skip.text = _t("skip")

	_update_online_tutorial()

	if configured:
		_update_online_room_text()


func get_character_state() -> Dictionary:
	return {
		"joined_waiting": joined_room_waiting_for_character,
		"other_chosen": other_player_character_chosen,
		"other_character": other_player_character
	}


func is_waiting_for_character() -> bool:
	return joined_room_waiting_for_character


func is_hosting_room() -> bool:
	return (
		settings != null
		and bool(settings.get("online_mode")) == true
		and String(settings.get("online_role")) == "host"
		and multiplayer.has_multiplayer_peer()
	)


func is_joining_room() -> bool:
	return (
		settings != null
		and bool(settings.get("online_mode")) == true
		and String(settings.get("online_role")) == "client"
	)


func local_character_selected(character: String) -> void:
	if not joined_room_waiting_for_character:
		return

	if is_joining_room():
		rpc_id(1, "_client_online_character_selected", character)
		_request_character_status(_t("waiting_for_host_start"))
		if online_status:
			online_status.text = _t("waiting_for_host_start")
		return

	_request_character_status(
		_t("selected_online") % _character_display_name(character)
	)
	if online_status:
		online_status.text = (
			_t("selected_online") % _character_display_name(character)
		)

	_sync_online_character_state()
	_try_auto_start_online_match()


func start_online_host_game() -> void:
	_try_auto_start_online_match()


func leave_from_character_page() -> void:
	if settings:
		settings.call("reset_online")
		settings.set("character_chosen", false)

	clear_peer()

	hosted_player_count = 1
	hosted_room_id = ""
	joined_room_waiting_for_character = false
	remote_client_character = "golem"
	remote_client_character_chosen = false
	squad_character_choices.clear()
	other_player_character = ""
	other_player_character_chosen = false
	online_match_starting = false
	pending_join_lobby.clear()

	_emit_character_refresh()


func clear_peer() -> void:
	var steam_manager := _steam_manager()
	if steam_manager and steam_manager.has_method("leave_lobby"):
		steam_manager.leave_lobby()

	var peer := multiplayer.multiplayer_peer
	if peer and peer.has_method("close"):
		peer.close()

	multiplayer.multiplayer_peer = null


func _process(delta: float) -> void:
	if not configured:
		return

	if not online_page or not online_page.visible:
		return

	if is_hosting_room() or is_joining_room() or not _steam_ready():
		return

	steam_lobby_refresh_timer -= delta

	if steam_lobby_refresh_timer <= 0.0:
		steam_lobby_refresh_timer = STEAM_LOBBY_REFRESH_INTERVAL
		_request_steam_lobbies(false)


func _resolve_nodes() -> void:
	tutorial_overlay = pages.get_node_or_null("TutorialOverlay") as Control
	if tutorial_overlay:
		tutorial_card = tutorial_overlay.get_node_or_null("Card") as PanelContainer

	if tutorial_card:
		tutorial_title = tutorial_card.get_node_or_null("Box/Title") as Label
		tutorial_text = tutorial_card.get_node_or_null("Box/Text") as Label
		tutorial_next = tutorial_card.get_node_or_null(
			"Box/Buttons/NextButton"
		) as Button
		tutorial_skip = tutorial_card.get_node_or_null(
			"Box/Buttons/SkipButton"
		) as Button
		tutorial_back = tutorial_card.get_node_or_null(
			"Box/Buttons/BackButton"
		) as Button

	legacy_wifi_mode_button = online_page.get_node_or_null(
		"ModeButtons/WifiButton"
	) as Button
	steam_mode_button = online_page.get_node_or_null(
		"ModeButtons/SteamButton"
	) as Button
	legacy_address_box = online_page.get_node_or_null("AddressBox") as Control

	if legacy_wifi_mode_button:
		legacy_wifi_mode_button.visible = false
		legacy_wifi_mode_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if legacy_address_box:
		legacy_address_box.visible = false
		legacy_address_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	room_name_input = online_page.get_node_or_null("RoomNameInput") as LineEdit
	room_name_hint = online_page.get_node_or_null("RoomNameHint") as Label
	online_header = online_page.get_node_or_null("Header") as Label
	online_status = online_page.get_node_or_null("StatusLabel") as Label
	lobby_select = online_page.get_node_or_null("LobbySelect") as ItemList

	host_button = online_page.get_node_or_null(
		"Buttons/HostButton"
	) as Button
	join_button = online_page.get_node_or_null(
		"Buttons/JoinButton"
	) as Button

	online_start_button = online_page.get_node_or_null(
		"StartOnlineButton"
	) as Button
	online_back_button = online_page.get_node_or_null(
		"BackButton"
	) as Button


func _connect_ui_signals() -> void:
	if host_button:
		host_button.pressed.connect(_host_online_game)

	if join_button:
		join_button.pressed.connect(_join_online_game)

	if lobby_select:
		lobby_select.item_activated.connect(
			func(_index: int): _join_online_game()
		)

	if online_start_button:
		online_start_button.pressed.connect(start_online_host_game)

	if tutorial_next:
		tutorial_next.pressed.connect(_advance_online_tutorial)

	if tutorial_skip:
		tutorial_skip.pressed.connect(_finish_online_tutorial)

	if tutorial_back:
		tutorial_back.pressed.connect(_back_from_online)

	if online_back_button:
		online_back_button.pressed.connect(_back_from_online)


func _connect_multiplayer_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)

	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)

	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)


func _apply_visuals() -> void:
	_apply_button_sprite(
		steam_mode_button,
		"res://Resources/Buttons/online_mode_steam.png",
		ONLINE_MODE_BUTTON_SIZE
	)
	_apply_button_sprite(
		host_button,
		"res://Resources/Buttons/online_action_host.png",
		ONLINE_ACTION_BUTTON_SIZE
	)
	_apply_button_sprite(
		join_button,
		"res://Resources/Buttons/online_action_join.png",
		ONLINE_ACTION_BUTTON_SIZE
	)
	_apply_button_sprite(
		online_start_button,
		"res://Resources/Buttons/online_action_host.png",
		CHARACTER_MENU_BUTTON_SIZE
	)
	_apply_button_sprite(
		online_back_button,
		ONLINE_BACK_PNG,
		ONLINE_BACK_SIZE
	)

	_apply_button_sprite(
		tutorial_back,
		"res://Resources/Buttons/online_tutorial_small_back.png",
		ONLINE_TUTORIAL_BUTTON_SIZE
	)
	_apply_button_sprite(
		tutorial_skip,
		"res://Resources/Buttons/online_tutorial_small_skip.png",
		ONLINE_TUTORIAL_BUTTON_SIZE
	)
	_apply_button_sprite(
		tutorial_next,
		"res://Resources/Buttons/online_tutorial_small_next.png",
		ONLINE_TUTORIAL_BUTTON_SIZE
	)

	_apply_line_edit_sprite(
		room_name_input,
		"res://Resources/Buttons/online_room_input.png",
		ONLINE_INPUT_SIZE
	)
	_apply_panel_sprite(
		tutorial_card,
		"res://Resources/Buttons/online_tutorial_panel.png",
		ONLINE_TUTORIAL_PANEL_SIZE
	)
	_apply_label_panel_sprite(
		online_status,
		"res://Resources/Buttons/online_status_panel.png",
		Vector2(380.0, 76.0)
	)
	_apply_item_list_sprite(
		lobby_select,
		"res://Resources/Buttons/online_status_panel.png",
		ONLINE_PANEL_SIZE
	)


func _apply_button_sprite(
	button: Button,
	texture_path: String,
	size: Vector2
) -> void:
	if (
		apply_button_sprite_callback is Callable
		and apply_button_sprite_callback.is_valid()
	):
		apply_button_sprite_callback.call(button, texture_path, size)


func _apply_line_edit_sprite(
	line_edit: LineEdit,
	texture_path: String,
	size: Vector2
) -> void:
	if (
		apply_line_edit_sprite_callback is Callable
		and apply_line_edit_sprite_callback.is_valid()
	):
		apply_line_edit_sprite_callback.call(line_edit, texture_path, size)


func _apply_panel_sprite(
	panel: Control,
	texture_path: String,
	size: Vector2
) -> void:
	if (
		apply_panel_sprite_callback is Callable
		and apply_panel_sprite_callback.is_valid()
	):
		apply_panel_sprite_callback.call(panel, texture_path, size)


func _apply_label_panel_sprite(
	label: Label,
	texture_path: String,
	size: Vector2
) -> void:
	if (
		apply_label_panel_sprite_callback is Callable
		and apply_label_panel_sprite_callback.is_valid()
	):
		apply_label_panel_sprite_callback.call(label, texture_path, size)


func _apply_item_list_sprite(
	item_list: ItemList,
	texture_path: String,
	size: Vector2
) -> void:
	if (
		apply_item_list_sprite_callback is Callable
		and apply_item_list_sprite_callback.is_valid()
	):
		apply_item_list_sprite_callback.call(item_list, texture_path, size)


func _layout_online_page() -> void:
	if not online_page or not online_back_button:
		return

	online_page.add_theme_constant_override("separation", 2)

	if online_status:
		online_status.custom_minimum_size.y = 60.0

	if lobby_select:
		lobby_select.custom_minimum_size.y = 75.0

		# Keep room-list text away from the decorative frame.
		# This fixes "No rooms yet. Waiting for rooms..." sitting on the top edge.
		var lobby_panel_style := lobby_select.get_theme_stylebox("panel")
		if lobby_panel_style:
			lobby_panel_style.content_margin_left = 18.0
			lobby_panel_style.content_margin_right = 18.0
			lobby_panel_style.content_margin_top = 14.0
			lobby_panel_style.content_margin_bottom = 12.0

		lobby_select.add_theme_constant_override("line_separation", 4)

	if room_name_hint:
		room_name_hint.custom_minimum_size.y = 24.0

	online_back_button.custom_minimum_size = ONLINE_BACK_SIZE
	online_back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _apply_default_connection_name() -> void:
	if not room_name_input:
		return

	var current_name := room_name_input.text.strip_edges()

	if current_name.is_empty() or current_name in [
		"Silent City",
		"ჩუმი ქალაქი"
	]:
		room_name_input.text = _t("default_connection_name")


func _update_online_mode_ui() -> void:
	online_connection_mode = ONLINE_MODE_STEAM

	if legacy_wifi_mode_button:
		legacy_wifi_mode_button.visible = false
		legacy_wifi_mode_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if legacy_address_box:
		legacy_address_box.visible = false
		legacy_address_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if steam_mode_button:
		steam_mode_button.visible = true
		steam_mode_button.button_pressed = true


func _show_online_tutorial_once() -> void:
	if settings and bool(settings.get("online_tutorial_seen")) == true:
		if tutorial_overlay:
			tutorial_overlay.visible = false
		return

	tutorial_step = 0

	if tutorial_overlay:
		tutorial_overlay.visible = true

	_update_online_tutorial()


func _update_online_tutorial() -> void:
	if not tutorial_text or not tutorial_next:
		return

	var lang := _language()
	var steps: Array = ONLINE_TUTORIAL_STEPS.get(
		lang,
		ONLINE_TUTORIAL_STEPS["eng"]
	)

	tutorial_text.text = String(steps[tutorial_step])
	tutorial_next.text = (
		_t("done")
		if tutorial_step >= steps.size() - 1
		else _t("next")
	)


func _advance_online_tutorial() -> void:
	var lang := _language()
	var steps: Array = ONLINE_TUTORIAL_STEPS.get(
		lang,
		ONLINE_TUTORIAL_STEPS["eng"]
	)

	if tutorial_step >= steps.size() - 1:
		_finish_online_tutorial()
		return

	tutorial_step += 1
	_update_online_tutorial()


func _finish_online_tutorial() -> void:
	if settings:
		settings.set("online_tutorial_seen", true)

	if tutorial_overlay:
		tutorial_overlay.visible = false


func _host_online_game() -> void:
	if is_hosting_room():
		if online_status:
			online_status.text = _t("hosting_active")

		get_tree().change_scene_to_file(_online_scene_path_from_settings())
		return

	clear_peer()
	steam_lobbies.clear()
	_update_lobby_select()

	if not _steam_ready():
		if online_status:
			online_status.text = _steam_not_ready_message()
		return

	if online_status:
		online_status.text = _t("steam_creating_lobby")

	host_button.disabled = true
	join_button.disabled = true

	var lobby_size := (
		MAX_ROOM_PLAYERS
		if settings and String(settings.get("game_mode")) == "squad"
		else 2
	)
	_steam_manager().create_lobby(_room_name(), lobby_size)


func _finish_steam_host_lobby(_lobby_id: int) -> void:
	if online_connection_mode != ONLINE_MODE_STEAM:
		return

	var steam_manager := _steam_manager()
	if not steam_manager:
		return

	var peer := steam_manager.create_host_peer() as MultiplayerPeer

	if not peer:
		if online_status:
			online_status.text = _t("steam_transport_missing")
		_update_room_buttons()
		return

	_prepare_online_host(peer)


func _prepare_online_host(peer: MultiplayerPeer) -> void:
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
	squad_character_choices.clear()
	other_player_character = ""
	other_player_character_chosen = false
	online_match_starting = false

	steam_lobbies.clear()

	_update_lobby_select()
	_set_online_status_with_player_line(_online_room_open_text())

	online_start_button.visible = false
	_update_room_buttons()

	joined_room_waiting_for_character = true
	_request_character_page(_t("connected_choose"))


func _try_auto_start_online_match() -> void:
	if online_match_starting:
		return

	if (
		not settings
		or bool(settings.get("online_mode")) != true
		or String(settings.get("online_role")) != "host"
	):
		return

	if bool(settings.get("character_chosen")) != true:
		joined_room_waiting_for_character = true
		_request_character_status(_t("connected_choose"))
		_emit_character_refresh()
		return

	var squad_mode := settings != null and String(settings.get("game_mode")) == "squad"
	var required_remote_players := 3 if squad_mode else 1
	if multiplayer.get_peers().size() < required_remote_players:
		_set_online_status_with_player_line(_online_room_waiting_text())
		return

	if squad_mode:
		for peer_id in multiplayer.get_peers():
			if not squad_character_choices.has(peer_id):
				_request_character_status("Waiting for all 4 players to choose a character.")
				if online_status:
					online_status.text = "Waiting for all 4 players to choose a character."
				return
	elif not remote_client_character_chosen:
		_request_character_status(_t("waiting_for_player_choice"))

		if online_status:
			online_status.text = _t("waiting_for_player_choice")
		return

	if squad_mode:
		settings.set("online_scene_path", SQUAD_SCENE)
		settings.set("level_chosen", true)

	if bool(settings.get("level_chosen")) != true:
		_request_character_status(_t("choose_map_to_start"))

		if online_status:
			online_status.text = _t("choose_map_to_start")

		playable_level_requested.emit()
		return

	online_match_starting = true
	joined_room_waiting_for_character = false

	var host_character := String(settings.get("selected_character"))
	var scene_path := _store_online_scene_path(_selected_main_scene())

	var steam_manager := _steam_manager()

	if (
		steam_manager
		and steam_manager.has_method("set_lobby_match_state")
	):
		steam_manager.set_lobby_match_state(
			"playing",
			host_character,
			remote_client_character,
			scene_path
		)

	_request_character_status(_t("both_ready"))

	if online_status:
		online_status.text = _t("both_ready")

	online_start_button.visible = false
	_update_room_buttons()
	_sync_online_character_state()

	rpc("_start_online_match", scene_path)
	get_tree().change_scene_to_file(scene_path)


func _join_online_game() -> void:
	if is_hosting_room():
		if online_status:
			online_status.text = _t("hosting_device")
		return

	if not _steam_ready():
		if online_status:
			online_status.text = _steam_not_ready_message()
		return

	if not steam_lobbies.is_empty():
		var selected_items := lobby_select.get_selected_items()
		var selected_index := (
			int(selected_items[0])
			if not selected_items.is_empty()
			else 0
		)

		if selected_index >= steam_lobbies.size():
			selected_index = 0

		var lobby_id := int(
			steam_lobbies[selected_index].get("id", 0)
		)

		_prepare_join_selected_lobby(steam_lobbies[selected_index])
		_steam_manager().join_lobby(lobby_id)

		if online_status:
			online_status.text = _t("joining")
		return

	if online_status:
		online_status.text = _t("steam_no_lobby")

	_request_steam_lobbies(true)


func _prepare_join_selected_lobby(lobby_data: Dictionary) -> void:
	clear_peer()

	pending_join_lobby = lobby_data.duplicate(true)

	if settings:
		settings.set("online_mode", true)
		settings.set("online_role", "client")

		if _is_pending_join_lobby_playing():
			_store_online_scene_path(_pending_lobby_scene_path())

			var saved_client_character := String(
				pending_join_lobby.get("client_character", "")
			).strip_edges()

			var saved_host_character := String(
				pending_join_lobby.get("host_character", "")
			).strip_edges()

			if saved_client_character in [
				"player",
				"golem",
				"ice_golem",
				"crusader",
				"wraith"
			]:
				settings.set(
					"selected_character",
					saved_client_character
				)

			settings.set("character_chosen", true)

			if saved_host_character in [
				"player",
				"golem",
				"ice_golem",
				"crusader",
				"wraith"
			]:
				settings.set(
					"online_remote_character",
					saved_host_character
				)
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

	if not is_joining_room():
		return

	var steam_manager := _steam_manager()
	if not steam_manager:
		return

	var peer := steam_manager.create_client_peer_for_lobby(
		lobby_id
	) as MultiplayerPeer

	if not peer:
		if online_status:
			online_status.text = _t("steam_transport_missing")
		_update_room_buttons()
		return

	multiplayer.multiplayer_peer = peer

	if _is_pending_join_lobby_playing():
		if online_status:
			online_status.text = "Rejoining match..."

		get_tree().change_scene_to_file(
			_store_online_scene_path(_pending_lobby_scene_path())
		)
	else:
		if online_status:
			online_status.text = _t("joining")


func _on_steam_lobby_list_updated(lobbies: Array) -> void:
	steam_lobby_searching = false

	if online_connection_mode != ONLINE_MODE_STEAM:
		return

	if (
		is_hosting_room()
		or (
			is_joining_room()
			and multiplayer.multiplayer_peer != null
		)
	):
		return

	if lobbies.is_empty() and not steam_lobby_wide_searching:
		if online_status:
			online_status.text = "Still searching Steam rooms..."

		_request_steam_lobbies(false, true)
		return

	steam_lobby_wide_searching = false

	if lobbies.is_empty() and not steam_lobbies.is_empty():
		if online_status:
			online_status.text = (
				"Steam refresh missed the room. "
				+ "Select it and press Join."
			)

		_update_lobby_select()
		_update_room_buttons()
		return

	steam_lobbies = lobbies.duplicate(true)
	_update_lobby_select()

	if lobbies.is_empty():
		if online_status:
			online_status.text = _t("steam_no_lobby")

		_update_room_buttons()
		return

	if online_status:
		online_status.text = _t("steam_lobby_count")

	_update_room_buttons()


func _on_connected_to_server() -> void:
	if (
		settings
		and bool(settings.get("online_mode")) == true
		and String(settings.get("online_role")) == "client"
	):
		if _is_pending_join_lobby_playing():
			if online_status:
				online_status.text = "Rejoining match..."

			get_tree().change_scene_to_file(
				_store_online_scene_path(
					_pending_lobby_scene_path()
				)
			)
			return

		joined_room_waiting_for_character = true
		other_player_character = ""
		other_player_character_chosen = false
		online_match_starting = false

		settings.set("character_chosen", false)

		_request_character_page(_t("connected_choose"))


func _on_peer_connected(_peer_id: int) -> void:
	if (
		settings
		and bool(settings.get("online_mode")) == true
		and String(settings.get("online_role")) == "host"
	):
		hosted_player_count = min(
			multiplayer.get_peers().size() + 1,
			MAX_ROOM_PLAYERS
		)

		remote_client_character_chosen = false
		other_player_character = ""
		other_player_character_chosen = false
		online_match_starting = false

		_set_online_status_with_player_line(_t("player_connected"))
		_update_room_buttons()

		_sync_online_character_state.call_deferred()


func _on_peer_disconnected(_peer_id: int) -> void:
	if (
		settings
		and bool(settings.get("online_mode")) == true
		and String(settings.get("online_role")) == "host"
	):
		hosted_player_count = min(
			multiplayer.get_peers().size() + 1,
			MAX_ROOM_PLAYERS
		)
		squad_character_choices.erase(_peer_id)

		remote_client_character_chosen = false
		other_player_character = ""
		other_player_character_chosen = false
		online_match_starting = false

		_set_online_status_with_player_line(_online_room_waiting_text())
		_emit_character_refresh()
		_update_room_buttons()


func _on_connection_failed() -> void:
	if online_status:
		online_status.text = _t("connection_failed")

	if settings:
		settings.call("reset_online")

	other_player_character = ""
	other_player_character_chosen = false
	online_match_starting = false

	clear_peer()


	if online_start_button:
		online_start_button.visible = false

	_update_room_buttons()


func _back_from_online() -> void:
	if settings:
		settings.call("reset_online")

	clear_peer()

	hosted_player_count = 1
	hosted_room_id = ""
	joined_room_waiting_for_character = false
	remote_client_character = "golem"
	remote_client_character_chosen = false
	other_player_character = ""
	other_player_character_chosen = false
	online_match_starting = false
	pending_join_lobby.clear()

	if online_start_button:
		online_start_button.visible = false

	steam_lobbies.clear()
	_update_lobby_select()

	if online_status:
		online_status.text = _online_default_status_text()

	_update_room_buttons()
	_emit_character_refresh()
	_show_page(home_page)


func _update_online_room_text() -> void:
	_sync_online_state_with_peer()
	_update_online_mode_ui()
	_update_lobby_select()
	_set_online_status_with_player_line(
		_online_default_status_text()
	)
	_update_room_buttons()


func _request_steam_lobbies(
	show_search_text: bool,
	wide_search: bool = false
) -> void:
	if (
		online_connection_mode != ONLINE_MODE_STEAM
		or steam_lobby_searching
		or not _steam_ready()
		or is_hosting_room()
		or is_joining_room()
	):
		return

	steam_lobby_searching = true
	steam_lobby_wide_searching = wide_search

	if show_search_text and online_status:
		online_status.text = _t("steam_finding_lobby")

	_steam_manager().request_lobbies(wide_search)


func _online_default_status_text() -> String:
	return _t("steam_status_default")


func _online_room_open_text() -> String:
	return _t("steam_room_open")


func _online_room_waiting_text() -> String:
	return _t("steam_room_waiting")


func _update_lobby_select() -> void:
	if not lobby_select:
		return

	lobby_select.clear()

	if steam_lobbies.is_empty():
		lobby_select.visible = true
		lobby_select.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lobby_select.add_item("\n   " + _t("steam_no_lobby"))
		return

	lobby_select.visible = true
	lobby_select.mouse_filter = Control.MOUSE_FILTER_STOP

	for index in steam_lobbies.size():
		var lobby: Dictionary = steam_lobbies[index]
		var lobby_name := String(
			lobby.get("name", "Silent City")
		)

		if String(lobby.get("state", "waiting")) == "playing":
			lobby_name = "%s - Playing" % lobby_name
		else:
			lobby_name = "%s - %d/%d" % [
				lobby_name,
				int(lobby.get("members", 1)),
				MAX_ROOM_PLAYERS
			]

		lobby_select.add_item(lobby_name)

	lobby_select.select(0)


func _is_pending_join_lobby_playing() -> bool:
	return (
		String(
			pending_join_lobby.get("state", "waiting")
		)
		== "playing"
	)


func _steam_manager() -> Node:
	return get_node_or_null("/root/SteamManager")


func _room_name() -> String:
	if not room_name_input:
		return _t("default_connection_name")

	var entered_name := room_name_input.text.strip_edges()

	return (
		entered_name
		if not entered_name.is_empty()
		else _t("default_connection_name")
	)


func _steam_ready() -> bool:
	var steam_manager := _steam_manager()

	return (
		steam_manager != null
		and steam_manager.has_method("is_ready")
		and bool(steam_manager.is_ready())
	)


func _steam_not_ready_message() -> String:
	if _language() == "geo":
		return "Steam-ში შესული არ ხარ."

	return "You are not signed in to Steam."


func _connect_steam_manager() -> void:
	var steam_manager := _steam_manager()

	if not steam_manager:
		return

	if (
		steam_manager.has_signal("lobby_created")
		and not steam_manager.lobby_created.is_connected(
			_finish_steam_host_lobby
		)
	):
		steam_manager.lobby_created.connect(
			_finish_steam_host_lobby
		)

	if (
		steam_manager.has_signal("lobby_joined")
		and not steam_manager.lobby_joined.is_connected(
			_finish_steam_join_lobby
		)
	):
		steam_manager.lobby_joined.connect(
			_finish_steam_join_lobby
		)

	if (
		steam_manager.has_signal("lobby_list_updated")
		and not steam_manager.lobby_list_updated.is_connected(
			_on_steam_lobby_list_updated
		)
	):
		steam_manager.lobby_list_updated.connect(
			_on_steam_lobby_list_updated
		)

	if (
		steam_manager.has_signal("steam_failed")
		and not steam_manager.steam_failed.is_connected(
			_on_steam_failed
		)
	):
		steam_manager.steam_failed.connect(_on_steam_failed)


func _on_steam_failed(_message: String) -> void:
	if (
		online_connection_mode == ONLINE_MODE_STEAM
		and online_page
		and online_page.visible
		and online_status
	):
		# Do not expose Steamworks/IPC technical errors to the player.
		online_status.text = _steam_not_ready_message()

	_update_room_buttons()


func _update_room_buttons() -> void:
	if not host_button or not join_button or not online_start_button:
		return

	_sync_online_state_with_peer()
	_update_online_mode_ui()

	var hosting := is_hosting_room()
	var joining := is_joining_room()
	var has_peer := multiplayer.multiplayer_peer != null

	host_button.disabled = joining

	_update_online_action_button_text()

	join_button.disabled = (
		hosting
		or steam_lobbies.is_empty()
		or (joining and has_peer)
	)

	online_start_button.visible = false
	online_start_button.disabled = true


func _update_online_action_button_text() -> void:
	if not host_button or not join_button:
		return

	if is_hosting_room():
		host_button.text = _t("return_to_match")
	else:
		host_button.text = _t("host_room")

	join_button.text = _t("join")


@rpc("any_peer", "reliable")
func _client_online_character_selected(character: String) -> void:
	if not is_hosting_room():
		return

	var sender_id := multiplayer.get_remote_sender_id()

	if (
		sender_id == 0
		or not multiplayer.get_peers().has(sender_id)
	):
		return

	if (
		settings
		and String(settings.get("game_mode")) != "squad"
		and bool(settings.get("character_chosen")) == true
		and String(settings.get("selected_character")) == character
	):
		_sync_online_character_state()
		return

	remote_client_character = character
	remote_client_character_chosen = true
	if settings and String(settings.get("game_mode")) == "squad":
		squad_character_choices[sender_id] = character
	other_player_character = character
	other_player_character_chosen = true

	if settings:
		settings.set("online_remote_character", character)

	_set_online_status_with_player_line(_t("player_connected"))
	_emit_character_refresh()
	_update_room_buttons()
	_sync_online_character_state()
	_try_auto_start_online_match()


func _sync_online_character_state() -> void:
	if not is_hosting_room():
		return

	var host_character := "player"
	var host_character_chosen := false

	if settings:
		host_character = String(
			settings.get("selected_character")
		)
		host_character_chosen = (
			bool(settings.get("character_chosen")) == true
		)

	rpc(
		"_online_character_state_updated",
		host_character_chosen,
		host_character,
		remote_client_character_chosen,
		remote_client_character
	)


@rpc("authority", "reliable")
func _online_character_state_updated(
	host_character_chosen: bool,
	host_character: String,
	_client_character_chosen: bool,
	_client_character: String
) -> void:
	if is_hosting_room():
		return

	if not is_joining_room():
		return

	other_player_character = host_character
	other_player_character_chosen = host_character_chosen

	if (
		settings
		and String(settings.get("game_mode")) != "squad"
		and bool(settings.get("character_chosen")) == true
		and host_character_chosen
		and String(settings.get("selected_character"))
			== host_character
	):
		settings.set("character_chosen", false)
		_request_character_status(_t("connected_choose"))

	_emit_character_refresh()
	_update_room_buttons()


@rpc("authority", "reliable")
func _start_online_match(
	scene_path: String = MAIN_SCENE
) -> void:
	if settings:
		settings.set("character_chosen", true)

	joined_room_waiting_for_character = false
	online_match_starting = true

	get_tree().change_scene_to_file(
		_store_online_scene_path(scene_path)
	)


func _valid_online_scene_path(scene_path: String) -> String:
	match scene_path:
		MAIN_SCENE, MEDIUM_SCENE, HARD_SCENE, SQUAD_SCENE:
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
	var valid_scene_path := _valid_online_scene_path(
		scene_path
	)

	if settings:
		settings.set("online_scene_path", valid_scene_path)
		settings.set(
			"selected_level",
			_level_for_scene_path(valid_scene_path)
		)
		settings.set("level_chosen", true)

	return valid_scene_path


func _online_scene_path_from_settings() -> String:
	if settings:
		return _valid_online_scene_path(
			String(settings.get("online_scene_path"))
		)

	return MAIN_SCENE


func _pending_lobby_scene_path() -> String:
	return _valid_online_scene_path(
		String(
			pending_join_lobby.get(
				"scene_path",
				MAIN_SCENE
			)
		)
	)


func _selected_main_scene() -> String:
	if settings and String(settings.get("game_mode")) == "squad":
		return SQUAD_SCENE
	if (
		selected_main_scene_callback is Callable
		and selected_main_scene_callback.is_valid()
	):
		return String(selected_main_scene_callback.call())

	if settings:
		var selected_level := String(
			settings.get("selected_level")
		)

		if selected_level == "hard":
			return HARD_SCENE
		if selected_level == "medium":
			return MEDIUM_SCENE

	return MAIN_SCENE


func _sync_online_state_with_peer() -> void:
	if not settings:
		return

	if bool(settings.get("online_mode")) != true:
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

	_emit_character_refresh()


func _set_online_status_with_player_line(
	base_text: String
) -> void:
	if online_status:
		if settings and String(settings.get("game_mode")) == "squad":
			online_status.text = "%s\nPlayers: %d/%d (2 vs 2)" % [
				base_text,
				hosted_player_count,
				MAX_ROOM_PLAYERS
			]
		else:
			online_status.text = base_text


func _make_room_id() -> String:
	return "%d-%d" % [
		Time.get_ticks_msec(),
		randi()
	]


func _character_display_name(character: String) -> String:
	match character:
		"golem":
			return "Stone Golem"
		"ice_golem":
			return "Ice Golem"
		"crusader":
			return "Skeleton Crusader"
		"wraith":
			return "Wraith"

	return "Ash Golem"


func _request_character_page(status_text: String) -> void:
	character_page_requested.emit(status_text)
	_emit_character_refresh()


func _request_character_status(status_text: String) -> void:
	character_status_requested.emit(status_text)


func _emit_character_refresh() -> void:
	character_refresh_requested.emit()


func _show_page(page: Control) -> void:
	if (
		show_page_callback is Callable
		and show_page_callback.is_valid()
	):
		show_page_callback.call(page)


func _t(key: String) -> String:
	if (
		translate_callback is Callable
		and translate_callback.is_valid()
	):
		return String(translate_callback.call(key))

	return key


func _language() -> String:
	if (
		language_callback is Callable
		and language_callback.is_valid()
	):
		return String(language_callback.call())

	return "eng"
