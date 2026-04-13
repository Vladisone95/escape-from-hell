extends GdUnitTestSuite

const EnemySprite: GDScript = preload("res://scripts/arena/EnemyArenaSprite.gd")

func _make_enemy(etype: int) -> Node2D:
	var sprite: Node2D = auto_free(Node2D.new())
	sprite.set_script(EnemySprite)
	sprite.etype = etype
	add_child(sprite)
	return sprite

func test_demon_spriteframes_loaded() -> void:
	var s: Node2D = _make_enemy(0)  # DEMON
	assert_object(s._anim.sprite_frames).is_not_null()

func test_imp_spriteframes_loaded() -> void:
	var s: Node2D = _make_enemy(1)  # IMP
	assert_object(s._anim.sprite_frames).is_not_null()

func test_hellhound_spriteframes_loaded() -> void:
	var s: Node2D = _make_enemy(2)  # HELLHOUND
	assert_object(s._anim.sprite_frames).is_not_null()

func test_warlock_spriteframes_loaded() -> void:
	var s: Node2D = _make_enemy(3)  # WARLOCK
	assert_object(s._anim.sprite_frames).is_not_null()

func test_abomination_spriteframes_loaded() -> void:
	var s: Node2D = _make_enemy(4)  # ABOMINATION
	assert_object(s._anim.sprite_frames).is_not_null()

func test_demon_has_idle_animations() -> void:
	var s: Node2D = _make_enemy(0)
	var sf: SpriteFrames = s._anim.sprite_frames
	assert_bool(sf.has_animation("idle_down")).is_true()
	assert_bool(sf.has_animation("idle_up")).is_true()
	assert_bool(sf.has_animation("idle_right")).is_true()

func test_warlock_has_cast_animations() -> void:
	var s: Node2D = _make_enemy(3)
	var sf: SpriteFrames = s._anim.sprite_frames
	assert_bool(sf.has_animation("cast_down")).is_true()
	assert_bool(sf.has_animation("cast_up")).is_true()
	assert_bool(sf.has_animation("cast_right")).is_true()

func test_enemy_api_methods() -> void:
	var s: Node2D = _make_enemy(0)
	assert_bool(s.has_method("start_idle")).is_true()
	assert_bool(s.has_method("start_walk")).is_true()
	assert_bool(s.has_method("play_hurt")).is_true()
	assert_bool(s.has_method("play_die")).is_true()
	assert_bool(s.has_method("play_cast")).is_true()
	assert_bool(s.has_method("set_facing_from_vec")).is_true()
