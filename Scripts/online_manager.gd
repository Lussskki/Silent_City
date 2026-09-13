extends CanvasLayer

const PORT := 8910
const MAX_CLIENTS := 3
const SECOND_PLAYER_NAME := "SecondPlayer"
const SECOND_PLAYER_SPAWNS_BY_SCENE := {
	"res://Scenes/main.tscn": Vector2(3264, 404),
	"res://Scenes/MainMedium.tscn": Vector2(3264, 410),
	"res://Scenes/MainHard.tscn": Vector2(3264, 195),
	"res://Scenes/SquadArena.tscn": Vector2(3250, 228),
}
const SQUAD_ARENA_SCENE := "res://Scenes/SquadArena.tscn"
const SQUAD_ARENA_SPAWNS: Array[Vector2] = [
	Vector2(1090, 178),
	Vector2(2510, 178),
	Vector2(1090, 578),
	Vector2(2510, 578),
]
const ASH_GOLEM_FRAMES_ROOT := "res://Player/player_assets/PNG Sequences"
const ONLINE_CHARACTER_SPRITE_OFFSETS := {
	"player": Vector2(0, -24),
	"golem": Vector2(0, -24),
	"ice_golem": Vector2(0, -24),
	"crusader": Vector2(0, -24),
	"wraith": Vector2(0, -24),
	"minotaur": Vector2(0, -32),
	"ranger": Vector2(0, -24),
}
const GEORGIAN_QWERTY_TO_LATIN := {
	"ა": "a",
	"ბ": "b",
	"ც": "c",
	"დ": "d",
	"ე": "e",
	"ფ": "f",
	"გ": "g",
	"ჰ": "h",
	"ი": "i",
	"ჯ": "j",
	"კ": "k",
	"ლ": "l",
	"მ": "m",
	"ნ": "n",
	"ო": "o",
	"პ": "p",
	"ქ": "q",
	"რ": "r",
	"ს": "s",
	"ტ": "t",
	"უ": "u",
	"ვ": "v",
	"წ": "w",
	"ხ": "x",
	"ყ": "y",
	"ზ": "z",
	"თ": "t",
	"შ": "s",
	"ჩ": "c",
	"ძ": "z",
	"ჟ": "j",
	"ღ": "r",
	"ჭ": "w",
}
const ICE_GOLEM_FRAMES_ROOT := "res://Characters/Golem_1/PNG/PNG Sequences"
const CRUSADER_FRAMES_ROOT := "res://Characters/Skeleton_crusider/Skeleton_Crusader_1/PNG/PNG Sequences"
const WRAITH_FRAMES_ROOT := "res://Characters/Wraithes/PNG/Wraith_01/PNG Sequences"
const MINOTAUR_FRAMES_ROOT := "res://Characters/Minotaurs/Minotaur_3/PNG/PNG Sequences"
const RANGER_FRAMES_ROOT := "res://Characters/Forest_Ranger_2/PNG/PNG Sequences"
const SQUAD_IDLE_TEXTURES := {
	"crusader": preload("res://Characters/Skeleton_crusider/Skeleton_Crusader_1/PNG/PNG Sequences/Idle/0_Skeleton_Crusader_Idle_000.png"),
	"wraith": preload("res://Characters/Wraithes/PNG/Wraith_01/PNG Sequences/Idle/Wraith_01_Idle_000.png"),
	"minotaur": preload("res://Characters/Minotaurs/Minotaur_3/PNG/PNG Sequences/Idle/0_Minotaur_Idle_000.png"),
	"ranger": preload("res://Characters/Forest_Ranger_2/PNG/PNG Sequences/Idle/0_Forest_Ranger_Idle_000.png")
}
const SQUAD_CHARACTER_FRAMES := {
	"crusader": preload("res://Resources/squad_crusader_sprite_frames.tres"),
	"wraith": preload("res://Resources/squad_wraith_sprite_frames.tres"),
	"minotaur": preload("res://Resources/squad_minotaur_sprite_frames.tres"),
	"ranger": preload("res://Resources/squad_ranger_sprite_frames.tres")
}
const ASH_GOLEM_ANIMATION_DIRS := {
	"Idle": "Idle",
	"Walking": "Walking",
	"Running": "Running",
	"Jump Looping": "Jump Loop",
	"Falling Down": "Falling Down",
	"Slashing": "Slashing",
	"Slashing In Air": "Slashing in The Air",
	"Run Slashing": "Run Slashing",
	"Kicking": "Kicking",
	"Throwing": "Throwing",
	"Throwing In Air": "Throwing in The Air",
	"Dying": "Dying",
	"Sliding": "Sliding"
}
const WRAITH_ANIMATION_DIRS := {
	"Idle": "Idle", "Walking": "Walking", "Running": "Walking",
	"Jump Looping": "Idle", "Falling Down": "Idle",
	"Slashing": "Attacking", "Slashing In Air": "Attacking",
	"Run Slashing": "Attacking", "Kicking": "Attacking",
	"Hurt": "Hurt", "Throwing": "Casting Spells",
	"Throwing In Air": "Casting Spells", "Dying": "Dying",
	"Sliding": "Walking"
}
const MINOTAUR_ANIMATION_DIRS := {
	"Idle": "Idle", "Walking": "Walking", "Running": "Running",
	"Jump Looping": "Jump Loop", "Falling Down": "Falling Down",
	"Slashing": "Slashing", "Slashing In Air": "Slashing in The Air",
	"Run Slashing": "Run Slashing", "Kicking": "Kicking",
	"Hurt": "Hurt", "Throwing": "Throwing",
	"Throwing In Air": "Throwing In The Air", "Dying": "Dying",
	"Sliding": "Sliding"
}
const RANGER_ANIMATION_DIRS := {
	"Idle": "Idle", "Walking": "Walking", "Running": "Running",
	"Jump Looping": "Jump Loop", "Falling Down": "Falling Down",
	"Slashing": "Shooting", "Slashing In Air": "Shooting in The Air",
	"Run Slashing": "Run Shooting", "Kicking": "Kicking",
	"Hurt": "Hurt", "Throwing": "Throwing",
	"Throwing In Air": "Throwing in The Air", "Dying": "Dying",
	"Sliding": "Sliding"
}

