extends Node2D

var _collisions_enabled := true

@export var collisions_enabled := true:
	set(value):
		_collisions_enabled = value
		if is_inside_tree():
			_sync_collision_state()
	get:
		return _collisions_enabled


func _ready() -> void:
	_sync_collision_state()


func _sync_collision_state() -> void:
	for node in find_children("*", "CollisionShape2D", true, false):
		var collision := node as CollisionShape2D
		if collision:
			collision.disabled = not _collisions_enabled
