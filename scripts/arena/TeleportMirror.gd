extends Node2D

const INTERACT_RANGE := 120.0

var cooldown: float = 15.0
var glow_color: Color = Color(0.3, 0.6, 1.0)
var partner: Node2D = null

var _player: CharacterBody2D
var _glow_time: float = 0.0
var _prompt_visible: bool = false
var _cooldown_timer: float = 0.0
var _is_teleporting: bool = false

# Teleport orb animation state
var _orb_active: bool = false
var _orb_pos: Vector2 = Vector2.ZERO
var _orb_target: Vector2 = Vector2.ZERO
var _orb_start: Vector2 = Vector2.ZERO
var _orb_progress: float = 0.0
var _orb_duration: float = 0.6
var _camera: Camera2D = null
var _camera_parent: Node = null

func init(player: CharacterBody2D, color: Color, linked_partner: Node2D, cd: float = 15.0) -> void:
	_player = player
	glow_color = color
	partner = linked_partner
	cooldown = cd
	add_to_group("interactable")
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4)
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_property(self, "scale", Vector2(2.0, 2.0), 0.15)

func _process(delta: float) -> void:
	_glow_time += delta
	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	var in_range := _is_player_in_range()
	if in_range != _prompt_visible:
		_prompt_visible = in_range

	if _orb_active:
		_orb_progress += delta / _orb_duration
		if _orb_progress >= 1.0:
			_orb_progress = 1.0
			_orb_active = false
			_finish_teleport()
		_orb_pos = _orb_start.lerp(_orb_target, _ease_out_cubic(_orb_progress))
		if _camera != null and is_instance_valid(_camera):
			_camera.global_position = to_global(_orb_pos)

	queue_redraw()

func _ease_out_cubic(t: float) -> float:
	var t1 := t - 1.0
	return t1 * t1 * t1 + 1.0

func _is_player_in_range() -> bool:
	if not is_instance_valid(_player):
		return false
	return global_position.distance_to(_player.global_position) <= INTERACT_RANGE

func interact() -> void:
	if _cooldown_timer > 0.0:
		return
	if not is_instance_valid(partner):
		return
	if _is_teleporting or partner._is_teleporting:
		return

	_cooldown_timer = cooldown
	partner._cooldown_timer = cooldown
	_is_teleporting = true

	_player.visible = false
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_player.hurtbox.collision_mask = 0

	# Reparent camera to scene root so it can follow the orb independently
	_camera = null
	for child in _player.get_children():
		if child is Camera2D:
			_camera = child
			break
	if _camera != null:
		_camera_parent = _camera.get_parent()
		var cam_global: Vector2 = _camera.global_position
		_camera_parent.remove_child(_camera)
		get_parent().add_child(_camera)
		_camera.global_position = cam_global

	_orb_start = Vector2.ZERO
	_orb_target = to_local(partner.global_position)
	_orb_pos = _orb_start
	_orb_progress = 0.0
	_orb_active = true
	SoundManager.play("teleport_out")

	_flash_effect()

func _finish_teleport() -> void:
	if not is_instance_valid(_player):
		return
	_player.global_position = partner.global_position + Vector2(0, 30)

	# Reparent camera back to player
	if _camera != null and is_instance_valid(_camera) and is_instance_valid(_camera_parent):
		_camera.get_parent().remove_child(_camera)
		_camera_parent.add_child(_camera)
		_camera.position = Vector2.ZERO
		_camera = null
		_camera_parent = null

	_player.visible = true
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)
	_player.hurtbox.collision_mask = 1 << 4
	_player.grant_iframes(GameData.effective_iframes())
	_is_teleporting = false
	SoundManager.play("teleport_in")
	partner._flash_effect()

func _flash_effect() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.08)
	tw.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

func _is_on_cooldown() -> bool:
	return _cooldown_timer > 0.0

