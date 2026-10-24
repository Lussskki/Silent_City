extends Node2D

const BAR_SIZE := Vector2(68.0, 8.0)

var health_ratio := 1.0


func set_values(current_health: float, maximum_health: float) -> void:
	health_ratio = clampf(current_health / maxf(maximum_health, 1.0), 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(-BAR_SIZE.x * 0.5, -BAR_SIZE.y * 0.5, BAR_SIZE.x, BAR_SIZE.y)
	draw_rect(rect, Color(0.055, 0.06, 0.065, 0.92), true)
	draw_rect(Rect2(rect.position + Vector2.ONE, Vector2((BAR_SIZE.x - 2.0) * health_ratio, BAR_SIZE.y - 2.0)), Color(0.68, 0.055, 0.045, 0.96), true)
	draw_rect(rect, Color(0.70, 0.70, 0.66, 0.78), false, 1.0)
