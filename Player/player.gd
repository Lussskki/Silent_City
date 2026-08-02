extends CharacterBody2D

const WALK_SPEED = 250.0
const RUN_SPEED = 450.0
const JUMP_VELOCITY = -600.0
const MAX_JUMPS = 2
const SLIDE_SPEED = 400.0
const SLIDE_ANGLE = 15.0
const NETWORK_SYNC_INTERVAL = 0.033
const REMOTE_POSITION_SMOOTHING = 14.0
const REMOTE_EXTRAPOLATION_LIMIT = 0.12
const DEFAULT_SPRITE_OFFSET := Vector2(0, -24)
const GOLEM_SPRITE_OFFSET := Vector2(0, -24)
const HURT_ANIMATION_TIME := 0.28


signal life_changed(life: int, max_life: int)

@export_group("Character Sounds")
@export var jump_sound: AudioStream
@export var run_sound: AudioStream
@export var attack_sound: AudioStream
@export var kick_sound: AudioStream
@export var hit_sound: AudioStream
@export var landing_sound: AudioStream
@export_range(-80.0, 6.0, 0.5) var character_sound_volume_db := -8.0
@export_range(0.1, 2.0, 0.05) var run_sound_interval := 0.35
@export_group("Player Life")
@export var max_life: int = 100
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
@export var dynamic_frames_root := ""

@onready var sprite = $AnimatedSprite2D
@onready var slide_collision = $CollisionShape2D

var attacking = false
var is_sliding = false
var dead = false
var life: int = 100
var jump_audio: AudioStreamPlayer2D
var run_audio: AudioStreamPlayer2D
var attack_audio: AudioStreamPlayer2D
var kick_audio: AudioStreamPlayer2D
var hit_audio: AudioStreamPlayer2D
var landing_audio: AudioStreamPlayer2D
var run_sound_timer := 0.0
var attack_hit_timer := 0.0
var hurt_animation_timer := 0.0
var network_sync_timer := 0.0
var spawn_position := Vector2.ZERO
var jumps_left := MAX_JUMPS
var remote_target_position := Vector2.ZERO
var remote_target_velocity := Vector2.ZERO
var remote_state_age := 0.0
var hit_targets := {}
var was_on_floor := false

func _ready():
	_set_player_groups(true)
	if name == "SecondPlayer" and not visible:
		set_online_player_active(false)
	spawn_position = global_position
	remote_target_position = global_position
	life = max_life
	life_changed.emit(life, max_life)
	if not _apply_selected_character():
		_load_dynamic_sprite_frames()
		sprite.position = DEFAULT_SPRITE_OFFSET
	_remember_default_player_frames()
	sprite.animation_finished.connect(_on_animation_finished)
	jump_audio = _create_sound_player("JumpSound", jump_sound)
	run_audio = _create_sound_player("RunSound", run_sound)
	attack_audio = _create_sound_player("AttackSound", attack_sound)
	kick_audio = _create_sound_player("KickSound", kick_sound)
	hit_audio = _create_sound_player("HitSound", hit_sound)
	landing_audio = _create_sound_player("LandingSound", landing_sound)
	was_on_floor = is_on_floor()

	# áƒ¢áƒáƒ˜áƒšáƒ”áƒ‘áƒ˜áƒ¡ áƒ¤áƒ”áƒ áƒ“áƒáƒ‘áƒ˜ áƒ™áƒ˜áƒ‘áƒ”áƒ¡áƒáƒ•áƒ˜áƒ— áƒ™áƒ•áƒáƒ“áƒ áƒáƒ¢áƒ”áƒ‘áƒ˜áƒ¡áƒ’áƒáƒœ áƒ¨áƒ”áƒ“áƒ’áƒ”áƒ‘áƒ (~51Â°).
	# áƒáƒ› áƒžáƒáƒ áƒáƒ›áƒ”áƒ¢áƒ áƒ”áƒ‘áƒ˜áƒ— áƒžáƒ”áƒ áƒ¡áƒáƒœáƒáƒŸáƒ˜ áƒ™áƒ˜áƒ‘áƒ”áƒ¡ áƒ’áƒšáƒ£áƒ• áƒ¤áƒ”áƒ áƒ“áƒáƒ‘áƒáƒ“ áƒáƒ¦áƒ˜áƒ¥áƒ•áƒáƒ›áƒ¡ áƒ“áƒ
	# áƒ¡áƒáƒ¤áƒ”áƒ®áƒ£áƒ áƒ”áƒ‘áƒ–áƒ” áƒáƒ¦áƒáƒ  áƒáƒ®áƒ¢áƒ”áƒ‘áƒ áƒ–áƒ”áƒ›áƒáƒ—-áƒ¥áƒ•áƒ”áƒ›áƒáƒ—.
	floor_max_angle = deg_to_rad(60)   # áƒªáƒ˜áƒªáƒáƒ‘áƒ áƒ™áƒ˜áƒ‘áƒ” â€žáƒ˜áƒáƒ¢áƒáƒ™áƒáƒ“" áƒ©áƒáƒ˜áƒ—áƒ•áƒáƒšáƒáƒ¡
	floor_snap_length = 80.0            # áƒ¡áƒáƒ¤áƒ”áƒ®áƒ£áƒ áƒ”áƒ‘áƒ–áƒ” áƒ›áƒ˜áƒ¬áƒ”áƒ‘áƒ”áƒ‘áƒ, áƒ°áƒáƒ”áƒ áƒ¨áƒ˜ áƒáƒ¦áƒáƒ  áƒáƒ®áƒ¢áƒ”áƒ¡
	floor_constant_speed = true         # áƒ¤áƒ”áƒ áƒ“áƒáƒ‘áƒ–áƒ” áƒ¡áƒ˜áƒ©áƒ¥áƒáƒ áƒ” áƒ›áƒ£áƒ“áƒ›áƒ˜áƒ•áƒ˜ áƒ“áƒáƒ áƒ©áƒ”áƒ¡

