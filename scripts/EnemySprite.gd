class_name EnemySprite
extends Control

enum EType { DEMON, IMP, HELLHOUND }
var etype: EType = EType.DEMON

# ── Animated properties ──────────────────────────────────────────────────
var bob_y: float = 0.0
var hurt_flash: float = 0.0
var hurt_offset: float = 0.0

var _idle_tween: Tween

# ── Colors per type ──────────────────────────────────────────────────────
const PALETTES := {
	EType.DEMON: {
		"body":     Color(0.55, 0.08, 0.08),
		"body_dk":  Color(0.38, 0.04, 0.04),
		"body_lt":  Color(0.72, 0.15, 0.10),
		"skin":     Color(0.70, 0.30, 0.25),
		"horn":     Color(0.25, 0.12, 0.08),
		"eye":      Color(1.0, 0.85, 0.0, 0.95),
		"accent":   Color(0.90, 0.30, 0.05),
	},
	EType.IMP: {
		"body":     Color(0.45, 0.18, 0.50),
		"body_dk":  Color(0.30, 0.10, 0.35),
		"body_lt":  Color(0.60, 0.28, 0.65),
		"skin":     Color(0.55, 0.35, 0.55),
		"horn":     Color(0.20, 0.10, 0.15),
		"eye":      Color(0.0, 1.0, 0.4, 0.95),
		"accent":   Color(0.80, 0.20, 0.70),
	},
	EType.HELLHOUND: {
		"body":     Color(0.20, 0.20, 0.22),
		"body_dk":  Color(0.10, 0.10, 0.12),
		"body_lt":  Color(0.35, 0.30, 0.28),
		"skin":     Color(0.30, 0.22, 0.18),
		"horn":     Color(0.12, 0.08, 0.06),
		"eye":      Color(1.0, 0.25, 0.0, 0.95),
		"accent":   Color(0.90, 0.45, 0.05),
	},
}

# ── Lifecycle ────────────────────────────────────────────────────────────
func _init(type: EType = EType.DEMON) -> void:
	etype = type
	custom_minimum_size = Vector2(90, 120)

func _ready() -> void:
	_start_idle()

func _process(_delta: float) -> void:
	queue_redraw()

# ── Idle animation ───────────────────────────────────────────────────────
func _start_idle() -> void:
	_kill_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "bob_y", -3.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "bob_y", 0.0, 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _kill_idle() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null
	bob_y = 0.0

# ── Attack animation ────────────────────────────────────────────────────
func play_attack() -> void:
	_kill_idle()
	var tw := create_tween()
	tw.tween_property(self, "hurt_offset", 12.0, 0.10) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "hurt_offset", 0.0, 0.20) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	_start_idle()

# ── Hurt animation ──────────────────────────────────────────────────────
func play_hurt() -> void:
	_kill_idle()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "hurt_flash", 1.0, 0.06)
	tw.tween_property(self, "hurt_offset", -8.0, 0.06)
	await tw.finished
	var tw2 := create_tween().set_parallel(true)
	tw2.tween_property(self, "hurt_flash", 0.0, 0.25)
	tw2.tween_property(self, "hurt_offset", 0.0, 0.25) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await tw2.finished
	_start_idle()

# ── Death animation ─────────────────────────────────────────────────────
func play_die() -> void:
	_kill_idle()
	hurt_flash = 0.0
	hurt_offset = 0.0
	pivot_offset = Vector2(45, 110)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "rotation", -1.4, 0.65) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate", Color(1.0, 0.15, 0.1, 0.0), 0.65)
	tw.tween_property(self, "hurt_flash", 0.6, 0.15)
	await tw.finished
	visible = false

# ── Color helper ─────────────────────────────────────────────────────────
func _tc(base: Color) -> Color:
	return base.lerp(Color(1.0, 1.0, 1.0), hurt_flash * 0.7)

func _pal() -> Dictionary:
	return PALETTES[etype]

# ── Draw ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	match etype:
		EType.DEMON:     _draw_demon()
		EType.IMP:       _draw_imp()
		EType.HELLHOUND: _draw_hellhound()

