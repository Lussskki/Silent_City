extends CharacterBody2D

const WALK_SPEED = 250.0
const RUN_SPEED = 450.0
const JUMP_VELOCITY = -600.0
const MAX_JUMPS = 2
const SLIDE_SPEED = 400.0
const SLIDE_ANGLE = 15.0

const NETWORK_SYNC_INTERVAL = 0.033
const REMOTE_POSITION_SMOOTHING = 20.0

const MENU_TEXTURE_CACHE_META := "_silent_city_menu_texture_cache_v1"
const DEFAULT_SPRITE_OFFSET := Vector2(0, -24)
const GOLEM_SPRITE_OFFSET := Vector2(0, -24)
const ICE_GOLEM_SPRITE_OFFSET := Vector2(0, -24)
const MINOTAUR_SPRITE_OFFSET := Vector2(0, -32)
const SQUAD_ARENA_SCENE := "res://Scenes/SquadArena.tscn"

const ICE_GOLEM_FRAMES_ROOT := "res://Characters/Golem_1/PNG/PNG Sequences"
const CRUSADER_FRAMES_ROOT := "res://Characters/Skeleton_crusider/Skeleton_Crusader_1/PNG/PNG Sequences"
const WRAITH_FRAMES_ROOT := "res://Characters/Wraithes/PNG/Wraith_01/PNG Sequences"
const MINOTAUR_FRAMES_ROOT := "res://Characters/Minotaurs/Minotaur_3/PNG/PNG Sequences"
const RANGER_FRAMES_ROOT := "res://Characters/Forest_Ranger_2/PNG/PNG Sequences"
const SQUAD_IDLE_TEXTURES := {
	"crusader": preload("res://Characters/Skeleton_crusider/Skeleton_Crusader_1/PNG/PNG Sequences/Idle/0_Skeleton_Crusader_Idle_000.png"),
	"wraith": preload("res://Characters/Wraithes/PNG/Wraith_01/PNG Sequences/Idle/Wraith_01_Idle_000.png"),
	"minotaur": preload("res://Characters/Minotaurs/Minotaur_3/PNG/PNG Sequences/Idle/0_Minotaur_Idle_000.png"),
	"ranger": preload("res://Characters/Forest_Ranger_2/PNG/PNG Sequences/Idle/0_Forest_Ranger_Idle_000.png")
}
const SQUAD_CHARACTER_FRAMES := {
	"crusader": preload("res://Resources/squad_crusader_sprite_frames.tres"),
	"wraith": preload("res://Resources/squad_wraith_sprite_frames.tres"),
	"minotaur": preload("res://Resources/squad_minotaur_sprite_frames.tres"),
	"ranger": preload("res://Resources/squad_ranger_sprite_frames.tres")
}

const GOLEM_ANIMATION_DIRS := {
	"Idle": "Idle",
	"Walking": "Walking",
	"Running": "Running",
	"Jump Looping": "Jump Loop",
	"Falling Down": "Falling Down",
	"Slashing": "Slashing",
	"Slashing In Air": "Slashing in The Air",
	"Run Slashing": "Run Slashing",
	"Kicking": "Kicking",
	"Hurt": "Hurt",
	"Throwing": "Throwing",
	"Throwing In Air": "Throwing in The Air",
	"Dying": "Dying",
	"Sliding": "Sliding"
}

const WRAITH_ANIMATION_DIRS := {
	"Idle": "Idle",
	"Walking": "Walking",
	"Running": "Walking",
	"Jump Looping": "Idle",
	"Falling Down": "Idle",
	"Slashing": "Attacking",
	"Slashing In Air": "Attacking",
	"Run Slashing": "Attacking",
	"Kicking": "Attacking",
	"Hurt": "Hurt",
	"Throwing": "Casting Spells",
	"Throwing In Air": "Casting Spells",
	"Dying": "Dying",
	"Sliding": "Walking"
}
const MINOTAUR_ANIMATION_DIRS := {
	"Idle": "Idle", "Walking": "Walking", "Running": "Running",
	"Jump Looping": "Jump Loop", "Falling Down": "Falling Down",
	"Slashing": "Slashing", "Slashing In Air": "Slashing in The Air",
	"Run Slashing": "Run Slashing", "Kicking": "Kicking",
	"Hurt": "Hurt", "Throwing": "Throwing",
	"Throwing In Air": "Throwing In The Air", "Dying": "Dying",
	"Sliding": "Sliding"
}
const RANGER_ANIMATION_DIRS := {
	"Idle": "Idle", "Walking": "Walking", "Running": "Running",
	"Jump Looping": "Jump Loop", "Falling Down": "Falling Down",
	"Slashing": "Shooting", "Slashing In Air": "Shooting in The Air",
	"Run Slashing": "Run Shooting", "Kicking": "Kicking",
	"Hurt": "Hurt", "Throwing": "Throwing",
	"Throwing In Air": "Throwing in The Air", "Dying": "Dying",
	"Sliding": "Sliding"
}

const HURT_ANIMATION_TIME := 0.28

const SHOCKWAVE_DAMAGE := 55
const SHOCKWAVE_RADIUS := 360.0
const SHOCKWAVE_VERTICAL_TOLERANCE := 115.0
const SHOCKWAVE_KNOCKBACK := Vector2(420, -120)


signal life_changed(life: int, max_life: int)
signal power_changed(power: int, max_power: int)


@export_group("Character Sounds")

@export var jump_sound: AudioStream
@export var run_sound: AudioStream
@export var attack_sound: AudioStream
@export var kick_sound: AudioStream
@export var hit_sound: AudioStream
@export var landing_sound: AudioStream

@export_range(-80.0, 6.0, 0.5)
var character_sound_volume_db := -8.0

@export_range(0.1, 2.0, 0.05)
var run_sound_interval := 0.35


@export_group("Player Life")

@export var max_life: int = 100
@export var max_coin_power := 50


@export_group("Combat")

