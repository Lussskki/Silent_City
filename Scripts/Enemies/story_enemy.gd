extends CharacterBody2D

const EnemyHealthBarScript := preload("res://Scripts/Enemies/enemy_health_bar.gd")

signal defeated(enemy: Node)
signal emergence_finished(enemy: Node)

enum State {
	DORMANT,
	EMERGING,
	IDLE,
	CHASE,
	WINDUP,
	ATTACK,
	RECOVERY,
	HURT,
	DYING,
	DEAD,
}

const ANIMATION_FOLDERS := {
	"dying": "Dying",
	"falling_down": "Falling Down",
	"hurt": "Hurt",
	"idle": "Idle",
	"idle_blinking": "Idle Blinking",
	"jump_loop": "Jump Loop",
	"jump_start": "Jump Start",
	"kicking": "Kicking",
	"run_slashing": "Run Slashing",
	"run_throwing": "Run Throwing",
	"running": "Running",
	"slashing": "Slashing",
	"slashing_in_air": "Slashing in The Air",
	"sliding": "Sliding",
	"throwing": "Throwing",
	"throwing_in_air": "Throwing in The Air",
	"walking": "Walking",
}

const NON_LOOPING_ANIMATIONS := [
	"dying", "falling_down", "hurt", "jump_start", "kicking",
	"run_slashing", "run_throwing", "slashing", "slashing_in_air",
	"sliding", "throwing", "throwing_in_air",
]

const SOURCE_ROOTS := {
	"zombie": "res://Resources/Second_prompt/zombies, skeletons/Zombie_Villager_2/PNG/PNG Sequences",
	"skeleton": "res://Resources/Second_prompt/zombies, skeletons/Skeleton_Warrior_1/PNG/PNG Sequences",
}

static var _frames_cache: Dictionary = {}
static var _loaded_animations: Dictionary = {}

const SOURCE_FRAME_SIZE := 900.0

@export_enum("zombie", "skeleton") var enemy_kind := "zombie"
@export var max_life := 75
@export var move_speed := 95.0
@export var detection_distance := 520.0
@export var attack_distance := 78.0
@export var attack_vertical_tolerance := 85.0
@export var attack_damage := 10
@export var attack_animation := "kicking"
@export var windup_time := 0.58
@export var active_time := 0.16
@export var recovery_time := 0.90
@export var recognition_time := 0.55
@export var emergence_time := 1.0
@export var patrol_half_width := 170.0
@export var sprite_scale := 0.22
@export var low_memory_mode := true

var life := 0
var dead := false
var state := State.DORMANT
var state_time := 0.0
var spawn_x := 0.0
var player: Node2D
var damage_applied := false
var registered_with_hud := false
var knockback_velocity := 0.0

var sprite: AnimatedSprite2D
var body_collision: CollisionShape2D
var health_bar: Node2D


func _ready() -> void:
	_ensure_runtime_nodes()
	life = max_life
	spawn_x = global_position.x
	sprite.sprite_frames = _get_lazy_sprite_frames(enemy_kind)
	_play_animation(&"idle")
	_apply_sprite_display_scale()
	sprite.position = Vector2(0.0, -66.0)
	_apply_dormant_state()


func _physics_process(delta: float) -> void:
	if state in [State.DORMANT, State.EMERGING, State.DEAD]:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0.0

	state_time = maxf(state_time - delta, 0.0)
	knockback_velocity = move_toward(knockback_velocity, 0.0, 560.0 * delta)

	match state:
		State.IDLE:
			velocity.x = knockback_velocity
			if state_time <= 0.0:
				_set_state(State.CHASE)
		State.CHASE:
			_update_chase()
		State.WINDUP:
			velocity.x = knockback_velocity
			if state_time <= 0.0:
				_set_state(State.ATTACK)
		State.ATTACK:
			velocity.x = knockback_velocity
			if not damage_applied:
				_try_damage_player()
				damage_applied = true
			if state_time <= 0.0:
				_set_state(State.RECOVERY)
		State.RECOVERY:
			velocity.x = knockback_velocity
			if state_time <= 0.0:
				_set_state(State.CHASE)
		State.HURT:
			velocity.x = knockback_velocity
			if state_time <= 0.0:
				_set_state(State.CHASE)
		State.DYING:
			velocity.x = 0.0
			if state_time <= 0.0:
				_finish_death()

	move_and_slide()


