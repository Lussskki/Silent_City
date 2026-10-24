@tool
extends Node2D

const ASSET_ROOT := "res://Resources/Second_prompt/background_assets"
const FRAME_COUNT := 8
const FRAME_SIZE := Vector2i(182, 180)

var animated_water: AnimatedSprite2D
var water_audio: AudioStreamPlayer2D
var audio_playback: AudioStreamGeneratorPlayback
var river_audio: AudioStreamPlayer2D
var river_audio_playback: AudioStreamGeneratorPlayback
var filtered_noise := 0.0
var river_filtered_noise := 0.0
var random := RandomNumberGenerator.new()
var water_material: ShaderMaterial


func _ready() -> void:
	z_index = -18
	random.seed = 0x51A7C17
	_ensure_visual_layers()
	if Engine.is_editor_hint():
		set_process(false)
		return
	_build_positional_audio()


func _process(_delta: float) -> void:
	_fill_water_audio()
	_fill_river_audio()


func get_waterfall_summary() -> Dictionary:
	return {
		"frame_count": animated_water.sprite_frames.get_frame_count(&"waterfall"),
		"fps": animated_water.sprite_frames.get_animation_speed(&"waterfall"),
		"loop": animated_water.sprite_frames.get_animation_loop(&"waterfall"),
		"frame_size": FRAME_SIZE,
		"positional_audio": water_audio != null,
		"river_positional_audio": river_audio != null,
		"waterfall_volume_db": water_audio.volume_db if water_audio != null else 0.0,
		"river_volume_db": river_audio.volume_db if river_audio != null else 0.0,
	}


func _ensure_visual_layers() -> void:
	animated_water = get_node_or_null("AnimatedWater") as AnimatedSprite2D
	if animated_water != null:
		return
	_build_visual_layers()


func _build_visual_layers() -> void:
	water_material = _make_water_alpha_material()
	var cliff := _sprite("WaterfallCliff", "waterfall_cliff.png", Vector2(0.0, -62.0), -6)
	cliff.modulate = Color(0.60, 0.63, 0.66, 1.0)
	var rear := _sprite("WaterfallBack", "waterfall_back.png", Vector2(0.0, 20.0), -5)
	rear.modulate = Color(0.50, 0.62, 0.72, 0.66)
	rear.material = water_material

	animated_water = AnimatedSprite2D.new()
	animated_water.name = "AnimatedWater"
	animated_water.position = Vector2(0.0, 22.0)
	animated_water.centered = true
	animated_water.z_index = -4
	animated_water.sprite_frames = _waterfall_frames()
	animated_water.animation = &"waterfall"
	animated_water.autoplay = &"waterfall"
	animated_water.modulate = Color(0.57, 0.70, 0.79, 0.86)
	animated_water.material = water_material
	add_child(animated_water)

	var front := _sprite("WaterfallFront", "waterfall_front.png", Vector2(0.0, 24.0), -3)
	front.modulate = Color(0.62, 0.74, 0.82, 0.72)
	front.material = water_material
	var mist := _sprite("WaterfallMist", "waterfall_mist.png", Vector2(0.0, 105.0), -2)
	mist.modulate = Color(0.62, 0.70, 0.76, 0.34)
	mist.material = water_material
	var splash := _sprite("WaterfallSplash", "waterfall_splash.png", Vector2(0.0, 122.0), -1)
	splash.modulate = Color(0.65, 0.76, 0.84, 0.50)
	splash.material = water_material


func _sprite(sprite_name: String, file_name: String, local_position: Vector2, layer_z: int) -> Sprite2D:
	var sprite_node := Sprite2D.new()
	sprite_node.name = sprite_name
	sprite_node.texture = load(ASSET_ROOT.path_join(file_name)) as Texture2D
	sprite_node.position = local_position
	sprite_node.z_index = layer_z
	sprite_node.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	add_child(sprite_node)
	return sprite_node


func _waterfall_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"waterfall")
	frames.set_animation_speed(&"waterfall", 8.0)
	frames.set_animation_loop(&"waterfall", true)
	for index in FRAME_COUNT:
		var path := ASSET_ROOT.path_join("waterfall_%03d.png" % index)
		var texture := load(path) as Texture2D
		if texture != null:
			frames.add_frame(&"waterfall", texture)
	return frames


func _make_water_alpha_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float value = max(source.r, max(source.g, source.b));
	float matte_clean = smoothstep(0.20, 0.39, value);
	float edge_x = smoothstep(0.0, 0.055, UV.x) * smoothstep(0.0, 0.055, 1.0 - UV.x);
	float edge_y = smoothstep(0.0, 0.045, UV.y) * smoothstep(0.0, 0.055, 1.0 - UV.y);
	source.a *= matte_clean * edge_x * edge_y;
	COLOR = source;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _build_positional_audio() -> void:
	water_audio = _make_water_player(
		"PositionalWaterfallSound",
		Vector2(0.0, 96.0),
		-26.0,
		980.0,
		1.7
	)
	water_audio.play()
	audio_playback = water_audio.get_stream_playback() as AudioStreamGeneratorPlayback

	river_audio = _make_water_player(
		"PositionalRiverSound",
		Vector2(-190.0, -62.0),
		-30.0,
		1250.0,
		1.45
	)
	river_audio.play()
	river_audio_playback = river_audio.get_stream_playback() as AudioStreamGeneratorPlayback


func _make_water_player(
	player_name: String,
	local_position: Vector2,
	volume: float,
	max_hearing_distance: float,
	distance_attenuation: float
) -> AudioStreamPlayer2D:
	var player := AudioStreamPlayer2D.new()
	player.name = player_name
	player.position = local_position
	player.volume_db = volume
	player.max_distance = max_hearing_distance
	player.attenuation = distance_attenuation
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 22050.0
	generator.buffer_length = 0.35
	player.stream = generator
	add_child(player)
	return player


func _fill_water_audio() -> void:
	if audio_playback == null:
		return
	var frames_available := audio_playback.get_frames_available()
	for _index in mini(frames_available, 4096):
		var white := random.randf_range(-1.0, 1.0)
		filtered_noise = lerpf(filtered_noise, white, 0.075)
		var sample := clampf(filtered_noise * 0.30 + white * 0.025, -0.36, 0.36)
		audio_playback.push_frame(Vector2(sample, sample))


func _fill_river_audio() -> void:
	if river_audio_playback == null:
		return
	var frames_available := river_audio_playback.get_frames_available()
	for _index in mini(frames_available, 4096):
		var white := random.randf_range(-1.0, 1.0)
		river_filtered_noise = lerpf(river_filtered_noise, white, 0.028)
		var sample := clampf(river_filtered_noise * 0.24 + white * 0.012, -0.28, 0.28)
		river_audio_playback.push_frame(Vector2(sample, sample))
