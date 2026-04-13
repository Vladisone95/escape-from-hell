class_name UpgradeThumbnail
extends Control

signal hovered(upgrade_def: Dictionary, global_pos: Vector2)
signal unhovered()

const CELL_SIZE := 64
const BADGE_RADIUS := 9.0

var upgrade_id: String = ""
var stack_count: int = 1

func _init(id: String = "", count: int = 1) -> void:
	upgrade_id = id
	stack_count = count
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(_delta: float) -> void:
	queue_redraw()

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

	match upgrade_id:
		"max_health":    _draw_vitality()
		"attack_up":     _draw_fury()
		"armor_up":      _draw_iron_skin()
		"regen_up":      _draw_blood_pact()
		"speed_up":      _draw_haste()
		"dash_up":       _draw_shadow_step()
		"attack_speed":  _draw_frenzy()
		"iframes_up":    _draw_soul_shield()

	if stack_count > 1:
		var badge_pos := Vector2(CELL_SIZE - 14, CELL_SIZE - 14)
		draw_circle(badge_pos, BADGE_RADIUS, Color(0.15, 0.08, 0.06))
		draw_circle(badge_pos, BADGE_RADIUS, Color(0.85, 0.30, 0.15), false, 1.5)
		var font := ThemeDB.fallback_font
		var text := str(stack_count)
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(font, badge_pos - Vector2(text_size.x / 2.0, -4.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.9, 0.7))


# ── Vitality: Red heart with plus sign ──────────────────────────────────
func _draw_vitality() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	var heart_col := Color(0.80, 0.10, 0.15)
	var heart_lt := Color(0.95, 0.25, 0.20)
	# Left lobe
	draw_circle(Vector2(cx - 6, cy - 5), 8.0, heart_col)
	# Right lobe
	draw_circle(Vector2(cx + 6, cy - 5), 8.0, heart_col)
	# Bottom
	draw_rect(Rect2(cx - 13, cy - 5, 26, 10), heart_col)
	draw_rect(Rect2(cx - 10, cy + 5, 20, 5), heart_col)
	draw_rect(Rect2(cx - 6, cy + 10, 12, 4), heart_col)
	draw_rect(Rect2(cx - 2, cy + 14, 4, 3), heart_col)
	# Highlight
	draw_circle(Vector2(cx - 7, cy - 8), 3.5, heart_lt)
	# Plus sign
	draw_rect(Rect2(cx - 1.5, cy - 8, 3, 10), Color.WHITE)
	draw_rect(Rect2(cx - 5, cy - 4.5, 10, 3), Color.WHITE)


# ── Fury: Flaming sword ────────────────────────────────────────────────
func _draw_fury() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	# Blade
	draw_rect(Rect2(cx - 2, cy - 18, 4, 22), Color(0.85, 0.40, 0.10))
	draw_rect(Rect2(cx - 0.5, cy - 18, 1, 22), Color(1.0, 0.70, 0.30))
	# Tip
	draw_rect(Rect2(cx - 1, cy - 21, 2, 4), Color(1.0, 0.60, 0.15))
	# Crossguard
	draw_rect(Rect2(cx - 7, cy + 4, 14, 3), Color(0.55, 0.20, 0.10))
	# Hilt
	draw_rect(Rect2(cx - 2, cy + 7, 4, 9), Color(0.40, 0.15, 0.08))
	# Pommel
	draw_rect(Rect2(cx - 3, cy + 15, 6, 4), Color(0.55, 0.20, 0.10))
	# Flame wisps
	draw_circle(Vector2(cx - 4, cy - 14), 3.0, Color(1.0, 0.5, 0.0, 0.5))
	draw_circle(Vector2(cx + 3, cy - 10), 2.5, Color(1.0, 0.6, 0.1, 0.4))
	draw_circle(Vector2(cx - 2, cy - 19), 2.0, Color(1.0, 0.8, 0.2, 0.6))


# ── Iron Skin: Shield with iron cross ──────────────────────────────────
func _draw_iron_skin() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	var shield := Color(0.45, 0.45, 0.50)
	var shield_lt := Color(0.60, 0.60, 0.68)
	var shield_dk := Color(0.30, 0.30, 0.35)
	# Shield body
	draw_rect(Rect2(cx - 14, cy - 14, 28, 26), shield)
	draw_rect(Rect2(cx - 12, cy + 12, 24, 4), shield)
	draw_rect(Rect2(cx - 8, cy + 16, 16, 3), shield)
	draw_rect(Rect2(cx - 4, cy + 19, 8, 2), shield)
	# Highlight
	draw_rect(Rect2(cx - 14, cy - 14, 28, 3), shield_lt)
	draw_rect(Rect2(cx - 14, cy - 14, 3, 26), shield_lt)
	# Iron cross
	draw_rect(Rect2(cx - 2, cy - 8, 4, 18), shield_dk)
	draw_rect(Rect2(cx - 8, cy - 2, 16, 4), shield_dk)
	# Rivets
	for p in [Vector2(cx - 10, cy - 10), Vector2(cx + 10, cy - 10), Vector2(cx - 10, cy + 8), Vector2(cx + 10, cy + 8)]:
		draw_circle(p, 2.0, shield_lt)


