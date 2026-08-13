extends CharacterBody2D

@export var max_life: int = 450
@export var notice_radius: float = 620.0
@export var move_speed: float = 24.0
@export var run_speed: float = 48.0
@export var chase_distance: float = 430.0
@export var attack_distance: float = 118.0
@export var jump_attack_distance: float = 280.0
@export var hit_damage: int = 18
@export var boom_damage: int = 28
@export var hook_range: float = 300.0
@export var hook_vertical_tolerance: float = 95.0
@export var hook_pull_speed: float = 145.0
@export var hook_kill_damage: int = 9999
@export var attack_cooldown: float = 3.2
@export var attack_hit_delay: float = 0.22
@export var attack_knockback: Vector2 = Vector2(280.0, -120.0)
@export var jump_cooldown: float = 7.0
@export var jump_velocity: float = 250.0
@export var jump_speed: float = 52.0
@export var platform_jump_min_vertical: float = 60.0
@export var platform_jump_gap_min_horizontal: float = 240.0
@export var platform_jump_max_horizontal: float = 520.0
@export var platform_jump_max_drop: float = 180.0
@export var platform_jump_cooldown: float = 1.2
@export var platform_jump_velocity: float = 560.0
@export var platform_jump_speed: float = 210.0
@export var boom_range: float = 230.0
@export var boom_knockback: Vector2 = Vector2(360.0, -150.0)
@export var edge_jump_probe_forward: float = 96.0
@export var edge_jump_probe_up: float = 24.0
@export var edge_jump_probe_down: float = 190.0
@export var edge_jump_min_target_horizontal: float = 145.0
@export var fall_recover_y: float = 950.0
@export var random_respawn_positions: Array[Vector2] = [
	Vector2(1982.0, 300.0),
	Vector2(2828.0, 430.0),
	Vector2(3282.0, 330.0),
]
@export var respawn_floor_snap_up: float = 460.0
@export var respawn_floor_snap_down: float = 900.0
@export var sprite_faces_left := true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var hook_line: Line2D = $HookLine

var life: int = 450
var player: Node2D
var attack_timer := 0.0
var jump_timer := 0.0
var action_locked := false
var pending_boom := false
var active_jump_speed := 0.0
var hook_target: Node2D
var hook_pulling := false
var dead := false
var hit_index := 0
var facing_direction := -1.0
var spawn_position := Vector2.ZERO
var last_respawn_index := -1


func _ready() -> void:
	add_to_group("Enemy")
	add_to_group("enemy")
	add_to_group("Boss")
	life = max_life
	spawn_position = global_position
	health_bar.max_value = max_life
	health_bar.value = life
	sprite.animation_finished.connect(_on_animation_finished)
	hook_line.visible = false
	_turn_toward_direction(facing_direction)
	_play("Idle")


func _physics_process(delta: float) -> void:
	if dead:
		return

	attack_timer = max(attack_timer - delta, 0.0)
	jump_timer = max(jump_timer - delta, 0.0)
	if global_position.y > fall_recover_y:
		_recover_from_fall()
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	_find_player()
	_face_player_in_notice_radius(delta)

	if pending_boom:
		_update_jump_boom()
		move_and_slide()
		return

	if hook_pulling:
		_update_hook_pull(delta)
		move_and_slide()
		return

	if action_locked:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 2.0)
		move_and_slide()
		return

	if not player:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * delta * 2.0)
		_play("Idle")
		move_and_slide()
		return

	var target_position := _get_player_hit_position()
	var distance := get_hit_position().distance_to(target_position)
	var direction: float = sign(target_position.x - get_hit_position().x)
	if not is_zero_approx(direction):
		facing_direction = direction
		_turn_toward_direction(facing_direction)

	if _can_start_platform_jump(target_position) and jump_timer <= 0.0:
		_start_jump_boom(platform_jump_velocity, platform_jump_speed, platform_jump_cooldown)
	elif distance <= attack_distance and attack_timer <= 0.0:
		_start_hit()
	elif _can_hook_player(target_position) and attack_timer <= 0.0:
		_start_hook()
	elif distance <= jump_attack_distance and distance > attack_distance * 1.2 and attack_timer <= 0.0 and jump_timer <= 0.0 and is_on_floor():
		_start_jump_boom(jump_velocity, jump_speed, jump_cooldown)
	elif distance <= chase_distance:
		var current_speed := run_speed if distance <= notice_radius else move_speed
		velocity.x = facing_direction * current_speed
		sprite.speed_scale = clamp(current_speed / move_speed, 1.0, 1.8)
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
	health_bar.value = life
	if life <= 0:
		_die()
		return

	if not action_locked and not pending_boom:
		_begin_action("Hurt")


