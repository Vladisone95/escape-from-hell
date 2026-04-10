class_name ItemThumbnail
extends Control

## Displays one inventory slot: drawn icon + stack count badge.
## Emits tooltip text on hover via signals read by the parent.

signal hovered(item_def: Dictionary, global_pos: Vector2)
signal unhovered()

const CELL_SIZE := 64
const BADGE_RADIUS := 9.0

var item_id: String = ""
var stack_count: int = 1

func _init(id: String = "", count: int = 1) -> void:
	item_id = id
	stack_count = count
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(_delta: float) -> void:
	queue_redraw()

func _on_mouse_entered() -> void:
	var def: Dictionary = Inventory.ITEMS.get(item_id, {})
	if not def.is_empty():
		hovered.emit(def, global_position)

func _on_mouse_exited() -> void:
	unhovered.emit()

# ── Draw ─────────────────────────────────────────────────────────────────
func _draw() -> void:
	# Background cell
	var bg := Rect2(2, 2, CELL_SIZE - 4, CELL_SIZE - 4)
	draw_rect(bg, Color(0.12, 0.10, 0.14))
	draw_rect(bg, Color(0.45, 0.35, 0.20), false, 2.0)

	# Draw icon based on id
	match item_id:
		"dagger":          _draw_dagger()
		"slice_and_dice":  _draw_slice_and_dice()
		"demon_heart":     _draw_demon_heart()
		"thick_skin":      _draw_thick_skin()

	# Stack badge (only if stackable and count > 1)
	if stack_count > 1:
		var badge_pos := Vector2(CELL_SIZE - 14, CELL_SIZE - 14)
		draw_circle(badge_pos, BADGE_RADIUS, Color(0.15, 0.12, 0.10))
		draw_circle(badge_pos, BADGE_RADIUS, Color(0.85, 0.70, 0.20), false, 1.5)
		# Count text via a small offset; drawn as a single character
		var font := ThemeDB.fallback_font
		var text := str(stack_count)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(font, badge_pos - Vector2(text_size.x / 2.0, -4.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.95, 0.7))


# ── Icon: Dagger ─────────────────────────────────────────────────────────
func _draw_dagger() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	# Blade
	draw_rect(Rect2(cx - 2, cy - 20, 4, 26), Color(0.80, 0.83, 0.90))
	# Edge highlight
	draw_rect(Rect2(cx, cy - 20, 1, 26), Color(0.95, 0.96, 1.0))
	# Tip
	draw_rect(Rect2(cx - 1, cy - 23, 2, 4), Color(0.92, 0.94, 0.98))
	# Crossguard
	draw_rect(Rect2(cx - 7, cy + 5, 14, 3), Color(0.60, 0.55, 0.30))
	# Hilt / grip
	draw_rect(Rect2(cx - 2, cy + 8, 4, 10), Color(0.50, 0.35, 0.15))
	# Pommel
	draw_rect(Rect2(cx - 3, cy + 17, 6, 4), Color(0.60, 0.55, 0.30))


# ── Icon: Slice and Dice ─────────────────────────────────────────────────
func _draw_slice_and_dice() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0

	# Two crossed swords
	# Sword 1 (leaning left)
	draw_set_transform(Vector2(cx - 8, cy), -0.35, Vector2.ONE)
	draw_rect(Rect2(-1.5, -18, 3, 24), Color(0.80, 0.83, 0.90))
	draw_rect(Rect2(-5, 5, 10, 2.5), Color(0.60, 0.55, 0.30))
	draw_rect(Rect2(-1.5, 7, 3, 8), Color(0.50, 0.35, 0.15))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Sword 2 (leaning right)
	draw_set_transform(Vector2(cx + 8, cy), 0.35, Vector2.ONE)
	draw_rect(Rect2(-1.5, -18, 3, 24), Color(0.80, 0.83, 0.90))
	draw_rect(Rect2(-5, 5, 10, 2.5), Color(0.60, 0.55, 0.30))
	draw_rect(Rect2(-1.5, 7, 3, 8), Color(0.50, 0.35, 0.15))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Slash arcs (stylized)
	draw_arc(Vector2(cx, cy - 4), 18.0, -2.2, -0.9, 8, Color(1.0, 0.85, 0.3, 0.7), 1.5)
	draw_arc(Vector2(cx, cy - 4), 14.0, -0.5, 0.8, 8, Color(1.0, 0.85, 0.3, 0.5), 1.5)


