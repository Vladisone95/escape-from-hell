extends Area2D

var damage: int = 20
var telegraph_duration: float = 3.0
var shadow_max_radius: float = 110.0
var impact_radius: float = 88.0

var _phase: int = 0  # 0=telegraph, 1=impact, 2=done
var _timer: float = 0.0
var _meteor_y_offset: float = -280.0
var _hit_done: bool = false

const METEOR_CORE := Color(0.95, 0.55, 0.10)
const METEOR_GLOW := Color(1.0, 0.30, 0.05)
const METEOR_HOT  := Color(1.0, 0.90, 0.40)
const METEOR_DARK := Color(0.30, 0.10, 0.02)
const FIRE_A      := Color(1.0, 0.55, 0.05)
const FIRE_B      := Color(1.0, 0.20, 0.02)
const FIRE_TIP    := Color(1.0, 0.90, 0.20)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.40)
const WARNING_COLOR := Color(1.0, 0.40, 0.05)

var _rock_vertices: PackedVector2Array = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	var vert_count: int = 12
	for i: int in range(vert_count):
		var a: float = TAU * i / float(vert_count)
		var r: float = impact_radius * randf_range(0.72, 1.0)
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
		collision_layer = 1 << 4  # enemy_attack
		collision_mask = 1 << 1   # player_body
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = impact_radius
		col.shape = shape
		add_child(col)
		area_entered.connect(_on_area_entered)
		_meteor_y_offset = -280.0
		SoundManager.play("meteor_incoming")

func _process_impact(_delta: float) -> void:
	_meteor_y_offset = lerpf(-280.0, 0.0, clampf(_timer / 0.35, 0.0, 1.0))
	if _timer >= 0.35:
		_convert_to_obstacle()

func _on_area_entered(area: Area2D) -> void:
	if _hit_done:
		return
	if area.has_method("receive_hit"):
		var knockback_dir: Vector2 = (area.global_position - global_position).normalized() * 200.0
		area.receive_hit(damage, knockback_dir)
		_hit_done = true

func _convert_to_obstacle() -> void:
	SoundManager.play("meteor_crash")
	var parent_node: Node2D = get_parent()
	if parent_node == null:
		queue_free()
		return
	var obs := StaticBody2D.new()
	obs.position = position
	obs.collision_layer = 1 << 6  # layer 7: meteor_obstacle (projectiles pass through)
	obs.collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = impact_radius
	col.shape = shape
	obs.add_child(col)
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
	var radius: float = lerpf(12.0, shadow_max_radius, progress)
	# Shadow ellipse — orange-tinted
	var pts: PackedVector2Array = []
	for i: int in range(24):
		var a: float = TAU * i / 24.0
		pts.append(Vector2(cos(a) * radius, sin(a) * radius * 0.55))
	var shadow_c := Color(0.15, 0.04, 0.0, lerpf(0.15, 0.50, progress))
	draw_colored_polygon(pts, shadow_c)
	# Outer heat ring
	var pulse: float = 0.5 + 0.5 * sin(_timer * 7.0)
	var ring_alpha: float = lerpf(0.25, 0.85, progress) * pulse
	for i: int in range(24):
		var a1: float = TAU * i / 24.0
		var a2: float = TAU * (i + 1) / 24.0
		var p1: Vector2 = Vector2(cos(a1) * radius, sin(a1) * radius * 0.55)
		var p2: Vector2 = Vector2(cos(a2) * radius, sin(a2) * radius * 0.55)
		draw_line(p1, p2, Color(WARNING_COLOR.r, WARNING_COLOR.g, WARNING_COLOR.b, ring_alpha), 2.5)
	# Inner glow dot — shows where it's going to land
	if progress > 0.3:
		var dot_r: float = lerpf(0.0, 8.0, (progress - 0.3) / 0.7)
		var dot_alpha: float = lerpf(0.0, 0.9, (progress - 0.3) / 0.7) * (0.5 + 0.5 * pulse)
		draw_circle(Vector2.ZERO, dot_r + 4.0, Color(1.0, 0.3, 0.05, dot_alpha * 0.4))
		draw_circle(Vector2.ZERO, dot_r, Color(1.0, 0.85, 0.3, dot_alpha))
	# Falling meteor hint in sky (tiny, far up)
	if progress > 0.1:
		var far_y: float = -240.0 + progress * 200.0
		var hint_r: float = lerpf(2.0, 7.0, progress)
		draw_circle(Vector2(0, far_y), hint_r + 3.0, Color(1.0, 0.4, 0.05, 0.35 * progress))
		draw_circle(Vector2(0, far_y), hint_r, Color(1.0, 0.85, 0.35, 0.75 * progress))
		# Fire trail hint
		for t: int in range(5):
			var trail_y: float = far_y + float(t + 1) * 6.0
			var trail_alpha: float = 0.5 * (1.0 - float(t) / 5.0) * progress
			draw_circle(Vector2(randf_range(-1.5, 1.5), trail_y), 2.5 - float(t) * 0.4, Color(1.0, 0.45, 0.05, trail_alpha))