func begin_emergence() -> void:
	if state != State.DORMANT:
		return
	visible = true
	if not registered_with_hud:
		add_to_group("Enemy")
		add_to_group("enemy")
		registered_with_hud = true
	state = State.EMERGING
	body_collision.set_deferred("disabled", true)
	health_bar.visible = false
	_play_animation(&"idle")
	sprite.position = Vector2(0.0, 18.0)
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.18)
	var rise := create_tween()
	rise.set_parallel(true)
	rise.set_trans(Tween.TRANS_QUAD)
	rise.set_ease(Tween.EASE_OUT)
	rise.tween_property(sprite, "position:y", -66.0, emergence_time)
	rise.tween_property(sprite, "modulate:a", 1.0, emergence_time * 0.72)
	rise.chain().tween_callback(_complete_emergence)


func prepare_dormant() -> void:
	if not is_node_ready():
		return
	_apply_dormant_state()


func take_damage(amount: int) -> void:
	if dead or state in [State.DORMANT, State.EMERGING, State.DYING, State.DEAD]:
		return
	life = maxi(life - maxi(amount, 0), 0)
	_update_health_bar()
	if life <= 0:
		_begin_death()
	else:
		_set_state(State.HURT)


func take_kick(amount: int, knockback: Vector2) -> void:
	take_damage(amount)
	if not dead:
		apply_knockback(knockback)


func apply_knockback(force: Vector2) -> void:
	if dead or state in [State.DORMANT, State.EMERGING]:
		return
	knockback_velocity = clampf(force.x, -260.0, 260.0)
	velocity.y = minf(force.y, 0.0)


func get_hit_position() -> Vector2:
	return global_position + Vector2(0.0, -48.0)


func get_animation_library_summary() -> Dictionary:
	var summary := {}
	var root_path := String(SOURCE_ROOTS.get(enemy_kind, SOURCE_ROOTS["zombie"]))
	for animation_name: String in ANIMATION_FOLDERS:
		var folder_name := String(ANIMATION_FOLDERS[animation_name])
		summary[animation_name] = _png_paths(root_path.path_join(folder_name)).size()
	return summary


func get_runtime_loaded_frame_count() -> int:
	var total := 0
	for animation_name in sprite.sprite_frames.get_animation_names():
		total += sprite.sprite_frames.get_frame_count(animation_name)
	return total


func get_runtime_max_texture_width() -> int:
	var maximum_width := 0
	for animation_name in sprite.sprite_frames.get_animation_names():
		for frame_index in sprite.sprite_frames.get_frame_count(animation_name):
			var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
			if texture != null:
				maximum_width = maxi(maximum_width, texture.get_width())
	return maximum_width


func _ensure_runtime_nodes() -> void:
	sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		sprite.z_index = 9
		add_child(sprite)

	body_collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_collision == null:
		body_collision = CollisionShape2D.new()
		body_collision.name = "CollisionShape2D"
		body_collision.position = Vector2(0.0, -45.0)
		var shape := CapsuleShape2D.new()
		shape.radius = 22.0
		shape.height = 90.0
		body_collision.shape = shape
		add_child(body_collision)

	health_bar = get_node_or_null("HealthBar") as Node2D
	if health_bar == null:
		health_bar = EnemyHealthBarScript.new()
		health_bar.name = "HealthBar"
		health_bar.z_index = 20
		health_bar.position = Vector2(0.0, -126.0)
		add_child(health_bar)


func _apply_dormant_state() -> void:
	state = State.DORMANT
	state_time = 0.0
	dead = false
	life = max_life
	velocity = Vector2.ZERO
	knockback_velocity = 0.0
	visible = false
	body_collision.set_deferred("disabled", true)
	health_bar.visible = false
	_update_health_bar()
	if registered_with_hud:
		remove_from_group("Enemy")
		remove_from_group("enemy")
		registered_with_hud = false


func _complete_emergence() -> void:
	if state != State.EMERGING:
		return
	body_collision.set_deferred("disabled", false)
	health_bar.visible = true
	_set_state(State.IDLE)
	emergence_finished.emit(self)


func _set_state(next_state: State) -> void:
	if dead and next_state != State.DEAD:
		return
	state = next_state
	match state:
		State.IDLE:
			state_time = recognition_time
			_play_animation(&"idle")
		State.CHASE:
			state_time = 0.0
			_play_animation(&"walking")
		State.WINDUP:
			state_time = windup_time
			damage_applied = false
			_play_animation(StringName(attack_animation))
		State.ATTACK:
			state_time = active_time
		State.RECOVERY:
			state_time = recovery_time
			_play_animation(&"idle")
		State.HURT:
			state_time = 0.34
			_play_animation(&"hurt")


func _update_chase() -> void:
	_find_player()
	if player == null:
		_patrol()
		return
	var offset := player.global_position - global_position
	if absf(offset.y) > 140.0 or absf(offset.x) > detection_distance:
		_patrol()
		return
	var direction := signf(offset.x)
	if not is_zero_approx(direction):
		sprite.flip_h = direction < 0.0
	if absf(offset.x) <= attack_distance and absf(offset.y) <= attack_vertical_tolerance:
		velocity.x = knockback_velocity
		_set_state(State.WINDUP)
		return
	velocity.x = direction * move_speed + knockback_velocity
	if sprite.animation != &"walking":
		_play_animation(&"walking")


