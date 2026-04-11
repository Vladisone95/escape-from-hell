extends Node2D

enum EType { DEMON, IMP, HELLHOUND }
enum Facing { DOWN, UP, LEFT, RIGHT }

var etype: int = EType.DEMON
var facing: int = Facing.DOWN

var bob_y: float = 0.0
var hurt_flash: float = 0.0
var walk_cycle: float = 0.0

var _idle_tween: Tween
var _walk_tween: Tween
var _is_walking: bool = false

const PALETTES := {
	EType.DEMON: {
		"body": Color(0.55, 0.08, 0.08), "body_dk": Color(0.38, 0.04, 0.04),
		"body_lt": Color(0.72, 0.15, 0.10), "skin": Color(0.70, 0.30, 0.25),
		"horn": Color(0.25, 0.12, 0.08), "eye": Color(1.0, 0.85, 0.0, 0.95),
		"accent": Color(0.90, 0.30, 0.05),
	},
	EType.IMP: {
		"body": Color(0.45, 0.18, 0.50), "body_dk": Color(0.30, 0.10, 0.35),
		"body_lt": Color(0.60, 0.28, 0.65), "skin": Color(0.55, 0.35, 0.55),
		"horn": Color(0.20, 0.10, 0.15), "eye": Color(0.0, 1.0, 0.4, 0.95),
		"accent": Color(0.80, 0.20, 0.70),
	},
	EType.HELLHOUND: {
		"body": Color(0.20, 0.20, 0.22), "body_dk": Color(0.10, 0.10, 0.12),
		"body_lt": Color(0.35, 0.30, 0.28), "skin": Color(0.30, 0.22, 0.18),
		"horn": Color(0.12, 0.08, 0.06), "eye": Color(1.0, 0.25, 0.0, 0.95),
		"accent": Color(0.90, 0.45, 0.05),
	},
}

func _process(_d: float) -> void:
	queue_redraw()

func _pal() -> Dictionary:
	return PALETTES[etype]

func _tc(base: Color) -> Color:
	return base.lerp(Color(1.0, 1.0, 1.0), hurt_flash * 0.7)

func _leg_offset() -> float:
	return (walk_cycle - 0.5) * 6.0

func start_idle() -> void:
	_stop_walk()
	_kill_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "bob_y", -3.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "bob_y", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func start_walk() -> void:
	if _is_walking: return
	_is_walking = true
	_kill_idle()
	_kill_walk()
	_walk_tween = create_tween().set_loops()
	_walk_tween.tween_property(self, "walk_cycle", 1.0, 0.2).set_trans(Tween.TRANS_SINE)
	_walk_tween.tween_property(self, "walk_cycle", 0.0, 0.2).set_trans(Tween.TRANS_SINE)

func _stop_walk() -> void:
	_is_walking = false
	_kill_walk()
	walk_cycle = 0.0

func _kill_idle() -> void:
	if _idle_tween and _idle_tween.is_valid(): _idle_tween.kill()
	_idle_tween = null; bob_y = 0.0

func _kill_walk() -> void:
	if _walk_tween and _walk_tween.is_valid(): _walk_tween.kill()
	_walk_tween = null

func play_attack() -> void:
	pass  # Handled by body lunge

func play_hurt() -> void:
	var tw := create_tween()
	tw.tween_property(self, "hurt_flash", 1.0, 0.06)
	tw.chain().tween_property(self, "hurt_flash", 0.0, 0.2)
	await tw.finished

func play_die() -> void:
	_kill_idle(); _stop_walk()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color(1.0, 0.15, 0.1, 0.0), 0.5)
	tw.tween_property(self, "hurt_flash", 0.8, 0.1)
	await tw.finished
	visible = false

