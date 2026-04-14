extends Node2D

var _grid: RoomGrid

# Atlas regions from decorative_props.png (x, y, w, h)
const SMALL_PROP_REGIONS: Array[Dictionary] = [
	{"name": "bush_1", "rect": Rect2(0, 418, 32, 94)},
	{"name": "bush_2", "rect": Rect2(34, 416, 27, 94)},
	{"name": "bush_3", "rect": Rect2(66, 416, 26, 96)},
	{"name": "bush_4", "rect": Rect2(98, 416, 28, 93)},
	{"name": "bush_5", "rect": Rect2(132, 422, 25, 84)},
	{"name": "bush_6", "rect": Rect2(178, 418, 32, 94)},
	{"name": "bush_7", "rect": Rect2(240, 417, 27, 94)},
	{"name": "bush_8", "rect": Rect2(309, 416, 26, 96)},
	{"name": "small_plant_1", "rect": Rect2(231, 300, 25, 108)},
	{"name": "small_plant_2", "rect": Rect2(287, 305, 22, 98)},
	{"name": "small_plant_3", "rect": Rect2(319, 300, 20, 106)},
	{"name": "small_plant_4", "rect": Rect2(355, 298, 16, 106)},
]

var _props_atlas: Texture2D

func init(grid: RoomGrid, seed_val: int) -> void:
	_grid = grid
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val + 5555

	var floor_cells: Array[Vector2i] = grid.get_floor_positions()
	if floor_cells.is_empty():
		return

	if not ResourceLoader.exists("res://assets/art/decorative_props.png"):
		return
	_props_atlas = load("res://assets/art/decorative_props.png")

	# Also load legacy decoration textures as fallback
	var legacy_textures: Array[Texture2D] = []
	var legacy_paths: Array[String] = [
		"res://assets/sprites/objects/decorations/skull_pile_decor.png",
		"res://assets/sprites/objects/decorations/bone_pile_decor.png",
		"res://assets/sprites/objects/decorations/broken_weapon.png",
		"res://assets/sprites/objects/decorations/fallen_shield.png",
	]
	for path: String in legacy_paths:
		if ResourceLoader.exists(path):
			legacy_textures.append(load(path))

	var center_x: int = grid.width / 2
	var center_y: int = grid.height / 2
	var count: int = rng.randi_range(8, 16)

	for i: int in count:
		var cell: Vector2i = floor_cells[rng.randi_range(0, floor_cells.size() - 1)]
		if absi(cell.x - center_x) < 3 and absi(cell.y - center_y) < 3:
			continue
		if not grid.is_floor(cell.x - 1, cell.y) or not grid.is_floor(cell.x + 1, cell.y):
			continue
		if not grid.is_floor(cell.x, cell.y - 1) or not grid.is_floor(cell.x, cell.y + 1):
			continue

		var world_pos: Vector2 = grid.grid_to_world(cell.x, cell.y)
		var sprite: Sprite2D = Sprite2D.new()

		# Mix art pack props with legacy decorations
		if rng.randf() < 0.7 or legacy_textures.is_empty():
			var prop: Dictionary = SMALL_PROP_REGIONS[rng.randi_range(0, SMALL_PROP_REGIONS.size() - 1)]
			var atlas_tex: AtlasTexture = AtlasTexture.new()
			atlas_tex.atlas = _props_atlas
			atlas_tex.region = prop["rect"]
			sprite.texture = atlas_tex
			sprite.scale = Vector2(0.5, 0.5)
		else:
			sprite.texture = legacy_textures[rng.randi_range(0, legacy_textures.size() - 1)]

		sprite.position = world_pos + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))
		sprite.rotation = rng.randf_range(-0.15, 0.15)
		sprite.modulate = Color(1, 1, 1, rng.randf_range(0.5, 0.8))
		sprite.z_index = -1
		add_child(sprite)
