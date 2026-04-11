extends Node2D

enum Facing { DOWN, UP, LEFT, RIGHT }
var facing: int = Facing.DOWN

# Colors (same as PlayerSprite.gd)
const COL_HELMET      := Color(0.40, 0.42, 0.50)
const COL_HELMET_DARK := Color(0.20, 0.22, 0.30)
const COL_VISOR_GLOW  := Color(0.4, 0.8, 1.0, 0.9)
const COL_ARMOR       := Color(0.15, 0.35, 0.85)
const COL_ARMOR_DARK  := Color(0.10, 0.25, 0.65)
const COL_ARMOR_LIGHT := Color(0.28, 0.50, 0.95)
const COL_SKIN        := Color(0.85, 0.70, 0.55)
const COL_BLADE       := Color(0.80, 0.83, 0.90)
const COL_BLADE_EDGE  := Color(0.92, 0.94, 0.98)
const COL_HILT        := Color(0.50, 0.35, 0.15)
const COL_GUARD       := Color(0.60, 0.55, 0.30)
const COL_BOOT        := Color(0.25, 0.18, 0.13)
const COL_BELT        := Color(0.50, 0.35, 0.12)

# Animated properties
var bob_y: float = 0.0
var arm_angle: float = 0.0
var hurt_flash: float = 0.0
var walk_cycle: float = 0.0  # 0 to 1, oscillates during walk

var _idle_tween: Tween
var _walk_tween: Tween
var _is_walking: bool = false

func _process(_d: float) -> void:
	queue_redraw()

func start_idle() -> void:
	_stop_walk()
	_kill_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "bob_y", -2.5, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "bob_y", 0.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func start_walk() -> void:
	if _is_walking:
		return
	_is_walking = true
	_kill_idle()
	_kill_walk()
	_walk_tween = create_tween().set_loops()
	_walk_tween.tween_property(self, "walk_cycle", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	_walk_tween.tween_property(self, "walk_cycle", 0.0, 0.25).set_trans(Tween.TRANS_SINE)

func _stop_walk() -> void:
	_is_walking = false
	_kill_walk()
	walk_cycle = 0.0

func _kill_idle() -> void:
	if _idle_tween and _idle_tween.is_valid(): _idle_tween.kill()
	_idle_tween = null
	bob_y = 0.0

func _kill_walk() -> void:
	if _walk_tween and _walk_tween.is_valid(): _walk_tween.kill()
	_walk_tween = null

func play_attack() -> void:
	var tw := create_tween()
	tw.tween_property(self, "arm_angle", -1.6, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "arm_angle", 0.7, 0.10).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "arm_angle", 0.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

func play_hurt() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "hurt_flash", 1.0, 0.06)
	await tw.finished
	var tw2 := create_tween()
	tw2.tween_property(self, "hurt_flash", 0.0, 0.2)
	await tw2.finished

func play_die() -> void:
	_kill_idle()
	_stop_walk()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color(1.0, 0.15, 0.1, 0.0), 0.65)
	tw.tween_property(self, "hurt_flash", 0.6, 0.15)
	await tw.finished
	visible = false

