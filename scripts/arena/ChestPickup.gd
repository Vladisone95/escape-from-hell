extends Node2D

signal chest_opened()

const INTERACT_RANGE := 120.0

var _player: CharacterBody2D
var _prompt_visible: bool = false
var _opened: bool = false
var _anim: AnimatedSprite2D

func init(player: CharacterBody2D) -> void:
	_player = player
	add_to_group("interactable")
	z_index = 1

	# Set up animated sprite
	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = load("res://assets/spriteframes/chest.tres")
	add_child(_anim)
	_anim.play("idle")

	# Spawn animation: scale pop + fade in
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.6, 0.6)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.4)
	tw.tween_property(self, "scale", Vector2(2.2, 2.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.chain().tween_property(self, "scale", Vector2(2.0, 2.0), 0.15)

func _process(_delta: float) -> void:
	if _opened:
		return
	var in_range: bool = _is_player_in_range()
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
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.35)
	tw.tween_callback(func():
		chest_opened.emit()
		queue_free()
	)

func _draw() -> void:
	if _opened or not _prompt_visible:
		return
	# "Press E" prompt only — chest visuals handled by AnimatedSprite2D
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14
	var text: String = "Press E"
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos: Vector2 = Vector2(-text_size.x * 0.5, -32)
	draw_rect(Rect2(text_pos.x - 4, text_pos.y - font_size + 2, text_size.x + 8, font_size + 6), Color(0, 0, 0, 0.7))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.9, 0.4))
