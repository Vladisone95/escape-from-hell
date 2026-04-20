extends Node2D

var _sprite: Sprite2D
var _is_swinging: bool = false
var _swing_tween: Tween
var _time: float = 0.0
var _current_angle: float = 0.0

const ORBIT_RADIUS: float = 24.0
const SWORD_SCALE: float = 0.30
const SWING_ARC: float = TAU / 3.0
const BOB_AMP: float = 2.0
const BOB_SPEED: float = 2.5

func _ready() -> void:
	_sprite = Sprite2D.new()
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = load("res://assets/sprites/player/sword.png")
	atlas.region = Rect2(0, 0, 176, 192)
	_sprite.texture = atlas
	_sprite.offset = Vector2(0, -74)
	_sprite.scale = Vector2(SWORD_SCALE, SWORD_SCALE)
	add_child(_sprite)

func _process(delta: float) -> void:
	_time += delta

	if _is_swinging:
		return

	var player_pos: Vector2 = get_parent().global_position
	var dir: Vector2 = (get_global_mouse_position() - player_pos).normalized()
	_current_angle = dir.angle()

	var bob: float = sin(_time * BOB_SPEED) * BOB_AMP
	position = dir * ORBIT_RADIUS + Vector2(0, -12.0 + bob)
	_sprite.rotation = _current_angle + PI / 2.0

func start_swing(direction: Vector2, duration: float) -> void:
	_is_swinging = true
	_sprite.self_modulate = Color(1.3, 1.15, 1.0)

	var mid_a: float = _current_angle
	var start_a: float
	var end_a: float
	if direction.y < 0.0:
		start_a = mid_a - SWING_ARC / 2.0
		end_a = mid_a + SWING_ARC / 2.0
	else:
		start_a = mid_a + SWING_ARC / 2.0
		end_a = mid_a - SWING_ARC / 2.0

	_pose(start_a)

	if _swing_tween and _swing_tween.is_valid():
		_swing_tween.kill()

	var slash_t: float = maxf(duration * 0.4, 0.12)

	_swing_tween = create_tween()
	_swing_tween.set_ease(Tween.EASE_OUT)
	_swing_tween.set_trans(Tween.TRANS_QUAD)
	_swing_tween.tween_method(_swing_step, start_a, end_a, slash_t)
	_swing_tween.tween_callback(_end_swing)

func _swing_step(angle: float) -> void:
	_pose(angle)
	_current_angle = angle

func _pose(angle: float) -> void:
	position = Vector2(cos(angle), sin(angle)) * ORBIT_RADIUS + Vector2(0, -12.0)
	_sprite.rotation = angle + PI / 2.0

func _end_swing() -> void:
	_is_swinging = false
	_sprite.self_modulate = Color.WHITE
