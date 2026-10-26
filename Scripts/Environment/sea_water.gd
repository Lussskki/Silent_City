extends ColorRect

const SINK_SPEED := 80.0
const DIVE_SPEED := 280.0
const DROWNING_DAMAGE := 25
const DROWNING_INTERVAL := 1.0
const WATER_SOUND := preload("res://Resources/character_voices/14_Step_water_02.wav")

@export var impact_damage := 25
@export var minimum_impact_speed := 150.0
@export var fatal_impact_speed := 900.0

var player: CharacterBody2D
var submerged := false
var drowning_time := 0.0
var splash_audio: AudioStreamPlayer2D
var rock_contacts: Array[int] = []


func _ready() -> void:
	process_physics_priority = 10
	player = get_parent().get_parent().get_node_or_null("Player") as CharacterBody2D
	splash_audio = AudioStreamPlayer2D.new()
	splash_audio.stream = WATER_SOUND
	splash_audio.volume_db = -8.0
	add_child(splash_audio)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or player.get("local_player") == false:
		return
	var feet := player.global_position + Vector2(0.0, 34.0)
	var water_rect := get_global_rect()
	var surface_y := water_rect.position.y + 8.0
	var in_water := (
		feet.x >= water_rect.position.x
		and feet.x <= water_rect.end.x
		and feet.y >= surface_y
	)
	if in_water:
		if not submerged:
			_splash(Vector2(feet.x, surface_y), player.velocity.y)
			_apply_impact_damage(player.velocity.y)
		var diving := Input.is_action_pressed("ui_down")
		if InputMap.has_action("move_down"):
			diving = diving or Input.is_action_pressed("move_down")
		player.velocity.y = DIVE_SPEED if diving else minf(player.velocity.y, SINK_SPEED)
		_apply_rock_damage()
	else:
		rock_contacts.clear()
	submerged = in_water
	var head_y := player.global_position.y - 64.0
	if in_water and head_y >= surface_y and not player.dead:
		drowning_time += delta
		if drowning_time >= DROWNING_INTERVAL:
			drowning_time -= DROWNING_INTERVAL
			player.take_damage(DROWNING_DAMAGE)
	else:
		drowning_time = 0.0


func _apply_rock_damage() -> void:
	var current_contacts: Array[int] = []
	for index in range(player.get_slide_collision_count()):
		var collider := player.get_slide_collision(index).get_collider() as Node
		if not is_instance_valid(collider) or not collider.is_in_group("underwater_rock"):
			continue
		var contact_id := collider.get_instance_id()
		if current_contacts.has(contact_id):
			continue
		current_contacts.append(contact_id)
		if not rock_contacts.has(contact_id) and not player.dead:
			player.take_damage(impact_damage, true)
	rock_contacts = current_contacts


func _apply_impact_damage(impact_speed: float) -> void:
	if player.dead or impact_speed < minimum_impact_speed:
		return
	var damage := int(player.life) if impact_speed >= fatal_impact_speed else impact_damage
	player.take_damage(damage, true)


func _splash(at: Vector2, impact_speed: float) -> void:
	var splash := Node2D.new()
	splash.z_index = 12
	get_tree().current_scene.add_child(splash)
	splash.global_position = at

	var droplets := CPUParticles2D.new()
	droplets.emitting = false
	droplets.amount = clampi(int(absf(impact_speed) / 15.0), 28, 56)
	droplets.lifetime = 0.9
	droplets.one_shot = true
	droplets.explosiveness = 1.0
	droplets.direction = Vector2.UP
	droplets.spread = 55.0
	droplets.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	droplets.emission_rect_extents = Vector2(24.0, 2.0)
	droplets.gravity = Vector2(0.0, 850.0)
	droplets.initial_velocity_min = 300.0
	droplets.initial_velocity_max = clampf(absf(impact_speed) * 0.6, 400.0, 520.0)
	droplets.scale_amount_min = 3.0
	droplets.scale_amount_max = 6.0
	droplets.color = Color(0.55, 0.85, 0.88, 1.0)
	splash.add_child(droplets)
	droplets.emitting = true

	var ripple := Line2D.new()
	ripple.width = 2.0
	ripple.default_color = Color(0.4, 0.7, 0.7, 0.9)
	for index in range(25):
		var angle := TAU * float(index) / 24.0
		ripple.add_point(Vector2(cos(angle) * 12.0, sin(angle) * 3.0))
	splash.add_child(ripple)
	var crown := Line2D.new()
	crown.width = 4.0
	crown.default_color = Color(0.5, 0.8, 0.83, 0.95)
	crown.points = PackedVector2Array([
		Vector2(-66, -30), Vector2(-46, -8), Vector2(-35, -46),
		Vector2(-18, -5), Vector2(0, -28), Vector2(18, -5),
		Vector2(35, -46), Vector2(46, -8), Vector2(66, -30)
	])
	splash.add_child(crown)
	var tween := splash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(crown, "scale", Vector2(1.5, 1.7), 0.3)
	tween.tween_property(crown, "modulate:a", 0.0, 0.4)
	tween.tween_property(ripple, "scale", Vector2(5.0, 2.0), 0.65)
	tween.tween_property(ripple, "modulate:a", 0.0, 0.65)
	tween.chain().tween_interval(0.35)
	tween.chain().tween_callback(splash.queue_free)
	splash_audio.global_position = at
	splash_audio.play()
