extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var player_trigger: Area2D = $PlayerTrigger

var is_lowered := false


func _ready() -> void:
	player_trigger.body_entered.connect(_on_player_trigger_body_entered)
	player_trigger.body_exited.connect(_on_player_trigger_body_exited)
	call_deferred(&"_sync_bridge_state")


func _physics_process(_delta: float) -> void:
	_sync_bridge_state()


func _on_player_trigger_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_set_lowered(true)


func _on_player_trigger_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_sync_bridge_state()


func _sync_bridge_state() -> void:
	for body in player_trigger.get_overlapping_bodies():
		if body.is_in_group("Player"):
			_set_lowered(true)
			return
	_set_lowered(false)


func _set_lowered(lowered: bool) -> void:
	if lowered == is_lowered:
		return
	is_lowered = lowered
	if is_lowered:
		animation_player.play(&"sag")
	else:
		animation_player.play_backwards(&"sag")
