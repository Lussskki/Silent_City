extends CharacterBody2D

signal cinematic_started
signal cinematic_finished

@export var max_life: int = 350
@export var notice_radius: float = 900.0
@export var move_speed: float = 72.0
@export var run_speed: float = 135.0
@export var chase_distance: float = 900.0
@export var attack_distance: float = 118.0
@export var attack_damage: int = 24
@export var attack_cooldown: float = 1.15
@export var lunge_speed: float = 180.0
@export var lunge_time: float = 0.18
@export var attack_hit_delay: float = 0.22
@export var attack_knockback: Vector2 = Vector2(260.0, -140.0)
@export var ground_burst_distance_min: float = 170.0
@export var ground_burst_distance_max: float = 420.0
@export var ground_burst_cooldown: float = 2.8
@export var ground_burst_speed: float = 230.0
@export var ground_burst_time: float = 0.28
@export var ground_burst_damage: int = 32
@export var ground_burst_radius: float = 145.0
@export var ground_burst_knockback: Vector2 = Vector2(330.0, -160.0)
@export var platform_jump_min_vertical: float = 70.0
@export var platform_jump_gap_min_horizontal: float = 210.0
@export var platform_jump_max_horizontal: float = 820.0
@export var platform_jump_max_drop: float = 220.0
@export var platform_jump_cooldown: float = 1.25
@export var platform_jump_velocity: float = 500.0
@export var platform_jump_forward_speed: float = 270.0
@export var air_double_jump_velocity: float = 300.0
@export var air_double_jump_forward_speed: float = 240.0
@export var air_double_jump_near_ground_distance: float = 95.0
@export var edge_jump_probe_forward: float = 86.0
@export var edge_jump_probe_up: float = 18.0
@export var edge_jump_probe_down: float = 170.0
@export var edge_jump_min_target_horizontal: float = 80.0
@export var fall_recover_y: float = 950.0
@export var fall_recover_offset: Vector2 = Vector2(0.0, 0.0)
@export var random_respawn_positions: Array[Vector2] = [
	Vector2(650.0, 512.0),
	Vector2(2048.0, 288.0),
	Vector2(3264.0, 448.0),
]
@export var respawn_floor_snap_up: float = 420.0
@export var respawn_floor_snap_down: float = 900.0
@export var fall_recover_message: String = "You, I am immortal you can't hide me"
@export var fall_recover_message_time: float = 2.0
@export var cinematic_enabled: bool = true
@export var cinematic_trigger_distance: float = 560.0
@export var sprite_faces_left: bool = true
@export var boss_sprite_scale: Vector2 = Vector2(2.3, 2.3)
@export var jump_sprite_tilt_degrees: float = 7.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_bar: Control = $BossHealthLayer/HealthBar
@onready var health_bar_progress_clip: Control = $BossHealthLayer/HealthBar/ProgressClip
@onready var taunt_label: Label = $TauntLabel
@onready var cinematic_layer: CanvasLayer = $CinematicLayer
@onready var top_bar: ColorRect = $CinematicLayer/TopBar
@onready var bottom_bar: ColorRect = $CinematicLayer/BottomBar
@onready var title_label: Label = $CinematicLayer/TitleLabel
@onready var screen_taunt_label: Label = $CinematicLayer/ScreenTauntLabel

var life: int = 600
var player: Node2D
var attack_timer := 0.0
var lunge_timer := 0.0
var ground_burst_timer := 0.0
var ground_burst_active_timer := 0.0
var ground_burst_has_hit := false
var platform_jump_timer := 0.0
var platform_jump_active := false
var double_jump_used := false
var dead := false
var action_locked := true
var intro_played := false
var facing_direction := -1.0
var spawn_position := Vector2.ZERO
var last_respawn_index := -1


func _ready() -> void:
	randomize()
	add_to_group("Enemy")
	add_to_group("enemy")
	add_to_group("Boss")
	life = max_life
	_update_health_bar()
	spawn_position = global_position
	sprite.scale = boss_sprite_scale
	sprite.animation_finished.connect(_on_animation_finished)
	taunt_label.visible = false
	screen_taunt_label.visible = false
	_setup_cinematic_layer()
	_turn_toward_direction(facing_direction)
	_play("Idle")
	if not cinematic_enabled:
		action_locked = false
		intro_played = true


