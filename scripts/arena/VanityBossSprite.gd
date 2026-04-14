extends Node2D

var hurt_flash: float = 0.0
var bob_y: float = 0.0
var _arm_sway: float = 0.0

var _idle_tween: Tween
var _hurt_tween: Tween
var _sway_tween: Tween
var _anim_sprite: AnimatedSprite2D

# Arm destruction state
var arms_alive: Array[bool] = [true, true, true, true, true, true, true, true, true, true]
var _arm_explosions: Array[Dictionary] = []
const ARM_DESTROY_ORDER: Array[int] = [0, 9, 1, 8, 2, 7, 3, 6, 4, 5]

# Colors — vivid crimson demon
const SKIN     := Color(0.80, 0.10, 0.10)
const SKIN_DK  := Color(0.47, 0.04, 0.04)
const SKIN_LT  := Color(0.91, 0.25, 0.22)
const GOLD     := Color(0.75, 0.55, 0.10)
const GOLD_DK  := Color(0.45, 0.30, 0.04)
const NAIL_POLISH := Color(0.85, 0.04, 0.18)
const IRON     := Color(0.22, 0.20, 0.22)
const BLOOD    := Color(0.72, 0.02, 0.04)
const MIRROR_GLASS := Color(0.28, 0.38, 0.50)
const COMB_C   := Color(0.70, 0.65, 0.55)
const BRUSH_TIP := Color(0.55, 0.55, 0.55)
const LIPS     := Color(0.88, 0.03, 0.10)
const POWDER   := Color(0.90, 0.55, 0.60)
const PERFUME  := Color(0.50, 0.20, 0.60)

# 10 arms — angles in local space, length in local pixels
# body_r: shoulder starts at edge of sprite body (~55 local px)
const BODY_R: float = 55.0
const ARM_DATA: Array[Dictionary] = [
	{ "angle": -2.6, "len": 62, "item": "mirror"    },
	{ "angle": -2.1, "len": 58, "item": "comb"      },
	{ "angle": -1.6, "len": 65, "item": "nail"      },
	{ "angle": -1.1, "len": 55, "item": "brush"     },
	{ "angle": -0.6, "len": 60, "item": "lipstick"  },
	{ "angle":  0.6, "len": 60, "item": "powder"    },
	{ "angle":  1.1, "len": 55, "item": "perfume"   },
	{ "angle":  1.6, "len": 65, "item": "scissors"  },
	{ "angle":  2.1, "len": 58, "item": "razor"     },
	{ "angle":  2.6, "len": 62, "item": "mirror"    },
]

const FRAME_W: int = 128
const SHEET_PATH: String = "res://assets/sprites/enemies/vanity_boss/vanity_boss.png"

func _ready() -> void:
	_anim_sprite = AnimatedSprite2D.new()
	_anim_sprite.centered = true
	_anim_sprite.animation_finished.connect(_on_animation_finished)
	add_child(_anim_sprite)

	var tex: Texture2D = load(SHEET_PATH)
	var frames: SpriteFrames = SpriteFrames.new()

	_add_anim(frames, tex, "idle",   [0, 1, 2, 3, 2, 1], [180, 180, 180, 180, 180, 180], true)
	_add_anim(frames, tex, "attack", [4, 5, 6],           [80, 120, 160],                 false)
	_add_anim(frames, tex, "cast",   [7, 8, 9],           [80, 120, 160],                 false)
	_add_anim(frames, tex, "hurt",   [10, 11],            [60, 120],                      false)
	_add_anim(frames, tex, "die",    [12, 13, 14, 15],    [150, 180, 240, 300],           false)

	_anim_sprite.sprite_frames = frames

func _add_anim(frames: SpriteFrames, tex: Texture2D, anim_name: String,
		frame_indices: Array, durations_ms: Array, looping: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, looping)
	frames.set_animation_speed(anim_name, 1.0)
	for i: int in frame_indices.size():
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(frame_indices[i] * FRAME_W, 0, FRAME_W, FRAME_W)
		frames.add_frame(anim_name, atlas, durations_ms[i] / 1000.0)

