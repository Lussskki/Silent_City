extends Area2D

@export var damage := 100


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if body.get("local_player") == false:
		return

	if body.has_method("respawn"):
		body.respawn()
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
