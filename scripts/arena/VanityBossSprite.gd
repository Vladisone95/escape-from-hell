extends Node2D
# ─────────────────────────────────────────────────────────────
# VanityBossSprite — Demon of Vanity boss sprite
# Massive stationary female demon with 20 arms holding vanity items.
# Front-view only. Drawn at ~160px local radius (scale 2 → ~640px on screen).
# ─────────────────────────────────────────────────────────────

var bob_y: float = 0.0
var hurt_flash: float = 0.0
var cast_anim: float = 0.0
var _arm_sway: float = 0.0

var _idle_tween: Tween
var _sway_tween: Tween

# Colors — deep red demonic skin, grotesque tones
const SKIN := Color(0.72, 0.22, 0.18)       # demon red skin
const SKIN_DK := Color(0.50, 0.12, 0.10)    # dark creases
const SKIN_LT := Color(0.85, 0.35, 0.28)    # highlights
const SKIN_VEIN := Color(0.40, 0.08, 0.15)  # veins/stretch marks
const DRESS := Color(0.45, 0.05, 0.30)      # dark crimson/purple robe
const DRESS_LT := Color(0.60, 0.12, 0.40)
const DRESS_DK := Color(0.30, 0.02, 0.18)
const GOLD := Color(0.90, 0.75, 0.20)
const GOLD_DK := Color(0.70, 0.55, 0.10)
const WIG := Color(0.95, 0.88, 0.25)
const WIG_DK := Color(0.80, 0.70, 0.15)
const WIG_LT := Color(1.0, 0.95, 0.50)
const BLUSH := Color(0.95, 0.35, 0.40)
const LIPS := Color(0.90, 0.08, 0.18)
const EYE_SHADOW := Color(0.45, 0.10, 0.55)
const EYE_GREEN := Color(0.30, 0.85, 0.15)  # sickly green demon eyes
const EYE_WHITE := Color(0.90, 0.85, 0.75)  # yellowish sclera
const MIRROR_GLASS := Color(0.70, 0.82, 0.92)
const MIRROR_FRAME := Color(0.85, 0.70, 0.15)
const NAIL_POLISH := Color(0.90, 0.10, 0.30)
const COMB_C := Color(0.80, 0.60, 0.20)
const BRUSH_HANDLE := Color(0.60, 0.35, 0.20)
const BRUSH_TIP := Color(0.85, 0.50, 0.60)
const LIPSTICK_TUBE := Color(0.20, 0.20, 0.22)
const HORN_C := Color(0.25, 0.05, 0.05)
const HORN_LT := Color(0.45, 0.15, 0.10)
const HORN_TIP := Color(0.15, 0.02, 0.02)
const BELLY_FOLD := Color(0.38, 0.08, 0.08)  # deep crease color
const NAVEL := Color(0.30, 0.06, 0.06)       # belly button shadow

# Arm definitions: angle (radians from top center going clockwise), length, item
# Items: "mirror", "comb", "nail_polish", "brush", "lipstick", "powder", "perfume", "empty"
const ARM_DATA := [
	# Left side arms (negative x, top to bottom)
	{ "angle": -2.6, "len": 100, "item": "mirror" },
	{ "angle": -2.3, "len": 90, "item": "comb" },
	{ "angle": -2.0, "len": 105, "item": "nail_polish" },
	{ "angle": -1.7, "len": 85, "item": "brush" },
	{ "angle": -1.4, "len": 95, "item": "mirror" },
	{ "angle": -1.1, "len": 80, "item": "lipstick" },
	{ "angle": -0.8, "len": 100, "item": "mirror" },
	{ "angle": -0.5, "len": 90, "item": "powder" },
	{ "angle": -0.2, "len": 85, "item": "comb" },
	{ "angle": 0.0, "len": 75, "item": "perfume" },
	# Right side arms (positive x, top to bottom)
	{ "angle": 0.2, "len": 85, "item": "mirror" },
	{ "angle": 0.5, "len": 90, "item": "nail_polish" },
	{ "angle": 0.8, "len": 100, "item": "mirror" },
	{ "angle": 1.1, "len": 80, "item": "brush" },
	{ "angle": 1.4, "len": 95, "item": "mirror" },
	{ "angle": 1.7, "len": 85, "item": "comb" },
	{ "angle": 2.0, "len": 105, "item": "mirror" },
	{ "angle": 2.3, "len": 90, "item": "lipstick" },
	{ "angle": 2.6, "len": 100, "item": "nail_polish" },
	{ "angle": 2.9, "len": 80, "item": "mirror" },
]

