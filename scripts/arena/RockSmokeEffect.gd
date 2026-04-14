extends Node2D

var _grid: RoomGrid

func init(grid: RoomGrid, seed_val: int) -> void:
	_grid = grid
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val + 4444

	# Load rocksmoke spritesheets (each 128x64, 4 frames at 32x64)
	var smoke_textures: Array[Texture2D] = []
	for i: int in range(1, 5):
		var path: String = "res://assets/art/anim/rocksmoke%d.png" % i
		if ResourceLoader.exists(path):
			smoke_textures.append(load(path))
	if smoke_textures.is_empty():
		return

	var boundary_cells: Array[Vector2i] = grid.get_lava_boundary_cells()
	if boundary_cells.is_empty():
		return

	var count: int = mini(6, maxi(2, boundary_cells.size() / 12))
	for i: int in count:
		var cell: Vector2i = boundary_cells[rng.randi_range(0, boundary_cells.size() - 1)]
		var world_pos: Vector2 = grid.grid_to_world(cell.x, cell.y)
		var smoke_tex: Texture2D = smoke_textures[rng.randi_range(0, smoke_textures.size() - 1)]

		# Create SpriteFrames with 4 atlas regions from the spritesheet
		var frames: SpriteFrames = SpriteFrames.new()
		frames.add_animation("smoke")
		frames.set_animation_loop("smoke", true)
		frames.set_animation_speed("smoke", 3.0)
		for f: int in 4:
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = smoke_tex
			atlas.region = Rect2(f * 32, 0, 32, 64)
			frames.add_frame("smoke", atlas)

		var anim_sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		anim_sprite.sprite_frames = frames
		anim_sprite.position = world_pos + Vector2(rng.randf_range(-8, 8), rng.randf_range(-20, -4))
		anim_sprite.scale = Vector2(0.8, 0.8)
		anim_sprite.modulate = Color(1, 1, 1, rng.randf_range(0.4, 0.7))
		anim_sprite.z_index = 2
		add_child(anim_sprite)
		anim_sprite.play("smoke")
