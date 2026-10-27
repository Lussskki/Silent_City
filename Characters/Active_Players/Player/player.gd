extends CharacterBody2D

const WALK_SPEED = 150.0
const RUN_SPEED = 400.0
const MOVE_ACCELERATION = 2200.0
const MOVE_DECELERATION = 3000.0
const JUMP_VELOCITY = -520.0
const MAX_JUMPS = 2
const SLIDE_SPEED = 830.0
const SLIDE_ANGLE = 15.0
const MANUAL_SLIDE_DURATION = 0.70
const MANUAL_SLIDE_FRICTION = 400.0
const LADDER_JUMP_SIDE_SPEED = 560.0
const CLIMB_SPEED = 180.0
const LADDER_TOP_ENTRY_DROP = 12.0
const GOLEM_CLIMB_SPRITE_SCALE = 1.15

# Ash uses these constants directly. Stone and Ice receive the same values
# explicitly when they are selected, so their movement can never inherit a
# different scene or character preset.
const GOLEM_MOVEMENT := {
	"walk_speed": 150.0,
	"run_speed": 400.0,
	"jump_velocity": -520.0,
	"max_jumps": 2,
	"slide_speed": 430.0,
	"climb_speed": 180.0
}

const NETWORK_SYNC_INTERVAL = 0.033
const REMOTE_POSITION_SMOOTHING = 20.0
const REMOTE_MAX_PREDICTION = 0.05
const REMOTE_SNAP_DISTANCE = 160.0

const MENU_TEXTURE_CACHE_META := "_silent_city_menu_texture_cache_v1"
const SPRITE_OFFSET := Vector2(0, -10)
# Foot baselines are measured from the center of the original 900px frames.
# Gait distances are tuned for readable chibi steps at the existing move speeds.
# Foot spread alone underestimates stride and makes the short legs cycle too fast.
const GOLEM_GAITS := {
	"player": {"Idle": 302.0, "Walking": 306.0, "Running": 302.0,
		"walk_stride": 550.0, "run_stride": 1000.0},
	"golem": {"Idle": 303.0, "Walking": 313.0, "Running": 303.0,
		"walk_stride": 550.0, "run_stride": 1000.0},
	"ice_golem": {"Idle": 308.0, "Walking": 312.0, "Running": 308.0,
		"walk_stride": 550.0, "run_stride": 1000.0},
}
const FOOT_CONTACT_FRAMES := {"Walking": [6, 18], "Running": [0, 6]}
const ARROW_PROJECTILE_SCENE := preload("res://Scenes/ArrowProjectile.tscn")
const CHARACTER_DISPLAY_NAMES := {
	"player": "Ash Golem",
	"golem": "Stone Golem",
	"ice_golem": "Ice Golem",
}

const HURT_ANIMATION_TIME := 0.28

const SHOCKWAVE_DAMAGE := 55
const SHOCKWAVE_RADIUS := 360.0
const SHOCKWAVE_VERTICAL_TOLERANCE := 115.0
const SHOCKWAVE_KNOCKBACK := Vector2(420, -120)


signal life_changed(life: int, max_life: int)
signal power_changed(power: int, max_power: int)


@export_group("Character Visuals")

# Seat the feet inside the illustrated grass rim, rather than on its top edge.
@export_range(0.0, 24.0, 1.0) var ground_visual_inset := 12.0

@export_group("Character Sounds")

@export var jump_sound: AudioStream
@export var run_sound: AudioStream
@export var attack_sound: AudioStream
@export var kick_sound: AudioStream
@export var hit_sound: AudioStream
@export var landing_sound: AudioStream

@export_range(-80.0, 6.0, 0.5)
var character_sound_volume_db := -8.0


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
@onready var ladder_detector: Area2D = get_node_or_null("LadderDetector") as Area2D


