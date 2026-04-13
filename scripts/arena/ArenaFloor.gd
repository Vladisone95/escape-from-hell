extends Node2D

var _grid: RoomGrid
var _tileset: Texture2D
var _detail_textures: Array[Texture2D] = []
var _detail_rng: RandomNumberGenerator

# Atlas tile source rects (column, row) → pixel Rect2
const TILE_ATLAS: Dictionary = {
	"center": Vector2i(0, 0),
	"edge_n": Vector2i(1, 0),
	"edge_e": Vector2i(2, 0),
	"edge_s": Vector2i(3, 0),
	"edge_w": Vector2i(0, 1),
	"corner_nw": Vector2i(1, 1),
	"corner_ne": Vector2i(2, 1),
	"corner_sw": Vector2i(3, 1),
	"corner_se": Vector2i(0, 2),
	"inner_nw": Vector2i(1, 2),
	"inner_ne": Vector2i(2, 2),
	"inner_sw": Vector2i(3, 2),
	"inner_se": Vector2i(0, 3),
	"wall_top": Vector2i(1, 3),
}

func init(grid: RoomGrid) -> void:
	_grid = grid

func _ready() -> void:
	_tileset = load("res://assets/sprites/tiles/tileset.png")
	# Load floor detail textures if available
	var detail_paths: Array[String] = [
		"res://assets/sprites/objects/floor_details/crack_1.png",
		"res://assets/sprites/objects/floor_details/crack_2.png",
		"res://assets/sprites/objects/floor_details/crack_3.png",
		"res://assets/sprites/objects/floor_details/skull_small.png",
		"res://assets/sprites/objects/floor_details/blood_stain_1.png",
		"res://assets/sprites/objects/floor_details/blood_stain_2.png",
		"res://assets/sprites/objects/floor_details/small_rocks.png",
	]
	for p: String in detail_paths:
		if ResourceLoader.exists(p):
			_detail_textures.append(load(p))

func _draw() -> void:
	if _grid == null:
		return
	var ts: float = RoomGrid.CELL_SIZE
	var origin: Vector2 = _grid.get_origin()

	# Pass 1: draw floor tiles with autotile selection
	for gy: int in _grid.height:
		for gx: int in _grid.width:
			if not _grid.is_floor(gx, gy):
				continue
			var tile_name: String = _select_tile(gx, gy)
			var atlas_pos: Vector2i = TILE_ATLAS.get(tile_name, Vector2i(0, 0))
			var src: Rect2 = Rect2(atlas_pos.x * ts, atlas_pos.y * ts, ts, ts)
			var dst: Vector2 = Vector2(origin.x + gx * ts, origin.y + gy * ts)
			draw_texture_rect_region(_tileset, Rect2(dst, Vector2(ts, ts)), src)

	# Pass 2: floor details
	if _detail_textures.is_empty():
		_draw_procedural_details(origin, ts)
	else:
		_draw_sprite_details(origin, ts)

func _select_tile(gx: int, gy: int) -> String:
	var n: bool = _grid.is_floor(gx, gy - 1)
	var e: bool = _grid.is_floor(gx + 1, gy)
	var s: bool = _grid.is_floor(gx, gy + 1)
	var w: bool = _grid.is_floor(gx - 1, gy)

	# Cardinal edges
	if not n and not w and s and e: return "corner_nw"
	if not n and not e and s and w: return "corner_ne"
	if not s and not w and n and e: return "corner_sw"
	if not s and not e and n and w: return "corner_se"
	if not n and e and s and w: return "edge_n"
	if not s and e and n and w: return "edge_s"
	if not e and n and s and w: return "edge_e"
	if not w and n and s and e: return "edge_w"

	# All cardinal neighbors are floor — check diagonals for inner corners
	if n and e and s and w:
		var ne: bool = _grid.is_floor(gx + 1, gy - 1)
		var se: bool = _grid.is_floor(gx + 1, gy + 1)
		var sw: bool = _grid.is_floor(gx - 1, gy + 1)
		var nw: bool = _grid.is_floor(gx - 1, gy - 1)
		if not nw: return "inner_nw"
		if not ne: return "inner_ne"
		if not sw: return "inner_sw"
		if not se: return "inner_se"

	return "center"

func _draw_procedural_details(origin: Vector2, ts: float) -> void:
	# Fallback: draw cracks and small details procedurally
	_detail_rng = RandomNumberGenerator.new()
	_detail_rng.seed = 42 + int(origin.x * 7 + origin.y * 13)
	for gy: int in _grid.height:
		for gx: int in _grid.width:
			if not _grid.is_floor(gx, gy):
				continue
			if _detail_rng.randf() > 0.15:
				continue
			var base: Vector2 = Vector2(origin.x + gx * ts, origin.y + gy * ts)
			var ox: float = _detail_rng.randf_range(4, ts - 4)
			var oy: float = _detail_rng.randf_range(4, ts - 4)
			var detail_type: int = _detail_rng.randi_range(0, 3)
			match detail_type:
				0:  # crack
					var start: Vector2 = base + Vector2(ox, oy)
					var end_pt: Vector2 = start + Vector2(_detail_rng.randf_range(-12, 12), _detail_rng.randf_range(-12, 12))
					draw_line(start, end_pt, Color(0.12, 0.04, 0.02, 0.5), 1.0)
				1:  # blood stain
					draw_circle(base + Vector2(ox, oy), _detail_rng.randf_range(2, 4), Color(0.3, 0.02, 0.0, 0.3))
				2:  # small rock
					draw_circle(base + Vector2(ox, oy), _detail_rng.randf_range(1, 2.5), Color(0.15, 0.07, 0.05, 0.6))
				3:  # scratch marks
					var s: Vector2 = base + Vector2(ox, oy)
					draw_line(s, s + Vector2(_detail_rng.randf_range(-6, 6), _detail_rng.randf_range(-6, 6)), Color(0.1, 0.03, 0.02, 0.35), 1.0)

func _draw_sprite_details(origin: Vector2, ts: float) -> void:
	_detail_rng = RandomNumberGenerator.new()
	_detail_rng.seed = 42 + int(origin.x * 7 + origin.y * 13)
	for gy: int in _grid.height:
		for gx: int in _grid.width:
			if not _grid.is_floor(gx, gy):
				continue
			if _detail_rng.randf() > 0.18:
				continue
			var base: Vector2 = Vector2(origin.x + gx * ts, origin.y + gy * ts)
			var ox: float = _detail_rng.randf_range(2, ts - 18)
			var oy: float = _detail_rng.randf_range(2, ts - 18)
			var tex: Texture2D = _detail_textures[_detail_rng.randi_range(0, _detail_textures.size() - 1)]
			draw_texture(tex, base + Vector2(ox, oy), Color(1, 1, 1, 0.7))
