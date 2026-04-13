extends Node2D

enum EType { DEMON, IMP, HELLHOUND, WARLOCK, ABOMINATION, VANITY_BOSS }
enum Facing { DOWN, UP, LEFT, RIGHT }

var etype: int = EType.DEMON
var facing: int = Facing.DOWN

var bob_y: float = 0.0
var hurt_flash: float = 0.0
var walk_cycle: float = 0.0
var cast_anim: float = 0.0

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
	EType.WARLOCK: {
		"body": Color(0.18, 0.08, 0.28), "body_dk": Color(0.10, 0.04, 0.18),
		"body_lt": Color(0.30, 0.14, 0.42), "skin": Color(0.45, 0.32, 0.40),
		"horn": Color(0.22, 0.10, 0.30), "eye": Color(0.7, 0.3, 1.0, 0.95),
		"accent": Color(0.75, 0.25, 0.95),
	},
	EType.ABOMINATION: {
		"body": Color(0.55, 0.12, 0.12), "body_dk": Color(0.35, 0.06, 0.06),
		"body_lt": Color(0.70, 0.20, 0.18), "skin": Color(0.75, 0.30, 0.28),
		"horn": Color(0.25, 0.10, 0.08), "eye": Color(1.0, 0.9, 0.0, 0.95),
		"accent": Color(0.90, 0.15, 0.10),
	},
}

func _process(_d: float) -> void:
	queue_redraw()

func _pal() -> Dictionary:
	return PALETTES[etype]

func _tc(base: Color) -> Color:
	return base.lerp(Color(1.0, 1.0, 1.0), hurt_flash * 0.7)

func _leg_offset() -> float:
	return (walk_cycle - 0.5) * 2.5

func start_idle() -> void:
	_stop_walk()
	_kill_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "bob_y", -1.5, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
	pass

func play_cast() -> void:
	var tw := create_tween()
	tw.tween_property(self, "cast_anim", 1.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(self, "cast_anim", 0.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

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
		EType.WARLOCK: _draw_warlock_dir()
		EType.ABOMINATION: _draw_abomination_dir()

# ══════════════════════════════════════════════════════════════════════
# DEMON — stocky brute, fits ~32px (hurtbox r=16)
# ══════════════════════════════════════════════════════════════════════
func _draw_demon_dir() -> void:
	match facing:
		Facing.DOWN: _draw_demon_front()
		Facing.UP: _draw_demon_back()
		Facing.LEFT:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1)); _draw_demon_side(); draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Facing.RIGHT: _draw_demon_side()

