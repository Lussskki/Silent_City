extends Area2D

@export var defence_duration := 7.0
@export var fall_speed := 300.0
@export var target_y := 0.0
@export var drop_id := 0

@onready var visual: Node2D = $Visual

var landed := false
var bob_time := 0.0
var consumed := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not landed:
		global_position.y = min(global_position.y + fall_speed * delta, target_y)
		if is_equal_approx(global_position.y, target_y):
			landed = true
		return

	bob_time += delta
	visual.position.y = sin(bob_time * 4.0) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if consumed:
		return
	if not body.is_in_group("Player"):
		return
	if body.get("local_player") == false:
		return

	var spawner := get_tree().current_scene.get_node_or_null("DefenceDropSpawner")
	if multiplayer.has_multiplayer_peer() and spawner and spawner.has_method("request_defence_pickup"):
		spawner.request_defence_pickup(drop_id, body)
		return

	if not body.has_method("activate_defence"):
		return

	body.activate_defence(defence_duration)
	consumed = true
	queue_free()
