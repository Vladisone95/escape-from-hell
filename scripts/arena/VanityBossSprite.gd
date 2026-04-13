extends Node2D

var bob_y: float = 0.0
var hurt_flash: float = 0.0
var cast_anim: float = 0.0
var _arm_sway: float = 0.0

var _idle_tween: Tween
var _sway_tween: Tween

# Arm destruction state
var arms_alive: Array[bool] = [true, true, true, true, true, true, true, true, true, true]
var _arm_explosions: Array[Dictionary] = []
const ARM_DESTROY_ORDER: Array[int] = [0, 9, 1, 8, 2, 7, 3, 6, 4, 5]

# Colors — darker, more evil demonic tones
const SKIN := Color(0.62, 0.14, 0.12)
const SKIN_DK := Color(0.40, 0.08, 0.06)
const SKIN_LT := Color(0.78, 0.25, 0.20)
const SKIN_VEIN := Color(0.35, 0.05, 0.12)
const DRESS := Color(0.35, 0.02, 0.22)
const DRESS_LT := Color(0.50, 0.08, 0.32)
const DRESS_DK := Color(0.22, 0.01, 0.12)
const GOLD := Color(0.75, 0.55, 0.10)
const GOLD_DK := Color(0.55, 0.38, 0.05)
const WIG := Color(0.88, 0.78, 0.18)
const WIG_DK := Color(0.65, 0.55, 0.10)
const WIG_LT := Color(0.95, 0.88, 0.40)
const BLUSH := Color(0.90, 0.25, 0.30)
const LIPS := Color(0.80, 0.04, 0.12)
const EYE_SHADOW := Color(0.38, 0.06, 0.45)
const EYE_GREEN := Color(0.25, 0.80, 0.10)
const EYE_WHITE := Color(0.85, 0.78, 0.65)
const MIRROR_GLASS := Color(0.35, 0.15, 0.18)
const MIRROR_FRAME := Color(0.25, 0.08, 0.08)
const NAIL_POLISH := Color(0.80, 0.05, 0.20)
const COMB_C := Color(0.75, 0.70, 0.60)
const BRUSH_HANDLE := Color(0.20, 0.10, 0.08)
const BRUSH_TIP := Color(0.55, 0.55, 0.55)
const LIPSTICK_TUBE := Color(0.12, 0.10, 0.12)
const HORN_C := Color(0.22, 0.04, 0.04)
const HORN_LT := Color(0.40, 0.12, 0.08)
const HORN_TIP := Color(0.12, 0.01, 0.01)
const BELLY_FOLD := Color(0.32, 0.05, 0.05)
const NAVEL := Color(0.25, 0.04, 0.04)
const IRON := Color(0.22, 0.20, 0.22)
const IRON_LT := Color(0.35, 0.32, 0.35)
const BONE := Color(0.82, 0.75, 0.62)
const BONE_DK := Color(0.60, 0.52, 0.40)
const BLOOD := Color(0.65, 0.02, 0.05)

# 10 arms — 5 per side, gothic vanity items
const ARM_DATA := [
	{ "angle": -2.4, "len": 100, "item": "gothic_mirror" },
	{ "angle": -1.8, "len": 90,  "item": "gothic_comb" },
	{ "angle": -1.2, "len": 105, "item": "gothic_nail_polish" },
	{ "angle": -0.6, "len": 85,  "item": "gothic_brush" },
	{ "angle": 0.0,  "len": 95,  "item": "gothic_lipstick" },
	{ "angle": 0.6,  "len": 95,  "item": "gothic_powder" },
	{ "angle": 1.2,  "len": 105, "item": "gothic_perfume" },
	{ "angle": 1.8,  "len": 90,  "item": "gothic_scissors" },
	{ "angle": 2.4,  "len": 100, "item": "gothic_razor" },
	{ "angle": 2.9,  "len": 80,  "item": "gothic_mirror" },
]

func _tc(base: Color) -> Color:
	return base.lerp(Color(1.0, 1.0, 1.0), hurt_flash * 0.7)

func _process(delta: float) -> void:
	# Tick explosion particles
	var i: int = _arm_explosions.size() - 1
	while i >= 0:
		var exp: Dictionary = _arm_explosions[i]
		exp["time"] += delta
		if exp["time"] >= exp["max_time"]:
			_arm_explosions.remove_at(i)
		else:
			var particles: Array = exp["particles"]
			for p: Dictionary in particles:
				p["pos"] += p["vel"] * delta
				p["vel"] *= 0.96
				p["life"] -= delta * 1.5
		i -= 1
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
	pass

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
	pass

