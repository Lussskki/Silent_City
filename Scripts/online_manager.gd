extends CanvasLayer

const PORT := 8910
const MAX_CLIENTS := 1
const SECOND_PLAYER_NAME := "SecondPlayer"
const SECOND_PLAYER_SPAWN_OFFSET := Vector2(-120, 0)
const SECOND_PLAYER_SPAWNS_BY_SCENE := {
	"res://Scenes/main.tscn": Vector2(3264, 404),
	"res://Scenes/MainMedium.tscn": Vector2(3008, 410),
	"res://Scenes/MainHard.tscn": Vector2(3282, 195),
}
const ASH_GOLEM_FRAMES_ROOT := "res://Player/player_assets/PNG Sequences"
const ONLINE_ASH_GOLEM_SPRITE_OFFSET := Vector2(0, -12)
const ONLINE_STONE_GOLEM_SPRITE_OFFSET := Vector2(0, -12)
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

@export var golem_player_scene: PackedScene

@onready var ip_input := get_node_or_null("Panel/IPInput") as LineEdit
@onready var host_button := get_node_or_null("Panel/HostButton") as Button
@onready var join_button := get_node_or_null("Panel/JoinButton") as Button
@onready var status_label := get_node_or_null("Panel/StatusLabel") as Label

var main_player: Node
var spawned_players := {}
var first_player_spawn := Vector2.ZERO
var second_player_spawn := Vector2.ZERO
var closing_online_session := false


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
	_reset_steam_session()
	multiplayer.multiplayer_peer = null
	_configure_main_player(true)


func _on_server_disconnected() -> void:
	_set_status("Online: Server disconnected")
	_close_online_session_local()


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


func close_online_session(match_finished: bool = false) -> void:
	if closing_online_session:
		return
	closing_online_session = true
	if multiplayer.is_server() and multiplayer.has_multiplayer_peer():
		if match_finished:
			rpc("_finished_match_room_closed")
			await get_tree().process_frame
			_close_online_session_local()
			return
		_return_host_to_menu_keep_room()
		return
	_close_online_session_local()


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
		_apply_character_to_player(main_player, _selected_character())
		_face_player_east(main_player)
		_set_status("Online: Hosting")
		for peer_id in multiplayer.get_peers():
			_complete_peer_spawn.call_deferred(peer_id, _remote_client_character())
	else:
		_on_connected_to_server()


func _configure_main_player(controlled_locally: bool) -> void:
	if not main_player:
		return
	main_player.global_position = first_player_spawn
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

	player.global_position = second_player_spawn
	_set_player_active(player, true)
	spawned_players[SECOND_PLAYER_NAME] = player

	if player.has_method("configure_online_player"):
		player.configure_online_player(peer_id, controlled_locally)
	_apply_character_to_player(player, character)
	_face_player_east(player)


func is_second_player_connected() -> bool:
	if not multiplayer.has_multiplayer_peer():
		return false
	if multiplayer.is_server():
		return multiplayer.get_peers().size() > 0
	return true


func _remove_spawned_players() -> void:
	for player in spawned_players.values():
		if player is Node2D:
			_set_player_active(player, false)
	spawned_players.clear()
	_hide_second_player()


func _reset_network() -> void:
	_reset_steam_session()
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
			sprite.position = ONLINE_STONE_GOLEM_SPRITE_OFFSET
			sprite.play("Idle")
		_apply_stone_golem_sounds(player)
		return

	var settings := get_node_or_null("/root/GameSettings")
	var player_frames = _get_ash_golem_frames(settings)
	if player_frames is SpriteFrames:
		sprite.sprite_frames = player_frames
		sprite.position = ONLINE_ASH_GOLEM_SPRITE_OFFSET
		sprite.play("Idle")
		return


func _face_player_east(player: Node2D) -> void:
	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.flip_h = false


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


func _cache_scene_spawns() -> void:
	if main_player is Node2D:
		first_player_spawn = (main_player as Node2D).global_position
	else:
		first_player_spawn = Vector2(300, 400)

	var scene_path := ""
	if get_tree().current_scene:
		scene_path = get_tree().current_scene.scene_file_path
	second_player_spawn = SECOND_PLAYER_SPAWNS_BY_SCENE.get(scene_path, first_player_spawn + SECOND_PLAYER_SPAWN_OFFSET)


func _reset_steam_session() -> void:
	var steam_manager := get_node_or_null("/root/SteamManager")
	if steam_manager and steam_manager.has_method("reset_session"):
		steam_manager.reset_session()


func _close_online_session_local() -> void:
	closing_online_session = true
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


func _return_host_to_menu_keep_room() -> void:
	_remove_spawned_players()
	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		settings.set("online_mode", true)
		settings.set("online_role", "host")
		settings.set("character_chosen", true)
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