func _physics_process(delta):
	if not local_player:
		_update_remote_network_motion(delta)
		return

	if dead:
		if not is_on_floor():
			velocity += get_gravity() * delta
			move_and_slide()
			_update_landing_sound()
		return

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_left = MAX_JUMPS

	# Jump
	if Input.is_action_just_pressed("ui_accept") and jumps_left > 0 and not is_sliding:
		attacking = false
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1
		_play_sound(jump_audio)

	# Attack
	if Input.is_action_just_pressed("attack") and not attacking:
		_play_sound(attack_audio)
		if is_on_floor():
			if Input.is_action_pressed("run"):
				_begin_attack("Run Slashing", slash_hit_window)
			else:
				_begin_attack("Slashing", slash_hit_window)
		else:
			_begin_attack("Slashing In Air", slash_hit_window)

	# Kick
	if Input.is_action_just_pressed("kick") and not attacking:
		_play_sound(kick_audio)
		_begin_attack("Kicking", kick_hit_window)

	# Movement
	var direction := Input.get_axis("move_left", "move_right")
	if is_zero_approx(direction):
		direction = Input.get_axis("ui_left", "ui_right")
	var speed := WALK_SPEED

	if Input.is_action_pressed("run"):
		speed = RUN_SPEED

	_update_run_sound(delta, direction)

	if direction != 0:
		velocity.x = direction * speed
		sprite.flip_h = direction < 0

		# áƒ“áƒáƒ®áƒ áƒ˜áƒš áƒáƒ“áƒ’áƒ˜áƒšáƒ–áƒ” INPUT - Y áƒ£áƒœáƒ“áƒ áƒ˜áƒ§áƒáƒ¡ downhill áƒ›áƒ˜áƒ›áƒáƒ áƒ—áƒ£áƒšáƒ”áƒ‘áƒ
		if is_on_floor():
			var angle = abs(rad_to_deg(get_floor_angle()))
			if angle > SLIDE_ANGLE:
				var normal = get_floor_normal()
				var downhill = Vector2(normal.y, -normal.x)
				if downhill.y < 0:
					downhill = -downhill
				downhill = downhill.normalized()
				velocity.y = downhill.y * SLIDE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