@export var golem_player_scene: PackedScene

@onready var ip_input := get_node_or_null("Panel/IPInput") as LineEdit
@onready var host_button := get_node_or_null("Panel/HostButton") as Button
@onready var join_button := get_node_or_null("Panel/JoinButton") as Button
@onready var status_label := get_node_or_null("Panel/StatusLabel") as Label

var main_player: Node
var spawned_players := {}
var first_player_spawn := Vector2.ZERO
var second_player_spawn := Vector2.ZERO
var squad_spawn_points: Array[Vector2] = []
var peer_slots: Dictionary = {1: 0}
var peer_characters: Dictionary = {}
var peer_teams: Dictionary = {1: 1}
var closing_online_session := false
var client_ready_sent := false


func send_chat_message(message: String) -> void:
	if not multiplayer.has_multiplayer_peer():
		return

	var clean_message := _normalize_qwerty_chat_text(message).strip_edges()
	if clean_message.is_empty():
		return

	clean_message = clean_message.left(120)
	var author := _local_chat_name()
	_add_chat_message(author, clean_message, false)
	rpc("_receive_chat_message", author, clean_message)


func _ready() -> void:
	add_to_group("OnlineManager")
	main_player = get_tree().get_first_node_in_group("Player")
	_cache_scene_spawns()
	_configure_main_player(true)
	_hide_second_player()
	if host_button:
		host_button.pressed.connect(_host_game)
	if join_button:
		join_button.pressed.connect(_join_game)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.visible = false
	_set_status("Online: Offline")
	_bootstrap_menu_connection.call_deferred()


func _host_game() -> void:
	_reset_network()

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		_set_status("Online host failed: %s" % _error_message(error))
		return

	multiplayer.multiplayer_peer = peer
	_configure_main_player(true)
	_set_status("Online: Hosting")


func _join_game() -> void:
	_reset_network()

	var address := _parse_join_address(ip_input.text if ip_input else "")
	var join_ip := String(address.get("ip", "")).strip_edges()
	if join_ip.is_empty():
		_set_status("Online join failed: no Wi-Fi host address")
		return

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(join_ip, int(address["port"]))
	if error != OK:
		_set_status("Online join failed: %s" % _error_message(error))
		return

	multiplayer.multiplayer_peer = peer
	_set_status("Online: Joining...")


func _on_connected_to_server() -> void:
	if client_ready_sent:
		return
	client_ready_sent = true
	var local_id := multiplayer.get_unique_id()
	var character := _selected_character()
	_configure_main_player(true, local_id, _spawn_point_for_peer(local_id))
	_apply_character_to_player(main_player, character)
	_face_player_for_spawn(main_player, local_id)
	_set_status("Online: Connected")
	rpc_id(1, "_client_ready", local_id, character)