@export var attack_hit_radius := 185.0
@export var attack_vertical_tolerance := 125.0
@export var attack_back_reach := 36.0

@export var kick_hit_radius := 82.0
@export var kick_vertical_tolerance := 70.0
@export var kick_back_reach := 12.0

@export var slash_hit_window := 0.34
@export var kick_hit_window := 0.28

@export var kick_knockback_force := Vector2(260, -55)


@export_group("Online")

@export var local_player := true
@export var network_player_id := 1
@export var team_id := 0
@export var dynamic_frames_root := ""


@onready var sprite = $AnimatedSprite2D
@onready var slide_collision = $CollisionShape2D


var attacking := false

var is_sliding := false
var dead := false

var life: int = 100
var coin_power: int = 0

var jump_audio: AudioStreamPlayer2D
var run_audio: AudioStreamPlayer2D
var attack_audio: AudioStreamPlayer2D
var kick_audio: AudioStreamPlayer2D
var hit_audio: AudioStreamPlayer2D
var landing_audio: AudioStreamPlayer2D

var run_sound_timer := 0.0
var attack_hit_timer := 0.0
var hurt_animation_timer := 0.0
var defence_power_timer := 0.0
var defence_block_flash_timer := 0.0
var network_sync_timer := 0.0

var spawn_position := Vector2.ZERO

var jumps_left := MAX_JUMPS

var remote_target_position := Vector2.ZERO
var remote_target_velocity := Vector2.ZERO
var remote_state_age := 0.0

var hit_targets := {}

var was_on_floor := false

var sprite_flip_inverted := false
var default_sprite_scale := Vector2.ONE
var runtime_texture_cache: Dictionary = {}
var menu_optimizer = null


func _ready():
	_set_player_groups(true)
	_setup_runtime_texture_optimizer()

	if name == "SecondPlayer" and not visible:
		set_online_player_active(false)

	spawn_position = global_position
	remote_target_position = global_position

	life = max_life

	life_changed.emit(life, max_life)
	power_changed.emit(coin_power, max_coin_power)

	if not _apply_selected_character():
		_load_dynamic_sprite_frames()

		sprite.position = DEFAULT_SPRITE_OFFSET

	default_sprite_scale = sprite.scale

	_remember_default_player_frames()

	sprite.animation_finished.connect(_on_animation_finished)

	jump_audio = _create_sound_player(
		"JumpSound",
		jump_sound
	)

	run_audio = _create_sound_player(
		"RunSound",
		run_sound
	)

	attack_audio = _create_sound_player(
		"AttackSound",
		attack_sound
	)

	kick_audio = _create_sound_player(
		"KickSound",
		kick_sound
	)

	hit_audio = _create_sound_player(
		"HitSound",
		hit_sound
	)

	landing_audio = _create_sound_player(
		"LandingSound",
		landing_sound
	)

	was_on_floor = is_on_floor()

	floor_max_angle = deg_to_rad(60)
	floor_snap_length = 80.0
	floor_constant_speed = true


func _physics_process(delta):

	# =====================================================
	# REMOTE PLAYER
	# =====================================================

	if not local_player:
		_update_remote_network_motion(delta)
		return


	# =====================================================
	# DEAD
	# =====================================================

	if dead:

		defence_power_timer = 0.0
		defence_block_flash_timer = 0.0
		sprite.self_modulate = Color.WHITE

		if not is_on_floor():
			velocity += get_gravity() * delta

			move_and_slide()

			_update_landing_sound()

		return


	_update_defence_power(delta)


	# =====================================================
	# GRAVITY
	# =====================================================

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_left = MAX_JUMPS


	var gameplay_input_blocked := _is_gameplay_input_blocked()


	if gameplay_input_blocked:

		attacking = false

		attack_hit_timer = 0.0

		hit_targets.clear()


	# =====================================================
	# JUMP
	# =====================================================

	if (
		not gameplay_input_blocked
		and Input.is_action_just_pressed("jump")
		and jumps_left > 0
		and not is_sliding
	):

		attacking = false

		velocity.y = JUMP_VELOCITY

		jumps_left -= 1

		_play_sound(jump_audio)


	# =====================================================
	# ATTACK
	# =====================================================

	if (
		not gameplay_input_blocked
		and Input.is_action_just_pressed("attack")
		and not attacking
	):

		_play_sound(attack_audio)

		if is_on_floor():

			if Input.is_action_pressed("run"):

				_begin_attack(
					"Run Slashing",
					slash_hit_window
				)

			else:

				_begin_attack(
					"Slashing",
					slash_hit_window
				)

		else:

			_begin_attack(
				"Slashing In Air",
				slash_hit_window
			)


	# =====================================================
	# KICK
	# =====================================================

	if (
		not gameplay_input_blocked
		and Input.is_action_just_pressed("kick")
		and not attacking
	):

		_play_sound(kick_audio)

		_begin_attack(
			"Kicking",
			kick_hit_window
		)


	# =====================================================
	# SPECIAL POWER
	# =====================================================

	if (
		not gameplay_input_blocked
		and Input.is_action_just_pressed("special_power")
	):

		_try_activate_shockwave()


	# =====================================================
	# MOVEMENT
	# =====================================================

	var direction := 0.0


	if (
		not gameplay_input_blocked
	):

		direction = Input.get_axis(
			"move_left",
			"move_right"
		)

		if is_zero_approx(direction):

			direction = Input.get_axis(
				"ui_left",
				"ui_right"
			)


	var speed := WALK_SPEED


	if (
		not gameplay_input_blocked
		and Input.is_action_pressed("run")
	):

		speed = RUN_SPEED


	_update_run_sound(
		delta,
		direction
	)


	if direction != 0:

		velocity.x = direction * speed

		face_right(
			direction > 0
		)


		# INPUT ON SLOPE
		if is_on_floor():

			var angle = abs(
				rad_to_deg(
					get_floor_angle()
				)
			)

			if angle > SLIDE_ANGLE:

				var normal = get_floor_normal()

				var downhill = Vector2(
					normal.y,
					-normal.x
				)

				if downhill.y < 0:
					downhill = -downhill

				downhill = downhill.normalized()

				velocity.y = downhill.y * SLIDE_SPEED

	else:

		velocity.x = move_toward(
			velocity.x,
			0,
			speed
		)


	# =====================================================
	# AUTOMATIC SLOPE SLIDING
	# =====================================================

	if is_on_floor():

		var angle = abs(
			rad_to_deg(
				get_floor_angle()
			)
		)

		if angle > SLIDE_ANGLE:

			is_sliding = true

			if direction == 0:

				var normal = get_floor_normal()

				var downhill = Vector2(
					normal.y,
					-normal.x
				)

				if downhill.y < 0:
					downhill = -downhill

				downhill = downhill.normalized()

				velocity = downhill * SLIDE_SPEED

		else:

			is_sliding = false

	move_and_slide()

	_update_landing_sound()

	_send_network_state(delta)

	_process_attack_hits(delta)


	# =====================================================
	# HURT
	# =====================================================

	if hurt_animation_timer > 0.0:

		hurt_animation_timer = max(
			hurt_animation_timer - delta,
			0.0
		)

		return


	# =====================================================
	# ATTACK ANIMATION LOCK
	# =====================================================

	if attacking:

		if not sprite.is_playing():

			attacking = false

		else:

			return


	# =====================================================
	# ANIMATIONS
	# =====================================================

	if not is_on_floor():

		if velocity.y < 0:

			if sprite.animation != "Jump Looping":
				_safe_play("Jump Looping")

		else:

			if sprite.animation != "Falling Down":
				_safe_play("Falling Down")


	elif is_sliding:

		if sprite.animation != "Sliding":
			_safe_play("Sliding")


	elif direction != 0:

		if (
			not gameplay_input_blocked
			and Input.is_action_pressed("run")
		):

			if sprite.animation != "Running":
				_safe_play("Running")

		else:

			if sprite.animation != "Walking":
				_safe_play("Walking")


	else:

		if sprite.animation != "Idle":
			_safe_play("Idle")