# ── DEMON: tall muscular brute with horns ────────────────────────────────
func _draw_demon() -> void:
	var p := _pal()
	var ox := hurt_offset
	var oy := bob_y
	var cx := 45.0 + ox

	# Legs
	draw_rect(Rect2(cx - 13, 72 + oy, 12, 32), _tc(p["body_dk"]))
	draw_rect(Rect2(cx + 1, 72 + oy, 12, 32), _tc(p["body_dk"]))
	# Hooves
	draw_rect(Rect2(cx - 15, 100 + oy, 16, 10), _tc(p["horn"]))
	draw_rect(Rect2(cx - 1, 100 + oy, 16, 10), _tc(p["horn"]))

	# Torso
	draw_rect(Rect2(cx - 18, 34 + oy, 36, 40), _tc(p["body"]))
	# Chest muscles
	draw_rect(Rect2(cx - 14, 38 + oy, 12, 8), _tc(p["body_lt"]))
	draw_rect(Rect2(cx + 2, 38 + oy, 12, 8), _tc(p["body_lt"]))
	# Belly scar
	draw_line(Vector2(cx - 4, 54 + oy), Vector2(cx + 6, 62 + oy), _tc(p["skin"]), 1.5)

	# Arms
	draw_rect(Rect2(cx - 26, 36 + oy, 10, 28), _tc(p["body"]))
	draw_rect(Rect2(cx + 16, 36 + oy, 10, 28), _tc(p["body"]))
	# Claws
	draw_rect(Rect2(cx - 27, 62 + oy, 4, 7), _tc(p["accent"]))
	draw_rect(Rect2(cx - 22, 62 + oy, 4, 7), _tc(p["accent"]))
	draw_rect(Rect2(cx + 18, 62 + oy, 4, 7), _tc(p["accent"]))
	draw_rect(Rect2(cx + 23, 62 + oy, 4, 7), _tc(p["accent"]))

	# Neck
	draw_rect(Rect2(cx - 5, 28 + oy, 10, 8), _tc(p["skin"]))

	# Head
	draw_circle(Vector2(cx, 18 + oy), 14.0, _tc(p["body"]))
	# Brow ridge
	draw_rect(Rect2(cx - 12, 12 + oy, 24, 5), _tc(p["body_dk"]))
	# Eyes
	draw_rect(Rect2(cx - 8, 16 + oy, 6, 4), _tc(p["eye"]))
	draw_rect(Rect2(cx + 2, 16 + oy, 6, 4), _tc(p["eye"]))
	# Mouth
	draw_rect(Rect2(cx - 6, 24 + oy, 12, 3), _tc(p["body_dk"]))
	# Fangs
	draw_rect(Rect2(cx - 5, 26 + oy, 3, 4), _tc(Color.WHITE))
	draw_rect(Rect2(cx + 2, 26 + oy, 3, 4), _tc(Color.WHITE))

	# Horns
	draw_rect(Rect2(cx - 16, 4 + oy, 6, 14), _tc(p["horn"]))
	draw_rect(Rect2(cx - 18, 2 + oy, 4, 6), _tc(p["horn"]))
	draw_rect(Rect2(cx + 10, 4 + oy, 6, 14), _tc(p["horn"]))
	draw_rect(Rect2(cx + 14, 2 + oy, 4, 6), _tc(p["horn"]))


