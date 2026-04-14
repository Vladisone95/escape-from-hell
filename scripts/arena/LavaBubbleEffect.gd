extends Node2D

const OCCUPANCY: float = 0.10  # fraction of eligible lava tiles that get a bubble
const MIN_SHORE_DISTANCE: int = 3  # minimum tile distance from any floor tile
const FRAME_SIZE: int = 32
const COLS: int = 4  # frames per row in the spritesheet
const FRAME_COUNT: int = 9
const ANIM_FPS: float = 4.0

var _grid: RoomGrid

func init(grid: RoomGrid, seed_val: int) -> void:
	_grid = grid
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_val + 3333

	var tex1: Texture2D = null
	var tex2: Texture2D = null
	if ResourceLoader.exists("res://assets/art/anim/volc_bubble1.png"):
		tex1 = load("res://assets/art/anim/volc_bubble1.png")
	if ResourceLoader.exists("res://assets/art/anim/volc_bubble2.png"):
		tex2 = load("res://assets/art/anim/volc_bubble2.png")
	if tex1 == null and tex2 == null:
		return

	var frames1: SpriteFrames = _build_frames("bubble", tex1) if tex1 != null else null
	var frames2: SpriteFrames = _build_frames("bubble", tex2) if tex2 != null else null

	var deep_lava: Array[Vector2i] = _get_deep_lava_cells()
	if deep_lava.is_empty():
		return

	var bubble_count: int = 0
	for i: int in deep_lava.size():
		if rng.randf() >= OCCUPANCY:
			continue
		var cell: Vector2i = deep_lava[i]
		var world_pos: Vector2 = _grid.grid_to_world(cell.x, cell.y)

		var frames: SpriteFrames = frames1 if rng.randf() < 0.5 else frames2
		if frames == null:
			frames = frames1 if frames1 != null else frames2

		var anim: AnimatedSprite2D = AnimatedSprite2D.new()
		anim.sprite_frames = frames
		anim.position = world_pos
		var s: float = rng.randf_range(0.75, 1.5)
		anim.scale = Vector2(s, s)
		anim.z_index = 1
		anim.visible = false
		add_child(anim)

		# Stagger start for natural boiling effect
		var delay: float = rng.randf_range(0.0, 3.0)
		var start_frame: int = rng.randi_range(0, FRAME_COUNT - 1)
		get_tree().create_timer(delay).timeout.connect(_start_anim.bind(anim, start_frame))
		bubble_count += 1


func _start_anim(sprite: AnimatedSprite2D, frame: int) -> void:
	if is_instance_valid(sprite):
		sprite.visible = true
		sprite.frame = frame
		sprite.play("bubble")

func _build_frames(anim_name: String, sheet: Texture2D) -> SpriteFrames:
	var sf: SpriteFrames = SpriteFrames.new()
	sf.add_animation(anim_name)
	sf.set_animation_loop(anim_name, true)
	sf.set_animation_speed(anim_name, ANIM_FPS)
	for f: int in FRAME_COUNT:
		var col: int = f % COLS
		var row: int = f / COLS
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
		sf.add_frame(anim_name, atlas)
	return sf

func _get_deep_lava_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for gy: int in _grid.height:
		for gx: int in _grid.width:
			if _grid.is_floor(gx, gy):
				continue
			if _is_deep_lava(gx, gy):
				result.append(Vector2i(gx, gy))
	return result

func _is_deep_lava(gx: int, gy: int) -> bool:
	for dy: int in range(-MIN_SHORE_DISTANCE, MIN_SHORE_DISTANCE + 1):
		for dx: int in range(-MIN_SHORE_DISTANCE, MIN_SHORE_DISTANCE + 1):
			if _grid.is_floor(gx + dx, gy + dy):
				return false
	return true