func _tc(base: Color) -> Color:
	return base.lerp(Color(1.0, 1.0, 1.0), hurt_flash * 0.7)

func _process(_delta: float) -> void:
	queue_redraw()

# ── Interface methods (called by EnemyBody.gd) ──────────────

func start_idle() -> void:
	_kill_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "bob_y", -3.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "bob_y", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_kill_sway()
	_sway_tween = create_tween().set_loops()
	_sway_tween.tween_property(self, "_arm_sway", 1.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sway_tween.tween_property(self, "_arm_sway", 0.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func start_walk() -> void:
	pass  # stationary boss

func _stop_walk() -> void:
	pass

func play_cast() -> void:
	var tw := create_tween()
	tw.tween_property(self, "cast_anim", 1.0, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(self, "cast_anim", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

func play_hurt() -> void:
	var tw := create_tween()
	tw.tween_property(self, "hurt_flash", 1.0, 0.06)
	tw.chain().tween_property(self, "hurt_flash", 0.0, 0.2)
	await tw.finished

func play_die() -> void:
	_kill_idle()
	_kill_sway()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color(1.0, 0.15, 0.1, 0.0), 0.5)
	tw.tween_property(self, "hurt_flash", 0.8, 0.1)
	await tw.finished
	visible = false

func set_facing_from_vec(_dir: Vector2) -> void:
	pass  # always front-facing

func _kill_idle() -> void:
	if _idle_tween and _idle_tween.is_valid(): _idle_tween.kill()
	_idle_tween = null; bob_y = 0.0

func _kill_sway() -> void:
	if _sway_tween and _sway_tween.is_valid(): _sway_tween.kill()
	_sway_tween = null

# ── Drawing ──────────────────────────────────────────────────

func _draw() -> void:
	_draw_shadow()
	_draw_arms_back()
	_draw_body()
	_draw_arms_front()
	_draw_head()
	_draw_cast_flash()

# ── Shadow ───────────────────────────────────────────────────

func _draw_shadow() -> void:
	var sy := 135.0 + bob_y
	var shadow_c := Color(0.0, 0.0, 0.0, 0.25)
	# Ellipse approximation with polygon
	var pts: PackedVector2Array = []
	for i in range(24):
		var a := TAU * i / 24.0
		pts.append(Vector2(cos(a) * 130.0, sin(a) * 30.0 + sy))
	draw_colored_polygon(pts, shadow_c)

# ── Body ─────────────────────────────────────────────────────

func _draw_body() -> void:
	var oy := bob_y
	# Main torso — massive fat grotesque shape
	# Lower dress/robe draping down
	draw_circle(Vector2(0, 70 + oy), 105.0, _tc(DRESS_DK))
	draw_circle(Vector2(-50, 65 + oy), 80.0, _tc(DRESS_DK))
	draw_circle(Vector2(50, 65 + oy), 80.0, _tc(DRESS_DK))

	# Main belly — exposed red demon skin, fat and bulging
	draw_circle(Vector2(0, 20 + oy), 125.0, _tc(SKIN))
	draw_circle(Vector2(-65, 15 + oy), 90.0, _tc(SKIN))
	draw_circle(Vector2(65, 15 + oy), 90.0, _tc(SKIN))
	# Lower belly hang
	draw_circle(Vector2(0, 55 + oy), 115.0, _tc(SKIN_DK))
	# Belly highlight (stretched skin)
	draw_circle(Vector2(0, 10 + oy), 100.0, _tc(SKIN_LT))

	# Dress top — covers shoulders/upper chest
	draw_circle(Vector2(0, -45 + oy), 65.0, _tc(DRESS))
	draw_circle(Vector2(-40, -35 + oy), 45.0, _tc(DRESS))
	draw_circle(Vector2(40, -35 + oy), 45.0, _tc(DRESS))
	draw_circle(Vector2(0, -30 + oy), 55.0, _tc(DRESS_LT))

	# Skin at neckline
	draw_circle(Vector2(0, -55 + oy), 40.0, _tc(SKIN))

	# === BELLY DETAILS — fat folds, wrinkles, veins ===
	# Deep horizontal fat folds
	for i in range(7):
		var fold_y := -15.0 + 18.0 * i + oy
		var fold_w := 90.0 - absf(i - 3) * 14.0
		var thickness := 2.0 if i == 3 else 1.5
		draw_line(Vector2(-fold_w, fold_y), Vector2(fold_w, fold_y), _tc(BELLY_FOLD), thickness)
		# Lighter line below each fold (skin catching light)
		draw_line(Vector2(-fold_w + 5, fold_y + 2), Vector2(fold_w - 5, fold_y + 2), _tc(SKIN_LT), 0.8)

	# Stretch marks / wrinkles (diagonal lines)
	for i in range(4):
		var sx := -55.0 + 35.0 * i
		var sy := 30.0 + oy + sin(float(i) * 1.5) * 10.0
		draw_line(Vector2(sx, sy), Vector2(sx + 12, sy + 18), _tc(SKIN_VEIN), 1.0)
		draw_line(Vector2(sx + 4, sy), Vector2(sx + 16, sy + 15), _tc(SKIN_VEIN), 0.8)
	# Right side stretch marks
	for i in range(4):
		var sx := 20.0 + 30.0 * i
		var sy := 25.0 + oy + sin(float(i) * 2.0) * 8.0
		draw_line(Vector2(sx, sy), Vector2(sx - 10, sy + 16), _tc(SKIN_VEIN), 1.0)

	# Visible veins
	draw_line(Vector2(-40, -5 + oy), Vector2(-55, 20 + oy), _tc(SKIN_VEIN), 1.2)
	draw_line(Vector2(-55, 20 + oy), Vector2(-48, 40 + oy), _tc(SKIN_VEIN), 1.0)
	draw_line(Vector2(35, 0 + oy), Vector2(50, 25 + oy), _tc(SKIN_VEIN), 1.2)
	draw_line(Vector2(50, 25 + oy), Vector2(42, 45 + oy), _tc(SKIN_VEIN), 1.0)

	# Belly button — deep sunken navel
	draw_circle(Vector2(0, 35 + oy), 7.0, _tc(NAVEL))
	draw_circle(Vector2(0, 35 + oy), 4.5, _tc(Color(0.20, 0.04, 0.04)))
	# Navel shadow/depth
	draw_circle(Vector2(0, 36 + oy), 3.0, _tc(Color(0.12, 0.02, 0.02)))
	# Skin folds radiating from navel
	draw_line(Vector2(-7, 33 + oy), Vector2(-14, 30 + oy), _tc(BELLY_FOLD), 1.0)
	draw_line(Vector2(7, 33 + oy), Vector2(14, 30 + oy), _tc(BELLY_FOLD), 1.0)
	draw_line(Vector2(-5, 38 + oy), Vector2(-12, 42 + oy), _tc(BELLY_FOLD), 1.0)
	draw_line(Vector2(5, 38 + oy), Vector2(12, 42 + oy), _tc(BELLY_FOLD), 1.0)

	# Fat dimples / cellulite patches
	for i in range(6):
		var dx := -70.0 + 28.0 * i
		var dy := 50.0 + oy + sin(float(i) * 1.8) * 12.0
		draw_circle(Vector2(dx, dy), 3.0, _tc(SKIN_DK))
		draw_circle(Vector2(dx + 2, dy - 1), 1.5, _tc(SKIN_LT))

	# Side fat rolls (love handles)
	for side: float in [-1.0, 1.0]:
		for j in range(3):
			var rx: float = side * (100.0 + j * 8.0)
			var ry: float = 10.0 + j * 20.0 + oy
			draw_line(Vector2(rx, ry - 8), Vector2(rx + side * 15, ry), _tc(SKIN_DK), 2.5)
			draw_line(Vector2(rx + side * 15, ry), Vector2(rx, ry + 8), _tc(SKIN_DK), 2.5)

	# Gold necklace
	var neck_pts: PackedVector2Array = []
	for i in range(16):
		var t := float(i) / 15.0
		var a := -PI * 0.3 + PI * 0.6 * t
		neck_pts.append(Vector2(cos(a) * 45.0, sin(a) * 18.0 - 58.0 + oy))
	for i in range(neck_pts.size() - 1):
		draw_line(neck_pts[i], neck_pts[i + 1], _tc(GOLD), 3.0)
	# Pendant
	draw_circle(Vector2(0, -42 + oy), 6.0, _tc(GOLD))
	draw_circle(Vector2(0, -42 + oy), 3.5, _tc(NAIL_POLISH))

	# Gold belt/sash at dress line
	var belt_pts: PackedVector2Array = []
	for i in range(20):
		var t := float(i) / 19.0
		var a := -PI * 0.45 + PI * 0.9 * t
		belt_pts.append(Vector2(cos(a) * 115.0, sin(a) * 12.0 + 60.0 + oy))
	for i in range(belt_pts.size() - 1):
		draw_line(belt_pts[i], belt_pts[i + 1], _tc(GOLD), 2.5)
	draw_circle(Vector2(0, 60 + oy), 5.0, _tc(EYE_SHADOW))

# ── Head ─────────────────────────────────────────────────────

func _draw_head() -> void:
	var oy := bob_y
	var hx := 0.0
	var hy := -105.0 + oy

	# Large horns BEHIND the wig (drawn first)
	_draw_horn(Vector2(hx - 30, hy - 40), -0.6, 50.0)
	_draw_horn(Vector2(hx + 30, hy - 40), 0.6, 50.0)

	# Wig back volume (behind head)
	draw_circle(Vector2(hx, hy - 15), 58.0, _tc(WIG_DK))
	draw_circle(Vector2(hx - 35, hy + 10), 40.0, _tc(WIG_DK))
	draw_circle(Vector2(hx + 35, hy + 10), 40.0, _tc(WIG_DK))

	# Head — red demon skin
	draw_circle(Vector2(hx, hy), 48.0, _tc(SKIN))
	# Double chin
	draw_circle(Vector2(hx, hy + 22), 28.0, _tc(SKIN))
	draw_circle(Vector2(hx, hy + 30), 20.0, _tc(SKIN_DK))
	# Chin fold
	draw_line(Vector2(hx - 20, hy + 18), Vector2(hx + 20, hy + 18), _tc(BELLY_FOLD), 1.5)
	# Slight chin highlight
	draw_circle(Vector2(hx, hy + 12), 25.0, _tc(SKIN_LT))

	# Wig top volume
	draw_circle(Vector2(hx, hy - 35), 50.0, _tc(WIG))
	draw_circle(Vector2(hx - 20, hy - 42), 35.0, _tc(WIG_LT))
	draw_circle(Vector2(hx + 20, hy - 42), 35.0, _tc(WIG))
	# Wig side curls
	draw_circle(Vector2(hx - 48, hy - 5), 25.0, _tc(WIG))
	draw_circle(Vector2(hx + 48, hy - 5), 25.0, _tc(WIG))
	draw_circle(Vector2(hx - 42, hy + 20), 20.0, _tc(WIG_DK))
	draw_circle(Vector2(hx + 42, hy + 20), 20.0, _tc(WIG_DK))
	# Wig bangs
	draw_circle(Vector2(hx - 15, hy - 38), 20.0, _tc(WIG_LT))
	draw_circle(Vector2(hx + 15, hy - 38), 20.0, _tc(WIG_LT))
	draw_circle(Vector2(hx, hy - 42), 18.0, _tc(WIG))

	# Smaller front horns poking through wig
	_draw_horn(Vector2(hx - 22, hy - 48), -0.3, 28.0)
	_draw_horn(Vector2(hx + 22, hy - 48), 0.3, 28.0)

	# Face wrinkles (forehead)
	draw_line(Vector2(hx - 15, hy - 22), Vector2(hx + 15, hy - 22), _tc(SKIN_DK), 0.8)
	draw_line(Vector2(hx - 12, hy - 19), Vector2(hx + 12, hy - 19), _tc(SKIN_DK), 0.8)

	# Eye shadow — heavy, smeared
	draw_rect(Rect2(hx - 23, hy - 15, 18, 7), _tc(EYE_SHADOW))
	draw_rect(Rect2(hx + 5, hy - 15, 18, 7), _tc(EYE_SHADOW))
	# Smear edges
	draw_circle(Vector2(hx - 25, hy - 12), 4.0, _tc(EYE_SHADOW))
	draw_circle(Vector2(hx + 25, hy - 12), 4.0, _tc(EYE_SHADOW))

	# Eyes — sickly yellow sclera, green demon irises
	draw_rect(Rect2(hx - 20, hy - 9, 13, 10), _tc(EYE_WHITE))
	draw_rect(Rect2(hx + 7, hy - 9, 13, 10), _tc(EYE_WHITE))
	# Irises
	draw_rect(Rect2(hx - 17, hy - 7, 7, 8), _tc(EYE_GREEN))
	draw_rect(Rect2(hx + 10, hy - 7, 7, 8), _tc(EYE_GREEN))
	# Pupils — slitted
	draw_rect(Rect2(hx - 15, hy - 6, 3, 6), _tc(Color(0.05, 0.05, 0.05)))
	draw_rect(Rect2(hx + 12, hy - 6, 3, 6), _tc(Color(0.05, 0.05, 0.05)))

	# Heavy eyelashes (thick, clumpy)
	for i in range(5):
		var lx := hx - 22.0 + 4.5 * i
		draw_line(Vector2(lx, hy - 15), Vector2(lx - 1, hy - 20), _tc(Color(0.1, 0.05, 0.05)), 2.0)
		lx = hx + 6.0 + 4.5 * i
		draw_line(Vector2(lx, hy - 15), Vector2(lx + 1, hy - 20), _tc(Color(0.1, 0.05, 0.05)), 2.0)

	# Crow's feet wrinkles at eye corners
	draw_line(Vector2(hx - 22, hy - 6), Vector2(hx - 28, hy - 10), _tc(SKIN_DK), 0.8)
	draw_line(Vector2(hx - 22, hy - 4), Vector2(hx - 27, hy - 2), _tc(SKIN_DK), 0.8)
	draw_line(Vector2(hx + 22, hy - 6), Vector2(hx + 28, hy - 10), _tc(SKIN_DK), 0.8)
	draw_line(Vector2(hx + 22, hy - 4), Vector2(hx + 27, hy - 2), _tc(SKIN_DK), 0.8)

	# Blush circles — heavy, garish
	draw_circle(Vector2(hx - 22, hy + 5), 12.0, _tc(BLUSH))
	draw_circle(Vector2(hx + 22, hy + 5), 12.0, _tc(BLUSH))

	# Nose — broad, demon-like
	draw_circle(Vector2(hx, hy + 4), 5.0, _tc(SKIN_DK))
	draw_circle(Vector2(hx - 3, hy + 5), 2.5, _tc(Color(0.3, 0.08, 0.08)))
	draw_circle(Vector2(hx + 3, hy + 5), 2.5, _tc(Color(0.3, 0.08, 0.08)))

	# Lips — oversized, garish red lipstick smeared slightly
	draw_rect(Rect2(hx - 14, hy + 14, 28, 6), _tc(LIPS))
	draw_rect(Rect2(hx - 12, hy + 12, 24, 3), _tc(LIPS))
	# Lip highlight
	draw_rect(Rect2(hx - 6, hy + 12, 12, 2), _tc(Color(1.0, 0.4, 0.45)))
	# Smeared lipstick
	draw_circle(Vector2(hx + 15, hy + 16), 3.0, _tc(Color(LIPS.r, LIPS.g, LIPS.b, 0.5)))

	# Beauty mark (mole)
	draw_circle(Vector2(hx + 18, hy + 8), 2.5, _tc(Color(0.15, 0.05, 0.05)))

	# Earrings — dangling gold
	draw_circle(Vector2(hx - 46, hy + 6), 4.5, _tc(GOLD))
	draw_circle(Vector2(hx - 46, hy + 13), 3.5, _tc(GOLD))
	draw_circle(Vector2(hx - 46, hy + 19), 2.5, _tc(GOLD_DK))
	draw_circle(Vector2(hx + 46, hy + 6), 4.5, _tc(GOLD))
	draw_circle(Vector2(hx + 46, hy + 13), 3.5, _tc(GOLD))
	draw_circle(Vector2(hx + 46, hy + 19), 2.5, _tc(GOLD_DK))

func _draw_horn(base: Vector2, lean: float, length: float = 30.0) -> void:
	var tip := base + Vector2(lean * length, -length * 0.85)
	var mid := base.lerp(tip, 0.5) + Vector2(lean * 8.0, -5.0)
	# Horn body — thick at base, tapered
	draw_line(base + Vector2(-5, 0), mid, _tc(HORN_C), 8.0)
	draw_line(mid, tip, _tc(HORN_C), 5.0)
	# Highlight
	draw_line(base + Vector2(2, -1), mid + Vector2(1, 0), _tc(HORN_LT), 4.0)
	draw_line(mid + Vector2(1, 0), tip, _tc(HORN_LT), 2.5)
	# Dark tip
	draw_circle(tip, 2.5, _tc(HORN_TIP))
	# Ridges
	for i in range(4):
		var t := 0.2 + 0.18 * i
		var p := base.lerp(tip, t)
		var w := 5.0 - t * 3.0
		draw_line(p + Vector2(-w, 0), p + Vector2(w, 0), _tc(HORN_C), 1.2)

# ── Arms ─────────────────────────────────────────────────────

func _draw_arms_back() -> void:
	# Draw arms that are behind the body (indices 0-4 and 15-19)
	for i in [0, 1, 2, 3, 4, 15, 16, 17, 18, 19]:
		_draw_single_arm(i)

func _draw_arms_front() -> void:
	# Draw arms in front of the body (indices 5-14)
	for i in range(5, 15):
		_draw_single_arm(i)

func _draw_single_arm(idx: int) -> void:
	var data: Dictionary = ARM_DATA[idx]
	var oy := bob_y
	var sway_offset := sin(_arm_sway * TAU + idx * 0.7) * 0.06

	var base_angle: float = data["angle"] + sway_offset
	var arm_len: float = data["len"]
	var item: String = data["item"]

	# Shoulder position on body perimeter
	var body_r := 110.0
	var shoulder := Vector2(cos(base_angle) * body_r, sin(base_angle) * body_r * 0.7 + 10.0 + oy)

	# Elbow (midpoint with slight bend)
	var arm_dir := Vector2(cos(base_angle), sin(base_angle))
	var bend := Vector2(-arm_dir.y, arm_dir.x) * 8.0  # slight outward bend
	var elbow := shoulder + arm_dir * arm_len * 0.5 + bend

	# Hand position
	var hand := shoulder + arm_dir * arm_len

	# Upper arm
	draw_line(shoulder, elbow, _tc(SKIN_DK), 7.0)
	draw_line(shoulder, elbow, _tc(SKIN), 5.0)

	# Lower arm
	draw_line(elbow, hand, _tc(SKIN_DK), 6.0)
	draw_line(elbow, hand, _tc(SKIN), 4.0)

	# Shoulder joint
	draw_circle(shoulder, 5.0, _tc(DRESS_LT))

	# Elbow joint
	draw_circle(elbow, 3.5, _tc(SKIN_LT))

	# Hand circle
	draw_circle(hand, 5.0, _tc(SKIN_LT))

	# Fingernails with polish (3 tiny dots at hand)
	for f in range(3):
		var nail_offset := Vector2(cos(base_angle + (f - 1) * 0.3), sin(base_angle + (f - 1) * 0.3)) * 7.0
		draw_circle(hand + nail_offset, 1.8, _tc(NAIL_POLISH))

	# Draw held item
	var item_pos := hand + arm_dir * 14.0
	match item:
		"mirror": _draw_item_mirror(item_pos, base_angle)
		"comb": _draw_item_comb(item_pos, base_angle)
		"nail_polish": _draw_item_nail_polish(item_pos)
		"brush": _draw_item_brush(item_pos, base_angle)
		"lipstick": _draw_item_lipstick(item_pos, base_angle)
		"powder": _draw_item_powder(item_pos)
		"perfume": _draw_item_perfume(item_pos)
		"empty": pass

# ── Held Items ───────────────────────────────────────────────

func _draw_item_mirror(pos: Vector2, angle: float) -> void:
	# Handle
	var handle_dir := Vector2(cos(angle), sin(angle))
	draw_line(pos - handle_dir * 8, pos, _tc(MIRROR_FRAME), 3.0)
	# Frame (oval)
	var pts: PackedVector2Array = []
	for i in range(16):
		var a := TAU * i / 16.0
		pts.append(pos + handle_dir * 8 + Vector2(cos(a) * 12.0, sin(a) * 16.0))
	draw_colored_polygon(pts, _tc(MIRROR_FRAME))
	# Glass
	var glass_pts: PackedVector2Array = []
	for i in range(16):
		var a := TAU * i / 16.0
		glass_pts.append(pos + handle_dir * 8 + Vector2(cos(a) * 9.0, sin(a) * 13.0))
	draw_colored_polygon(glass_pts, _tc(MIRROR_GLASS))
	# Reflection shine
	draw_line(pos + handle_dir * 5 + Vector2(-3, -4), pos + handle_dir * 5 + Vector2(2, -8), _tc(Color(1, 1, 1, 0.6)), 1.5)

func _draw_item_comb(pos: Vector2, angle: float) -> void:
	var perp := Vector2(-sin(angle), cos(angle))
	# Comb body
	draw_rect(Rect2(pos.x - 10, pos.y - 3, 20, 6), _tc(COMB_C))
	# Teeth
	for i in range(7):
		var tx := pos.x - 9 + 3 * i
		draw_line(Vector2(tx, pos.y + 3), Vector2(tx, pos.y + 10), _tc(COMB_C), 1.5)

func _draw_item_nail_polish(pos: Vector2) -> void:
	# Bottle body
	draw_rect(Rect2(pos.x - 5, pos.y - 4, 10, 12), _tc(NAIL_POLISH))
	# Cap
	draw_rect(Rect2(pos.x - 3, pos.y - 8, 6, 5), _tc(Color(0.2, 0.2, 0.22)))
	# Label
	draw_rect(Rect2(pos.x - 4, pos.y, 8, 4), _tc(Color(1, 1, 1, 0.3)))

func _draw_item_brush(pos: Vector2, angle: float) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	# Handle
	draw_line(pos - dir * 10, pos, _tc(BRUSH_HANDLE), 3.0)
	# Brush head
	draw_circle(pos + dir * 6, 7.0, _tc(BRUSH_TIP))
	draw_circle(pos + dir * 6, 4.0, _tc(Color(0.95, 0.65, 0.7)))

func _draw_item_lipstick(pos: Vector2, angle: float) -> void:
	var dir := Vector2(cos(angle), sin(angle))
	# Tube
	draw_line(pos - dir * 8, pos, _tc(LIPSTICK_TUBE), 5.0)
	# Red tip
	draw_line(pos, pos + dir * 6, _tc(LIPS), 4.0)
	draw_line(pos + dir * 3, pos + dir * 6, _tc(Color(1.0, 0.3, 0.35)), 3.0)

func _draw_item_powder(pos: Vector2) -> void:
	# Compact case
	draw_circle(pos, 10.0, _tc(GOLD))
	draw_circle(pos, 8.0, _tc(Color(0.95, 0.85, 0.75)))
	# Mirror in compact
	draw_circle(pos + Vector2(0, -1), 5.0, _tc(MIRROR_GLASS))

func _draw_item_perfume(pos: Vector2) -> void:
	# Bottle
	draw_rect(Rect2(pos.x - 5, pos.y - 6, 10, 14), _tc(Color(0.7, 0.5, 0.8, 0.7)))
	# Sprayer
	draw_rect(Rect2(pos.x - 2, pos.y - 10, 4, 5), _tc(GOLD))
	draw_circle(Vector2(pos.x, pos.y - 12), 3.0, _tc(GOLD))

# ── Cast flash overlay ───────────────────────────────────────

func _draw_cast_flash() -> void:
	if cast_anim <= 0.01:
		return
	var flash_c := Color(1.0, 0.7, 0.85, cast_anim * 0.3)
	draw_circle(Vector2(0, bob_y), 160.0, flash_c)
