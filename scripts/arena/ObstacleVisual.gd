extends Node2D

var _sprite: Sprite2D
var obstacle_type: String = "boulder"

const OBSTACLE_TEXTURES: Dictionary = {
	"boulder": "res://assets/sprites/objects/obstacle/boulder.png",
	"pillar": "res://assets/sprites/objects/obstacle/pillar.png",
	"bone_pile": "res://assets/sprites/objects/obstacle/bone_pile.png",
	"skull_pile": "res://assets/sprites/objects/obstacle/skull_pile.png",
}

func _ready() -> void:
	_sprite = Sprite2D.new()
	var path: String = OBSTACLE_TEXTURES.get(obstacle_type, OBSTACLE_TEXTURES["boulder"])
	if ResourceLoader.exists(path):
		_sprite.texture = load(path)
	else:
		_sprite.texture = load("res://assets/sprites/objects/obstacle/obstacle.png")
	add_child(_sprite)