func get_hit_position() -> Vector2:
	return global_position + Vector2(0.0, -78.0)


func _start_hit() -> void:
	attack_timer = attack_cooldown
	hit_index = 1 - hit_index
	_begin_action("Hit 1" if hit_index == 0 else "Hit 2")
	await get_tree().create_timer(attack_hit_delay).timeout
	if not dead:
		_damage_player_if_close(hit_damage, attack_distance + 35.0, attack_knockback)


func _start_hook() -> void:
	if not player:
		return
	attack_timer = attack_cooldown + 0.5
	hook_target = player
	hook_pulling = true
	action_locked = true
	velocity.x = 0.0
	_play("Hook Kill")
	_update_hook_line()


func _update_hook_pull(delta: float) -> void:
	if not is_instance_valid(hook_target) or hook_target.get("dead") == true:
		_finish_hook(false)
		return

	var grab_position := _get_hook_grab_position()
	var target_position := _get_hook_target_position()
	var next_position := target_position.move_toward(grab_position, hook_pull_speed * delta)
	var offset := next_position - target_position
	hook_target.global_position += offset
	hook_target.set("velocity", Vector2.ZERO)
	velocity.x = 0.0
	_update_hook_line()

	if next_position.distance_to(grab_position) <= 18.0:
		_finish_hook(true)


func _finish_hook(should_kill: bool) -> void:
	hook_line.visible = false
	if should_kill and is_instance_valid(hook_target) and hook_target.has_method("take_damage"):
		hook_target.call("take_damage", hook_kill_damage)
	hook_target = null
	hook_pulling = false
	action_locked = false
	_play("Idle")


func _can_start_platform_jump(target_position: Vector2) -> bool:
	if not is_on_floor():
		return false
	if action_locked or pending_boom or hook_pulling:
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
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(probe_x, global_position.y - edge_jump_probe_up),
		Vector2(probe_x, global_position.y + edge_jump_probe_down)
	)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	return not space_state.intersect_ray(query).is_empty()


func _start_jump_boom(jump_force: float, forward_speed: float, cooldown: float) -> void:
	attack_timer = attack_cooldown
	jump_timer = cooldown
	pending_boom = true
	action_locked = true
	active_jump_speed = forward_speed
	velocity.x = facing_direction * forward_speed
	velocity.y = -jump_force
	_play("Jump Start")


func _update_jump_boom() -> void:
	_face_player_for_attack()
	if not is_on_floor():
		velocity.x = facing_direction * active_jump_speed
	if velocity.y > 0.0 and sprite.animation != "Jump Loop":
		_play("Jump Loop")
	if is_on_floor() and velocity.y >= 0.0:
		pending_boom = false
		active_jump_speed = 0.0
		velocity.x = 0.0
		_begin_action("Boom")
		_damage_player_if_close(boom_damage, boom_range, boom_knockback)


func _begin_action(animation_name: String) -> void:
	action_locked = true
	_play(animation_name)


func _die() -> void:
	dead = true
	action_locked = true
	velocity = Vector2.ZERO
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	health_bar.visible = false
	_play("Dying")


func _damage_player_if_close(amount: int, radius: float, knockback := Vector2.ZERO) -> void:
	if not player or not player.has_method("take_damage"):
		return
	if get_hit_position().distance_to(_get_player_hit_position()) > radius:
		return
	player.call("take_damage", amount)
	if knockback != Vector2.ZERO and player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2(facing_direction * knockback.x, knockback.y)


