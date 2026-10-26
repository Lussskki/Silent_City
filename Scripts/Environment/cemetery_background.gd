extends Node2D

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

var _clock_elapsed := 0.0
@onready var _sky_material := $SkyFill.material as ShaderMaterial


func _ready() -> void:
	z_index = -100
	_update_local_sky()


func _process(delta: float) -> void:
	_clock_elapsed += delta
	if _clock_elapsed >= 1.0:
		_clock_elapsed = 0.0
		_update_local_sky()


func _update_local_sky() -> void:
	var local_time := Time.get_time_dict_from_system()
	var hour := float(local_time.hour) + float(local_time.minute) / 60.0 + float(local_time.second) / 3600.0
	_update_sky_time(hour)


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