func _on_connection_failed() -> void:
	_set_status("Online: Connection failed")
	client_ready_sent = false

	var peer := multiplayer.multiplayer_peer
	if peer and peer.has_method("close"):
		peer.close()
	multiplayer.multiplayer_peer = null

	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("reset_online"):
		settings.reset_online()

	_reset_steam_session()
	_remove_spawned_players()
	_configure_main_player(true)


func _on_server_disconnected() -> void:
	if closing_online_session:
		return
	_set_status("Online: Server disconnected")
	_prepare_disconnected_session_for_modal()
	_show_online_disconnect_modal("Host left the server.")


func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_assign_peer_slot(peer_id)
	_set_status("Online: Player connected")


func _on_peer_disconnected(peer_id: int) -> void:
	if closing_online_session:
		return

	var player_name := _player_node_name(peer_id)
	var player := spawned_players.get(player_name) as Node2D
	if player:
		player.queue_free()
	spawned_players.erase(player_name)
	peer_slots.erase(peer_id)
	peer_characters.erase(peer_id)
	peer_teams.erase(peer_id)
	_show_online_disconnect_modal("A Squad player left the server.")


func close_online_session(match_finished: bool = false) -> void:
	if closing_online_session:
		return

	closing_online_session = true

	# If the host is finishing the match, tell the client first.
	if multiplayer.is_server() and multiplayer.has_multiplayer_peer() and match_finished:
		rpc("_finished_match_room_closed")
		await get_tree().process_frame

	# IMPORTANT FOR WI-FI:
	# Always close the ENet peer when leaving the match.
	# Do not keep an old host room alive in Main Menu.
	_close_online_session_local()


@rpc("any_peer", "reliable")
func _client_ready(peer_id: int, character: String = "golem") -> void:
	if not multiplayer.is_server():
		return

	_complete_peer_spawn(peer_id, character)


@rpc("authority", "reliable")
func _spawn_remote_golem(peer_id: int, character: String = "golem") -> void:
	_spawn_golem_player(peer_id, false, character, _team_for_peer(peer_id))


@rpc("authority", "reliable")
func _spawn_remote_player(
	peer_id: int,
	character: String,
	team_id: int,
	slot: int
) -> void:
	peer_slots[peer_id] = slot
	peer_characters[peer_id] = character
	peer_teams[peer_id] = team_id
	_spawn_golem_player(peer_id, false, character, team_id)


@rpc("authority", "reliable")
func _configure_local_squad_player(slot: int, team_id: int) -> void:
	var local_id := multiplayer.get_unique_id()
	peer_slots[local_id] = slot
	peer_teams[local_id] = team_id
	peer_characters[local_id] = _selected_character()
	_configure_main_player(true, local_id, _spawn_point_for_slot(slot), team_id)
	_apply_character_to_player(main_player, _selected_character())
	_face_player_for_team(main_player, team_id)


@rpc("authority", "reliable")
func _apply_remote_host_character(character: String = "player") -> void:
	if main_player:
		_apply_character_to_player(main_player, character)
		_face_player_east(main_player)


@rpc("authority", "reliable")
func _finished_match_room_closed() -> void:
	if multiplayer.is_server():
		return
	_set_status("Online: Match finished")
	_close_online_session_local()


func _complete_peer_spawn(peer_id: int, character: String = "golem") -> void:
	if not multiplayer.is_server():
		return

	var slot := _assign_peer_slot(peer_id)
	var team_id := _team_for_slot(slot)
	peer_characters[peer_id] = character
	peer_teams[peer_id] = team_id
	_spawn_golem_player(peer_id, false, character, team_id)
	rpc_id(peer_id, "_configure_local_squad_player", slot, team_id)

	# Give the new player every existing remote proxy, then announce the new
	# player to all clients already in the match.
	var host_character := _selected_character()
	rpc_id(peer_id, "_spawn_remote_player", 1, host_character, 1, 0)
	for existing_peer in peer_characters.keys():
		var existing_id := int(existing_peer)
		if existing_id == 1 or existing_id == peer_id:
			continue
		rpc_id(
			peer_id,
			"_spawn_remote_player",
			existing_id,
			String(peer_characters[existing_id]),
			int(peer_teams[existing_id]),
			int(peer_slots[existing_id])
		)
	for target_peer in multiplayer.get_peers():
		if target_peer == peer_id or not peer_characters.has(target_peer):
			continue
		rpc_id(
			target_peer,
			"_spawn_remote_player",
			peer_id,
			character,
			team_id,
			slot
		)


