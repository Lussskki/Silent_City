extends Node2D

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

@export_range(0.0, 5.0, 0.05) var wind_intensity := 1.0

var _wind_materials: Array[ShaderMaterial] = []
@onready var _sky_material := $SkyFill.material as ShaderMaterial


func _ready() -> void:
	z_index = -100
	if _sky_material != null:
		_sky_material.set_shader_parameter("time_sky_top", Color("32283f"))
		_sky_material.set_shader_parameter("time_sky_bottom", Color("655572"))
		_sky_material.set_shader_parameter("time_sky_blend", 1.0)
	_setup_lamps.call_deferred()
	_setup_wind_materials()
	_update_wind()


func _process(_delta: float) -> void:
	_update_wind()


func _setup_wind_materials() -> void:
	for sprite in get_parent().find_children("*", "Sprite2D", true, false):
		var material := sprite.material as ShaderMaterial
		if material != null and material.shader != null and material.shader.resource_path == "res://Scripts/Environment/wind_sway.gdshader":
			if not _wind_materials.has(material):
				_wind_materials.append(material)


func _update_wind() -> void:
	var breeze := (1.0 + sin(float(Time.get_ticks_msec()) * 0.0004) * 0.2) * wind_intensity
	for material in _wind_materials:
		material.set_shader_parameter("wind_strength", breeze)
	if _sky_material != null:
		_sky_material.set_shader_parameter("cloud_wind_speed", 4.0 * wind_intensity)


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
		if lamp is ProximityLantern:
			lamp.set_night_enabled(true)
		else:
			light.enabled = true
			var glow := lamp.get_parent().get_node_or_null(str(lamp.name) + "Glow") as CanvasItem
			if glow != null:
				glow.visible = true
	for light in get_parent().find_children("FlameLight", "PointLight2D", true, false):
		var torch := light.get_parent() as Sprite2D
		if torch == null or not torch.material is ShaderMaterial:
			continue
		light.enabled = true
		var material := torch.material as ShaderMaterial
		material.set_shader_parameter("flame_cutoff", 0.46)
		material.set_shader_parameter("flame_enabled", true)


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
