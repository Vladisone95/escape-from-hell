extends Node2D

var _grid: RoomGrid

func init(grid: RoomGrid, seed_val: int) -> void:
	_grid = grid
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val + 9999

	# Find lava cells and place emitters on a random subset
	var lava_cells: Array[Vector2i] = []
	for gy: int in grid.height:
		for gx: int in grid.width:
			if grid.get_cell(gx, gy) == RoomGrid.LAVA:
				lava_cells.append(Vector2i(gx, gy))
	if lava_cells.is_empty():
		return

	var emitter_count: int = mini(12, maxi(6, lava_cells.size() / 10))
	for i: int in emitter_count:
		var cell: Vector2i = lava_cells[rng.randi_range(0, lava_cells.size() - 1)]
		var world_pos: Vector2 = grid.grid_to_world(cell.x, cell.y)
		_create_emitter(world_pos, rng)

func _create_emitter(pos: Vector2, rng: RandomNumberGenerator) -> void:
	var particles: GPUParticles2D = GPUParticles2D.new()
	particles.position = pos
	particles.amount = rng.randi_range(2, 4)
	particles.lifetime = 1.2
	particles.speed_scale = 0.8 + rng.randf() * 0.4
	particles.randomness = 0.5
	particles.visibility_rect = Rect2(-40, -80, 80, 100)

	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 25.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3(0, 120, 0)  # pulls particles back down
	mat.scale_min = 1.0
	mat.scale_max = 2.5
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 8.0

	# Color: bright orange → dark red → transparent
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.5, 0.0, 0.9))
	gradient.add_point(0.5, Color(1.0, 0.2, 0.0, 0.7))
	gradient.set_color(1, Color(0.4, 0.05, 0.0, 0.0))
	var grad_tex: GradientTexture1D = GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex

	# Scale curve: grow then shrink
	var scale_curve: Curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.3))
	scale_curve.add_point(Vector2(0.3, 1.0))
	scale_curve.add_point(Vector2(1.0, 0.1))
	var scale_curve_tex: CurveTexture = CurveTexture.new()
	scale_curve_tex.curve = scale_curve
	mat.scale_curve = scale_curve_tex

	particles.process_material = mat
	particles.emitting = true
	add_child(particles)
