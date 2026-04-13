extends "res://scripts/arena/SpriteBase.gd"

enum EType { DEMON, IMP, HELLHOUND, WARLOCK, ABOMINATION, VANITY_BOSS }

var etype: int = EType.DEMON

const SPRITEFRAMES_PATHS := {
	EType.DEMON: "res://assets/spriteframes/demon.tres",
	EType.IMP: "res://assets/spriteframes/imp.tres",
	EType.HELLHOUND: "res://assets/spriteframes/hellhound.tres",
	EType.WARLOCK: "res://assets/spriteframes/warlock.tres",
	EType.ABOMINATION: "res://assets/spriteframes/abomination.tres",
}

func _get_spriteframes_path() -> String:
	if etype in SPRITEFRAMES_PATHS:
		return SPRITEFRAMES_PATHS[etype]
	return ""

func set_facing_from_vec(dir: Vector2) -> void:
	## Enemy facing uses simple axis dominance (no hysteresis).
	if abs(dir.x) >= abs(dir.y):
		facing = Facing.RIGHT if dir.x > 0 else Facing.LEFT
	else:
		facing = Facing.DOWN if dir.y > 0 else Facing.UP
	if _is_walking:
		_play_anim("walk")
	else:
		_play_anim("idle")