func _physics_process(delta: float) -> void:
	if dead:
		return

	attack_timer = max(attack_timer - delta, 0.0)
	lunge_timer = max(lunge_timer - delta, 0.0)
	ground_burst_timer = max(ground_burst_timer - delta, 0.0)
	ground_burst_active_timer = max(ground_burst_active_timer - delta, 0.0)
	platform_jump_timer = max(platform_jump_timer - delta, 0.0)
	if global_position.y > fall_recover_y:
		_recover_from_fall()
		move_and_slide()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	_find_player()
	_face_player_in_notice_radius(delta)

	if cinematic_enabled and not intro_played and _player_close_for_intro():
		_play_intro()
		move_and_slide()
		return

	if lunge_timer > 0.0:
		velocity.x = facing_direction * lunge_speed
		move_and_slide()
		return

	if ground_burst_active_timer > 0.0:
		_update_ground_burst()
		move_and_slide()
		return

	if platform_jump_active:
		_update_platform_jump(delta)
		move_and_slide()
		return

	if action_locked:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 4.0)
		move_and_slide()
		return

	if not player:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 2.0)
		sprite.speed_scale = 1.0
		_play("Idle")
		move_and_slide()
		return

	var target_position := _get_player_hit_position()
	var distance := get_hit_position().distance_to(target_position)
	var direction: float = sign(target_position.x - get_hit_position().x)
	if not is_zero_approx(direction):
		facing_direction = direction
		_turn_toward_direction(facing_direction)

	if _can_start_platform_jump(target_position) and platform_jump_timer <= 0.0:
		_start_platform_jump()
	elif _can_start_ground_burst(distance) and ground_burst_timer <= 0.0 and attack_timer <= 0.0:
		_start_ground_burst()
	elif distance <= attack_distance and attack_timer <= 0.0:
		_start_attack()
	elif distance <= chase_distance:
		var current_speed := run_speed if distance <= notice_radius else move_speed
		velocity.x = facing_direction * current_speed
		sprite.speed_scale = clamp(current_speed / move_speed, 1.0, 1.9)
		_play("Walking")
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 2.0)
		sprite.speed_scale = 1.0
		_play("Idle")

	move_and_slide()


func take_damage(amount: int) -> void:
	if dead:
		return
	life = max(life - amount, 0)
	_update_health_bar()
	if life <= 0:
		_die()
		return
	if not action_locked:
		action_locked = true
		_play("Hurt")


func get_hit_position() -> Vector2:
	return global_position + Vector2(0.0, -86.0)


func _start_attack() -> void:
	attack_timer = attack_cooldown
	action_locked = true
	lunge_timer = lunge_time
	velocity.x = facing_direction * lunge_speed
	sprite.speed_scale = 1.0
	_play("Cleave")
	await get_tree().create_timer(attack_hit_delay).timeout
	if not dead:
		_damage_player_if_close()


func _can_start_ground_burst(distance: float) -> bool:
	return is_on_floor() and distance >= ground_burst_distance_min and distance <= ground_burst_distance_max


func _start_ground_burst() -> void:
	ground_burst_timer = ground_burst_cooldown
	attack_timer = attack_cooldown
	action_locked = true
	ground_burst_active_timer = ground_burst_time
	ground_burst_has_hit = false
	velocity.x = facing_direction * ground_burst_speed
	sprite.speed_scale = 1.15
	_play("Cleave")
	sprite.scale = Vector2(boss_sprite_scale.x * 1.04, boss_sprite_scale.y * 0.95)


func _update_ground_burst() -> void:
	velocity.x = facing_direction * ground_burst_speed
	if not ground_burst_has_hit:
		_damage_player_in_ground_burst()
		ground_burst_has_hit = true
	if ground_burst_active_timer <= 0.0:
		velocity.x = 0.0
		sprite.scale = boss_sprite_scale
		sprite.speed_scale = 1.0
		action_locked = false
		_play("Idle")


func _can_start_platform_jump(target_position: Vector2) -> bool:
	if not is_on_floor():
		return false
	var offset: Vector2 = target_position - get_hit_position()
	var horizontal_distance: float = abs(offset.x)
	if horizontal_distance > platform_jump_max_horizontal:
		return false
	if offset.y > platform_jump_max_drop:
		return false
	var player_is_above: bool = offset.y <= -platform_jump_min_vertical
	var player_is_across_gap: bool = horizontal_distance >= platform_jump_gap_min_horizontal
	return player_is_above or player_is_across_gap or _should_jump_from_edge(offset)


func _should_jump_from_edge(target_offset: Vector2) -> bool:
	if abs(target_offset.x) < edge_jump_min_target_horizontal:
		return false
	if sign(target_offset.x) != sign(facing_direction):
		return false
	return not _has_floor_ahead()


