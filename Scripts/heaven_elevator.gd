extends Node2D

signal reached_heaven

@export var lift_texture: Texture2D
@export var bottom_platform_y := 901.0
@export var top_platform_y := 345.0
@export var travel_time := 3.4
@export var departure_delay := 0.45
@export var return_delay := 1.5

@onready var platform: AnimatableBody2D = $Platform
@onready var rider_sensor: Area2D = $Platform/RiderSensor

var _platform_y := 901.0
var _state := "bottom"
var _riders: Dictionary = {}
var _trip_id := 0
var _motion_tween: Tween


func _ready() -> void:
	_platform_y = bottom_platform_y
	platform.position.y = _platform_y
	rider_sensor.body_entered.connect(_on_rider_entered)
	rider_sensor.body_exited.connect(_on_rider_exited)
	queue_redraw()


func _draw() -> void:
	if not lift_texture:
		return
	var tower_top := top_platform_y - 70.0
	var tower_height := bottom_platform_y - top_platform_y + 145.0
	draw_texture_rect_region(lift_texture, Rect2(-205, tower_top, 70, tower_height), Rect2(43, 7, 35, 241))
	draw_texture_rect_region(lift_texture, Rect2(135, tower_top, 70, tower_height), Rect2(180, 7, 35, 241))
	draw_texture_rect_region(lift_texture, Rect2(-180, _platform_y - 30, 360, 60), Rect2(62, 169, 134, 50))


func _on_rider_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	_riders[body.get_instance_id()] = true
	if _state == "bottom":
		_trip_id += 1
		_depart_after_delay(_trip_id)


func _on_rider_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
	_riders.erase(body.get_instance_id())
	if _state == "top" and _riders.is_empty():
		_trip_id += 1
		_return_after_delay(_trip_id)


func _is_player(body: Node) -> bool:
	return body.is_in_group("Player") or body.is_in_group("LocalPlayer")


func _depart_after_delay(trip_id: int) -> void:
	await get_tree().create_timer(departure_delay).timeout
	if trip_id != _trip_id or _state != "bottom" or _riders.is_empty():
		return
	_move_to(top_platform_y, "rising")


func _return_after_delay(trip_id: int) -> void:
	await get_tree().create_timer(return_delay).timeout
	if trip_id != _trip_id or _state != "top" or not _riders.is_empty():
		return
	_move_to(bottom_platform_y, "descending")


func _move_to(target_y: float, moving_state: String) -> void:
	_state = moving_state
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = create_tween()
	_motion_tween.set_trans(Tween.TRANS_SINE)
	_motion_tween.set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_method(_set_platform_y, _platform_y, target_y, travel_time)
	await _motion_tween.finished
	_set_platform_y(target_y)
	if moving_state == "rising":
		_state = "top"
		reached_heaven.emit()
		if _riders.is_empty():
			_trip_id += 1
			_return_after_delay(_trip_id)
	else:
		_state = "bottom"


func _set_platform_y(value: float) -> void:
	_platform_y = value
	platform.position.y = value
	queue_redraw()
