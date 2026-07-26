extends Node

signal steam_ready
signal steam_failed(message: String)
signal lobby_created(lobby_id: int)
signal lobby_joined(lobby_id: int)
signal lobby_list_updated(lobbies: Array)

const DEV_APP_ID := "480"
const LOBBY_TYPE_PUBLIC := 2
const LOBBY_COMPARISON_EQUAL := 0
const LOBBY_DISTANCE_FILTER_WORLDWIDE := 3
const MAX_LOBBY_MEMBERS := 2
const STEAM_VIRTUAL_PORT := 0

var steam: Object
var initialized := false
var last_error := ""
var current_lobby_id: int = 0
var available_lobbies: Array = []
var pending_lobby_name := "Silent City"


func _ready() -> void:
	OS.set_environment("SteamAppId", DEV_APP_ID)
	OS.set_environment("SteamGameId", DEV_APP_ID)

	if not Engine.has_singleton("Steam"):
		steam_failed.emit("GodotSteam is not loaded.")
		return

	steam = Engine.get_singleton("Steam")
	_connect_signal("lobby_created", _on_lobby_created)
	_connect_signal("lobby_joined", _on_lobby_joined)
	_connect_signal("lobby_match_list", _on_lobby_match_list)
	_connect_signal("lobby_chat_update", _on_lobby_chat_update)
	_connect_signal("join_requested", _on_join_requested)

	var result = steam.call("steamInitEx", int(DEV_APP_ID))
	initialized = _steam_init_succeeded(result)
	if initialized:
		last_error = ""
		steam_ready.emit()
	else:
		last_error = _steam_init_error(result)
		steam_failed.emit(last_error)


func _process(_delta: float) -> void:
	if initialized and steam:
		steam.call("run_callbacks")


func create_lobby(lobby_name: String = "Silent City") -> void:
	if not initialized:
		steam_failed.emit("Steam is not ready.")
		return
	if current_lobby_id != 0:
		leave_lobby()
	pending_lobby_name = lobby_name.strip_edges()
	if pending_lobby_name.is_empty():
		pending_lobby_name = "Silent City"
	steam.call("createLobby", LOBBY_TYPE_PUBLIC, MAX_LOBBY_MEMBERS)


func request_lobbies() -> void:
	if not initialized:
		steam_failed.emit("Steam is not ready.")
		return
	steam.call("addRequestLobbyListStringFilter", "game", "silent_city", LOBBY_COMPARISON_EQUAL)
	steam.call("addRequestLobbyListDistanceFilter", LOBBY_DISTANCE_FILTER_WORLDWIDE)
	steam.call("requestLobbyList")


func join_lobby(lobby_id: int) -> void:
	if not initialized:
		steam_failed.emit("Steam is not ready.")
		return
	if lobby_id == 0:
		steam_failed.emit("No Steam lobby found.")
		return
	steam.call("joinLobby", lobby_id)


func join_first_lobby() -> void:
	if available_lobbies.is_empty():
		request_lobbies()
		return
	join_lobby(int(available_lobbies[0].get("id", 0)))


func get_lobbies() -> Array:
	return available_lobbies.duplicate(true)


func set_lobby_match_state(state: String, host_character: String = "", client_character: String = "") -> void:
	if not initialized or not steam or current_lobby_id == 0:
		return
	steam.call("setLobbyData", current_lobby_id, "state", state)
	if not host_character.is_empty():
		steam.call("setLobbyData", current_lobby_id, "host_character", host_character)
	if not client_character.is_empty():
		steam.call("setLobbyData", current_lobby_id, "client_character", client_character)


func create_host_peer() -> MultiplayerPeer:
	if not ClassDB.class_exists("SteamMultiplayerPeer"):
		steam_failed.emit("Steam MultiplayerPeer addon is missing.")
		return null
	var peer := ClassDB.instantiate("SteamMultiplayerPeer") as MultiplayerPeer
	if not peer:
		steam_failed.emit("Could not create Steam MultiplayerPeer.")
		return null
	var error := int(peer.callv("create_host", [STEAM_VIRTUAL_PORT]))
	if error != OK:
		steam_failed.emit("Steam host peer failed: %s" % error)
		return null
	return peer


