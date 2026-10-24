@tool
class_name WindowLight
extends Node2D

@export var light_enabled: bool = true:
	set(value):
		light_enabled = value
		_apply_state()

@export_node_path("Sprite2D") var window_sprite_path: NodePath = ^"WindowSprite"
@export_node_path("PointLight2D") var point_light_path: NodePath


func _ready() -> void:
	_apply_state()


func turn_on() -> void:
	light_enabled = true


func turn_off() -> void:
	light_enabled = false


func toggle() -> void:
	light_enabled = not light_enabled


func _apply_state() -> void:
	var window_sprite := get_node_or_null(window_sprite_path) as Sprite2D
	if window_sprite != null:
		window_sprite.visible = light_enabled

	if not point_light_path.is_empty():
		var point_light := get_node_or_null(point_light_path) as PointLight2D
		if point_light != null:
			point_light.enabled = light_enabled
			point_light.visible = light_enabled
