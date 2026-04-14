extends Node2D

var _sprite: Sprite2D
var obstacle_type: String = "boulder"

const OBSTACLE_TEXTURES: Dictionary = {
	"boulder": "res://assets/sprites/objects/obstacle/boulder.png",
	"pillar": "res://assets/sprites/objects/obstacle/pillar.png",
	"bone_pile": "res://assets/sprites/objects/obstacle/bone_pile.png",
	"skull_pile": "res://assets/sprites/objects/obstacle/skull_pile.png",
}

# Art pack obstacles from decorative_props.png (atlas regions)
const ART_OBSTACLE_REGIONS: Dictionary = {
	"large_rock_1": Rect2(7, 6, 51, 218),
	"large_rock_2": Rect2(228, 8, 60, 216),
	"rock_cluster_1": Rect2(64, 0, 160, 224),
	"rock_cluster_2": Rect2(290, 3, 125, 238),
	"rock_formation": Rect2(417, 1, 90, 221),
	"dead_tree_1": Rect2(7, 259, 65, 151),
	"dead_tree_2": Rect2(76, 266, 44, 132),
	"tall_rock": Rect2(448, 247, 64, 104),
}

# Props from other_props.png (atlas regions)
const OTHER_PROP_REGIONS: Dictionary = {
	"well_large": Rect2(4, 0, 24, 64),
	"well_medium": Rect2(36, 14, 24, 50),
	"cauldron_large": Rect2(68, 6, 24, 58),
	"cauldron_medium": Rect2(100, 16, 24, 48),
}

# Scale factors per art obstacle to fit gameplay (collision radius ~40-60px)
const ART_OBSTACLE_SCALE: Dictionary = {
	"large_rock_1": 0.4,
	"large_rock_2": 0.4,
	"rock_cluster_1": 0.35,
	"rock_cluster_2": 0.35,
	"rock_formation": 0.4,
	"dead_tree_1": 0.5,
	"dead_tree_2": 0.5,
	"tall_rock": 0.5,
	"well_large": 1.0,
	"well_medium": 1.0,
	"cauldron_large": 1.0,
	"cauldron_medium": 1.0,
}

var _art_atlas: Texture2D

func _ready() -> void:
	_sprite = Sprite2D.new()

	if ART_OBSTACLE_REGIONS.has(obstacle_type):
		var atlas: Texture2D = load("res://assets/art/decorative_props.png")
		var atlas_tex: AtlasTexture = AtlasTexture.new()
		atlas_tex.atlas = atlas
		atlas_tex.region = ART_OBSTACLE_REGIONS[obstacle_type]
		_sprite.texture = atlas_tex
		var s: float = ART_OBSTACLE_SCALE.get(obstacle_type, 0.4)
		_sprite.scale = Vector2(s, s)
	elif OTHER_PROP_REGIONS.has(obstacle_type):
		var atlas: Texture2D = load("res://assets/art/other_props.png")
		var atlas_tex: AtlasTexture = AtlasTexture.new()
		atlas_tex.atlas = atlas
		atlas_tex.region = OTHER_PROP_REGIONS[obstacle_type]
		_sprite.texture = atlas_tex
		var s: float = ART_OBSTACLE_SCALE.get(obstacle_type, 1.0)
		_sprite.scale = Vector2(s, s)
	else:
		var path: String = OBSTACLE_TEXTURES.get(obstacle_type, OBSTACLE_TEXTURES["boulder"])
		if ResourceLoader.exists(path):
			_sprite.texture = load(path)
		else:
			_sprite.texture = load("res://assets/sprites/objects/obstacle/obstacle.png")

	add_child(_sprite)
