extends Node

const MAIN_SCENE := "res://Scenes/Online.tscn"
const ONLINE_PORT := 8910
const ONLINE_MAX_ROUNDS := 5
const SAVE_PATH := "user://silent_city_save.json"
const SAVE_DIRECTORY := "user://saves"
const STORY_SCENE := "res://Scenes/OuterGraveyardMoonlit.tscn"
const AUDIO_CONFIG_PATH := "user://audio_settings.cfg"
const SAVE_VERSION := 3
const MANUAL_SLOT_COUNT := 3
const ICE_GOLEM_UNLOCK_COINS := 2500

const OFFLINE_LEVEL_TRIES := {
	"easy": 5,
	"medium": 3,
	"hard": 2
}

signal online_rounds_changed(rounds_played: int, max_rounds: int)
signal online_match_finished(winner_name: String)
signal saved_coins_changed(saved_coins: int)
signal save_slots_changed
signal cloud_sync_status_changed(status: String)

var selected_character := "player"
var game_mode := "story"
var character_chosen := false
var selected_level := "easy"
var level_chosen := false
var online_mode := false
var online_role := ""
var online_remote_character := "golem"
var online_scene_path := MAIN_SCENE
var online_tutorial_seen := false
var language := "eng"
var player_sprite_frames: SpriteFrames

var online_rounds_played: int = 0
var online_max_rounds: int = ONLINE_MAX_ROUNDS
var online_match_winner := ""

var offline_tries_left := 5
var offline_tries_max := 5
var offline_tries_level := "easy"

var pending_health_drop := false
var pending_health_drop_id := 0
var pending_health_drop_position := Vector2.INF
var pending_defence_drop := false
var pending_defence_drop_id := 0
var pending_defence_drop_position := Vector2.INF

var saved_coins := 0
var cloud_sync_status := "Local saves ready"
var pending_load_data: Dictionary = {}


func _ready() -> void:
	_ensure_save_directory()
	load_save()
	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred(&"_setup_cloud_sync")


func reset_online() -> void:
	online_mode = false
	online_role = ""
	online_remote_character = "golem"
	online_scene_path = MAIN_SCENE
	character_chosen = false
	reset_online_rounds()


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if not file:
		return

	var data = JSON.parse_string(file.get_as_text())

	if data is Dictionary:
		saved_coins = max(int(data.get("saved_coins", 0)), 0)
		language = String(data.get("language", language))
		selected_character = String(data.get("selected_character", selected_character))
		_apply_audio_percent(int(data.get("master_volume_percent", _master_volume_percent())))

	saved_coins_changed.emit(saved_coins)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if not file:
		return

	var data := {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"saved_coins": saved_coins,
		"language": language,
		"selected_character": selected_character,
		"master_volume_percent": _master_volume_percent()
	}

	file.store_string(JSON.stringify(data, "\t"))
	if _upload_json_to_cloud("silent_city_profile.json", data):
		_set_cloud_status("Saved locally • Steam Cloud synced")
	else:
		_set_cloud_status("Saved locally")


func notify_preferences_changed() -> void:
	save_game()


func add_saved_coins(amount: int) -> int:
	if amount <= 0:
		return saved_coins

	saved_coins += amount
	save_game()
	saved_coins_changed.emit(saved_coins)

	return saved_coins


func get_saved_coins() -> int:
	return saved_coins


func get_character_unlock_cost(character: String) -> int:
	if character == "ice_golem":
		return ICE_GOLEM_UNLOCK_COINS

	return 0


func is_character_unlocked(character: String) -> bool:
	return saved_coins >= get_character_unlock_cost(character)


func save_current_game(slot: int) -> bool:
	if online_mode or slot < 1 or slot > MANUAL_SLOT_COUNT:
		return false
	var data := _capture_current_game()
	if data.is_empty():
		return false
	return _save_slot_data(slot, data)