func _process(delta: float) -> void:
	if _anim_sprite:
		_anim_sprite.self_modulate = Color(
			1.0 + hurt_flash * 0.7,
			1.0 - hurt_flash * 0.3,
			1.0 - hurt_flash * 0.5, 1.0)
		_anim_sprite.position.y = bob_y
	var i: int = _arm_explosions.size() - 1
	while i >= 0:
		var exp: Dictionary = _arm_explosions[i]
		exp["time"] += delta
		if exp["time"] >= exp["max_time"]:
			_arm_explosions.remove_at(i)
		else:
			for p: Dictionary in exp["particles"]:
				p["pos"] += p["vel"] * delta
				p["vel"] *= 0.96
				p["life"] -= delta * 1.5
		i -= 1
	queue_redraw()

func _draw() -> void:
	_draw_arms()
	for exp: Dictionary in _arm_explosions:
		var fade: float = 1.0 - exp["time"] / exp["max_time"]
		for p: Dictionary in exp["particles"]:
			var c: Color = p["color"]
			c.a = clampf(p["life"], 0.0, 1.0) * fade
			draw_circle(p["pos"], 2.5, c)

func _draw_arms() -> void:
	var flash_mod: Color = Color(1.0 + hurt_flash * 0.7, 1.0 - hurt_flash * 0.3, 1.0 - hurt_flash * 0.5, 1.0)
	for idx: int in ARM_DATA.size():
		if not arms_alive[idx]:
			continue
		var data: Dictionary = ARM_DATA[idx]
		var base_angle: float = data["angle"]
		# Gentle per-arm sway offset
		var sway_offset: float = sin(base_angle * 2.3 + _arm_sway * TAU) * 0.12
		var angle: float = base_angle + sway_offset
		var arm_dir: Vector2 = Vector2(cos(angle), sin(angle))
		var shoulder: Vector2 = arm_dir * BODY_R + Vector2(0.0, bob_y)
		var elbow: Vector2 = shoulder + arm_dir * (data["len"] * 0.5)
		var hand: Vector2 = shoulder + arm_dir * data["len"]

		# Shadow under arm
		draw_line(shoulder + Vector2(1.5, 1.5), hand + Vector2(1.5, 1.5),
			Color(0.0, 0.0, 0.0, 0.25), 7.0)

		# Upper arm — thick flesh
		var upper_col: Color = _tint(SKIN_DK, flash_mod)
		draw_line(shoulder, elbow, upper_col, 8.0)
		# Lower arm — slightly lighter
		var lower_col: Color = _tint(SKIN, flash_mod)
		draw_line(elbow, hand, lower_col, 6.0)
		# Elbow joint
		draw_circle(elbow, 5.0, _tint(SKIN_DK, flash_mod))
		# Knuckle at hand
		draw_circle(hand, 4.0, _tint(SKIN_LT, flash_mod))
		# Vein stripe along upper arm
		draw_line(shoulder + arm_dir.orthogonal() * 1.5,
			elbow + arm_dir.orthogonal() * 1.5,
			Color(0.30, 0.04, 0.08, 0.5), 1.5)

		# Item held at tip
		_draw_item(hand, angle, data["item"], flash_mod)

