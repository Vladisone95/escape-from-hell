extends Node
# AutoLoad — persists between scenes

var current_wave: int    = 1
var player_health: int   = 100
var player_max_health: int = 100
var player_attack: int   = 10
var player_armor: int    = 3
var player_spikes: int   = 0
var player_regen: int    = 1
const TOTAL_WAVES: int   = 10

# Inventory
var player_inventory: Inventory = Inventory.new()

# Waves that offer item rewards instead of (or alongside) normal upgrades
const ITEM_REWARD_WAVES: Array[int] = [3, 5, 7]

# Wave enemy definitions: Array of [EnemyNode.EType, count]
# EType: 0=DEMON 1=IMP 2=HELLHOUND
const WAVE_ENEMIES: Array = [
	[[1, 2]],                          # Wave  1: 2 Imps
	[[0, 1]],                          # Wave  2: 1 Demon
	[[1, 3]],                          # Wave  3: 3 Imps
	[[0, 1],[1, 2]],                   # Wave  4: 1 Demon + 2 Imps
	[[0, 2],[2, 1]],                   # Wave  5: 2 Demons + 1 Hellhound
	[[0, 2],[1, 2]],                   # Wave  6: 2 Demons + 2 Imps
	[[1, 3],[2, 2]],                   # Wave  7: 3 Imps + 2 Hellhounds
	[[0, 2],[2, 2]],                   # Wave  8: 2 Demons + 2 Hellhounds
	[[0, 3],[1, 2],[2, 1]],            # Wave  9: 3 Demons + 2 Imps + 1 Hellhound
	[[0, 4],[2, 2],[1, 2]],            # Wave 10 (BOSS): 4 Demons + 2 Hellhounds + 2 Imps
]

# Base stats per enemy type [health, attack, speed, armor]
const ENEMY_BASE: Array = [
	[35, 9, 75, 2],   # Demon
	[18, 4, 130, 0],  # Imp
	[22, 7, 155, 1],  # Hellhound
]

func reset() -> void:
	current_wave      = 1
	player_health     = 100
	player_max_health = 100
	player_attack     = 10
	player_armor      = 3
	player_spikes     = 0
	player_regen      = 1
	player_inventory  = Inventory.new()

func is_item_reward_wave() -> bool:
	return current_wave in ITEM_REWARD_WAVES

## Effective attack = base + inventory bonus
func effective_attack() -> int:
	return player_attack + player_inventory.bonus_attack()

## Number of attacks per turn from inventory
func attacks_per_turn() -> int:
	return player_inventory.attacks_per_turn()

## Effective max health = base + inventory bonus
func effective_max_health() -> int:
	return player_max_health + player_inventory.bonus_max_health()

## Effective regen = base + inventory bonus
func effective_regen() -> int:
	return player_regen + player_inventory.bonus_regen()

func wave_scale() -> float:
	return 1.0 + (current_wave - 1) * 0.22

func enemy_health(etype: int) -> int:
	return int(ENEMY_BASE[etype][0] * wave_scale())

func enemy_attack(etype: int) -> int:
	return int(ENEMY_BASE[etype][1] * wave_scale())

func enemy_armor(etype: int) -> int:
	return int(ENEMY_BASE[etype][3] * wave_scale())

func enemy_speed(etype: int) -> float:
	return ENEMY_BASE[etype][2] * (1.0 + (current_wave - 1) * 0.08)

func is_last_wave() -> bool:
	return current_wave >= TOTAL_WAVES