func get_save_slot_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for slot in range(1, MANUAL_SLOT_COUNT + 1):
		var data := _read_slot_data(slot)
		summaries.append({
			"slot": slot,
			"empty": data.is_empty(),
			"saved_at_text": String(data.get("saved_at_text", "")),
			"scene_title": String(data.get("scene_title", "Story")),
			"character": String(data.get("selected_character", "player")),
			"coins": int(data.get("saved_coins", 0))
		})
	return summaries


func request_load_slot(slot: int) -> String:
	if slot < 1 or slot > MANUAL_SLOT_COUNT:
		return ""
	var data := _read_slot_data(slot)
	if data.is_empty():
		return ""
	pending_load_data = data.duplicate(true)
	saved_coins = max(int(data.get("saved_coins", saved_coins)), 0)
	selected_character = String(data.get("selected_character", "player"))
	selected_level = String(data.get("selected_level", "easy"))
	offline_tries_level = selected_level
	offline_tries_max = int(data.get("offline_tries_max", OFFLINE_LEVEL_TRIES.get(selected_level, 5)))
	offline_tries_left = int(data.get("offline_tries_left", offline_tries_max))
	game_mode = "story"
	character_chosen = true
	level_chosen = true
	save_game()
	saved_coins_changed.emit(saved_coins)
	var scene_path := String(data.get("scene_path", STORY_SCENE))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		scene_path = STORY_SCENE
	return scene_path


func has_any_save() -> bool:
	return latest_save_slot() >= 0


func latest_save_slot() -> int:
	var newest_slot := -1
	var newest_time := -1
	for slot in range(1, MANUAL_SLOT_COUNT + 1):
		var data := _read_slot_data(slot)
		var saved_time := int(data.get("saved_at_unix", -1))
		if saved_time > newest_time:
			newest_time = saved_time
			newest_slot = slot
	return newest_slot


func get_cloud_sync_status() -> String:
	return cloud_sync_status


func is_load_pending() -> bool:
	return not pending_load_data.is_empty()


func _capture_current_game() -> Dictionary:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.is_empty() or scene.scene_file_path.ends_with("MainMenu.tscn"):
		return {}
	var player := scene.get_node_or_null("Player") as Node2D
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return {}
	return {
		"version": SAVE_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"saved_at_text": Time.get_datetime_string_from_system(false, true),
		"scene_path": scene.scene_file_path,
		"scene_title": _friendly_scene_title(scene.scene_file_path),
		"player_position": {"x": player.global_position.x, "y": player.global_position.y},
		"selected_character": selected_character,
		"selected_level": selected_level,
		"saved_coins": saved_coins,
		"offline_tries_left": offline_tries_left,
		"offline_tries_max": offline_tries_max,
		"life": int(player.get("life")) if player.get("life") != null else -1,
		"coin_power": int(player.get("coin_power")) if player.get("coin_power") != null else 0,
		"world_state": _capture_world_state(scene)
	}


func _capture_world_state(scene: Node) -> Array[Dictionary]:
	var saved_nodes: Array[Dictionary] = []
	var candidates: Array[Node] = [scene]
	candidates.append_array(scene.find_children("*", "Node", true, false))
	for node: Node in candidates:
		var state = null
		if node.has_method("get_save_state"):
			state = node.call("get_save_state")
		elif _is_grave_encounter(node):
			state = _capture_grave_encounter(node)
		if not state is Dictionary:
			continue
		saved_nodes.append({
			"path": String(scene.get_path_to(node)),
			"state": state
		})
	return saved_nodes


func _is_grave_encounter(node: Node) -> bool:
	var script := node.get_script() as Script
	return script != null and script.resource_path.ends_with("/grave_encounter.gd")


