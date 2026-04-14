extends TileMapLayer
class_name ArenaFloorTileMap

# ── Outer border: ground tiles ──
const CENTER: Vector2i = Vector2i(3, 3)

const GROUND_CORNER_NW: Vector2i = Vector2i(1, 1)
const GROUND_CORNER_NE: Vector2i = Vector2i(6, 1)
const GROUND_CORNER_SW: Vector2i = Vector2i(1, 6)
const GROUND_CORNER_SE: Vector2i = Vector2i(6, 6)

const GROUND_EDGE_LEFT: Array[Vector2i] = [Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 5)]
const GROUND_EDGE_RIGHT: Array[Vector2i] = [Vector2i(6, 2), Vector2i(6, 3), Vector2i(6, 4), Vector2i(6, 5)]
const GROUND_EDGE_TOP: Array[Vector2i] = [Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1)]
const GROUND_EDGE_BOTTOM: Array[Vector2i] = [Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6)]

# ── Outer border: lava tiles ──
const DEEP_LAVA: Vector2i = Vector2i(0, 0)

const LAVA_CORNER_NW: Vector2i = Vector2i(0, 0)
const LAVA_CORNER_NE: Vector2i = Vector2i(7, 0)
const LAVA_CORNER_SW: Vector2i = Vector2i(0, 7)
const LAVA_CORNER_SE: Vector2i = Vector2i(7, 7)

const LAVA_TRANS_LEFT_TOP: Vector2i = Vector2i(0, 1)
const LAVA_TRANS_LEFT_BOTTOM: Vector2i = Vector2i(0, 6)
const LAVA_TRANS_RIGHT_TOP: Vector2i = Vector2i(7, 1)
const LAVA_TRANS_RIGHT_BOTTOM: Vector2i = Vector2i(7, 6)
const LAVA_TRANS_TOP_LEFT: Vector2i = Vector2i(1, 0)
const LAVA_TRANS_TOP_RIGHT: Vector2i = Vector2i(6, 0)
const LAVA_TRANS_BOTTOM_LEFT: Vector2i = Vector2i(1, 7)
const LAVA_TRANS_BOTTOM_RIGHT: Vector2i = Vector2i(6, 7)

const LAVA_EDGE_LEFT: Array[Vector2i] = [Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4), Vector2i(0, 5)]
const LAVA_EDGE_RIGHT: Array[Vector2i] = [Vector2i(7, 2), Vector2i(7, 3), Vector2i(7, 4), Vector2i(7, 5)]
const LAVA_EDGE_TOP: Array[Vector2i] = [Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)]
const LAVA_EDGE_BOTTOM: Array[Vector2i] = [Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7), Vector2i(5, 7)]

# ── Pool: unique ground corners (3 tiles per lava corner) ──
const POOL_GC_NW_DIAG: Vector2i = Vector2i(8, 0)
const POOL_GC_NW_TOP: Vector2i = Vector2i(9, 0)
const POOL_GC_NW_LEFT: Vector2i = Vector2i(8, 1)
const POOL_GC_NE_DIAG: Vector2i = Vector2i(15, 0)
const POOL_GC_NE_TOP: Vector2i = Vector2i(14, 0)
const POOL_GC_NE_RIGHT: Vector2i = Vector2i(15, 1)
const POOL_GC_SW_DIAG: Vector2i = Vector2i(8, 7)
const POOL_GC_SW_BOTTOM: Vector2i = Vector2i(9, 7)
const POOL_GC_SW_LEFT: Vector2i = Vector2i(8, 6)
const POOL_GC_SE_DIAG: Vector2i = Vector2i(15, 7)
const POOL_GC_SE_BOTTOM: Vector2i = Vector2i(14, 7)
const POOL_GC_SE_RIGHT: Vector2i = Vector2i(15, 6)