func _bootstrap_menu_connection() -> void:
	if not multiplayer.has_multiplayer_peer():
		return

	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		var panel := get_node_or_null("Panel") as Control
		if panel:
			panel.visible = false

	if multiplayer.is_server():
		peer_slots = {1: 0}
		peer_teams = {1: 1}
		peer_characters = {1: _selected_character()}
		_configure_main_player(true, 1, _spawn_point_for_slot(0), 1)
		var character := _selected_character()
		_apply_character_to_player(main_player, character)
		_face_player_for_team(main_player, 1)
		_set_status("Online: Hosting")
		if not _is_squad_mode():
			for peer_id in multiplayer.get_peers():
				_complete_peer_spawn.call_deferred(peer_id, _remote_client_character())
	else:
		_on_connected_to_server()


func _configure_main_player(
	controlled_locally: bool,
	player_id := 1,
	spawn_point := Vector2.INF,
	team_id := 0
) -> void:
	if not main_player:
		return
	main_player.global_position = first_player_spawn if spawn_point == Vector2.INF else spawn_point
	if main_player.has_method("configure_online_player"):
		main_player.configure_online_player(player_id, controlled_locally, team_id)


func _spawn_golem_player(
	peer_id: int,
	controlled_locally: bool,
	character: String = "golem",
	team_id := 0
) -> void:
	var player_name := _player_node_name(peer_id)
	var player := spawned_players.get(player_name) as Node2D
	if not player:
		if not golem_player_scene:
			return
		player = golem_player_scene.instantiate() as Node2D
		player.name = player_name
		get_parent().add_child(player)

	player.global_position = _spawn_point_for_peer(peer_id)
	_set_player_active(player, true)
	spawned_players[player_name] = player

	if player.has_method("configure_online_player"):
		player.configure_online_player(peer_id, controlled_locally, team_id)
	_apply_character_to_player(player, character)
	# The player scene initializes its default Skeleton frames in _ready().
	# Reapply the network-authoritative skin after that initialization frame so
	# a remote proxy cannot remain on the scene's default skin.
	call_deferred("_apply_character_to_player", player, character)
	_face_player_for_team(player, team_id)


func is_second_player_connected() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return false
	if multiplayer.is_server():
		return multiplayer.get_peers().size() > 0
	return true


@rpc("any_peer", "unreliable_ordered")
func _receive_player_network_state(owner_peer_id: int, remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_animation: String, remote_life: int, remote_dead: bool = false) -> void:
	var api := get_multiplayer()
	if api == null or not api.has_multiplayer_peer():
		return
	var sender_id := api.get_remote_sender_id()
	if sender_id == 0 or owner_peer_id != sender_id:
		return
	_apply_player_network_state(owner_peer_id, remote_position, remote_velocity, remote_flip_h, remote_animation, remote_life, remote_dead)
	if api.is_server():
		_relay_player_network_state(
			"_receive_relayed_player_network_state",
			sender_id,
			owner_peer_id,
			remote_position,
			remote_velocity,
			remote_flip_h,
			remote_animation,
			remote_life,
			remote_dead
		)


@rpc("any_peer", "reliable")
func _receive_forced_player_network_state(owner_peer_id: int, remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_animation: String, remote_life: int, remote_dead: bool = false) -> void:
	var api := get_multiplayer()
	if api == null or not api.has_multiplayer_peer():
		return
	var sender_id := api.get_remote_sender_id()
	if sender_id == 0 or owner_peer_id != sender_id:
		return
	_apply_player_network_state(owner_peer_id, remote_position, remote_velocity, remote_flip_h, remote_animation, remote_life, remote_dead)
	if api.is_server():
		_relay_player_network_state(
			"_receive_relayed_forced_player_network_state",
			sender_id,
			owner_peer_id,
			remote_position,
			remote_velocity,
			remote_flip_h,
			remote_animation,
			remote_life,
			remote_dead
		)


func _relay_player_network_state(
	rpc_name: String,
	sender_id: int,
	owner_peer_id: int,
	remote_position: Vector2,
	remote_velocity: Vector2,
	remote_flip_h: bool,
	remote_animation: String,
	remote_life: int,
	remote_dead: bool
) -> void:
	if not multiplayer.is_server():
		return

	for target_peer_id in multiplayer.get_peers():
		if target_peer_id == sender_id:
			continue
		rpc_id(
			target_peer_id,
			rpc_name,
			owner_peer_id,
			remote_position,
			remote_velocity,
			remote_flip_h,
			remote_animation,
			remote_life,
			remote_dead
		)