func _capture_grave_encounter(encounter: Node) -> Dictionary:
	var enemies = encounter.get("enemies")
	var next_index := int(encounter.get("next_enemy_index"))
	var enemy_states: Array[Dictionary] = []
	if enemies is Array:
		for index in range(enemies.size()):
			var enemy = enemies[index]
			if not is_instance_valid(enemy):
				enemy_states.append({"defeated": true})
				continue
			var enemy_position := (enemy as Node2D).position if enemy is Node2D else Vector2.ZERO
			enemy_states.append({
				"defeated": bool(enemy.get("dead")) or int(enemy.get("life")) <= 0,
				"awakened": index < next_index,
				"life": int(enemy.get("life")),
				"position": {"x": enemy_position.x, "y": enemy_position.y}
			})
	return {
		"kind": "grave_encounter",
		"triggered": bool(encounter.get("triggered")),
		"cleared": bool(encounter.get("cleared")),
		"next_enemy_index": next_index,
		"enemy_states": enemy_states
	}


func _save_slot_data(slot: int, data: Dictionary) -> bool:
	if not _write_json_file(_slot_path(slot), data):
		return false
	if _upload_json_to_cloud(_cloud_slot_name(slot), data):
		_set_cloud_status("Saved locally • Steam Cloud synced")
	else:
		_set_cloud_status("Saved locally")
	save_slots_changed.emit()
	return true


func _read_slot_data(slot: int) -> Dictionary:
	var local_data := _read_json_file(_slot_path(slot))
	if not local_data.is_empty():
		return local_data
	var remote_data := _download_json_from_cloud(_cloud_slot_name(slot))
	if not remote_data.is_empty():
		_write_json_file(_slot_path(slot), remote_data)
	return remote_data


func _slot_path(slot: int) -> String:
	return SAVE_DIRECTORY.path_join("slot_%d.json" % slot)


func _cloud_slot_name(slot: int) -> String:
	return "silent_city_slot_%d.json" % slot


func _setup_cloud_sync() -> void:
	var steam_manager := get_node_or_null("/root/SteamManager")
	if steam_manager == null:
		_set_cloud_status("Local saves ready")
		return
	var callback := Callable(self, "_sync_cloud_saves")
	if steam_manager.has_signal("steam_ready") and not steam_manager.is_connected("steam_ready", callback):
		steam_manager.connect("steam_ready", callback)
	if steam_manager.has_method("is_ready") and steam_manager.is_ready():
		_sync_cloud_saves()
	else:
		_set_cloud_status("Local saves ready • Steam Cloud waiting")


func _sync_cloud_saves() -> void:
	if not _steam_cloud_available():
		_set_cloud_status("Local saves ready • Steam Cloud unavailable")
		return
	_set_cloud_status("Syncing Steam Cloud…")
	for slot in range(1, MANUAL_SLOT_COUNT + 1):
		_sync_one_json(_slot_path(slot), _cloud_slot_name(slot))
	_sync_one_json(SAVE_PATH, "silent_city_profile.json")
	load_save()
	save_slots_changed.emit()
	_set_cloud_status("Saved locally • Steam Cloud synced")


func _sync_one_json(local_path: String, cloud_name: String) -> void:
	var local_data := _read_json_file(local_path)
	var remote_data := _download_json_from_cloud(cloud_name)
	if local_data.is_empty() and remote_data.is_empty():
		return
	if local_data.is_empty() or int(remote_data.get("saved_at_unix", -1)) > int(local_data.get("saved_at_unix", -1)):
		_write_json_file(local_path, remote_data)
	else:
		_upload_json_to_cloud(cloud_name, local_data)


func _upload_json_to_cloud(cloud_name: String, data: Dictionary) -> bool:
	if not _steam_cloud_available():
		return false
	var steam := Engine.get_singleton("Steam")
	if not steam.has_method("fileWrite"):
		return false
	var bytes := JSON.stringify(data).to_utf8_buffer()
	return bool(steam.call("fileWrite", cloud_name, bytes, bytes.size()))


func _download_json_from_cloud(cloud_name: String) -> Dictionary:
	if not _steam_cloud_available():
		return {}
	var steam := Engine.get_singleton("Steam")
	if not steam.has_method("fileExists") or not bool(steam.call("fileExists", cloud_name)):
		return {}
	if not steam.has_method("getFileSize") or not steam.has_method("fileRead"):
		return {}
	var file_size := int(steam.call("getFileSize", cloud_name))
	if file_size <= 0:
		return {}
	var bytes = steam.call("fileRead", cloud_name, file_size)
	if not bytes is PackedByteArray:
		return {}
	var text: String = bytes.get_string_from_utf8()
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


