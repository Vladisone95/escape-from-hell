extends Area2D

signal portal_entered

const PORTAL_RADIUS: float = 80.0

const INTERACT_RANGE: float = 90.0  # distance to show prompt and allow E press

var _player: CharacterBody2D
var _glow_time: float = 0.0
var _spawned: bool = false
var _player_nearby: bool = false

func init(player: CharacterBody2D) -> void:
	_player = player
	collision_layer = 0
	collision_mask = 1 << 1  # layer 2: player_body
	var col: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = INTERACT_RANGE
	col.shape = shape
	add_child(col)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Spawn bounce animation
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	scale = Vector2(0.1, 0.1)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _process(delta: float) -> void:
	_glow_time += delta
	if _player_nearby and not _spawned and Input.is_action_just_pressed("interact"):
		_spawned = true
		portal_entered.emit()
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body == _player:
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player_nearby = false

func _draw() -> void:
	var t: float = _glow_time
	_draw_outer_halos(t)
	_draw_vortex_rings(t)
	_draw_orbit_wisps(t)
	_draw_rune_marks(t)
	_draw_inner_void(t)
	_draw_central_eye(t)
	_draw_enter_prompt()

func _draw_outer_halos(t: float) -> void:
	draw_circle(Vector2.ZERO, 110.0, Color(0.4, 0.1, 0.9, 0.06 + 0.03 * sin(t * 1.2)))
	draw_circle(Vector2.ZERO, 95.0,  Color(0.5, 0.2, 1.0, 0.10 + 0.04 * sin(t * 1.5)))
	draw_circle(Vector2.ZERO, 82.0,  Color(0.6, 0.3, 1.0, 0.14 + 0.05 * sin(t * 2.0)))

func _draw_vortex_rings(t: float) -> void:
	for i: int in 6:
		var ring_t: float = fmod(t * 0.45 + float(i) / 6.0, 1.0)
		var ring_r: float = 8.0 + ring_t * 72.0
		var ring_alpha: float = (1.0 - ring_t) * 0.55
		var ring_width: float = 2.5 - ring_t * 1.5
		var ring_col: Color = Color(
			lerpf(0.9, 0.4, ring_t),
			lerpf(0.8, 0.1, ring_t),
			1.0,
			ring_alpha
		)
		draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 48, ring_col, ring_width)

func _draw_orbit_wisps(t: float) -> void:
	for i: int in 8:
		var angle: float = t * (0.9 + float(i) * 0.25) + float(i) * 0.785
		var dist: float = 52.0 + sin(t * 2.0 + float(i) * 1.3) * 18.0
		var wx: float = cos(angle) * dist
		var wy: float = sin(angle) * dist * 0.85
		var alpha: float = 0.55 + 0.35 * sin(t * 3.5 + float(i) * 2.0)
		draw_circle(Vector2(wx, wy), 3.5, Color(0.8, 0.5, 1.0, alpha))
		var ta: float = angle - 0.5
		var td: float = dist * 0.75
		draw_circle(Vector2(cos(ta) * td, sin(ta) * td * 0.85), 2.0, Color(0.6, 0.3, 1.0, alpha * 0.4))
	# Star sparks at outer ring
	for i: int in 4:
		var sa: float = t * (0.4 + float(i) * 0.15) + float(i) * 1.571
		var sd: float = 68.0 + sin(t * 1.8 + float(i)) * 10.0
		var spark_alpha: float = 0.7 * absf(sin(t * 4.0 + float(i)))
		draw_circle(Vector2(cos(sa) * sd, sin(sa) * sd), 2.0, Color(0.3, 0.8, 1.0, spark_alpha))

func _draw_rune_marks(t: float) -> void:
	for i: int in 8:
		var ra: float = float(i) * 0.785 + t * 0.15
		var rx: float = cos(ra) * 65.0
		var ry: float = sin(ra) * 65.0
		var rune_alpha: float = 0.4 + 0.3 * sin(t * 2.5 + float(i))
		var rcol: Color = Color(0.7, 0.4, 1.0, rune_alpha)
		draw_line(Vector2(rx - 5.0, ry), Vector2(rx + 5.0, ry), rcol, 1.2)
		draw_line(Vector2(rx, ry - 5.0), Vector2(rx, ry + 5.0), rcol, 1.2)
		draw_circle(Vector2(rx, ry), 1.5, Color(1.0, 0.9, 1.0, rune_alpha * 0.8))

func _draw_inner_void(t: float) -> void:
	draw_circle(Vector2.ZERO, 36.0, Color(0.02, 0.0, 0.06, 1.0))
	# Rising sparks inside void
	for i: int in 4:
		var sy: float = fmod(t * 40.0 + float(i) * 20.0, 70.0) - 35.0
		var sx: float = sin(t * 2.5 + float(i) * 2.5) * 14.0
		var spark_a: float = 0.7 * (1.0 - absf(sy) / 35.0)
		draw_circle(Vector2(sx, sy), 1.5, Color(0.8, 0.6, 1.0, spark_a))
	# Bright border ring
	draw_arc(Vector2.ZERO, 36.0, 0.0, TAU, 32, Color(0.9, 0.8, 1.0, 0.6 + 0.2 * sin(t * 3.0)), 2.5)
	draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 32, Color(0.7, 0.4, 1.0, 0.25), 1.5)

func _draw_central_eye(t: float) -> void:
	draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.95, 1.0, 0.9))
	draw_circle(Vector2.ZERO, 5.0, Color(0.15, 0.0, 0.35, 1.0))
	var pa: float = 0.5 + 0.5 * sin(t * 4.0)
	draw_circle(Vector2.ZERO, 3.0, Color(0.7, 0.3, 1.0, pa))
	draw_circle(Vector2.ZERO, 14.0, Color(0.9, 0.8, 1.0, 0.25 + 0.15 * sin(t * 2.0)))

func _draw_enter_prompt() -> void:
	if not _player_nearby:
		return
	var font: Font = ThemeDB.fallback_font
	var text: String = "[E] Enter Portal"
	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	var tp: Vector2 = Vector2(-ts.x * 0.5, -PORTAL_RADIUS - 24.0)
	draw_rect(Rect2(tp.x - 6.0, tp.y - 16.0, ts.x + 12.0, 22.0), Color(0.0, 0.0, 0.0, 0.7))
	draw_string(font, tp, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.8, 1.0, 1.0))
