extends "res://scripts/arena/SpriteBase.gd"

func _get_spriteframes_path() -> String:
	if GameData.player_weapon_type == GameData.WeaponType.RANGED:
		return "res://assets/spriteframes/player_staff.tres"
	return "res://assets/spriteframes/player.tres"
