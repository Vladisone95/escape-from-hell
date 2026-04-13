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
var _icon_tex: Texture2D = null

const ICON_PATHS: Dictionary = {
	"dagger": "res://assets/sprites/items/dagger.png",
	"slice_and_dice": "res://assets/sprites/items/slice_and_dice.png",
	"demon_heart": "res://assets/sprites/items/demon_heart.png",
	"thick_skin": "res://assets/sprites/items/thick_skin.png",
}

func _init(id: String = "", count: int = 1) -> void:
	item_id = id
	stack_count = count
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if id in ICON_PATHS:
		_icon_tex = load(ICON_PATHS[id])

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

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

	# Draw icon texture
	if _icon_tex:
		draw_texture(_icon_tex, Vector2(2, 2))

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