# ── Pool: ground edge variants ──
const POOL_GROUND_TOP: Array[Vector2i] = [Vector2i(10, 0), Vector2i(11, 0), Vector2i(12, 0), Vector2i(13, 0)]
const POOL_GROUND_BOTTOM: Array[Vector2i] = [Vector2i(10, 7), Vector2i(11, 7), Vector2i(12, 7), Vector2i(13, 7)]
const POOL_GROUND_LEFT: Array[Vector2i] = [Vector2i(8, 2), Vector2i(8, 3), Vector2i(8, 4), Vector2i(8, 5)]
const POOL_GROUND_RIGHT: Array[Vector2i] = [Vector2i(15, 2), Vector2i(15, 3), Vector2i(15, 4), Vector2i(15, 5)]

# ── Pool: lava corners (unique) ──
const POOL_LAVA_NW: Vector2i = Vector2i(9, 1)
const POOL_LAVA_NE: Vector2i = Vector2i(14, 1)
const POOL_LAVA_SW: Vector2i = Vector2i(9, 6)
const POOL_LAVA_SE: Vector2i = Vector2i(14, 6)

# ── Pool: lava edge variants ──
const POOL_LAVA_TOP: Array[Vector2i] = [Vector2i(10, 1), Vector2i(11, 1), Vector2i(12, 1), Vector2i(13, 1)]
const POOL_LAVA_BOTTOM: Array[Vector2i] = [Vector2i(10, 6), Vector2i(11, 6), Vector2i(12, 6), Vector2i(13, 6)]
const POOL_LAVA_LEFT: Array[Vector2i] = [Vector2i(9, 2), Vector2i(9, 3), Vector2i(9, 4), Vector2i(9, 5)]
const POOL_LAVA_RIGHT: Array[Vector2i] = [Vector2i(14, 2), Vector2i(14, 3), Vector2i(14, 4), Vector2i(14, 5)]

# ── Island: ground corners (unique) ──
const ISLAND_GR_NW: Vector2i = Vector2i(17, 1)
const ISLAND_GR_NE: Vector2i = Vector2i(18, 1)
const ISLAND_GR_SW: Vector2i = Vector2i(17, 2)
const ISLAND_GR_SE: Vector2i = Vector2i(18, 2)

# ── Island (big): ground edge variants (non-corner) ──
const ISLAND_EDGE_TOP: Array[Vector2i] = [Vector2i(10, 3), Vector2i(13, 3)]
const ISLAND_EDGE_BOTTOM: Array[Vector2i] = [Vector2i(10, 4), Vector2i(13, 4)]
const ISLAND_EDGE_LEFT: Array[Vector2i] = [Vector2i(11, 2), Vector2i(11, 4)]
const ISLAND_EDGE_RIGHT: Array[Vector2i] = [Vector2i(12, 2), Vector2i(12, 4)]

# ── Island (big): lava tiles ──
const ISLAND_LAVA_NW: Vector2i = Vector2i(16, 0)
const ISLAND_LAVA_NE: Vector2i = Vector2i(19, 0)
const ISLAND_LAVA_TOP: Array[Vector2i] = [Vector2i(17, 0), Vector2i(18, 0)]
const ISLAND_LAVA_LEFT_UPPER: Vector2i = Vector2i(16, 1)
const ISLAND_LAVA_LEFT_LOWER: Vector2i = Vector2i(16, 2)
const ISLAND_LAVA_RIGHT_UPPER: Vector2i = Vector2i(19, 1)
const ISLAND_LAVA_RIGHT_LOWER: Vector2i = Vector2i(19, 2)

# ── Island (small, 1x2 ground): ground tiles ──
const SMALL_ISLAND_TOP: Vector2i = Vector2i(17, 4)
const SMALL_ISLAND_BOTTOM: Vector2i = Vector2i(17, 5)

