extends Node2D

var current_health: int = 100
var max_health: int = 100
var bar_width: float = 72.0
var bar_height: float = 8.0
var y_offset: float = -100.0

func update_health(cur: int, mx: int) -> void:
	current_health = cur
	max_health = mx
	queue_redraw()

func _draw() -> void:
	if current_health >= max_health:
		return
	var x0 := -bar_width * 0.5
	# Background
	draw_rect(Rect2(x0, y_offset, bar_width, bar_height), Color(0.15, 0.0, 0.0))
	# Fill
	var ratio := clampf(float(current_health) / float(max_health), 0.0, 1.0)
	var fill_color := Color(0.1, 0.8, 0.1) if ratio > 0.4 else Color(0.9, 0.2, 0.1)
	draw_rect(Rect2(x0, y_offset, bar_width * ratio, bar_height), fill_color)
	# Border
	draw_rect(Rect2(x0, y_offset, bar_width, bar_height), Color(0.3, 0.3, 0.3), false, 1.0)
