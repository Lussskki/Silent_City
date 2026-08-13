extends Area2D

@export var power_value := 10
@export var launch_velocity := Vector2.ZERO
@export var coin_gravity := 900.0
@export var ground_y := 0.0
@export var pickup_delay := 0.18
@export var frame_size := Vector2i(32, 32)
@export var frame_count := 14
@export var frames_per_second := 14.0
@export var visual_scale := 2.0

@onready var sprite: Sprite2D = $Visual/CoinSprite
@onready var effect: Sprite2D = $Visual/PickupEffect
@onready var visual: Node2D = $Visual

const COIN_ROTATE_SHEET := preload("res://Sprites/Coins/gold/golden.rotate.png")

var bob_time := 0.0
var collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sprite.texture = COIN_ROTATE_SHEET
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, frame_size)
	visual.scale = Vector2.ONE * visual_scale
	effect.visible = false


func _process(delta: float) -> void:
	if collected:
		return

	pickup_delay = max(pickup_delay - delta, 0.0)
	if not launch_velocity.is_zero_approx():
		launch_velocity.y += coin_gravity * delta
		global_position += launch_velocity * delta
		if global_position.y >= ground_y:
			global_position.y = ground_y
			launch_velocity = Vector2.ZERO

	bob_time += delta
	visual.position.y = sin(bob_time * 5.5) * 3.0
	var frame := int(bob_time * frames_per_second) % frame_count
	sprite.region_rect = Rect2(Vector2(frame * frame_size.x, 0), frame_size)
	_try_collect_overlapping_player()


func _on_body_entered(body: Node2D) -> void:
	_try_collect_body(body)


func _try_collect_overlapping_player() -> void:
	if pickup_delay > 0.0:
		return
	for body in get_overlapping_bodies():
		if _try_collect_body(body):
			return


func _try_collect_body(body: Node2D) -> bool:
	if collected or pickup_delay > 0.0:
		return false
	if not body.is_in_group("Player"):
		return false
	if body.get("local_player") == false:
		return false
	if not body.has_method("collect_coin_power"):
		return false

	collected = true
	body.call("collect_coin_power", power_value)
	_play_pickup_effect()
	return true


func _play_pickup_effect() -> void:
	sprite.visible = false
	effect.visible = true
	effect.modulate.a = 1.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect, "scale", Vector2(2.2, 2.2), 0.18)
	tween.tween_property(effect, "modulate:a", 0.0, 0.18)
	tween.tween_property(visual, "position:y", -20.0, 0.18)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
