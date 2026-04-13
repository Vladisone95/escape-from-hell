extends Node2D

var _grid: RoomGrid
var _shader_material: ShaderMaterial
var _noise_tex: Texture2D

func init(grid: RoomGrid) -> void:
	_grid = grid

func _ready() -> void:
	_noise_tex = load("res://assets/sprites/tiles/lava_noise.png")
	var shader: Shader = load("res://assets/shaders/lava.gdshader")
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader
	_shader_material.set_shader_parameter("noise_tex", _noise_tex)
	material = _shader_material

func _draw() -> void:
	if _grid == null:
		return
	var origin: Vector2 = _grid.get_origin()
	var total_w: float = _grid.width * RoomGrid.CELL_SIZE
	var total_h: float = _grid.height * RoomGrid.CELL_SIZE
	# Draw a single rect covering the entire grid area — shader renders lava
	# Floor tiles drawn on top by ArenaFloor will occlude lava on floor cells
	draw_rect(Rect2(origin.x, origin.y, total_w, total_h), Color.WHITE)
