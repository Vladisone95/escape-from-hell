extends Node2D

enum Facing { DOWN, UP, LEFT, RIGHT }
var facing: int = Facing.DOWN

# Colors
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
var walk_cycle: float = 0.0

var _idle_tween: Tween
var _is_walking: bool = false
var _walk_phase: float = 0.0  # continuous phase for smooth sine-wave walk

const WALK_SPEED: float = 10.0  # radians/sec for walk cycle
const WALK_AMPLITUDE: float = 1.0
const WALK_DECAY_SPEED: float = 8.0  # how fast walk_cycle decays to 0 when stopping

func _process(d: float) -> void:
	if _is_walking:
		_walk_phase += d * WALK_SPEED
		walk_cycle = 0.5 + 0.5 * sin(_walk_phase)
	else:
		# Smoothly decay walk_cycle to 0.5 (neutral leg position) then to 0
		if absf(walk_cycle) > 0.01:
			walk_cycle = move_toward(walk_cycle, 0.5, d * WALK_DECAY_SPEED)
			if absf(walk_cycle - 0.5) < 0.02:
				walk_cycle = 0.0
	queue_redraw()

func start_idle() -> void:
	_stop_walk()
	_kill_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "bob_y", -1.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "bob_y", 0.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func start_walk() -> void:
	if _is_walking:
		return
	_is_walking = true
	_kill_idle()

func _stop_walk() -> void:
	_is_walking = false

func _kill_idle() -> void:
	if _idle_tween and _idle_tween.is_valid(): _idle_tween.kill()
	_idle_tween = null
	bob_y = 0.0

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
	# Hysteresis: bias toward current facing to prevent flip-flopping near diagonals
	var ax := absf(dir.x)
	var ay := absf(dir.y)
	var is_currently_horizontal := (facing == Facing.LEFT or facing == Facing.RIGHT)
	# Require ~55% dominance in the other axis to switch orientation
	var threshold := 1.3
	if is_currently_horizontal:
		# Currently horizontal — only switch to vertical if y clearly dominates
		if ay > ax * threshold:
			facing = Facing.DOWN if dir.y > 0 else Facing.UP
		elif ax > 0.01:
			facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		# Currently vertical — only switch to horizontal if x clearly dominates
		if ax > ay * threshold:
			facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
		elif ay > 0.01:
			facing = Facing.DOWN if dir.y > 0 else Facing.UP

func _tc(base: Color) -> Color:
	return base.lerp(Color(1.0, 0.12, 0.08), hurt_flash)

func _leg_offset() -> float:
	return (walk_cycle - 0.5) * 3.0

func _draw() -> void:
	match facing:
		Facing.DOWN:  _draw_front()
		Facing.UP:    _draw_back()
		Facing.LEFT:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
			_draw_side(true)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Facing.RIGHT: _draw_side(false)

