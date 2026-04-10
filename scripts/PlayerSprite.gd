class_name PlayerSprite
extends Control

# ── Colors ───────────────────────────────────────────────────────────────
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

# ── Animated properties ──────────────────────────────────────────────────
var bob_y: float = 0.0
var arm_angle: float = 0.0
var hurt_flash: float = 0.0
var hurt_offset: float = 0.0

var _idle_tween: Tween

# ── Lifecycle ────────────────────────────────────────────────────────────
func _init() -> void:
	custom_minimum_size = Vector2(90, 120)

func _ready() -> void:
	_start_idle()

func _process(_delta: float) -> void:
	queue_redraw()

# ── Idle animation (looping breathing bob) ───────────────────────────────
func _start_idle() -> void:
	_kill_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "bob_y", -2.5, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "bob_y", 0.0, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _kill_idle() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null
	bob_y = 0.0

# ── Attack animation (sword swing) ──────────────────────────────────────
func play_attack() -> void:
	_kill_idle()
	var tw := create_tween()
	# Wind up — arm swings back
	tw.tween_property(self, "arm_angle", -1.6, 0.10) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	# Slash forward
	tw.tween_property(self, "arm_angle", 0.7, 0.14) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Return to rest
	tw.tween_property(self, "arm_angle", 0.0, 0.16) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	_start_idle()

# ── Hurt animation (red flash + recoil) ─────────────────────────────────
func play_hurt() -> void:
	_kill_idle()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "hurt_flash", 1.0, 0.06)
	tw.tween_property(self, "hurt_offset", -10.0, 0.06)
	await tw.finished
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(self, "hurt_flash", 0.0, 0.25)
	tw2.tween_property(self, "hurt_offset", 0.0, 0.25) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_start_idle()

# ── Death animation (topple over + fade) ────────────────────────────────
func play_die() -> void:
	_kill_idle()
	hurt_flash = 0.0
	hurt_offset = 0.0
	pivot_offset = Vector2(45, 110)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "rotation", 1.4, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate", Color(1.0, 0.15, 0.1, 0.0), 0.65)
	tw.tween_property(self, "hurt_flash", 0.6, 0.15)
	await tw.finished
	visible = false

# ── Color helper — blend with red during hurt ───────────────────────────
func _tc(base: Color) -> Color:
	return base.lerp(Color(1.0, 0.12, 0.08), hurt_flash)

# ── Draw ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	var ox := hurt_offset
	var oy := bob_y
	var cx := 45.0 + ox

	# ── Left arm (behind body) ──
	draw_rect(Rect2(cx - 24, 44 + oy, 10, 22), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(cx - 23, 64 + oy, 8, 5), _tc(COL_SKIN))

	# ── Legs ──
	draw_rect(Rect2(cx - 12, 70 + oy, 11, 34), _tc(COL_ARMOR_DARK))
	draw_rect(Rect2(cx + 1, 70 + oy, 11, 34), _tc(COL_ARMOR_DARK))
	# Knee guards
	draw_rect(Rect2(cx - 10, 82 + oy, 7, 3), _tc(COL_ARMOR))
	draw_rect(Rect2(cx + 3, 82 + oy, 7, 3), _tc(COL_ARMOR))

	# ── Boots ──
	draw_rect(Rect2(cx - 14, 100 + oy, 15, 10), _tc(COL_BOOT))
	draw_rect(Rect2(cx - 1, 100 + oy, 15, 10), _tc(COL_BOOT))

	# ── Body / torso armor ──
	draw_rect(Rect2(cx - 14, 34 + oy, 28, 36), _tc(COL_ARMOR))
	# Chest plate highlight
	draw_rect(Rect2(cx - 10, 37 + oy, 20, 4), _tc(COL_ARMOR_LIGHT))
	# Chest V-detail
	draw_line(Vector2(cx, 37 + oy), Vector2(cx - 8, 52 + oy), _tc(COL_ARMOR_LIGHT), 1.5)
	draw_line(Vector2(cx, 37 + oy), Vector2(cx + 8, 52 + oy), _tc(COL_ARMOR_LIGHT), 1.5)

	# ── Belt ──
	draw_rect(Rect2(cx - 16, 64 + oy, 32, 5), _tc(COL_BELT))
	draw_rect(Rect2(cx - 3, 64 + oy, 6, 5), _tc(COL_GUARD))   # buckle

	# ── Shoulder pads ──
	draw_rect(Rect2(cx - 22, 34 + oy, 10, 12), _tc(COL_ARMOR_LIGHT))
	draw_rect(Rect2(cx + 12, 34 + oy, 10, 12), _tc(COL_ARMOR_LIGHT))
	# Top-edge highlight
	draw_rect(Rect2(cx - 22, 34 + oy, 10, 3), _tc(COL_ARMOR_LIGHT.lightened(0.2)))
	draw_rect(Rect2(cx + 12, 34 + oy, 10, 3), _tc(COL_ARMOR_LIGHT.lightened(0.2)))

	# ── Neck ──
	draw_rect(Rect2(cx - 4, 30 + oy, 8, 5), _tc(COL_SKIN))

	# ── Head / helmet ──
	draw_circle(Vector2(cx, 18 + oy), 14.0, _tc(COL_HELMET))
	# Helmet crest
	draw_rect(Rect2(cx - 2, 4 + oy, 4, 10), _tc(COL_HELMET.lightened(0.15)))
	# Visor
	draw_rect(Rect2(cx - 10, 16 + oy, 20, 7), _tc(COL_HELMET_DARK))
	# Eye glow
	draw_rect(Rect2(cx - 7, 18 + oy, 5, 3), _tc(COL_VISOR_GLOW))
	draw_rect(Rect2(cx + 2, 18 + oy, 5, 3), _tc(COL_VISOR_GLOW))

	# ── Right arm + sword (rotated around shoulder pivot) ──
	var shoulder := Vector2(cx + 17, 38 + oy)
	draw_set_transform(shoulder, arm_angle, Vector2.ONE)
	# Upper arm
	draw_rect(Rect2(-5, 0, 10, 14), _tc(COL_ARMOR_DARK))
	# Forearm
	draw_rect(Rect2(-4, 13, 8, 12), _tc(COL_ARMOR))
	# Hand
	draw_rect(Rect2(-3, 23, 6, 5), _tc(COL_SKIN))
	# Sword hilt
	draw_rect(Rect2(-2, 19, 4, 9), _tc(COL_HILT))
	# Crossguard
	draw_rect(Rect2(-6, 17, 12, 3), _tc(COL_GUARD))
	# Blade
	draw_rect(Rect2(-1.5, -16, 3, 34), _tc(COL_BLADE))
	# Blade edge highlight
	draw_rect(Rect2(0, -16, 1, 34), _tc(COL_BLADE_EDGE))
	# Blade tip
	draw_rect(Rect2(-1, -20, 2, 5), _tc(COL_BLADE_EDGE))
	# Reset transform
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
