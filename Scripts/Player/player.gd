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


signal life_changed(life: int, max_life: int)

@export_group("Character Sounds")
@export var jump_sound: AudioStream
@export var run_sound: AudioStream
@export var attack_sound: AudioStream
@export var kick_sound: AudioStream
@export_range(-80.0, 6.0, 0.5) var character_sound_volume_db := -8.0
@export_range(0.1, 2.0, 0.05) var run_sound_interval := 0.35
@export_group("Player Life")
@export var max_life: int = 100
@export_group("Combat")
@export var attack_hit_radius := 130.0
@export var attack_vertical_tolerance := 95.0
@export_group("LAN")
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
var run_sound_timer := 0.0
var network_sync_timer := 0.0
var spawn_position := Vector2.ZERO
var jumps_left := MAX_JUMPS
var remote_target_position := Vector2.ZERO
var remote_target_velocity := Vector2.ZERO
var remote_state_age := 0.0

func _ready():
	_set_player_groups(true)
	if name == "SecondPlayer" and not visible:
		set_lan_player_active(false)
	spawn_position = global_position
	remote_target_position = global_position
	life = max_life
	life_changed.emit(life, max_life)
	_remember_default_player_frames()
	_apply_selected_character()
	_load_dynamic_sprite_frames()
	sprite.animation_finished.connect(_on_animation_finished)
	jump_audio = _create_sound_player("JumpSound", jump_sound)
	run_audio = _create_sound_player("RunSound", run_sound)
	attack_audio = _create_sound_player("AttackSound", attack_sound)
	kick_audio = _create_sound_player("KickSound", kick_sound)

	# ტაილების ფერდობი კიბესავით კვადრატებისგან შედგება (~51°).
	# ამ პარამეტრებით პერსონაჟი კიბეს გლუვ ფერდობად აღიქვამს და
	# საფეხურებზე აღარ ახტება ზემოთ-ქვემოთ.
	floor_max_angle = deg_to_rad(60)   # ციცაბო კიბე „იატაკად" ჩაითვალოს
	floor_snap_length = 80.0            # საფეხურებზე მიწებება, ჰაერში აღარ ახტეს
	floor_constant_speed = true         # ფერდობზე სიჩქარე მუდმივი დარჩეს

func _physics_process(delta):
	if not local_player:
		_update_remote_network_motion(delta)
		return

	if dead:
		if not is_on_floor():
			velocity += get_gravity() * delta
			move_and_slide()
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
		attacking = true
		_play_sound(attack_audio)
		if is_on_floor():
			if Input.is_action_pressed("run"):
				_safe_play("Run Slashing")
			else:
				_safe_play("Slashing")
		else:
			_safe_play("Slashing In Air")
		_damage_nearby_enemies()
		_damage_nearby_players()

	# Kick
	if Input.is_action_just_pressed("kick") and not attacking:
		attacking = true
		_play_sound(kick_audio)
		_safe_play("Kicking")
		_damage_nearby_enemies()
		_damage_nearby_players()

	# Movement
	var direction := Input.get_axis("ui_left", "ui_right")
	var speed := WALK_SPEED

	if Input.is_action_pressed("run"):
		speed = RUN_SPEED

	_update_run_sound(delta, direction)

	if direction != 0:
		velocity.x = direction * speed
		sprite.flip_h = direction < 0

		# დახრილ ადგილზე INPUT - Y უნდა იყოს downhill მიმართულება
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

			# თუ INPUT არ არის, downhill-ით სრიალი
			if direction == 0:
				var normal = get_floor_normal()
				var downhill = Vector2(normal.y, -normal.x)
				if downhill.y < 0:
					downhill = -downhill
				downhill = downhill.normalized()
				velocity = downhill * SLIDE_SPEED
			# თუ INPUT არის, INPUT-ით სრიალი
		else:
			is_sliding = false

	move_and_slide()
	_send_network_state(delta)

	
	

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
			return 20
		"Run Slashing":
			return 35
		_:
			return 25


func take_damage(amount: int) -> void:
	if dead:
		return

	life = max(life - amount, 0)
	life_changed.emit(life, max_life)
	if life <= 0:
		_die()
		return

	_send_network_state(0.0, true)
	modulate = Color(1.0, 0.55, 0.55)
	await get_tree().create_timer(0.12).timeout
	if not dead:
		modulate = Color.WHITE


@rpc("any_peer", "reliable")
func network_take_damage(amount: int) -> void:
	if not local_player:
		return
	take_damage(amount)


func get_hit_position() -> Vector2:
	return sprite.global_position



 

func configure_lan_player(player_id: int, controlled_locally: bool) -> void:
	network_player_id = player_id
	local_player = controlled_locally
	spawn_position = global_position
	set_multiplayer_authority(player_id)

	_set_player_groups(true)

	var camera := get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.position = Vector2.ZERO
		camera.ignore_rotation = true
		camera.enabled = controlled_locally
		camera.zoom = Vector2(0.82, 0.82) if _has_network_peer() else Vector2.ONE


func set_lan_player_active(active: bool) -> void:
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
		_record_lan_round()
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


func _apply_selected_character() -> void:
	if name != "Player":
		return
	var settings := get_node_or_null("/root/GameSettings")
	if not settings:
		return
	if String(settings.get("selected_character")) != "golem":
		return

	var golem_frames := load("res://resources/golem_sprite_frames.tres") as SpriteFrames
	if golem_frames:
		sprite.sprite_frames = golem_frames
		sprite.play("Idle")


func _remember_default_player_frames() -> void:
	if name != "Player":
		return
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.get("player_sprite_frames") == null:
		settings.set("player_sprite_frames", sprite.sprite_frames)


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
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)


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

		var target_peer_id := int(other_player.get("network_player_id"))
		var api := get_multiplayer()
		if api and api.has_multiplayer_peer() and target_peer_id != api.get_unique_id():
			if other_player.has_method("network_take_damage"):
				other_player.rpc_id(target_peer_id, "network_take_damage", damage)
		elif other_player.has_method("take_damage"):
			other_player.take_damage(damage)


func _is_valid_hit(hit_origin: Vector2, target_position: Vector2, facing_direction: float) -> bool:
	var hit_offset := target_position - hit_origin
	if abs(hit_offset.x) > attack_hit_radius:
		return false
	if abs(hit_offset.y) > attack_vertical_tolerance:
		return false
	if abs(hit_offset.x) > 16.0 and sign(hit_offset.x) != facing_direction:
		return false
	return true




func _die() -> void:
	_record_lan_round()
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
		if _is_lan_match_over():
			velocity = Vector2.ZERO
			set_physics_process(false)
			return
		_respawn_for_lan_match()
	else:
		get_tree().reload_current_scene()


func _respawn_for_lan_match() -> void:
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


func _has_network_peer() -> bool:
	var api := get_multiplayer()
	return api and api.has_multiplayer_peer()


func _record_lan_round() -> void:
	if not _has_network_peer():
		return
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("record_lan_round"):
		settings.record_lan_round(_lan_round_winner_name())


func _is_lan_match_over() -> bool:
	var settings := get_node_or_null("/root/GameSettings")
	if settings and settings.has_method("is_lan_match_over"):
		return settings.is_lan_match_over()
	return false


func _lan_round_winner_name() -> String:
	return "Golem 2" if network_player_id == 1 else "Golem 1"