func set_facing_from_vec(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if dir.y > 0 else Facing.UP

func _tc(base: Color) -> Color:
	return base.lerp(Color(1.0, 0.12, 0.08), hurt_flash)

# Walk offset for legs
func _leg_offset() -> float:
	return (walk_cycle - 0.5) * 8.0  # -4 to +4

func _draw() -> void:
	match facing:
		Facing.DOWN:  _draw_front()
		Facing.UP:    _draw_back()
		Facing.LEFT:
			scale.x = -1
			_draw_side()
			scale.x = 1
		Facing.RIGHT: _draw_side()

# ── FRONT VIEW (ported from PlayerSprite.gd, recentered to 0,0) ──
func _draw_front() -> void:
	var oy := bob_y
	var lo := _leg_offset()

	# Left arm (behind body)
	draw_rect(Rect2(-24, -11 + oy, 10, 22), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-23, 9 + oy, 8, 5), _tc(COL_SKIN))

	# Legs
	draw_rect(Rect2(-12, 15 + oy + lo, 11, 34), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(1, 15 + oy - lo, 11, 34), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-10, 27 + oy + lo, 7, 3), _tc(COL_ARMOR))
	draw_rect(Rect2(3, 27 + oy - lo, 7, 3), _tc(COL_ARMOR))

	# Boots
	draw_rect(Rect2(-14, 45 + oy + lo, 15, 10), _tc(COL_BOOT))
	draw_rect(Rect2(-1, 45 + oy - lo, 15, 10), _tc(COL_BOOT))

	# Torso
	draw_rect(Rect2(-14, -21 + oy, 28, 36), _tc(COL_ARMOR))
	draw_rect(Rect2(-10, -18 + oy, 20, 4), _tc(COL_ARMOR_LIGHT))
	draw_line(Vector2(0, -18 + oy), Vector2(-8, -3 + oy), _tc(COL_ARMOR_LIGHT), 1.5)
	draw_line(Vector2(0, -18 + oy), Vector2(8, -3 + oy), _tc(COL_ARMOR_LIGHT), 1.5)

	# Belt
	draw_rect(Rect2(-16, 9 + oy, 32, 5), _tc(COL_BELT))
	draw_rect(Rect2(-3, 9 + oy, 6, 5), _tc(COL_GUARD))

	# Shoulders
	draw_rect(Rect2(-22, -21 + oy, 10, 12), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(12, -21 + oy, 10, 12), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(-22, -21 + oy, 10, 3), _tc(COL_ARMOR_LIGHT.lightened(0.2)))
	draw_rect(Rect2(12, -21 + oy, 10, 3), _tc(COL_ARMOR_LIGHT.lightened(0.2)))

	# Neck
	draw_rect(Rect2(-4, -25 + oy, 8, 5), _tc(COL_SKIN))

	# Head
	draw_circle(Vector2(0, -37 + oy), 14.0, _tc(COL_HELMET))
	draw_rect(Rect2(-2, -51 + oy, 4, 10), _tc(COL_HELMET.lightened(0.15)))
	draw_rect(Rect2(-10, -39 + oy, 20, 7), _tc(COL_HELMET_DARK))
	draw_rect(Rect2(-7, -37 + oy, 5, 3), _tc(COL_VISOR_GLOW))
	draw_rect(Rect2(2, -37 + oy, 5, 3), _tc(COL_VISOR_GLOW))

	# Right arm + sword
	var shoulder := Vector2(17, -17 + oy)
	draw_set_transform(shoulder, arm_angle, Vector2.ONE)
	draw_rect(Rect2(-5, 0, 10, 14), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-4, 13, 8, 12), _tc(COL_ARMOR))
	draw_rect(Rect2(-3, 23, 6, 5), _tc(COL_SKIN))
	draw_rect(Rect2(-2, 19, 4, 9), _tc(COL_HILT))
	draw_rect(Rect2(-6, 17, 12, 3), _tc(COL_GUARD))
	draw_rect(Rect2(-1.5, -16, 3, 34), _tc(COL_BLADE))
	draw_rect(Rect2(0, -16, 1, 34), _tc(COL_BLADE_EDGE))
	draw_rect(Rect2(-1, -20, 2, 5), _tc(COL_BLADE_EDGE))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── BACK VIEW ──
