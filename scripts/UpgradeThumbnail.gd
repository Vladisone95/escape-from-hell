class_name UpgradeThumbnail
extends Control

signal hovered(upgrade_def: Dictionary, global_pos: Vector2)
signal unhovered()

const CELL_SIZE := 64
const BADGE_RADIUS := 9.0

var upgrade_id: String = ""
var stack_count: int = 1
var _icon_tex: Texture2D = null

const ICON_PATHS: Dictionary = {
	"max_health": "res://assets/sprites/upgrades/max_health.png",
	"attack_up": "res://assets/sprites/upgrades/attack_up.png",
	"armor_up": "res://assets/sprites/upgrades/armor_up.png",
	"regen_up": "res://assets/sprites/upgrades/regen_up.png",
	"speed_up": "res://assets/sprites/upgrades/speed_up.png",
	"dash_up": "res://assets/sprites/upgrades/dash_up.png",
	"attack_speed": "res://assets/sprites/upgrades/attack_speed.png",
	"iframes_up": "res://assets/sprites/upgrades/iframes_up.png",
}

func _init(id: String = "", count: int = 1) -> void:
	upgrade_id = id
	stack_count = count
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if id in ICON_PATHS:
		_icon_tex = load(ICON_PATHS[id])

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	var def: Dictionary = Upgrades.UPGRADES.get(upgrade_id, {})
	if not def.is_empty():
		hovered.emit(def, global_position)

func _on_mouse_exited() -> void:
	unhovered.emit()

func _draw() -> void:
	var bg := Rect2(2, 2, CELL_SIZE - 4, CELL_SIZE - 4)
	draw_rect(bg, Color(0.14, 0.06, 0.08))
	draw_rect(bg, Color(0.55, 0.20, 0.15), false, 2.0)

	# Draw icon texture
	if _icon_tex:
		draw_texture(_icon_tex, Vector2(2, 2))

	if stack_count > 1:
		var badge_pos := Vector2(CELL_SIZE - 14, CELL_SIZE - 14)
		draw_circle(badge_pos, BADGE_RADIUS, Color(0.15, 0.08, 0.06))
		draw_circle(badge_pos, BADGE_RADIUS, Color(0.85, 0.30, 0.15), false, 1.5)
		var font := ThemeDB.fallback_font
		var text := str(stack_count)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(font, badge_pos - Vector2(text_size.x / 2.0, -4.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.9, 0.7))

