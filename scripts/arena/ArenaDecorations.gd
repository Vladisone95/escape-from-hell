extends Node2D

var _grid: RoomGrid

const DECORATION_TEXTURES: Array[String] = [
	"res://assets/sprites/objects/decorations/skull_pile_decor.png",
	"res://assets/sprites/objects/decorations/bone_pile_decor.png",
	"res://assets/sprites/objects/decorations/broken_weapon.png",
	"res://assets/sprites/objects/decorations/fallen_shield.png",
]

func init(grid: RoomGrid, seed_val: int) -> void:
	_grid = grid
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val + 5555

	var floor_cells: Array[Vector2i] = grid.get_floor_positions()
	if floor_cells.is_empty():
		return

	# Load available textures
	var textures: Array[Texture2D] = []
	for path: String in DECORATION_TEXTURES:
		if ResourceLoader.exists(path):
			textures.append(load(path))
	if textures.is_empty():
		return

	var center_x: int = grid.width / 2
	var center_y: int = grid.height / 2
	var count: int = rng.randi_range(5, 10)

	for i: int in count:
		# Pick a random floor cell, not too close to center
		var cell: Vector2i = floor_cells[rng.randi_range(0, floor_cells.size() - 1)]
		if absi(cell.x - center_x) < 3 and absi(cell.y - center_y) < 3:
			continue
		# Skip edge tiles
		if not grid.is_floor(cell.x - 1, cell.y) or not grid.is_floor(cell.x + 1, cell.y):
			continue
		if not grid.is_floor(cell.x, cell.y - 1) or not grid.is_floor(cell.x, cell.y + 1):
			continue

		var world_pos: Vector2 = grid.grid_to_world(cell.x, cell.y)
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = textures[rng.randi_range(0, textures.size() - 1)]
		sprite.position = world_pos + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))
		sprite.rotation = rng.randf_range(-0.15, 0.15)
		sprite.modulate = Color(1, 1, 1, rng.randf_range(0.5, 0.8))
		sprite.z_index = -1  # behind characters
		add_child(sprite)