func destroy_arm(order_index: int) -> void:
	if order_index < 0 or order_index >= ARM_DESTROY_ORDER.size():
		return
	var arm_index: int = ARM_DESTROY_ORDER[order_index]
	if not arms_alive[arm_index]:
		return
	arms_alive[arm_index] = false
	var data: Dictionary = ARM_DATA[arm_index]
	var base_angle: float = data["angle"]
	var arm_len: float = data["len"]
	var body_r: float = 120.0
	var shoulder: Vector2 = Vector2(cos(base_angle) * body_r, sin(base_angle) * body_r * 0.7 + 10.0 + bob_y)
	var arm_dir: Vector2 = Vector2(cos(base_angle), sin(base_angle))
	var hand: Vector2 = shoulder + arm_dir * arm_len
	var explosion: Dictionary = {
		"pos": hand,
		"particles": [],
		"time": 0.0,
		"max_time": 0.8,
	}
	for p_i: int in range(14):
		var angle: float = randf() * TAU
		var spd: float = randf_range(90.0, 220.0)
		explosion["particles"].append({
			"pos": hand,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"color": [SKIN, SKIN_LT, BLOOD, NAIL_POLISH, IRON].pick_random(),
			"life": 1.0,
		})
	_arm_explosions.append(explosion)

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
	_draw_arm_explosions()

# ── Shadow ───────────────────────────────────────────────────

func _draw_shadow() -> void:
	var sy: float = 145.0 + bob_y
	var shadow_c := Color(0.0, 0.0, 0.0, 0.30)
	var pts: PackedVector2Array = []
	for i: int in range(24):
		var a: float = TAU * i / 24.0
		pts.append(Vector2(cos(a) * 145.0, sin(a) * 35.0 + sy))
	draw_colored_polygon(pts, shadow_c)

# ── Body ─────────────────────────────────────────────────────

