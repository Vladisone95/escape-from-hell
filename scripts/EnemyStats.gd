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
		"speed": 60,
		"armor": 2,
		"attack_range": 40.0,
		"attack_cooldown": 2.2,
		"rarity": Rarity.COMMON,
		"base_difficulty": 15.0,
		"health_scale": 1.0,
		"damage_scale": 1.0,
	},
	"IMP": {
		"health": 18,
		"attack": 4,
		"speed": 120,
		"armor": 0,
		"attack_range": 30.0,
		"attack_cooldown": 1.3,
		"rarity": Rarity.COMMON,
		"base_difficulty": 10.0,
		"health_scale": 1.0,
		"damage_scale": 1.0,
	},
	"HELLHOUND": {
		"health": 22,
		"attack": 7,
		"speed": 80,
		"armor": 1,
		"attack_range": 35.0,
		"attack_cooldown": 2.0,
		"rarity": Rarity.COMMON,
		"base_difficulty": 25.0,
		"health_scale": 1.0,
		"damage_scale": 1.0,
	},
	"WARLOCK": {
		"health": 25,
		"attack": 11,
		"speed": 50,
		"armor": 1,
		"attack_range": 280.0,
		"attack_cooldown": 3.0,
		"rarity": Rarity.COMMON,
		"base_difficulty": 15.0,
		"health_scale": 1.0,
		"damage_scale": 1.0,
		"projectile": {
			"speed": 200.0,
			"max_distance": 1000.0,
			"radius": 6.0,
			"color_core": Color(1.0, 0.45, 0.05, 0.85),
		},
	},
	"ABOMINATION": {
		"health": 70,
		"attack": 6,
		"speed": 35,
		"armor": 0,
		"attack_range": 600.0,
		"attack_cooldown": 4.5,
		"rarity": Rarity.RARE,
		"base_difficulty": 50.0,
		"health_scale": 1.0,
		"damage_scale": 1.0,
		"projectile": {
			"speed": 200.0,
			"max_distance": 700.0,
			"radius": 6.0,
			"color_core": Color(0.6, 0.1, 0.8, 0.85),
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
		"rarity": Rarity.BOSS,
		"base_difficulty": 0.0,
		"health_scale": 1.0,
		"damage_scale": 1.0,
		"projectile": {
			"speed": 170.0,
			"max_distance": 2500.0,
			"radius": 6.0,
			"color_core": Color(0.95, 0.3, 0.5, 0.85),
		},
	},
}

# Encounter types for waves
enum Encounter { ENEMIES, SHOP, BOSS, SECRET }

# Wave types for Act Map display icons
enum WaveType { FIGHT = 0, BOSS = 1, SHOP = 2, SECRET = 3 }

# Enemy rarity tiers
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, BOSS }

# Wave definitions — array index 0 = wave 1, etc.
# FIGHT waves use difficulty-budget spawning (see generate_wave_enemies).
# BOSS waves spawn a single boss from "boss_type".
const WAVES: Array = [
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
	{ "encounter": Encounter.BOSS, "wave_type": WaveType.BOSS, "boss_name": "DEMON OF VANITY", "boss_type": "VANITY_BOSS" },
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
	{ "encounter": Encounter.ENEMIES, "wave_type": WaveType.FIGHT },
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
## FIGHT waves generate random enemies from the difficulty budget.
## BOSS waves return the single boss specified in the wave definition.
static func get_wave_def(wave: int) -> Array:
	var wave_info: Dictionary = WAVES[wave - 1]
	if wave_info["encounter"] == Encounter.BOSS:
		return generate_boss_wave(wave_info.get("boss_type", "VANITY_BOSS"))
	return generate_wave_enemies(wave)

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

## Compute the real difficulty cost for a given enemy type.
## At default scales (1.0) this equals base_difficulty.
## Scales above 1.0 increase the cost proportionally.
static func real_difficulty(type_name: String) -> float:
	var stats: Dictionary = BASE[type_name]
	var bd: float = stats["base_difficulty"]
	var hs: float = stats.get("health_scale", 1.0)
	var ds: float = stats.get("damage_scale", 1.0)
	return bd * ((hs + ds) / 2.0)

## Return the difficulty budget for a given wave number.
static func get_difficulty_budget(wave: int) -> float:
	return 100.0 + float(wave - 1) * 25.0

## Build a randomized enemy list for a FIGHT wave within the difficulty budget.
## Returns Array of { "type": String, "count": int }.
static func generate_wave_enemies(wave: int) -> Array:
	var budget: float = get_difficulty_budget(wave)
	var allowed_rarities: Array[int] = [Rarity.COMMON, Rarity.UNCOMMON, Rarity.RARE]

	var pool: Array[Dictionary] = []
	for type_name: String in BASE:
		var stats: Dictionary = BASE[type_name]
		var rarity: int = stats.get("rarity", Rarity.COMMON)
		if rarity not in allowed_rarities:
			continue
		var cost: float = real_difficulty(type_name)
		pool.append({ "type": type_name, "cost": cost })

	pool.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["cost"] < b["cost"])
	var min_cost: float = pool[0]["cost"] if pool.size() > 0 else 999999.0

	var counts: Dictionary = {}
	while budget >= min_cost and pool.size() > 0:
		var affordable: Array[Dictionary] = []
		for entry: Dictionary in pool:
			if entry["cost"] <= budget:
				affordable.append(entry)
		if affordable.is_empty():
			break
		var pick: Dictionary = affordable[randi() % affordable.size()]
		counts[pick["type"]] = counts.get(pick["type"], 0) + 1
		budget -= pick["cost"]

	var result: Array = []
	for type_name: String in counts:
		result.append({ "type": type_name, "count": counts[type_name] })
	return result

## Build the enemy list for a BOSS wave.
static func generate_boss_wave(boss_type_name: String) -> Array:
	return [{ "type": boss_type_name, "count": 1 }]