# ── IMP: small hunched creature with wings ───────────────────────────────
func _draw_imp() -> void:
	var p := _pal()
	var ox := hurt_offset
	var oy := bob_y + 16.0  # shorter, offset down
	var cx := 45.0 + ox

	# Tail (behind body)
	draw_line(Vector2(cx + 8, 62 + oy), Vector2(cx + 28, 50 + oy), _tc(p["body_dk"]), 3.0)
	draw_line(Vector2(cx + 28, 50 + oy), Vector2(cx + 32, 44 + oy), _tc(p["accent"]), 2.5)

	# Wings (behind body)
	var wing_col := _tc(p["body_dk"])
	# Left wing
	draw_line(Vector2(cx - 10, 30 + oy), Vector2(cx - 30, 14 + oy), wing_col, 2.5)
	draw_line(Vector2(cx - 30, 14 + oy), Vector2(cx - 22, 28 + oy), wing_col, 2.0)
	draw_line(Vector2(cx - 30, 14 + oy), Vector2(cx - 16, 22 + oy), wing_col, 2.0)
	# Right wing
	draw_line(Vector2(cx + 10, 30 + oy), Vector2(cx + 30, 14 + oy), wing_col, 2.5)
	draw_line(Vector2(cx + 30, 14 + oy), Vector2(cx + 22, 28 + oy), wing_col, 2.0)
	draw_line(Vector2(cx + 30, 14 + oy), Vector2(cx + 16, 22 + oy), wing_col, 2.0)

	# Legs (short and spindly)
	draw_rect(Rect2(cx - 10, 60 + oy, 8, 20), _tc(p["body_dk"]))
	draw_rect(Rect2(cx + 2, 60 + oy, 8, 20), _tc(p["body_dk"]))
	# Feet
	draw_rect(Rect2(cx - 12, 78 + oy, 12, 6), _tc(p["horn"]))
	draw_rect(Rect2(cx + 0, 78 + oy, 12, 6), _tc(p["horn"]))

	# Body (small, hunched)
	draw_rect(Rect2(cx - 12, 30 + oy, 24, 32), _tc(p["body"]))
	# Belly
	draw_rect(Rect2(cx - 8, 44 + oy, 16, 12), _tc(p["body_lt"]))

	# Arms (thin)
	draw_rect(Rect2(cx - 20, 32 + oy, 8, 22), _tc(p["body"]))
	draw_rect(Rect2(cx + 12, 32 + oy, 8, 22), _tc(p["body"]))
	# Claws
	draw_rect(Rect2(cx - 21, 52 + oy, 3, 5), _tc(p["accent"]))
	draw_rect(Rect2(cx - 17, 52 + oy, 3, 5), _tc(p["accent"]))
	draw_rect(Rect2(cx + 14, 52 + oy, 3, 5), _tc(p["accent"]))
	draw_rect(Rect2(cx + 18, 52 + oy, 3, 5), _tc(p["accent"]))

	# Head (large relative to body)
	draw_circle(Vector2(cx, 18 + oy), 13.0, _tc(p["body"]))
	# Big eyes
	draw_rect(Rect2(cx - 9, 14 + oy, 7, 6), _tc(Color(0.0, 0.0, 0.0)))
	draw_rect(Rect2(cx + 2, 14 + oy, 7, 6), _tc(Color(0.0, 0.0, 0.0)))
	draw_rect(Rect2(cx - 7, 15 + oy, 4, 4), _tc(p["eye"]))
	draw_rect(Rect2(cx + 3, 15 + oy, 4, 4), _tc(p["eye"]))
	# Grin
	draw_rect(Rect2(cx - 6, 24 + oy, 12, 2), _tc(p["body_dk"]))
	draw_rect(Rect2(cx - 4, 25 + oy, 2, 3), _tc(Color.WHITE))
	draw_rect(Rect2(cx + 2, 25 + oy, 2, 3), _tc(Color.WHITE))

	# Small horns
	draw_rect(Rect2(cx - 12, 8 + oy, 4, 8), _tc(p["horn"]))
	draw_rect(Rect2(cx + 8, 8 + oy, 4, 8), _tc(p["horn"]))
	# Pointed ears
	draw_rect(Rect2(cx - 16, 14 + oy, 6, 4), _tc(p["body_lt"]))
	draw_rect(Rect2(cx + 10, 14 + oy, 6, 4), _tc(p["body_lt"]))


