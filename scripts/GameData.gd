extends Node
# AutoLoad — persists between scenes

var current_wave: int    = 1
var current_act: int     = 1
var _cursor_default: ImageTexture
var _cursor_pointer: ImageTexture
var player_health: int   = 100
var player_max_health: int = 100
var player_attack: int   = 10
var player_armor: int    = 3
var player_spikes: int   = 0
var player_regen: int    = 1

# Real-time arena stats
enum WeaponType { MELEE, RANGED }

var player_weapon_type: int = WeaponType.MELEE
var player_attack_range: float = 150.0

var player_speed: float         = 280.0
var player_dash_speed: float    = 1000.0
var player_dash_duration: float = 0.15
var player_dash_cooldown: float = 10.0
var player_attack_cooldown: float = 0.5
var player_iframes: float       = 0.5

const TOTAL_WAVES: int   = 10

# Inventory
var player_inventory: Inventory = Inventory.new()

# Upgrades (from Sacrificial Shrines)
var player_upgrades: Upgrades = Upgrades.new()

# Waves that offer item rewards instead of (or alongside) normal upgrades
const ITEM_REWARD_WAVES: Array[int] = [3, 5, 7]

# Enemy stats & wave definitions live in EnemyStats.gd

func _ready() -> void:
	_create_cursors()

func _create_cursors() -> void:
	_cursor_default = _make_cursor_texture(_draw_default_cursor)
	_cursor_pointer = _make_cursor_texture(_draw_pointer_cursor)
	Input.set_custom_mouse_cursor(_cursor_default, Input.CURSOR_ARROW, Vector2(1, 1))
	Input.set_custom_mouse_cursor(_cursor_pointer, Input.CURSOR_POINTING_HAND, Vector2(7, 1))

func _make_cursor_texture(draw_fn: Callable) -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	draw_fn.call(img)
	return ImageTexture.create_from_image(img)

func _draw_default_cursor(img: Image) -> void:
	# Infernal pointed arrow — dark body with ember-orange edge
	# Arrow shape pixels (pointing top-left)
	var outline_col := Color(0.9, 0.35, 0.05)       # ember orange
	var fill_col    := Color(0.12, 0.05, 0.08)       # near-black
	var highlight   := Color(1.0, 0.6, 0.15)         # bright tip
	var hot_col     := Color(0.7, 0.2, 0.03, 0.7)    # warm inner glow

	# Arrow outline (hand-crafted scanlines for a 20px tall arrow)
	var arrow: Array[PackedInt32Array] = [
		PackedInt32Array([1]),                          # row 0
		PackedInt32Array([1, 2]),                       # row 1
		PackedInt32Array([1, 2, 3]),
		PackedInt32Array([1, 2, 3, 4]),
		PackedInt32Array([1, 2, 3, 4, 5]),
		PackedInt32Array([1, 2, 3, 4, 5, 6]),
		PackedInt32Array([1, 2, 3, 4, 5, 6, 7]),
		PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8]),
		PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9]),
		PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]),
		PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
		PackedInt32Array([1, 2, 3, 4, 5, 6, 7]),       # row 11: notch
		PackedInt32Array([1, 2, 3, 4, 5, 6]),
		PackedInt32Array([1, 2, 3, 5, 6, 7]),
		PackedInt32Array([1, 2, 6, 7, 8]),
		PackedInt32Array([1, 7, 8, 9]),
		PackedInt32Array([8, 9, 10]),
		PackedInt32Array([9, 10, 11]),
		PackedInt32Array([10, 11]),
		PackedInt32Array([11]),                         # row 19
	]

	# Draw outline (1px border around each filled pixel)
	for y in range(arrow.size()):
		for x in arrow[y]:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var px := x + dx
					var py := y + dy
					if px >= 0 and px < 32 and py >= 0 and py < 32:
						if img.get_pixel(px, py).a < 0.01:
							img.set_pixel(px, py, outline_col)

	# Fill interior
	for y in range(arrow.size()):
		for x in arrow[y]:
			img.set_pixel(x, y, fill_col)

	# Inner glow (warm gradient near the edge, rows 2-10)
	for y in range(2, mini(arrow.size(), 10)):
		var cols: PackedInt32Array = arrow[y]
		if cols.size() >= 2:
			img.set_pixel(cols[cols.size() - 1], y, hot_col)
			if cols.size() >= 3:
				img.set_pixel(cols[cols.size() - 2], y, Color(hot_col.r, hot_col.g, hot_col.b, 0.35))

	# Bright tip (top 3 pixels)
	img.set_pixel(1, 0, highlight)
	img.set_pixel(1, 1, highlight)
	img.set_pixel(2, 1, Color(highlight.r, highlight.g, highlight.b, 0.6))