func _patrol() -> void:
	var left := spawn_x - patrol_half_width
	var right := spawn_x + patrol_half_width
	var direction := -1.0 if global_position.x >= right else 1.0
	if global_position.x > left and global_position.x < right:
		direction = -1.0 if sprite.flip_h else 1.0
	sprite.flip_h = direction < 0.0
	velocity.x = direction * move_speed * 0.45 + knockback_velocity


func _find_player() -> void:
	if is_instance_valid(player) and player.get("dead") != true:
		return
	player = null
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("Player"):
		if not candidate is Node2D or candidate.get("dead") == true:
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			player = candidate as Node2D


func _try_damage_player() -> void:
	_find_player()
	if player == null or not player.has_method("take_damage"):
		return
	var offset := player.global_position - global_position
	var facing := -1.0 if sprite.flip_h else 1.0
	if absf(offset.y) > attack_vertical_tolerance:
		return
	if offset.x * facing < -16.0 or offset.x * facing > attack_distance + 12.0:
		return
	player.call("take_damage", attack_damage)


func _begin_death() -> void:
	if dead:
		return
	dead = true
	state = State.DYING
	state_time = 1.65
	velocity = Vector2.ZERO
	body_collision.set_deferred("disabled", true)
	health_bar.visible = false
	_play_animation(&"dying")
	defeated.emit(self)


func _finish_death() -> void:
	state = State.DEAD
	remove_from_group("Enemy")
	remove_from_group("enemy")
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.35)
	fade.tween_callback(queue_free)


func _update_health_bar() -> void:
	if health_bar != null:
		health_bar.call("set_values", life, max_life)


func _get_lazy_sprite_frames(kind: String) -> SpriteFrames:
	if _frames_cache.has(kind):
		return _frames_cache[kind] as SpriteFrames

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	for animation_name: String in ANIMATION_FOLDERS:
		frames.add_animation(StringName(animation_name))
		frames.set_animation_loop(StringName(animation_name), animation_name not in NON_LOOPING_ANIMATIONS)
		frames.set_animation_speed(StringName(animation_name), _animation_fps(animation_name))
	_frames_cache[kind] = frames
	_loaded_animations[kind] = {}
	return frames


func _play_animation(animation_name: StringName) -> void:
	if low_memory_mode and animation_name != &"idle":
		animation_name = &"idle"
	_ensure_animation_loaded(String(animation_name))
	if sprite.sprite_frames.get_frame_count(animation_name) > 0:
		sprite.play(animation_name)


func _ensure_animation_loaded(animation_name: String) -> void:
	var loaded_for_kind: Dictionary = _loaded_animations.get(enemy_kind, {})
	if int(loaded_for_kind.get(animation_name, 0)) == 2:
		return
	var folder_name := String(ANIMATION_FOLDERS.get(animation_name, ""))
	if folder_name.is_empty():
		return
	var root_path := String(SOURCE_ROOTS.get(enemy_kind, SOURCE_ROOTS["zombie"]))
	var frame_paths := _png_paths(root_path.path_join(folder_name))
	var already_loaded := sprite.sprite_frames.get_frame_count(StringName(animation_name))
	for index in range(already_loaded, frame_paths.size()):
		var frame_path := frame_paths[index]
		var texture := load(frame_path) as Texture2D
		if texture != null:
			sprite.sprite_frames.add_frame(StringName(animation_name), texture)
	loaded_for_kind[animation_name] = 2
	_loaded_animations[enemy_kind] = loaded_for_kind

func _apply_sprite_display_scale() -> void:
	var idle_frames := sprite.sprite_frames
	if idle_frames.get_frame_count(&"idle") == 0:
		sprite.scale = Vector2.ONE * sprite_scale
		return
	var texture := idle_frames.get_frame_texture(&"idle", 0)
	var imported_width := float(texture.get_width()) if texture != null else SOURCE_FRAME_SIZE
	var import_compensation := SOURCE_FRAME_SIZE / maxf(imported_width, 1.0)
	sprite.scale = Vector2.ONE * sprite_scale * import_compensation


func _png_paths(folder_path: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var files := DirAccess.get_files_at(folder_path)
	files.sort()
	for file_name in files:
		if file_name.to_lower().ends_with(".png"):
			paths.append(folder_path.path_join(file_name))
	return paths


func _animation_fps(animation_name: String) -> float:
	if animation_name in ["slashing", "kicking", "hurt", "run_slashing"]:
		return 11.0
	if animation_name == "dying":
		return 9.0
	return 9.0