func _has_floor_ahead() -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var probe_x: float = global_position.x + facing_direction * edge_jump_probe_forward
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		Vector2(probe_x, global_position.y - edge_jump_probe_up),
		Vector2(probe_x, global_position.y + edge_jump_probe_down)
	)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result: Dictionary = space_state.intersect_ray(query)
	return not result.is_empty()


func _start_platform_jump() -> void:
	platform_jump_timer = platform_jump_cooldown
	platform_jump_active = true
	double_jump_used = false
	action_locked = true
	sprite.speed_scale = 1.0
	sprite.scale = Vector2(boss_sprite_scale.x * 0.96, boss_sprite_scale.y * 1.04)
	_play("Jump")
	velocity.x = facing_direction * platform_jump_forward_speed
	velocity.y = -platform_jump_velocity


func _update_platform_jump(delta: float) -> void:
	_face_player_for_attack()
	velocity.x = facing_direction * (air_double_jump_forward_speed if double_jump_used else platform_jump_forward_speed)
	var target_tilt: float = -facing_direction * jump_sprite_tilt_degrees
	if velocity.y > 0.0:
		target_tilt = facing_direction * jump_sprite_tilt_degrees * 0.55
	sprite.rotation_degrees = move_toward(sprite.rotation_degrees, target_tilt, 220.0 * delta)
	sprite.scale = boss_sprite_scale
	if _should_air_double_jump():
		_start_air_double_jump()
	if is_on_floor() and velocity.y >= 0.0:
		platform_jump_active = false
		action_locked = false
		sprite.speed_scale = 1.0
		sprite.rotation_degrees = 0.0
		sprite.scale = boss_sprite_scale
		_play("Idle")


func _should_air_double_jump() -> bool:
	if double_jump_used or not player:
		return false
	if velocity.y <= 0.0:
		return false
	return is_on_wall() or _is_near_ground_for_double_jump()


func _start_air_double_jump() -> void:
	double_jump_used = true
	velocity.x = facing_direction * air_double_jump_forward_speed
	velocity.y = -air_double_jump_velocity
	sprite.scale = Vector2(boss_sprite_scale.x * 0.94, boss_sprite_scale.y * 1.06)
	_play("Jump")


func _is_near_ground_for_double_jump() -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2(0.0, air_double_jump_near_ground_distance)
	)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result: Dictionary = space_state.intersect_ray(query)
	return not result.is_empty()


func _face_player_for_attack() -> void:
	if not player:
		return
	var offset := _get_player_hit_position() - get_hit_position()
	var direction: float = sign(offset.x)
	if not is_zero_approx(direction):
		facing_direction = direction
		_turn_toward_direction(facing_direction)


func _recover_from_fall() -> void:
	global_position = _get_random_recover_position()
	velocity = Vector2.ZERO
	attack_timer = attack_cooldown
	ground_burst_active_timer = 0.0
	platform_jump_active = false
	double_jump_used = false
	action_locked = false
	sprite.scale = boss_sprite_scale
	sprite.rotation_degrees = 0.0
	sprite.speed_scale = 1.0
	_play("Idle")
	_show_taunt(fall_recover_message)


func _get_random_recover_position() -> Vector2:
	if random_respawn_positions.is_empty():
		return _snap_respawn_position_to_floor(spawn_position) + fall_recover_offset
	var index: int = randi_range(0, random_respawn_positions.size() - 1)
	if random_respawn_positions.size() > 1:
		while index == last_respawn_index:
			index = randi_range(0, random_respawn_positions.size() - 1)
	last_respawn_index = index
	return _snap_respawn_position_to_floor(random_respawn_positions[index]) + fall_recover_offset


func _snap_respawn_position_to_floor(position: Vector2) -> Vector2:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(position.x, position.y - respawn_floor_snap_up),
		Vector2(position.x, position.y + respawn_floor_snap_down)
	)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result: Dictionary = space_state.intersect_ray(query)
	if not result.has("position"):
		return position
	var floor_position: Vector2 = result["position"]
	return Vector2(position.x, floor_position.y)


func _show_taunt(message: String) -> void:
	taunt_label.visible = false
	screen_taunt_label.text = message
	screen_taunt_label.visible = true
	screen_taunt_label.modulate.a = 1.0
	cinematic_layer.visible = true
	var tween := create_tween()
	tween.tween_interval(fall_recover_message_time)
	tween.tween_property(screen_taunt_label, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		screen_taunt_label.visible = false
		if title_label.modulate.a <= 0.0:
			cinematic_layer.visible = false
	)