@rpc("authority", "unreliable_ordered")
func _receive_relayed_player_network_state(owner_peer_id: int, remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_animation: String, remote_life: int, remote_dead: bool = false) -> void:
	_apply_player_network_state(owner_peer_id, remote_position, remote_velocity, remote_flip_h, remote_animation, remote_life, remote_dead)


@rpc("authority", "reliable")
func _receive_relayed_forced_player_network_state(owner_peer_id: int, remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_animation: String, remote_life: int, remote_dead: bool = false) -> void:
	_apply_player_network_state(owner_peer_id, remote_position, remote_velocity, remote_flip_h, remote_animation, remote_life, remote_dead)


func _apply_player_network_state(peer_id: int, remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_animation: String, remote_life: int, remote_dead: bool) -> void:
	var player := _remote_player_for_peer(peer_id)
	if not player:
		return
	# While moving, derive facing from the authoritative movement direction.
	# This avoids mirroring the second player's sprite when a stale/raw flip
	# value arrives through the relay. When standing still, preserve the last
	# explicitly transmitted facing direction.
	if not is_zero_approx(remote_velocity.x):
		remote_flip_h = remote_velocity.x < 0.0
	if player.has_method("_apply_remote_network_state"):
		player.call("_apply_remote_network_state", remote_position, remote_velocity, remote_flip_h, remote_animation, remote_life, remote_dead)


@rpc("any_peer", "reliable")
func _receive_player_damage(amount: int) -> void:
	var player := _local_controlled_player()
	if player and player.has_method("take_damage"):
		player.call("take_damage", amount)


func report_squad_defeat(player_id: int, defeated_team: int) -> void:
	if not _is_squad_mode() or defeated_team not in [1, 2]:
		return
	if multiplayer.is_server():
		_award_squad_point(player_id, defeated_team)
	else:
		rpc_id(1, "_report_squad_defeat", player_id, defeated_team)


