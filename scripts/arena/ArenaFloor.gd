extends Node2D

func _draw() -> void:
	var sz: Vector2 = get_meta("arena_size", Vector2(1000, 700))
	var hw := sz.x * 0.5
	var hh := sz.y * 0.5

	# Dark floor
	draw_rect(Rect2(-hw, -hh, sz.x, sz.y), Color(0.08, 0.03, 0.04))

	# Subtle cracks
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # deterministic
	for i in 12:
		var start := Vector2(rng.randf_range(-hw, hw), rng.randf_range(-hh, hh))
		var end := start + Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120))
		draw_line(start, end, Color(0.15, 0.05, 0.03, 0.4), 1.0)

	# Lava glow at edges
	var glow_w := 40.0
	draw_rect(Rect2(-hw, -hh, glow_w, sz.y), Color(0.4, 0.08, 0.0, 0.15))
	draw_rect(Rect2(hw - glow_w, -hh, glow_w, sz.y), Color(0.4, 0.08, 0.0, 0.15))
	draw_rect(Rect2(-hw, -hh, sz.x, glow_w), Color(0.4, 0.08, 0.0, 0.15))
	draw_rect(Rect2(-hw, hh - glow_w, sz.x, glow_w), Color(0.4, 0.08, 0.0, 0.15))

	# Wall visuals (thick colored border)
	var wt := 60.0
	var wall_col := Color(0.25, 0.06, 0.02)
	draw_rect(Rect2(-hw - wt, -hh - wt, sz.x + wt * 2, wt), wall_col)  # top
	draw_rect(Rect2(-hw - wt, hh, sz.x + wt * 2, wt), wall_col)         # bottom
	draw_rect(Rect2(-hw - wt, -hh, wt, sz.y), wall_col)                  # left
	draw_rect(Rect2(hw, -hh, wt, sz.y), wall_col)                        # right