# ── Blood Pact: Green drop with veins ──────────────────────────────────
func _draw_blood_pact() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	var drop := Color(0.15, 0.70, 0.25)
	var drop_lt := Color(0.25, 0.85, 0.35)
	# Drop shape
	draw_circle(Vector2(cx, cy + 4), 12.0, drop)
	draw_rect(Rect2(cx - 8, cy - 4, 16, 10), drop)
	draw_rect(Rect2(cx - 5, cy - 10, 10, 8), drop)
	draw_rect(Rect2(cx - 2, cy - 16, 4, 8), drop)
	draw_rect(Rect2(cx - 0.5, cy - 19, 1, 4), drop)
	# Highlight
	draw_circle(Vector2(cx - 4, cy + 1), 4.0, drop_lt)
	# Veins
	draw_line(Vector2(cx, cy - 6), Vector2(cx - 5, cy + 8), Color(0.08, 0.45, 0.12), 1.2)
	draw_line(Vector2(cx, cy - 6), Vector2(cx + 4, cy + 6), Color(0.08, 0.45, 0.12), 1.2)


# ── Haste: Winged boot ─────────────────────────────────────────────────
func _draw_haste() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	var boot := Color(0.50, 0.35, 0.18)
	var wing := Color(0.80, 0.80, 0.90)
	# Boot sole
	draw_rect(Rect2(cx - 10, cy + 10, 20, 4), Color(0.30, 0.20, 0.10))
	# Boot body
	draw_rect(Rect2(cx - 8, cy - 4, 14, 14), boot)
	# Boot top
	draw_rect(Rect2(cx - 6, cy - 14, 10, 12), boot)
	# Boot toe
	draw_rect(Rect2(cx + 4, cy + 6, 8, 4), boot)
	# Wing feathers
	for i in range(3):
		var fy := cy - 2.0 + i * 5.0
		var fw := 12.0 - i * 2.0
		draw_line(Vector2(cx - 8, fy), Vector2(cx - 8 - fw, fy - 4 + i * 2), wing, 2.0)
	# Speed lines
	for i in range(3):
		var ly := cy - 8.0 + i * 8.0
		draw_line(Vector2(cx + 14, ly), Vector2(cx + 22, ly), Color(1.0, 0.9, 0.3, 0.5), 1.5)


# ── Shadow Step: Dash trail ─────────────────────────────────────────────
func _draw_shadow_step() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	# Ghost silhouettes (3 fading copies)
	for i in range(3):
		var alpha := 0.15 + i * 0.15
		var ox := -14.0 + i * 8.0
		var col := Color(0.50, 0.20, 0.70, alpha)
		# Simple figure silhouette
		draw_circle(Vector2(cx + ox, cy - 8), 6.0, col)  # head
		draw_rect(Rect2(cx + ox - 4, cy - 2, 8, 14), col)  # body
	# Final solid figure
	draw_circle(Vector2(cx + 10, cy - 8), 6.0, Color(0.72, 0.30, 0.92))
	draw_rect(Rect2(cx + 6, cy - 2, 8, 14), Color(0.72, 0.30, 0.92))
	# Trail swoosh
	draw_line(Vector2(cx - 18, cy + 6), Vector2(cx + 6, cy + 6), Color(0.60, 0.20, 0.80, 0.4), 2.0)
	draw_line(Vector2(cx - 14, cy + 10), Vector2(cx + 4, cy + 10), Color(0.60, 0.20, 0.80, 0.25), 1.5)


# ── Frenzy: Crossed swords with speed marks ─────────────────────────────
func _draw_frenzy() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	# Sword 1
	draw_set_transform(Vector2(cx - 6, cy), -0.4, Vector2.ONE)
	draw_rect(Rect2(-1.5, -16, 3, 20), Color(0.85, 0.40, 0.10))
	draw_rect(Rect2(-4, 3, 8, 2), Color(0.55, 0.20, 0.10))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Sword 2
	draw_set_transform(Vector2(cx + 6, cy), 0.4, Vector2.ONE)
	draw_rect(Rect2(-1.5, -16, 3, 20), Color(0.85, 0.40, 0.10))
	draw_rect(Rect2(-4, 3, 8, 2), Color(0.55, 0.20, 0.10))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Speed arcs
	draw_arc(Vector2(cx, cy - 6), 16.0, -2.0, -1.0, 6, Color(1.0, 0.7, 0.2, 0.6), 1.5)
	draw_arc(Vector2(cx, cy - 6), 12.0, -0.3, 0.7, 6, Color(1.0, 0.7, 0.2, 0.4), 1.5)
	# Impact sparks
	draw_circle(Vector2(cx, cy - 12), 2.5, Color(1.0, 0.9, 0.3, 0.7))


# ── Soul Shield: Glowing spirit orb ────────────────────────────────────
func _draw_soul_shield() -> void:
	var cx := CELL_SIZE / 2.0
	var cy := CELL_SIZE / 2.0
	# Outer glow
	draw_circle(Vector2(cx, cy), 18.0, Color(1.0, 0.75, 0.10, 0.12))
	draw_circle(Vector2(cx, cy), 14.0, Color(1.0, 0.75, 0.10, 0.20))
	# Main orb
	draw_circle(Vector2(cx, cy), 10.0, Color(1.0, 0.75, 0.10, 0.6))
	# Inner bright core
	draw_circle(Vector2(cx, cy), 5.0, Color(1.0, 0.90, 0.50, 0.85))
	draw_circle(Vector2(cx, cy), 2.5, Color(1.0, 1.0, 0.90))
	# Spirit wisps
	for i in range(4):
		var angle := i * TAU / 4.0 + 0.3
		var wp := Vector2(cx + cos(angle) * 14.0, cy + sin(angle) * 14.0)
		draw_circle(wp, 2.0, Color(1.0, 0.85, 0.30, 0.4))
	# Shield ring
	draw_arc(Vector2(cx, cy), 16.0, 0.0, TAU, 16, Color(1.0, 0.80, 0.20, 0.35), 1.5)