func set_facing_from_vec(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if dir.y > 0 else Facing.UP

func _draw() -> void:
	match etype:
		EType.DEMON: _draw_demon_dir()
		EType.IMP: _draw_imp_dir()
		EType.HELLHOUND: _draw_hound_dir()

# ══════════════════════════════════════════════════════════════════════
# DEMON
# ══════════════════════════════════════════════════════════════════════
func _draw_demon_dir() -> void:
	match facing:
		Facing.DOWN: _draw_demon_front()
		Facing.UP: _draw_demon_back()
		Facing.LEFT:
			scale.x = -1; _draw_demon_side(); scale.x = 1
		Facing.RIGHT: _draw_demon_side()

func _draw_demon_front() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Legs
	draw_rect(Rect2(-13, 17 + oy + lo, 12, 32), _tc(p["body_dk"]))
	draw_rect(Rect2(1, 17 + oy - lo, 12, 32), _tc(p["body_dk"]))
	draw_rect(Rect2(-15, 45 + oy + lo, 16, 10), _tc(p["horn"]))
	draw_rect(Rect2(-1, 45 + oy - lo, 16, 10), _tc(p["horn"]))

	# Torso
	draw_rect(Rect2(-18, -21 + oy, 36, 40), _tc(p["body"]))
	draw_rect(Rect2(-14, -17 + oy, 12, 8), _tc(p["body_lt"]))
	draw_rect(Rect2(2, -17 + oy, 12, 8), _tc(p["body_lt"]))
	draw_line(Vector2(-4, -1 + oy), Vector2(6, 7 + oy), _tc(p["skin"]), 1.5)

	# Arms
	draw_rect(Rect2(-26, -19 + oy, 10, 28), _tc(p["body"]))
	draw_rect(Rect2(16, -19 + oy, 10, 28), _tc(p["body"]))
	draw_rect(Rect2(-27, 7 + oy, 4, 7), _tc(p["accent"]))
	draw_rect(Rect2(-22, 7 + oy, 4, 7), _tc(p["accent"]))
	draw_rect(Rect2(18, 7 + oy, 4, 7), _tc(p["accent"]))
	draw_rect(Rect2(23, 7 + oy, 4, 7), _tc(p["accent"]))

	# Neck
	draw_rect(Rect2(-5, -27 + oy, 10, 8), _tc(p["skin"]))

	# Head
	draw_circle(Vector2(0, -37 + oy), 14.0, _tc(p["body"]))
	draw_rect(Rect2(-12, -43 + oy, 24, 5), _tc(p["body_dk"]))
	draw_rect(Rect2(-8, -39 + oy, 6, 4), _tc(p["eye"]))
	draw_rect(Rect2(2, -39 + oy, 6, 4), _tc(p["eye"]))
	draw_rect(Rect2(-6, -31 + oy, 12, 3), _tc(p["body_dk"]))
	draw_rect(Rect2(-5, -29 + oy, 3, 4), _tc(Color.WHITE))
	draw_rect(Rect2(2, -29 + oy, 3, 4), _tc(Color.WHITE))

	# Horns
	draw_rect(Rect2(-16, -51 + oy, 6, 14), _tc(p["horn"]))
	draw_rect(Rect2(-18, -53 + oy, 4, 6), _tc(p["horn"]))
	draw_rect(Rect2(10, -51 + oy, 6, 14), _tc(p["horn"]))
	draw_rect(Rect2(14, -53 + oy, 4, 6), _tc(p["horn"]))

func _draw_demon_back() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()
	draw_rect(Rect2(-13, 17 + oy + lo, 12, 32), _tc(p["body_dk"]))
	draw_rect(Rect2(1, 17 + oy - lo, 12, 32), _tc(p["body_dk"]))
	draw_rect(Rect2(-15, 45 + oy + lo, 16, 10), _tc(p["horn"]))
	draw_rect(Rect2(-1, 45 + oy - lo, 16, 10), _tc(p["horn"]))
	draw_rect(Rect2(-18, -21 + oy, 36, 40), _tc(p["body_dk"]))
	draw_line(Vector2(0, -18 + oy), Vector2(0, 16 + oy), _tc(p["body"].darkened(0.3)), 2.0)
	draw_rect(Rect2(-26, -19 + oy, 10, 28), _tc(p["body"]))
	draw_rect(Rect2(16, -19 + oy, 10, 28), _tc(p["body"]))
	draw_rect(Rect2(-5, -27 + oy, 10, 8), _tc(p["skin"]))
	draw_circle(Vector2(0, -37 + oy), 14.0, _tc(p["body"]))
	draw_rect(Rect2(-16, -51 + oy, 6, 14), _tc(p["horn"]))
	draw_rect(Rect2(-18, -53 + oy, 4, 6), _tc(p["horn"]))
	draw_rect(Rect2(10, -51 + oy, 6, 14), _tc(p["horn"]))
	draw_rect(Rect2(14, -53 + oy, 4, 6), _tc(p["horn"]))

func _draw_demon_side() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()
	draw_rect(Rect2(-4, 17 + oy - lo, 12, 32), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(-4, 17 + oy + lo, 12, 32), _tc(p["body_dk"]))
	draw_rect(Rect2(-6, 45 + oy + lo, 16, 10), _tc(p["horn"]))
	draw_rect(Rect2(-10, -21 + oy, 22, 40), _tc(p["body"]))
	draw_rect(Rect2(-10, -17 + oy, 8, 8), _tc(p["body_lt"]))
	draw_rect(Rect2(8, -19 + oy, 8, 28), _tc(p["body"]))
	draw_rect(Rect2(10, 7 + oy, 4, 7), _tc(p["accent"]))
	draw_rect(Rect2(-3, -27 + oy, 8, 8), _tc(p["skin"]))
	draw_circle(Vector2(2, -37 + oy), 13.0, _tc(p["body"]))
	draw_rect(Rect2(4, -39 + oy, 6, 4), _tc(p["eye"]))
	draw_rect(Rect2(8, -31 + oy, 6, 3), _tc(p["body_dk"]))
	draw_rect(Rect2(10, -29 + oy, 3, 4), _tc(Color.WHITE))
	draw_rect(Rect2(4, -51 + oy, 6, 14), _tc(p["horn"]))
	draw_rect(Rect2(6, -53 + oy, 4, 6), _tc(p["horn"]))

# ══════════════════════════════════════════════════════════════════════
# IMP
# ══════════════════════════════════════════════════════════════════════
func _draw_imp_dir() -> void:
	match facing:
		Facing.DOWN: _draw_imp_front()
		Facing.UP: _draw_imp_back()
		Facing.LEFT:
			scale.x = -1; _draw_imp_side(); scale.x = 1
		Facing.RIGHT: _draw_imp_side()

func _draw_imp_front() -> void:
	var p := _pal(); var oy := bob_y + 16.0; var lo := _leg_offset()

	# Tail
	draw_line(Vector2(8, 7 + oy), Vector2(28, -5 + oy), _tc(p["body_dk"]), 3.0)
	draw_line(Vector2(28, -5 + oy), Vector2(32, -11 + oy), _tc(p["accent"]), 2.5)

	# Wings
	var wc := _tc(p["body_dk"])
	draw_line(Vector2(-10, -25 + oy), Vector2(-30, -41 + oy), wc, 2.5)
	draw_line(Vector2(-30, -41 + oy), Vector2(-22, -27 + oy), wc, 2.0)
	draw_line(Vector2(10, -25 + oy), Vector2(30, -41 + oy), wc, 2.5)
	draw_line(Vector2(30, -41 + oy), Vector2(22, -27 + oy), wc, 2.0)

	# Legs
	draw_rect(Rect2(-10, 5 + oy + lo, 8, 20), _tc(p["body_dk"]))
	draw_rect(Rect2(2, 5 + oy - lo, 8, 20), _tc(p["body_dk"]))
	draw_rect(Rect2(-12, 23 + oy + lo, 12, 6), _tc(p["horn"]))
	draw_rect(Rect2(0, 23 + oy - lo, 12, 6), _tc(p["horn"]))

	# Body
	draw_rect(Rect2(-12, -25 + oy, 24, 32), _tc(p["body"]))
	draw_rect(Rect2(-8, -11 + oy, 16, 12), _tc(p["body_lt"]))

	# Arms
	draw_rect(Rect2(-20, -23 + oy, 8, 22), _tc(p["body"]))
	draw_rect(Rect2(12, -23 + oy, 8, 22), _tc(p["body"]))
	draw_rect(Rect2(-21, -3 + oy, 3, 5), _tc(p["accent"]))
	draw_rect(Rect2(-17, -3 + oy, 3, 5), _tc(p["accent"]))
	draw_rect(Rect2(14, -3 + oy, 3, 5), _tc(p["accent"]))
	draw_rect(Rect2(18, -3 + oy, 3, 5), _tc(p["accent"]))

	# Head
	draw_circle(Vector2(0, -37 + oy), 13.0, _tc(p["body"]))
	draw_rect(Rect2(-9, -41 + oy, 7, 6), _tc(Color(0.0, 0.0, 0.0)))
	draw_rect(Rect2(2, -41 + oy, 7, 6), _tc(Color(0.0, 0.0, 0.0)))
	draw_rect(Rect2(-7, -40 + oy, 4, 4), _tc(p["eye"]))
	draw_rect(Rect2(3, -40 + oy, 4, 4), _tc(p["eye"]))
	draw_rect(Rect2(-6, -31 + oy, 12, 2), _tc(p["body_dk"]))
	draw_rect(Rect2(-4, -30 + oy, 2, 3), _tc(Color.WHITE))
	draw_rect(Rect2(2, -30 + oy, 2, 3), _tc(Color.WHITE))
	draw_rect(Rect2(-12, -47 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(8, -47 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(-16, -41 + oy, 6, 4), _tc(p["body_lt"]))
	draw_rect(Rect2(10, -41 + oy, 6, 4), _tc(p["body_lt"]))

func _draw_imp_back() -> void:
	var p := _pal(); var oy := bob_y + 16.0; var lo := _leg_offset()
	# Tail
	draw_line(Vector2(0, 5 + oy), Vector2(20, -5 + oy), _tc(p["body_dk"]), 3.0)
	# Wings (larger from back)
	var wc := _tc(p["body_dk"])
	draw_line(Vector2(-8, -25 + oy), Vector2(-28, -45 + oy), wc, 3.0)
	draw_line(Vector2(-28, -45 + oy), Vector2(-20, -25 + oy), wc, 2.5)
	draw_line(Vector2(-28, -45 + oy), Vector2(-14, -30 + oy), wc, 2.5)
	draw_line(Vector2(8, -25 + oy), Vector2(28, -45 + oy), wc, 3.0)
	draw_line(Vector2(28, -45 + oy), Vector2(20, -25 + oy), wc, 2.5)
	draw_line(Vector2(28, -45 + oy), Vector2(14, -30 + oy), wc, 2.5)

	draw_rect(Rect2(-10, 5 + oy + lo, 8, 20), _tc(p["body_dk"]))
	draw_rect(Rect2(2, 5 + oy - lo, 8, 20), _tc(p["body_dk"]))
	draw_rect(Rect2(-12, 23 + oy + lo, 12, 6), _tc(p["horn"]))
	draw_rect(Rect2(0, 23 + oy - lo, 12, 6), _tc(p["horn"]))
	draw_rect(Rect2(-12, -25 + oy, 24, 32), _tc(p["body_dk"]))
	draw_rect(Rect2(-20, -23 + oy, 8, 22), _tc(p["body"]))
	draw_rect(Rect2(12, -23 + oy, 8, 22), _tc(p["body"]))
	draw_circle(Vector2(0, -37 + oy), 13.0, _tc(p["body"]))
	draw_rect(Rect2(-12, -47 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(8, -47 + oy, 4, 8), _tc(p["horn"]))

func _draw_imp_side() -> void:
	var p := _pal(); var oy := bob_y + 16.0; var lo := _leg_offset()
	# Tail
	draw_line(Vector2(-6, 3 + oy), Vector2(-22, -5 + oy), _tc(p["body_dk"]), 3.0)
	# Wing
	var wc := _tc(p["body_dk"])
	draw_line(Vector2(0, -25 + oy), Vector2(22, -42 + oy), wc, 2.5)
	draw_line(Vector2(22, -42 + oy), Vector2(14, -25 + oy), wc, 2.0)

	draw_rect(Rect2(-3, 5 + oy - lo, 8, 20), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(-3, 5 + oy + lo, 8, 20), _tc(p["body_dk"]))
	draw_rect(Rect2(-5, 23 + oy + lo, 12, 6), _tc(p["horn"]))
	draw_rect(Rect2(-8, -25 + oy, 18, 32), _tc(p["body"]))
	draw_rect(Rect2(6, -23 + oy, 7, 22), _tc(p["body"]))
	draw_rect(Rect2(8, -3 + oy, 3, 5), _tc(p["accent"]))
	draw_circle(Vector2(2, -37 + oy), 12.0, _tc(p["body"]))
	draw_rect(Rect2(4, -41 + oy, 6, 5), _tc(Color.BLACK))
	draw_rect(Rect2(5, -40 + oy, 4, 3), _tc(p["eye"]))
	draw_rect(Rect2(6, -31 + oy, 6, 2), _tc(p["body_dk"]))
	draw_rect(Rect2(6, -47 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(10, -41 + oy, 5, 4), _tc(p["body_lt"]))

# ══════════════════════════════════════════════════════════════════════
# HELLHOUND
# ══════════════════════════════════════════════════════════════════════
func _draw_hound_dir() -> void:
	match facing:
		Facing.DOWN: _draw_hound_front()
		Facing.UP: _draw_hound_back()
		Facing.LEFT:
			scale.x = -1; _draw_hound_side(); scale.x = 1
		Facing.RIGHT: _draw_hound_side()

func _draw_hound_front() -> void:
	var p := _pal(); var oy := bob_y + 20.0; var lo := _leg_offset()

	# Legs (4 visible from front, slightly spread)
	draw_rect(Rect2(-20, -3 + oy + lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(-10, -3 + oy - lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(0, -3 + oy + lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(10, -3 + oy - lo, 10, 22), _tc(p["body_dk"]))
	# Paws
	draw_rect(Rect2(-22, 17 + oy + lo, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(-12, 17 + oy - lo, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(-2, 17 + oy + lo, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(8, 17 + oy - lo, 14, 8), _tc(p["horn"]))

	# Body (seen from front - wider, shorter)
	draw_rect(Rect2(-18, -23 + oy, 36, 22), _tc(p["body"]))

	# Mane
	var mc := _tc(p["accent"])
	draw_rect(Rect2(-12, -31 + oy, 5, 10), mc)
	draw_rect(Rect2(-5, -33 + oy, 5, 12), mc)
	draw_rect(Rect2(2, -33 + oy, 5, 12), mc)
	draw_rect(Rect2(8, -31 + oy, 5, 10), mc)

	# Head
	draw_rect(Rect2(-12, -25 + oy, 24, 16), _tc(p["body"]))
	# Snout
	draw_rect(Rect2(-6, -15 + oy, 12, 8), _tc(p["body_lt"]))
	draw_rect(Rect2(-3, -15 + oy, 6, 3), _tc(p["horn"]))
	# Eyes
	draw_rect(Rect2(-10, -23 + oy, 5, 4), _tc(p["eye"]))
	draw_rect(Rect2(5, -23 + oy, 5, 4), _tc(p["eye"]))
	# Jaw
	draw_rect(Rect2(-4, -9 + oy, 8, 3), _tc(p["body_dk"]))
	draw_rect(Rect2(-3, -7 + oy, 2, 3), _tc(Color.WHITE))
	draw_rect(Rect2(1, -7 + oy, 2, 3), _tc(Color.WHITE))
	# Ears
	draw_rect(Rect2(-14, -31 + oy, 5, 8), _tc(p["body_dk"]))
	draw_rect(Rect2(9, -31 + oy, 5, 8), _tc(p["body_dk"]))

func _draw_hound_back() -> void:
	var p := _pal(); var oy := bob_y + 20.0; var lo := _leg_offset()
	# Tail
	draw_line(Vector2(0, -15 + oy), Vector2(0, -30 + oy), _tc(p["body"]), 4.0)
	draw_line(Vector2(0, -30 + oy), Vector2(0, -38 + oy), _tc(p["accent"]), 3.0)

	draw_rect(Rect2(-20, -3 + oy + lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(-10, -3 + oy - lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(0, -3 + oy + lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(10, -3 + oy - lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(-22, 17 + oy + lo, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(8, 17 + oy - lo, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(-18, -23 + oy, 36, 22), _tc(p["body_dk"]))
	# Spine
	draw_rect(Rect2(-2, -23 + oy, 4, 22), _tc(p["body_lt"]))
	# Mane from back
	var mc := _tc(p["accent"])
	draw_rect(Rect2(-8, -31 + oy, 16, 10), mc)
	draw_rect(Rect2(-12, -25 + oy, 24, 10), _tc(p["body"]))
	draw_rect(Rect2(-14, -27 + oy, 5, 8), _tc(p["body_dk"]))
	draw_rect(Rect2(9, -27 + oy, 5, 8), _tc(p["body_dk"]))

func _draw_hound_side() -> void:
	var p := _pal(); var oy := bob_y + 20.0; var lo := _leg_offset()

	# Tail
	draw_line(Vector2(24, -17 + oy), Vector2(38, -33 + oy), _tc(p["body"]), 4.0)
	draw_line(Vector2(38, -33 + oy), Vector2(42, -39 + oy), _tc(p["accent"]), 3.0)
	draw_line(Vector2(42, -39 + oy), Vector2(40, -45 + oy), _tc(Color(1.0, 0.6, 0.0)), 2.0)

	# Back legs
	draw_rect(Rect2(12, -3 + oy - lo, 10, 22), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(18, -3 + oy + lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(10, 17 + oy - lo, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(18, 17 + oy + lo, 14, 8), _tc(p["horn"]))

	# Front legs
	draw_rect(Rect2(-24, -3 + oy + lo, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(-18, -3 + oy - lo, 10, 22), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(-26, 17 + oy + lo, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(-18, 17 + oy - lo, 14, 8), _tc(p["horn"]))

	# Body
	draw_rect(Rect2(-22, -23 + oy, 48, 24), _tc(p["body"]))
	draw_line(Vector2(-8, -19 + oy), Vector2(-10, -5 + oy), _tc(p["body_lt"]), 1.2)
	draw_line(Vector2(-2, -20 + oy), Vector2(-4, -5 + oy), _tc(p["body_lt"]), 1.2)
	draw_line(Vector2(4, -20 + oy), Vector2(2, -5 + oy), _tc(p["body_lt"]), 1.2)
	draw_rect(Rect2(-18, -25 + oy, 40, 4), _tc(p["body_lt"]))

	# Mane
	var mc := _tc(p["accent"])
	draw_rect(Rect2(-20, -31 + oy, 5, 10), mc)
	draw_rect(Rect2(-14, -33 + oy, 5, 12), mc)
	draw_rect(Rect2(-8, -31 + oy, 5, 10), mc)
	draw_rect(Rect2(-18, -35 + oy, 3, 6), _tc(Color(1.0, 0.6, 0.0)))
	draw_rect(Rect2(-12, -37 + oy, 3, 6), _tc(Color(1.0, 0.6, 0.0)))

	# Head
	draw_rect(Rect2(-30, -25 + oy, 16, 16), _tc(p["body"]))
	draw_rect(Rect2(-38, -19 + oy, 10, 10), _tc(p["body_lt"]))
	draw_rect(Rect2(-38, -18 + oy, 4, 3), _tc(p["horn"]))
	draw_rect(Rect2(-36, -11 + oy, 8, 3), _tc(p["body_dk"]))
	draw_rect(Rect2(-35, -12 + oy, 2, 3), _tc(Color.WHITE))
	draw_rect(Rect2(-31, -12 + oy, 2, 3), _tc(Color.WHITE))
	draw_rect(Rect2(-28, -23 + oy, 5, 4), _tc(p["eye"]))
	draw_rect(Rect2(-30, -31 + oy, 5, 8), _tc(p["body_dk"]))
	draw_rect(Rect2(-22, -31 + oy, 5, 8), _tc(p["body_dk"]))
