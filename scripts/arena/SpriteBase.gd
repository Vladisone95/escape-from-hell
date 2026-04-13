extends Node2D
## Base class for all sprite-backed character nodes.
## Replaces procedural _draw() rendering with AnimatedSprite2D + SpriteFrames.

enum Facing { DOWN, UP, LEFT, RIGHT }

var facing: int = Facing.DOWN
var _is_walking: bool = false
var _anim: AnimatedSprite2D

## Override in subclass to return the SpriteFrames resource path.
func _get_spriteframes_path() -> String:
	return ""

func _ready() -> void:
	_anim = AnimatedSprite2D.new()
	var path: String = _get_spriteframes_path()
	if path != "":
		_anim.sprite_frames = load(path)
	add_child(_anim)

func _get_dir_suffix() -> String:
	match facing:
		Facing.DOWN: return "down"
		Facing.UP: return "up"
		Facing.LEFT: return "right"  # flip_h used for left
		Facing.RIGHT: return "right"
		_: return "down"

func _apply_flip() -> void:
	_anim.flip_h = (facing == Facing.LEFT)

func _play_anim(action: String, _looping: bool = true) -> void:
	var anim_name: String = action + "_" + _get_dir_suffix()
	if _anim.sprite_frames and _anim.sprite_frames.has_animation(anim_name):
		_anim.play(anim_name)
	_apply_flip()

func start_idle() -> void:
	_stop_walk()
	_play_anim("idle")

func start_walk() -> void:
	if _is_walking:
		return
	_is_walking = true
	_play_anim("walk")

func _stop_walk() -> void:
	_is_walking = false

func play_attack() -> void:
	_play_anim("attack", false)
	if _anim.sprite_frames and _anim.sprite_frames.has_animation("attack_" + _get_dir_suffix()):
		await _anim.animation_finished
	else:
		# Fallback: wait the expected attack duration
		await get_tree().create_timer(0.3).timeout

func play_hurt() -> void:
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_anim, "self_modulate", Color(1.0, 0.3, 0.25), 0.06)
	await tw.finished
	var tw2: Tween = create_tween()
	tw2.tween_property(_anim, "self_modulate", Color.WHITE, 0.2)
	await tw2.finished

func play_die() -> void:
	_stop_walk()
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(self, "modulate", Color(1.0, 0.15, 0.1, 0.0), 0.65)
	tw.tween_property(_anim, "self_modulate", Color(1.0, 0.3, 0.25), 0.15)
	await tw.finished
	visible = false

func play_cast() -> void:
	_play_anim("cast", false)
	if _anim.sprite_frames and _anim.sprite_frames.has_animation("cast_" + _get_dir_suffix()):
		await _anim.animation_finished
	else:
		await get_tree().create_timer(0.46).timeout

func set_facing_from_vec(dir: Vector2) -> void:
	var ax: float = absf(dir.x)
	var ay: float = absf(dir.y)
	var is_currently_horizontal: bool = (facing == Facing.LEFT or facing == Facing.RIGHT)
	var threshold: float = 1.3
	if is_currently_horizontal:
		if ay > ax * threshold:
			facing = Facing.DOWN if dir.y > 0 else Facing.UP
		elif ax > 0.01:
			facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		if ax > ay * threshold:
			facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
		elif ay > 0.01:
			facing = Facing.DOWN if dir.y > 0 else Facing.UP
	# Update current animation direction
	if _is_walking:
		_play_anim("walk")
	else:
		_play_anim("idle")