func _damage_player_in_ground_burst() -> void:
	if not player or not player.has_method("take_damage"):
		return
	var offset := _get_player_hit_position() - get_hit_position()
	if abs(offset.x) > ground_burst_radius or abs(offset.y) > 120.0:
		return
	player.take_damage(ground_burst_damage)
	if player is CharacterBody2D:
		var knockback_direction: float = sign(offset.x)
		if is_zero_approx(knockback_direction):
			knockback_direction = facing_direction
		(player as CharacterBody2D).velocity = Vector2(knockback_direction * ground_burst_knockback.x, ground_burst_knockback.y)


func _damage_player_if_close() -> void:
	if not player or not player.has_method("take_damage"):
		return
	if get_hit_position().distance_to(_get_player_hit_position()) > attack_distance + 36.0:
		return
	player.take_damage(attack_damage)
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2(facing_direction * attack_knockback.x, attack_knockback.y)


func _die() -> void:
	dead = true
	action_locked = true
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	health_bar.visible = false
	_play("Dying")


func _update_health_bar() -> void:
	if not is_instance_valid(health_bar_progress_clip):
		return
	var health_percent: float = 1.0
	if max_life > 0:
		health_percent = clamp(float(life) / float(max_life), 0.0, 1.0)
	health_bar_progress_clip.size.x = 288.0 * health_percent


func _find_player() -> void:
	var closest_player: Node2D
	var closest_distance := INF
	for candidate in get_tree().get_nodes_in_group("Player"):
		if not candidate is Node2D:
			continue
		if candidate.get("dead") == true:
			continue
		var candidate_position: Vector2 = candidate.global_position
		if candidate.has_method("get_hit_position"):
			candidate_position = candidate.get_hit_position()
		var distance := get_hit_position().distance_to(candidate_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = candidate
	player = closest_player


func _face_player_in_notice_radius(delta: float) -> void:
	if not player:
		sprite.rotation_degrees = move_toward(sprite.rotation_degrees, 0.0, 40.0 * delta)
		return

	var target_position := _get_player_hit_position()
	var offset := target_position - get_hit_position()
	if offset.length() > notice_radius:
		sprite.rotation_degrees = move_toward(sprite.rotation_degrees, 0.0, 40.0 * delta)
		return

	var direction: float = sign(offset.x)
	if not is_zero_approx(direction):
		facing_direction = direction
		_turn_toward_direction(facing_direction)

	sprite.rotation_degrees = move_toward(sprite.rotation_degrees, 0.0, 70.0 * delta)


func _turn_toward_direction(direction: float) -> void:
	if is_zero_approx(direction):
		return
	sprite.flip_h = direction > 0.0 if sprite_faces_left else direction < 0.0


func _get_player_hit_position() -> Vector2:
	if player and player.has_method("get_hit_position"):
		return player.get_hit_position()
	if player:
		return player.global_position
	return global_position


func _player_close_for_intro() -> bool:
	if not player:
		return false
	return get_hit_position().distance_to(_get_player_hit_position()) <= cinematic_trigger_distance


func _play_intro() -> void:
	intro_played = true
	action_locked = true
	velocity = Vector2.ZERO
	cinematic_started.emit()
	cinematic_layer.visible = true
	title_label.modulate.a = 0.0
	top_bar.size.y = 0.0
	bottom_bar.size.y = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(top_bar, "size:y", 72.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bottom_bar, "size:y", 72.0, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.45).set_delay(0.25)
	tween.set_parallel(false)
	tween.tween_interval(1.1)
	tween.tween_property(title_label, "modulate:a", 0.0, 0.35)
	tween.tween_property(top_bar, "size:y", 0.0, 0.25)
	tween.parallel().tween_property(bottom_bar, "size:y", 0.0, 0.25)
	tween.tween_callback(func() -> void:
		cinematic_layer.visible = false
		action_locked = false
		cinematic_finished.emit()
	)


func _setup_cinematic_layer() -> void:
	cinematic_layer.visible = false
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(1280.0, 0.0)
	bottom_bar.position = Vector2(0.0, 648.0)
	bottom_bar.size = Vector2(1280.0, 0.0)
	title_label.modulate.a = 0.0
	screen_taunt_label.modulate.a = 0.0


func _on_animation_finished() -> void:
	if dead:
		queue_free()
		return
	if sprite.animation in ["Cleave", "Hurt"]:
		sprite.scale = boss_sprite_scale
		sprite.speed_scale = 1.0
		action_locked = false
		_play("Idle")


func _play(animation_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name or not sprite.is_playing():
			sprite.play(animation_name)
