extends Area2D

var damage: int = 10
var knockback_force: float = 150.0
var lifetime: float = 0.15
var source: Node = null  # who spawned this hitbox

var _hit_targets: Array[Node] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area is Area2D and area.has_method("receive_hit") and area not in _hit_targets:
		_hit_targets.append(area)
		var dir := (area.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		area.receive_hit(damage, dir * knockback_force)

static func create_arc(parent: Node2D, pos: Vector2, facing: Vector2, dmg: int, kb: float = 150.0, arc_radius: float = 40.0, src: Node = null) -> Area2D:
	var hitbox := Area2D.new()
	hitbox.set_script(load("res://scripts/arena/AttackHitbox.gd"))
	hitbox.damage = dmg
	hitbox.knockback_force = kb
	hitbox.source = src
	hitbox.position = pos + facing * 20.0
	hitbox.collision_layer = 0
	hitbox.collision_mask = 0

	# Build arc from 5 small circles
	var angle_base := facing.angle()
	var arc_spread := deg_to_rad(60.0)  # +/- 60 = 120 deg total
	for i in 5:
		var t := float(i) / 4.0
		var a := angle_base - arc_spread + t * arc_spread * 2.0
		var offset := Vector2(cos(a), sin(a)) * arc_radius * 0.5
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 14.0
		shape.shape = circle
		shape.position = offset
		hitbox.add_child(shape)

	parent.add_child(hitbox)
	return hitbox