func _is_gameplay_input_blocked() -> bool:

	var focus_owner := get_viewport().gui_get_focus_owner()

	return (
		focus_owner is LineEdit
		or focus_owner is TextEdit
	)


func _on_animation_finished():

	if sprite.animation in [
		"Slashing",
		"Slashing In Air",
		"Run Slashing",
		"Kicking"
	]:

		attacking = false

		attack_hit_timer = 0.0

		hit_targets.clear()


func _begin_attack(
	animation_name: String,
	hit_window: float
) -> void:

	attacking = true

	attack_hit_timer = hit_window

	hit_targets.clear()

	_safe_play(animation_name)

	_process_attack_hits(0.0)


@warning_ignore("shadowed_variable_base_class")
func _safe_play(name: String) -> void:

	if (
		_has_animation(name)
		and (
			sprite.animation != name
			or not sprite.is_playing()
		)
	):

		sprite.play(name)


@warning_ignore("shadowed_variable_base_class")
func _has_animation(name: String) -> bool:

	if not sprite:
		return false


	var frames = null


	if sprite.has_method("get_sprite_frames"):

		frames = sprite.get_sprite_frames()

	else:

		for p in sprite.get_property_list():

			if p is Dictionary and p.has("name"):

				if (
					p["name"] == "frames"
					or p["name"] == "sprite_frames"
				):

					frames = sprite.get(
						p["name"]
					)

					break


	if (
		frames
		and frames.has_animation(name)
	):

		return true


	return false


@warning_ignore("shadowed_variable_base_class")
func _create_sound_player(
	name: String,
	stream: AudioStream
) -> AudioStreamPlayer2D:

	var player := AudioStreamPlayer2D.new()

	player.name = name

	player.stream = stream

	player.volume_db = character_sound_volume_db

	add_child(player)

	return player


func _play_sound(
	player: AudioStreamPlayer2D
) -> void:

	if (
		not player
		or not player.stream
	):

		return


	player.volume_db = character_sound_volume_db

	player.stop()

	player.play()


func _update_run_sound(
	delta: float,
	direction: float
) -> void:

	var should_play_run := (
		direction != 0
		and is_on_floor()
		and Input.is_action_pressed("run")
		and not attacking
		and not is_sliding
	)


	if not should_play_run:

		run_sound_timer = 0.0

		return


	run_sound_timer -= delta


	if run_sound_timer <= 0.0:

		_play_sound(run_audio)

		run_sound_timer = run_sound_interval


func _update_landing_sound() -> void:

	var on_floor := is_on_floor()


	if (
		on_floor
		and not was_on_floor
		and abs(velocity.y) < 1.0
	):

		_play_sound(
			landing_audio
		)


	was_on_floor = on_floor


func is_attacking_enemy() -> bool:

	return (
		attacking
		and sprite.animation in [
			"Slashing",
			"Slashing In Air",
			"Run Slashing",
			"Kicking"
		]
	)


func get_attack_damage() -> int:

	match sprite.animation:

		"Kicking":
			return 12

		"Run Slashing":
			return 35

		_:
			return 25


func get_attack_knockback() -> Vector2:

	if sprite.animation != "Kicking":
		return Vector2.ZERO


	var facing_direction := _facing_direction()


	return Vector2(
		kick_knockback_force.x * facing_direction,
		kick_knockback_force.y
	)


func set_sprite_flip_inverted(
	inverted: bool
) -> void:

	sprite_flip_inverted = inverted


func face_right(
	should_face_right: bool
) -> void:

	sprite.flip_h = not should_face_right


func _facing_direction() -> float:

	return (
		-1.0
		if sprite.flip_h
		else 1.0
	)


func take_damage(amount: int) -> void:

	if dead:
		return


	if defence_power_timer > 0.0:
		defence_block_flash_timer = 0.16
		_update_defence_power_visual()
		_send_network_state(
			0.0,
			true
		)
		return


	life = max(
		life - amount,
		0
	)


	life_changed.emit(
		life,
		max_life
	)


	_play_sound(
		hit_audio
	)


	if life <= 0:

		_die()

		return


	_play_hurt_feedback()


	_send_network_state(
		0.0,
		true
	)


