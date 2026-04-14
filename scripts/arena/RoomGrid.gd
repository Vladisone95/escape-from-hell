extends RefCounted
class_name RoomGrid

const LAVA: int = 0
const FLOOR: int = 1
const CELL_SIZE: int = 32
const BORDER: int = 12   # lava margin around the ground (12 cells = 384px)
const GRID_W: int = 64   # 40 playable + 12-cell border each side
const GRID_H: int = 64   # 40 playable + 12-cell border each side

var width: int = 0
var height: int = 0
var cells: PackedByteArray
var _hw: float = 0.0
var _hh: float = 0.0

func generate(seed_val: int, boss_mode: bool = false) -> void:
	width = GRID_W
	height = GRID_H
	_hw = width * CELL_SIZE * 0.5
	_hh = height * CELL_SIZE * 0.5
	cells.resize(width * height)
	cells.fill(LAVA)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	# Fill central rectangle as floor (perfect square)
	var margin: int = BORDER
	for gy: int in range(margin, height - margin):
		for gx: int in range(margin, width - margin):
			set_cell(gx, gy, FLOOR)

	# Interior lava pools
	if not boss_mode:
		_add_lava_pools(rng, margin)

	# Lava islands (decorative ground patches in the outer lava)
	_add_islands(rng, margin)

func get_cell(gx: int, gy: int) -> int:
	if gx < 0 or gx >= width or gy < 0 or gy >= height:
		return LAVA
	return cells[gy * width + gx]

func set_cell(gx: int, gy: int, val: int) -> void:
	if gx >= 0 and gx < width and gy >= 0 and gy < height:
		cells[gy * width + gx] = val

func is_floor(gx: int, gy: int) -> bool:
	return get_cell(gx, gy) == FLOOR

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var gx: int = int((world_pos.x + _hw) / CELL_SIZE)
	var gy: int = int((world_pos.y + _hh) / CELL_SIZE)
	return Vector2i(gx, gy)

func grid_to_world(gx: int, gy: int) -> Vector2:
	return Vector2(gx * CELL_SIZE - _hw + CELL_SIZE * 0.5, gy * CELL_SIZE - _hh + CELL_SIZE * 0.5)

func get_origin() -> Vector2:
	return Vector2(-_hw, -_hh)

