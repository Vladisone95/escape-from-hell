extends Node
# AutoLoad — persists between scenes

var current_wave: int    = 1
var _cursor_default: ImageTexture
var _cursor_pointer: ImageTexture
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