@rpc("any_peer", "reliable")
func _report_squad_defeat(player_id: int, defeated_team: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != player_id:
		return
	_award_squad_point(player_id, defeated_team)


func _award_squad_point(_player_id: int, defeated_team: int) -> void:
	var winner_team := 2 if defeated_team == 1 else 1
	_apply_squad_point(winner_team)
	rpc("_apply_squad_point", winner_team)


@rpc("authority", "reliable")
func _apply_squad_point(winner_team: int) -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("record_online_round"):
		settings.record_online_round("Team %d" % winner_team)


@rpc("any_peer", "reliable")
func _receive_chat_message(author: String, message: String) -> void:
	var api := get_multiplayer()
	if api == null or not api.has_multiplayer_peer():
		return

	var peer_id := api.get_remote_sender_id()
	if peer_id == 0:
		return

	var clean_author := author.strip_edges().left(24)
	var clean_message := _normalize_qwerty_chat_text(message).strip_edges().left(120)
	if clean_author.is_empty():
		clean_author = "Player %d" % peer_id
	if clean_message.is_empty():
		return

	_add_chat_message(clean_author, clean_message, true)


func _add_chat_message(author: String, message: String, notify := false) -> void:
	var hud := get_tree().get_first_node_in_group("PlayerHUD")
	if hud and hud.has_method("add_chat_message"):
		hud.call("add_chat_message", author, message, notify)


func _normalize_qwerty_chat_text(value: String) -> String:
	var result := ""
	for index in range(value.length()):
		var character := value.substr(index, 1)
		result += String(GEORGIAN_QWERTY_TO_LATIN.get(character, character))
	return result


func _local_chat_name() -> String:
	var character := _selected_character()
	if character == "crusader":
		return "Skeleton Crusader"
	if character == "wraith":
		return "Wraith"
	if character == "minotaur":
		return "Minotaur"
	if character == "ranger":
		return "Forest Ranger"
	if character == "ice_golem":
		return "Ice Golem"
	if character == "golem":
		return "Stone Golem"
	return "Ash Golem"


func _local_controlled_player() -> Node:
	var players: Array[Node] = []
	if main_player:
		players.append(main_player)
	for spawned_player in spawned_players.values():
		if spawned_player is Node:
			players.append(spawned_player)

	for player in players:
		if bool(player.get("local_player")):
			return player

	return null


func _remote_player_for_peer(peer_id: int) -> Node:
	var players: Array[Node] = []
	if main_player:
		players.append(main_player)
	for spawned_player in spawned_players.values():
		if spawned_player is Node:
			players.append(spawned_player)

	for player in players:
		var player_id := int(player.get("network_player_id"))
		var controlled_locally := bool(player.get("local_player"))
		if player_id == peer_id and not controlled_locally:
			return player

	return null


func _remove_spawned_players() -> void:
	for player in spawned_players.values():
		if player is Node2D:
			player.queue_free()
	spawned_players.clear()
	peer_slots = {1: 0}
	peer_characters.clear()
	peer_teams = {1: 1}
	_hide_second_player()


func _reset_network() -> void:
	# A fresh Wi-Fi Host/Join must never inherit the previous session state.
	closing_online_session = false
	client_ready_sent = false

	_reset_steam_session()

	var peer := multiplayer.multiplayer_peer
	if peer and peer.has_method("close"):
		peer.close()
	multiplayer.multiplayer_peer = null

	_remove_spawned_players()
	_configure_main_player(true)


func _hide_second_player() -> void:
	var player := get_parent().get_node_or_null(SECOND_PLAYER_NAME) as Node2D
	if not player:
		return
	if player.has_method("configure_online_player"):
		player.configure_online_player(2, false)
	_set_player_active(player, false)


func _set_player_active(player: Node2D, active: bool) -> void:
	if player.has_method("set_online_player_active"):
		player.set_online_player_active(active)
	else:
		player.visible = active


func _apply_character_to_player(player: Node2D, character: String) -> void:
	if _is_squad_mode() and character not in [
		"crusader",
		"wraith",
		"minotaur",
		"ranger"
	]:
		character = "crusader"
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not sprite:
		return
	if player.has_method("set_sprite_flip_inverted"):
		player.call("set_sprite_flip_inverted", character in ["golem", "ice_golem", "crusader", "wraith", "minotaur", "ranger"])

	if character in ["crusader", "wraith", "minotaur", "ranger"]:
		var frames_root := CRUSADER_FRAMES_ROOT
		var animation_dirs: Dictionary = ASH_GOLEM_ANIMATION_DIRS
		if character == "wraith":
			frames_root = WRAITH_FRAMES_ROOT
			animation_dirs = WRAITH_ANIMATION_DIRS
		elif character == "minotaur":
			frames_root = MINOTAUR_FRAMES_ROOT
			animation_dirs = MINOTAUR_ANIMATION_DIRS
		elif character == "ranger":
			frames_root = RANGER_FRAMES_ROOT
			animation_dirs = RANGER_ANIMATION_DIRS
		var squad_frames := SQUAD_CHARACTER_FRAMES.get(character) as SpriteFrames
		if not squad_frames:
			squad_frames = _build_sprite_frames_from_root(frames_root, animation_dirs)
		if not squad_frames.has_animation("Idle"):
			var idle_texture := SQUAD_IDLE_TEXTURES.get(character) as Texture2D
			if idle_texture:
				squad_frames.add_animation("Idle")
				squad_frames.add_frame("Idle", idle_texture)
		if squad_frames.has_animation("Idle"):
			sprite.sprite_frames = squad_frames
			sprite.position = _online_character_sprite_offset(character)
			sprite.scale = Vector2(0.22, 0.22) if character in ["crusader", "ranger"] else Vector2(0.34, 0.34)
			sprite.play("Idle")
		return

	if character == "ice_golem":
		var ice_frames := _build_sprite_frames_from_root(ICE_GOLEM_FRAMES_ROOT)
		if ice_frames.has_animation("Idle"):
			sprite.sprite_frames = ice_frames
			sprite.position = _online_character_sprite_offset(character)
			sprite.play("Idle")
		_apply_stone_golem_sounds(player)
		return

	if character == "golem":
		var golem_frames := load("res://Resources/golem_sprite_frames.tres") as SpriteFrames
		if golem_frames:
			sprite.sprite_frames = golem_frames
			if player.has_method("_add_animation_from_folder"):
				player.call("_add_animation_from_folder", sprite.sprite_frames, "Hurt", "res://Characters/Golem/PNG/PNG Sequences/Hurt", 12.0, false)
			sprite.position = _online_character_sprite_offset(character)
			sprite.play("Idle")
		_apply_stone_golem_sounds(player)
		return

	var settings := get_node_or_null("/root/GameSettings")
	var player_frames = _get_ash_golem_frames(settings)
	if player_frames is SpriteFrames:
		sprite.sprite_frames = player_frames
		sprite.position = _online_character_sprite_offset(character)
		sprite.play("Idle")
		return


func _online_character_sprite_offset(character: String) -> Vector2:
	return ONLINE_CHARACTER_SPRITE_OFFSETS.get(character, ONLINE_CHARACTER_SPRITE_OFFSETS["player"])


func _spawn_point_for_peer(peer_id: int) -> Vector2:
	var slot := int(peer_slots.get(peer_id, 0 if peer_id == 1 else 1))
	return _spawn_point_for_slot(slot)


func _spawn_point_for_slot(slot: int) -> Vector2:
	if squad_spawn_points.is_empty():
		return first_player_spawn if slot == 0 else second_player_spawn
	return squad_spawn_points[clampi(slot, 0, squad_spawn_points.size() - 1)]


func _assign_peer_slot(peer_id: int) -> int:
	if peer_slots.has(peer_id):
		return int(peer_slots[peer_id])
	for slot in range(1, 4):
		if not peer_slots.values().has(slot):
			peer_slots[peer_id] = slot
			peer_teams[peer_id] = _team_for_slot(slot)
			return slot
	peer_slots[peer_id] = 3
	peer_teams[peer_id] = 2
	return 3


func _team_for_slot(slot: int) -> int:
	return 1 if slot % 2 == 0 else 2


func _team_for_peer(peer_id: int) -> int:
	return int(peer_teams.get(peer_id, _team_for_slot(int(peer_slots.get(peer_id, 0)))))


func _player_node_name(peer_id: int) -> String:
	return "OnlinePlayer_%d" % peer_id


func _is_squad_mode() -> bool:
	var settings := get_node_or_null("/root/GameSettings")
	return (
		(settings != null and String(settings.get("game_mode")) == "squad")
		or (
			get_tree().current_scene != null
			and get_tree().current_scene.scene_file_path == SQUAD_ARENA_SCENE
		)
	)


func _face_player_east(player: Node2D) -> void:
	_face_player(player, true)


func _face_player_for_spawn(player: Node2D, peer_id: int) -> void:
	_face_player(player, peer_id == 1)


func _face_player_for_team(player: Node2D, team_id: int) -> void:
	_face_player(player, team_id == 1)


func _face_player(player: Node2D, face_right: bool) -> void:
	if player.has_method("face_right"):
		player.call("face_right", face_right)
		return
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.flip_h = not face_right


func _apply_stone_golem_sounds(player: Node2D) -> void:
	var jump := load("res://Resources/character_voices/30_Jump_03.wav") as AudioStream
	var attack := load("res://Resources/character_voices/56_Attack_03.wav") as AudioStream
	var hit := load("res://Resources/character_voices/61_Hit_03.wav") as AudioStream
	var landing := load("res://Resources/character_voices/45_Landing_01.wav") as AudioStream

	player.set("jump_sound", jump)
	player.set("attack_sound", attack)
	player.set("kick_sound", hit)
	player.set("hit_sound", hit)
	player.set("landing_sound", landing)

	var sound_map := {
		"JumpSound": jump,
		"AttackSound": attack,
		"KickSound": hit,
		"HitSound": hit,
		"LandingSound": landing,
	}
	for sound_name in sound_map:
		var sound_player := player.get_node_or_null(sound_name) as AudioStreamPlayer2D
		if sound_player:
			sound_player.stream = sound_map[sound_name]


func _selected_character() -> String:
	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		var character := String(settings.get("selected_character"))
		if _is_squad_mode():
			if character == "player" or character.is_empty():
				return "crusader"
			if character == "golem":
				return "wraith"
			if character not in ["crusader", "wraith", "minotaur", "ranger"]:
				return "crusader"
		return character
	return "golem"


func _remote_client_character() -> String:
	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		return String(settings.get("online_remote_character"))
	return "golem"


func _set_status(text: String) -> void:
	if status_label:
		status_label.text = text


func _error_message(error: int) -> String:
	if error == ERR_CANT_CREATE:
		return "20 no network permission/port busy"
	return str(error)


func _parse_join_address(text: String) -> Dictionary:
	var value := text.strip_edges()

	# Empty input should not accidentally try localhost.
	# Wi-Fi discovery/menu should provide the host LAN IP.
	if value.is_empty():
		return {
			"ip": "",
			"port": PORT
		}

	var result := {
		"ip": value,
		"port": PORT
	}

	if value.contains(":"):
		var parts := value.split(":", false, 1)
		result["ip"] = parts[0].strip_edges()
		if parts.size() > 1 and parts[1].is_valid_int():
			result["port"] = int(parts[1])

	return result


func _cache_scene_spawns() -> void:
	if main_player is Node2D:
		first_player_spawn = (main_player as Node2D).global_position
	else:
		first_player_spawn = Vector2(300, 400)

	var scene_path := ""
	if get_tree().current_scene:
		scene_path = get_tree().current_scene.scene_file_path
	second_player_spawn = SECOND_PLAYER_SPAWNS_BY_SCENE.get(scene_path, first_player_spawn + Vector2(120, 0))
	if scene_path == SQUAD_ARENA_SCENE:
		squad_spawn_points = SQUAD_ARENA_SPAWNS.duplicate()
		first_player_spawn = squad_spawn_points[0]
		second_player_spawn = squad_spawn_points[1]
		return
	squad_spawn_points = [
		first_player_spawn,
		second_player_spawn,
		first_player_spawn + Vector2(140, 0),
		second_player_spawn - Vector2(140, 0)
	]


func _reset_steam_session() -> void:
	var steam_manager := get_node_or_null("/root/SteamManager")
	if steam_manager and steam_manager.has_method("reset_session"):
		steam_manager.reset_session()


func _prepare_disconnected_session_for_modal() -> void:
	client_ready_sent = false
	_reset_steam_session()

	var peer := multiplayer.multiplayer_peer
	if peer and peer.has_method("close"):
		peer.close()
	multiplayer.multiplayer_peer = null

	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("reset_online"):
		settings.reset_online()

	_remove_spawned_players()
	_configure_main_player(true)


func _show_online_disconnect_modal(message: String) -> void:
	var hud := get_tree().get_first_node_in_group("PlayerHUD")
	if hud and hud.has_method("show_online_disconnect_popup"):
		hud.call("show_online_disconnect_popup", message)


func _close_online_session_local() -> void:
	closing_online_session = true
	client_ready_sent = false

	_reset_steam_session()

	var peer := multiplayer.multiplayer_peer
	if peer and peer.has_method("close"):
		peer.close()
	multiplayer.multiplayer_peer = null

	_remove_spawned_players()

	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("reset_online"):
		settings.reset_online()

	if get_tree().current_scene and get_tree().current_scene.scene_file_path != "res://Scenes/MainMenu.tscn":
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _get_ash_golem_frames(settings: Node) -> SpriteFrames:
	if settings:
		var cached_frames = settings.get("player_sprite_frames")
		if cached_frames is SpriteFrames and cached_frames.has_animation("Idle") and not String(cached_frames.resource_path).contains("golem_sprite_frames"):
			return cached_frames

	var frames := SpriteFrames.new()
	for animation_name in ASH_GOLEM_ANIMATION_DIRS:
		var folder_name: String = ASH_GOLEM_ANIMATION_DIRS[animation_name]
		var folder_path := "%s/%s" % [ASH_GOLEM_FRAMES_ROOT, folder_name]
		var image_files := _get_png_files(folder_path)
		if image_files.is_empty():
			continue

		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 12.0)
		frames.set_animation_loop(animation_name, animation_name in ["Idle", "Walking", "Running", "Jump Looping", "Falling Down"])
		for file_name in image_files:
			var texture := load("%s/%s" % [folder_path, file_name]) as Texture2D
			if texture:
				frames.add_frame(animation_name, texture)

	if frames.has_animation("Idle"):
		if settings:
			settings.set("player_sprite_frames", frames)
		return frames
	return null


func _build_sprite_frames_from_root(frames_root: String, animation_dirs: Dictionary = ASH_GOLEM_ANIMATION_DIRS) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in animation_dirs:
		var folder_name: String = animation_dirs[animation_name]
		var folder_path := "%s/%s" % [frames_root, folder_name]
		var image_files := _get_png_files(folder_path)
		if image_files.is_empty():
			continue

		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 12.0)
		frames.set_animation_loop(animation_name, animation_name in ["Idle", "Walking", "Running", "Jump Looping", "Falling Down"])
		for file_name in image_files:
			var texture := load("%s/%s" % [folder_path, file_name]) as Texture2D
			if texture:
				frames.add_frame(animation_name, texture)
	return frames


func _get_png_files(folder_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(folder_path)
	if not dir:
		return files

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.to_lower().ends_with(".png"):
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files
