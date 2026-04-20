extends Node2D

const OCCUPANCY: float = 0.20  # fraction of lava tiles that get a bubble
const MIN_POOL_BUBBLES: int = 2  # minimum bubbles per interior lava pool
const FRAME_SIZE: int = 32
const COLS: int = 4  # frames per row in the spritesheet
const FRAME_COUNT: int = 9
const ANIM_FPS: float = 4.0

var _grid: RoomGrid
var _frames1: SpriteFrames
var _frames2: SpriteFrames

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

	_frames1 = _build_frames("bubble", tex1) if tex1 != null else null
	_frames2 = _build_frames("bubble", tex2) if tex2 != null else null

	var lava_cells: Array[Vector2i] = _get_lava_cells()
	if lava_cells.is_empty():
		return

	var bubbled: Dictionary = {}  # Vector2i -> true
	for i: int in lava_cells.size():
		if rng.randf() >= OCCUPANCY:
			continue
		var cell: Vector2i = lava_cells[i]
		_spawn_bubble(cell, rng)
		bubbled[cell] = true

	# Ensure interior lava pools have at least MIN_POOL_BUBBLES
	var interior_pools: Array = _find_interior_pools()
	for pool: Array in interior_pools:
		var count: int = 0
		for cell: Vector2i in pool:
			if bubbled.has(cell):
				count += 1
		if count >= MIN_POOL_BUBBLES:
			continue
		var available: Array[Vector2i] = []
		for cell: Vector2i in pool:
			if not bubbled.has(cell):
				available.append(cell)
		while count < MIN_POOL_BUBBLES and not available.is_empty():
			var idx: int = rng.randi_range(0, available.size() - 1)
			var cell: Vector2i = available[idx]
			available.remove_at(idx)
			_spawn_bubble(cell, rng)
			bubbled[cell] = true
			count += 1


func _spawn_bubble(cell: Vector2i, rng: RandomNumberGenerator) -> void:
	var world_pos: Vector2 = _grid.grid_to_world(cell.x, cell.y)
	var frames: SpriteFrames = _frames1 if rng.randf() < 0.5 else _frames2
	if frames == null:
		frames = _frames1 if _frames1 != null else _frames2
	var anim: AnimatedSprite2D = AnimatedSprite2D.new()
	anim.sprite_frames = frames
	anim.position = world_pos
	var s: float = rng.randf_range(0.75, 1.5)
	anim.scale = Vector2(s, s)
	anim.z_index = 1
	anim.visible = false
	add_child(anim)
	var delay: float = rng.randf_range(0.0, 3.0)
	var start_frame: int = rng.randi_range(0, FRAME_COUNT - 1)
	get_tree().create_timer(delay).timeout.connect(_start_anim.bind(anim, start_frame))

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

func _get_lava_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for gy: int in _grid.height:
		for gx: int in _grid.width:
			if not _grid.is_floor(gx, gy):
				result.append(Vector2i(gx, gy))
	return result

func _find_interior_pools() -> Array:
	var w: int = _grid.width
	var h: int = _grid.height
	# Flood-fill from edges to mark exterior lava
	var exterior: Dictionary = {}
	var queue: Array[Vector2i] = []
	for gx: int in w:
		for gy: int in [0, h - 1]:
			if not _grid.is_floor(gx, gy) and not exterior.has(Vector2i(gx, gy)):
				exterior[Vector2i(gx, gy)] = true
				queue.append(Vector2i(gx, gy))
	for gy: int in h:
		for gx: int in [0, w - 1]:
			if not _grid.is_floor(gx, gy) and not exterior.has(Vector2i(gx, gy)):
				exterior[Vector2i(gx, gy)] = true
				queue.append(Vector2i(gx, gy))
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = cell + dir
			if n.x < 0 or n.x >= w or n.y < 0 or n.y >= h:
				continue
			if _grid.is_floor(n.x, n.y) or exterior.has(n):
				continue
			exterior[n] = true
			queue.append(n)

	# Collect interior lava cells
	var interior: Dictionary = {}
	for gy: int in h:
		for gx: int in w:
			var c: Vector2i = Vector2i(gx, gy)
			if not _grid.is_floor(gx, gy) and not exterior.has(c):
				interior[c] = true

	# Group into connected components
	var visited: Dictionary = {}
	var pools: Array = []
	for cell: Vector2i in interior:
		if visited.has(cell):
			continue
		var pool: Array[Vector2i] = []
		var bfs: Array[Vector2i] = [cell]
		visited[cell] = true
		while not bfs.is_empty():
			var cur: Vector2i = bfs.pop_back()
			pool.append(cur)
			for dir: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = cur + dir
				if interior.has(n) and not visited.has(n):
					visited[n] = true
					bfs.append(n)
		pools.append(pool)
	return pools