func activate_defence(duration: float = 7.0) -> void:

	if dead:
		return

	defence_power_timer = max(
		defence_power_timer,
		duration
	)
	defence_block_flash_timer = 0.18
	_update_defence_power_visual()


func _update_defence_power(delta: float) -> void:

	defence_power_timer = max(
		defence_power_timer - delta,
		0.0
	)
	defence_block_flash_timer = max(
		defence_block_flash_timer - delta,
		0.0
	)
	_update_defence_power_visual()


func _update_defence_power_visual() -> void:

	if defence_power_timer <= 0.0:

		sprite.self_modulate = Color.WHITE

		return

	sprite.self_modulate = (
		Color(1.0, 1.0, 1.0, 1.0)
		if defence_block_flash_timer > 0.0
		else Color(0.70, 0.94, 1.0, 1.0)
	)


func _setup_runtime_texture_optimizer() -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if settings:
		if not settings.has_meta(MENU_TEXTURE_CACHE_META):
			settings.set_meta(MENU_TEXTURE_CACHE_META, {})

		var cached_value = settings.get_meta(MENU_TEXTURE_CACHE_META)
		if cached_value is Dictionary:
			runtime_texture_cache = cached_value
		else:
			runtime_texture_cache = {}
			settings.set_meta(MENU_TEXTURE_CACHE_META, runtime_texture_cache)

	if ClassDB.class_exists("MenuOptimizer"):
		menu_optimizer = MenuOptimizer.new()
		menu_optimizer.set_texture_cache(runtime_texture_cache)


func _load_runtime_sprite_texture(texture_path: String) -> Texture2D:
	if not ResourceLoader.exists(texture_path):
		return null

	if menu_optimizer and menu_optimizer.has_method("load_runtime_texture"):
		var optimized: Texture2D = menu_optimizer.load_runtime_texture(texture_path)
		if optimized:
			return optimized

	return load(texture_path) as Texture2D


func heal(amount: int) -> int:

	if dead:
		return 0


	var previous_life := life


	life = min(
		life + amount,
		max_life
	)


	var healed := (
		life - previous_life
	)


	if healed <= 0:
		return 0


	life_changed.emit(
		life,
		max_life
	)


	modulate = Color(
		0.65,
		1.0,
		0.65
	)


	get_tree().create_timer(
		0.16
	).timeout.connect(
		func():

			if not dead:

				modulate = Color.WHITE
	)


	_send_network_state(
		0.0,
		true
	)


	return healed


func collect_coin_power(
	amount: int
) -> void:

	if dead:
		return


	var settings := get_node_or_null(
		"/root/GameSettings"
	)


	if (
		settings
		and settings.has_method(
			"add_saved_coins"
		)
	):

		settings.call(
			"add_saved_coins",
			amount
		)


	coin_power = min(
		coin_power + amount,
		max_coin_power
	)


	power_changed.emit(
		coin_power,
		max_coin_power
	)


func get_max_coin_power() -> int:

	return max_coin_power


func _try_activate_shockwave() -> void:

	if (
		dead
		or not local_player
	):

		return


	if coin_power < max_coin_power:
		return


	if not is_on_floor():
		return


	coin_power = 0


	power_changed.emit(
		coin_power,
		max_coin_power
	)


	_play_shockwave_visual()

	_damage_shockwave_targets()

	_send_network_state(
		0.0,
		true
	)


func _play_shockwave_visual() -> void:

	var shockwave := Node2D.new()

	shockwave.name = "GolemShockwave"

	shockwave.global_position = (
		global_position
		+ Vector2(
			0.0,
			28.0
		)
	)

	shockwave.z_index = 60


	get_tree().current_scene.add_child(
		shockwave
	)


	for index in 8:

		var burst := Sprite2D.new()

		burst.texture = _blue_power_impact_texture(
			index
		)

		burst.centered = true

		burst.position = Vector2(
			34.0 + index * 24.0,
			0.0
		)

		burst.scale = Vector2(
			2.6,
			2.6
		)

		burst.modulate = Color(
			0.65,
			0.96,
			1.0,
			0.28
		)


		shockwave.add_child(
			burst
		)


		var mirror_burst := (
			burst.duplicate()
			as Sprite2D
		)


		mirror_burst.position.x = (
			-burst.position.x
		)


		shockwave.add_child(
			mirror_burst
		)


		var burst_tween := create_tween()

		burst_tween.set_parallel(
			true
		)


		burst_tween.tween_property(
			burst,
			"position:y",
			-18.0,
			0.36
		)


		burst_tween.tween_property(
			burst,
			"scale",
			Vector2(
				3.6,
				3.6
			),
			0.36
		)


		burst_tween.tween_property(
			burst,
			"modulate:a",
			0.0,
			0.36
		)


		burst_tween.tween_property(
			mirror_burst,
			"position:y",
			-18.0,
			0.36
		)


		burst_tween.tween_property(
			mirror_burst,
			"scale",
			Vector2(
				3.6,
				3.6
			),
			0.36
		)


		burst_tween.tween_property(
			mirror_burst,
			"modulate:a",
			0.0,
			0.36
		)


	var cleanup := create_tween()

	cleanup.tween_interval(
		0.5
	)

	cleanup.tween_callback(
		shockwave.queue_free
	)


func _blue_power_impact_texture(
	index: int
) -> AtlasTexture:

	var atlas := AtlasTexture.new()


	atlas.atlas = load(
		"res://Sprites/Powers/Impact/blue_impact_32x32_sheet.png"
	) as Texture2D


	atlas.region = Rect2(
		(index % 8) * 32,
		0,
		32,
		32
	)


	return atlas