func _draw_item(pos: Vector2, angle: float, item: String, flash_mod: Color) -> void:
	var perp: Vector2 = Vector2(-sin(angle), cos(angle))
	var fwd: Vector2 = Vector2(cos(angle), sin(angle))
	match item:
		"mirror":
			# Gothic hand mirror — oval glass + handle
			var frame_col: Color = _tint(GOLD, flash_mod)
			draw_circle(pos, 7.0, frame_col)
			draw_circle(pos, 5.5, _tint(MIRROR_GLASS, flash_mod))
			draw_circle(pos, 3.0, Color(0.7, 0.85, 1.0, 0.6))
			draw_line(pos, pos + fwd * 8.0, frame_col, 3.0)
			draw_circle(pos + fwd * 8.0, 2.0, _tint(GOLD_DK, flash_mod))
		"comb":
			# Wide comb with teeth
			var comb_col: Color = _tint(COMB_C, flash_mod)
			draw_line(pos - perp * 6.0, pos + perp * 6.0, comb_col, 3.0)
			for t: int in range(-5, 6):
				var base_pt: Vector2 = pos + perp * float(t) * 1.1
				draw_line(base_pt, base_pt + fwd * 5.0, comb_col, 1.5)
		"nail":
			# Nail polish bottle
			var bottle_col: Color = _tint(NAIL_POLISH, flash_mod)
			draw_circle(pos, 5.0, _tint(Color(0.1, 0.08, 0.1), flash_mod))
			draw_circle(pos, 3.5, bottle_col)
			draw_line(pos + fwd * 4.0, pos + fwd * 9.0, bottle_col, 2.5)
			draw_circle(pos + fwd * 9.0, 2.0, _tint(Color(0.9, 0.9, 0.9), flash_mod))
		"brush":
			# Makeup brush — handle + splayed tip
			var handle_col: Color = _tint(Color(0.35, 0.12, 0.08), flash_mod)
			draw_line(pos, pos + fwd * 10.0, handle_col, 3.0)
			for t: int in range(-3, 4):
				var tip_base: Vector2 = pos + fwd * 2.0
				var tip_end: Vector2 = tip_base + perp * float(t) * 2.0 - fwd * 5.0
				draw_line(tip_base, tip_end, _tint(BRUSH_TIP, flash_mod), 1.2)
		"lipstick":
			# Lipstick tube — cylinder with exposed tip
			var tube_col: Color = _tint(Color(0.15, 0.10, 0.15), flash_mod)
			draw_circle(pos, 3.5, tube_col)
			draw_line(pos, pos - fwd * 7.0, tube_col, 5.0)
			draw_circle(pos - fwd * 7.0, 3.0, tube_col)
			draw_circle(pos, 3.0, _tint(LIPS, flash_mod))
		"powder":
			# Powder puff — fluffy circle
			var puff_col: Color = _tint(POWDER, flash_mod)
			draw_circle(pos, 7.0, Color(puff_col.r, puff_col.g, puff_col.b, 0.5))
			draw_circle(pos, 5.0, puff_col)
			for t: int in range(6):
				var a2: float = float(t) / 6.0 * TAU
				draw_circle(pos + Vector2(cos(a2), sin(a2)) * 5.0, 2.5, puff_col)
		"perfume":
			# Perfume bottle — square with spray top
			var perf_col: Color = _tint(PERFUME, flash_mod)
			draw_rect(Rect2(pos - perp * 4.0 - fwd * 4.0, Vector2(8.0, 8.0)), perf_col)
			draw_rect(Rect2(pos - perp * 4.0 - fwd * 4.0, Vector2(8.0, 8.0)),
				Color(perf_col.r * 1.4, perf_col.g * 1.4, perf_col.b * 1.4, 0.6), false, 1.5)
			draw_line(pos - fwd * 4.0, pos - fwd * 9.0,
				_tint(Color(0.75, 0.75, 0.75), flash_mod), 2.0)
		"scissors":
			# Scissors — two crossing lines
			var sc_col: Color = _tint(IRON, flash_mod)
			draw_line(pos - perp * 5.0 + fwd * 3.0, pos + perp * 5.0 - fwd * 3.0, sc_col, 2.5)
			draw_line(pos + perp * 5.0 + fwd * 3.0, pos - perp * 5.0 - fwd * 3.0, sc_col, 2.5)
			draw_circle(pos, 2.5, _tint(Color(0.55, 0.50, 0.45), flash_mod))
		"razor":
			# Straight razor — thin rectangle with edge glint
			var blade_col: Color = _tint(Color(0.75, 0.72, 0.70), flash_mod)
			draw_line(pos - perp * 5.0 - fwd * 1.0, pos + perp * 5.0 - fwd * 1.0, blade_col, 4.0)
			draw_line(pos - perp * 5.0 - fwd * 1.0, pos + perp * 5.0 - fwd * 1.0,
				Color(1.0, 1.0, 1.0, 0.5), 1.0)
			draw_line(pos - perp * 4.0 + fwd * 3.0, pos + perp * 4.0 + fwd * 3.0,
				_tint(Color(0.25, 0.22, 0.22), flash_mod), 3.0)