func _draw_pointer_cursor(img: Image) -> void:
	# Infernal hand/pointer — a small hellish pointing finger
	var outline_col := Color(0.9, 0.35, 0.05)
	var fill_col    := Color(0.15, 0.06, 0.08)
	var highlight   := Color(1.0, 0.6, 0.15)

	# Pointing hand shape (simplified)
	var hand: Array[PackedInt32Array] = [
		PackedInt32Array([6, 7]),                          # fingertip
		PackedInt32Array([5, 6, 7, 8]),
		PackedInt32Array([5, 6, 7, 8]),
		PackedInt32Array([5, 6, 7, 8]),
		PackedInt32Array([5, 6, 7, 8]),
		PackedInt32Array([5, 6, 7, 8, 10, 11]),
		PackedInt32Array([3, 4, 5, 6, 7, 8, 10, 11, 13, 14]),
		PackedInt32Array([3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]),
		PackedInt32Array([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]),
		PackedInt32Array([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14]),
		PackedInt32Array([3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]),
		PackedInt32Array([4, 5, 6, 7, 8, 9, 10, 11, 12]),
		PackedInt32Array([4, 5, 6, 7, 8, 9, 10, 11, 12]),
		PackedInt32Array([4, 5, 6, 7, 8, 9, 10, 11, 12]),
		PackedInt32Array([5, 6, 7, 8, 9, 10, 11, 12]),
		PackedInt32Array([5, 6, 7, 8, 9, 10, 11]),
		PackedInt32Array([5, 6, 7, 8, 9, 10, 11]),
		PackedInt32Array([6, 7, 8, 9, 10]),
	]

	# Outline
	for y in range(hand.size()):
		for x in hand[y]:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var px := x + dx
					var py := y + dy
					if px >= 0 and px < 32 and py >= 0 and py < 32:
						if img.get_pixel(px, py).a < 0.01:
							img.set_pixel(px, py, outline_col)

	# Fill
	for y in range(hand.size()):
		for x in hand[y]:
			img.set_pixel(x, y, fill_col)

	# Bright fingertip
	img.set_pixel(6, 0, highlight)
	img.set_pixel(7, 0, highlight)
	img.set_pixel(6, 1, Color(highlight.r, highlight.g, highlight.b, 0.7))

func reset() -> void:
	current_wave      = 1
	current_act       = 1
	player_health     = 100
	player_max_health = 100
	player_attack     = 10
	player_armor      = 3
	player_spikes     = 0
	player_regen      = 1
	player_inventory  = Inventory.new()
	player_upgrades   = Upgrades.new()
	player_speed         = 280.0
	player_dash_speed    = 1000.0
	player_dash_duration = 0.15
	player_dash_cooldown = 10.0
	player_attack_cooldown = 0.5
	player_weapon_type   = WeaponType.MELEE
	player_attack_range  = 150.0
	player_iframes       = 0.5

func is_item_reward_wave() -> bool:
	return current_wave in ITEM_REWARD_WAVES

## Effective attack = base + inventory bonus + upgrade bonus
func effective_attack() -> int:
	return player_attack + player_inventory.bonus_attack() + player_upgrades.bonus_attack()

## Number of strikes per attack press from inventory
func attacks_per_press() -> int:
	return player_inventory.attacks_per_press()

## Effective max health = base + inventory bonus + upgrade bonus
func effective_max_health() -> int:
	return player_max_health + player_inventory.bonus_max_health() + player_upgrades.bonus_max_health()

## Effective regen = base + inventory bonus + upgrade bonus
func effective_regen() -> int:
	return player_regen + player_inventory.bonus_regen() + player_upgrades.bonus_regen()

## Effective armor = base + upgrade bonus
func effective_armor() -> int:
	return player_armor + player_upgrades.bonus_armor()

## Effective speed = base + upgrade bonus
func effective_speed() -> float:
	return player_speed + player_upgrades.bonus_speed()

## Effective dash cooldown = base + upgrade bonus
func effective_dash_cooldown() -> float:
	return player_dash_cooldown + player_upgrades.bonus_dash_cooldown()

## Effective attack cooldown = base + upgrade bonus
func effective_attack_cooldown() -> float:
	return player_attack_cooldown + player_upgrades.bonus_attack_cooldown()

## Effective attack range = base + inventory bonus + upgrade bonus
func effective_attack_range() -> float:
	return player_attack_range + player_inventory.bonus_attack_range() + player_upgrades.bonus_attack_range()

## Effective iframes = base + upgrade bonus
func effective_iframes() -> float:
	return player_iframes + player_upgrades.bonus_iframes()

func wave_scale() -> float:
	return 1.0 + (current_wave - 1) * 0.22

func is_last_wave() -> bool:
	return current_wave >= TOTAL_WAVES
