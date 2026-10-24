class_name ProximityLantern
extends Sprite2D

@export_node_path("CanvasItem") var glow_path: NodePath
@export var activation_distance: float = 135.0
@export var rearm_distance: float = 210.0
@export var off_tint := Color(0.32, 0.38, 0.48, 1.0)

var _player: Node2D
var _flickering := false
var _armed := true
var _on_tint := Color.WHITE


func _ready() -> void:
	_on_tint = self_modulate


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("Player") as Node2D
		if _player == null:
			return

	var distance := global_position.distance_to(_player.global_position)
	if _armed and distance <= activation_distance:
		_armed = false
		play_flicker()
	elif not _armed and distance >= rearm_distance:
		_armed = true


func play_flicker() -> void:
	if _flickering:
		return
	_flickering = true

	_set_light(false)
	await get_tree().create_timer(0.10).timeout
	_set_light(true)
	await get_tree().create_timer(0.14).timeout
	_set_light(false)
	await get_tree().create_timer(0.08).timeout
	_set_light(true)
	await get_tree().create_timer(0.18).timeout
	_set_light(false)
	await get_tree().create_timer(0.06).timeout
	_set_light(true)

	_flickering = false


func turn_on() -> void:
	_set_light(true)


func turn_off() -> void:
	_set_light(false)


func _set_light(light_on: bool) -> void:
	self_modulate = _on_tint if light_on else off_tint
	if not glow_path.is_empty():
		var glow := get_node_or_null(glow_path) as CanvasItem
		if glow != null:
			glow.visible = light_on