var attacking := false
var selected_character_key := ""
var character_walk_speed := WALK_SPEED
var character_run_speed := RUN_SPEED
var character_jump_velocity := JUMP_VELOCITY
var character_max_jumps := MAX_JUMPS
var character_slide_speed := SLIDE_SPEED
var character_climb_speed := CLIMB_SPEED

var is_sliding := false
var ladder_overlap_count := 0
var is_climbing_ladder := false
var ladder_jump_ignore_timer := 0.0
var dead := false

var life: int = 100
var coin_power: int = 0

var jump_audio: AudioStreamPlayer2D
var run_audio: AudioStreamPlayer2D
var attack_audio: AudioStreamPlayer2D
var kick_audio: AudioStreamPlayer2D
var hit_audio: AudioStreamPlayer2D
var landing_audio: AudioStreamPlayer2D

var manual_slide_timer := 0.0
var manual_slide_speed := 0.0
var manual_slide_direction := 1.0
var attack_hit_timer := 0.0
var hurt_animation_timer := 0.0
var defence_power_timer := 0.0
var defence_block_flash_timer := 0.0
var network_sync_timer := 0.0
var remote_last_animation := ""
var remote_shot_animation_timer := 0.0

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
	_ensure_ladder_detector()

	if name == "SecondPlayer" and not visible:
		set_online_player_active(false)

	spawn_position = global_position
	remote_target_position = global_position

	life = max_life

	life_changed.emit(life, max_life)
	power_changed.emit(coin_power, max_coin_power)

	if not _apply_selected_character():
		_load_dynamic_sprite_frames()

		sprite.position = SPRITE_OFFSET

	default_sprite_scale = sprite.scale
	_align_sprite_feet("Idle")

	_remember_default_player_frames()

	sprite.animation_finished.connect(_on_animation_finished)

	ladder_detector.area_entered.connect(_on_ladder_detector_area_entered)
	ladder_detector.area_exited.connect(_on_ladder_detector_area_exited)

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
	sprite.frame_changed.connect(_on_footstep_frame_changed)


func _ensure_ladder_detector() -> void:
	if ladder_detector:
		return

	ladder_detector = Area2D.new()
	ladder_detector.name = "LadderDetector"
	ladder_detector.collision_layer = 0
	ladder_detector.monitorable = false
	add_child(ladder_detector)

	var detector_shape := CollisionShape2D.new()
	detector_shape.position = Vector2(0.0, 25.0)
	var circle := CircleShape2D.new()
	circle.radius = 42.0
	detector_shape.shape = circle
	ladder_detector.add_child(detector_shape)


func _process(_delta: float) -> void:
	if not is_instance_valid(sprite) or sprite.sprite_frames == null:
		return
	_align_sprite_feet(String(sprite.animation))
	var ground_velocity: Vector2 = velocity if not local_player else (
		get_real_velocity() - get_platform_velocity()
	)
	_sync_gait_to_motion(ground_velocity.length())


func _align_sprite_feet(animation_name: String) -> void:
	if slide_collision == null or slide_collision.shape == null:
		return
	var gait: Dictionary = GOLEM_GAITS.get(selected_character_key, GOLEM_GAITS["player"])
	var foot_baseline: float = float(gait.get(animation_name, gait["Idle"]))
	var collision_bottom: float = slide_collision.position.y + (
		slide_collision.shape.get_rect().end.y * slide_collision.scale.y
	)
	sprite.position.y = collision_bottom + ground_visual_inset - foot_baseline * sprite.scale.y


