extends Node
# ─────────────────────────────────────────────────────────────
# EnemyStats — single source of truth for enemy stats & waves
# Edit the dictionaries below to tune all enemies at once.
# ─────────────────────────────────────────────────────────────

# Maps human-readable name → EnemyArenaSprite.EType int
const TYPE_ID := {
	"DEMON": 0,
	"IMP": 1,
	"HELLHOUND": 2,
	"WARLOCK": 3,
	"ABOMINATION": 4,
	"VANITY_BOSS": 5,
}

# Base stats shared by every enemy of a given type.
# These values are constant across all waves.
const BASE := {
	"DEMON": {
		"health": 35,
		"attack": 9,
		"speed": 90,
		"armor": 2,
		"attack_range": 90.0,
		"attack_cooldown": 2.2,
	},
	"IMP": {
		"health": 18,
		"attack": 4,
		"speed": 180,
		"armor": 0,
		"attack_range": 70.0,
		"attack_cooldown": 1.3,
	},
	"HELLHOUND": {
		"health": 22,
		"attack": 7,
		"speed": 120,
		"armor": 1,
		"attack_range": 80.0,
		"attack_cooldown": 2.0,
	},
	"WARLOCK": {
		"health": 25,
		"attack": 11,
		"speed": 75,
		"armor": 1,
		"attack_range": 800.0,
		"attack_cooldown": 3.0,
		"projectile": {
			"speed": 300.0,
			"max_distance": 1000.0,
			"radius": 16.0,
			"color_core": Color(1.0, 0.45, 0.05, 0.85),
			"color_inner": Color(1.0, 0.7, 0.1, 0.95),
			"color_center": Color(1.0, 0.95, 0.7),
			"color_glow": Color(1.0, 0.3, 0.0, 0.5),
		},
	},
	"ABOMINATION": {
		"health": 70,
		"attack": 6,
		"speed": 50,
		"armor": 0,
		"attack_range": 600.0,
		"attack_cooldown": 4.5,
		"projectile": {
			"speed": 300.0,
			"max_distance": 700.0,
			"radius": 20.0,
			"color_core": Color(0.6, 0.1, 0.8, 0.85),
			"color_inner": Color(0.8, 0.3, 1.0, 0.95),
			"color_center": Color(1.0, 0.8, 1.0),
			"color_glow": Color(0.5, 0.0, 0.7, 0.5),
		},
	},
	"VANITY_BOSS": {
		"health": 1500,
		"attack": 12,
		"speed": 0,
		"armor": 0,
		"attack_range": 2000.0,
		"attack_cooldown": 2.0,
		"is_boss": true,
		"projectile": {
			"speed": 250.0,
			"max_distance": 2500.0,
			"radius": 18.0,
			"color_core": Color(0.95, 0.3, 0.5, 0.85),
			"color_inner": Color(1.0, 0.5, 0.7, 0.95),
			"color_center": Color(1.0, 0.85, 0.9),
			"color_glow": Color(0.9, 0.2, 0.4, 0.5),
		},
	},
}

# Encounter types for waves
enum Encounter { ENEMIES, SHOP, BOSS, SECRET }

# Wave types for Act Map display icons
enum WaveType { FIGHT = 0, BOSS = 1, SHOP = 2, SECRET = 3 }

# Wave definitions — array index 0 = wave 1, etc.
# Each wave is a dict with:
#   "encounter": Encounter type
#   "enemies": Array of { "type": "<NAME>", "count": N }
#   "boss_name": String (only for BOSS encounter)
const WAVES: Array = [
	# Wave 1
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "IMP", "count": 2 }, { "type": "WARLOCK", "count": 1 }] },
	# Wave 2
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "DEMON", "count": 1 }] },
	# Wave 3 (BOSS)
	{ "encounter": Encounter.BOSS, "wave_type": WaveType.BOSS, "boss_name": "DEMON OF VANITY", "enemies": [{ "type": "VANITY_BOSS", "count": 1 }] },
	# Wave 4
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "DEMON", "count": 1 }, { "type": "IMP", "count": 2 }] },
	# Wave 5
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "DEMON", "count": 2 }, { "type": "HELLHOUND", "count": 1 }, { "type": "ABOMINATION", "count": 1 }] },
	# Wave 6
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "DEMON", "count": 2 }, { "type": "IMP", "count": 2 }] },
	# Wave 7
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "IMP", "count": 3 }, { "type": "HELLHOUND", "count": 2 }] },
	# Wave 8
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "DEMON", "count": 2 }, { "type": "HELLHOUND", "count": 2 }] },
	# Wave 9
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "DEMON", "count": 3 }, { "type": "IMP", "count": 2 }, { "type": "HELLHOUND", "count": 1 }] },
	# Wave 10
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT, "enemies": [{ "type": "DEMON", "count": 4 }, { "type": "HELLHOUND", "count": 2 }, { "type": "IMP", "count": 2 }] },
]

## Act structure — add new dicts here for Act II, III, etc.
## first_wave and last_wave are 1-based inclusive.
const ACTS: Array = [
	{ "id": 1, "name": "Act I: Descent", "first_wave": 1, "last_wave": 10 }
]

# Per-wave stat overrides. Only the keys you specify here replace the base value.
# Example — to make wave 10 demons tougher and faster:
#   10: { "DEMON": { "health": 60, "speed": 100 } }
const WAVE_OVERRIDES := {
	# wave_number: { "TYPE": { "stat": value, ... }, ... }
}

# ── helpers (called by GameData / EnemyBody) ──────────────────

## Return the full stat dict for an enemy type on a given wave.
## Stats are constant across all waves; per-wave overrides still apply if set.
static func get_stats(type_name: String, wave: int) -> Dictionary:
	var stats: Dictionary = BASE[type_name].duplicate()

	# Apply per-wave overrides if any
	if WAVE_OVERRIDES.has(wave) and WAVE_OVERRIDES[wave].has(type_name):
		var ov: Dictionary = WAVE_OVERRIDES[wave][type_name]
		for key in ov:
			stats[key] = ov[key]

	return stats

## Return the wave info dict for a given wave number (1-based).
static func get_wave_info(wave: int) -> Dictionary:
	return WAVES[wave - 1]

## Return the enemy definition array for a given wave number (1-based).
static func get_wave_def(wave: int) -> Array:
	return WAVES[wave - 1]["enemies"]

## Return the encounter type for a given wave number (1-based).
static func get_encounter(wave: int) -> int:
	return WAVES[wave - 1]["encounter"]

## Return the boss name for a boss encounter wave, or empty string.
static func get_boss_name(wave: int) -> String:
	return WAVES[wave - 1].get("boss_name", "")

## Convert a type name to its int ID.
static func type_id(type_name: String) -> int:
	return TYPE_ID[type_name]

## Return the WaveType for a given wave number (1-based).
static func get_wave_type(wave: int) -> int:
	return WAVES[wave - 1].get("wave_type", WaveType.FIGHT)

## Return the act dict that contains the given wave number.
static func get_act_for_wave(wave: int) -> Dictionary:
	for act: Dictionary in ACTS:
		if wave >= act["first_wave"] and wave <= act["last_wave"]:
			return act
	return ACTS[0]