func _draw_demon_front() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Arms (behind body)
	draw_rect(Rect2(-15, -3 + oy, 5, 14), _tc(p["body"]))
	draw_rect(Rect2(10, -3 + oy, 5, 14), _tc(p["body"]))
	# Claws
	draw_rect(Rect2(-16, 10 + oy, 3, 4), _tc(p["accent"]))
	draw_rect(Rect2(-13, 10 + oy, 3, 4), _tc(p["accent"]))
	draw_rect(Rect2(11, 10 + oy, 3, 4), _tc(p["accent"]))
	draw_rect(Rect2(14, 10 + oy, 3, 4), _tc(p["accent"]))

	# Legs
	draw_rect(Rect2(-7, 10 + oy + lo, 6, 8), _tc(p["body_dk"]))
	draw_rect(Rect2(1, 10 + oy - lo, 6, 8), _tc(p["body_dk"]))
	# Hooves
	draw_rect(Rect2(-8, 16 + oy + lo, 8, 4), _tc(p["horn"]))
	draw_rect(Rect2(0, 16 + oy - lo, 8, 4), _tc(p["horn"]))

	# Torso (barrel-chested)
	draw_rect(Rect2(-10, -6 + oy, 20, 16), _tc(p["body"]))
	draw_rect(Rect2(-8, -4 + oy, 7, 6), _tc(p["body_lt"]))
	draw_rect(Rect2(1, -4 + oy, 7, 6), _tc(p["body_lt"]))
	# Scar
	draw_line(Vector2(-3, 0 + oy), Vector2(4, 5 + oy), _tc(p["skin"]), 1.0)

	# Head (big demon head)
	draw_circle(Vector2(0, -12 + oy), 9.0, _tc(p["body"]))
	draw_rect(Rect2(-8, -16 + oy, 16, 3), _tc(p["body_dk"]))  # brow ridge
	draw_rect(Rect2(-5, -14 + oy, 4, 3), _tc(p["eye"]))
	draw_rect(Rect2(1, -14 + oy, 4, 3), _tc(p["eye"]))
	draw_rect(Rect2(-4, -7 + oy, 8, 2), _tc(p["body_dk"]))  # mouth
	draw_rect(Rect2(-3, -6 + oy, 2, 2), _tc(Color.WHITE))  # fangs
	draw_rect(Rect2(1, -6 + oy, 2, 2), _tc(Color.WHITE))

	# Horns (decorative, extend outside hitbox)
	draw_rect(Rect2(-11, -20 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(-13, -22 + oy, 3, 4), _tc(p["horn"]))
	draw_rect(Rect2(7, -20 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(10, -22 + oy, 3, 4), _tc(p["horn"]))

func _draw_demon_back() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Legs
	draw_rect(Rect2(-7, 10 + oy + lo, 6, 8), _tc(p["body_dk"]))
	draw_rect(Rect2(1, 10 + oy - lo, 6, 8), _tc(p["body_dk"]))
	draw_rect(Rect2(-8, 16 + oy + lo, 8, 4), _tc(p["horn"]))
	draw_rect(Rect2(0, 16 + oy - lo, 8, 4), _tc(p["horn"]))

	# Torso
	draw_rect(Rect2(-10, -6 + oy, 20, 16), _tc(p["body_dk"]))
	draw_line(Vector2(0, -4 + oy), Vector2(0, 8 + oy), _tc(p["body"].darkened(0.3)), 1.5)

	# Arms
	draw_rect(Rect2(-15, -3 + oy, 5, 14), _tc(p["body"]))
	draw_rect(Rect2(10, -3 + oy, 5, 14), _tc(p["body"]))

	# Head
	draw_circle(Vector2(0, -12 + oy), 9.0, _tc(p["body"]))
	# Horns
	draw_rect(Rect2(-11, -20 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(-13, -22 + oy, 3, 4), _tc(p["horn"]))
	draw_rect(Rect2(7, -20 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(10, -22 + oy, 3, 4), _tc(p["horn"]))

func _draw_demon_side() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Back arm
	draw_rect(Rect2(-8, -3 + oy, 4, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(-9, 8 + oy, 2, 3), _tc(p["accent"].darkened(0.2)))

	# Back leg
	draw_rect(Rect2(-3, 10 + oy - lo, 6, 8), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(-4, 16 + oy - lo, 8, 4), _tc(p["horn"].darkened(0.1)))
	# Front leg
	draw_rect(Rect2(-3, 10 + oy + lo, 6, 8), _tc(p["body_dk"]))
	draw_rect(Rect2(-4, 16 + oy + lo, 8, 4), _tc(p["horn"]))

	# Torso
	draw_rect(Rect2(-5, -6 + oy, 5, 16), _tc(p["body_dk"]))
	draw_rect(Rect2(0, -6 + oy, 6, 16), _tc(p["body"]))
	draw_rect(Rect2(1, -4 + oy, 4, 6), _tc(p["body_lt"]))

	# Front arm
	draw_rect(Rect2(5, -3 + oy, 5, 14), _tc(p["body"]))
	draw_rect(Rect2(7, 10 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(10, 10 + oy, 2, 3), _tc(p["accent"]))

	# Head (side)
	draw_circle(Vector2(1, -12 + oy), 8.0, _tc(p["body"]))
	draw_circle(Vector2(-2, -12 + oy), 6.0, _tc(p["body_dk"]))
	draw_circle(Vector2(3, -13 + oy), 6.0, _tc(p["body_lt"]))
	draw_rect(Rect2(4, -14 + oy, 5, 4), _tc(p["eye"]))
	draw_rect(Rect2(1, -16 + oy, 8, 3), _tc(p["body_dk"]))  # brow
	draw_rect(Rect2(5, -8 + oy, 5, 2), _tc(p["body_dk"]))  # jaw
	draw_rect(Rect2(7, -7 + oy, 2, 3), _tc(Color.WHITE))  # fang

	# Horn (single visible)
	draw_rect(Rect2(3, -20 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(5, -23 + oy, 3, 5), _tc(p["horn"]))

# ══════════════════════════════════════════════════════════════════════
# IMP — small trickster, fits ~32px (hurtbox r=16)
# ══════════════════════════════════════════════════════════════════════
func _draw_imp_dir() -> void:
	match facing:
		Facing.DOWN: _draw_imp_front()
		Facing.UP: _draw_imp_back()
		Facing.LEFT:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1)); _draw_imp_side(); draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Facing.RIGHT: _draw_imp_side()

func _draw_imp_front() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Tail (decorative)
	draw_line(Vector2(6, 6 + oy), Vector2(18, -2 + oy), _tc(p["body_dk"]), 2.0)
	draw_line(Vector2(18, -2 + oy), Vector2(20, -6 + oy), _tc(p["accent"]), 1.5)

	# Wings (decorative, outside hitbox)
	var wc := _tc(p["body_dk"])
	draw_line(Vector2(-7, -10 + oy), Vector2(-18, -22 + oy), wc, 2.0)
	draw_line(Vector2(-18, -22 + oy), Vector2(-13, -12 + oy), wc, 1.5)
	draw_line(Vector2(7, -10 + oy), Vector2(18, -22 + oy), wc, 2.0)
	draw_line(Vector2(18, -22 + oy), Vector2(13, -12 + oy), wc, 1.5)

	# Legs
	draw_rect(Rect2(-6, 10 + oy + lo, 5, 7), _tc(p["body_dk"]))
	draw_rect(Rect2(1, 10 + oy - lo, 5, 7), _tc(p["body_dk"]))
	draw_rect(Rect2(-7, 15 + oy + lo, 7, 3), _tc(p["horn"]))
	draw_rect(Rect2(0, 15 + oy - lo, 7, 3), _tc(p["horn"]))

	# Body (compact)
	draw_rect(Rect2(-8, -5 + oy, 16, 16), _tc(p["body"]))
	draw_rect(Rect2(-5, 0 + oy, 10, 8), _tc(p["body_lt"]))

	# Arms
	draw_rect(Rect2(-13, -3 + oy, 5, 12), _tc(p["body"]))
	draw_rect(Rect2(8, -3 + oy, 5, 12), _tc(p["body"]))
	draw_rect(Rect2(-14, 8 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(-12, 8 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(10, 8 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(12, 8 + oy, 2, 3), _tc(p["accent"]))

	# Head (oversized chibi head)
	draw_circle(Vector2(0, -11 + oy), 9.0, _tc(p["body"]))
	draw_rect(Rect2(-6, -15 + oy, 5, 4), _tc(Color.BLACK))
	draw_rect(Rect2(1, -15 + oy, 5, 4), _tc(Color.BLACK))
	draw_rect(Rect2(-5, -14 + oy, 3, 3), _tc(p["eye"]))
	draw_rect(Rect2(2, -14 + oy, 3, 3), _tc(p["eye"]))
	draw_rect(Rect2(-4, -6 + oy, 8, 1), _tc(p["body_dk"]))  # grin
	draw_rect(Rect2(-3, -6 + oy, 2, 2), _tc(Color.WHITE))
	draw_rect(Rect2(1, -6 + oy, 2, 2), _tc(Color.WHITE))
	# Horns
	draw_rect(Rect2(-8, -19 + oy, 3, 6), _tc(p["horn"]))
	draw_rect(Rect2(5, -19 + oy, 3, 6), _tc(p["horn"]))
	# Ears
	draw_rect(Rect2(-11, -14 + oy, 4, 3), _tc(p["body_lt"]))
	draw_rect(Rect2(7, -14 + oy, 4, 3), _tc(p["body_lt"]))

func _draw_imp_back() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()
	# Tail
	draw_line(Vector2(0, 6 + oy), Vector2(14, -2 + oy), _tc(p["body_dk"]), 2.0)
	# Wings
	var wc := _tc(p["body_dk"])
	draw_line(Vector2(-6, -10 + oy), Vector2(-18, -24 + oy), wc, 2.5)
	draw_line(Vector2(-18, -24 + oy), Vector2(-12, -12 + oy), wc, 2.0)
	draw_line(Vector2(6, -10 + oy), Vector2(18, -24 + oy), wc, 2.5)
	draw_line(Vector2(18, -24 + oy), Vector2(12, -12 + oy), wc, 2.0)

	draw_rect(Rect2(-6, 10 + oy + lo, 5, 7), _tc(p["body_dk"]))
	draw_rect(Rect2(1, 10 + oy - lo, 5, 7), _tc(p["body_dk"]))
	draw_rect(Rect2(-7, 15 + oy + lo, 7, 3), _tc(p["horn"]))
	draw_rect(Rect2(0, 15 + oy - lo, 7, 3), _tc(p["horn"]))
	draw_rect(Rect2(-8, -5 + oy, 16, 16), _tc(p["body_dk"]))
	draw_rect(Rect2(-13, -3 + oy, 5, 12), _tc(p["body"]))
	draw_rect(Rect2(8, -3 + oy, 5, 12), _tc(p["body"]))
	draw_circle(Vector2(0, -11 + oy), 9.0, _tc(p["body"]))
	draw_rect(Rect2(-8, -19 + oy, 3, 6), _tc(p["horn"]))
	draw_rect(Rect2(5, -19 + oy, 3, 6), _tc(p["horn"]))

func _draw_imp_side() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()
	# Tail
	draw_line(Vector2(-4, 4 + oy), Vector2(-14, -4 + oy), _tc(p["body_dk"]), 2.0)
	draw_line(Vector2(-14, -4 + oy), Vector2(-16, -7 + oy), _tc(p["accent"]), 1.5)
	# Wing
	var wc := _tc(p["body_dk"])
	draw_line(Vector2(-2, -10 + oy), Vector2(-12, -24 + oy), wc, 2.5)
	draw_line(Vector2(-12, -24 + oy), Vector2(-7, -12 + oy), wc, 2.0)

	# Back leg
	draw_rect(Rect2(-3, 10 + oy - lo, 5, 7), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(-4, 15 + oy - lo, 7, 3), _tc(p["horn"].darkened(0.1)))
	# Front leg
	draw_rect(Rect2(-3, 10 + oy + lo, 5, 7), _tc(p["body_dk"]))
	draw_rect(Rect2(-4, 15 + oy + lo, 7, 3), _tc(p["horn"]))

	# Back arm
	draw_rect(Rect2(-7, -3 + oy, 4, 10), _tc(p["body_dk"]))

	# Body
	draw_rect(Rect2(-4, -5 + oy, 5, 16), _tc(p["body_dk"]))
	draw_rect(Rect2(1, -5 + oy, 6, 16), _tc(p["body"]))
	draw_rect(Rect2(2, 0 + oy, 4, 8), _tc(p["body_lt"]))

	# Front arm
	draw_rect(Rect2(5, -3 + oy, 5, 12), _tc(p["body_lt"]))
	draw_rect(Rect2(7, 8 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(9, 8 + oy, 2, 3), _tc(p["accent"]))

	# Head
	draw_circle(Vector2(1, -11 + oy), 8.0, _tc(p["body"]))
	draw_circle(Vector2(-2, -11 + oy), 6.0, _tc(p["body_dk"]))
	draw_circle(Vector2(3, -12 + oy), 6.0, _tc(p["body_lt"]))
	draw_rect(Rect2(3, -15 + oy, 5, 4), _tc(Color.BLACK))
	draw_rect(Rect2(4, -14 + oy, 3, 3), _tc(p["eye"]))
	draw_rect(Rect2(5, -7 + oy, 4, 1), _tc(p["body_dk"]))
	draw_rect(Rect2(6, -7 + oy, 2, 2), _tc(Color.WHITE))
	draw_rect(Rect2(3, -19 + oy, 3, 6), _tc(p["horn"]))
	draw_rect(Rect2(8, -14 + oy, 4, 3), _tc(p["body_lt"]))  # ear

# ══════════════════════════════════════════════════════════════════════
# HELLHOUND — quadruped blob, fits ~32px (hurtbox r=16)
# ══════════════════════════════════════════════════════════════════════
func _draw_hound_dir() -> void:
	match facing:
		Facing.DOWN: _draw_hound_front()
		Facing.UP: _draw_hound_back()
		Facing.RIGHT:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1)); _draw_hound_side(); draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Facing.LEFT: _draw_hound_side()

func _draw_hound_front() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# 4 legs
	draw_rect(Rect2(-12, 4 + oy + lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(-6, 4 + oy - lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(1, 4 + oy + lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(7, 4 + oy - lo, 5, 12), _tc(p["body_dk"]))
	# Paws
	draw_rect(Rect2(-13, 14 + oy + lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(-7, 14 + oy - lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(0, 14 + oy + lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(6, 14 + oy - lo, 7, 4), _tc(p["horn"]))

	# Body
	draw_rect(Rect2(-10, -8 + oy, 20, 14), _tc(p["body"]))

	# Mane
	var mc := _tc(p["accent"])
	draw_rect(Rect2(-7, -14 + oy, 3, 6), mc)
	draw_rect(Rect2(-3, -15 + oy, 3, 7), mc)
	draw_rect(Rect2(1, -15 + oy, 3, 7), mc)
	draw_rect(Rect2(5, -14 + oy, 3, 6), mc)

	# Head
	draw_rect(Rect2(-8, -10 + oy, 16, 10), _tc(p["body"]))
	# Snout
	draw_rect(Rect2(-4, -3 + oy, 8, 5), _tc(p["body_lt"]))
	draw_rect(Rect2(-2, -3 + oy, 4, 2), _tc(p["horn"]))  # nose
	# Eyes
	draw_rect(Rect2(-7, -9 + oy, 4, 3), _tc(p["eye"]))
	draw_rect(Rect2(3, -9 + oy, 4, 3), _tc(p["eye"]))
	# Jaw
	draw_rect(Rect2(-3, 0 + oy, 6, 2), _tc(p["body_dk"]))
	draw_rect(Rect2(-2, 1 + oy, 2, 2), _tc(Color.WHITE))
	draw_rect(Rect2(1, 1 + oy, 2, 2), _tc(Color.WHITE))
	# Ears
	draw_rect(Rect2(-10, -14 + oy, 4, 6), _tc(p["body_dk"]))
	draw_rect(Rect2(6, -14 + oy, 4, 6), _tc(p["body_dk"]))

func _draw_hound_back() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()
	# Tail (decorative)
	draw_line(Vector2(0, -6 + oy), Vector2(0, -16 + oy), _tc(p["body"]), 3.0)
	draw_line(Vector2(0, -16 + oy), Vector2(0, -20 + oy), _tc(p["accent"]), 2.0)

	draw_rect(Rect2(-12, 4 + oy + lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(-6, 4 + oy - lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(1, 4 + oy + lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(7, 4 + oy - lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(-13, 14 + oy + lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(6, 14 + oy - lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(-10, -8 + oy, 20, 14), _tc(p["body_dk"]))
	draw_rect(Rect2(-1, -8 + oy, 2, 14), _tc(p["body_lt"]))  # spine
	var mc := _tc(p["accent"])
	draw_rect(Rect2(-5, -14 + oy, 10, 6), mc)
	draw_rect(Rect2(-8, -10 + oy, 16, 6), _tc(p["body"]))
	draw_rect(Rect2(-10, -12 + oy, 4, 4), _tc(p["body_dk"]))  # ears
	draw_rect(Rect2(6, -12 + oy, 4, 4), _tc(p["body_dk"]))

func _draw_hound_side() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Tail (decorative)
	draw_line(Vector2(14, -6 + oy), Vector2(22, -14 + oy), _tc(p["body"]), 3.0)
	draw_line(Vector2(22, -14 + oy), Vector2(24, -18 + oy), _tc(p["accent"]), 2.0)
	draw_line(Vector2(24, -18 + oy), Vector2(23, -21 + oy), _tc(Color(1.0, 0.6, 0.0)), 1.5)

	# Back legs
	draw_rect(Rect2(8, 4 + oy - lo, 5, 12), _tc(p["body_dk"].darkened(0.2)))
	draw_rect(Rect2(12, 4 + oy + lo, 4, 12), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(7, 14 + oy - lo, 7, 4), _tc(p["horn"].darkened(0.1)))
	# Front legs
	draw_rect(Rect2(-14, 4 + oy + lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(-10, 4 + oy - lo, 5, 12), _tc(p["body_dk"].darkened(0.1)))
	draw_rect(Rect2(-15, 14 + oy + lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(-11, 14 + oy - lo, 7, 4), _tc(p["horn"]))

	# Body (elongated side view)
	draw_rect(Rect2(-12, -8 + oy, 28, 7), _tc(p["body_lt"]))
	draw_rect(Rect2(-12, -1 + oy, 28, 7), _tc(p["body"]))
	draw_rect(Rect2(-10, 4 + oy, 24, 2), _tc(p["body_dk"]))
	draw_rect(Rect2(-10, -10 + oy, 24, 3), _tc(p["body_lt"]))  # spine

	# Mane
	var mc := _tc(p["accent"])
	draw_rect(Rect2(-12, -14 + oy, 4, 6), mc)
	draw_rect(Rect2(-8, -15 + oy, 3, 7), mc)
	draw_rect(Rect2(-5, -14 + oy, 3, 6), mc)
	draw_rect(Rect2(-11, -16 + oy, 3, 4), _tc(Color(1.0, 0.6, 0.0)))  # flame tip

	# Head (angular snout)
	draw_rect(Rect2(-16, -10 + oy, 10, 10), _tc(p["body"]))
	draw_rect(Rect2(-22, -8 + oy, 8, 8), _tc(p["body_lt"]))  # snout
	draw_rect(Rect2(-22, -7 + oy, 3, 3), _tc(p["horn"]))  # nose
	draw_rect(Rect2(-21, -1 + oy, 7, 3), _tc(p["body_dk"]))  # jaw
	draw_rect(Rect2(-20, -1 + oy, 2, 2), _tc(Color.WHITE))  # fangs
	draw_rect(Rect2(-17, -1 + oy, 2, 2), _tc(Color.WHITE))
	draw_rect(Rect2(-15, -9 + oy, 4, 3), _tc(p["eye"]))  # eye
	draw_rect(Rect2(-18, -14 + oy, 3, 6), _tc(p["body"]))  # ear
	draw_rect(Rect2(-14, -13 + oy, 3, 4), _tc(p["body_dk"]))  # back ear

# ══════════════════════════════════════════════════════════════════════
# WARLOCK — hooded caster, fits ~32px (hurtbox r=16)
# ══════════════════════════════════════════════════════════════════════
func _draw_warlock_dir() -> void:
	match facing:
		Facing.DOWN: _draw_warlock_front()
		Facing.UP: _draw_warlock_back()
		Facing.LEFT:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1)); _draw_warlock_side(); draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Facing.RIGHT: _draw_warlock_side()

func _draw_warlock_front() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Robe bottom (compact)
	var robe_pts := PackedVector2Array([
		Vector2(-9, 5 + oy), Vector2(9, 5 + oy),
		Vector2(12, 18 + oy), Vector2(-12, 18 + oy),
	])
	draw_colored_polygon(robe_pts, _tc(p["body"]))
	draw_rect(Rect2(1, 5 + oy, 10, 13), _tc(p["body_dk"]))
	draw_rect(Rect2(-11, 16 + oy, 23, 2), _tc(p["body_lt"]))
	# Ember hem
	draw_rect(Rect2(-9, 17 + oy, 3, 1), _tc(p["accent"]).lerp(Color.TRANSPARENT, 0.4))
	draw_rect(Rect2(3, 17 + oy, 3, 1), _tc(p["accent"]).lerp(Color.TRANSPARENT, 0.5))

	# Torso
	draw_rect(Rect2(-8, -6 + oy, 16, 12), _tc(p["body"]))
	# Rune on chest
	draw_line(Vector2(-2, -4 + oy), Vector2(2, -4 + oy), _tc(p["accent"]).lerp(Color.TRANSPARENT, 0.3), 1.0)
	draw_line(Vector2(0, -5 + oy), Vector2(0, -1 + oy), _tc(p["accent"]).lerp(Color.TRANSPARENT, 0.3), 1.0)
	# Collar V
	var collar := PackedVector2Array([
		Vector2(-5, -6 + oy), Vector2(5, -6 + oy), Vector2(0, -1 + oy),
	])
	draw_colored_polygon(collar, _tc(p["body_dk"]))

	# Arms
	draw_rect(Rect2(-13, -4 + oy + lo, 5, 12), _tc(p["body_lt"]))
	draw_rect(Rect2(8, -4 + oy - lo, 5, 12), _tc(p["body"]))
	# Hand glow
	draw_circle(Vector2(-10, 9 + oy + lo), 3.0, _tc(Color(0.5, 0.1, 0.8, 0.3)))
	draw_circle(Vector2(-10, 9 + oy + lo), 2.0, _tc(p["accent"]).lerp(Color.WHITE, 0.2))
	draw_circle(Vector2(11, 9 + oy - lo), 3.0, _tc(Color(0.5, 0.1, 0.8, 0.3)))
	draw_circle(Vector2(11, 9 + oy - lo), 2.0, _tc(p["accent"]).lerp(Color.WHITE, 0.2))

	# Staff (decorative, extends above hitbox)
	var staff_thrust := cast_anim * 5.0
	var soy := oy - staff_thrust
	draw_rect(Rect2(-1, -22 + soy, 2, 28), _tc(p["horn"]))
	# Forked head
	draw_rect(Rect2(-3, -25 + soy, 2, 4), _tc(p["horn"]))
	draw_rect(Rect2(1, -25 + soy, 2, 4), _tc(p["horn"]))
	# Purple fire
	var fs := 1.0 + cast_anim * 1.2
	var fa := 0.5 + cast_anim * 0.5
	draw_circle(Vector2(0, -25 + soy), 3.5 * fs, _tc(Color(0.5, 0.1, 0.8, fa)))
	draw_circle(Vector2(0, -26 + soy), 2.5 * fs, _tc(Color(0.6, 0.2, 0.9, min(fa + 0.3, 1.0))))
	draw_circle(Vector2(0, -27 + soy), 1.5 * fs, _tc(Color(0.75, 0.4, 1.0, min(fa + 0.4, 1.0))))
	var fh := 4.0 + cast_anim * 6.0
	var flame := PackedVector2Array([
		Vector2(-2 - cast_anim, -27 + soy), Vector2(0, -27 - fh + soy), Vector2(2 + cast_anim, -27 + soy),
	])
	draw_colored_polygon(flame, _tc(Color(0.6, 0.2, 0.9, 0.6 + cast_anim * 0.4)))

	# Head (hooded)
	draw_circle(Vector2(0, -12 + oy), 8.0, _tc(p["body"]))
	var hood := PackedVector2Array([
		Vector2(-5, -18 + oy), Vector2(5, -18 + oy), Vector2(1, -22 + oy),
	])
	draw_colored_polygon(hood, _tc(p["body"]))
	# Face shadow
	draw_circle(Vector2(0, -11 + oy), 5.0, _tc(Color(0.03, 0.01, 0.03)))
	# Eyes
	draw_rect(Rect2(-4, -13 + oy, 3, 2), _tc(p["eye"]))
	draw_rect(Rect2(1, -13 + oy, 3, 2), _tc(p["eye"]))
	draw_circle(Vector2(-2, -12 + oy), 2.0, _tc(Color(0.5, 0.15, 0.8, 0.35)))
	draw_circle(Vector2(2, -12 + oy), 2.0, _tc(Color(0.5, 0.15, 0.8, 0.35)))

func _draw_warlock_back() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Robe bottom
	var robe_pts := PackedVector2Array([
		Vector2(-9, 5 + oy), Vector2(9, 5 + oy),
		Vector2(12, 18 + oy), Vector2(-12, 18 + oy),
	])
	draw_colored_polygon(robe_pts, _tc(p["body_dk"]))
	draw_rect(Rect2(-11, 16 + oy, 23, 2), _tc(p["body"]))

	# Torso back
	draw_rect(Rect2(-8, -6 + oy, 16, 12), _tc(p["body_dk"]))

	# Arms
	draw_rect(Rect2(-13, -4 + oy + lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(8, -4 + oy - lo, 5, 12), _tc(p["body_dk"]))

	# Staff
	var staff_thrust := cast_anim * 5.0
	var soy := oy - staff_thrust
	draw_rect(Rect2(-1, -22 + soy, 2, 28), _tc(p["horn"]))
	draw_rect(Rect2(-3, -25 + soy, 2, 4), _tc(p["horn"]))
	draw_rect(Rect2(1, -25 + soy, 2, 4), _tc(p["horn"]))
	var fs := 1.0 + cast_anim * 1.2
	var fa := 0.5 + cast_anim * 0.5
	draw_circle(Vector2(0, -25 + soy), 3.5 * fs, _tc(Color(0.5, 0.1, 0.8, fa)))
	draw_circle(Vector2(0, -26 + soy), 2.5 * fs, _tc(Color(0.6, 0.2, 0.9, min(fa + 0.3, 1.0))))
	var fh := 4.0 + cast_anim * 6.0
	var flame := PackedVector2Array([
		Vector2(-2 - cast_anim, -27 + soy), Vector2(0, -27 - fh + soy), Vector2(2 + cast_anim, -27 + soy),
	])
	draw_colored_polygon(flame, _tc(Color(0.6, 0.2, 0.9, 0.6 + cast_anim * 0.4)))

	# Hood back
	draw_circle(Vector2(0, -12 + oy), 8.0, _tc(p["body_dk"]))
	var hood := PackedVector2Array([
		Vector2(-5, -18 + oy), Vector2(5, -18 + oy), Vector2(1, -22 + oy),
	])
	draw_colored_polygon(hood, _tc(p["body_dk"]))

func _draw_warlock_side() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()

	# Robe (side)
	var robe_pts := PackedVector2Array([
		Vector2(-6, 5 + oy), Vector2(6, 5 + oy),
		Vector2(8, 18 + oy), Vector2(-8, 18 + oy),
	])
	draw_colored_polygon(robe_pts, _tc(p["body"]))
	draw_rect(Rect2(1, 5 + oy, 6, 13), _tc(p["body_dk"]))
	draw_rect(Rect2(-7, 16 + oy, 16, 2), _tc(p["body_lt"]))
	draw_rect(Rect2(-5, 17 + oy, 2, 1), _tc(p["accent"]).lerp(Color.TRANSPARENT, 0.4))

	# Torso
	draw_rect(Rect2(-5, -6 + oy, 10, 12), _tc(p["body"]))
	draw_rect(Rect2(1, -6 + oy, 4, 12), _tc(p["body_dk"]))

	# Front arm
	draw_rect(Rect2(5, -4 + oy, 5, 12), _tc(p["body"]))
	draw_circle(Vector2(8, 9 + oy), 2.5, _tc(Color(0.5, 0.1, 0.8, 0.3)))
	draw_circle(Vector2(8, 9 + oy), 1.5, _tc(p["accent"]).lerp(Color.WHITE, 0.2))
	# Back arm
	draw_rect(Rect2(-8, -3 + oy, 4, 10), _tc(p["body_dk"]))

	# Staff (side)
	var staff_thrust := cast_anim * 5.0
	var soy := oy - staff_thrust
	draw_rect(Rect2(6, -22 + soy, 2, 28), _tc(p["horn"]))
	draw_rect(Rect2(4, -25 + soy, 2, 4), _tc(p["horn"]))
	draw_rect(Rect2(8, -25 + soy, 2, 4), _tc(p["horn"]))
	var fs := 1.0 + cast_anim * 1.2
	var fa := 0.5 + cast_anim * 0.5
	draw_circle(Vector2(7, -25 + soy), 3.0 * fs, _tc(Color(0.5, 0.1, 0.8, fa)))
	draw_circle(Vector2(7, -26 + soy), 2.0 * fs, _tc(Color(0.6, 0.2, 0.9, min(fa + 0.3, 1.0))))
	var fh := 4.0 + cast_anim * 6.0
	var flame := PackedVector2Array([
		Vector2(5.5 - cast_anim * 0.5, -27 + soy), Vector2(7, -27 - fh + soy), Vector2(8.5 + cast_anim * 0.5, -27 + soy),
	])
	draw_colored_polygon(flame, _tc(Color(0.6, 0.2, 0.9, 0.6 + cast_anim * 0.4)))

	# Head (hooded, side)
	draw_circle(Vector2(0, -12 + oy), 7.0, _tc(p["body"]))
	draw_circle(Vector2(2, -12 + oy), 5.0, _tc(p["body_dk"]))
	var hood := PackedVector2Array([
		Vector2(-3, -18 + oy), Vector2(3, -18 + oy), Vector2(1, -22 + oy),
	])
	draw_colored_polygon(hood, _tc(p["body"]))
	# Face shadow
	draw_circle(Vector2(-1, -11 + oy), 4.5, _tc(Color(0.03, 0.01, 0.03)))
	# Eye
	draw_rect(Rect2(-4, -13 + oy, 3, 2), _tc(p["eye"]))
	draw_circle(Vector2(-2, -12 + oy), 2.0, _tc(Color(0.5, 0.15, 0.8, 0.35)))

# ══════════════════════════════════════════════════════════════════════
# ABOMINATION — grotesque multi-headed horror, fits ~68px (hurtbox r=34)
# ══════════════════════════════════════════════════════════════════════
func _draw_abomination_dir() -> void:
	match facing:
		Facing.DOWN: _draw_abomination_front()
		Facing.UP: _draw_abomination_back()
		Facing.LEFT:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1)); _draw_abomination_side(); draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Facing.RIGHT: _draw_abomination_side()

func _draw_abomination_front() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()
	var teeth_c := Color(0.92, 0.88, 0.75)
	var guts_c := Color(0.45, 0.08, 0.12)
	var vein_c := Color(0.7, 0.15, 0.1, 0.7)

	# Dangling tendrils / intestines
	draw_line(Vector2(-18, 8 + oy), Vector2(-28, 22 + oy), _tc(guts_c), 2.5)
	draw_line(Vector2(-16, 10 + oy), Vector2(-24, 26 + oy), _tc(guts_c.lightened(0.1)), 2.0)
	draw_line(Vector2(18, 8 + oy), Vector2(28, 24 + oy), _tc(guts_c), 2.5)
	draw_line(Vector2(15, 12 + oy), Vector2(22, 28 + oy), _tc(guts_c.lightened(0.15)), 1.5)

	# 8 legs — mismatched, different lengths
	draw_rect(Rect2(-22, 16 + oy + lo, 6, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(-15, 18 + oy - lo, 5, 11), _tc(p["body"]))
	draw_rect(Rect2(-9, 20 + oy + lo * 0.7, 5, 9), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(-3, 19 + oy - lo * 0.5, 4, 10), _tc(p["body"]))
	draw_rect(Rect2(3, 20 + oy + lo * 0.7, 4, 9), _tc(p["body_dk"]))
	draw_rect(Rect2(9, 18 + oy - lo, 5, 11), _tc(p["body"]))
	draw_rect(Rect2(15, 16 + oy + lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(21, 19 + oy - lo * 0.5, 5, 10), _tc(p["body_dk"].darkened(0.2)))
	# Clawed feet
	draw_rect(Rect2(-23, 26 + oy + lo, 9, 4), _tc(p["horn"]))
	draw_rect(Rect2(-24, 25 + oy + lo, 2, 3), _tc(teeth_c))
	draw_rect(Rect2(-16, 27 + oy - lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(-10, 27 + oy + lo * 0.7, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(2, 27 + oy - lo * 0.5, 6, 4), _tc(p["horn"]))
	draw_rect(Rect2(8, 27 + oy - lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(14, 26 + oy + lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(20, 27 + oy - lo * 0.5, 8, 4), _tc(p["horn"]))
	draw_rect(Rect2(27, 26 + oy - lo * 0.5, 2, 3), _tc(teeth_c))

	# Central mass — bloated, lumpy
	draw_circle(Vector2(0, 6 + oy), 24.0, _tc(p["body"]))
	draw_circle(Vector2(-10, 0 + oy), 16.0, _tc(p["body_dk"]))
	draw_circle(Vector2(10, 0 + oy), 16.0, _tc(p["body_dk"]))
	draw_circle(Vector2(0, 12 + oy), 18.0, _tc(p["body_lt"]))
	draw_circle(Vector2(-6, 10 + oy), 8.0, _tc(p["body_dk"].darkened(0.1)))
	draw_circle(Vector2(8, 8 + oy), 7.0, _tc(p["body_dk"].darkened(0.15)))
	# Pulsing boils / tumors
	draw_circle(Vector2(-14, 8 + oy), 5.0, _tc(p["body_lt"].lightened(0.15)))
	draw_circle(Vector2(16, 4 + oy), 4.0, _tc(p["body_lt"].lightened(0.1)))
	draw_circle(Vector2(4, 16 + oy), 3.5, _tc(p["accent"].lightened(0.2)))
	# Seams / stitches
	draw_line(Vector2(-6, -14 + oy), Vector2(-12, 18 + oy), _tc(p["accent"]), 2.0)
	draw_line(Vector2(6, -14 + oy), Vector2(12, 18 + oy), _tc(p["accent"]), 2.0)
	draw_line(Vector2(-16, 4 + oy), Vector2(16, 4 + oy), _tc(p["accent"]), 1.5)
	# Veins
	draw_line(Vector2(-8, -4 + oy), Vector2(-18, 10 + oy), _tc(vein_c), 1.0)
	draw_line(Vector2(8, -4 + oy), Vector2(20, 8 + oy), _tc(vein_c), 1.0)
	draw_line(Vector2(0, 10 + oy), Vector2(-6, 20 + oy), _tc(vein_c), 1.0)

	# Belly mouth with teeth
	draw_rect(Rect2(-8, 8 + oy, 16, 6), _tc(guts_c))
	for tx in range(-7, 8, 3):
		draw_rect(Rect2(tx, 7 + oy, 2, 3), _tc(teeth_c))
		draw_rect(Rect2(tx, 12 + oy, 2, 3), _tc(teeth_c))

	# 6 arms — grotesque, varied
	# Left arm 1 (upper)
	draw_rect(Rect2(-28, -10 + oy, 8, 6), _tc(p["skin"]))
	draw_rect(Rect2(-34, -12 + oy, 7, 5), _tc(p["skin"]))
	draw_rect(Rect2(-36, -14 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(-34, -14 + oy, 2, 3), _tc(p["accent"]))
	# Left arm 2 (lower, bent)
	draw_rect(Rect2(-26, 2 + oy, 7, 5), _tc(p["skin"].darkened(0.1)))
	draw_rect(Rect2(-30, 6 + oy, 5, 8), _tc(p["skin"].darkened(0.1)))
	draw_rect(Rect2(-32, 12 + oy, 2, 3), _tc(p["accent"]))
	# Right arm 1 (upper)
	draw_rect(Rect2(20, -12 + oy, 8, 6), _tc(p["skin"]))
	draw_rect(Rect2(26, -16 + oy, 6, 7), _tc(p["skin"]))
	draw_rect(Rect2(30, -18 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(32, -18 + oy, 2, 3), _tc(p["accent"]))
	# Right arm 2 (mid, reaching forward)
	draw_rect(Rect2(22, 0 + oy, 10, 5), _tc(p["skin"].darkened(0.15)))
	draw_rect(Rect2(30, -2 + oy, 5, 4), _tc(p["skin"].darkened(0.15)))
	draw_rect(Rect2(33, -4 + oy, 2, 3), _tc(p["accent"]))
	# Top arm (reaching up from body)
	draw_rect(Rect2(-5, -22 + oy, 6, 10), _tc(p["skin"]))
	draw_rect(Rect2(-6, -30 + oy, 5, 9), _tc(p["skin"]))
	draw_rect(Rect2(-7, -33 + oy, 2, 4), _tc(p["accent"]))
	draw_rect(Rect2(-5, -33 + oy, 2, 4), _tc(p["accent"]))
	# Small vestigial arm (right side of body)
	draw_rect(Rect2(12, 12 + oy, 5, 4), _tc(p["skin"].darkened(0.2)))
	draw_rect(Rect2(16, 14 + oy, 3, 3), _tc(p["skin"].darkened(0.2)))

	# MAIN HEAD (center-top) — large, toothy maw
	draw_circle(Vector2(0, -14 + oy), 12.0, _tc(p["body"]))
	draw_rect(Rect2(-9, -19 + oy, 18, 4), _tc(p["body_dk"]))
	draw_rect(Rect2(-7, -17 + oy, 4, 4), _tc(p["eye"]))
	draw_rect(Rect2(3, -17 + oy, 4, 4), _tc(p["eye"]))
	# Third eye
	draw_rect(Rect2(-2, -20 + oy, 3, 3), _tc(p["eye"].lightened(0.2)))
	# Main mouth with teeth
	draw_rect(Rect2(-6, -7 + oy, 12, 4), _tc(p["body_dk"]))
	for tx in range(-5, 6, 2):
		draw_rect(Rect2(tx, -8 + oy, 2, 3), _tc(teeth_c))
		draw_rect(Rect2(tx, -5 + oy, 2, 3), _tc(teeth_c))

	# SECOND HEAD (left) — smaller, jaw agape
	draw_circle(Vector2(-18, -10 + oy), 8.0, _tc(p["body_lt"]))
	draw_rect(Rect2(-22, -13 + oy, 3, 3), _tc(p["eye"]))
	draw_rect(Rect2(-17, -13 + oy, 3, 3), _tc(p["eye"]))
	draw_rect(Rect2(-22, -5 + oy, 8, 3), _tc(p["body_dk"]))
	for tx in range(-21, -14, 2):
		draw_rect(Rect2(tx, -6 + oy, 2, 2), _tc(teeth_c))
		draw_rect(Rect2(tx, -4 + oy, 2, 2), _tc(teeth_c))

	# THIRD HEAD (right-low) — half-formed, fused into body
	draw_circle(Vector2(16, 0 + oy), 7.0, _tc(p["body"]))
	draw_rect(Rect2(13, -1 + oy, 3, 2), _tc(p["eye"]))
	draw_rect(Rect2(17, -1 + oy, 3, 2), _tc(p["eye"]))
	draw_rect(Rect2(13, 4 + oy, 7, 2), _tc(p["body_dk"]))
	draw_rect(Rect2(14, 3 + oy, 2, 2), _tc(teeth_c))
	draw_rect(Rect2(17, 3 + oy, 2, 2), _tc(teeth_c))

	# FOURTH HEAD (top-right) — tiny, vestigial
	draw_circle(Vector2(10, -18 + oy), 5.0, _tc(p["body_dk"]))
	draw_rect(Rect2(8, -20 + oy, 2, 2), _tc(p["eye"]))
	draw_rect(Rect2(11, -20 + oy, 2, 2), _tc(p["eye"]))
	draw_rect(Rect2(8, -16 + oy, 5, 2), _tc(p["body_dk"].darkened(0.2)))

	# Horns on main head
	draw_rect(Rect2(-12, -24 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(-13, -28 + oy, 3, 5), _tc(p["horn"].lightened(0.1)))
	draw_rect(Rect2(8, -24 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(10, -28 + oy, 3, 5), _tc(p["horn"].lightened(0.1)))
	# Horns on second head
	draw_rect(Rect2(-23, -17 + oy, 2, 5), _tc(p["horn"]))
	draw_rect(Rect2(-16, -17 + oy, 2, 5), _tc(p["horn"]))
	# Spike on fourth head
	draw_rect(Rect2(9, -23 + oy, 2, 4), _tc(p["horn"]))

func _draw_abomination_back() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()
	var guts_c := Color(0.45, 0.08, 0.12)
	var vein_c := Color(0.7, 0.15, 0.1, 0.7)

	# 8 legs
	draw_rect(Rect2(-22, 16 + oy + lo, 6, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(-15, 18 + oy - lo, 5, 11), _tc(p["body_dk"]))
	draw_rect(Rect2(-9, 20 + oy + lo * 0.7, 5, 9), _tc(p["body_dk"].darkened(0.1)))
	draw_rect(Rect2(-3, 19 + oy - lo * 0.5, 4, 10), _tc(p["body_dk"]))
	draw_rect(Rect2(3, 20 + oy + lo * 0.7, 4, 9), _tc(p["body_dk"]))
	draw_rect(Rect2(9, 18 + oy - lo, 5, 11), _tc(p["body_dk"]))
	draw_rect(Rect2(15, 16 + oy + lo, 5, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(21, 19 + oy - lo * 0.5, 5, 10), _tc(p["body_dk"].darkened(0.2)))
	draw_rect(Rect2(-23, 26 + oy + lo, 9, 4), _tc(p["horn"]))
	draw_rect(Rect2(14, 26 + oy + lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(20, 27 + oy - lo * 0.5, 8, 4), _tc(p["horn"]))

	# Central mass (darker from behind)
	draw_circle(Vector2(0, 6 + oy), 24.0, _tc(p["body_dk"]))
	draw_circle(Vector2(-10, 0 + oy), 16.0, _tc(p["body_dk"].darkened(0.1)))
	draw_circle(Vector2(10, 0 + oy), 16.0, _tc(p["body_dk"].darkened(0.1)))
	# Boils
	draw_circle(Vector2(-12, 10 + oy), 5.0, _tc(p["body_lt"].lightened(0.1)))
	draw_circle(Vector2(14, 6 + oy), 4.0, _tc(p["body_lt"].lightened(0.05)))
	draw_circle(Vector2(0, 16 + oy), 3.5, _tc(p["accent"].lightened(0.1)))
	# Spine ridges — thick, bony
	draw_line(Vector2(0, -14 + oy), Vector2(0, 20 + oy), _tc(p["accent"]), 3.0)
	draw_line(Vector2(-4, -10 + oy), Vector2(-4, 16 + oy), _tc(p["accent"]), 1.5)
	draw_line(Vector2(4, -10 + oy), Vector2(4, 16 + oy), _tc(p["accent"]), 1.5)
	# Veins
	draw_line(Vector2(-6, 0 + oy), Vector2(-18, 12 + oy), _tc(vein_c), 1.0)
	draw_line(Vector2(6, 0 + oy), Vector2(20, 10 + oy), _tc(vein_c), 1.0)
	# Exposed flesh patches
	draw_circle(Vector2(-8, 4 + oy), 4.0, _tc(guts_c))
	draw_circle(Vector2(10, 12 + oy), 3.5, _tc(guts_c))

	# Arms (from behind)
	draw_rect(Rect2(-28, -10 + oy, 8, 6), _tc(p["skin"]))
	draw_rect(Rect2(20, -12 + oy, 8, 6), _tc(p["skin"]))
	draw_rect(Rect2(-5, -22 + oy, 6, 10), _tc(p["skin"]))
	draw_rect(Rect2(-26, 2 + oy, 7, 5), _tc(p["skin"].darkened(0.1)))
	draw_rect(Rect2(22, 0 + oy, 10, 5), _tc(p["skin"].darkened(0.15)))

	# Heads (bumps from back)
	draw_circle(Vector2(0, -14 + oy), 12.0, _tc(p["body_dk"]))
	draw_circle(Vector2(-18, -10 + oy), 8.0, _tc(p["body_dk"]))
	draw_circle(Vector2(16, 0 + oy), 7.0, _tc(p["body_dk"]))
	draw_circle(Vector2(10, -18 + oy), 5.0, _tc(p["body_dk"].darkened(0.1)))
	# Horns
	draw_rect(Rect2(-12, -24 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(-13, -28 + oy, 3, 5), _tc(p["horn"]))
	draw_rect(Rect2(8, -24 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(10, -28 + oy, 3, 5), _tc(p["horn"]))
	draw_rect(Rect2(-23, -17 + oy, 2, 5), _tc(p["horn"]))
	draw_rect(Rect2(9, -23 + oy, 2, 4), _tc(p["horn"]))

func _draw_abomination_side() -> void:
	var p := _pal(); var oy := bob_y; var lo := _leg_offset()
	var teeth_c := Color(0.92, 0.88, 0.75)
	var guts_c := Color(0.45, 0.08, 0.12)
	var vein_c := Color(0.7, 0.15, 0.1, 0.7)

	# Back legs (4)
	draw_rect(Rect2(8, 16 + oy - lo, 6, 12), _tc(p["body_dk"].darkened(0.2)))
	draw_rect(Rect2(14, 18 + oy + lo, 5, 11), _tc(p["body_dk"].darkened(0.15)))
	draw_rect(Rect2(19, 17 + oy - lo * 0.5, 5, 10), _tc(p["body_dk"].darkened(0.25)))
	draw_rect(Rect2(7, 26 + oy - lo, 8, 4), _tc(p["horn"].darkened(0.1)))
	draw_rect(Rect2(13, 27 + oy + lo, 7, 4), _tc(p["horn"].darkened(0.1)))
	# Front legs (4)
	draw_rect(Rect2(-20, 16 + oy + lo, 6, 12), _tc(p["body_dk"]))
	draw_rect(Rect2(-13, 18 + oy - lo, 5, 11), _tc(p["body"]))
	draw_rect(Rect2(-7, 20 + oy + lo * 0.7, 5, 9), _tc(p["body_dk"]))
	draw_rect(Rect2(-2, 19 + oy - lo * 0.5, 4, 10), _tc(p["body"]))
	draw_rect(Rect2(-21, 26 + oy + lo, 9, 4), _tc(p["horn"]))
	draw_rect(Rect2(-14, 27 + oy - lo, 7, 4), _tc(p["horn"]))
	draw_rect(Rect2(-8, 27 + oy + lo * 0.7, 7, 4), _tc(p["horn"]))

	# Dangling tendril
	draw_line(Vector2(-8, 14 + oy), Vector2(-14, 28 + oy), _tc(guts_c), 2.0)

	# Central mass (side view — taller, lumpier)
	draw_circle(Vector2(0, 6 + oy), 22.0, _tc(p["body"]))
	draw_circle(Vector2(-8, 0 + oy), 14.0, _tc(p["body_dk"]))
	draw_circle(Vector2(8, 8 + oy), 14.0, _tc(p["body_lt"]))
	draw_circle(Vector2(-4, 14 + oy), 8.0, _tc(p["body_dk"].darkened(0.1)))
	# Boils
	draw_circle(Vector2(12, 2 + oy), 4.0, _tc(p["body_lt"].lightened(0.1)))
	draw_circle(Vector2(-10, 12 + oy), 3.5, _tc(p["accent"].lightened(0.15)))
	# Seams
	draw_line(Vector2(-4, -14 + oy), Vector2(-4, 20 + oy), _tc(p["accent"]), 2.0)
	draw_line(Vector2(4, -10 + oy), Vector2(8, 18 + oy), _tc(p["accent"]), 1.5)
	# Veins
	draw_line(Vector2(-6, 0 + oy), Vector2(-16, 10 + oy), _tc(vein_c), 1.0)
	draw_line(Vector2(6, 4 + oy), Vector2(16, 14 + oy), _tc(vein_c), 1.0)

	# Belly mouth (side view)
	draw_rect(Rect2(-6, 8 + oy, 10, 5), _tc(guts_c))
	for tx in range(-5, 4, 2):
		draw_rect(Rect2(tx, 7 + oy, 2, 2), _tc(teeth_c))
		draw_rect(Rect2(tx, 12 + oy, 2, 2), _tc(teeth_c))

	# Arms (side — 4 visible)
	draw_rect(Rect2(-24, -6 + oy, 8, 6), _tc(p["skin"]))
	draw_rect(Rect2(-30, -8 + oy, 7, 5), _tc(p["skin"]))
	draw_rect(Rect2(-32, -10 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(-30, -10 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(-22, 4 + oy, 6, 5), _tc(p["skin"].darkened(0.1)))
	draw_rect(Rect2(-26, 8 + oy, 5, 7), _tc(p["skin"].darkened(0.1)))
	draw_rect(Rect2(-28, 13 + oy, 2, 3), _tc(p["accent"]))
	draw_rect(Rect2(-4, -20 + oy, 6, 10), _tc(p["skin"]))
	draw_rect(Rect2(-5, -28 + oy, 5, 9), _tc(p["skin"]))
	draw_rect(Rect2(-6, -31 + oy, 2, 4), _tc(p["accent"]))
	draw_rect(Rect2(-4, -31 + oy, 2, 4), _tc(p["accent"]))
	draw_rect(Rect2(12, 0 + oy, 6, 5), _tc(p["skin"].darkened(0.2)))
	draw_rect(Rect2(16, 2 + oy, 4, 4), _tc(p["skin"].darkened(0.2)))

	# Main head (side) — big jaw with teeth
	draw_circle(Vector2(-4, -14 + oy), 10.0, _tc(p["body"]))
	draw_circle(Vector2(-8, -14 + oy), 8.0, _tc(p["body_dk"]))
	draw_circle(Vector2(0, -15 + oy), 7.0, _tc(p["body_lt"]))
	draw_rect(Rect2(-10, -17 + oy, 5, 4), _tc(p["eye"]))
	# Third eye
	draw_rect(Rect2(-4, -20 + oy, 3, 3), _tc(p["eye"].lightened(0.2)))
	# Mouth
	draw_rect(Rect2(-10, -8 + oy, 8, 3), _tc(p["body_dk"]))
	for tx in range(-9, -2, 2):
		draw_rect(Rect2(tx, -9 + oy, 2, 2), _tc(teeth_c))
		draw_rect(Rect2(tx, -7 + oy, 2, 2), _tc(teeth_c))
	draw_rect(Rect2(-8, -24 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(-9, -28 + oy, 3, 5), _tc(p["horn"].lightened(0.1)))

	# Second head (on top)
	draw_circle(Vector2(6, -12 + oy), 7.0, _tc(p["body_lt"]))
	draw_rect(Rect2(4, -14 + oy, 3, 3), _tc(p["eye"]))
	draw_rect(Rect2(8, -14 + oy, 2, 2), _tc(p["eye"]))
	draw_rect(Rect2(3, -8 + oy, 6, 2), _tc(p["body_dk"]))
	draw_rect(Rect2(4, -9 + oy, 2, 2), _tc(teeth_c))
	draw_rect(Rect2(7, -9 + oy, 2, 2), _tc(teeth_c))
	draw_rect(Rect2(4, -18 + oy, 2, 5), _tc(p["horn"]))

	# Third head (lower back)
	draw_circle(Vector2(16, 4 + oy), 6.0, _tc(p["body"]))
	draw_rect(Rect2(14, 3 + oy, 2, 2), _tc(p["eye"]))
	draw_rect(Rect2(17, 3 + oy, 2, 2), _tc(p["eye"]))
	draw_rect(Rect2(14, 7 + oy, 5, 2), _tc(p["body_dk"]))

	# Fourth head (vestigial, top-back)
	draw_circle(Vector2(12, -16 + oy), 4.0, _tc(p["body_dk"]))
	draw_rect(Rect2(11, -17 + oy, 2, 2), _tc(p["eye"]))
