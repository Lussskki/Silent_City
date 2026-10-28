extends Node2D

const RAIN_LIGHT := preload("res://Sprites/rain/png/64x64/rain_light.png")
const RAIN_NORMAL := preload("res://Sprites/rain/png/64x64/rain.png")
const RAIN_HEAVY := preload("res://Sprites/rain/png/64x64/rain_heavy.png")
const TBILISI_WEATHER_URL := "https://api.open-meteo.com/v1/forecast?latitude=41.7151&longitude=44.8271&current=rain,showers&timezone=Asia%2FTbilisi&forecast_days=1"
const LAMP_SHADER := """
shader_type canvas_item;
uniform bool bulb_on = true;
void fragment() {
	// Only the yellow glass/bulb pixels; preserve the roof, frame, and post.
	if (!bulb_on && UV.x >= 0.25 && UV.x <= 0.76 && UV.y >= 0.23 && UV.y <= 0.46
			&& COLOR.r > 0.4 && COLOR.g > 0.36 && COLOR.b < COLOR.g * 0.85) {
		float glass = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114)) * 0.3;
		COLOR.rgb = vec3(glass * 0.9, glass, glass * 0.95);
	}
}
"""

const SKY_STOPS := [
	[0.0, Color("32283f"), Color("655572")],
	[6.0, Color("32283f"), Color("655572")],
	[7.0, Color("786e92"), Color("c7a48f")],
	[10.0, Color("527da0"), Color("a5b6b8")],
	[16.0, Color("527da0"), Color("a5b6b8")],
	[18.0, Color("766080"), Color("bf8a79")],
	[20.0, Color("32283f"), Color("655572")],
	[24.0, Color("32283f"), Color("655572")],
]

@export_group("Story Weather")
## 0 disables rain; 1 is the current light rain; higher values add more drops.
@export_range(0.0, 5.0, 0.05) var rain_intensity := 1.0
## 0 is calm; 1 is the current breeze; higher values strengthen wind and cloud drift.
@export_range(0.0, 5.0, 0.05) var wind_intensity := 1.0
## Optional development weather connection; disabled by default. F3 can enable it.
@export var use_tbilisi_weather := false

var _clock_elapsed := 0.0
var _lamps: Array[Dictionary] = []
var _torch_lights: Array[PointLight2D] = []
var _lamps_on := false
var _lamp_time_initialized := false
var _rain: Polygon2D
var _weather_debug: PanelContainer
var _rain_toggle: CheckButton
var _rain_amount: SpinBox
var _auto_weather: CheckButton
var _weather_status: Label
var _weather_request: HTTPRequest
var _weather_rain_intensity := 0.0
var _wind_materials: Array[ShaderMaterial] = []
@onready var _sky_material := $SkyFill.material as ShaderMaterial


func _ready() -> void:
	z_index = -100
	_update_local_sky()
	_setup_lamps.call_deferred()
	_setup_wind_materials()
	if use_tbilisi_weather:
		rain_intensity = 0.0
	_setup_rain()
	_setup_weather_debug()
	_setup_live_weather()


func _process(delta: float) -> void:
	_update_rain()
	_clock_elapsed += delta
	if _clock_elapsed >= 1.0:
		_clock_elapsed = 0.0
		_update_local_sky()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		_weather_debug.visible = not _weather_debug.visible
		if not _weather_debug.visible:
			_rain_amount.get_line_edit().release_focus()
		get_viewport().set_input_as_handled()


func _setup_weather_debug() -> void:
	var layer := CanvasLayer.new()
	layer.name = "WeatherDebug"
	layer.layer = 100
	add_child(layer)
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(screen)
	_weather_debug = PanelContainer.new()
	_weather_debug.name = "Panel"
	screen.add_child(_weather_debug)
	_weather_debug.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_weather_debug.offset_left = -300
	_weather_debug.offset_right = -20
	_weather_debug.offset_top = 100
	_weather_debug.offset_bottom = 100
	_weather_debug.custom_minimum_size = Vector2(280, 0)
	_weather_debug.hide()
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	_weather_debug.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)
	var title := Label.new()
	title.text = "Weather Debug (F3)"
	content.add_child(title)
	_auto_weather = CheckButton.new()
	_auto_weather.text = "Tbilisi live weather"
	_auto_weather.button_pressed = use_tbilisi_weather
	content.add_child(_auto_weather)
	_auto_weather.toggled.connect(_set_live_weather_enabled)
	_weather_status = Label.new()
	_weather_status.text = "Tbilisi: waiting for weather" if use_tbilisi_weather else "Manual weather (live weather off)"
	_weather_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_weather_status)
	_rain_toggle = CheckButton.new()
	_rain_toggle.name = "RainEnabled"
	_rain_toggle.text = "Rain On / Off"
	_rain_toggle.button_pressed = rain_intensity > 0.0
	content.add_child(_rain_toggle)
	var row := HBoxContainer.new()
	content.add_child(row)
	var label := Label.new()
	label.text = "Intensity"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	_rain_amount = SpinBox.new()
	_rain_amount.name = "RainIntensity"
	_rain_amount.min_value = 0.0
	_rain_amount.max_value = 5.0
	_rain_amount.step = 0.05
	_rain_amount.custom_minimum_size.x = 110
	_rain_amount.value = rain_intensity if rain_intensity > 0.0 else 1.0
	_rain_amount.update_on_text_changed = true
	row.add_child(_rain_amount)
	var hint := Label.new()
	hint.text = "0 = off   1 = light   5 = heavy"
	content.add_child(hint)
	_rain_toggle.toggled.connect(_set_debug_rain_enabled)
	_rain_amount.value_changed.connect(_set_debug_rain_intensity)


