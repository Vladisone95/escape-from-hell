extends Node2D

const ROCK_COLOR := Color(0.30, 0.22, 0.18)
const ROCK_DARK := Color(0.18, 0.12, 0.10)
const ROCK_LIGHT := Color(0.42, 0.35, 0.28)

func _draw() -> void:
	var vertices: PackedVector2Array = get_meta("vertices", PackedVector2Array())
	if vertices.size() < 3:
		return
	draw_colored_polygon(vertices, ROCK_COLOR)
	for i: int in range(vertices.size()):
		var next_i: int = (i + 1) % vertices.size()
		draw_line(vertices[i], vertices[next_i], ROCK_DARK, 1.5)
	if vertices.size() > 2:
		draw_line(vertices[0], vertices[1], ROCK_LIGHT, 2.0)
	# Crack detail
	if vertices.size() > 4:
		draw_line(Vector2.ZERO, vertices[2] * 0.6, ROCK_DARK, 1.0)
		draw_line(Vector2.ZERO, vertices[5 % vertices.size()] * 0.5, ROCK_DARK, 1.0)
