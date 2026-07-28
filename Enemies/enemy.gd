extends CharacterBody2D

@export var max_life: int = 100
@export var move_speed := 95.0
@export var chase_distance := 520.0
@export var attack_distance := 95.0
@export var attack_vertical_tolerance := 95.0
@export var attack_damage: int = 10
@export var attack_cooldown := 1.0
@export var hurt_cooldown := 0.35
@export var patrol_min_x := 0.0
@export var patrol_max_x := 0.0
@export var sight_vertical_tolerance := 120.0
@export var random_character := true
@export var character_name := ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar

const CHARACTER_NAMES := [
	"Adventurer",
	"Female",
	"Soldier",
	"Zombie"
]

const SPRITE_GROUND_Y := 12.0

var life: int = 100
var player: Node2D
var attack_timer := 0.0
var hurt_timer := 0.0
var dead := false
var character_key := ""
var idle_texture: Texture2D
var walk_textures: Array[Texture2D] = []
var attack_texture: Texture2D
var hurt_texture: Texture2D
var flip_direction := false
var network_sync_timer := 0.0
var current_pose := "idle"
var patrol_direction := 1.0

func _ready() -> void:
	add_to_group("Enemy")
	add_to_group("enemy")
	life = max_life
	if is_zero_approx(patrol_min_x) and is_zero_approx(patrol_max_x):
		patrol_min_x = global_position.x - 120.0
		patrol_max_x = global_position.x + 120.0
	_setup_random_character()
	_find_player()
	_ignore_player_collisions()
	_update_health_bar()


# ბრძოლა დისტანციაზეა (range-based), ამიტომ მოთამაშესა და მტერს ფიზიკურად
# არ უნდა ეჯახებოდნენ — თორემ მტრის collision სხეული მოთამაშეს ვერ ატანს ახლოს.
func _ignore_player_collisions() -> void:
	for candidate in get_tree().get_nodes_in_group("Player"):
		if candidate is PhysicsBody2D:
			add_collision_exception_with(candidate)
			candidate.add_collision_exception_with(self)


func _physics_process(delta: float) -> void:
	if dead:
		return

	var api := get_multiplayer()
	if api and api.has_multiplayer_peer() and not api.is_server():
		return

	attack_timer = max(attack_timer - delta, 0.0)
	hurt_timer = max(hurt_timer - delta, 0.0)

	_find_player()

	if not is_on_floor():
		velocity += get_gravity() * delta

	if player:
		var enemy_position := get_hit_position()
		var player_position := _get_player_hit_position()
		var distance := enemy_position.distance_to(player_position)
		var direction: float = sign(player_position.x - enemy_position.x)
		var player_in_attack_range := _is_player_in_attack_range()

		if _can_see_player(distance, player_position) and not player_in_attack_range:
			_walk(direction, move_speed, delta)
		else:
			_patrol(delta)

		if player_in_attack_range:
			_try_attack_player()
	else:
		_patrol(delta)

	move_and_slide()
	_send_network_state(delta)


func take_damage(amount: int) -> void:
	if dead:
		return

	var api := get_multiplayer()
	if api and api.has_multiplayer_peer() and not api.is_server():
		rpc_id(1, "network_take_damage", amount)
		return

	life = max(life - amount, 0)
	_update_health_bar()
	_show_hurt_pose()
	modulate = Color(1.0, 0.45, 0.45)

	if life <= 0:
		_die()
		return

	await get_tree().create_timer(0.12).timeout
	if not dead:
		modulate = Color.WHITE


func get_hit_position() -> Vector2:
	return sprite.global_position


@rpc("any_peer", "reliable")
func network_take_damage(amount: int) -> void:
	var api := get_multiplayer()
	if api and api.has_multiplayer_peer() and not api.is_server():
		return
	take_damage(amount)


func _find_player() -> void:
	var closest_player: Node2D
	var closest_distance := INF
	for candidate in get_tree().get_nodes_in_group("Player"):
		if not candidate is Node2D:
			continue
		if candidate is CanvasItem and not candidate.visible:
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


func _try_attack_player() -> void:
	if attack_timer > 0.0:
		return
	if not player:
		return
	if not _is_player_in_attack_range():
		return

	attack_timer = attack_cooldown
	_show_attack_pose()
	_damage_player(player, attack_damage)


func _damage_player(target: Node, amount: int) -> void:
	if not target or not target.has_method("take_damage"):
		return

	var api := get_multiplayer()
	if api and api.has_multiplayer_peer():
		var target_peer_id := int(target.get("network_player_id"))
		if target_peer_id != api.get_unique_id() and target_peer_id in api.get_peers() and target.has_method("network_take_damage"):
			target.rpc_id(target_peer_id, "network_take_damage", amount)
			return

	target.take_damage(amount)


func _try_take_player_hit(distance: float) -> void:
	if hurt_timer > 0.0:
		return
	if not player or not player.has_method("is_attacking_enemy"):
		return
	if distance > attack_distance + 45.0:
		return
	if not player.is_attacking_enemy():
		return

	hurt_timer = hurt_cooldown
	var damage := 25
	if player.has_method("get_attack_damage"):
		damage = int(player.get_attack_damage())
	take_damage(damage)