# Automatic slope sliding


	if is_on_floor():
		var angle = abs(rad_to_deg(get_floor_angle()))

		if angle > SLIDE_ANGLE:
			is_sliding = true

			# áƒ—áƒ£ INPUT áƒáƒ  áƒáƒ áƒ˜áƒ¡, downhill-áƒ˜áƒ— áƒ¡áƒ áƒ˜áƒáƒšáƒ˜
			if direction == 0:
				var normal = get_floor_normal()
				var downhill = Vector2(normal.y, -normal.x)
				if downhill.y < 0:
					downhill = -downhill
				downhill = downhill.normalized()
				velocity = downhill * SLIDE_SPEED
			# áƒ—áƒ£ INPUT áƒáƒ áƒ˜áƒ¡, INPUT-áƒ˜áƒ— áƒ¡áƒ áƒ˜áƒáƒšáƒ˜
		else:
			is_sliding = false

	move_and_slide()
	_update_landing_sound()
	_send_network_state(delta)
	_process_attack_hits(delta)

	if hurt_animation_timer > 0.0:
		hurt_animation_timer = max(hurt_animation_timer - delta, 0.0)
		return
	
	

	# Stop movement while attacking
	if attacking:
		if not sprite.is_playing():
			attacking = false
		else:
			return

	# Animations
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
		if Input.is_action_pressed("run"):
			if sprite.animation != "Running":
				_safe_play("Running")
		else:
			if sprite.animation != "Walking":
				_safe_play("Walking")

	else:
		if sprite.animation != "Idle":
			_safe_play("Idle")


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


func _begin_attack(animation_name: String, hit_window: float) -> void:
	attacking = true
	attack_hit_timer = hit_window
	hit_targets.clear()
	_safe_play(animation_name)
	_process_attack_hits(0.0)


@warning_ignore("shadowed_variable_base_class")
func _safe_play(name: String) -> void:
	if _has_animation(name) and (sprite.animation != name or not sprite.is_playing()):
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
				if p["name"] == "frames" or p["name"] == "sprite_frames":
					frames = sprite.get(p["name"])
					break

	if frames and frames.has_animation(name):
		return true

	return false


@warning_ignore("shadowed_variable_base_class")
func _create_sound_player(name: String, stream: AudioStream) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.name = name
	player.stream = stream
	player.volume_db = character_sound_volume_db
	add_child(player)
	return player


func _play_sound(player: AudioStreamPlayer2D) -> void:
	if not player or not player.stream:
		return

	player.volume_db = character_sound_volume_db
	player.stop()
	player.play()


func _update_run_sound(delta: float, direction: float) -> void:
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
	if on_floor and not was_on_floor and abs(velocity.y) < 1.0:
		_play_sound(landing_audio)
	was_on_floor = on_floor


func is_attacking_enemy() -> bool:
	return attacking and sprite.animation in [
		"Slashing",
		"Slashing In Air",
		"Run Slashing",
		"Kicking"
	]


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

	var facing_direction := -1.0 if sprite.flip_h else 1.0
	return Vector2(kick_knockback_force.x * facing_direction, kick_knockback_force.y)


func take_damage(amount: int) -> void:
	if dead:
		return

	life = max(life - amount, 0)
	life_changed.emit(life, max_life)
	_play_sound(hit_audio)
	if life <= 0:
		_die()
		return

	_play_hurt_feedback()
	_send_network_state(0.0, true)


func heal(amount: int) -> int:
	if dead:
		return 0

	var previous_life := life
	life = min(life + amount, max_life)
	var healed := life - previous_life
	if healed <= 0:
		return 0

	life_changed.emit(life, max_life)
	modulate = Color(0.65, 1.0, 0.65)
	get_tree().create_timer(0.16).timeout.connect(func():
		if not dead:
			modulate = Color.WHITE
	)
	_send_network_state(0.0, true)
	return healed


@rpc("any_peer", "reliable")
func network_take_damage(amount: int) -> void:
	if not local_player:
		return
	take_damage(amount)


func get_hit_position() -> Vector2:
	return sprite.global_position



 

func configure_online_player(player_id: int, controlled_locally: bool) -> void:
	network_player_id = player_id
	local_player = controlled_locally
	spawn_position = global_position
	remote_target_position = global_position
	remote_target_velocity = Vector2.ZERO
	remote_state_age = 0.0
	set_multiplayer_authority(player_id)

	_set_player_groups(true)

	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.position = Vector2.ZERO
		camera.ignore_rotation = true
		camera.enabled = controlled_locally
		camera.zoom = Vector2(0.82, 0.82) if _has_network_peer() else Vector2.ONE


