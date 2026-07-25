extends CanvasLayer

const PORT := 8910
const MAX_CLIENTS := 1
const SECOND_PLAYER_NAME := "SecondPlayer"
const FIRST_PLAYER_SPAWN := Vector2(300, 400)
const SECOND_PLAYER_SPAWN := Vector2(150, 400)

@export var golem_player_scene: PackedScene

@onready var ip_input := get_node_or_null("Panel/IPInput") as LineEdit
@onready var host_button := get_node_or_null("Panel/HostButton") as Button
@onready var join_button := get_node_or_null("Panel/JoinButton") as Button
@onready var status_label := get_node_or_null("Panel/StatusLabel") as Label

var main_player: Node
var spawned_players := {}


func _ready() -> void:
	main_player = get_tree().get_first_node_in_group("Player")
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

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(address["ip"], address["port"])
	if error != OK:
		_set_status("Online join failed: %s" % _error_message(error))
		return

	multiplayer.multiplayer_peer = peer
	_set_status("Online: Joining...")


func _on_connected_to_server() -> void:
	var local_id := multiplayer.get_unique_id()
	var character := _selected_character()
	_configure_main_player(false)
	_spawn_golem_player(local_id, true, character)
	_set_status("Online: Connected")
	rpc_id(1, "_client_ready", local_id, character)


func _on_connection_failed() -> void:
	_set_status("Online: Connection failed")
	multiplayer.multiplayer_peer = null
	_configure_main_player(true)


func _on_server_disconnected() -> void:
	_set_status("Online: Server disconnected")
	multiplayer.multiplayer_peer = null
	_remove_spawned_players()
	_configure_main_player(true)


func _on_peer_connected(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_set_status("Online: Player connected")
	_complete_peer_spawn.call_deferred(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	var player := spawned_players.get(SECOND_PLAYER_NAME) as Node2D
	if player:
		if player.has_method("configure_online_player"):
			player.configure_online_player(2, false)
		_set_player_active(player, false)
	spawned_players.erase(SECOND_PLAYER_NAME)


@rpc("any_peer", "reliable")
func _client_ready(peer_id: int, character: String = "golem") -> void:
	if not multiplayer.is_server():
		return

	_complete_peer_spawn(peer_id, character)


@rpc("authority", "reliable")
func _spawn_remote_golem(peer_id: int, character: String = "golem") -> void:
	_spawn_golem_player(peer_id, peer_id == multiplayer.get_unique_id(), character)


@rpc("authority", "reliable")
func _apply_remote_host_character(character: String = "player") -> void:
	if main_player:
		_apply_character_to_player(main_player, character)


func _complete_peer_spawn(peer_id: int, character: String = "golem") -> void:
	if not multiplayer.is_server():
		return

	_spawn_golem_player(peer_id, false, character)
	rpc_id(peer_id, "_spawn_remote_golem", peer_id, character)
	rpc_id(peer_id, "_apply_remote_host_character", _selected_character())


func _bootstrap_menu_connection() -> void:
	if not multiplayer.has_multiplayer_peer():
		return

	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		var panel := get_node_or_null("Panel") as Control
		if panel:
			panel.visible = false

	if multiplayer.is_server():
		_configure_main_player(true)
		_set_status("Online: Hosting")
		for peer_id in multiplayer.get_peers():
			_complete_peer_spawn.call_deferred(peer_id, _remote_client_character())
	else:
		_on_connected_to_server()


func _configure_main_player(controlled_locally: bool) -> void:
	if not main_player:
		return
	main_player.global_position = FIRST_PLAYER_SPAWN
	if main_player.has_method("configure_online_player"):
		main_player.configure_online_player(1, controlled_locally)


func _spawn_golem_player(peer_id: int, controlled_locally: bool, character: String = "golem") -> void:
	var player := get_parent().get_node_or_null(SECOND_PLAYER_NAME) as Node2D
	if not player:
		if not golem_player_scene:
			return
		player = golem_player_scene.instantiate() as Node2D
		player.name = SECOND_PLAYER_NAME
		get_parent().add_child(player)

	player.global_position = SECOND_PLAYER_SPAWN
	_set_player_active(player, true)
	spawned_players[SECOND_PLAYER_NAME] = player
	_apply_character_to_player(player, character)

	if player.has_method("configure_online_player"):
		player.configure_online_player(peer_id, controlled_locally)


func _remove_spawned_players() -> void:
	for player in spawned_players.values():
		if player is Node2D:
			_set_player_active(player, false)
	spawned_players.clear()
	_hide_second_player()


func _reset_network() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer:
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
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not sprite:
		return

	if character == "golem":
		var golem_frames := load("res://Resources/golem_sprite_frames.tres") as SpriteFrames
		if golem_frames:
			sprite.sprite_frames = golem_frames
			sprite.position = Vector2(0, -24)
			sprite.play("Idle")
		_apply_stone_golem_sounds(player)
		return

	var settings := get_node_or_null("/root/GameSettings")
	var player_frames = settings.get("player_sprite_frames") if settings else null
	if player_frames is SpriteFrames:
		sprite.sprite_frames = player_frames
		sprite.position = Vector2(0, -32)
		sprite.play("Idle")
		return

	if main_player:
		var main_sprite := main_player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if main_sprite and main_sprite.sprite_frames:
			sprite.sprite_frames = main_sprite.sprite_frames
			sprite.position = main_sprite.position
			sprite.play("Idle")


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
		return String(settings.get("selected_character"))
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
	if value.is_empty():
		value = "127.0.0.1"

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