func _damage_shockwave_targets() -> void:

	var origin := get_hit_position()


	for enemy in get_tree().get_nodes_in_group(
		"Enemy"
	):

		if not enemy is Node2D:
			continue


		if enemy.get("dead") == true:
			continue


		var enemy_position: Vector2 = (
			enemy.global_position
		)


		if enemy.has_method(
			"get_hit_position"
		):

			enemy_position = enemy.get_hit_position()


		var offset := (
			enemy_position
			- origin
		)


		if abs(offset.x) > SHOCKWAVE_RADIUS:
			continue


		if (
			abs(offset.y)
			> SHOCKWAVE_VERTICAL_TOLERANCE
		):

			continue


		if enemy.has_method(
			"take_damage"
		):

			enemy.call(
				"take_damage",
				SHOCKWAVE_DAMAGE
			)


		if (
			enemy.has_method(
				"apply_knockback"
			)
			and not is_zero_approx(
				offset.x
			)
		):

			enemy.call(
				"apply_knockback",
				Vector2(
					sign(offset.x)
					* SHOCKWAVE_KNOCKBACK.x,
					SHOCKWAVE_KNOCKBACK.y
				)
			)


@rpc("any_peer", "reliable")
func network_take_damage(
	amount: int
) -> void:

	if not local_player:
		return


	# This calls take_damage(), therefore
	# defence also works with network damage.
	take_damage(amount)


func get_hit_position() -> Vector2:

	return sprite.global_position


func configure_online_player(
	player_id: int,
	controlled_locally: bool,
	assigned_team_id: int = 0
) -> void:

	network_player_id = player_id

	local_player = controlled_locally
	team_id = assigned_team_id
	_update_team_marker()

	spawn_position = global_position

	remote_target_position = global_position

	remote_target_velocity = Vector2.ZERO

	remote_state_age = 0.0


	set_multiplayer_authority(
		player_id
	)


	_set_player_groups(true)


	var camera := get_node_or_null(
		"Camera2D"
	) as Camera2D


	if camera:

		camera.position = Vector2.ZERO

		camera.ignore_rotation = true

		camera.enabled = controlled_locally


		camera.zoom = (
			Vector2(
				0.82,
				0.82
			)
			if _has_network_peer()
			else Vector2.ONE
		)


func _update_team_marker() -> void:
	var marker := get_node_or_null("TeamMarker") as Label
	if team_id <= 0:
		if marker:
			marker.visible = false
		return
	if not marker:
		marker = Label.new()
		marker.name = "TeamMarker"
		marker.position = Vector2(-42, -112)
		marker.size = Vector2(84, 24)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 14)
		marker.add_theme_color_override("font_shadow_color", Color.BLACK)
		marker.add_theme_constant_override("shadow_offset_x", 1)
		marker.add_theme_constant_override("shadow_offset_y", 1)
		marker.z_index = 20
		add_child(marker)
	marker.text = "TEAM %d" % team_id
	marker.add_theme_color_override(
		"font_color",
		Color(0.30, 0.80, 1.0) if team_id == 1 else Color(1.0, 0.32, 0.28)
	)
	marker.visible = true


func set_online_player_active(
	active: bool
) -> void:

	visible = active

	set_physics_process(
		active
	)

	_set_player_groups(
		active
	)


	var collision := get_node_or_null(
		"CollisionShape2D"
	) as CollisionShape2D


	if collision:

		collision.disabled = not active


	var camera := get_node_or_null(
		"Camera2D"
	) as Camera2D


	if (
		camera
		and not active
	):

		camera.enabled = false


func _set_player_groups(
	active: bool
) -> void:

	if active:

		add_to_group(
			"Player"
		)

		add_to_group(
			"player"
		)


		if local_player:

			add_to_group(
				"LocalPlayer"
			)

		else:

			remove_from_group(
				"LocalPlayer"
			)

		return


	remove_from_group(
		"Player"
	)

	remove_from_group(
		"player"
	)

	remove_from_group(
		"LocalPlayer"
	)


func _send_network_state(
	delta: float,
	force := false
) -> void:

	if not _has_network_peer():
		return


	network_sync_timer -= delta


	if (
		network_sync_timer > 0.0
		and not force
	):

		return


	network_sync_timer = (
		NETWORK_SYNC_INTERVAL
	)


	var online_manager := get_tree().get_first_node_in_group(
		"OnlineManager"
	)


	if online_manager:

		online_manager.rpc(
			"_receive_player_network_state",
			network_player_id,
			global_position,
			velocity,
			sprite.flip_h,
			String(sprite.animation),
			life,
			dead
		)


		if force:

			online_manager.rpc(
				"_receive_forced_player_network_state",
				network_player_id,
				global_position,
				velocity,
				sprite.flip_h,
				String(sprite.animation),
				life,
				dead
			)

		return


	rpc(
		"_receive_network_state",
		global_position,
		velocity,
		sprite.flip_h,
		String(sprite.animation),
		life,
		dead
	)


	if force:

		rpc(
			"_receive_forced_network_state",
			global_position,
			velocity,
			sprite.flip_h,
			String(sprite.animation),
			life,
			dead
		)


@rpc("any_peer", "unreliable_ordered")
func _receive_network_state(
	remote_position: Vector2,
	remote_velocity: Vector2,
	remote_flip_h: bool,
	remote_animation: String,
	remote_life: int,
	remote_dead: bool = false
) -> void:

	if local_player:
		return


	var api := get_multiplayer()


	if not api:
		return


	if (
		api.get_remote_sender_id()
		!= network_player_id
	):

		return


	_apply_remote_network_state(
		remote_position,
		remote_velocity,
		remote_flip_h,
		remote_animation,
		remote_life,
		remote_dead
	)


@rpc("any_peer", "reliable")
func _receive_forced_network_state(
	remote_position: Vector2,
	remote_velocity: Vector2,
	remote_flip_h: bool,
	remote_animation: String,
	remote_life: int,
	remote_dead: bool = false
) -> void:

	if local_player:
		return


	var api := get_multiplayer()


	if not api:
		return


	if (
		api.get_remote_sender_id()
		!= network_player_id
	):

		return


	_apply_remote_network_state(
		remote_position,
		remote_velocity,
		remote_flip_h,
		remote_animation,
		remote_life,
		remote_dead
	)