func _set_debug_rain_enabled(enabled: bool) -> void:
	use_tbilisi_weather = false
	_auto_weather.set_pressed_no_signal(false)
	rain_intensity = _rain_amount.value if enabled else 0.0
	_update_rain()


func _set_debug_rain_intensity(value: float) -> void:
	use_tbilisi_weather = false
	_auto_weather.set_pressed_no_signal(false)
	if _rain_toggle.button_pressed:
		rain_intensity = value
		_update_rain()


func _setup_live_weather() -> void:
	_weather_request = HTTPRequest.new()
	_weather_request.timeout = 10.0
	_weather_request.body_size_limit = 65536
	add_child(_weather_request)
	_weather_request.request_completed.connect(_on_weather_completed)
	var refresh := Timer.new()
	refresh.wait_time = 900.0
	add_child(refresh)
	refresh.timeout.connect(_request_weather)
	refresh.start()
	_request_weather()


func _request_weather() -> void:
	if not use_tbilisi_weather or _weather_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	if _weather_request.request(TBILISI_WEATHER_URL) != OK:
		_weather_status.text = "Tbilisi: unavailable; keeping last weather"


func _on_weather_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or not _apply_weather_data(body):
		_weather_status.text = "Tbilisi: unavailable; keeping last weather"


func _apply_weather_data(body: PackedByteArray) -> bool:
	var json := JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK or not json.data is Dictionary:
		return false
	var current: Variant = json.data.get("current")
	if not current is Dictionary:
		return false
	var rain: Variant = current.get("rain")
	var showers: Variant = current.get("showers")
	if not (rain is float or rain is int) or not (showers is float or showers is int):
		return false
	if float(rain) < 0.0 or float(showers) < 0.0:
		return false
	var amount := float(rain) + float(showers)
	_weather_rain_intensity = 0.0 if amount == 0.0 else (1.0 if amount <= 0.5 else (2.5 if amount <= 2.0 else 4.5))
	_weather_status.text = "Tbilisi: " + ("dry" if amount == 0.0 else "rain") + " (Open-Meteo)"
	if use_tbilisi_weather:
		_apply_live_rain()
	return true


func _set_live_weather_enabled(enabled: bool) -> void:
	use_tbilisi_weather = enabled
	if enabled:
		_apply_live_rain()
		_request_weather()


func _apply_live_rain() -> void:
	rain_intensity = _weather_rain_intensity
	_rain_toggle.set_pressed_no_signal(rain_intensity > 0.0)
	if rain_intensity > 0.0:
		_rain_amount.set_value_no_signal(rain_intensity)
	_update_rain()


func _setup_wind_materials() -> void:
	for sprite in get_parent().find_children("*", "Sprite2D", true, false):
		var material := sprite.material as ShaderMaterial
		if material != null and material.shader != null and material.shader.resource_path == "res://Scripts/Environment/wind_sway.gdshader":
			if not _wind_materials.has(material):
				_wind_materials.append(material)


func _setup_rain() -> void:
	_rain = Polygon2D.new()
	_rain.name = "LightRain"
	_rain.top_level = true
	_rain.z_as_relative = false
	_rain.z_index = 1400
	var rain_shader := Shader.new()
	rain_shader.code = """shader_type canvas_item;
uniform sampler2D rain_sheet : source_color, filter_nearest, repeat_disable;
uniform float water_surface = 1000000.0;
uniform float rain_opacity = 0.5;
uniform float wind_strength = 1.0;
varying vec2 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; }
void fragment() {
	if (world_position.y >= water_surface) { discard; }
	vec2 sheet_size = vec2(textureSize(rain_sheet, 0));
	float frame = mod(floor(TIME * 12.0), sheet_size.x / 64.0);
	vec2 rain_pixel = world_position / 2.0;
	rain_pixel.x -= rain_pixel.y * 0.2 * wind_strength + TIME * 24.0 * wind_strength;
	vec2 tile_pixel = floor(mod(rain_pixel, vec2(64.0))) + vec2(0.5);
	vec2 rain_uv = (vec2(frame * 64.0, 0.0) + tile_pixel) / sheet_size;
	float rain_alpha = texture(rain_sheet, rain_uv).a;
	COLOR = vec4(0.7, 0.82, 0.9, rain_alpha * rain_opacity) * COLOR;
}
"""
	var rain_material := ShaderMaterial.new()
	rain_material.shader = rain_shader
	var water := get_parent().get_node_or_null("Level/SeaWater") as Control
	if water != null:
		rain_material.set_shader_parameter("water_surface", water.get_global_rect().position.y + 8.0)
	_rain.material = rain_material
	add_child(_rain)
	_update_rain()