func set_online_player_active(active: bool) -> void:
	visible = active
	set_physics_process(active)
	_set_player_groups(active)

	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision:
		collision.disabled = not active

	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera and not active:
		camera.enabled = false


func _set_player_groups(active: bool) -> void:
	if active:
		add_to_group("Player")
		add_to_group("player")
		if local_player:
			add_to_group("LocalPlayer")
		else:
			remove_from_group("LocalPlayer")
		return

	remove_from_group("Player")
	remove_from_group("player")
	remove_from_group("LocalPlayer")


func _send_network_state(delta: float, force := false) -> void:
	if not _has_network_peer():
		return

	network_sync_timer -= delta
	if network_sync_timer > 0.0 and not force:
		return

	network_sync_timer = NETWORK_SYNC_INTERVAL
	rpc("_receive_network_state", global_position, velocity, sprite.flip_h, String(sprite.animation), life, dead)
	if force:
		rpc("_receive_forced_network_state", global_position, velocity, sprite.flip_h, String(sprite.animation), life, dead)


@rpc("any_peer", "unreliable_ordered")
func _receive_network_state(remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_animation: String, remote_life: int, remote_dead: bool = false) -> void:
	if local_player:
		return

	var api := get_multiplayer()
	if not api:
		return
	if api.get_remote_sender_id() != network_player_id:
		return

	_apply_remote_network_state(remote_position, remote_velocity, remote_flip_h, remote_animation, remote_life, remote_dead)


@rpc("any_peer", "reliable")
func _receive_forced_network_state(remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_animation: String, remote_life: int, remote_dead: bool = false) -> void:
	if local_player:
		return

	var api := get_multiplayer()
	if not api:
		return
	if api.get_remote_sender_id() != network_player_id:
		return

	_apply_remote_network_state(remote_position, remote_velocity, remote_flip_h, remote_animation, remote_life, remote_dead)


func _apply_remote_network_state(remote_position: Vector2, remote_velocity: Vector2, remote_flip_h: bool, remote_animation: String, remote_life: int, remote_dead: bool) -> void:
	if dead and not remote_dead and remote_life < max_life:
		return

	var was_dead: bool = dead
	remote_target_position = remote_position
	remote_target_velocity = remote_velocity
	remote_state_age = 0.0
	velocity = remote_target_velocity
	sprite.flip_h = remote_flip_h
	life = remote_life
	dead = remote_dead
	if dead and not was_dead:
		_record_online_round()
	life_changed.emit(life, max_life)
	if dead:
		velocity = Vector2.ZERO
		modulate = Color.WHITE
		if _has_animation("Dying"):
			_safe_play("Dying")
		else:
			sprite.stop()
			modulate = Color(0.45, 0.45, 0.45, 0.85)
	else:
		if remote_animation == "Hurt":
			_play_hurt_feedback()
		else:
			modulate = Color.WHITE
			_safe_play(remote_animation)


func _update_remote_network_motion(delta: float) -> void:
	if dead:
		return

	remote_state_age = min(remote_state_age + delta, REMOTE_EXTRAPOLATION_LIMIT)
	var predicted_position := remote_target_position + remote_target_velocity * remote_state_age
	var smoothing := 1.0 - exp(-REMOTE_POSITION_SMOOTHING * delta)
	global_position = global_position.lerp(predicted_position, smoothing)


func _load_dynamic_sprite_frames() -> void:
	var packaged_frames := load("res://Resources/ash_golem_sprite_frames.tres") as SpriteFrames
	if packaged_frames:
		sprite.sprite_frames = packaged_frames
		sprite.play("Idle")
		return

	if dynamic_frames_root.is_empty():
		return

	var frames := SpriteFrames.new()
	var animation_dirs := {
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

	for animation_name in animation_dirs:
		var folder_name: String = animation_dirs[animation_name]
		var folder_path := "%s/%s" % [dynamic_frames_root, folder_name]
		var image_files := _get_png_files(folder_path)
		if image_files.is_empty():
			continue

		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 12.0)
		frames.set_animation_loop(animation_name, animation_name in ["Idle", "Walking", "Running", "Jump Looping", "Falling Down"])

		for file_name in image_files:
			var texture := load("%s/%s" % [folder_path, file_name]) as Texture2D
			if texture:
				frames.add_frame(animation_name, texture)

	if frames.has_animation("Idle"):
		sprite.sprite_frames = frames
		sprite.play("Idle")


