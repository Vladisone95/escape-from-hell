extends GdUnitTestSuite

const SpriteBase: GDScript = preload("res://scripts/arena/SpriteBase.gd")

var _sprite: Node2D

func before_test() -> void:
	_sprite = auto_free(Node2D.new())
	_sprite.set_script(SpriteBase)
	add_child(_sprite)

func test_initial_facing_is_down() -> void:
	assert_int(_sprite.facing).is_equal(0)  # Facing.DOWN

func test_is_walking_starts_false() -> void:
	assert_bool(_sprite._is_walking).is_false()

func test_start_walk_sets_walking() -> void:
	_sprite.start_walk()
	assert_bool(_sprite._is_walking).is_true()

func test_start_idle_clears_walking() -> void:
	_sprite.start_walk()
	_sprite.start_idle()
	assert_bool(_sprite._is_walking).is_false()

func test_set_facing_from_vec_right() -> void:
	_sprite.set_facing_from_vec(Vector2(1, 0))
	assert_int(_sprite.facing).is_equal(3)  # Facing.RIGHT

func test_set_facing_from_vec_left() -> void:
	_sprite.set_facing_from_vec(Vector2(-1, 0))
	assert_int(_sprite.facing).is_equal(2)  # Facing.LEFT

func test_set_facing_from_vec_up() -> void:
	_sprite.set_facing_from_vec(Vector2(0, -1))
	assert_int(_sprite.facing).is_equal(1)  # Facing.UP

func test_set_facing_from_vec_down() -> void:
	_sprite.set_facing_from_vec(Vector2(0, 1))
	assert_int(_sprite.facing).is_equal(0)  # Facing.DOWN

func test_anim_child_exists() -> void:
	assert_object(_sprite._anim).is_not_null()
	assert_bool(_sprite._anim is AnimatedSprite2D).is_true()