func _apply_remote_network_state(
	remote_position: Vector2,
	remote_velocity: Vector2,
	remote_flip_h: bool,
	remote_animation: String,
	remote_life: int,
	remote_dead: bool
) -> void:

	if (
		dead
		and not remote_dead
		and remote_life < max_life
	):

		return


	var was_dead: bool = dead


	remote_target_position = remote_position

	remote_target_velocity = remote_velocity

	remote_state_age = 0.0

	velocity = remote_target_velocity

	sprite.flip_h = remote_flip_h

	life = remote_life

	dead = remote_dead


	if (
		dead
		and not was_dead
	):

		_record_online_round()


	life_changed.emit(
		life,
		max_life
	)


	if dead:

		velocity = Vector2.ZERO

		modulate = Color.WHITE


		if _has_animation(
			"Dying"
		):

			_safe_play(
				"Dying"
			)

		else:

			sprite.stop()

			modulate = Color(
				0.45,
				0.45,
				0.45,
				0.85
			)


	else:

		if remote_animation == "Hurt":

			_play_hurt_feedback()

		else:

			modulate = Color.WHITE

			_safe_play(
				remote_animation
			)


func _update_remote_network_motion(
	delta: float
) -> void:

	if dead:
		return


	var smoothing := (
		1.0
		- exp(
			-REMOTE_POSITION_SMOOTHING
			* delta
		)
	)


	global_position = global_position.lerp(
		remote_target_position,
		smoothing
	)


func _load_dynamic_sprite_frames() -> void:

	var packaged_frames := load(
		"res://Resources/ash_golem_sprite_frames.tres"
	) as SpriteFrames


	if packaged_frames:

		sprite.sprite_frames = packaged_frames

		sprite.play(
			"Idle"
		)

		return


	if dynamic_frames_root.is_empty():
		return


	var frames := _build_sprite_frames_from_root(
		dynamic_frames_root
	)


	if frames.has_animation(
		"Idle"
	):

		sprite.sprite_frames = frames

		sprite.play(
			"Idle"
		)


func _apply_selected_character() -> bool:

	if name != "Player":
		return false


	var settings := get_node_or_null(
		"/root/GameSettings"
	)


	if not settings:
		return false


	var selected_character := String(
		settings.get(
			"selected_character"
		)
	)
	var squad_mode := (
		String(settings.get("game_mode")) == "squad"
		or (
			get_tree().current_scene != null
			and get_tree().current_scene.scene_file_path == SQUAD_ARENA_SCENE
		)
	)
	if squad_mode:
		if selected_character == "player" or selected_character.is_empty():
			selected_character = "crusader"
		elif selected_character == "golem":
			selected_character = "wraith"
		elif selected_character not in [
			"crusader",
			"wraith",
			"minotaur",
			"ranger"
		]:
			selected_character = "crusader"

	if selected_character in ["crusader", "wraith", "minotaur", "ranger"]:
		var frames_root := (
			CRUSADER_FRAMES_ROOT
			if selected_character == "crusader"
			else WRAITH_FRAMES_ROOT
		)
		var animation_dirs: Dictionary = (
			GOLEM_ANIMATION_DIRS
			if selected_character == "crusader"
			else WRAITH_ANIMATION_DIRS
		)
		if selected_character == "minotaur":
			frames_root = MINOTAUR_FRAMES_ROOT
			animation_dirs = MINOTAUR_ANIMATION_DIRS
		elif selected_character == "ranger":
			frames_root = RANGER_FRAMES_ROOT
			animation_dirs = RANGER_ANIMATION_DIRS
		var squad_frames := SQUAD_CHARACTER_FRAMES.get(
			selected_character
		) as SpriteFrames
		if not squad_frames:
			squad_frames = _build_sprite_frames_from_root(
				frames_root,
				animation_dirs
			)
		if not squad_frames.has_animation("Idle"):
			var idle_texture := SQUAD_IDLE_TEXTURES.get(selected_character) as Texture2D
			if idle_texture:
				squad_frames.add_animation("Idle")
				squad_frames.add_frame("Idle", idle_texture)
		if squad_frames.has_animation("Idle"):
			sprite.sprite_frames = squad_frames
			sprite.position = (
				MINOTAUR_SPRITE_OFFSET
				if selected_character == "minotaur"
				else DEFAULT_SPRITE_OFFSET
			)
			sprite.scale = (
				Vector2(0.22, 0.22)
				if selected_character in ["crusader", "ranger"]
				else Vector2(0.34, 0.34)
			)
			set_sprite_flip_inverted(true)
			sprite.play("Idle")
			return true
		return false


	if selected_character == "ice_golem":

		var ice_frames := _build_sprite_frames_from_root(
			ICE_GOLEM_FRAMES_ROOT
		)


		if ice_frames.has_animation(
			"Idle"
		):

			sprite.sprite_frames = ice_frames

			sprite.position = ICE_GOLEM_SPRITE_OFFSET

			set_sprite_flip_inverted(
				true
			)

			sprite.play(
				"Idle"
			)

			_apply_stone_golem_sounds()

			return true


		return false


	if selected_character != "golem":
		return false


	var golem_frames := load(
		"res://Resources/golem_sprite_frames.tres"
	) as SpriteFrames


	if golem_frames:

		sprite.sprite_frames = golem_frames


		_add_animation_from_folder(
			sprite.sprite_frames,
			"Hurt",
			"res://Characters/Golem/PNG/PNG Sequences/Hurt",
			12.0,
			false
		)


		sprite.position = GOLEM_SPRITE_OFFSET

		set_sprite_flip_inverted(
			true
		)

		sprite.play(
			"Idle"
		)

		_apply_stone_golem_sounds()

		return true


	return false


