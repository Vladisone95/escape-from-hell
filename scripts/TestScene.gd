extends Node2D

var _player: CharacterBody2D
var _camera: Camera2D

func _ready() -> void:
	GameData.reset()
	_build_tilemap()
	_spawn_player()
	_add_back_button()

func _build_tilemap() -> void:
	var tileset: TileSet = load("res://assets/tilesets/main_tileset.tres")
	var layer: TileMapLayer = TileMapLayer.new()
	layer.tile_set = tileset

	# 4x4 ground only — direct placement to verify grid
	for x in range(-2, 2):
		for y in range(-2, 2):
			layer.set_cell(Vector2i(x, y), 0, Vector2i(10, 0))
	add_child(layer)

func _spawn_player() -> void:
	_player = CharacterBody2D.new()
	_player.set_script(load("res://scripts/arena/PlayerBody.gd"))
	_player.position = Vector2(-32, -32)
	add_child(_player)

	_camera = Camera2D.new()
	_camera.zoom = Vector2(1.0, 1.0)
	_player.add_child(_camera)

func _add_back_button() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)

	var btn: Button = Button.new()
	btn.text = "BACK TO MENU"
	btn.position = Vector2(20, 20)
	btn.custom_minimum_size = Vector2(180, 50)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	canvas.add_child(btn)
