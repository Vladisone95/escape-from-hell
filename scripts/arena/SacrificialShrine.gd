extends Node2D

signal shrine_used

const INTERACT_RANGE := 120.0

var _player: CharacterBody2D
var _glow_time: float = 0.0
var _prompt_visible: bool = false
var _depleted: bool = false

func init(player: CharacterBody2D) -> void:
	_player = player
	add_to_group("interactable")
	# Spawn animation
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4)
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_property(self, "scale", Vector2(2.0, 2.0), 0.15)

func _process(delta: float) -> void:
	_glow_time += delta
	var in_range := _is_player_in_range()
	if in_range != _prompt_visible:
		_prompt_visible = in_range
	queue_redraw()

func _is_player_in_range() -> bool:
	if not is_instance_valid(_player):
		return false
	return global_position.distance_to(_player.global_position) <= INTERACT_RANGE

func interact() -> void:
	if _depleted:
		return
	_depleted = true

	# Sacrifice 25% current HP (minimum 1 damage, clamp health to 1)
	var sacrifice := maxi(1, GameData.player_health / 4)
	GameData.player_health = maxi(1, GameData.player_health - sacrifice)

	# Update health bar and trigger hurt animation
	if is_instance_valid(_player):
		_player.health_bar.update_health(GameData.player_health, GameData.effective_max_health())
		_player.health_changed.emit(GameData.player_health, GameData.effective_max_health())
		_player.sprite.play_hurt()
		_player._flash_iframes(0.3)

		# Spawn damage number
		var DmgNum := load("res://scripts/arena/DamageNumber.gd")
		DmgNum.spawn(get_parent(), _player.global_position, sacrifice, Color(0.8, 0.1, 0.1))

	# Flash effect on shrine
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(2.0, 0.5, 0.5, 1.0), 0.1)
	tw.tween_property(self, "modulate", Color(0.6, 0.6, 0.6, 1.0), 0.4)

	shrine_used.emit()