func _draw_back() -> void:
	var oy := bob_y
	var lo := _leg_offset()

	# Legs
	draw_rect(Rect2(-12, 15 + oy + lo, 11, 34), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(1, 15 + oy - lo, 11, 34), _tc(COL_ARMOR_DARK))
	# Boots
	draw_rect(Rect2(-14, 45 + oy + lo, 15, 10), _tc(COL_BOOT))
	draw_rect(Rect2(-1, 45 + oy - lo, 15, 10), _tc(COL_BOOT))

	# Torso back plate
	draw_rect(Rect2(-14, -21 + oy, 28, 36), _tc(COL_ARMOR_DARK))
	# Spine line
	draw_line(Vector2(0, -18 + oy), Vector2(0, 12 + oy), _tc(COL_ARMOR.darkened(0.2)), 2.0)
	# Back plate edges
	draw_rect(Rect2(-14, -21 + oy, 3, 36), _tc(COL_ARMOR))
	draw_rect(Rect2(11, -21 + oy, 3, 36), _tc(COL_ARMOR))

	# Belt
	draw_rect(Rect2(-16, 9 + oy, 32, 5), _tc(COL_BELT))

	# Shoulders
	draw_rect(Rect2(-22, -21 + oy, 10, 12), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(12, -21 + oy, 10, 12), _tc(COL_ARMOR_LIGHT))

	# Arms behind
	draw_rect(Rect2(-24, -11 + oy, 10, 22), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(14, -11 + oy, 10, 22), _tc(COL_ARMOR_DARK))

	# Neck
	draw_rect(Rect2(-4, -25 + oy, 8, 5), _tc(COL_SKIN))

	# Head back — helmet rear
	draw_circle(Vector2(0, -37 + oy), 14.0, _tc(COL_HELMET))
	draw_rect(Rect2(-2, -51 + oy, 4, 10), _tc(COL_HELMET.lightened(0.15)))
	# Helmet back detail
	draw_rect(Rect2(-8, -38 + oy, 16, 6), _tc(COL_HELMET_DARK))

	# Sword on back (diagonal)
	draw_set_transform(Vector2(8, -15 + oy), 0.2, Vector2.ONE)
	draw_rect(Rect2(-1.5, -20, 3, 34), _tc(COL_BLADE))
	draw_rect(Rect2(-5, 12, 10, 3), _tc(COL_GUARD))
	draw_rect(Rect2(-1.5, 14, 3, 8), _tc(COL_HILT))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── SIDE VIEW (drawn facing right, flipped for left) ──
func _draw_side() -> void:
	var oy := bob_y
	var lo := _leg_offset()

	# Back leg
	draw_rect(Rect2(-4, 15 + oy - lo, 11, 34), _tc(COL_ARMOR_DARK.darkened(0.15)))
	draw_rect(Rect2(-6, 45 + oy - lo, 14, 10), _tc(COL_BOOT.darkened(0.1)))

	# Front leg
	draw_rect(Rect2(-4, 15 + oy + lo, 11, 34), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-6, 45 + oy + lo, 14, 10), _tc(COL_BOOT))

	# Torso (narrower from side)
	draw_rect(Rect2(-8, -21 + oy, 18, 36), _tc(COL_ARMOR))
	draw_rect(Rect2(-8, -21 + oy, 4, 36), _tc(COL_ARMOR_DARK))
	# Shoulder pad
	draw_rect(Rect2(6, -21 + oy, 8, 12), _tc(COL_ARMOR_LIGHT))

	# Belt
	draw_rect(Rect2(-10, 9 + oy, 22, 5), _tc(COL_BELT))

	# Neck
	draw_rect(Rect2(-2, -25 + oy, 6, 5), _tc(COL_SKIN))

	# Head (side profile)
	draw_circle(Vector2(2, -37 + oy), 13.0, _tc(COL_HELMET))
	# Visor side
	draw_rect(Rect2(2, -39 + oy, 14, 6), _tc(COL_HELMET_DARK))
	# Eye
	draw_rect(Rect2(8, -38 + oy, 5, 3), _tc(COL_VISOR_GLOW))
	# Crest
	draw_rect(Rect2(0, -51 + oy, 4, 10), _tc(COL_HELMET.lightened(0.15)))

	# Arm + sword
	var shoulder := Vector2(10, -17 + oy)
	draw_set_transform(shoulder, arm_angle, Vector2.ONE)
	draw_rect(Rect2(-4, 0, 8, 12), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-3, 11, 7, 10), _tc(COL_ARMOR))
	draw_rect(Rect2(-2, 19, 5, 4), _tc(COL_SKIN))
	draw_rect(Rect2(-1.5, 16, 3, 8), _tc(COL_HILT))
	draw_rect(Rect2(-5, 14, 10, 3), _tc(COL_GUARD))
	draw_rect(Rect2(-1.5, -16, 3, 30), _tc(COL_BLADE))
	draw_rect(Rect2(0, -16, 1, 30), _tc(COL_BLADE_EDGE))
	draw_rect(Rect2(-1, -19, 2, 4), _tc(COL_BLADE_EDGE))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
