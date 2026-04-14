class_name Upgrades
extends RefCounted

# ── Upgrade Database ────────────────────────────────────────────────────
const UPGRADES: Dictionary = {
	"max_health": {
		"id":          "max_health",
		"name":        "Vitality",
		"description": "+25 Max Health per stack",
		"stackable":   true,
		"max_stack":   5,
		"icon_id":     "max_health",
		"rarity":      Inventory.Rarity.COMMON,
	},
	"attack_up": {
		"id":          "attack_up",
		"name":        "Fury",
		"description": "+5 Attack per stack",
		"stackable":   true,
		"max_stack":   5,
		"icon_id":     "attack_up",
		"rarity":      Inventory.Rarity.COMMON,
	},
	"armor_up": {
		"id":          "armor_up",
		"name":        "Iron Skin",
		"description": "+3 Armor per stack",
		"stackable":   true,
		"max_stack":   3,
		"icon_id":     "armor_up",
		"rarity":      Inventory.Rarity.RARE,
	},
	"regen_up": {
		"id":          "regen_up",
		"name":        "Blood Pact",
		"description": "+2 Regen per stack",
		"stackable":   true,
		"max_stack":   3,
		"icon_id":     "regen_up",
		"rarity":      Inventory.Rarity.RARE,
	},
	"speed_up": {
		"id":          "speed_up",
		"name":        "Haste",
		"description": "+40 Speed per stack",
		"stackable":   true,
		"max_stack":   3,
		"icon_id":     "speed_up",
		"rarity":      Inventory.Rarity.RARE,
	},
	"dash_up": {
		"id":          "dash_up",
		"name":        "Shadow Step",
		"description": "-0.3s dash cooldown",
		"stackable":   false,
		"max_stack":   1,
		"icon_id":     "dash_up",
		"rarity":      Inventory.Rarity.EPIC,
	},
	"attack_speed": {
		"id":          "attack_speed",
		"name":        "Frenzy",
		"description": "-0.08s attack cooldown per stack",
		"stackable":   true,
		"max_stack":   3,
		"icon_id":     "attack_speed",
		"rarity":      Inventory.Rarity.EPIC,
	},
	"iframes_up": {
		"id":          "iframes_up",
		"name":        "Soul Shield",
		"description": "+0.3s invincibility frames",
		"stackable":   false,
		"max_stack":   1,
		"icon_id":     "iframes_up",
		"rarity":      Inventory.Rarity.MYTHICAL,
	},
}

# ── Upgrade slots ───────────────────────────────────────────────────────
var slots: Array[Dictionary] = []

func get_upgrade_def(upgrade_id: String) -> Dictionary:
	return UPGRADES.get(upgrade_id, {})

func has_upgrade(upgrade_id: String) -> bool:
	for slot in slots:
		if slot["id"] == upgrade_id:
			return true
	return false

func get_upgrade_stack(upgrade_id: String) -> int:
	for slot in slots:
		if slot["id"] == upgrade_id:
			return slot["count"]
	return 0

func add_upgrade(upgrade_id: String) -> bool:
	var def := get_upgrade_def(upgrade_id)
	if def.is_empty():
		return false
	for slot in slots:
		if slot["id"] == upgrade_id:
			if not def["stackable"]:
				return false
			if slot["count"] >= def["max_stack"]:
				return false
			slot["count"] += 1
			return true
	slots.append({"id": upgrade_id, "count": 1})
	return true

func clear() -> void:
	slots.clear()

# ── Rolling ─────────────────────────────────────────────────────────────
func roll_upgrades(count: int = 3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var used_ids: Array[String] = []

	for _i in range(count):
		# Build pool excluding maxed and already-rolled upgrades
		var pool_by_rarity: Dictionary = {}
		for id: String in UPGRADES:
			if id in used_ids:
				continue
			var def: Dictionary = UPGRADES[id]
			var current := get_upgrade_stack(id)
			if current >= def["max_stack"]:
				continue
			var r: int = def["rarity"]
			if not pool_by_rarity.has(r):
				pool_by_rarity[r] = []
			pool_by_rarity[r].append(id)

		if pool_by_rarity.is_empty():
			break

		# Roll rarity (only from available rarities)
		var available_rarities: Array[int] = []
		var weights: Array[int] = []
		for r: int in pool_by_rarity:
			available_rarities.append(r)
			weights.append(Inventory.RARITY_WEIGHTS[r])

		var total := 0
		for w: int in weights:
			total += w
		var roll := randi() % total
		var cumulative := 0
		var chosen_rarity: int = available_rarities[0]
		for idx in range(weights.size()):
			cumulative += weights[idx]
			if roll < cumulative:
				chosen_rarity = available_rarities[idx]
				break

		# Pick random upgrade from that rarity
		var rarity_pool: Array = pool_by_rarity[chosen_rarity]
		var chosen_id: String = rarity_pool[randi() % rarity_pool.size()]
		used_ids.append(chosen_id)
		result.append({"id": chosen_id, "rarity": chosen_rarity})

	return result

# ── Stat bonuses ────────────────────────────────────────────────────────
func bonus_max_health() -> int:
	return get_upgrade_stack("max_health") * 25

func bonus_attack() -> int:
	return get_upgrade_stack("attack_up") * 5

func bonus_armor() -> int:
	return get_upgrade_stack("armor_up") * 3

func bonus_regen() -> int:
	return get_upgrade_stack("regen_up") * 2

func bonus_speed() -> float:
	return get_upgrade_stack("speed_up") * 40.0

func bonus_dash_cooldown() -> float:
	if has_upgrade("dash_up"):
		return -0.3
	return 0.0

func bonus_attack_cooldown() -> float:
	return get_upgrade_stack("attack_speed") * -0.08

func bonus_attack_range() -> float:
	return 0.0

func bonus_iframes() -> float:
	if has_upgrade("iframes_up"):
		return 0.3
	return 0.0