func _steam_cloud_available() -> bool:
	var steam_manager := get_node_or_null("/root/SteamManager")
	if steam_manager == null or not steam_manager.has_method("is_ready") or not steam_manager.is_ready():
		return false
	if not Engine.has_singleton("Steam"):
		return false
	var steam := Engine.get_singleton("Steam")
	if not steam.has_method("isCloudEnabledForAccount") or not steam.has_method("isCloudEnabledForApp"):
		return false
	return bool(steam.call("isCloudEnabledForAccount")) and bool(steam.call("isCloudEnabledForApp"))


func _set_cloud_status(status: String) -> void:
	cloud_sync_status = status
	cloud_sync_status_changed.emit(status)


func _ensure_save_directory() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIRECTORY))


func _read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _write_json_file(path: String, data: Dictionary) -> bool:
	_ensure_save_directory()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


func _master_volume_percent() -> int:
	var config := ConfigFile.new()
	if config.load(AUDIO_CONFIG_PATH) != OK:
		return 100
	return clampi(int(config.get_value("audio", "master_volume_percent", 100)), 0, 100)


func _apply_audio_percent(percent: int) -> void:
	var config := ConfigFile.new()
	config.load(AUDIO_CONFIG_PATH)
	config.set_value("audio", "master_volume_percent", clampi(percent, 0, 100))
	config.save(AUDIO_CONFIG_PATH)


func _friendly_scene_title(scene_path: String) -> String:
	return "Outer Graveyard" if scene_path == STORY_SCENE else scene_path.get_file().get_basename().capitalize()


func _on_scene_changed() -> void:
	var scene := get_tree().current_scene
	if pending_load_data.is_empty() or scene == null:
		return
	call_deferred(&"_apply_pending_load", scene)


func _apply_pending_load(scene: Node) -> void:
	await get_tree().process_frame
	_apply_world_state(scene, pending_load_data.get("world_state", []))
	var player := scene.get_node_or_null("Player") as Node2D
	if player == null:
		player = get_tree().get_first_node_in_group("Player") as Node2D
	if player == null:
		return
	var position_data = pending_load_data.get("player_position", {})
	if position_data is Dictionary:
		player.global_position = Vector2(float(position_data.get("x", player.global_position.x)), float(position_data.get("y", player.global_position.y)))
	var saved_life := int(pending_load_data.get("life", -1))
	if saved_life >= 0 and player.get("life") != null:
		player.set("life", saved_life)
		if player.has_signal("life_changed"):
			player.emit_signal("life_changed", saved_life, int(player.get("max_life")))
	if player.get("coin_power") != null:
		var saved_power := int(pending_load_data.get("coin_power", 0))
		player.set("coin_power", saved_power)
		if player.has_signal("power_changed"):
			player.emit_signal("power_changed", saved_power, int(player.get("max_coin_power")))
	pending_load_data.clear()


func _apply_world_state(scene: Node, saved_nodes) -> void:
	if not saved_nodes is Array:
		return
	for entry in saved_nodes:
		if not entry is Dictionary:
			continue
		var node_path := NodePath(String(entry.get("path", "")))
		if node_path.is_empty():
			continue
		var node := scene.get_node_or_null(node_path)
		if node:
			var state = entry.get("state", {})
			if state is Dictionary and node.has_method("apply_save_state"):
				node.call("apply_save_state", state)
			elif state is Dictionary and String(state.get("kind", "")) == "grave_encounter" and _is_grave_encounter(node):
				_apply_grave_encounter(node, state)