# ── HELLHOUND: four-legged beast with fiery mane ────────────────────────
func _draw_hellhound() -> void:
	var p := _pal()
	var ox := hurt_offset
	var oy := bob_y + 20.0  # lower stance
	var cx := 45.0 + ox

	# Tail (raised, fiery tip)
	draw_line(Vector2(cx + 24, 38 + oy), Vector2(cx + 38, 22 + oy), _tc(p["body"]), 4.0)
	draw_line(Vector2(cx + 38, 22 + oy), Vector2(cx + 42, 16 + oy), _tc(p["accent"]), 3.0)
	draw_line(Vector2(cx + 42, 16 + oy), Vector2(cx + 40, 10 + oy), _tc(Color(1.0, 0.6, 0.0)), 2.0)

	# Back legs
	draw_rect(Rect2(cx + 12, 52 + oy, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(cx + 18, 52 + oy, 10, 22), _tc(p["body_dk"]))
	# Back paws
	draw_rect(Rect2(cx + 10, 72 + oy, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(cx + 18, 72 + oy, 14, 8), _tc(p["horn"]))

	# Front legs
	draw_rect(Rect2(cx - 24, 52 + oy, 10, 22), _tc(p["body_dk"]))
	draw_rect(Rect2(cx - 18, 52 + oy, 10, 22), _tc(p["body_dk"]))
	# Front paws
	draw_rect(Rect2(cx - 26, 72 + oy, 14, 8), _tc(p["horn"]))
	draw_rect(Rect2(cx - 18, 72 + oy, 14, 8), _tc(p["horn"]))

	# Body (long, horizontal)
	draw_rect(Rect2(cx - 22, 32 + oy, 48, 24), _tc(p["body"]))
	# Rib lines
	draw_line(Vector2(cx - 8, 36 + oy), Vector2(cx - 10, 50 + oy), _tc(p["body_lt"]), 1.2)
	draw_line(Vector2(cx - 2, 35 + oy), Vector2(cx - 4, 50 + oy), _tc(p["body_lt"]), 1.2)
	draw_line(Vector2(cx + 4, 35 + oy), Vector2(cx + 2, 50 + oy), _tc(p["body_lt"]), 1.2)

	# Spine ridge
	draw_rect(Rect2(cx - 18, 30 + oy, 40, 4), _tc(p["body_lt"]))

	# Fiery mane (jagged shapes along neck/back)
	var mane_col := _tc(p["accent"])
	draw_rect(Rect2(cx - 20, 24 + oy, 5, 10), mane_col)
	draw_rect(Rect2(cx - 14, 22 + oy, 5, 12), mane_col)
	draw_rect(Rect2(cx - 8, 24 + oy, 5, 10), mane_col)
	draw_rect(Rect2(cx - 18, 20 + oy, 3, 6), _tc(Color(1.0, 0.6, 0.0)))
	draw_rect(Rect2(cx - 12, 18 + oy, 3, 6), _tc(Color(1.0, 0.6, 0.0)))

	# Head (angular, snout)
	draw_rect(Rect2(cx - 30, 30 + oy, 16, 16), _tc(p["body"]))
	# Snout
	draw_rect(Rect2(cx - 38, 36 + oy, 10, 10), _tc(p["body_lt"]))
	# Nose
	draw_rect(Rect2(cx - 38, 37 + oy, 4, 3), _tc(p["horn"]))
	# Jaw
	draw_rect(Rect2(cx - 36, 44 + oy, 8, 3), _tc(p["body_dk"]))
	# Teeth
	draw_rect(Rect2(cx - 35, 43 + oy, 2, 3), _tc(Color.WHITE))
	draw_rect(Rect2(cx - 31, 43 + oy, 2, 3), _tc(Color.WHITE))

	# Eyes (fierce, glowing)
	draw_rect(Rect2(cx - 28, 32 + oy, 5, 4), _tc(p["eye"]))
	draw_rect(Rect2(cx - 20, 32 + oy, 5, 4), _tc(p["eye"]))

	# Ears
	draw_rect(Rect2(cx - 30, 24 + oy, 5, 8), _tc(p["body_dk"]))
	draw_rect(Rect2(cx - 22, 24 + oy, 5, 8), _tc(p["body_dk"]))
