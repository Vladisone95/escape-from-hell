extends Area2D

var damage: int = 20
var telegraph_duration: float = 3.0
var shadow_max_radius: float = 50.0
var impact_radius: float = 44.0

var _phase: int = 0  # 0=telegraph, 1=impact, 2=done
var _timer: float = 0.0
var _rock_y_offset: float = -200.0
var _hit_done: bool = false

const ROCK_COLOR := Color(0.30, 0.22, 0.18)
const ROCK_DARK := Color(0.18, 0.12, 0.10)
const ROCK_LIGHT := Color(0.42, 0.35, 0.28)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)
const WARNING_COLOR := Color(0.9, 0.15, 0.1, 0.6)

var _rock_vertices: PackedVector2Array = []

func _ready() -> void:
	# No collision during telegraph
	collision_layer = 0
	collision_mask = 0
	# Generate jagged rock shape
	var vert_count: int = 10
	for i: int in range(vert_count):
		var a: float = TAU * i / float(vert_count)
		var r: float = impact_radius * randf_range(0.7, 1.0)
		_rock_vertices.append(Vector2(cos(a) * r, sin(a) * r))

func _physics_process(delta: float) -> void:
	_timer += delta
	match _phase:
		0: _process_telegraph(delta)
		1: _process_impact(delta)
	queue_redraw()

func _process_telegraph(_delta: float) -> void:
	if _timer >= telegraph_duration:
		_phase = 1
		_timer = 0.0
		# Enable collision for impact
		collision_layer = 1 << 4  # enemy_attack
		collision_mask = 1 << 1   # player_body
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = impact_radius
		col.shape = shape
		add_child(col)
		area_entered.connect(_on_area_entered)
		_rock_y_offset = -200.0

func _process_impact(_delta: float) -> void:
	_rock_y_offset = lerpf(-200.0, 0.0, clampf(_timer / 0.3, 0.0, 1.0))
	if _timer >= 0.3:
		_convert_to_obstacle()

func _on_area_entered(area: Area2D) -> void:
	if _hit_done:
		return
	if area.has_method("receive_hit"):
		var knockback_dir: Vector2 = (area.global_position - global_position).normalized() * 180.0
		area.receive_hit(damage, knockback_dir)
		_hit_done = true

func _convert_to_obstacle() -> void:
	var parent_node: Node2D = get_parent()
	if parent_node == null:
		queue_free()
		return
	# Create permanent obstacle
	var obs := StaticBody2D.new()
	obs.position = position
	obs.collision_layer = 1 << 0  # world
	obs.collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = impact_radius
	col.shape = shape
	obs.add_child(col)
	# Rock visual
	var vis := Node2D.new()
	vis.set_script(load("res://scripts/arena/MeteorRockVisual.gd"))
	vis.set_meta("vertices", _rock_vertices)
	obs.add_child(vis)
	parent_node.add_child(obs)
	queue_free()

func _draw() -> void:
	match _phase:
		0: _draw_telegraph()
		1: _draw_impact()

func _draw_telegraph() -> void:
	var progress: float = clampf(_timer / telegraph_duration, 0.0, 1.0)
	var radius: float = lerpf(10.0, shadow_max_radius, progress)
	# Shadow ellipse
	var pts: PackedVector2Array = []
	for i: int in range(20):
		var a: float = TAU * i / 20.0
		pts.append(Vector2(cos(a) * radius, sin(a) * radius * 0.6))
	var alpha: float = lerpf(0.15, 0.45, progress)
	draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, alpha))
	# Pulsing warning ring
	var pulse: float = 0.5 + 0.5 * sin(_timer * 6.0)
	var ring_alpha: float = lerpf(0.2, 0.7, progress) * pulse
	for i: int in range(20):
		var a1: float = TAU * i / 20.0
		var a2: float = TAU * (i + 1) / 20.0
		var p1: Vector2 = Vector2(cos(a1) * radius, sin(a1) * radius * 0.6)
		var p2: Vector2 = Vector2(cos(a2) * radius, sin(a2) * radius * 0.6)
		draw_line(p1, p2, Color(WARNING_COLOR.r, WARNING_COLOR.g, WARNING_COLOR.b, ring_alpha), 2.0)

func _draw_impact() -> void:
	# Shadow stays
	var pts: PackedVector2Array = []
	for i: int in range(20):
		var a: float = TAU * i / 20.0
		pts.append(Vector2(cos(a) * shadow_max_radius, sin(a) * shadow_max_radius * 0.6))
	draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.4))
	# Rock falling in
	var rock_pts: PackedVector2Array = []
	for v: Vector2 in _rock_vertices:
		rock_pts.append(v + Vector2(0, _rock_y_offset))
	if rock_pts.size() >= 3:
		draw_colored_polygon(rock_pts, ROCK_COLOR)
		# Highlight
		for i: int in range(rock_pts.size()):
			var next_i: int = (i + 1) % rock_pts.size()
			draw_line(rock_pts[i], rock_pts[next_i], ROCK_DARK, 1.5)
		# Light top edge
		if rock_pts.size() > 2:
			draw_line(rock_pts[0], rock_pts[1], ROCK_LIGHT, 2.0)

static func fire(parent: Node2D, target_pos: Vector2, dmg: int = 20) -> void:
	var meteor := Area2D.new()
	meteor.set_script(load("res://scripts/arena/MeteorStrike.gd"))
	meteor.damage = dmg
	meteor.position = target_pos
	parent.add_child(meteor)