func _apply_selected_character() -> bool:
	if name != "Player":
		return false
	var settings := get_node_or_null("/root/GameSettings")
	if not settings:
		return false
	if String(settings.get("selected_character")) != "golem":
		return false

	var golem_frames := load("res://Resources/golem_sprite_frames.tres") as SpriteFrames
	if golem_frames:
		sprite.sprite_frames = golem_frames
		_add_animation_from_folder(sprite.sprite_frames, "Hurt", "res://Characters/Golem/PNG/PNG Sequences/Hurt", 12.0, false)
		sprite.position = GOLEM_SPRITE_OFFSET
		sprite.play("Idle")
		_apply_stone_golem_sounds()
		return true
	return false


func _apply_stone_golem_sounds() -> void:
	jump_sound = _load_audio("res://Resources/character_voices/30_Jump_03.wav", jump_sound)
	attack_sound = _load_audio("res://Resources/character_voices/56_Attack_03.wav", attack_sound)
	kick_sound = _load_audio("res://Resources/character_voices/61_Hit_03.wav", kick_sound)
	hit_sound = _load_audio("res://Resources/character_voices/61_Hit_03.wav", hit_sound)
	landing_sound = _load_audio("res://Resources/character_voices/45_Landing_01.wav", landing_sound)
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


func _load_audio(path: String, fallback: AudioStream) -> AudioStream:
	var stream := load(path) as AudioStream
	return stream if stream else fallback


func _remember_default_player_frames() -> void:
	if name != "Player":
		return
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.get("player_sprite_frames") == null:
		settings.set("player_sprite_frames", sprite.sprite_frames)


func _play_hurt_feedback() -> void:
	attacking = false
	is_sliding = false
	attack_hit_timer = 0.0
	hit_targets.clear()
	hurt_animation_timer = HURT_ANIMATION_TIME
	if _has_animation("Hurt"):
		_safe_play("Hurt")
	modulate = Color(1.0, 0.45, 0.45)
	_clear_hurt_flash_later()


func _clear_hurt_flash_later() -> void:
	await get_tree().create_timer(0.14).timeout
	if not dead:
		modulate = Color.WHITE


func _add_animation_from_folder(frames: SpriteFrames, animation_name: String, folder_path: String, speed: float, loop: bool) -> void:
	if not frames or frames.has_animation(animation_name):
		return

	var image_files := _get_png_files(folder_path)
	if image_files.is_empty():
		return

	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loop)
	for file_name in image_files:
		var texture := load("%s/%s" % [folder_path, file_name]) as Texture2D
		if texture:
			frames.add_frame(animation_name, texture)


func _get_png_files(folder_path: String) -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open(folder_path)
	if not dir:
		return files

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "png":
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	files.sort()
	return files


func _damage_nearby_enemies() -> void:
	var damage := get_attack_damage()
	var knockback := get_attack_knockback()
	var hit_origin: Vector2 = sprite.global_position
	var facing_direction := -1.0 if sprite.flip_h else 1.0
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not enemy is Node2D:
			continue

		var enemy_position: Vector2 = enemy.global_position
		if enemy.has_method("get_hit_position"):
			enemy_position = enemy.get_hit_position()

		if not _is_valid_hit(hit_origin, enemy_position, facing_direction):
			continue
		if _try_damage_target(enemy, damage, knockback):
			_play_sound(hit_audio)


func _damage_nearby_players() -> void:
	var damage := get_attack_damage()
	var hit_origin: Vector2 = sprite.global_position
	var facing_direction := -1.0 if sprite.flip_h else 1.0

	for other_player in get_tree().get_nodes_in_group("Player"):
		if other_player == self:
			continue
		if not other_player is Node2D:
			continue
		if other_player is CanvasItem and not other_player.visible:
			continue
		if other_player.get("dead") == true:
			continue

		var other_position: Vector2 = other_player.global_position
		if other_player.has_method("get_hit_position"):
			other_position = other_player.get_hit_position()

		if not _is_valid_hit(hit_origin, other_position, facing_direction):
			continue

		if _try_damage_target(other_player, damage):
			_play_sound(hit_audio)