func _get_player_hit_position() -> Vector2:
	if player and player.has_method("get_hit_position"):
		return player.get_hit_position()
	if player:
		return player.global_position
	return global_position


func _is_player_in_attack_range() -> bool:
	var hit_offset := _get_player_hit_position() - get_hit_position()
	return abs(hit_offset.x) <= attack_distance and abs(hit_offset.y) <= attack_vertical_tolerance


func _can_see_player(distance: float, player_position: Vector2) -> bool:
	if distance > chase_distance:
		return false
	if abs(player_position.y - get_hit_position().y) > sight_vertical_tolerance:
		return false
	return player_position.x >= patrol_min_x - 80.0 and player_position.x <= patrol_max_x + 80.0


func _patrol(delta: float) -> void:
	_walk(patrol_direction, move_speed * 0.55, delta)


func _walk(direction: float, speed: float, delta: float) -> void:
	if is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, 0.0, speed)
		_show_idle_pose()
		return

	var next_x := global_position.x + direction * speed * delta
	if next_x <= patrol_min_x:
		direction = 1.0
		patrol_direction = 1.0
	elif next_x >= patrol_max_x:
		direction = -1.0
		patrol_direction = -1.0
	else:
		patrol_direction = direction

	velocity.x = direction * speed
	flip_direction = direction < 0
	sprite.flip_h = flip_direction
	_show_walk_pose()


func _update_health_bar() -> void:
	health_bar.max_value = max_life
	health_bar.value = life


func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	current_pose = "dead"
	modulate = Color(0.35, 0.35, 0.35, 0.75)
	if _is_network_server():
		rpc("_network_enemy_died")
	await get_tree().create_timer(0.35).timeout
	queue_free()


func _setup_random_character() -> void:
	var names := CHARACTER_NAMES
	character_key = character_name
	if random_character or character_key.is_empty():
		character_key = names.pick_random()

	var prefix := character_key.to_lower()
	var pose_dir := "res://Characters/%s/Poses" % character_key

	idle_texture = load("%s/%s_idle.png" % [pose_dir, prefix]) as Texture2D
	walk_textures = [
		load("%s/%s_walk1.png" % [pose_dir, prefix]) as Texture2D,
		load("%s/%s_walk2.png" % [pose_dir, prefix]) as Texture2D
	]
	attack_texture = load("%s/%s_action1.png" % [pose_dir, prefix]) as Texture2D
	hurt_texture = load("%s/%s_hurt.png" % [pose_dir, prefix]) as Texture2D

	if idle_texture:
		sprite.texture = idle_texture
		_align_sprite_to_ground()


func _show_idle_pose() -> void:
	if attack_timer > attack_cooldown - 0.18:
		return
	current_pose = "idle"
	if idle_texture and sprite.texture != idle_texture:
		sprite.texture = idle_texture
		_align_sprite_to_ground()


func _show_walk_pose() -> void:
	if attack_timer > attack_cooldown - 0.18:
		return
	if walk_textures.is_empty():
		return

	current_pose = "walk"
	var index := int(Time.get_ticks_msec() / 220) % walk_textures.size()
	if walk_textures[index]:
		sprite.texture = walk_textures[index]
		_align_sprite_to_ground()


func _show_attack_pose() -> void:
	current_pose = "attack"
	if attack_texture:
		sprite.texture = attack_texture
		_align_sprite_to_ground()


func _show_hurt_pose() -> void:
	current_pose = "hurt"
	if hurt_texture:
		sprite.texture = hurt_texture
		_align_sprite_to_ground()


func _align_sprite_to_ground() -> void:
	if not sprite.texture:
		return

	var texture_height := float(sprite.texture.get_height())
	sprite.position.y = SPRITE_GROUND_Y - (texture_height * abs(sprite.scale.y) * 0.5)


func _send_network_state(delta: float) -> void:
	if not _is_network_server():
		return

	network_sync_timer -= delta
	if network_sync_timer > 0.0:
		return

	network_sync_timer = 0.1
	rpc("_receive_network_state", global_position, velocity, sprite.flip_h, life, current_pose)


@rpc("authority", "unreliable")
func _receive_network_state(remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_life: int, remote_pose: String) -> void:
	var api := get_multiplayer()
	if not api or not api.has_multiplayer_peer() or api.is_server():
		return

	global_position = global_position.lerp(remote_position, 0.65)
	velocity = remote_velocity
	sprite.flip_h = remote_flip_h
	life = remote_life
	current_pose = remote_pose
	_update_health_bar()
	_apply_pose(remote_pose)


@rpc("authority", "reliable")
func _network_enemy_died() -> void:
	if _is_network_server():
		return
	queue_free()


func _apply_pose(pose: String) -> void:
	match pose:
		"walk":
			_show_walk_pose()
		"attack":
			_show_attack_pose()
		"hurt":
			_show_hurt_pose()
		"dead":
			modulate = Color(0.35, 0.35, 0.35, 0.75)
		_:
			_show_idle_pose()


func _is_network_server() -> bool:
	var api := get_multiplayer()
	return api and api.has_multiplayer_peer() and api.is_server()
