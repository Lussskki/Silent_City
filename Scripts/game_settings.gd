extends Node

const MAIN_SCENE := "res://Scenes/main.tscn"
const ONLINE_PORT := 8910
const ONLINE_MAX_ROUNDS := 5

signal online_rounds_changed(rounds_played: int, max_rounds: int)
signal online_match_finished(winner_name: String)

var selected_character := "player"
var character_chosen := false
var selected_level := "easy"
var level_chosen := false
var online_mode := false
var online_role := ""
var online_remote_character := "golem"
var online_tutorial_seen := false
var language := "eng"
var player_sprite_frames: SpriteFrames
var online_rounds_played: int = 0
var online_max_rounds: int = ONLINE_MAX_ROUNDS
var online_match_winner := ""


func reset_online() -> void:
	online_mode = false
	online_role = ""
	online_remote_character = "golem"
	reset_online_rounds()


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