# ── Icon: Demon Heart ───────────────────────────────────────────────────
func _draw_demon_heart() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0

	# Heart shape (two overlapping circles + triangle bottom)
	var heart_col := Color(0.70, 0.05, 0.10)
	var heart_lt := Color(0.85, 0.15, 0.15)
	var heart_dk := Color(0.45, 0.02, 0.05)

	# Left lobe
	draw_circle(Vector2(cx - 7, cy - 6), 10.0, heart_col)
	# Right lobe
	draw_circle(Vector2(cx + 7, cy - 6), 10.0, heart_col)
	# Bottom triangle fill
	draw_rect(Rect2(cx - 16, cy - 6, 32, 12), heart_col)
	draw_rect(Rect2(cx - 12, cy + 6, 24, 6), heart_col)
	draw_rect(Rect2(cx - 8, cy + 12, 16, 4), heart_col)
	draw_rect(Rect2(cx - 4, cy + 16, 8, 3), heart_col)
	draw_rect(Rect2(cx - 1, cy + 19, 2, 2), heart_col)

	# Highlight on left lobe
	draw_circle(Vector2(cx - 9, cy - 9), 4.0, heart_lt)

	# Dark vein lines
	draw_line(Vector2(cx, cy - 4), Vector2(cx - 5, cy + 10), heart_dk, 1.5)
	draw_line(Vector2(cx, cy - 4), Vector2(cx + 6, cy + 8), heart_dk, 1.5)
	draw_line(Vector2(cx - 5, cy + 10), Vector2(cx - 2, cy + 16), heart_dk, 1.2)

	# Demonic glow dots
	draw_circle(Vector2(cx - 6, cy - 2), 2.0, Color(1.0, 0.3, 0.0, 0.7))
	draw_circle(Vector2(cx + 5, cy + 2), 1.5, Color(1.0, 0.3, 0.0, 0.5))


# ── Icon: Thick Skin ────────────────────────────────────────────────────
func _draw_thick_skin() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0

	# Shield shape
	var shield_col := Color(0.50, 0.40, 0.25)
	var shield_lt := Color(0.65, 0.55, 0.35)
	var shield_dk := Color(0.35, 0.28, 0.15)

	# Main shield body
	draw_rect(Rect2(cx - 14, cy - 16, 28, 28), shield_col)
	draw_rect(Rect2(cx - 12, cy + 12, 24, 4), shield_col)
	draw_rect(Rect2(cx - 8, cy + 16, 16, 4), shield_col)
	draw_rect(Rect2(cx - 4, cy + 20, 8, 3), shield_col)

	# Top edge highlight
	draw_rect(Rect2(cx - 14, cy - 16, 28, 3), shield_lt)
	# Left edge
	draw_rect(Rect2(cx - 14, cy - 16, 3, 28), shield_lt)

	# Inner cross pattern (health symbol)
	draw_rect(Rect2(cx - 3, cy - 10, 6, 20), Color(0.20, 0.65, 0.20))
	draw_rect(Rect2(cx - 9, cy - 4, 18, 6), Color(0.20, 0.65, 0.20))
	# Cross highlight
	draw_rect(Rect2(cx - 2, cy - 9, 4, 18), Color(0.30, 0.80, 0.30))
	draw_rect(Rect2(cx - 8, cy - 3, 16, 4), Color(0.30, 0.80, 0.30))

	# Bottom shadow
	draw_rect(Rect2(cx - 12, cy + 10, 24, 2), shield_dk)