func _process_attack_hits(delta: float) -> void:
	if not attacking:
		return
	if attack_hit_timer <= 0.0:
		return

	_damage_nearby_enemies()
	_damage_nearby_players()
	attack_hit_timer = max(attack_hit_timer - delta, 0.0)


func _try_damage_target(target: Node, damage: int, knockback := Vector2.ZERO) -> bool:
	if hit_targets.has(target.get_instance_id()):
		return false

	var dealt_damage := false
	var raw_target_peer_id = target.get("network_player_id")
	var target_peer_id := 0
	if raw_target_peer_id != null:
		target_peer_id = int(raw_target_peer_id)
	var api := get_multiplayer()
	if (
		api
		and api.has_multiplayer_peer()
		and target_peer_id > 0
		and target_peer_id != api.get_unique_id()
		and target_peer_id in api.get_peers()
	):
		if knockback != Vector2.ZERO and target.has_method("network_take_kick"):
			target.rpc_id(target_peer_id, "network_take_kick", damage, knockback)
			dealt_damage = true
		elif target.has_method("network_take_damage"):
			target.rpc_id(target_peer_id, "network_take_damage", damage)
			dealt_damage = true
	elif target.has_method("take_damage"):
		if knockback != Vector2.ZERO and target.has_method("take_kick"):
			target.take_kick(damage, knockback)
		else:
			target.take_damage(damage)
			if knockback != Vector2.ZERO and target.has_method("apply_knockback"):
				target.apply_knockback(knockback)
		dealt_damage = true

	if dealt_damage:
		hit_targets[target.get_instance_id()] = true
	return dealt_damage


func _is_valid_hit(hit_origin: Vector2, target_position: Vector2, facing_direction: float) -> bool:
	var hit_offset := target_position - hit_origin
	var reach := attack_hit_radius
	var vertical_tolerance := attack_vertical_tolerance
	var back_reach := attack_back_reach

	if sprite.animation == "Kicking":
		reach = kick_hit_radius
		vertical_tolerance = kick_vertical_tolerance
		back_reach = kick_back_reach

	if abs(hit_offset.y) > vertical_tolerance:
		return false
	if hit_offset.x * facing_direction < -back_reach:
		return false
	if hit_offset.x * facing_direction > reach:
		return false
	return true




func _die() -> void:
	_record_online_round()
	dead = true
	attacking = false
	is_sliding = false
	velocity.x = 0.0
	modulate = Color.WHITE

	if _has_animation("Dying"):
		sprite.play("Dying")
	else:
		sprite.stop()
		modulate = Color(0.45, 0.45, 0.45, 0.85)
	_send_network_state(0.0, true)

	await get_tree().create_timer(1.2).timeout
	var api := get_multiplayer()
	if api and api.has_multiplayer_peer():
		if _is_online_match_over():
			velocity = Vector2.ZERO
			set_physics_process(false)
			return
		_respawn_for_online_match()
	else:
		var settings := get_node_or_null("/root/GameSettings")
		if settings and int(settings.get("offline_tries_left")) <= 0:
			velocity = Vector2.ZERO
			set_physics_process(false)
			return
		get_tree().reload_current_scene()


func _respawn_for_online_match() -> void:
	dead = false
	attacking = false
	is_sliding = false
	velocity = Vector2.ZERO
	jumps_left = MAX_JUMPS
	life = max_life
	modulate = Color.WHITE
	global_position = spawn_position
	network_sync_timer = 0.0
	life_changed.emit(life, max_life)
	_safe_play("Idle")
	_send_network_state(1.0, true)


func respawn() -> void:
	_respawn_for_online_match()


func _has_network_peer() -> bool:
	var api := get_multiplayer()
	return api and api.has_multiplayer_peer()


func _record_online_round() -> void:
	if not _has_network_peer():
		return
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("record_online_round"):
		settings.record_online_round(_online_round_winner_name())


func _is_online_match_over() -> bool:
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("is_online_match_over"):
		return settings.is_online_match_over()
	return false


func _online_round_winner_name() -> String:
	return "Golem 2" if network_player_id == 1 else "Golem 1"
