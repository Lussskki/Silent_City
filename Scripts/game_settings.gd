extends Node

const MAIN_SCENE := "res://Scenes/main.tscn"
const ONLINE_PORT := 8910
const ONLINE_MAX_ROUNDS := 5
const SAVE_PATH := "user://silent_city_save.json"
const ICE_GOLEM_UNLOCK_COINS := 2500
const OFFLINE_LEVEL_TRIES := {
	"easy": 5,
	"medium": 3,
	"hard": 2
}

signal online_rounds_changed(rounds_played: int, max_rounds: int)
signal online_match_finished(winner_name: String)
signal saved_coins_changed(saved_coins: int)

var selected_character := "player"
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
var saved_coins := 0


func _ready() -> void:
	load_save()


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
	saved_coins_changed.emit(saved_coins)


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	var data := {
		"saved_coins": saved_coins
	}
	file.store_string(JSON.stringify(data))


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


func start_offline_level(level: String) -> void:
	offline_tries_level = level
	offline_tries_max = int(OFFLINE_LEVEL_TRIES.get(level, 5))
	offline_tries_left = offline_tries_max
	pending_health_drop = false
	pending_health_drop_id = 0
	pending_health_drop_position = Vector2.INF


func consume_offline_try() -> int:
	offline_tries_left = max(offline_tries_left - 1, 0)
	return offline_tries_left


func offline_tries_text() -> String:
	return "Lives: %d/%d" % [offline_tries_max - offline_tries_left, offline_tries_max]


func set_pending_health_drop(drop_id: int, drop_position: Vector2) -> void:
	pending_health_drop = true
	pending_health_drop_id = drop_id
	pending_health_drop_position = drop_position


func clear_pending_health_drop(drop_id: int) -> void:
	if pending_health_drop_id == drop_id:
		pending_health_drop = false
		pending_health_drop_id = 0
		pending_health_drop_position = Vector2.INF


func reset_online_rounds() -> void:
	online_rounds_played = 0
	online_match_winner = ""
	online_rounds_changed.emit(online_rounds_played, ONLINE_MAX_ROUNDS)


func record_online_round(winner_name: String = "") -> void:
	if online_rounds_played >= ONLINE_MAX_ROUNDS:
		return
	online_rounds_played += 1
	online_rounds_changed.emit(online_rounds_played, ONLINE_MAX_ROUNDS)
	if online_rounds_played >= ONLINE_MAX_ROUNDS:
		online_match_winner = winner_name
		online_match_finished.emit(online_match_winner)


func is_online_match_over() -> bool:
	return online_rounds_played >= ONLINE_MAX_ROUNDS
