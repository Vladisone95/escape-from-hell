extends RefCounted
class_name RoomGrid

const LAVA: int = 0
const FLOOR: int = 1
const CELL_SIZE: int = 32

var width: int = 0
var height: int = 0
var cells: PackedByteArray
var _hw: float = 0.0
var _hh: float = 0.0

func generate(arena_size: Vector2, seed_val: int, boss_mode: bool = false) -> void:
	width = int(arena_size.x / CELL_SIZE) + 4  # +4 for lava border
	height = int(arena_size.y / CELL_SIZE) + 4
	_hw = width * CELL_SIZE * 0.5
	_hh = height * CELL_SIZE * 0.5
	cells.resize(width * height)
	cells.fill(LAVA)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val

	# Fill central rectangle as floor (leave 2-cell lava border)
	var margin: int = 2
	for gy: int in range(margin, height - margin):
		for gx: int in range(margin, width - margin):
			set_cell(gx, gy, FLOOR)

	# Corner erosion
	var erosion_depth: int = 3 if boss_mode else rng.randi_range(4, 8)
	_erode_corners(rng, margin, erosion_depth)

	# Edge wobble
	if not boss_mode:
		_wobble_edges(rng, margin)

	# Interior lava pools
	if not boss_mode:
		var pool_count: int = rng.randi_range(1, 3)
		for i: int in pool_count:
			_add_lava_pool(rng, margin)

	# Connectivity guarantee: flood fill from center, remove unreachable floor
	_enforce_connectivity()

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

func get_floor_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for gy: int in height:
		for gx: int in width:
			if is_floor(gx, gy):
				result.append(Vector2i(gx, gy))
	return result

func get_edge_floor_positions(distance: int = 3) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for gy: int in height:
		for gx: int in width:
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

func _erode_corners(rng: RandomNumberGenerator, margin: int, depth: int) -> void:
	var corners: Array[Vector2i] = [
		Vector2i(margin, margin),                          # top-left
		Vector2i(width - margin - 1, margin),              # top-right
		Vector2i(margin, height - margin - 1),             # bottom-left
		Vector2i(width - margin - 1, height - margin - 1), # bottom-right
	]
	var dirs: Array[Vector2i] = [
		Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)
	]
	for ci: int in 4:
		var corner: Vector2i = corners[ci]
		var dir: Vector2i = dirs[ci]
		for d: int in depth:
			var row_len: int = depth - d + rng.randi_range(-1, 1)
			row_len = maxi(0, row_len)
			for r: int in row_len:
				var gx: int = corner.x - dir.x * r
				var gy: int = corner.y - dir.y * d
				set_cell(gx, gy, LAVA)
				# Mirror: also erode in the other axis
				var gx2: int = corner.x - dir.x * d
				var gy2: int = corner.y - dir.y * r
				set_cell(gx2, gy2, LAVA)

func _wobble_edges(rng: RandomNumberGenerator, margin: int) -> void:
	# Top and bottom edges
	for gx: int in range(margin + 3, width - margin - 3):
		if rng.randf() < 0.3:
			var indent: int = rng.randi_range(1, 2)
			for d: int in indent:
				set_cell(gx, margin + d, LAVA)  # top
		if rng.randf() < 0.3:
			var indent: int = rng.randi_range(1, 2)
			for d: int in indent:
				set_cell(gx, height - margin - 1 - d, LAVA)  # bottom
	# Left and right edges
	for gy: int in range(margin + 3, height - margin - 3):
		if rng.randf() < 0.3:
			var indent: int = rng.randi_range(1, 2)
			for d: int in indent:
				set_cell(margin + d, gy, LAVA)  # left
		if rng.randf() < 0.3:
			var indent: int = rng.randi_range(1, 2)
			for d: int in indent:
				set_cell(width - margin - 1 - d, gy, LAVA)  # right

func _add_lava_pool(rng: RandomNumberGenerator, margin: int) -> void:
	var cx: int = rng.randi_range(margin + 5, width - margin - 5)
	var cy: int = rng.randi_range(margin + 5, height - margin - 5)
	# Don't place pools too close to center (player spawn)
	var center_x: int = width / 2
	var center_y: int = height / 2
	if absi(cx - center_x) < 4 and absi(cy - center_y) < 4:
		cx += 5 if cx >= center_x else -5
	var rx: int = rng.randi_range(2, 4)
	var ry: int = rng.randi_range(2, 3)
	for dy: int in range(-ry, ry + 1):
		for dx: int in range(-rx, rx + 1):
			var dist: float = float(dx * dx) / float(rx * rx) + float(dy * dy) / float(ry * ry)
			if dist <= 1.0 + rng.randf() * 0.3:
				set_cell(cx + dx, cy + dy, LAVA)

func _enforce_connectivity() -> void:
	var center_x: int = width / 2
	var center_y: int = height / 2
	if not is_floor(center_x, center_y):
		# Find nearest floor cell to center
		for r: int in range(1, maxi(width, height)):
			var found: bool = false
			for dy: int in range(-r, r + 1):
				for dx: int in range(-r, r + 1):
					if is_floor(center_x + dx, center_y + dy):
						center_x += dx
						center_y += dy
						found = true
						break
				if found:
					break
			if found:
				break

	# BFS from center
	var visited: PackedByteArray = PackedByteArray()
	visited.resize(width * height)
	visited.fill(0)
	var queue: Array[Vector2i] = [Vector2i(center_x, center_y)]
	visited[center_y * width + center_x] = 1
	var head: int = 0
	while head < queue.size():
		var pos: Vector2i = queue[head]
		head += 1
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: int = pos.x + dir.x
			var ny: int = pos.y + dir.y
			if nx >= 0 and nx < width and ny >= 0 and ny < height:
				var idx: int = ny * width + nx
				if visited[idx] == 0 and cells[idx] == FLOOR:
					visited[idx] = 1
					queue.append(Vector2i(nx, ny))

	# Remove unreachable floor cells
	for gy: int in height:
		for gx: int in width:
			var idx: int = gy * width + gx
			if cells[idx] == FLOOR and visited[idx] == 0:
				cells[idx] = LAVA