func _draw() -> void:
	var on_cd := _is_on_cooldown()
	# Use exact glow_color for orb and active state; no glow at all on cooldown
	var col := glow_color
	var glow_alpha := 0.15 + 0.1 * sin(_glow_time * 3.0)

	# === BOSS MIRROR CHARGE EFFECT ===
	var charge_p: float = get_meta("charge_progress", -1.0)
	if charge_p > 0.0 and charge_p <= 1.0:
		# Intensifying red glow — pulsing faster as charge builds
		var pulse_speed := 4.0 + charge_p * 12.0
		var charge_alpha := charge_p * 0.8 + 0.1 * sin(_glow_time * pulse_speed)
		var charge_r := 60.0 + charge_p * 40.0
		draw_circle(Vector2(0, 0), charge_r, Color(1.0, 0.1, 0.05, charge_alpha * 0.5))
		draw_circle(Vector2(0, 0), charge_r * 0.7, Color(1.0, 0.2, 0.1, charge_alpha * 0.7))
		draw_circle(Vector2(0, 0), charge_r * 0.4, Color(1.0, 0.6, 0.3, charge_alpha * 0.6))
		# Shaking sparks
		for i in range(8):
			var sa := _glow_time * (3.0 + i * 0.5) + i * 0.785
			var sd := charge_r * (0.5 + 0.5 * charge_p) + sin(_glow_time * 6.0 + i) * 10.0
			draw_circle(Vector2(cos(sa) * sd, sin(sa) * sd), 2.5, Color(1.0, 0.4, 0.2, charge_alpha))

	# === GLOW AURA (only when active) ===
	if not on_cd:
		draw_circle(Vector2(0, 0), 55.0, Color(col.r, col.g, col.b, glow_alpha * 0.3))
		draw_circle(Vector2(0, 0), 42.0, Color(col.r, col.g, col.b, glow_alpha * 0.6))
		draw_circle(Vector2(0, 0), 60.0, Color(0.8, 0.1, 0.0, glow_alpha * 0.15))
		# Flickering ember particles around the mirror
		for i in range(6):
			var angle := _glow_time * (0.8 + i * 0.3) + i * 1.047
			var dist := 45.0 + sin(_glow_time * 2.0 + i) * 8.0
			var ember_pos := Vector2(cos(angle) * dist, sin(angle) * dist)
			var ember_alpha := 0.4 + 0.3 * sin(_glow_time * 4.0 + i * 2.0)
			draw_circle(ember_pos, 1.5, Color(col.r, col.g, col.b, ember_alpha))

	# === BASE PLATFORM — flesh/bone slab ===
	var base_col := Color(0.2, 0.08, 0.06) if not on_cd else Color(0.15, 0.12, 0.12)
	# Cracked stone base
	draw_circle(Vector2(0, 28), 16.0, base_col)
	draw_circle(Vector2(0, 28), 16.0, Color(0.3, 0.1, 0.08, 0.3))
	# Base cracks
	draw_line(Vector2(-8, 24), Vector2(-12, 32), Color(0.1, 0.03, 0.02), 1.0)
	draw_line(Vector2(5, 22), Vector2(10, 30), Color(0.1, 0.03, 0.02), 1.0)
	draw_line(Vector2(-2, 26), Vector2(3, 34), Color(0.1, 0.03, 0.02), 1.0)

	# === FRAME — twisted bone and sinew ===
	var frame := Rect2(-16, -30, 32, 58)
	var frame_col := Color(0.22, 0.09, 0.07) if not on_cd else Color(0.18, 0.14, 0.14)
	draw_rect(frame, frame_col)
	# Outer bone border
	draw_rect(frame, Color(0.45, 0.18, 0.1), false, 2.5)
	# Inner border — sinew red
	draw_rect(Rect2(-14, -28, 28, 54), Color(0.55, 0.12, 0.08, 0.6), false, 1.5)

	# Rib bones protruding from sides
	for i in range(5):
		var ry := -22.0 + i * 11.0
		# Left ribs
		draw_line(Vector2(-16, ry), Vector2(-22, ry - 2), Color(0.6, 0.55, 0.45), 2.0)
		draw_line(Vector2(-22, ry - 2), Vector2(-24, ry + 1), Color(0.5, 0.45, 0.35), 1.5)
		draw_circle(Vector2(-24, ry + 1), 1.0, Color(0.7, 0.6, 0.5))  # bone tip
		# Right ribs
		draw_line(Vector2(16, ry), Vector2(22, ry - 2), Color(0.6, 0.55, 0.45), 2.0)
		draw_line(Vector2(22, ry - 2), Vector2(24, ry + 1), Color(0.5, 0.45, 0.35), 1.5)
		draw_circle(Vector2(24, ry + 1), 1.0, Color(0.7, 0.6, 0.5))

	# Vertical spine column on each side
	draw_line(Vector2(-16, -28), Vector2(-16, 26), Color(0.5, 0.4, 0.3), 2.0)
	draw_line(Vector2(16, -28), Vector2(16, 26), Color(0.5, 0.4, 0.3), 2.0)
	# Vertebrae notches
	for i in range(8):
		var vy := -26.0 + i * 7.0
		draw_line(Vector2(-17, vy), Vector2(-15, vy), Color(0.4, 0.3, 0.25), 1.5)
		draw_line(Vector2(15, vy), Vector2(17, vy), Color(0.4, 0.3, 0.25), 1.5)

	# === TOP SKULL — large central imp head ===
	var skull_y := -30.0
	# Skull dome
	draw_circle(Vector2(0, skull_y), 9.0, Color(0.7, 0.63, 0.52))
	draw_circle(Vector2(0, skull_y), 9.0, Color(0.35, 0.08, 0.04, 0.35))
	# Brow ridge
	draw_line(Vector2(-7, skull_y - 1), Vector2(-2, skull_y - 3), Color(0.55, 0.48, 0.4), 1.5)
	draw_line(Vector2(7, skull_y - 1), Vector2(2, skull_y - 3), Color(0.55, 0.48, 0.4), 1.5)
	# Large horns curving outward
	draw_line(Vector2(-6, skull_y - 5), Vector2(-11, skull_y - 14), Color(0.3, 0.08, 0.04), 3.0)
	draw_line(Vector2(-11, skull_y - 14), Vector2(-13, skull_y - 18), Color(0.25, 0.06, 0.03), 2.5)
	draw_line(Vector2(6, skull_y - 5), Vector2(11, skull_y - 14), Color(0.3, 0.08, 0.04), 3.0)
	draw_line(Vector2(11, skull_y - 14), Vector2(13, skull_y - 18), Color(0.25, 0.06, 0.03), 2.5)
	# Horn tips glow
	if not on_cd:
		draw_circle(Vector2(-13, skull_y - 18), 2.0, Color(col.r, col.g, col.b, 0.7))
		draw_circle(Vector2(13, skull_y - 18), 2.0, Color(col.r, col.g, col.b, 0.7))
	else:
		draw_circle(Vector2(-13, skull_y - 18), 1.5, Color(0.3, 0.1, 0.08))
		draw_circle(Vector2(13, skull_y - 18), 1.5, Color(0.3, 0.1, 0.08))
	# Eye sockets
	draw_circle(Vector2(-3.5, skull_y + 1), 2.5, Color(0.05, 0.02, 0.02))
	draw_circle(Vector2(3.5, skull_y + 1), 2.5, Color(0.05, 0.02, 0.02))
	if not on_cd:
		draw_circle(Vector2(-3.5, skull_y + 1), 1.5, Color(col.r, col.g, col.b, 0.95))
		draw_circle(Vector2(3.5, skull_y + 1), 1.5, Color(col.r, col.g, col.b, 0.95))
	# Nasal cavity
	draw_line(Vector2(-1, skull_y + 3), Vector2(0, skull_y + 5), Color(0.15, 0.05, 0.03), 1.0)
	draw_line(Vector2(1, skull_y + 3), Vector2(0, skull_y + 5), Color(0.15, 0.05, 0.03), 1.0)
	# Jaw with fangs
	draw_line(Vector2(-6, skull_y + 6), Vector2(6, skull_y + 6), Color(0.55, 0.48, 0.4), 1.5)
	for tx: int in [-5, -3, -1, 1, 3, 5]:
		var fang_len := 3.0 if (tx == -3 or tx == 3) else 2.0
		draw_line(Vector2(tx, skull_y + 6), Vector2(tx, skull_y + 6 + fang_len), Color(0.75, 0.7, 0.6), 1.0)

	# === SIDE SKULLS — smaller imp heads flanking the frame ===
	for side: float in [-1.0, 1.0]:
		var sx := side * 18.0
		var sy := -10.0
		# Small skull
		draw_circle(Vector2(sx, sy), 5.5, Color(0.65, 0.58, 0.48))
		draw_circle(Vector2(sx, sy), 5.5, Color(0.3, 0.08, 0.04, 0.3))
		# Small horns
		draw_line(Vector2(sx - side * 1, sy - 4), Vector2(sx - side * 4, sy - 9), Color(0.3, 0.08, 0.04), 2.0)
		draw_line(Vector2(sx + side * 3, sy - 3), Vector2(sx + side * 6, sy - 8), Color(0.3, 0.08, 0.04), 2.0)
		# Eyes
		draw_circle(Vector2(sx - 2 * side, sy + 0.5), 1.5, Color(0.05, 0.02, 0.02))
		draw_circle(Vector2(sx + 1 * side, sy + 0.5), 1.5, Color(0.05, 0.02, 0.02))
		if not on_cd:
			draw_circle(Vector2(sx - 2 * side, sy + 0.5), 0.8, Color(col.r, col.g, col.b, 0.8))
			draw_circle(Vector2(sx + 1 * side, sy + 0.5), 0.8, Color(col.r, col.g, col.b, 0.8))
		# Teeth
		draw_line(Vector2(sx - 3, sy + 3.5), Vector2(sx + 3, sy + 3.5), Color(0.5, 0.42, 0.35), 1.0)
		for ftx: int in [-2, 0, 2]:
			draw_line(Vector2(sx + ftx, sy + 3.5), Vector2(sx + ftx, sy + 5), Color(0.7, 0.65, 0.55), 0.8)

	# === CLAWS — multiple sets, top and bottom ===
	var bone_col := Color(0.3, 0.08, 0.05)
	var tip_col := Color(0.6, 0.15, 0.1)
	# Bottom claws — large demonic hands gripping base
	var cy := 28.0
	# Left hand
	draw_line(Vector2(-10, cy - 4), Vector2(-16, cy + 8), bone_col, 2.5)
	draw_line(Vector2(-6, cy - 2), Vector2(-10, cy + 10), bone_col, 2.5)
	draw_line(Vector2(-2, cy), Vector2(-4, cy + 12), bone_col, 2.0)
	draw_line(Vector2(-16, cy + 8), Vector2(-18, cy + 12), bone_col, 2.0)
	# Claw tips
	draw_circle(Vector2(-18, cy + 12), 1.5, tip_col)
	draw_circle(Vector2(-10, cy + 10), 1.5, tip_col)
	draw_circle(Vector2(-4, cy + 12), 1.5, tip_col)
	# Right hand (mirrored)
	draw_line(Vector2(10, cy - 4), Vector2(16, cy + 8), bone_col, 2.5)
	draw_line(Vector2(6, cy - 2), Vector2(10, cy + 10), bone_col, 2.5)
	draw_line(Vector2(2, cy), Vector2(4, cy + 12), bone_col, 2.0)
	draw_line(Vector2(16, cy + 8), Vector2(18, cy + 12), bone_col, 2.0)
	draw_circle(Vector2(18, cy + 12), 1.5, tip_col)
	draw_circle(Vector2(10, cy + 10), 1.5, tip_col)
	draw_circle(Vector2(4, cy + 12), 1.5, tip_col)
	# Knuckle bumps
	draw_circle(Vector2(-10, cy - 4), 1.8, Color(0.55, 0.48, 0.4))
	draw_circle(Vector2(10, cy - 4), 1.8, Color(0.55, 0.48, 0.4))

	# Top claws — smaller talons flanking skull
	draw_line(Vector2(-10, -36), Vector2(-14, -44), bone_col, 2.0)
	draw_line(Vector2(-7, -34), Vector2(-9, -42), bone_col, 1.5)
	draw_circle(Vector2(-14, -44), 1.2, tip_col)
	draw_circle(Vector2(-9, -42), 1.2, tip_col)
	draw_line(Vector2(10, -36), Vector2(14, -44), bone_col, 2.0)
	draw_line(Vector2(7, -34), Vector2(9, -42), bone_col, 1.5)
	draw_circle(Vector2(14, -44), 1.2, tip_col)
	draw_circle(Vector2(9, -42), 1.2, tip_col)

	# === PORTAL SURFACE (replaces mirror glass) ===
	var surface := Rect2(-12, -22, 24, 44)
	# Deep void black
	draw_rect(surface, Color(0.03, 0.01, 0.02))

	if not on_cd:
		# Swirling vortex rings
		for i in range(4):
			var ring_t := fmod(_glow_time * 0.6 + i * 0.25, 1.0)
			var ring_r := 4.0 + ring_t * 14.0
			var ring_alpha := (1.0 - ring_t) * 0.35
			draw_arc(Vector2(0, 0), ring_r, 0, TAU, 32, Color(col.r, col.g, col.b, ring_alpha), 1.5)

		# Rotating energy wisps
		for i in range(5):
			var angle := _glow_time * (1.2 + i * 0.4) + i * 1.257
			var dist := 5.0 + sin(_glow_time * 1.5 + i * 1.8) * 6.0
			var wx := cos(angle) * dist
			var wy := sin(angle) * dist * 1.6  # elongated vertically
			var wisp_alpha := 0.5 + 0.3 * sin(_glow_time * 3.0 + i)
			draw_circle(Vector2(wx, wy), 2.0, Color(col.r, col.g, col.b, wisp_alpha))
			# Wisp trail
			var trail_angle := angle - 0.4
			var trail_dist := dist * 0.8
			draw_circle(Vector2(cos(trail_angle) * trail_dist, sin(trail_angle) * trail_dist * 1.6), 1.2, Color(col.r, col.g, col.b, wisp_alpha * 0.4))

		# Central glow pulse
		var center_alpha := 0.15 + 0.1 * sin(_glow_time * 2.0)
		draw_circle(Vector2(0, 0), 8.0, Color(col.r, col.g, col.b, center_alpha))
		draw_circle(Vector2(0, 0), 4.0, Color(col.r, col.g, col.b, center_alpha * 1.5))

		# Hellfire sparks drifting upward inside portal
		for i in range(4):
			var spark_y := fmod(_glow_time * 30.0 + i * 11.0, 40.0) - 20.0
			var spark_x := sin(_glow_time * 2.0 + i * 2.5) * 6.0
			var spark_alpha := 0.6 * (1.0 - absf(spark_y) / 20.0)
			draw_circle(Vector2(spark_x, spark_y), 1.0, Color(1.0, 0.5, 0.2, spark_alpha))
	else:
		# Dead portal — faint smoke wisps
		for i in range(3):
			var smoke_y := fmod(_glow_time * 8.0 + i * 14.0, 40.0) - 20.0
			var smoke_x := sin(_glow_time * 0.5 + i * 2.0) * 4.0
			var smoke_alpha := 0.15 * (1.0 - absf(smoke_y) / 20.0)
			draw_circle(Vector2(smoke_x, smoke_y), 2.0, Color(0.3, 0.3, 0.3, smoke_alpha))

	# Portal border glow (active only)
	if not on_cd:
		# Inner edge glow
		draw_rect(surface, Color(col.r, col.g, col.b, 0.25), false, 2.0)
		draw_rect(Rect2(-11, -21, 22, 42), Color(col.r, col.g, col.b, 0.1), false, 1.0)

	# === SINEW STRANDS across portal ===
	var sinew_col := Color(0.4, 0.1, 0.06, 0.4)
	draw_line(Vector2(-12, -15), Vector2(-4, -8), sinew_col, 1.0)
	draw_line(Vector2(12, -12), Vector2(5, -5), sinew_col, 1.0)
	draw_line(Vector2(-12, 10), Vector2(-3, 5), sinew_col, 1.0)
	draw_line(Vector2(12, 12), Vector2(4, 7), sinew_col, 1.0)
	# Dripping blood drops on strands
	draw_circle(Vector2(-4, -8), 1.0, Color(0.5, 0.05, 0.02, 0.5))
	draw_circle(Vector2(5, -5), 1.0, Color(0.5, 0.05, 0.02, 0.5))

	# === RUNE MARKS — glowing sigils ===
	if not on_cd:
		var rune_alpha := 0.5 + 0.3 * sin(_glow_time * 2.0)
		var rune_col := Color(col.r, col.g, col.b, rune_alpha)
		# Left runes
		draw_line(Vector2(-15, -10), Vector2(-15, -4), rune_col, 1.2)
		draw_line(Vector2(-15, -4), Vector2(-13, -7), rune_col, 1.2)
		draw_line(Vector2(-15, 2), Vector2(-15, 8), rune_col, 1.2)
		draw_line(Vector2(-15, 8), Vector2(-13, 5), rune_col, 1.2)
		draw_line(Vector2(-15, 12), Vector2(-15, 18), rune_col, 1.2)
		draw_line(Vector2(-15, 18), Vector2(-13, 15), rune_col, 1.2)
		# Right runes
		draw_line(Vector2(15, -10), Vector2(15, -4), rune_col, 1.2)
		draw_line(Vector2(15, -4), Vector2(13, -7), rune_col, 1.2)
		draw_line(Vector2(15, 2), Vector2(15, 8), rune_col, 1.2)
		draw_line(Vector2(15, 8), Vector2(13, 5), rune_col, 1.2)
		draw_line(Vector2(15, 12), Vector2(15, 18), rune_col, 1.2)
		draw_line(Vector2(15, 18), Vector2(13, 15), rune_col, 1.2)

	# === TELEPORT ORB — exact glow_color ===
	if _orb_active:
		# Outer glow halo
		draw_circle(_orb_pos, 22.0, Color(glow_color.r, glow_color.g, glow_color.b, 0.08))
		draw_circle(_orb_pos, 16.0, Color(glow_color.r, glow_color.g, glow_color.b, 0.2))
		# Main orb
		draw_circle(_orb_pos, 9.0, Color(glow_color.r, glow_color.g, glow_color.b, 0.9))
		# Core white-hot center
		draw_circle(_orb_pos, 4.0, Color(1.0, 1.0, 1.0, 0.7))
		draw_circle(_orb_pos, 2.0, Color(1.0, 1.0, 1.0, 0.95))
		# Trail particles
		for i in range(5):
			var trail_t := clampf(_orb_progress - (i + 1) * 0.06, 0.0, 1.0)
			var trail_pos := _orb_start.lerp(_orb_target, _ease_out_cubic(trail_t))
			var trail_alpha := 0.6 - i * 0.1
			var trail_r := 5.0 - i * 0.8
			draw_circle(trail_pos, trail_r, Color(glow_color.r, glow_color.g, glow_color.b, trail_alpha))

	# === "Press E" prompt ===
	if _prompt_visible and not on_cd and not _is_teleporting:
		var font := ThemeDB.fallback_font
		var font_size := 14
		var text := "Press E"
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(-text_size.x * 0.5, -56)
		draw_rect(Rect2(text_pos.x - 4, text_pos.y - font_size + 2, text_size.x + 8, font_size + 6), Color(0, 0, 0, 0.7))
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, glow_color)
