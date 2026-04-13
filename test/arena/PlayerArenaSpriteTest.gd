extends GdUnitTestSuite

const PlayerSprite: GDScript = preload("res://scripts/arena/PlayerArenaSprite.gd")

var _sprite: Node2D

func before_test() -> void:
	_sprite = auto_free(Node2D.new())
	_sprite.set_script(PlayerSprite)
	add_child(_sprite)

func test_spriteframes_loaded() -> void:
	assert_object(_sprite._anim.sprite_frames).is_not_null()

func test_has_idle_animations() -> void:
	var sf: SpriteFrames = _sprite._anim.sprite_frames
	assert_bool(sf.has_animation("idle_down")).is_true()
	assert_bool(sf.has_animation("idle_up")).is_true()
	assert_bool(sf.has_animation("idle_right")).is_true()

func test_has_walk_animations() -> void:
	var sf: SpriteFrames = _sprite._anim.sprite_frames
	assert_bool(sf.has_animation("walk_down")).is_true()
	assert_bool(sf.has_animation("walk_up")).is_true()
	assert_bool(sf.has_animation("walk_right")).is_true()

func test_has_attack_animations() -> void:
	var sf: SpriteFrames = _sprite._anim.sprite_frames
	assert_bool(sf.has_animation("attack_down")).is_true()
	assert_bool(sf.has_animation("attack_up")).is_true()
	assert_bool(sf.has_animation("attack_right")).is_true()

func test_has_die_animation() -> void:
	var sf: SpriteFrames = _sprite._anim.sprite_frames
	assert_bool(sf.has_animation("die_down")).is_true()

func test_api_methods_exist() -> void:
	assert_bool(_sprite.has_method("start_idle")).is_true()
	assert_bool(_sprite.has_method("start_walk")).is_true()
	assert_bool(_sprite.has_method("play_attack")).is_true()
	assert_bool(_sprite.has_method("play_hurt")).is_true()
	assert_bool(_sprite.has_method("play_die")).is_true()
	assert_bool(_sprite.has_method("set_facing_from_vec")).is_true()
