extends Node2D

const METEOR_DARK := Color(0.22, 0.08, 0.02)
const METEOR_MID  := Color(0.35, 0.12, 0.03)
const CRACK_HOT   := Color(1.0, 0.50, 0.05)
const CRACK_GLOW  := Color(1.0, 0.80, 0.20)
const FIRE_A      := Color(1.0, 0.50, 0.05)
const FIRE_B      := Color(1.0, 0.20, 0.02)
const FIRE_TIP    := Color(1.0, 0.90, 0.25)

var _time: float = 0.0

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var vertices: PackedVector2Array = get_meta("vertices", PackedVector2Array())
	if vertices.size() < 3:
		return

	# Base rock body
	draw_colored_polygon(vertices, METEOR_DARK)

	# Glowing magma cracks along edges
	for i: int in range(vertices.size()):
		var next_i: int = (i + 1) % vertices.size()
		var heat: float = 0.45 + 0.55 * sin(float(i) * 1.7 + _time * 3.0)
		var crack_col := Color(CRACK_HOT.r, CRACK_HOT.g * heat, CRACK_HOT.b * heat, 0.65 + heat * 0.35)
		draw_line(vertices[i], vertices[next_i], crack_col, 2.0)

	# Interior magma glow patches
	var patch_count: int = 4
	for p: int in range(patch_count):
		var pa: float = TAU * p / float(patch_count) + _time * 0.4 + float(p) * 0.8
		var pr: float = 12.0 + 8.0 * sin(_time * 2.5 + float(p) * 1.2)
		var pp: Vector2 = Vector2(cos(pa), sin(pa)) * pr
		var glow_r: float = 5.0 + 3.0 * sin(_time * 4.0 + float(p) * 1.5)
		draw_circle(pp, glow_r + 3.0, Color(1.0, 0.35, 0.02, 0.20))
		draw_circle(pp, glow_r, Color(1.0, lerpf(0.4, 0.8, sin(_time * 5.0 + float(p)) * 0.5 + 0.5), 0.05, 0.6))

	# Animated flame tongues above the meteor
	var flame_count: int = 7
	for f: int in range(flame_count):
		var fa: float = -PI * 0.75 + PI * 1.5 * (float(f) / float(flame_count - 1))
		var flicker: float = sin(_time * (9.0 + float(f) * 1.3) + float(f) * 2.1) * 0.5 + 0.5
		var flame_h: float = (14.0 + 12.0 * flicker) * (0.7 + 0.3 * sin(_time * 5.0 + float(f)))
		var base_r: float = 20.0 + sin(float(f) * 1.1) * 6.0
		var base_x: float = cos(fa) * base_r
		var base_y: float = sin(fa) * base_r * 0.5 - 4.0
		var tip_x: float = base_x + sin(_time * 7.0 + float(f) * 1.7) * 3.0
		var tip_y: float = base_y - flame_h
		var base_pt: Vector2 = Vector2(base_x, base_y)
		var tip_pt: Vector2 = Vector2(tip_x, tip_y)
		var mid_pt: Vector2 = base_pt.lerp(tip_pt, 0.5)
		# Outer flame
		draw_line(base_pt, tip_pt, Color(FIRE_B.r, FIRE_B.g, FIRE_B.b, 0.55 + flicker * 0.3), 4.5)
		# Mid flame
		draw_line(base_pt, mid_pt, Color(FIRE_A.r, FIRE_A.g, FIRE_A.b, 0.7 + flicker * 0.25), 2.8)
		# Bright core
		draw_line(base_pt, mid_pt * 0.6 + base_pt * 0.4, Color(FIRE_TIP.r, FIRE_TIP.g, FIRE_TIP.b, 0.5 + flicker * 0.4), 1.5)

	# Smoke wisps drifting upward
	var smoke_count: int = 5
	for s: int in range(smoke_count):
		var st: float = fmod(_time * 0.8 + float(s) * 0.4, 1.0)
		var sx: float = cos(float(s) * 1.9 + _time * 0.5) * 15.0 * st
		var sy: float = -35.0 - st * 30.0
		var smoke_r: float = (3.0 + st * 5.0)
		draw_circle(Vector2(sx, sy), smoke_r, Color(0.2, 0.1, 0.05, (1.0 - st) * 0.25))