func _sync_gait_to_motion(ground_speed: float) -> void:
	var animation_name := String(sprite.animation)
	if animation_name not in ["Walking", "Running"]:
		sprite.speed_scale = 1.0
		return
	var gait: Dictionary = GOLEM_GAITS.get(selected_character_key, GOLEM_GAITS["player"])
	var stride_key := "walk_stride" if animation_name == "Walking" else "run_stride"
	var stride: float = float(gait[stride_key]) * absf(sprite.scale.x)
	var frames: SpriteFrames = sprite.sprite_frames
	var cycle_duration := 0.0
	for frame in frames.get_frame_count(animation_name):
		cycle_duration += frames.get_frame_duration(animation_name, frame)
	cycle_duration /= frames.get_animation_speed(animation_name)
	# Changing base FPS no longer changes the distance covered by a full gait.
	sprite.speed_scale = ground_speed * cycle_duration / maxf(stride, 0.001)


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

	# A ladder jump must have time to leave the Area2D before it can grab the
	# player again. Without this, the rising player is snapped back to the ladder.
	ladder_jump_ignore_timer = max(ladder_jump_ignore_timer - delta, 0.0)
	_refresh_ladder_overlap()

	# =====================================================
	# LADDER CLIMBING
	# =====================================================

	var climb_direction := _get_ladder_direction()
	# Catch a ladder while rising from a jump, even if the player presses Up a
	# moment after entering its Area2D.  Falling onto a ladder still requires
	# deliberate vertical input, so ordinary drops stay uninterrupted.
	if (
		ladder_jump_ignore_timer <= 0.0
		and
		ladder_overlap_count > 0
		and (
			not is_zero_approx(climb_direction)
			or velocity.y < 0.0
		)
	):
		is_climbing_ladder = true

	if is_climbing_ladder:
		if ladder_overlap_count <= 0:
			is_climbing_ladder = false
		else:
			_snap_to_ladder_center()
			# Step through the one-way floor even when reversing after climbing up.
			# Once below it, is_on_floor() clears and normal climbing continues.
			if (
				climb_direction > 0.0
				and is_on_floor()
			):
				global_position.y += LADDER_TOP_ENTRY_DROP

			# Left or right immediately jumps away from the ladder.  It does not
			# require the jump button, so ↑/↓ stay dedicated to climbing.
			var ladder_jump_direction := Input.get_axis("move_left", "move_right")
			if is_zero_approx(ladder_jump_direction):
				ladder_jump_direction = Input.get_axis("ui_left", "ui_right")
			var wants_ladder_side_jump := (
				Input.is_action_just_pressed("move_left")
				or Input.is_action_just_pressed("move_right")
				or Input.is_action_just_pressed("ui_left")
				or Input.is_action_just_pressed("ui_right")
			)
			if wants_ladder_side_jump and not is_zero_approx(ladder_jump_direction):
				is_climbing_ladder = false
				ladder_jump_ignore_timer = 0.70
				floor_snap_length = 0.0
				velocity = Vector2(
					ladder_jump_direction * LADDER_JUMP_SIDE_SPEED,
					character_jump_velocity
				)
				if not is_zero_approx(ladder_jump_direction):
					face_right(ladder_jump_direction > 0.0)
				jumps_left = character_max_jumps - 1
				_play_sound(jump_audio)
				move_and_slide()
				_send_network_state(delta)
				_safe_play("Jump Looping")
				return

			floor_snap_length = 0.0
			velocity = Vector2(0.0, climb_direction * character_climb_speed)
			is_sliding = false
			move_and_slide()
			_send_network_state(delta)

			# Keep the back-facing pose on the ladder, but advance its steps only
			# while the player is actually holding an up/down movement key.
			_apply_animation_sprite_scale("Climbing")
			if is_zero_approx(climb_direction):
				if sprite.animation != "Climbing":
					sprite.play("Climbing")
				if sprite.is_playing():
					sprite.pause()
			else:
				if sprite.animation != "Climbing" or not sprite.is_playing():
					sprite.play("Climbing")
			return

	# Restore normal floor snapping outside the ladder.
	_apply_animation_sprite_scale("")
	floor_snap_length = 80.0


	# =====================================================
	# GRAVITY
	# =====================================================

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		jumps_left = character_max_jumps


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

		velocity.y = character_jump_velocity

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

		if _uses_projectile_attack():

			_shoot_arrow()

		elif is_on_floor():

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
	# RUNNING SLIDE
	# =====================================================

	# Holding Shift (the Run action) and pressing Down Arrow performs a short
	# forward slide. S remains dedicated to Kick.
	if (
		not gameplay_input_blocked
		and is_on_floor()
		and not attacking
		and manual_slide_timer <= 0.0
		and Input.is_action_pressed("run")
		and Input.is_action_just_pressed("ui_down")
	):
		manual_slide_timer = MANUAL_SLIDE_DURATION
		manual_slide_direction = _facing_direction()
		# Start with the speed the player already has, so the slide flows out of
		# the run instead of snapping to a new speed.
		manual_slide_speed = max(
			abs(velocity.x),
			character_run_speed
		)
		is_sliding = true
		velocity.x = manual_slide_direction * manual_slide_speed
		_safe_play("Sliding")


	# =====================================================
	# KICK
	# =====================================================

	if (
		not gameplay_input_blocked
		and Input.is_action_just_pressed("kick")
		and not Input.is_action_pressed("run")
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


	# Manual running slide has control for a short time. It uses the existing
	# Sliding animation and sends the result to online players.
	if manual_slide_timer > 0.0:
		manual_slide_timer = max(manual_slide_timer - delta, 0.0)
		is_sliding = true
		manual_slide_speed = move_toward(
			manual_slide_speed,
			0.0,
			MANUAL_SLIDE_FRICTION * delta
		)
		velocity.x = manual_slide_direction * manual_slide_speed
		move_and_slide()
		_update_landing_sound()
		_send_network_state(delta)
		return


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


	var speed := character_walk_speed


	if (
		not gameplay_input_blocked
		and Input.is_action_pressed("run")
	):

		speed = character_run_speed




	if direction != 0:

		velocity.x = move_toward(
			velocity.x,
			direction * speed,
			MOVE_ACCELERATION * delta
		)

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

				velocity.y = downhill.y * character_slide_speed

	else:

		velocity.x = move_toward(
			velocity.x,
			0,
			MOVE_DECELERATION * delta
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

				velocity = downhill * character_slide_speed

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

func _refresh_ladder_overlap() -> void:
	# Poll only the player's small detector.  This complements the Area2D
	# signals and prevents a one-frame missed signal while entering at jump speed.
	ladder_overlap_count = 0
	for area in ladder_detector.get_overlapping_areas():
		if _is_ladder_area(area):
			ladder_overlap_count += 1

	if ladder_overlap_count == 0:
		is_climbing_ladder = false
func _snap_to_ladder_center() -> void:
	for area in ladder_detector.get_overlapping_areas():
		if not _is_ladder_area(area):
			continue

		var climb_area := area.get_node_or_null("LadderClimbArea") as Node2D
		var center_x := climb_area.global_position.x if climb_area else area.global_position.x
		global_position = Vector2(center_x, global_position.y)
		return

func _get_ladder_direction() -> float:
	var direction := 0.0
	if InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		direction = Input.get_axis("move_up", "move_down")
	if is_zero_approx(direction):
		direction = Input.get_axis("ui_up", "ui_down")
	if is_zero_approx(direction):
		direction = float(Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_UP))
	return direction

func _is_ladder_area(area: Area2D) -> bool:
	# The group is the normal contract.  The name fallback keeps the placed
	# Ladder node usable if an older saved scene has not retained its group.
	if area.is_in_group("ladder") or area.name.to_lower().contains("ladder"):
		return true
	var parent := area.get_parent()
	return parent != null and parent.name.to_lower().contains("ladder")

func _on_ladder_detector_area_entered(area: Area2D) -> void:
	if _is_ladder_area(area):
		ladder_overlap_count += 1


func _on_ladder_detector_area_exited(area: Area2D) -> void:
	if not _is_ladder_area(area):
		return

	ladder_overlap_count = max(ladder_overlap_count - 1, 0)
	if ladder_overlap_count == 0:
		is_climbing_ladder = false

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


func _is_ranger_character() -> bool:
	return selected_character_key == "ranger"


func _uses_projectile_attack() -> bool:
	return selected_character_key in ["ranger", "wraith"]


func _shoot_arrow() -> void:
	var arrow := ARROW_PROJECTILE_SCENE.instantiate()
	var scene := get_tree().current_scene
	if not arrow or not scene:
		return

	var facing_direction := _facing_direction()
	# Release the projectile from the character's hand position. Nina's
	# projectile damage path is reused by Wraith through apply_projectile_damage.
	var hand_height := 18.0 if selected_character_key == "wraith" else 30.0
	var origin := get_hit_position() + Vector2(22.0 * facing_direction, hand_height)
	scene.add_child(arrow)
	arrow.setup(origin, facing_direction, self)
	attacking = true
	attack_hit_timer = 0.0
	hit_targets.clear()
	var attack_animation := "Slashing"
	if selected_character_key == "wraith":
		attack_animation = "Throwing" if is_on_floor() else "Throwing In Air"
	else:
		attack_animation = "Slashing" if is_on_floor() else "Slashing In Air"
	_safe_play(attack_animation)
	_send_remote_shot_visual(origin, facing_direction, attack_animation)


func _send_remote_shot_visual(
	origin: Vector2,
	shot_direction: float,
	attack_animation: String
) -> void:
	if not _has_network_peer():
		return
	var online_manager := get_tree().get_first_node_in_group("OnlineManager")
	if online_manager and online_manager.has_method("send_player_shot_visual"):
		online_manager.call(
			"send_player_shot_visual",
			network_player_id,
			origin,
			shot_direction,
			selected_character_key,
			attack_animation
		)


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
	_apply_animation_sprite_scale(name)
	_align_sprite_feet(name)
	if name not in ["Walking", "Running"]:
		sprite.speed_scale = 1.0

	if (
		_has_animation(name)
		and (
			sprite.animation != name
			or not sprite.is_playing()
		)
	):

		sprite.play(name)


func _apply_animation_sprite_scale(animation_name: String) -> void:
	if not sprite:
		return
	var multiplier := 1.0
	if (
		animation_name == "Climbing"
		and selected_character_key in ["golem", "ice_golem"]
	):
		multiplier = GOLEM_CLIMB_SPRITE_SCALE
	sprite.scale = default_sprite_scale * multiplier


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


func _on_footstep_frame_changed() -> void:
	if not local_player or dead or attacking or is_sliding or not is_on_floor():
		return
	if hurt_animation_timer > 0.0 or is_climbing_ladder or _is_gameplay_input_blocked():
		return
	var contacts: Array = FOOT_CONTACT_FRAMES.get(String(sprite.animation), [])
	if sprite.frame not in contacts:
		return
	if (get_real_velocity() - get_platform_velocity()).length() <= 1.0:
		return
	_play_sound(run_audio)


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
		not _is_ranger_character()
		and attacking
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


func set_selected_character(character: String) -> void:
	selected_character_key = character
	_update_team_marker()


func apply_projectile_damage(target: Node, damage: int) -> bool:
	# Projectiles have their own lifetime and hit only once, so they must not be
	# blocked by a stale melee hit entry from the previous attack animation.
	hit_targets.erase(target.get_instance_id())
	return _try_damage_target(target, damage)


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


func take_damage(amount: int, bypass_defence: bool = false) -> void:

	if dead:
		return


	if defence_power_timer > 0.0 and not bypass_defence:
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
		camera.ignore_rotation = true

		camera.enabled = controlled_locally

		if controlled_locally:

			camera.make_current()


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
		marker.position = Vector2(-80, -112)
		marker.size = Vector2(160, 24)
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.add_theme_font_size_override("font_size", 14)
		marker.add_theme_color_override("font_shadow_color", Color.BLACK)
		marker.add_theme_constant_override("shadow_offset_x", 1)
		marker.add_theme_constant_override("shadow_offset_y", 1)
		marker.z_index = 20
		add_child(marker)
	marker.text = String(
		CHARACTER_DISPLAY_NAMES.get(selected_character_key, "Player")
	)
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
	remote_last_animation = remote_animation

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

		elif remote_shot_animation_timer <= 0.0 or _is_projectile_shot_animation(remote_animation):

			modulate = Color.WHITE

			_safe_play(
				remote_animation
			)


func play_remote_shot_visual(
	origin: Vector2,
	shot_direction: float,
	projectile_character: String,
	attack_animation: String
) -> void:
	remote_last_animation = attack_animation
	remote_shot_animation_timer = 0.35
	_safe_play(attack_animation)

	var scene := get_tree().current_scene
	if not scene:
		return
	var arrow := ARROW_PROJECTILE_SCENE.instantiate()
	if not arrow:
		return
	if arrow.has_method("configure_visual_only"):
		arrow.call("configure_visual_only")
	scene.add_child(arrow)
	arrow.setup(origin, shot_direction, self, projectile_character)


func _is_projectile_shot_animation(animation_name: String) -> bool:
	return animation_name in [
		"Slashing",
		"Slashing In Air",
		"Run Slashing",
		"Throwing",
		"Throwing In Air"
	]


func _spawn_remote_arrow_visual(projectile_character: String) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var arrow := ARROW_PROJECTILE_SCENE.instantiate()
	if not arrow:
		return
	var facing_direction := _facing_direction()
	var hand_height := 18.0 if projectile_character == "wraith" else 30.0
	var origin := get_hit_position() + Vector2(22.0 * facing_direction, hand_height)
	scene.add_child(arrow)
	if arrow.has_method("configure_visual_only"):
		arrow.call("configure_visual_only")
	# The explicit synchronized character avoids stale local character state on
	# another PC selecting the wrong arrow texture.
	arrow.setup(origin, facing_direction, self, projectile_character)


func _update_remote_network_motion(
	delta: float
) -> void:

	if dead:
		return

	remote_shot_animation_timer = max(remote_shot_animation_timer - delta, 0.0)
	remote_state_age = min(remote_state_age + delta, REMOTE_MAX_PREDICTION)
	var display_target := (
		remote_target_position
		+ remote_target_velocity * remote_state_age
	)

	# Respawns and large corrections must not slide across the screen.
	if global_position.distance_to(display_target) > REMOTE_SNAP_DISTANCE:
		global_position = display_target
		return


	var smoothing := (
		1.0
		- exp(
			-REMOTE_POSITION_SMOOTHING
			* delta
		)
	)


	global_position = global_position.lerp(
		display_target,
		smoothing
	)


func _load_dynamic_sprite_frames() -> void:
	AshGolemAnimations.apply(self)


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
	if selected_character in ["crusader", "wraith", "minotaur", "ranger"]:
		selected_character = "player"
	selected_character_key = selected_character
	if selected_character in ["golem", "ice_golem"]:
		_apply_golem_movement_settings()


	if selected_character == "ice_golem":
		if not IceGolemAnimations.apply(self):
			return false
		sprite.position = SPRITE_OFFSET
		set_sprite_flip_inverted(true)
		_apply_stone_golem_sounds()
		return true


	if selected_character != "golem":
		return false


	if not StoneGolemAnimations.apply(self):
		return false
	sprite.position = SPRITE_OFFSET
	set_sprite_flip_inverted(true)
	_apply_stone_golem_sounds()
	return true


func _apply_golem_movement_settings() -> void:
	character_walk_speed = float(GOLEM_MOVEMENT["walk_speed"])
	character_run_speed = float(GOLEM_MOVEMENT["run_speed"])
	character_jump_velocity = float(GOLEM_MOVEMENT["jump_velocity"])
	character_max_jumps = int(GOLEM_MOVEMENT["max_jumps"])
	character_slide_speed = float(GOLEM_MOVEMENT["slide_speed"])
	character_climb_speed = float(GOLEM_MOVEMENT["climb_speed"])
	jumps_left = character_max_jumps


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

	jumps_left = character_max_jumps

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
