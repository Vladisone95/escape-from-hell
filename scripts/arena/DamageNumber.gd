extends Node2D

var value: int = 0
var color: Color = Color.WHITE
var _alpha: float = 1.0
var _rise: float = 0.0

func _ready() -> void:
	z_index = 5
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "_rise", -60.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_alpha", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.finished.connect(queue_free)

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := str(value)
	var col := Color(color.r, color.g, color.b, _alpha)
	draw_string(font, Vector2(-20, _rise), text, HORIZONTAL_ALIGNMENT_CENTER, 80, 32, col)

static func spawn(parent: Node2D, pos: Vector2, val: int, col: Color = Color.WHITE) -> void:
	var dn := Node2D.new()
	dn.set_script(load("res://scripts/arena/DamageNumber.gd"))
	dn.value = val
	dn.color = col
	dn.position = pos + Vector2(randf_range(-20, 20), -40)
	parent.add_child(dn)
