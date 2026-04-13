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
var _anim: AnimatedSprite2D

func _ready() -> void:
	z_index = 10
	collision_layer = 1 << 4  # layer 5: enemy_attack
	collision_mask = (1 << 1) | (1 << 0)  # layer 2: player_body + layer 1: world

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = load("res://assets/spriteframes/projectile.tres")
	_anim.scale = Vector2(radius / 8.0, radius / 8.0)
	# Tint the neutral sprite to match the projectile's color
	_anim.self_modulate = color_core
	add_child(_anim)
	_anim.play("fly")

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	var step: float = speed * delta
	position += direction * step
	_distance_traveled += step
	if _distance_traveled >= max_distance:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_hit"):
		area.receive_hit(damage, direction * 240.0)
		_spawn_impact()
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	queue_free()

func _spawn_impact() -> void:
	var DmgVfx: GDScript = load("res://scripts/arena/DamageNumber.gd")
	DmgVfx.spawn(get_parent(), global_position, damage, color_core)

static func fire(parent: Node2D, from: Vector2, to: Vector2, dmg: int, config: Dictionary = {}) -> void:
	var proj := Area2D.new()
	proj.set_script(load("res://scripts/arena/Projectile.gd"))
	proj.damage = dmg
	proj.direction = (to - from).normalized()
	proj.position = from
	for key: String in config:
		proj.set(key, config[key])
	parent.add_child(proj)