func get_floor_positions(main_area_only: bool = false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var min_g: int = BORDER if main_area_only else 0
	var max_gx: int = (width - BORDER) if main_area_only else width
	var max_gy: int = (height - BORDER) if main_area_only else height
	for gy: int in range(min_g, max_gy):
		for gx: int in range(min_g, max_gx):
			if is_floor(gx, gy):
				result.append(Vector2i(gx, gy))
	return result

func get_edge_floor_positions(distance: int = 3, main_area_only: bool = false) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var min_g: int = BORDER if main_area_only else 0
	var max_gx: int = (width - BORDER) if main_area_only else width
	var max_gy: int = (height - BORDER) if main_area_only else height
	for gy: int in range(min_g, max_gy):
		for gx: int in range(min_g, max_gx):
			if not is_floor(gx, gy):
				continue
			var near_lava: bool = false
			for dy: int in range(-distance, distance + 1):
				for dx: int in range(-distance, distance + 1):
					if get_cell(gx + dx, gy + dy) == LAVA:
						near_lava = true
						break
				if near_lava:
					break
			if near_lava:
				result.append(Vector2i(gx, gy))
	return result

func get_lava_boundary_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for gy: int in height:
		for gx: int in width:
			if get_cell(gx, gy) != LAVA:
				continue
			if is_floor(gx - 1, gy) or is_floor(gx + 1, gy) or is_floor(gx, gy - 1) or is_floor(gx, gy + 1):
				result.append(Vector2i(gx, gy))
	return result

## Build an AStarGrid2D from this grid's floor/lava layout.
## obstacle_world_positions: world-space centres of physical obstacles to mark solid.
func build_astar(obstacle_world_positions: Array[Vector2]) -> AStarGrid2D:
	var astar: AStarGrid2D = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, width, height)
	astar.cell_size = Vector2(CELL_SIZE, CELL_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	# Mark all non-floor cells solid
	for gy: int in height:
		for gx: int in width:
			if not is_floor(gx, gy):
				astar.set_point_solid(Vector2i(gx, gy), true)
	# Mark cells under/around each obstacle solid (radius 2 cells)
	for world_pos: Vector2 in obstacle_world_positions:
		var cell: Vector2i = world_to_grid(world_pos)
		for dy: int in range(-2, 3):
			for dx: int in range(-2, 3):
				var cx: int = cell.x + dx
				var cy: int = cell.y + dy
				if cx >= 0 and cx < width and cy >= 0 and cy < height:
					astar.set_point_solid(Vector2i(cx, cy), true)
	return astar

## Returns autotile bitmask for a floor cell (4-bit cardinal + 4-bit diagonal)
func get_tile_bitmask(gx: int, gy: int) -> int:
	var mask: int = 0
	if is_floor(gx, gy - 1): mask |= 1       # N
	if is_floor(gx + 1, gy): mask |= 2       # E
	if is_floor(gx, gy + 1): mask |= 4       # S
	if is_floor(gx - 1, gy): mask |= 8       # W
	if is_floor(gx + 1, gy - 1): mask |= 16  # NE
	if is_floor(gx + 1, gy + 1): mask |= 32  # SE
	if is_floor(gx - 1, gy + 1): mask |= 64  # SW
	if is_floor(gx - 1, gy - 1): mask |= 128 # NW
	return mask

# ── Private generation helpers ──

func _add_lava_pools(rng: RandomNumberGenerator, margin: int) -> void:
	var pool_count: int = rng.randi_range(2, 4)
	var pools: Array[Rect2i] = []
	var center_x: int = width / 2
	var center_y: int = height / 2
	var min_edge: int = 3
	var min_center: int = 6
	var min_gap: int = 3

	for i: int in pool_count:
		var attempts: int = 0
		while attempts < 30:
			attempts += 1
			var pw: int = rng.randi_range(3, 6)
			var ph: int = rng.randi_range(3, 6)
			var px: int = rng.randi_range(margin + min_edge, width - margin - min_edge - pw)
			var py: int = rng.randi_range(margin + min_edge, height - margin - min_edge - ph)
			# Avoid center (player spawn)
			var pcx: float = px + pw * 0.5
			var pcy: float = py + ph * 0.5
			if absf(pcx - center_x) < min_center and absf(pcy - center_y) < min_center:
				continue
			# Avoid overlap with existing pools (including gap)
			var rect: Rect2i = Rect2i(px, py, pw, ph)
			var overlap: bool = false
			for existing: Rect2i in pools:
				var expanded: Rect2i = Rect2i(
					existing.position - Vector2i(min_gap, min_gap),
					existing.size + Vector2i(min_gap * 2, min_gap * 2))
				if expanded.intersects(rect):
					overlap = true
					break
			if overlap:
				continue
			pools.append(rect)
			for gy: int in range(py, py + ph):
				for gx: int in range(px, px + pw):
					set_cell(gx, gy, LAVA)
			break

func _add_islands(rng: RandomNumberGenerator, margin: int) -> void:
	var islands: Array[Rect2i] = []
	var arena_ring: Rect2i = Rect2i(margin - 2, margin - 2,
		width - 2 * margin + 4, height - 2 * margin + 4)

	# Small islands (1x2 ground, 3x3 footprint)
	var small_count: int = rng.randi_range(3, 5)
	for i: int in small_count:
		_try_place_island(rng, 1, 2, islands, arena_ring)

	# One bigger island (2x2 to 3x3 ground)
	if rng.randf() < 0.7:
		var bw: int = rng.randi_range(2, 3)
		var bh: int = rng.randi_range(2, 3)
		_try_place_island(rng, bw, bh, islands, arena_ring)

	# One large island (5x6 ground)
	_try_place_island(rng, 5, 6, islands, arena_ring)

func _try_place_island(rng: RandomNumberGenerator, iw: int, ih: int,
		islands: Array[Rect2i], arena_ring: Rect2i) -> void:
	for attempt: int in 40:
		var ix: int = rng.randi_range(1, width - iw - 1)
		var iy: int = rng.randi_range(1, height - ih - 1)
		var ground_rect: Rect2i = Rect2i(ix, iy, iw, ih)
		var footprint: Rect2i = Rect2i(ix - 1, iy - 1, iw + 2, ih + 2)
		if footprint.intersects(arena_ring):
			continue
		var overlap: bool = false
		for existing: Rect2i in islands:
			var gap_rect: Rect2i = Rect2i(
				existing.position - Vector2i(3, 3),
				existing.size + Vector2i(6, 6))
			if gap_rect.intersects(ground_rect):
				overlap = true
				break
		if overlap:
			continue
		islands.append(ground_rect)
		for gy: int in range(iy, iy + ih):
			for gx: int in range(ix, ix + iw):
				set_cell(gx, gy, FLOOR)
		return