func _update_rain() -> void:
	if not is_instance_valid(_rain):
		return
	_rain.visible = rain_intensity > 0.0
	var view := get_viewport_rect()
	var inverse_canvas := get_viewport().get_canvas_transform().affine_inverse()
	var view_start := inverse_canvas * view.position
	var view_end := inverse_canvas * view.end
	_rain.global_position = view_start
	var view_size := view_end - view_start
	_rain.polygon = PackedVector2Array([Vector2.ZERO, Vector2(view_size.x, 0), view_size, Vector2(0, view_size.y)])
	var rain_material := _rain.material as ShaderMaterial
	var sheet := RAIN_LIGHT if rain_intensity <= 1.5 else (RAIN_NORMAL if rain_intensity <= 3.0 else RAIN_HEAVY)
	if rain_material.get_shader_parameter("rain_sheet") != sheet:
		rain_material.set_shader_parameter("rain_sheet", sheet)
	rain_material.set_shader_parameter("rain_opacity", clampf(rain_intensity * 0.35, 0.0, 0.85))
	var breeze := (1.0 + sin(float(Time.get_ticks_msec()) * 0.0004) * 0.2) * wind_intensity
	rain_material.set_shader_parameter("wind_strength", breeze)
	for material in _wind_materials:
		material.set_shader_parameter("wind_strength", breeze)
	if _sky_material != null:
		_sky_material.set_shader_parameter("cloud_wind_speed", 4.0 * wind_intensity)


func _update_local_sky() -> void:
	var local_time := Time.get_time_dict_from_system()
	var hour := float(local_time.hour) + float(local_time.minute) / 60.0 + float(local_time.second) / 3600.0
	_update_sky_time(hour)
	_update_lamp_time(hour)


func _setup_lamps() -> void:
	var bulb_shader := Shader.new()
	bulb_shader.code = LAMP_SHADER
	for light in get_parent().find_children("LampLight", "PointLight2D", true, false):
		var lamp := light.get_parent() as Sprite2D
		if lamp == null:
			continue
		var bulb_material := ShaderMaterial.new()
		bulb_material.shader = bulb_shader
		lamp.material = bulb_material
		_lamps.append({
			"sprite": lamp,
			"light": light,
			"glow": lamp.get_parent().get_node_or_null(str(lamp.name) + "Glow") as CanvasItem,
		})
	for light in get_parent().find_children("FlameLight", "PointLight2D", true, false):
		var torch := light.get_parent() as Sprite2D
		if torch == null or not torch.material is ShaderMaterial:
			continue
		(torch.material as ShaderMaterial).set_shader_parameter("flame_cutoff", 0.46)
		_torch_lights.append(light as PointLight2D)
	_update_local_sky()


func _update_lamp_time(hour: float) -> void:
	if _lamps.is_empty() and _torch_lights.is_empty():
		return
	var lights_on := hour >= 20.0 or hour < 6.0
	if _lamp_time_initialized and lights_on == _lamps_on:
		return
	_lamp_time_initialized = true
	_lamps_on = lights_on
	for light in _torch_lights:
		light.enabled = lights_on
		(light.get_parent().material as ShaderMaterial).set_shader_parameter("flame_enabled", lights_on)
	for entry in _lamps:
		var lamp := entry.sprite as Sprite2D
		if lamp is ProximityLantern:
			lamp.set_night_enabled(lights_on)
		else:
			(lamp.material as ShaderMaterial).set_shader_parameter("bulb_on", lights_on)
			(entry.light as PointLight2D).enabled = lights_on
			var glow := entry.glow as CanvasItem
			if glow != null:
				glow.visible = lights_on


func _update_sky_time(hour: float) -> void:
	if _sky_material == null:
		return
	for index in range(SKY_STOPS.size() - 1):
		var start: Array = SKY_STOPS[index]
		var end: Array = SKY_STOPS[index + 1]
		if hour >= start[0] and hour <= end[0]:
			var weight := smoothstep(float(start[0]), float(end[0]), hour)
			_sky_material.set_shader_parameter("time_sky_top", (start[1] as Color).lerp(end[1], weight))
			_sky_material.set_shader_parameter("time_sky_bottom", (start[2] as Color).lerp(end[2], weight))
			_sky_material.set_shader_parameter("time_sky_blend", 1.0)
			break


func get_background_summary() -> Dictionary:
	return {
		"moon_instances": 1,
		"hill_sprites": 0,
		"fog_layers": 0,
		"house_sprites": 0,
		"sky_path": "res://Sprites/Background/Forbidden_Graveyard_sky_only.png",
		"sky_scroll_factor": 1.0,
		"fog_scroll_factor": 0.0,
		"fog_drift_speed": 0.0,
	}