# ── FRONT VIEW — chibi proportions, fits within ~32px diameter ──
func _draw_front() -> void:
	var oy := bob_y
	var lo := _leg_offset()

	# Left arm (behind body)
	draw_rect(Rect2(-14, -3 + oy, 5, 12), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-14, 8 + oy, 4, 3), _tc(COL_SKIN))

	# Legs
	draw_rect(Rect2(-7, 10 + oy + lo, 6, 8), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(1, 10 + oy - lo, 6, 8), _tc(COL_ARMOR_DARK))

	# Boots
	draw_rect(Rect2(-8, 16 + oy + lo, 8, 4), _tc(COL_BOOT))
	draw_rect(Rect2(0, 16 + oy - lo, 8, 4), _tc(COL_BOOT))

	# Torso
	draw_rect(Rect2(-9, -6 + oy, 18, 16), _tc(COL_ARMOR))
	draw_rect(Rect2(-7, -4 + oy, 14, 3), _tc(COL_ARMOR_LIGHT))
	# V-detail on chest
	draw_line(Vector2(0, -4 + oy), Vector2(-5, 4 + oy), _tc(COL_ARMOR_LIGHT), 1.0)
	draw_line(Vector2(0, -4 + oy), Vector2(5, 4 + oy), _tc(COL_ARMOR_LIGHT), 1.0)

	# Belt
	draw_rect(Rect2(-10, 7 + oy, 20, 3), _tc(COL_BELT))
	draw_rect(Rect2(-2, 7 + oy, 4, 3), _tc(COL_GUARD))

	# Shoulders
	draw_rect(Rect2(-13, -6 + oy, 6, 7), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(7, -6 + oy, 6, 7), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(-13, -6 + oy, 6, 2), _tc(COL_ARMOR_LIGHT.lightened(0.2)))
	draw_rect(Rect2(7, -6 + oy, 6, 2), _tc(COL_ARMOR_LIGHT.lightened(0.2)))

	# Head (large chibi head)
	draw_circle(Vector2(0, -12 + oy), 9.0, _tc(COL_HELMET))
	draw_rect(Rect2(-1, -21 + oy, 2, 5), _tc(COL_HELMET.lightened(0.15)))  # crest
	draw_rect(Rect2(-7, -14 + oy, 14, 5), _tc(COL_HELMET_DARK))  # visor band
	draw_rect(Rect2(-5, -13 + oy, 4, 2), _tc(COL_VISOR_GLOW))  # left eye
	draw_rect(Rect2(1, -13 + oy, 4, 2), _tc(COL_VISOR_GLOW))   # right eye

	# Right arm + sword
	var shoulder := Vector2(10, -4 + oy)
	draw_set_transform(shoulder, arm_angle, Vector2.ONE)
	draw_rect(Rect2(-3, 0, 6, 8), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-2, 7, 5, 6), _tc(COL_ARMOR))
	draw_rect(Rect2(-2, 12, 4, 3), _tc(COL_SKIN))
	draw_rect(Rect2(-1, 10, 3, 6), _tc(COL_HILT))
	draw_rect(Rect2(-4, 9, 8, 2), _tc(COL_GUARD))
	draw_rect(Rect2(-1, -10, 2, 20), _tc(COL_BLADE))
	draw_rect(Rect2(0, -10, 1, 20), _tc(COL_BLADE_EDGE))
	draw_rect(Rect2(-0.5, -13, 1, 3), _tc(COL_BLADE_EDGE))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ── BACK VIEW ──
func _draw_back() -> void:
	var oy := bob_y
	var lo := _leg_offset()

	# Sword arm behind
	var shoulder := Vector2(10, -4 + oy)
	draw_set_transform(shoulder, arm_angle, Vector2.ONE)
	draw_rect(Rect2(-3, 0, 6, 8), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-2, 7, 5, 6), _tc(COL_ARMOR))
	draw_rect(Rect2(-2, 12, 4, 3), _tc(COL_SKIN))
	draw_rect(Rect2(-1, 10, 3, 6), _tc(COL_HILT))
	draw_rect(Rect2(-4, 9, 8, 2), _tc(COL_GUARD))
	draw_rect(Rect2(-1, -10, 2, 18), _tc(COL_BLADE))
	draw_rect(Rect2(0, -10, 1, 18), _tc(COL_BLADE_EDGE))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Legs
	draw_rect(Rect2(-7, 10 + oy + lo, 6, 8), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(1, 10 + oy - lo, 6, 8), _tc(COL_ARMOR_DARK))
	# Boots
	draw_rect(Rect2(-8, 16 + oy + lo, 8, 4), _tc(COL_BOOT))
	draw_rect(Rect2(0, 16 + oy - lo, 8, 4), _tc(COL_BOOT))

	# Torso back plate
	draw_rect(Rect2(-9, -6 + oy, 18, 16), _tc(COL_ARMOR_DARK))
	draw_line(Vector2(0, -4 + oy), Vector2(0, 8 + oy), _tc(COL_ARMOR.darkened(0.2)), 1.5)
	draw_rect(Rect2(-9, -6 + oy, 2, 16), _tc(COL_ARMOR))
	draw_rect(Rect2(7, -6 + oy, 2, 16), _tc(COL_ARMOR))

	# Belt
	draw_rect(Rect2(-10, 7 + oy, 20, 3), _tc(COL_BELT))

	# Shoulders
	draw_rect(Rect2(-13, -6 + oy, 6, 7), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(7, -6 + oy, 6, 7), _tc(COL_ARMOR_LIGHT))

	# Arms behind
	draw_rect(Rect2(-14, -3 + oy, 5, 12), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(9, -3 + oy, 5, 12), _tc(COL_ARMOR_DARK))

	# Shield on back
	draw_rect(Rect2(-5, -3 + oy, 10, 12), _tc(COL_ARMOR))
	draw_rect(Rect2(-4, -2 + oy, 8, 10), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(-1, 1 + oy, 2, 4), _tc(COL_GUARD))

	# Head back
	draw_circle(Vector2(0, -12 + oy), 9.0, _tc(COL_HELMET))
	draw_rect(Rect2(-1, -21 + oy, 2, 5), _tc(COL_HELMET.lightened(0.15)))
	draw_rect(Rect2(-6, -14 + oy, 12, 4), _tc(COL_HELMET_DARK))