func _draw_body() -> void:
	var oy: float = bob_y

	# Lower dress/robe — darker, tattered
	draw_circle(Vector2(0, 80 + oy), 120.0, _tc(DRESS_DK))
	draw_circle(Vector2(-60, 75 + oy), 90.0, _tc(DRESS_DK))
	draw_circle(Vector2(60, 75 + oy), 90.0, _tc(DRESS_DK))
	draw_circle(Vector2(-30, 90 + oy), 85.0, _tc(DRESS_DK))
	draw_circle(Vector2(30, 90 + oy), 85.0, _tc(DRESS_DK))

	# Main belly — massive, fat, exposed red demon skin
	draw_circle(Vector2(0, 20 + oy), 140.0, _tc(SKIN))
	draw_circle(Vector2(-75, 15 + oy), 100.0, _tc(SKIN))
	draw_circle(Vector2(75, 15 + oy), 100.0, _tc(SKIN))
	# Extra belly mass — fatter
	draw_circle(Vector2(-40, 40 + oy), 110.0, _tc(SKIN))
	draw_circle(Vector2(40, 40 + oy), 110.0, _tc(SKIN))
	# Lower belly hang
	draw_circle(Vector2(0, 65 + oy), 130.0, _tc(SKIN_DK))
	# Belly highlight
	draw_circle(Vector2(0, 10 + oy), 110.0, _tc(SKIN_LT))

	# Dress top
	draw_circle(Vector2(0, -50 + oy), 72.0, _tc(DRESS))
	draw_circle(Vector2(-45, -38 + oy), 50.0, _tc(DRESS))
	draw_circle(Vector2(45, -38 + oy), 50.0, _tc(DRESS))
	draw_circle(Vector2(0, -35 + oy), 60.0, _tc(DRESS_LT))

	# Skin at neckline
	draw_circle(Vector2(0, -60 + oy), 44.0, _tc(SKIN))

	# === BELLY DETAILS ===
	# Deep horizontal fat folds — more of them
	for i: int in range(9):
		var fold_y: float = -20.0 + 16.0 * i + oy
		var fold_w: float = 100.0 - absf(i - 4) * 14.0
		var thickness: float = 2.5 if i == 4 else 1.8
		draw_line(Vector2(-fold_w, fold_y), Vector2(fold_w, fold_y), _tc(BELLY_FOLD), thickness)
		draw_line(Vector2(-fold_w + 5, fold_y + 2), Vector2(fold_w - 5, fold_y + 2), _tc(SKIN_LT), 0.8)

	# Stretch marks — more pronounced
	for i: int in range(5):
		var sx: float = -65.0 + 32.0 * i
		var sy: float = 30.0 + oy + sin(float(i) * 1.5) * 10.0
		draw_line(Vector2(sx, sy), Vector2(sx + 14, sy + 20), _tc(SKIN_VEIN), 1.4)
		draw_line(Vector2(sx + 5, sy), Vector2(sx + 18, sy + 17), _tc(SKIN_VEIN), 1.0)
	for i: int in range(5):
		var sx: float = 25.0 + 28.0 * i
		var sy: float = 22.0 + oy + sin(float(i) * 2.0) * 8.0
		draw_line(Vector2(sx, sy), Vector2(sx - 12, sy + 18), _tc(SKIN_VEIN), 1.4)

	# Visible veins — thicker, more prominent
	draw_line(Vector2(-45, -8 + oy), Vector2(-65, 22 + oy), _tc(SKIN_VEIN), 1.8)
	draw_line(Vector2(-65, 22 + oy), Vector2(-55, 48 + oy), _tc(SKIN_VEIN), 1.4)
	draw_line(Vector2(-50, 35 + oy), Vector2(-70, 55 + oy), _tc(SKIN_VEIN), 1.2)
	draw_line(Vector2(40, -2 + oy), Vector2(60, 28 + oy), _tc(SKIN_VEIN), 1.8)
	draw_line(Vector2(60, 28 + oy), Vector2(50, 50 + oy), _tc(SKIN_VEIN), 1.4)
	draw_line(Vector2(55, 40 + oy), Vector2(72, 58 + oy), _tc(SKIN_VEIN), 1.2)

	# Belly button — deep, oozing
	draw_circle(Vector2(0, 38 + oy), 9.0, _tc(NAVEL))
	draw_circle(Vector2(0, 38 + oy), 6.0, _tc(Color(0.18, 0.03, 0.03)))
	draw_circle(Vector2(0, 39 + oy), 4.0, _tc(Color(0.10, 0.01, 0.01)))
	# Navel folds
	draw_line(Vector2(-9, 35 + oy), Vector2(-16, 31 + oy), _tc(BELLY_FOLD), 1.2)
	draw_line(Vector2(9, 35 + oy), Vector2(16, 31 + oy), _tc(BELLY_FOLD), 1.2)
	draw_line(Vector2(-7, 41 + oy), Vector2(-14, 46 + oy), _tc(BELLY_FOLD), 1.2)
	draw_line(Vector2(7, 41 + oy), Vector2(14, 46 + oy), _tc(BELLY_FOLD), 1.2)

	# Cellulite / boils
	for i: int in range(8):
		var dx: float = -80.0 + 22.0 * i
		var dy: float = 55.0 + oy + sin(float(i) * 1.8) * 14.0
		draw_circle(Vector2(dx, dy), 4.0, _tc(SKIN_DK))
		draw_circle(Vector2(dx + 2, dy - 1), 2.0, _tc(SKIN_LT))
	# Pustules / sores
	draw_circle(Vector2(-35, 60 + oy), 5.0, _tc(Color(0.55, 0.15, 0.10)))
	draw_circle(Vector2(-35, 60 + oy), 3.0, _tc(Color(0.70, 0.25, 0.15)))
	draw_circle(Vector2(50, 45 + oy), 4.0, _tc(Color(0.55, 0.15, 0.10)))
	draw_circle(Vector2(50, 45 + oy), 2.5, _tc(Color(0.70, 0.25, 0.15)))

	# Side fat rolls — bigger
	for side: float in [-1.0, 1.0]:
		for j: int in range(4):
			var rx: float = side * (110.0 + j * 10.0)
			var ry: float = 5.0 + j * 18.0 + oy
			draw_line(Vector2(rx, ry - 9), Vector2(rx + side * 18, ry), _tc(SKIN_DK), 3.0)
			draw_line(Vector2(rx + side * 18, ry), Vector2(rx, ry + 9), _tc(SKIN_DK), 3.0)

	# Spiked iron necklace
	var neck_pts: PackedVector2Array = []
	for i: int in range(16):
		var t: float = float(i) / 15.0
		var a: float = -PI * 0.3 + PI * 0.6 * t
		neck_pts.append(Vector2(cos(a) * 50.0, sin(a) * 20.0 - 62.0 + oy))
	for i: int in range(neck_pts.size() - 1):
		draw_line(neck_pts[i], neck_pts[i + 1], _tc(IRON), 3.5)
	# Spikes on necklace
	for i: int in range(0, neck_pts.size(), 3):
		var p: Vector2 = neck_pts[i]
		draw_line(p, p + Vector2(0, 8), _tc(IRON_LT), 2.0)
		draw_circle(p + Vector2(0, 9), 1.5, _tc(BLOOD))
	# Skull pendant
	draw_circle(Vector2(0, -44 + oy), 7.0, _tc(BONE))
	draw_circle(Vector2(-2, -46 + oy), 2.0, _tc(Color(0.1, 0.05, 0.05)))
	draw_circle(Vector2(2, -46 + oy), 2.0, _tc(Color(0.1, 0.05, 0.05)))
	draw_line(Vector2(-2, -41 + oy), Vector2(2, -41 + oy), _tc(Color(0.1, 0.05, 0.05)), 1.0)

	# Iron belt with skull buckle
	var belt_pts: PackedVector2Array = []
	for i: int in range(20):
		var t: float = float(i) / 19.0
		var a: float = -PI * 0.45 + PI * 0.9 * t
		belt_pts.append(Vector2(cos(a) * 128.0, sin(a) * 14.0 + 68.0 + oy))
	for i: int in range(belt_pts.size() - 1):
		draw_line(belt_pts[i], belt_pts[i + 1], _tc(IRON), 3.0)
	draw_circle(Vector2(0, 68 + oy), 6.0, _tc(BONE))
	draw_circle(Vector2(-1.5, 67 + oy), 1.5, _tc(Color(0.1, 0.05, 0.05)))
	draw_circle(Vector2(1.5, 67 + oy), 1.5, _tc(Color(0.1, 0.05, 0.05)))

