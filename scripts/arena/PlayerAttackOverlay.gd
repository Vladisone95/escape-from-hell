extends Node2D

var _cone_dir: float = 0.0
var _cone_alpha: float = 0.0

const CONE_ARC: float = TAU / 3.0
const CONE_SEGMENTS: int = 24
const FADE_SPEED: float = 5.0

func _process(delta: float) -> void:
	if _cone_alpha > 0.0:
		_cone_alpha -= delta * FADE_SPEED
		if _cone_alpha < 0.0:
			_cone_alpha = 0.0
	queue_redraw()

func _draw() -> void:
	var reach: float = GameData.effective_attack_range()
	# Persistent range circle
	draw_arc(Vector2.ZERO, reach, 0.0, TAU, 64, Color(1.0, 0.8, 0.5, 0.12), 1.5)
	# Cone flash
	if _cone_alpha > 0.01:
		_draw_cone(reach)

func _draw_cone(reach: float) -> void:
	var half: float = CONE_ARC / 2.0
	var sa: float = _cone_dir - half
	var pts: PackedVector2Array = PackedVector2Array()
	pts.append(Vector2.ZERO)
	for i in CONE_SEGMENTS + 1:
		var t: float = float(i) / float(CONE_SEGMENTS)
		var a: float = sa + CONE_ARC * t
		pts.append(Vector2(cos(a), sin(a)) * reach)
	draw_colored_polygon(pts, Color(1.0, 0.55, 0.15, _cone_alpha * 0.4))
	# Bright outer edge
	for i in CONE_SEGMENTS:
		var t0: float = float(i) / float(CONE_SEGMENTS)
		var t1: float = float(i + 1) / float(CONE_SEGMENTS)
		var a0: float = sa + CONE_ARC * t0
		var a1: float = sa + CONE_ARC * t1
		draw_line(
			Vector2(cos(a0), sin(a0)) * reach,
			Vector2(cos(a1), sin(a1)) * reach,
			Color(1.0, 0.85, 0.5, _cone_alpha * 0.6), 2.0, true
		)

func flash_cone(direction: Vector2) -> void:
	_cone_dir = direction.angle()
	_cone_alpha = 1.0