# ── SIDE VIEW (drawn facing right, flipped for left) ──
func _draw_side(flipped: bool = false) -> void:
	var oy := bob_y
	var lo := _leg_offset()

	# Shield on back arm (behind body)
	draw_rect(Rect2(-10, -1 + oy, 5, 10), _tc(COL_ARMOR))
	draw_rect(Rect2(-9, 0 + oy, 3, 8), _tc(COL_ARMOR_LIGHT))

	# Back leg
	draw_rect(Rect2(-3, 10 + oy - lo, 6, 8), _tc(COL_ARMOR_DARK.darkened(0.15)))
	draw_rect(Rect2(-4, 16 + oy - lo, 8, 4), _tc(COL_BOOT.darkened(0.1)))

	# Front leg
	draw_rect(Rect2(-3, 10 + oy + lo, 6, 8), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-4, 16 + oy + lo, 8, 4), _tc(COL_BOOT))

	# Torso (narrower from side)
	draw_rect(Rect2(-5, -6 + oy, 5, 16), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(0, -6 + oy, 6, 16), _tc(COL_ARMOR))
	draw_rect(Rect2(5, -5 + oy, 1, 14), _tc(COL_ARMOR_LIGHT))
	# Shoulder pad
	draw_rect(Rect2(3, -6 + oy, 5, 7), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(3, -6 + oy, 5, 2), _tc(COL_ARMOR_LIGHT.lightened(0.2)))

	# Belt
	draw_rect(Rect2(-6, 7 + oy, 14, 3), _tc(COL_BELT))
	draw_rect(Rect2(4, 7 + oy, 3, 3), _tc(COL_GUARD))

	# Head (side profile)
	draw_circle(Vector2(1, -12 + oy), 8.0, _tc(COL_HELMET))
	draw_circle(Vector2(-2, -12 + oy), 6.0, _tc(COL_HELMET_DARK.lerp(COL_HELMET, 0.5)))
	draw_circle(Vector2(3, -13 + oy), 6.0, _tc(COL_HELMET.lightened(0.08)))
	draw_rect(Rect2(1, -15 + oy, 10, 4), _tc(COL_HELMET_DARK))  # visor
	draw_rect(Rect2(7, -14 + oy, 3, 2), _tc(COL_VISOR_GLOW))    # eye glow
	draw_rect(Rect2(4, -10 + oy, 5, 2), _tc(COL_HELMET_DARK))    # chin guard
	draw_rect(Rect2(0, -21 + oy, 2, 6), _tc(COL_HELMET.lightened(0.15)))  # crest

	# Sword arm + sword
	var sword_shoulder: Vector2
	var sword_scale: Vector2
	var sword_angle: float
	if flipped:
		sword_shoulder = Vector2(-6, -4 + oy)
		sword_angle = -arm_angle
		sword_scale = Vector2(-1, 1)
	else:
		sword_shoulder = Vector2(6, -4 + oy)
		sword_angle = arm_angle
		sword_scale = Vector2.ONE
	draw_set_transform(sword_shoulder, sword_angle, sword_scale)
	draw_rect(Rect2(-2, 0, 5, 8), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(-2, 7, 4, 6), _tc(COL_ARMOR))
	draw_rect(Rect2(-1, 12, 3, 3), _tc(COL_SKIN))
	draw_rect(Rect2(-1, 10, 2, 5), _tc(COL_HILT))
	draw_rect(Rect2(-3, 9, 7, 2), _tc(COL_GUARD))
	draw_rect(Rect2(-1, -10, 2, 20), _tc(COL_BLADE))
	draw_rect(Rect2(0, -10, 1, 20), _tc(COL_BLADE_EDGE))
	draw_rect(Rect2(-0.5, -12, 1, 3), _tc(COL_BLADE_EDGE))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
