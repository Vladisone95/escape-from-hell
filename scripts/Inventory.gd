class_name Inventory
extends RefCounted

# ── Rarity System ───────────────────────────────────────────────────────
enum Rarity { COMMON, RARE, EPIC, MYTHICAL }

const RARITY_WEIGHTS: Array[int] = [60, 25, 10, 5]
const RARITY_NAMES: Array[String] = ["Common", "Rare", "Epic", "Mythical"]
const RARITY_COLORS: Dictionary = {
	Rarity.COMMON:   Color(0.65, 0.65, 0.70),
	Rarity.RARE:     Color(0.30, 0.55, 1.0),
	Rarity.EPIC:     Color(0.72, 0.30, 0.92),
	Rarity.MYTHICAL: Color(1.0, 0.75, 0.10),
}

static func roll_rarity() -> Rarity:
	var total := 0
	for w: int in RARITY_WEIGHTS:
		total += w
	var roll := randi() % total
	var cumulative := 0
	for i in range(RARITY_WEIGHTS.size()):
		cumulative += RARITY_WEIGHTS[i]
		if roll < cumulative:
			return i as Rarity
	return Rarity.COMMON

# ── Item Database ────────────────────────────────────────────────────────
# Each item is a dictionary with: id, name, description, stackable, max_stack, icon_id
# icon_id is used by ItemThumbnail to draw the correct icon
const ITEMS: Dictionary = {
	"dagger": {
		"id":          "dagger",
		"name":        "Dagger",
		"description": "+10 Attack per stack",
		"stackable":   true,
		"max_stack":   5,
		"icon_id":     "dagger",
		"rarity":      Rarity.COMMON,
	},
	"slice_and_dice": {
		"id":          "slice_and_dice",
		"name":        "Slice and Dice",
		"description": "Attack 2 times each turn",
		"stackable":   false,
		"max_stack":   1,
		"icon_id":     "slice_and_dice",
		"rarity":      Rarity.MYTHICAL,
	},
	"demon_heart": {
		"id":          "demon_heart",
		"name":        "Demon Heart",
		"description": "+3 Regen per stack",
		"stackable":   true,
		"max_stack":   5,
		"icon_id":     "demon_heart",
		"rarity":      Rarity.COMMON,
	},
	"thick_skin": {
		"id":          "thick_skin",
		"name":        "Thick Skin",
		"description": "+25 Max Health per stack",
		"stackable":   true,
		"max_stack":   5,
		"icon_id":     "thick_skin",
		"rarity":      Rarity.COMMON,
	},
}

# ── Inventory slots ──────────────────────────────────────────────────────
# Each slot: { "id": String, "count": int }
var slots: Array[Dictionary] = []

# ── Query ────────────────────────────────────────────────────────────────
func get_item_def(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

func has_item(item_id: String) -> bool:
	for slot in slots:
		if slot["id"] == item_id:
			return true
	return false

func get_stack(item_id: String) -> int:
	for slot in slots:
		if slot["id"] == item_id:
			return slot["count"]
	return 0

func get_slots() -> Array[Dictionary]:
	return slots

# ── Add / Remove ─────────────────────────────────────────────────────────

## Returns true if the item was successfully added.
func add_item(item_id: String) -> bool:
	var def := get_item_def(item_id)
	if def.is_empty():
		return false

	# Check if already in inventory
	for slot in slots:
		if slot["id"] == item_id:
			if not def["stackable"]:
				return false  # unique — already owned
			if slot["count"] >= def["max_stack"]:
				return false  # stack full
			slot["count"] += 1
			return true

	# New slot
	slots.append({"id": item_id, "count": 1})
	return true

## Returns true if the item was successfully removed (one from stack).
func remove_item(item_id: String) -> bool:
	for i in range(slots.size()):
		if slots[i]["id"] == item_id:
			slots[i]["count"] -= 1
			if slots[i]["count"] <= 0:
				slots.remove_at(i)
			return true
	return false

func clear() -> void:
	slots.clear()

# ── Combat helpers ───────────────────────────────────────────────────────

## Total bonus attack from all items.
func bonus_attack() -> int:
	var total := 0
	for slot in slots:
		if slot["id"] == "dagger":
			total += 10 * slot["count"]
	return total

## Number of attacks per turn.
func attacks_per_turn() -> int:
	if has_item("slice_and_dice"):
		return 2
	return 1

## Total bonus regen from all items.
func bonus_regen() -> int:
	var total := 0
	for slot in slots:
		if slot["id"] == "demon_heart":
			total += 3 * slot["count"]
	return total

## Total bonus max health from all items.
func bonus_max_health() -> int:
	var total := 0
	for slot in slots:
		if slot["id"] == "thick_skin":
			total += 25 * slot["count"]
	return total