# ── Island (small): lava tiles (3x3 around 1x2 ground) ──
const SMALL_LAVA_NW: Vector2i = Vector2i(16, 3)
const SMALL_LAVA_TOP: Vector2i = Vector2i(17, 3)
const SMALL_LAVA_NE: Vector2i = Vector2i(18, 3)
const SMALL_LAVA_LEFT_UPPER: Vector2i = Vector2i(16, 4)
const SMALL_LAVA_RIGHT_UPPER: Vector2i = Vector2i(18, 4)
const SMALL_LAVA_LEFT_LOWER: Vector2i = Vector2i(16, 5)
const SMALL_LAVA_RIGHT_LOWER: Vector2i = Vector2i(18, 5)

var _grid: RoomGrid
var _left: int
var _top: int
var _right: int
var _bottom: int

func populate(grid: RoomGrid) -> void:
	_grid = grid
	clear()
	_left = RoomGrid.BORDER
	_top = RoomGrid.BORDER
	_right = grid.width - RoomGrid.BORDER - 1
	_bottom = grid.height - RoomGrid.BORDER - 1

	for gy: int in grid.height:
		for gx: int in grid.width:
			var atlas: Vector2i = _select_tile(gx, gy)
			set_cell(Vector2i(gx, gy), 0, atlas)

func _select_tile(gx: int, gy: int) -> Vector2i:
	if _grid.is_floor(gx, gy):
		if _is_island(gx, gy):
			return _select_island_ground(gx, gy)
		return _select_ground(gx, gy)
	return _select_lava(gx, gy)

# ── Ground selection ──

func _select_ground(gx: int, gy: int) -> Vector2i:
	var on_left: bool = gx == _left
	var on_right: bool = gx == _right
	var on_top: bool = gy == _top
	var on_bottom: bool = gy == _bottom
	if on_left or on_right or on_top or on_bottom:
		if on_left and on_top: return GROUND_CORNER_NW
		if on_right and on_top: return GROUND_CORNER_NE
		if on_left and on_bottom: return GROUND_CORNER_SW
		if on_right and on_bottom: return GROUND_CORNER_SE
		if on_left: return _variant(GROUND_EDGE_LEFT, gx, gy)
		if on_right: return _variant(GROUND_EDGE_RIGHT, gx, gy)
		if on_top: return _variant(GROUND_EDGE_TOP, gx, gy)
		return _variant(GROUND_EDGE_BOTTOM, gx, gy)

	# Pool border
	var pn: bool = _is_pool_lava(gx, gy - 1)
	var ps: bool = _is_pool_lava(gx, gy + 1)
	var pe: bool = _is_pool_lava(gx + 1, gy)
	var pw: bool = _is_pool_lava(gx - 1, gy)

	if ps and not pe and not pw:
		var pse: bool = _is_pool_lava(gx + 1, gy + 1)
		var psw: bool = _is_pool_lava(gx - 1, gy + 1)
		if pse and not psw: return POOL_GC_NW_TOP
		if psw and not pse: return POOL_GC_NE_TOP
		return _variant(POOL_GROUND_TOP, gx, gy)
	if pn and not pe and not pw:
		var pne: bool = _is_pool_lava(gx + 1, gy - 1)
		var pnw: bool = _is_pool_lava(gx - 1, gy - 1)
		if pne and not pnw: return POOL_GC_SW_BOTTOM
		if pnw and not pne: return POOL_GC_SE_BOTTOM
		return _variant(POOL_GROUND_BOTTOM, gx, gy)
	if pe and not pn and not ps:
		var pse: bool = _is_pool_lava(gx + 1, gy + 1)
		var pne: bool = _is_pool_lava(gx + 1, gy - 1)
		if pse and not pne: return POOL_GC_NW_LEFT
		if pne and not pse: return POOL_GC_SW_LEFT
		return _variant(POOL_GROUND_LEFT, gx, gy)
	if pw and not pn and not ps:
		var psw: bool = _is_pool_lava(gx - 1, gy + 1)
		var pnw: bool = _is_pool_lava(gx - 1, gy - 1)
		if psw and not pnw: return POOL_GC_NE_RIGHT
		if pnw and not psw: return POOL_GC_SE_RIGHT
		return _variant(POOL_GROUND_RIGHT, gx, gy)

	if not pn and not ps and not pe and not pw:
		if _is_pool_lava(gx + 1, gy + 1): return POOL_GC_NW_DIAG
		if _is_pool_lava(gx - 1, gy + 1): return POOL_GC_NE_DIAG
		if _is_pool_lava(gx + 1, gy - 1): return POOL_GC_SW_DIAG
		if _is_pool_lava(gx - 1, gy - 1): return POOL_GC_SE_DIAG

	return CENTER