func _apply_grave_encounter(encounter: Node, saved_state: Dictionary) -> void:
	var enemies = encounter.get("enemies")
	if not enemies is Array:
		return
	var cleared := bool(saved_state.get("cleared", false))
	var triggered := bool(saved_state.get("triggered", false))
	var next_index := clampi(int(saved_state.get("next_enemy_index", 0)), 0, enemies.size())
	encounter.set("triggered", triggered)
	encounter.set("cleared", cleared)
	encounter.set("next_enemy_index", next_index)
	encounter.set("active_enemy_count", 0)
	encounter.set("spawn_delay", 0.1)
	var active_count := 0
	var enemy_states = saved_state.get("enemy_states", [])
	for index in range(enemies.size()):
		var enemy = enemies[index]
		if not is_instance_valid(enemy):
			continue
		var enemy_state: Dictionary = (
			enemy_states[index]
			if enemy_states is Array and index < enemy_states.size() and enemy_states[index] is Dictionary
			else {}
		)
		if cleared or bool(enemy_state.get("defeated", false)):
			enemy.queue_free()
			continue
		if not bool(enemy_state.get("awakened", index < next_index)):
			continue
		if enemy.has_method("begin_emergence"):
			enemy.call("begin_emergence")
		enemy.set("life", int(enemy_state.get("life", enemy.get("max_life"))))
		if enemy is Node2D:
			var position_data = enemy_state.get("position", {})
			if position_data is Dictionary:
				(enemy as Node2D).position = Vector2(
					float(position_data.get("x", (enemy as Node2D).position.x)),
					float(position_data.get("y", (enemy as Node2D).position.y))
				)
		if enemy.has_method("_update_health_bar"):
			enemy.call("_update_health_bar")
		active_count += 1
	encounter.set("active_enemy_count", active_count)
	encounter.set_process(triggered and not cleared)


func start_offline_level(level: String) -> void:
	offline_tries_level = level
	offline_tries_max = int(OFFLINE_LEVEL_TRIES.get(level, 5))
	offline_tries_left = offline_tries_max

	pending_health_drop = false
	pending_health_drop_id = 0
	pending_health_drop_position = Vector2.INF
	pending_defence_drop = false
	pending_defence_drop_id = 0
	pending_defence_drop_position = Vector2.INF


func consume_offline_try() -> int:
	offline_tries_left = max(offline_tries_left - 1, 0)

	return offline_tries_left


func offline_tries_text() -> String:
	return "Lives: %d/%d" % [
		offline_tries_max - offline_tries_left,
		offline_tries_max
	]


func set_pending_health_drop(
	drop_id: int,
	drop_position: Vector2
) -> void:
	pending_health_drop = true
	pending_health_drop_id = drop_id
	pending_health_drop_position = drop_position


func clear_pending_health_drop(drop_id: int) -> void:
	if pending_health_drop_id == drop_id:
		pending_health_drop = false
		pending_health_drop_id = 0
		pending_health_drop_position = Vector2.INF


func set_pending_defence_drop(drop_id: int, drop_position: Vector2) -> void:
	pending_defence_drop = true
	pending_defence_drop_id = drop_id
	pending_defence_drop_position = drop_position


func clear_pending_defence_drop(drop_id: int) -> void:
	if pending_defence_drop_id == drop_id:
		pending_defence_drop = false
		pending_defence_drop_id = 0
		pending_defence_drop_position = Vector2.INF


func reset_online_rounds() -> void:
	online_rounds_played = 0
	online_match_winner = ""

	online_rounds_changed.emit(
		online_rounds_played,
		ONLINE_MAX_ROUNDS
	)


func record_online_round(winner_name: String = "") -> void:
	if online_rounds_played >= ONLINE_MAX_ROUNDS:
		return

	online_rounds_played += 1

	online_rounds_changed.emit(
		online_rounds_played,
		ONLINE_MAX_ROUNDS
	)

	if online_rounds_played >= ONLINE_MAX_ROUNDS:
		online_match_winner = winner_name
		online_match_finished.emit(online_match_winner)


func is_online_match_over() -> bool:
	return online_rounds_played >= ONLINE_MAX_ROUNDS
