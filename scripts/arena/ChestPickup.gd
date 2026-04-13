extends Node2D

signal chest_opened()

const INTERACT_RANGE := 120.0
const GLOW_RADIUS := 80.0

var _player: CharacterBody2D
var _glow_time: float = 0.0
var _prompt_visible: bool = false
var _opened: bool = false

func init(player: CharacterBody2D) -> void:
	_player = player
	add_to_group("interactable")
	z_index = 1
	# Spawn animation: scale pop + fade in
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.6, 0.6)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4)
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_property(self, "scale", Vector2(2.0, 2.0), 0.15)

func _process(delta: float) -> void:
	if _opened:
		return
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
	if _opened:
		return
	_opened = true
	# Brief open animation then emit
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.35)
	tw.tween_callback(func():
		chest_opened.emit()
		queue_free()
	)

func _draw() -> void:
	if _opened:
		return

	# Pulsing glow
	var glow_alpha := 0.15 + 0.1 * sin(_glow_time * 3.0)
	var glow_color := Color(1.0, 0.85, 0.2, glow_alpha)
	draw_circle(Vector2(0, -6), GLOW_RADIUS, glow_color)
	var glow_color2 := Color(1.0, 0.7, 0.1, glow_alpha * 0.5)
	draw_circle(Vector2(0, -6), GLOW_RADIUS * 1.5, glow_color2)

	# Chest body
	var body_rect := Rect2(-16, -8, 32, 18)
	draw_rect(body_rect, Color(0.45, 0.25, 0.1))  # dark wood
	# Wood grain lines
	draw_line(Vector2(-14, -2), Vector2(14, -2), Color(0.35, 0.18, 0.07), 1.0)
	draw_line(Vector2(-14, 4), Vector2(14, 4), Color(0.35, 0.18, 0.07), 1.0)

	# Metal band
	draw_rect(Rect2(-17, -2, 34, 4), Color(0.5, 0.5, 0.5))
	draw_rect(Rect2(-17, -2, 34, 4), Color(0.3, 0.3, 0.3), false, 1.0)

	# Lid (slightly lighter, trapezoid-ish top)
	var lid_rect := Rect2(-16, -18, 32, 12)
	draw_rect(lid_rect, Color(0.55, 0.3, 0.12))
	# Lid highlight
	draw_line(Vector2(-14, -16), Vector2(14, -16), Color(0.65, 0.38, 0.15), 1.0)

	# Metal corners on lid
	draw_rect(Rect2(-16, -18, 5, 4), Color(0.5, 0.5, 0.5))
	draw_rect(Rect2(11, -18, 5, 4), Color(0.5, 0.5, 0.5))

	# Lock/clasp (golden)
	draw_rect(Rect2(-4, -6, 8, 8), Color(0.9, 0.75, 0.2))
	draw_rect(Rect2(-3, -5, 6, 6), Color(1.0, 0.85, 0.3))
	# Keyhole
	draw_circle(Vector2(0, -1), 1.5, Color(0.2, 0.15, 0.05))

	# "Press E" prompt
	if _prompt_visible:
		var font := ThemeDB.fallback_font
		var font_size := 14
		var text := "Press E"
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(-text_size.x * 0.5, -32)
		# Background
		draw_rect(Rect2(text_pos.x - 4, text_pos.y - font_size + 2, text_size.x + 8, font_size + 6), Color(0, 0, 0, 0.7))
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.9, 0.4))
