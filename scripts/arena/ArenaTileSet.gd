extends RefCounted
class_name ArenaTileSet

static func create() -> TileSet:
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(32, 32)

	# Physics layer 0 = world (collision layer bit 0)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1 << 0)
	ts.set_physics_layer_collision_mask(0, 0)

	# Atlas source from tilemap-lava.png
	var tex: Texture2D = load("res://assets/art/tilemap-lava.png")
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(32, 32)

	# Register all tiles: outer border (0-7), pool (8-15), island (16-19 rows 0-5)
	for ty: int in 8:
		for tx: int in 16:
			source.create_tile(Vector2i(tx, ty))
	for ty: int in 6:
		for tx: int in range(16, 20):
			source.create_tile(Vector2i(tx, ty))

	var source_id: int = ts.add_source(source)

	# Collision polygon for impassable lava tiles
	var half: float = 16.0
	var collision_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)
	])

	# Outer border lava: cols 0,7 and rows 0,7
	var lava_positions: Dictionary = {}
	for i: int in 8:
		lava_positions[Vector2i(i, 0)] = true
		lava_positions[Vector2i(i, 7)] = true
		lava_positions[Vector2i(0, i)] = true
		lava_positions[Vector2i(7, i)] = true

	# Pool lava: corners + edges (cols 9-14, rows 1-6 lava area)
	# Corners
	for pos: Vector2i in [Vector2i(9, 1), Vector2i(14, 1), Vector2i(9, 6), Vector2i(14, 6)]:
		lava_positions[pos] = true
	# Top/bottom lava edges
	for tx: int in range(10, 14):
		lava_positions[Vector2i(tx, 1)] = true
		lava_positions[Vector2i(tx, 6)] = true
	# Left/right lava edges
	for ty: int in range(2, 6):
		lava_positions[Vector2i(9, ty)] = true
		lava_positions[Vector2i(14, ty)] = true
	# Pool interior lava
	for ty: int in range(2, 6):
		for tx: int in range(10, 14):
			lava_positions[Vector2i(tx, ty)] = true

	for pos: Vector2i in lava_positions:
		var tile_data: TileData = source.get_tile_data(pos, 0)
		tile_data.add_collision_polygon(0)
		tile_data.set_collision_polygon_points(0, 0, collision_poly)

	return ts