# ── Head ─────────────────────────────────────────────────────

func _draw_head() -> void:
	var oy: float = bob_y
	var hx: float = 0.0
	var hy: float = -115.0 + oy

	# Large horns BEHIND wig — bigger, more menacing
	_draw_horn(Vector2(hx - 35, hy - 45), -0.7, 60.0)
	_draw_horn(Vector2(hx + 35, hy - 45), 0.7, 60.0)

	# Wig back volume
	draw_circle(Vector2(hx, hy - 18), 62.0, _tc(WIG_DK))
	draw_circle(Vector2(hx - 38, hy + 12), 42.0, _tc(WIG_DK))
	draw_circle(Vector2(hx + 38, hy + 12), 42.0, _tc(WIG_DK))

	# Head — darker red demon skin
	draw_circle(Vector2(hx, hy), 52.0, _tc(SKIN))
	# Triple chin
	draw_circle(Vector2(hx, hy + 24), 32.0, _tc(SKIN))
	draw_circle(Vector2(hx, hy + 34), 24.0, _tc(SKIN_DK))
	draw_circle(Vector2(hx, hy + 42), 18.0, _tc(SKIN_DK))
	# Chin folds
	draw_line(Vector2(hx - 24, hy + 20), Vector2(hx + 24, hy + 20), _tc(BELLY_FOLD), 1.8)
	draw_line(Vector2(hx - 18, hy + 30), Vector2(hx + 18, hy + 30), _tc(BELLY_FOLD), 1.5)
	draw_circle(Vector2(hx, hy + 14), 28.0, _tc(SKIN_LT))

	# Wig top — messier, wilder
	draw_circle(Vector2(hx, hy - 40), 55.0, _tc(WIG))
	draw_circle(Vector2(hx - 25, hy - 48), 38.0, _tc(WIG_LT))
	draw_circle(Vector2(hx + 25, hy - 48), 38.0, _tc(WIG))
	# Wig side curls
	draw_circle(Vector2(hx - 52, hy - 8), 28.0, _tc(WIG))
	draw_circle(Vector2(hx + 52, hy - 8), 28.0, _tc(WIG))
	draw_circle(Vector2(hx - 46, hy + 22), 22.0, _tc(WIG_DK))
	draw_circle(Vector2(hx + 46, hy + 22), 22.0, _tc(WIG_DK))
	# Messy bangs
	draw_circle(Vector2(hx - 18, hy - 42), 22.0, _tc(WIG_LT))
	draw_circle(Vector2(hx + 18, hy - 42), 22.0, _tc(WIG_LT))
	draw_circle(Vector2(hx, hy - 46), 20.0, _tc(WIG))

	# Front horns — sharper
	_draw_horn(Vector2(hx - 25, hy - 52), -0.35, 32.0)
	_draw_horn(Vector2(hx + 25, hy - 52), 0.35, 32.0)
	# Extra small horn nubs on forehead
	_draw_horn(Vector2(hx - 12, hy - 38), -0.15, 14.0)
	_draw_horn(Vector2(hx + 12, hy - 38), 0.15, 14.0)

	# Face wrinkles — deeper
	draw_line(Vector2(hx - 18, hy - 24), Vector2(hx + 18, hy - 24), _tc(SKIN_DK), 1.2)
	draw_line(Vector2(hx - 15, hy - 21), Vector2(hx + 15, hy - 21), _tc(SKIN_DK), 1.0)
	draw_line(Vector2(hx - 12, hy - 18), Vector2(hx + 12, hy - 18), _tc(SKIN_DK), 0.8)

	# Eye shadow — heavier, more smeared
	draw_rect(Rect2(hx - 25, hy - 16, 20, 8), _tc(EYE_SHADOW))
	draw_rect(Rect2(hx + 5, hy - 16, 20, 8), _tc(EYE_SHADOW))
	draw_circle(Vector2(hx - 27, hy - 12), 5.0, _tc(EYE_SHADOW))
	draw_circle(Vector2(hx + 27, hy - 12), 5.0, _tc(EYE_SHADOW))

	# Eyes — sickly, sunken
	draw_rect(Rect2(hx - 22, hy - 10, 14, 11), _tc(EYE_WHITE))
	draw_rect(Rect2(hx + 8, hy - 10, 14, 11), _tc(EYE_WHITE))
	# Irises — glowing green
	draw_rect(Rect2(hx - 19, hy - 8, 8, 9), _tc(EYE_GREEN))
	draw_rect(Rect2(hx + 11, hy - 8, 8, 9), _tc(EYE_GREEN))
	# Pupils — slitted
	draw_rect(Rect2(hx - 17, hy - 7, 3, 7), _tc(Color(0.04, 0.04, 0.04)))
	draw_rect(Rect2(hx + 13, hy - 7, 3, 7), _tc(Color(0.04, 0.04, 0.04)))

	# Eyelashes — clumpy
	for i: int in range(6):
		var lx: float = hx - 24.0 + 4.0 * i
		draw_line(Vector2(lx, hy - 16), Vector2(lx - 1, hy - 22), _tc(Color(0.08, 0.04, 0.04)), 2.2)
		lx = hx + 6.0 + 4.0 * i
		draw_line(Vector2(lx, hy - 16), Vector2(lx + 1, hy - 22), _tc(Color(0.08, 0.04, 0.04)), 2.2)

	# Crow's feet
	draw_line(Vector2(hx - 24, hy - 7), Vector2(hx - 30, hy - 12), _tc(SKIN_DK), 1.0)
	draw_line(Vector2(hx - 24, hy - 5), Vector2(hx - 29, hy - 2), _tc(SKIN_DK), 1.0)
	draw_line(Vector2(hx + 24, hy - 7), Vector2(hx + 30, hy - 12), _tc(SKIN_DK), 1.0)
	draw_line(Vector2(hx + 24, hy - 5), Vector2(hx + 29, hy - 2), _tc(SKIN_DK), 1.0)

	# Blush — smeared
	draw_circle(Vector2(hx - 24, hy + 5), 14.0, _tc(BLUSH))
	draw_circle(Vector2(hx + 24, hy + 5), 14.0, _tc(BLUSH))

	# Nose — broad, warty
	draw_circle(Vector2(hx, hy + 4), 6.0, _tc(SKIN_DK))
	draw_circle(Vector2(hx - 4, hy + 5), 3.0, _tc(Color(0.25, 0.06, 0.06)))
	draw_circle(Vector2(hx + 4, hy + 5), 3.0, _tc(Color(0.25, 0.06, 0.06)))
	# Wart
	draw_circle(Vector2(hx + 7, hy + 2), 2.5, _tc(Color(0.50, 0.18, 0.12)))
	draw_circle(Vector2(hx + 7, hy + 2), 1.2, _tc(SKIN_LT))

	# Lips — grotesque, smeared
	draw_rect(Rect2(hx - 16, hy + 14, 32, 7), _tc(LIPS))
	draw_rect(Rect2(hx - 14, hy + 12, 28, 3), _tc(LIPS))
	draw_rect(Rect2(hx - 7, hy + 12, 14, 2), _tc(Color(0.95, 0.35, 0.40)))
	# Drool
	draw_line(Vector2(hx + 12, hy + 20), Vector2(hx + 14, hy + 30), _tc(Color(0.5, 0.3, 0.3, 0.6)), 1.5)

	# Beauty mark
	draw_circle(Vector2(hx + 20, hy + 9), 3.0, _tc(Color(0.12, 0.04, 0.04)))

	# Earrings — iron skulls
	for side: float in [-1.0, 1.0]:
		var ex: float = hx + side * 50.0
		draw_circle(Vector2(ex, hy + 8), 5.0, _tc(IRON))
		draw_line(Vector2(ex, hy + 13), Vector2(ex, hy + 20), _tc(IRON_LT), 2.0)
		draw_circle(Vector2(ex, hy + 22), 4.0, _tc(BONE))
		draw_circle(Vector2(ex - 1, hy + 21), 1.0, _tc(Color(0.1, 0.05, 0.05)))
		draw_circle(Vector2(ex + 1, hy + 21), 1.0, _tc(Color(0.1, 0.05, 0.05)))