func create_client_peer_for_lobby(lobby_id: int) -> MultiplayerPeer:
	if not initialized or not steam:
		steam_failed.emit("Steam is not ready.")
		return null
	if not ClassDB.class_exists("SteamMultiplayerPeer"):
		steam_failed.emit("Steam MultiplayerPeer addon is missing.")
		return null
	var owner_id := int(steam.call("getLobbyOwner", lobby_id))
	if owner_id == 0:
		steam_failed.emit("Steam lobby owner was not found.")
		return null
	var peer := ClassDB.instantiate("SteamMultiplayerPeer") as MultiplayerPeer
	if not peer:
		steam_failed.emit("Could not create Steam MultiplayerPeer.")
		return null
	var error := int(peer.callv("create_client", [owner_id, STEAM_VIRTUAL_PORT]))
	if error != OK:
		steam_failed.emit("Steam client peer failed: %s" % error)
		return null
	return peer


func leave_lobby() -> void:
	if initialized and steam and current_lobby_id != 0:
		steam.call("leaveLobby", current_lobby_id)
	current_lobby_id = 0
	available_lobbies.clear()


func reset_session() -> void:
	leave_lobby()


func is_ready() -> bool:
	return initialized


func get_last_error() -> String:
	return last_error


func _connect_signal(signal_name: StringName, target: Callable) -> void:
	if steam and steam.has_signal(signal_name) and not steam.is_connected(signal_name, target):
		steam.connect(signal_name, target)


func _steam_init_succeeded(result) -> bool:
	if result is bool:
		return result
	if result is Dictionary:
		var status = result.get("status", false)
		if status is bool:
			return status
		if status is int:
			return int(status) == 0
	return false


func _steam_init_error(result) -> String:
	if result is Dictionary:
		var verbal := String(result.get("verbal", "")).strip_edges()
		var status := str(result.get("status", "unknown"))
		if not verbal.is_empty():
			return "Steam failed: %s (%s)" % [verbal, status]
		return "Steam failed with status: %s" % status
	return "Steam is not running or Steam API failed to initialize."


func _on_lobby_created(connect_result: int, lobby_id: int) -> void:
	if connect_result != 1:
		steam_failed.emit("Steam lobby create failed: %s" % connect_result)
		return
	current_lobby_id = lobby_id
	steam.call("setLobbyData", current_lobby_id, "name", pending_lobby_name)
	steam.call("setLobbyData", current_lobby_id, "game", "silent_city")
	steam.call("setLobbyData", current_lobby_id, "state", "waiting")
	steam.call("setLobbyData", current_lobby_id, "host_character", "")
	steam.call("setLobbyData", current_lobby_id, "client_character", "")
	lobby_created.emit(current_lobby_id)


func _on_lobby_joined(lobby_id: int, _permissions: int = 0, _locked: bool = false, response: int = 1) -> void:
	if response != 1:
		steam_failed.emit("Steam lobby join failed: %s" % response)
		return
	current_lobby_id = lobby_id
	lobby_joined.emit(current_lobby_id)


func _on_lobby_match_list(lobbies) -> void:
	available_lobbies.clear()
	if lobbies is Array:
		for lobby_id in lobbies:
			_add_lobby(int(lobby_id))
	elif lobbies is int:
		for index in lobbies:
			var lobby_id := int(steam.call("getLobbyByIndex", index))
			_add_lobby(lobby_id)
	lobby_list_updated.emit(available_lobbies)


func _add_lobby(lobby_id: int) -> void:
	if lobby_id == 0:
		return
	var lobby_name := "Silent City"
	var lobby_state := "waiting"
	var host_character := ""
	var client_character := ""
	if steam:
		var name = steam.call("getLobbyData", lobby_id, "name")
		if String(name).strip_edges() != "":
			lobby_name = String(name)
		lobby_state = String(steam.call("getLobbyData", lobby_id, "state"))
		host_character = String(steam.call("getLobbyData", lobby_id, "host_character"))
		client_character = String(steam.call("getLobbyData", lobby_id, "client_character"))
	if lobby_state.strip_edges().is_empty():
		lobby_state = "waiting"
	if lobby_state == "closed":
		return
	available_lobbies.append({
		"id": lobby_id,
		"name": lobby_name,
		"state": lobby_state,
		"host_character": host_character,
		"client_character": client_character,
	})


func _on_lobby_chat_update(_lobby_id: int, _changed_id: int, _making_change_id: int, _chat_state: int) -> void:
	request_lobbies()


func _on_join_requested(lobby_id: int, _friend_id: int = 0) -> void:
	join_lobby(lobby_id)
