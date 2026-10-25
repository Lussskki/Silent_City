extends Node2D


func _ready() -> void:
	z_index = -100


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