func _draw_horn(base: Vector2, lean: float, length: float = 30.0) -> void:
	var tip: Vector2 = base + Vector2(lean * length, -length * 0.85)
	var mid: Vector2 = base.lerp(tip, 0.5) + Vector2(lean * 8.0, -5.0)
	draw_line(base + Vector2(-5, 0), mid, _tc(HORN_C), 9.0)
	draw_line(mid, tip, _tc(HORN_C), 5.5)
	draw_line(base + Vector2(2, -1), mid + Vector2(1, 0), _tc(HORN_LT), 4.5)
	draw_line(mid + Vector2(1, 0), tip, _tc(HORN_LT), 2.8)
	draw_circle(tip, 2.8, _tc(HORN_TIP))
	for i: int in range(5):
		var t: float = 0.15 + 0.16 * i
		var p: Vector2 = base.lerp(tip, t)
		var w: float = 5.5 - t * 3.5
		draw_line(p + Vector2(-w, 0), p + Vector2(w, 0), _tc(HORN_C), 1.4)

# ── Arms ─────────────────────────────────────────────────────

func _draw_arms_back() -> void:
	for i: int in [0, 1, 2, 7, 8, 9]:
		_draw_single_arm(i)

func _draw_arms_front() -> void:
	for i: int in [3, 4, 5, 6]:
		_draw_single_arm(i)