func _can_hook_player(target_position: Vector2) -> bool:
	var hook_offset := target_position - get_hit_position()
	if abs(hook_offset.y) > hook_vertical_tolerance:
		return false
	if abs(hook_offset.x) < attack_distance:
		return false
	if abs(hook_offset.x) > hook_range:
		return false
	return sign(hook_offset.x) == sign(facing_direction)


func _get_hook_grab_position() -> Vector2:
	return global_position + Vector2(facing_direction * 62.0, -70.0)


func _get_hook_target_position() -> Vector2:
	if hook_target and hook_target.has_method("get_hit_position"):
		return hook_target.get_hit_position()
	if hook_target:
		return hook_target.global_position
	return global_position


func _update_hook_line() -> void:
	if not hook_line or not is_instance_valid(hook_target):
		return
	hook_line.visible = true
	hook_line.clear_points()
	hook_line.add_point(to_local(_get_hook_grab_position()))
	hook_line.add_point(to_local(_get_hook_target_position()))


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
		var distance := global_position.distance_to(candidate_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = candidate
	player = closest_player


func _face_player_in_notice_radius(delta: float) -> void:
	if not player:
		sprite.rotation_degrees = move_toward(sprite.rotation_degrees, 0.0, 40.0 * delta)
		return

	var offset := _get_player_hit_position() - get_hit_position()
	if offset.length() > notice_radius:
		sprite.rotation_degrees = move_toward(sprite.rotation_degrees, 0.0, 40.0 * delta)
		return

	var direction: float = sign(offset.x)
	if not is_zero_approx(direction):
		facing_direction = direction
		_turn_toward_direction(facing_direction)
	sprite.rotation_degrees = move_toward(sprite.rotation_degrees, 0.0, 70.0 * delta)


func _face_player_for_attack() -> void:
	if not player:
		return
	var direction: float = sign((_get_player_hit_position() - get_hit_position()).x)
	if not is_zero_approx(direction):
		facing_direction = direction
		_turn_toward_direction(facing_direction)


func _turn_toward_direction(direction: float) -> void:
	if is_zero_approx(direction):
		return
	sprite.flip_h = direction > 0.0 if sprite_faces_left else direction < 0.0


func _recover_from_fall() -> void:
	global_position = _get_random_recover_position()
	velocity = Vector2.ZERO
	attack_timer = attack_cooldown
	jump_timer = platform_jump_cooldown
	pending_boom = false
	hook_pulling = false
	hook_target = null
	hook_line.visible = false
	action_locked = false
	sprite.rotation_degrees = 0.0
	sprite.speed_scale = 1.0
	_play("Idle")


func _get_random_recover_position() -> Vector2:
	if random_respawn_positions.is_empty():
		return _snap_respawn_position_to_floor(spawn_position)
	var index: int = randi_range(0, random_respawn_positions.size() - 1)
	if random_respawn_positions.size() > 1:
		while index == last_respawn_index:
			index = randi_range(0, random_respawn_positions.size() - 1)
	last_respawn_index = index
	return _snap_respawn_position_to_floor(random_respawn_positions[index])


func _snap_respawn_position_to_floor(position: Vector2) -> Vector2:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(position.x, position.y - respawn_floor_snap_up),
		Vector2(position.x, position.y + respawn_floor_snap_down)
	)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := space_state.intersect_ray(query)
	if not result.has("position"):
		return position
	var floor_position: Vector2 = result["position"]
	return Vector2(position.x, floor_position.y)


func _get_player_hit_position() -> Vector2:
	if player and player.has_method("get_hit_position"):
		return player.get_hit_position()
	if player:
		return player.global_position
	return global_position


func _on_animation_finished() -> void:
	if dead:
		queue_free()
		return
	if hook_pulling:
		return
	if sprite.animation in ["Hit 1", "Hit 2", "Hook Kill", "Boom", "Hurt"]:
		sprite.speed_scale = 1.0
		action_locked = false
		_play("Idle")


func _play(animation_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name or not sprite.is_playing():
			sprite.play(animation_name)