func _build_sprite_frames_from_root(
	frames_root: String,
	animation_dirs: Dictionary = GOLEM_ANIMATION_DIRS
) -> SpriteFrames:

	var frames := SpriteFrames.new()


	for animation_name in animation_dirs:

		var folder_name: String = (
			animation_dirs[
				animation_name
			]
		)


		var folder_path := "%s/%s" % [
			frames_root,
			folder_name
		]


		var image_files := _get_png_files(
			folder_path
		)


		if image_files.is_empty():
			continue


		frames.add_animation(
			animation_name
		)


		frames.set_animation_speed(
			animation_name,
			12.0
		)


		frames.set_animation_loop(
			animation_name,
			animation_name in [
				"Idle",
				"Walking",
				"Running",
				"Jump Looping",
				"Falling Down"
			]
		)


		for file_name in image_files:

			var texture := load(
				"%s/%s"
				% [
					folder_path,
					file_name
				]
			) as Texture2D


			if texture:

				frames.add_frame(
					animation_name,
					texture
				)


	return frames


func _apply_stone_golem_sounds() -> void:

	jump_sound = _load_audio(
		"res://Resources/character_voices/30_Jump_03.wav",
		jump_sound
	)


	attack_sound = _load_audio(
		"res://Resources/character_voices/56_Attack_03.wav",
		attack_sound
	)


	kick_sound = _load_audio(
		"res://Resources/character_voices/61_Hit_03.wav",
		kick_sound
	)


	hit_sound = _load_audio(
		"res://Resources/character_voices/61_Hit_03.wav",
		hit_sound
	)


	landing_sound = _load_audio(
		"res://Resources/character_voices/45_Landing_01.wav",
		landing_sound
	)


	character_sound_volume_db = -2.0


	_update_sound_players()


func _update_sound_players() -> void:

	if jump_audio:

		jump_audio.stream = jump_sound

		jump_audio.volume_db = character_sound_volume_db


	if attack_audio:

		attack_audio.stream = attack_sound

		attack_audio.volume_db = character_sound_volume_db


	if kick_audio:

		kick_audio.stream = kick_sound

		kick_audio.volume_db = character_sound_volume_db


	if hit_audio:

		hit_audio.stream = hit_sound

		hit_audio.volume_db = character_sound_volume_db


	if landing_audio:

		landing_audio.stream = landing_sound

		landing_audio.volume_db = character_sound_volume_db


func _load_audio(
	path: String,
	fallback: AudioStream
) -> AudioStream:

	var stream := load(
		path
	) as AudioStream


	return (
		stream
		if stream
		else fallback
	)


func _remember_default_player_frames() -> void:

	if name != "Player":
		return


	var settings := get_node_or_null(
		"/root/GameSettings"
	)


	if (
		settings
		and settings.get(
			"player_sprite_frames"
		) == null
	):

		settings.set(
			"player_sprite_frames",
			sprite.sprite_frames
		)


func _play_hurt_feedback() -> void:

	attacking = false

	is_sliding = false

	attack_hit_timer = 0.0

	hit_targets.clear()


	hurt_animation_timer = (
		HURT_ANIMATION_TIME
	)


	if _has_animation(
		"Hurt"
	):

		_safe_play(
			"Hurt"
		)


	modulate = Color(
		1.0,
		0.45,
		0.45
	)


	_clear_hurt_flash_later()


func _clear_hurt_flash_later() -> void:

	await get_tree().create_timer(
		0.14
	).timeout


	if not dead:

		modulate = Color.WHITE


func _add_animation_from_folder(
	frames: SpriteFrames,
	animation_name: String,
	folder_path: String,
	speed: float,
	loop: bool
) -> void:

	if (
		not frames
		or frames.has_animation(
			animation_name
		)
	):

		return


	var image_files := _get_png_files(
		folder_path
	)


	if image_files.is_empty():
		return


	frames.add_animation(
		animation_name
	)


	frames.set_animation_speed(
		animation_name,
		speed
	)


	frames.set_animation_loop(
		animation_name,
		loop
	)


	for file_name in image_files:

		var texture := load(
			"%s/%s"
			% [
				folder_path,
				file_name
			]
		) as Texture2D


		if texture:

			frames.add_frame(
				animation_name,
				texture
			)


func _get_png_files(
	folder_path: String
) -> Array[String]:

	var files: Array[String] = []


	var dir := DirAccess.open(
		folder_path
	)


	if not dir:
		return files


	dir.list_dir_begin()


	var file_name := dir.get_next()


	while not file_name.is_empty():

		if (
			not dir.current_is_dir()
			and file_name.get_extension().to_lower() == "png"
		):

			files.append(
				file_name
			)


		file_name = dir.get_next()


	dir.list_dir_end()

	files.sort()

	return files


func _damage_nearby_enemies() -> void:

	var damage := get_attack_damage()

	var knockback := get_attack_knockback()

	var hit_origin: Vector2 = sprite.global_position

	var facing_direction := _facing_direction()


	for enemy in get_tree().get_nodes_in_group(
		"Enemy"
	):

		if not enemy is Node2D:
			continue


		var enemy_position: Vector2 = (
			enemy.global_position
		)


		if enemy.has_method(
			"get_hit_position"
		):

			enemy_position = (
				enemy.get_hit_position()
			)


		if not _is_valid_hit(
			hit_origin,
			enemy_position,
			facing_direction
		):

			continue


		if _try_damage_target(
			enemy,
			damage,
			knockback
		):

			_play_sound(
				hit_audio
			)


func _damage_nearby_players() -> void:

	var damage := get_attack_damage()

	var hit_origin: Vector2 = sprite.global_position

	var facing_direction := _facing_direction()


	for other_player in get_tree().get_nodes_in_group(
		"Player"
	):

		if other_player == self:
			continue


		if not other_player is Node2D:
			continue


		if (
			other_player is CanvasItem
			and not other_player.visible
		):

			continue


		if other_player.get("dead") == true:
			continue

		if (
			team_id > 0
			and int(other_player.get("team_id")) == team_id
		):
			continue


		var other_position: Vector2 = (
			other_player.global_position
		)


		if other_player.has_method(
			"get_hit_position"
		):

			other_position = (
				other_player.get_hit_position()
			)


		if not _is_valid_hit(
			hit_origin,
			other_position,
			facing_direction
		):

			continue


		if _try_damage_target(
			other_player,
			damage
		):

			_play_sound(
				hit_audio
			)