func _draw_single_arm(idx: int) -> void:
	if not arms_alive[idx]:
		return
	var data: Dictionary = ARM_DATA[idx]
	var oy: float = bob_y
	var sway_offset: float = sin(_arm_sway * TAU + idx * 0.7) * 0.06

	var base_angle: float = data["angle"] + sway_offset
	var arm_len: float = data["len"]
	var item: String = data["item"]

	var body_r: float = 120.0
	var shoulder: Vector2 = Vector2(cos(base_angle) * body_r, sin(base_angle) * body_r * 0.7 + 10.0 + oy)

	var arm_dir: Vector2 = Vector2(cos(base_angle), sin(base_angle))
	var bend: Vector2 = Vector2(-arm_dir.y, arm_dir.x) * 8.0
	var elbow: Vector2 = shoulder + arm_dir * arm_len * 0.5 + bend
	var hand: Vector2 = shoulder + arm_dir * arm_len

	# Upper arm
	draw_line(shoulder, elbow, _tc(SKIN_DK), 8.0)
	draw_line(shoulder, elbow, _tc(SKIN), 6.0)
	# Lower arm
	draw_line(elbow, hand, _tc(SKIN_DK), 7.0)
	draw_line(elbow, hand, _tc(SKIN), 5.0)
	# Shoulder joint
	draw_circle(shoulder, 6.0, _tc(DRESS_LT))
	# Elbow joint
	draw_circle(elbow, 4.0, _tc(SKIN_LT))
	# Hand
	draw_circle(hand, 6.0, _tc(SKIN_LT))

	# Clawed fingernails
	for f: int in range(3):
		var nail_offset: Vector2 = Vector2(cos(base_angle + (f - 1) * 0.3), sin(base_angle + (f - 1) * 0.3)) * 8.0
		var nail_tip: Vector2 = hand + nail_offset + arm_dir * 4.0
		draw_line(hand + nail_offset, nail_tip, _tc(Color(0.15, 0.05, 0.05)), 2.0)
		draw_circle(nail_tip, 1.5, _tc(NAIL_POLISH))

	# Draw held item
	var item_pos: Vector2 = hand + arm_dir * 16.0
	match item:
		"gothic_mirror": _draw_item_gothic_mirror(item_pos, base_angle)
		"gothic_comb": _draw_item_gothic_comb(item_pos, base_angle)
		"gothic_nail_polish": _draw_item_gothic_nail_polish(item_pos)
		"gothic_brush": _draw_item_gothic_brush(item_pos, base_angle)
		"gothic_lipstick": _draw_item_gothic_lipstick(item_pos, base_angle)
		"gothic_powder": _draw_item_gothic_powder(item_pos)
		"gothic_perfume": _draw_item_gothic_perfume(item_pos)
		"gothic_scissors": _draw_item_gothic_scissors(item_pos, base_angle)
		"gothic_razor": _draw_item_gothic_razor(item_pos, base_angle)

# ── Gothic Held Items ────────────────────────────────────────

