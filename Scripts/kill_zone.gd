extends Area2D

@onready var timer: Timer = $Timer


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if timer and not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if body.get("local_player") == false:
		return

	if body.has_method("respawn"):
		body.respawn()
		return
	if body.has_method("take_damage"):
		body.take_damage(9999)
		return
	if timer:
		timer.start()

func _on_timer_timeout() -> void:
	if multiplayer.has_multiplayer_peer():
		return
	get_tree().reload_current_scene()