func _select_island_ground(gx: int, gy: int) -> Vector2i:
	var ln: bool = not _grid.is_floor(gx, gy - 1)
	var ls: bool = not _grid.is_floor(gx, gy + 1)
	var le: bool = not _grid.is_floor(gx + 1, gy)
	var lw: bool = not _grid.is_floor(gx - 1, gy)
	# Small island (1 tile wide)
	if le and lw:
		if ln: return SMALL_ISLAND_TOP
		return SMALL_ISLAND_BOTTOM
	# Big island corners
	if ln and lw: return ISLAND_GR_NW
	if ln and le: return ISLAND_GR_NE
	if ls and lw: return ISLAND_GR_SW
	if ls and le: return ISLAND_GR_SE
	# Single-edge tiles — island-specific edge variants
	if ls: return _variant(ISLAND_EDGE_BOTTOM, gx, gy)
	if ln: return _variant(ISLAND_EDGE_TOP, gx, gy)
	if lw: return _variant(ISLAND_EDGE_LEFT, gx, gy)
	if le: return _variant(ISLAND_EDGE_RIGHT, gx, gy)
	return CENTER

# ── Lava selection ──

func _select_lava(gx: int, gy: int) -> Vector2i:
	# Outer border
	if gx == _left - 1 and gy == _top - 1: return LAVA_CORNER_NW
	if gx == _right + 1 and gy == _top - 1: return LAVA_CORNER_NE
	if gx == _left - 1 and gy == _bottom + 1: return LAVA_CORNER_SW
	if gx == _right + 1 and gy == _bottom + 1: return LAVA_CORNER_SE
	if gx == _left and gy == _top - 1: return LAVA_TRANS_TOP_LEFT
	if gx == _right and gy == _top - 1: return LAVA_TRANS_TOP_RIGHT
	if gx == _left and gy == _bottom + 1: return LAVA_TRANS_BOTTOM_LEFT
	if gx == _right and gy == _bottom + 1: return LAVA_TRANS_BOTTOM_RIGHT
	if gx == _left - 1 and gy == _top: return LAVA_TRANS_LEFT_TOP
	if gx == _left - 1 and gy == _bottom: return LAVA_TRANS_LEFT_BOTTOM
	if gx == _right + 1 and gy == _top: return LAVA_TRANS_RIGHT_TOP
	if gx == _right + 1 and gy == _bottom: return LAVA_TRANS_RIGHT_BOTTOM
	if gx == _left - 1 and gy > _top and gy < _bottom: return _variant(LAVA_EDGE_LEFT, gx, gy)
	if gx == _right + 1 and gy > _top and gy < _bottom: return _variant(LAVA_EDGE_RIGHT, gx, gy)
	if gy == _top - 1 and gx > _left and gx < _right: return _variant(LAVA_EDGE_TOP, gx, gy)
	if gy == _bottom + 1 and gx > _left and gx < _right: return _variant(LAVA_EDGE_BOTTOM, gx, gy)

	# Pool lava
	if gx >= _left and gx <= _right and gy >= _top and gy <= _bottom:
		var fn: bool = _grid.is_floor(gx, gy - 1)
		var fs: bool = _grid.is_floor(gx, gy + 1)
		var fe: bool = _grid.is_floor(gx + 1, gy)
		var fw: bool = _grid.is_floor(gx - 1, gy)
		if fn and fw: return POOL_LAVA_NW
		if fn and fe: return POOL_LAVA_NE
		if fs and fw: return POOL_LAVA_SW
		if fs and fe: return POOL_LAVA_SE
		if fn: return _variant(POOL_LAVA_TOP, gx, gy)
		if fs: return _variant(POOL_LAVA_BOTTOM, gx, gy)
		if fw: return _variant(POOL_LAVA_LEFT, gx, gy)
		if fe: return _variant(POOL_LAVA_RIGHT, gx, gy)
		return DEEP_LAVA

	# Island lava (lava adjacent to island ground)
	var ign: bool = _is_island(gx, gy - 1)
	var igs: bool = _is_island(gx, gy + 1)
	var ige: bool = _is_island(gx + 1, gy)
	var igw: bool = _is_island(gx - 1, gy)
	# Diagonal-only corners (no cardinal island ground)
	if not ign and not igs and not ige and not igw:
		if _is_island(gx + 1, gy + 1):
			if _is_narrow_island(gx + 1, gy + 1): return SMALL_LAVA_NW
			return ISLAND_LAVA_NW
		if _is_island(gx - 1, gy + 1):
			if _is_narrow_island(gx - 1, gy + 1): return SMALL_LAVA_NE
			return ISLAND_LAVA_NE
		return DEEP_LAVA
	# Top edge (island ground below)
	if igs and not ige and not igw:
		if _is_narrow_island(gx, gy + 1): return SMALL_LAVA_TOP
		return _variant(ISLAND_LAVA_TOP, gx, gy)
	# Left edge (island ground to east)
	if ige and not igs and not ign:
		var narrow: bool = _is_narrow_island(gx + 1, gy)
		var se_ground: bool = _is_island(gx + 1, gy + 1)
		if narrow:
			if se_ground: return SMALL_LAVA_LEFT_UPPER
			return SMALL_LAVA_LEFT_LOWER
		if se_ground: return ISLAND_LAVA_LEFT_UPPER
		return ISLAND_LAVA_LEFT_LOWER
	# Right edge (island ground to west)
	if igw and not igs and not ign:
		var narrow: bool = _is_narrow_island(gx - 1, gy)
		var sw_ground: bool = _is_island(gx - 1, gy + 1)
		if narrow:
			if sw_ground: return SMALL_LAVA_RIGHT_UPPER
			return SMALL_LAVA_RIGHT_LOWER
		if sw_ground: return ISLAND_LAVA_RIGHT_UPPER
		return ISLAND_LAVA_RIGHT_LOWER
	# Top-left corner (island ground at S and E)
	if igs and ige:
		if _is_narrow_island(gx + 1, gy + 1): return SMALL_LAVA_NW
		return ISLAND_LAVA_NW
	# Top-right corner (island ground at S and W)
	if igs and igw:
		if _is_narrow_island(gx - 1, gy + 1): return SMALL_LAVA_NE
		return ISLAND_LAVA_NE

	return DEEP_LAVA

# ── Helpers ──

func _is_pool_lava(gx: int, gy: int) -> bool:
	if _grid.is_floor(gx, gy):
		return false
	return gx >= _left and gx <= _right and gy >= _top and gy <= _bottom

func _is_narrow_island(gx: int, gy: int) -> bool:
	return _is_island(gx, gy) and not _grid.is_floor(gx - 1, gy) and not _grid.is_floor(gx + 1, gy)

func _is_island(gx: int, gy: int) -> bool:
	if not _grid.is_floor(gx, gy):
		return false
	return gx < _left or gx > _right or gy < _top or gy > _bottom

func _variant(variants: Array[Vector2i], gx: int, gy: int) -> Vector2i:
	var hash_val: int = (gx * 73856093) ^ (gy * 19349663)
	var idx: int = absi(hash_val) % variants.size()
	return variants[idx]