func _tint(c: Color, mod: Color) -> Color:
	return Color(c.r * mod.r, c.g * mod.g, c.b * mod.b, c.a)

# ── Interface methods ──────────────────────────────────────────

func start_idle() -> void:
	if not _anim_sprite:
		return
	_anim_sprite.play("idle")
	_kill_idle()
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(self, "bob_y", -3.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_idle_tween.tween_property(self, "bob_y",  0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_kill_sway()
	_sway_tween = create_tween().set_loops()
	_sway_tween.tween_property(self, "_arm_sway", 1.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sway_tween.tween_property(self, "_arm_sway", 0.0, 2.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func start_walk() -> void:
	if _anim_sprite:
		_anim_sprite.play("idle")

func _stop_walk() -> void:
	if _anim_sprite:
		_anim_sprite.play("idle")

func set_facing_from_vec(dir: Vector2) -> void:
	if _anim_sprite and dir.x != 0.0:
		_anim_sprite.flip_h = dir.x < 0.0

func play_attack_wind_up() -> void:
	if _anim_sprite:
		_anim_sprite.play("attack")

func play_cast() -> void:
	if _anim_sprite:
		_anim_sprite.play("cast")

func play_hurt() -> void:
	if _hurt_tween and _hurt_tween.is_valid():
		_hurt_tween.kill()
	if _anim_sprite:
		_anim_sprite.play("hurt")
	_hurt_tween = create_tween()
	_hurt_tween.tween_property(self, "hurt_flash", 1.0, 0.06)
	_hurt_tween.chain().tween_property(self, "hurt_flash", 0.0, 0.2)
	await _hurt_tween.finished

func play_die() -> void:
	_kill_idle()
	_kill_sway()
	if _anim_sprite:
		_anim_sprite.play("die")
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color(1.0, 0.15, 0.1, 0.0), 0.5)
	tw.tween_property(self, "hurt_flash", 0.8, 0.1)
	await tw.finished
	visible = false

func destroy_arm(order_index: int) -> void:
	if order_index < 0 or order_index >= ARM_DESTROY_ORDER.size():
		return
	var arm_index: int = ARM_DESTROY_ORDER[order_index]
	if not arms_alive[arm_index]:
		return
	arms_alive[arm_index] = false
	var data: Dictionary = ARM_DATA[arm_index]
	var base_angle: float = data["angle"]
	var arm_dir: Vector2 = Vector2(cos(base_angle), sin(base_angle))
	var shoulder: Vector2 = arm_dir * BODY_R + Vector2(0.0, bob_y)
	var hand: Vector2 = shoulder + arm_dir * float(data["len"])
	var explosion: Dictionary = {
		"pos": hand,
		"particles": [],
		"time": 0.0,
		"max_time": 0.8,
	}
	var colors: Array = [SKIN, SKIN_LT, BLOOD, NAIL_POLISH, IRON]
	for _p: int in range(16):
		var angle: float = randf() * TAU
		var spd: float = randf_range(90.0, 220.0)
		explosion["particles"].append({
			"pos": hand,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"color": colors[randi() % colors.size()],
			"life": 1.0,
		})
	_arm_explosions.append(explosion)
	queue_redraw()

func _on_animation_finished() -> void:
	if not _anim_sprite:
		return
	var anim: String = _anim_sprite.animation
	if anim == "attack" or anim == "cast" or anim == "hurt":
		_anim_sprite.play("idle")

func _kill_idle() -> void:
	if _idle_tween and _idle_tween.is_valid():
		_idle_tween.kill()
	_idle_tween = null
	bob_y = 0.0

func _kill_sway() -> void:
	if _sway_tween and _sway_tween.is_valid():
		_sway_tween.kill()
	_sway_tween = null
	_arm_sway = 0.0