func _draw_item_gothic_mirror(pos: Vector2, angle: float) -> void:
	var handle_dir: Vector2 = Vector2(cos(angle), sin(angle))
	# Iron handle with spikes
	draw_line(pos - handle_dir * 10, pos, _tc(IRON), 4.0)
	draw_line(pos - handle_dir * 5 + Vector2(-3, -3), pos - handle_dir * 5 + Vector2(-6, -6), _tc(IRON_LT), 2.0)
	# Dark iron frame
	var pts: PackedVector2Array = []
	for i: int in range(16):
		var a: float = TAU * i / 16.0
		pts.append(pos + handle_dir * 9 + Vector2(cos(a) * 13.0, sin(a) * 17.0))
	draw_colored_polygon(pts, _tc(MIRROR_FRAME))
	# Blood-red glass with crack
	var glass_pts: PackedVector2Array = []
	for i: int in range(16):
		var a: float = TAU * i / 16.0
		glass_pts.append(pos + handle_dir * 9 + Vector2(cos(a) * 10.0, sin(a) * 14.0))
	draw_colored_polygon(glass_pts, _tc(MIRROR_GLASS))
	# Crack lines
	var center: Vector2 = pos + handle_dir * 9
	draw_line(center + Vector2(-3, -5), center + Vector2(2, 3), _tc(Color(0.15, 0.05, 0.05, 0.7)), 1.2)
	draw_line(center + Vector2(2, 3), center + Vector2(6, 1), _tc(Color(0.15, 0.05, 0.05, 0.7)), 1.0)
	draw_line(center + Vector2(2, 3), center + Vector2(0, 8), _tc(Color(0.15, 0.05, 0.05, 0.7)), 1.0)

func _draw_item_gothic_comb(pos: Vector2, _angle: float) -> void:
	# Bone comb body
	draw_rect(Rect2(pos.x - 11, pos.y - 3, 22, 6), _tc(BONE))
	draw_rect(Rect2(pos.x - 11, pos.y - 3, 22, 2), _tc(BONE_DK))
	# Jagged bone teeth
	for i: int in range(8):
		var tx: float = pos.x - 10 + 2.8 * i
		var tooth_len: float = 10.0 + sin(float(i) * 1.5) * 3.0
		draw_line(Vector2(tx, pos.y + 3), Vector2(tx, pos.y + tooth_len), _tc(BONE), 1.8)
		draw_circle(Vector2(tx, pos.y + tooth_len), 0.8, _tc(BONE_DK))

func _draw_item_gothic_nail_polish(pos: Vector2) -> void:
	# Dark bottle with skull cap
	draw_rect(Rect2(pos.x - 6, pos.y - 5, 12, 14), _tc(Color(0.15, 0.05, 0.10)))
	draw_rect(Rect2(pos.x - 4, pos.y - 1, 8, 8), _tc(BLOOD))
	# Skull cap
	draw_circle(Vector2(pos.x, pos.y - 8), 5.0, _tc(BONE))
	draw_circle(Vector2(pos.x - 1.5, pos.y - 9), 1.2, _tc(Color(0.1, 0.05, 0.05)))
	draw_circle(Vector2(pos.x + 1.5, pos.y - 9), 1.2, _tc(Color(0.1, 0.05, 0.05)))

func _draw_item_gothic_brush(pos: Vector2, angle: float) -> void:
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	# Dark handle with thorns
	draw_line(pos - dir * 12, pos, _tc(BRUSH_HANDLE), 3.5)
	draw_line(pos - dir * 8 + Vector2(0, -4), pos - dir * 8 + Vector2(0, -7), _tc(BRUSH_HANDLE), 1.5)
	draw_line(pos - dir * 4 + Vector2(0, 4), pos - dir * 4 + Vector2(0, 7), _tc(BRUSH_HANDLE), 1.5)
	# Wire brush head
	draw_circle(pos + dir * 7, 8.0, _tc(IRON))
	# Wire bristles
	for i: int in range(5):
		var bristle_a: float = angle + (i - 2) * 0.4
		var bd: Vector2 = Vector2(cos(bristle_a), sin(bristle_a))
		draw_line(pos + dir * 7, pos + dir * 7 + bd * 8, _tc(BRUSH_TIP), 1.2)

func _draw_item_gothic_lipstick(pos: Vector2, angle: float) -> void:
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	# Black iron tube
	draw_line(pos - dir * 9, pos, _tc(LIPSTICK_TUBE), 6.0)
	# Dark blood-red tip
	draw_line(pos, pos + dir * 7, _tc(BLOOD), 5.0)
	draw_line(pos + dir * 4, pos + dir * 7, _tc(Color(0.85, 0.08, 0.12)), 3.5)

