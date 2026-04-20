extends Node2D

var range_radius: float = 0.0

func _draw() -> void:
	if range_radius > 0.0:
		draw_arc(Vector2.ZERO, range_radius, 0.0, TAU, 48, Color(1.0, 0.3, 0.2, 0.08), 1.0)