func _draw() -> void:
	var active := not _depleted
	var glow_alpha := 0.15 + 0.1 * sin(_glow_time * 3.0)
	var glow_col := Color(0.8, 0.1, 0.05)

	# ── Red glow aura (only when active) ──────────────────────────────
	if active:
		draw_circle(Vector2(0, 0), 55.0, Color(glow_col.r, glow_col.g, glow_col.b, glow_alpha * 0.3))
		draw_circle(Vector2(0, 0), 42.0, Color(glow_col.r, glow_col.g, glow_col.b, glow_alpha * 0.6))
		draw_circle(Vector2(0, 0), 60.0, Color(0.8, 0.05, 0.0, glow_alpha * 0.15))
		# Flickering embers
		for i in range(6):
			var angle := _glow_time * (1.5 + i * 0.7) + i * 1.1
			var r := 48.0 + sin(angle * 0.8) * 8.0
			var ep := Vector2(cos(angle) * r, sin(angle) * r)
			var ea := (0.3 + 0.3 * sin(angle * 2.0))
			draw_circle(ep, 2.0, Color(1.0, 0.3, 0.05, ea))

	# ── Base pedestal ─────────────────────────────────────────────────
	var base_col := Color(0.12, 0.10, 0.10) if active else Color(0.08, 0.07, 0.07)
	var base_lt := Color(0.18, 0.15, 0.14) if active else Color(0.12, 0.10, 0.10)
	# Stone platform
	draw_rect(Rect2(-18, 22, 36, 8), base_col)
	draw_rect(Rect2(-20, 26, 40, 6), base_col)
	# Platform top highlight
	draw_rect(Rect2(-18, 22, 36, 2), base_lt)
	# Cracks in base
	draw_line(Vector2(-10, 28), Vector2(-6, 31), Color(0.06, 0.04, 0.04), 1.0)
	draw_line(Vector2(8, 27), Vector2(12, 30), Color(0.06, 0.04, 0.04), 1.0)

	# ── Statue body ──────────────────────────────────────────────────
	var body_col := Color(0.08, 0.06, 0.06) if active else Color(0.06, 0.05, 0.05)
	var body_lt := Color(0.14, 0.10, 0.10) if active else Color(0.09, 0.07, 0.07)
	# Main body pillar
	draw_rect(Rect2(-10, -14, 20, 36), body_col)
	# Shoulder widening
	draw_rect(Rect2(-14, -6, 28, 12), body_col)
	# Body edge highlights
	draw_rect(Rect2(-10, -14, 2, 36), body_lt)
	draw_rect(Rect2(8, -14, 2, 36), body_lt)
	# Chest detail - carved ribs
	for rib_y in [-2, 4, 10]:
		draw_line(Vector2(-8, rib_y), Vector2(-2, rib_y + 2), Color(0.04, 0.03, 0.03), 1.0)
		draw_line(Vector2(8, rib_y), Vector2(2, rib_y + 2), Color(0.04, 0.03, 0.03), 1.0)

	# ── Wings ────────────────────────────────────────────────────────
	var wing_col := Color(0.10, 0.07, 0.07) if active else Color(0.07, 0.05, 0.05)
	var wing_edge := Color(0.16, 0.10, 0.08) if active else Color(0.10, 0.07, 0.06)
	# Left wing
	draw_line(Vector2(-14, -8), Vector2(-26, -18), wing_col, 2.5)
	draw_line(Vector2(-26, -18), Vector2(-30, -10), wing_col, 2.0)
	draw_line(Vector2(-30, -10), Vector2(-26, -2), wing_col, 2.0)
	draw_line(Vector2(-26, -2), Vector2(-14, 0), wing_col, 2.0)
	# Wing membrane
	draw_line(Vector2(-26, -18), Vector2(-22, -6), wing_edge, 1.0)
	draw_line(Vector2(-28, -14), Vector2(-20, -4), wing_edge, 1.0)
	# Right wing (mirrored)
	draw_line(Vector2(14, -8), Vector2(26, -18), wing_col, 2.5)
	draw_line(Vector2(26, -18), Vector2(30, -10), wing_col, 2.0)
	draw_line(Vector2(30, -10), Vector2(26, -2), wing_col, 2.0)
	draw_line(Vector2(26, -2), Vector2(14, 0), wing_col, 2.0)
	draw_line(Vector2(26, -18), Vector2(22, -6), wing_edge, 1.0)
	draw_line(Vector2(28, -14), Vector2(20, -4), wing_edge, 1.0)

	# ── Head (creature face) ────────────────────────────────────────
	var head_col := Color(0.06, 0.04, 0.04) if active else Color(0.05, 0.04, 0.04)
	var head_lt := Color(0.12, 0.08, 0.08) if active else Color(0.08, 0.06, 0.06)
	# Large head
	draw_circle(Vector2(0, -22), 11.0, head_col)
	# Brow ridge
	draw_rect(Rect2(-12, -28, 24, 4), head_col)
	draw_rect(Rect2(-10, -30, 20, 3), head_lt)
	# Jaw
	draw_rect(Rect2(-8, -14, 16, 6), head_col)
	draw_rect(Rect2(-6, -8, 12, 3), head_col)

	# ── Horns ────────────────────────────────────────────────────────
	var horn_col := Color(0.12, 0.08, 0.06) if active else Color(0.08, 0.06, 0.05)
	var horn_tip := Color(0.20, 0.10, 0.06) if active else Color(0.12, 0.08, 0.06)
	# Left horn - curves upward and outward
	draw_line(Vector2(-10, -28), Vector2(-16, -36), horn_col, 3.0)
	draw_line(Vector2(-16, -36), Vector2(-20, -42), horn_col, 2.5)
	draw_line(Vector2(-20, -42), Vector2(-22, -46), horn_tip, 2.0)
	# Right horn
	draw_line(Vector2(10, -28), Vector2(16, -36), horn_col, 3.0)
	draw_line(Vector2(16, -36), Vector2(20, -42), horn_col, 2.5)
	draw_line(Vector2(20, -42), Vector2(22, -46), horn_tip, 2.0)

	# Horn tips glow when active
	if active:
		var tip_glow := 0.4 + 0.3 * sin(_glow_time * 4.0)
		draw_circle(Vector2(-22, -46), 3.0, Color(1.0, 0.15, 0.05, tip_glow))
		draw_circle(Vector2(22, -46), 3.0, Color(1.0, 0.15, 0.05, tip_glow))

	# ── Eyes ─────────────────────────────────────────────────────────
	var eye_socket := Color(0.02, 0.01, 0.01)
	# Eye sockets
	draw_circle(Vector2(-5, -24), 3.5, eye_socket)
	draw_circle(Vector2(5, -24), 3.5, eye_socket)
	# Glowing pupils
	if active:
		var eye_pulse := 0.6 + 0.4 * sin(_glow_time * 5.0)
		var eye_col := Color(1.0, 0.1, 0.05, eye_pulse)
		draw_circle(Vector2(-5, -24), 2.0, eye_col)
		draw_circle(Vector2(5, -24), 2.0, eye_col)
		# Eye glow halo
		draw_circle(Vector2(-5, -24), 4.0, Color(1.0, 0.1, 0.05, eye_pulse * 0.3))
		draw_circle(Vector2(5, -24), 4.0, Color(1.0, 0.1, 0.05, eye_pulse * 0.3))
	else:
		# Dim dead eyes
		draw_circle(Vector2(-5, -24), 1.5, Color(0.15, 0.08, 0.06))
		draw_circle(Vector2(5, -24), 1.5, Color(0.15, 0.08, 0.06))

	# ── Mouth / Fangs ────────────────────────────────────────────────
	# Mouth opening
	draw_rect(Rect2(-4, -16, 8, 4), Color(0.03, 0.01, 0.01))
	# Fangs
	var fang_col := Color(0.20, 0.18, 0.15) if active else Color(0.14, 0.12, 0.10)
	draw_rect(Rect2(-3, -16, 2, 3), fang_col)
	draw_rect(Rect2(1, -16, 2, 3), fang_col)
	# Smaller inner fangs
	draw_rect(Rect2(-1, -16, 1, 2), fang_col)

	# ── Decorative runes on body ─────────────────────────────────────
	if active:
		var rune_pulse := 0.3 + 0.3 * sin(_glow_time * 2.5 + 1.0)
		var rune_col := Color(0.8, 0.1, 0.05, rune_pulse)
		# Left rune
		draw_rect(Rect2(-7, 2, 4, 1), rune_col)
		draw_rect(Rect2(-6, 0, 1, 4), rune_col)
		draw_rect(Rect2(-8, 3, 1, 2), rune_col)
		# Right rune
		draw_rect(Rect2(3, 2, 4, 1), rune_col)
		draw_rect(Rect2(4, 0, 1, 4), rune_col)
		draw_rect(Rect2(7, 3, 1, 2), rune_col)

	# ── "Press E" prompt ─────────────────────────────────────────────
	if _prompt_visible and active:
		var font := ThemeDB.fallback_font
		var font_size := 14
		var text := "Press E"
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(-text_size.x * 0.5, -56)
		draw_rect(Rect2(text_pos.x - 4, text_pos.y - font_size + 2, text_size.x + 8, font_size + 6), Color(0, 0, 0, 0.7))
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.9, 0.2, 0.1))
