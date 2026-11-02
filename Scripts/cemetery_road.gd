extends Node2D


func _ready() -> void:
	$Player.global_position = $LiftArrival.global_position
	var tree := get_tree()
	if not tree.has_meta(&"cemetery_road_player_state"):
		return
	var state: Dictionary = tree.get_meta(&"cemetery_road_player_state")
	tree.remove_meta(&"cemetery_road_player_state")
	var player := $Player
	player.life = int(state.life)
	player.coin_power = int(state.coin_power)
	player.defence_power_timer = float(state.defence_power_timer)
	player.life_changed.emit(player.life, player.max_life)
	player.power_changed.emit(player.coin_power, player.max_coin_power)
	if state.get("arrival_descent", false):
		$ArrivalLift.start_arrival_descent(player)
		$Player/Camera2D.reset_smoothing()
