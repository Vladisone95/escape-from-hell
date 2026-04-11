extends Node2D

func _draw() -> void:
	# Dark rock
	draw_circle(Vector2.ZERO, 22.0, Color(0.18, 0.12, 0.10))
	draw_circle(Vector2(-4, -3), 18.0, Color(0.22, 0.15, 0.12))
	# Highlight
	draw_circle(Vector2(-6, -8), 6.0, Color(0.28, 0.20, 0.16))
	# Dark crack
	draw_line(Vector2(-8, 4), Vector2(10, -2), Color(0.10, 0.06, 0.05), 1.5)