func _draw_impact() -> void:
	var fall_t: float = clampf(_timer / 0.35, 0.0, 1.0)
	var my: float = _meteor_y_offset
	var core_r: float = impact_radius * 0.85

	# Shadow under impact point
	var pts: PackedVector2Array = []
	for i: int in range(24):
		var a: float = TAU * i / 24.0
		pts.append(Vector2(cos(a) * shadow_max_radius, sin(a) * shadow_max_radius * 0.55))
	draw_colored_polygon(pts, Color(0.0, 0.0, 0.0, 0.45))

	# Outer heat glow halo (large, soft)
	var glow_r: float = core_r + 28.0
	var glow_pts: PackedVector2Array = []
	for i: int in range(32):
		var a: float = TAU * i / 32.0
		glow_pts.append(Vector2(cos(a) * glow_r, sin(a) * glow_r + my))
	draw_colored_polygon(glow_pts, Color(1.0, 0.35, 0.02, 0.35))

	# Meteor body polygon (jagged rock shape, shifted up by my)
	var rock_pts: PackedVector2Array = []
	for v: Vector2 in _rock_vertices:
		rock_pts.append(v + Vector2(0, my))
	if rock_pts.size() >= 3:
		draw_colored_polygon(rock_pts, METEOR_DARK)
		# Hot cracks / magma seams
		for i: int in range(rock_pts.size()):
			var next_i: int = (i + 1) % rock_pts.size()
			var edge_t: float = float(i) / float(rock_pts.size())
			var heat: float = 0.5 + 0.5 * sin(edge_t * TAU * 3.0 + _timer * 20.0)
			draw_line(rock_pts[i], rock_pts[next_i], Color(1.0, 0.45 * heat, 0.0, 0.6 + heat * 0.4), 1.8)

	# Core bright spot
	draw_circle(Vector2(0, my), core_r * 0.6, Color(1.0, 0.6, 0.1, 0.9))
	draw_circle(Vector2(0, my - core_r * 0.15), core_r * 0.3, METEOR_HOT)

	# Fire trail above the meteor
	var trail_len: int = 8
	for t: int in range(trail_len):
		var trail_y: float = my - float(t + 1) * 14.0
		var trail_frac: float = float(t) / float(trail_len)
		var tr: float = lerpf(core_r * 0.55, 4.0, trail_frac)
		var ta: float = lerpf(0.8, 0.0, trail_frac)
		draw_circle(Vector2(0, trail_y), tr + 5.0, Color(1.0, 0.25, 0.02, ta * 0.35))
		draw_circle(Vector2(0, trail_y), tr, Color(1.0, lerpf(0.55, 0.9, trail_frac), 0.1, ta))

	# Flame tongues licking forward (animated)
	var flame_count: int = 6
	for f: int in range(flame_count):
		var fa: float = TAU * f / float(flame_count) + _timer * 8.0 + float(f) * 0.9
		var flame_len: float = core_r * (0.6 + 0.4 * sin(_timer * 12.0 + float(f) * 1.3))
		var flame_base: Vector2 = Vector2(cos(fa), sin(fa)) * core_r * 0.7 + Vector2(0, my)
		var flame_tip: Vector2 = flame_base + Vector2(cos(fa), sin(fa)) * flame_len
		draw_line(flame_base, flame_tip, Color(1.0, 0.6, 0.05, 0.7), 3.5)
		draw_line(flame_base, (flame_base + flame_tip) * 0.5, FIRE_TIP, 1.8)

static func fire(parent: Node2D, target_pos: Vector2, dmg: int = 20) -> void:
	var meteor := Area2D.new()
	meteor.set_script(load("res://scripts/arena/MeteorStrike.gd"))
	meteor.damage = dmg
	meteor.position = target_pos
	parent.add_child(meteor)
