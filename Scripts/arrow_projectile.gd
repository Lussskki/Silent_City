extends Node2D

const RANGER_ARROW_TEXTURE := preload("res://Sprites/Weapons/forest_ranger_arrow.png")
const WRAITH_ARROW_TEXTURE := preload("res://Characters/Wraithes/PNG/Wraith_01/PNG Sequences/arrow.png")
const RANGER_ARROW_SCALE := Vector2(0.30, 0.30)
const WRAITH_ARROW_SCALE := Vector2(0.30, 0.30)

@export var speed := 900.0
@export var damage := 40
@export var max_distance := 1100.0
@export var hit_radius := 32.0
@export var launch_delay := 0.25
@export var animation_fps := 18.0

var direction := Vector2.RIGHT
var travelled := 0.0
var shooter: Node
var launch_timer := 0.0
var launched := false
var visual_only := false
var animation_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func configure_visual_only() -> void:
	# Remote clients display the shot but must not run a second damage check.
	visual_only = true

func setup(origin: Vector2, shot_direction: float, source: Node, character_override: String = "") -> void:
	global_position = origin
	direction = Vector2.RIGHT if shot_direction >= 0.0 else Vector2.LEFT
	rotation = 0.0 if direction.x > 0.0 else PI
	shooter = source
	_configure_character_visual(source, character_override)
	launch_timer = launch_delay
	launched = launch_delay <= 0.0
	visible = launched

func _configure_character_visual(source: Node, character_override: String) -> void:
	var character_key := character_override
	if character_key.is_empty() and source:
		character_key = str(source.get("selected_character_key"))
	if character_key == "wraith":
		sprite.texture = WRAITH_ARROW_TEXTURE
		sprite.hframes = 6
		sprite.scale = WRAITH_ARROW_SCALE
	else:
		# Nina keeps her original physical arrow. Only Wraith uses ice.
		sprite.texture = RANGER_ARROW_TEXTURE
		sprite.hframes = 1
		sprite.frame = 0
		sprite.scale = RANGER_ARROW_SCALE

func _physics_process(delta: float) -> void:
	if not launched:
		launch_timer -= delta
		if launch_timer > 0.0:
			return
		launched = true
		visible = true

	animation_time += delta
	if sprite and sprite.hframes > 1:
		sprite.frame = int(animation_time * animation_fps) % sprite.hframes

	var previous_position := global_position
	var movement := direction * speed * delta
	global_position += movement
	travelled += movement.length()
	if travelled >= max_distance:
		queue_free()
		return

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(enemy) or enemy == shooter or enemy.get("dead") == true:
			continue
		var target_position: Vector2 = enemy.global_position
		if enemy.has_method("get_hit_position"):
			target_position = enemy.get_hit_position()
		if _segment_distance_to_point(previous_position, global_position, target_position) <= hit_radius:
			if not visual_only:
				_damage_enemy(enemy)
			queue_free()
			return

	for player in get_tree().get_nodes_in_group("Player"):
		if not is_instance_valid(player) or player == shooter or player.get("dead") == true:
			continue
		var target_position: Vector2 = player.global_position
		if player.has_method("get_hit_position"):
			target_position = player.get_hit_position()
		if _segment_distance_to_point(previous_position, global_position, target_position) <= hit_radius:
			if not visual_only:
				_damage_target(player)
			queue_free()
			return

func _segment_distance_to_point(segment_start: Vector2, segment_end: Vector2, point: Vector2) -> float:
	var segment := segment_end - segment_start
	var segment_length_squared := segment.length_squared()
	if is_zero_approx(segment_length_squared):
		return point.distance_to(segment_start)
	var projection := clampf((point - segment_start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_to(segment_start + segment * projection)

func _damage_enemy(enemy: Node) -> void:
	if not _damage_target(enemy):
		return
	# Keep the visible bar synchronized immediately after the enemy's damage API
	# changes its life value, including when the hit happens during an animation.
	var health_bar := enemy.get_node_or_null("HealthBar") as ProgressBar
	if health_bar and enemy.get("life") != null:
		health_bar.value = float(enemy.get("life"))

func _damage_target(target: Node) -> bool:
	if shooter and shooter.has_method("apply_projectile_damage"):
		return bool(shooter.call("apply_projectile_damage", target, damage))
	if shooter and shooter.has_method("_try_damage_target"):
		return bool(shooter.call("_try_damage_target", target, damage))
	if target.has_method("take_damage"):
		target.take_damage(damage)
		return true
	return false
