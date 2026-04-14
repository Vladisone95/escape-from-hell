extends Area2D
# ─────────────────────────────────────────────────────────────
# ExpandingRing — reusable expanding ring projectile.
# Grows outward from its spawn position, dealing damage once to
# anything with a hurtbox that the ring edge passes through.
# Configure via the static fire() method or set properties directly.
# ─────────────────────────────────────────────────────────────

var damage: int = 50
var expand_speed: float = 225.0
var max_radius: float = 2200.0
var ring_width: float = 20.0
var color_core: Color = Color(1.0, 0.15, 0.1)
var color_glow: Color = Color(0.9, 0.1, 0.05, 0.5)
var color_bright: Color = Color(1.0, 0.5, 0.3)
var color_center: Color = Color(1.0, 0.8, 0.6)

var _radius: float = 30.0
var _hit_player: bool = false
var _time: float = 0.0

func _ready() -> void:
	collision_layer = 1 << 4  # layer 5: enemy_attack
	collision_mask = 1 << 1   # layer 2: player_body (player hurtbox)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = _radius
	shape.shape = circle
	add_child(shape)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	_time += delta
	_radius += expand_speed * delta
	# Update collision to match ring outer edge
	var shape_node := get_child(0) as CollisionShape2D
	if shape_node:
		(shape_node.shape as CircleShape2D).radius = _radius + ring_width
	queue_redraw()
	if _radius >= max_radius:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if _hit_player:
		return
	if not area.has_method("receive_hit"):
		return
	# Only damage if the target is near the ring edge, not deep inside
	var dist := global_position.distance_to(area.global_position)
	if dist >= _radius - ring_width * 2.0 and dist <= _radius + ring_width * 2.0:
		_hit_player = true
		var knockback_dir := (area.global_position - global_position).normalized()
		area.receive_hit(damage, knockback_dir * 350.0)

func _process(_delta: float) -> void:
	# Continuous ring-edge proximity check (area_entered only fires once on overlap)
	if _hit_player:
		return
	for body in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(body):
			continue
		var dist := global_position.distance_to(body.global_position)
		if dist >= _radius - ring_width * 2.0 and dist <= _radius + ring_width * 2.0:
			var hurtbox_node: Area2D = body.get("hurtbox")
			if hurtbox_node and hurtbox_node.has_method("receive_hit"):
				_hit_player = true
				var knockback_dir: Vector2 = (body.global_position - global_position).normalized()
				hurtbox_node.receive_hit(damage, knockback_dir * 350.0)
				break

func _draw() -> void:
	var alpha := clampf(1.0 - _radius / max_radius, 0.1, 0.8)
	var pulse := 0.1 * sin(_time * 8.0)
	# Outer glow
	draw_arc(Vector2.ZERO, _radius + ring_width * 0.5, 0, TAU, 64,
		Color(color_glow.r, color_glow.g, color_glow.b, alpha * 0.3 + pulse), ring_width * 1.5)
	# Main ring
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 64,
		Color(color_core.r, color_core.g, color_core.b, alpha + pulse), ring_width)
	# Inner bright edge
	draw_arc(Vector2.ZERO, _radius - ring_width * 0.3, 0, TAU, 64,
		Color(color_bright.r, color_bright.g, color_bright.b, alpha * 0.7), ring_width * 0.4)
	# Core center line
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 64,
		Color(color_center.r, color_center.g, color_center.b, alpha * 0.5), ring_width * 0.2)

## Fire an expanding ring with a config dictionary.
## Config keys (all optional): damage, expand_speed, max_radius, ring_width,
## color_core, color_glow, color_bright, color_center. Unset keys use class defaults.
static func fire(parent: Node2D, from: Vector2, dmg: int, config: Dictionary = {}) -> void:
	var ring := Area2D.new()
	ring.set_script(load("res://scripts/arena/ExpandingRing.gd"))
	ring.damage = dmg
	ring.position = from
	for key in config:
		ring.set(key, config[key])
	parent.add_child(ring)
