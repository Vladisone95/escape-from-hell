extends Area2D

var damage: int = 10
var direction: Vector2 = Vector2.RIGHT
var speed: float = 560.0
var max_distance: float = 1000.0
var radius: float = 16.0
var color_core: Color = Color(1.0, 0.45, 0.05, 0.85)
var color_inner: Color = Color(1.0, 0.7, 0.1, 0.95)
var color_center: Color = Color(1.0, 0.95, 0.7)
var color_glow: Color = Color(1.0, 0.3, 0.0, 0.5)
var _distance_traveled: float = 0.0
var _flicker: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 4  # layer 5: enemy_attack
	collision_mask = 1 << 1   # layer 2: player_body (player hurtbox)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	var step := speed * delta
	position += direction * step
	_distance_traveled += step
	_flicker += delta * 12.0
	queue_redraw()
	if _distance_traveled >= max_distance:
		queue_free()

func _draw() -> void:
	var glow_r := radius + sin(_flicker) * 1.0
	draw_circle(Vector2.ZERO, glow_r, color_glow)
	draw_circle(Vector2.ZERO, radius, color_core)
	draw_circle(Vector2.ZERO, radius * 0.625, color_inner)
	draw_circle(Vector2.ZERO, radius * 0.3125, color_center)
	var back := -direction * 20.0
	draw_circle(back, radius * 0.375, Color(color_core.r, color_core.g, color_core.b, 0.5))
	draw_circle(back * 1.6, radius * 0.25, Color(color_glow.r, color_glow.g, color_glow.b, 0.3))

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_hit"):
		area.receive_hit(damage, direction * 240.0)
		_spawn_impact()
		queue_free()

func _spawn_impact() -> void:
	var DmgVfx := load("res://scripts/arena/DamageNumber.gd")
	DmgVfx.spawn(get_parent(), global_position, damage, color_core)

## Fire a projectile with a config dictionary.
## Config keys (all optional): speed, max_distance, radius, color_core, color_inner,
## color_center, color_glow. Unset keys use class defaults.
static func fire(parent: Node2D, from: Vector2, to: Vector2, dmg: int, config: Dictionary = {}) -> void:
	var proj := Area2D.new()
	proj.set_script(load("res://scripts/arena/Projectile.gd"))
	proj.damage = dmg
	proj.direction = (to - from).normalized()
	proj.position = from
	for key in config:
		proj.set(key, config[key])
	parent.add_child(proj)