func _draw_item_gothic_powder(pos: Vector2) -> void:
	# Iron compact with pentagram
	draw_circle(pos, 11.0, _tc(IRON))
	draw_circle(pos, 9.0, _tc(IRON_LT))
	# Pentagram scratched into surface
	for i: int in range(5):
		var a1: float = -PI / 2.0 + TAU * i / 5.0
		var a2: float = -PI / 2.0 + TAU * ((i + 2) % 5) / 5.0
		var p1: Vector2 = pos + Vector2(cos(a1), sin(a1)) * 7.0
		var p2: Vector2 = pos + Vector2(cos(a2), sin(a2)) * 7.0
		draw_line(p1, p2, _tc(BLOOD), 1.0)

func _draw_item_gothic_perfume(pos: Vector2) -> void:
	# Dark vial
	draw_rect(Rect2(pos.x - 5, pos.y - 7, 10, 16), _tc(Color(0.25, 0.10, 0.20, 0.8)))
	# Thorned wire around bottle
	for i: int in range(3):
		var ty: float = pos.y - 4 + 5.0 * i
		draw_line(Vector2(pos.x - 6, ty), Vector2(pos.x + 6, ty), _tc(IRON), 1.0)
		draw_line(Vector2(pos.x - 7, ty), Vector2(pos.x - 7, ty - 3), _tc(IRON_LT), 1.0)
		draw_line(Vector2(pos.x + 7, ty), Vector2(pos.x + 7, ty - 3), _tc(IRON_LT), 1.0)
	# Skull stopper
	draw_circle(Vector2(pos.x, pos.y - 10), 4.0, _tc(BONE))

func _draw_item_gothic_scissors(pos: Vector2, angle: float) -> void:
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	# Two black iron blades
	draw_line(pos - dir * 2 + perp * 2, pos + dir * 16 + perp * 4, _tc(IRON), 2.5)
	draw_line(pos - dir * 2 - perp * 2, pos + dir * 16 - perp * 4, _tc(IRON), 2.5)
	# Blade edges
	draw_line(pos + dir * 8 + perp * 3, pos + dir * 16 + perp * 4, _tc(IRON_LT), 1.2)
	draw_line(pos + dir * 8 - perp * 3, pos + dir * 16 - perp * 4, _tc(IRON_LT), 1.2)
	# Pivot joint
	draw_circle(pos + dir * 2, 3.0, _tc(IRON))
	# Finger loops
	draw_circle(pos - dir * 6 + perp * 3, 4.0, _tc(IRON))
	draw_circle(pos - dir * 6 - perp * 3, 4.0, _tc(IRON))
	draw_circle(pos - dir * 6 + perp * 3, 2.5, _tc(Color(0.1, 0.08, 0.1)))
	draw_circle(pos - dir * 6 - perp * 3, 2.5, _tc(Color(0.1, 0.08, 0.1)))

func _draw_item_gothic_razor(pos: Vector2, angle: float) -> void:
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	# Handle
	draw_line(pos - dir * 8, pos, _tc(BRUSH_HANDLE), 4.0)
	# Blade — wide, shiny
	var blade_start: Vector2 = pos + dir * 2
	var blade_end: Vector2 = pos + dir * 18
	draw_line(blade_start, blade_end, _tc(IRON_LT), 5.0)
	draw_line(blade_start, blade_end, _tc(Color(0.50, 0.48, 0.52)), 3.0)
	# Blood on blade
	draw_line(pos + dir * 8, pos + dir * 14 + Vector2(0, 3), _tc(BLOOD), 1.5)
	draw_circle(pos + dir * 12 + Vector2(1, 4), 2.0, _tc(BLOOD))

# ── Arm Explosion Particles ──────────────────────────────────

func _draw_arm_explosions() -> void:
	for exp: Dictionary in _arm_explosions:
		var particles: Array = exp["particles"]
		for p: Dictionary in particles:
			if p["life"] <= 0.0:
				continue
			var alpha: float = clampf(p["life"], 0.0, 1.0)
			var c: Color = p["color"]
			c.a = alpha
			var radius: float = 3.0 + (1.0 - alpha) * 4.0
			draw_circle(p["pos"], radius, _tc(c))

# ── Cast flash overlay ───────────────────────────────────────

func _draw_cast_flash() -> void:
	if cast_anim <= 0.01:
		return
	var flash_c := Color(1.0, 0.5, 0.3, cast_anim * 0.3)
	draw_circle(Vector2(0, bob_y), 175.0, flash_c)