func _process_attack_hits(
	delta: float
) -> void:

	if not attacking:
		return


	if attack_hit_timer <= 0.0:
		return


	_damage_nearby_enemies()

	_damage_nearby_players()


	attack_hit_timer = max(
		attack_hit_timer - delta,
		0.0
	)


func _try_damage_target(
	target: Node,
	damage: int,
	knockback := Vector2.ZERO
) -> bool:

	if hit_targets.has(
		target.get_instance_id()
	):

		return false


	var dealt_damage := false


	var raw_target_peer_id = target.get(
		"network_player_id"
	)


	var target_peer_id := 0


	if raw_target_peer_id != null:

		target_peer_id = int(
			raw_target_peer_id
		)


	var api := get_multiplayer()


	if (
		api
		and api.has_multiplayer_peer()
		and target_peer_id > 0
		and target_peer_id != api.get_unique_id()
	):

		var online_manager := get_tree().get_first_node_in_group(
			"OnlineManager"
		)


		if online_manager:

			online_manager.rpc_id(
				target_peer_id,
				"_receive_player_damage",
				damage
			)

			dealt_damage = true


		elif target.has_method(
			"network_take_damage"
		):

			target.rpc_id(
				target_peer_id,
				"network_take_damage",
				damage
			)

			dealt_damage = true


	elif target.has_method(
		"take_damage"
	):

		if (
			knockback != Vector2.ZERO
			and target.has_method(
				"take_kick"
			)
		):

			target.take_kick(
				damage,
				knockback
			)

		else:

			target.take_damage(
				damage
			)


			if (
				knockback != Vector2.ZERO
				and target.has_method(
					"apply_knockback"
				)
			):

				target.apply_knockback(
					knockback
				)


		dealt_damage = true


	if dealt_damage:

		hit_targets[
			target.get_instance_id()
		] = true


	return dealt_damage


func _is_valid_hit(
	hit_origin: Vector2,
	target_position: Vector2,
	facing_direction: float
) -> bool:

	var hit_offset := (
		target_position
		- hit_origin
	)


	var reach := attack_hit_radius

	var vertical_tolerance := (
		attack_vertical_tolerance
	)

	var back_reach := (
		attack_back_reach
	)


	if sprite.animation == "Kicking":

		reach = kick_hit_radius

		vertical_tolerance = (
			kick_vertical_tolerance
		)

		back_reach = (
			kick_back_reach
		)


	if (
		abs(hit_offset.y)
		> vertical_tolerance
	):

		return false


	if (
		hit_offset.x * facing_direction
		< -back_reach
	):

		return false


	if (
		hit_offset.x * facing_direction
		> reach
	):

		return false


	return true


func _die() -> void:

	_record_online_round()


	dead = true

	attacking = false

	defence_power_timer = 0.0
	defence_block_flash_timer = 0.0

	is_sliding = false

	velocity.x = 0.0

	modulate = Color.WHITE
	sprite.self_modulate = Color.WHITE


	if _has_animation(
		"Dying"
	):

		sprite.play(
			"Dying"
		)

	else:

		sprite.stop()

		modulate = Color(
			0.45,
			0.45,
			0.45,
			0.85
		)


	_send_network_state(
		0.0,
		true
	)


	await get_tree().create_timer(
		1.2
	).timeout


	var api := get_multiplayer()


	if (
		api
		and api.has_multiplayer_peer()
	):

		if _is_online_match_over():

			velocity = Vector2.ZERO

			set_physics_process(
				false
			)

			return


		_respawn_for_online_match()


	else:

		var settings := get_node_or_null(
			"/root/GameSettings"
		)


		if (
			settings
			and int(
				settings.get(
					"offline_tries_left"
				)
			) <= 0
		):

			velocity = Vector2.ZERO

			set_physics_process(
				false
			)

			return


		get_tree().reload_current_scene()


func _respawn_for_online_match() -> void:

	dead = false

	attacking = false

	defence_power_timer = 0.0
	defence_block_flash_timer = 0.0

	is_sliding = false

	velocity = Vector2.ZERO

	jumps_left = MAX_JUMPS

	life = max_life

	modulate = Color.WHITE
	sprite.self_modulate = Color.WHITE

	global_position = spawn_position

	network_sync_timer = 0.0


	life_changed.emit(
		life,
		max_life
	)


	_safe_play(
		"Idle"
	)


	_send_network_state(
		1.0,
		true
	)


func respawn() -> void:

	_respawn_for_online_match()


func _has_network_peer() -> bool:

	var api := get_multiplayer()


	return (
		api
		and api.has_multiplayer_peer()
	)


func _record_online_round() -> void:

	if not _has_network_peer():
		return


	var settings := get_node_or_null(
		"/root/GameSettings"
	)

	if settings and String(settings.get("game_mode")) == "squad":
		if not local_player:
			return
		var online_manager := get_tree().get_first_node_in_group("OnlineManager")
		if online_manager and online_manager.has_method("report_squad_defeat"):
			online_manager.call("report_squad_defeat", network_player_id, team_id)
		return


	if (
		settings
		and settings.has_method(
			"record_online_round"
		)
	):

		settings.record_online_round(
			_online_round_winner_name()
		)


func _is_online_match_over() -> bool:

	var settings := get_node_or_null(
		"/root/GameSettings"
	)


	if (
		settings
		and settings.has_method(
			"is_online_match_over"
		)
	):

		return settings.is_online_match_over()


	return false


func _online_round_winner_name() -> String:

	return (
		"Golem 2"
		if network_player_id == 1
		else "Golem 1"
	)
