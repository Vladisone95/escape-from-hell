extends TileMapLayer
class_name ArenaFloorTileMap

const SOURCE_ID: int = 1
const LAVA_ATLAS: Vector2i = Vector2i(3, 4)

var _grid: RoomGrid

func populate(grid: RoomGrid) -> void:
	_grid = grid
	clear()

	var ground_cells: Array[Vector2i] = []

	for gy: int in grid.height:
		for gx: int in grid.width:
			var coord: Vector2i = Vector2i(gx, gy)
			if grid.is_floor(gx, gy):
				ground_cells.append(coord)
			else:
				set_cell(coord, SOURCE_ID, LAVA_ATLAS)

	set_cells_terrain_connect(ground_cells, 0, 1)
