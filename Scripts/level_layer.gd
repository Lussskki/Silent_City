extends Node2D

@export var collisions_enabled := true:
	set(value):
		collisions_enabled = value
		if is_inside_tree():
			_sync_collision_state()


func _ready() -> void:
	_sync_collision_state()


func _sync_collision_state() -> void:
	for node in find_children("*", "CollisionShape2D", true, false):
		var collision := node as CollisionShape2D
		if collision:
			collision.disabled = not collisions_enabled
