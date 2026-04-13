extends Node2D

func _draw() -> void:
	# Dark rock
	draw_circle(Vector2.ZERO, 44.0, Color(0.18, 0.12, 0.10))
	draw_circle(Vector2(-8, -6), 36.0, Color(0.22, 0.15, 0.12))
	# Highlight
	draw_circle(Vector2(-12, -16), 12.0, Color(0.28, 0.20, 0.16))
	# Dark crack
	draw_line(Vector2(-16, 8), Vector2(20, -4), Color(0.10, 0.06, 0.05), 2.0)
