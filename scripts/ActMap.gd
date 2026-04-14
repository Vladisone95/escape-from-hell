class_name ActMap
extends Control

signal wave_selected(wave_num: int)
signal close_requested

## If true, all nodes are read-only — no click interaction (used for TAB mid-combat).
var read_only: bool = false
## Override which wave is selectable. -1 = auto (current_wave + 1).
var selectable_wave: int = -1

var _time: float = 0.0
var _hovered_wave: int = -1

const NODE_RADIUS: float = 28.0
const TOP_Y: float = 120.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _wave_y(wave: int) -> float:
	var bottom_y: float = size.y - 80.0
	var t: float = float(wave - 1) / float(GameData.TOTAL_WAVES - 1)
	return lerpf(bottom_y, TOP_Y, t)

func _get_selectable() -> int:
	if selectable_wave > 0:
		return selectable_wave
	return GameData.current_wave + 1

func _close_rect() -> Rect2:
	return Rect2(size.x - 52.0, 12.0, 40.0, 40.0)

func _gui_input(event: InputEvent) -> void:
	if read_only:
		return
	if event is InputEventMouseMotion:
		_update_hovered((event as InputEventMouseMotion).position)
	if event is InputEventMouseButton:
		var mbe: InputEventMouseButton = event as InputEventMouseButton
		if mbe.button_index == MOUSE_BUTTON_LEFT and mbe.pressed:
			if _close_rect().has_point(mbe.position):
				close_requested.emit()
				return
			if _hovered_wave > 0:
				wave_selected.emit(_hovered_wave)

func _update_hovered(mouse_pos: Vector2) -> void:
	var sel: int = _get_selectable()
	if sel > GameData.TOTAL_WAVES:
		_hovered_wave = -1
		return
	var node_pos: Vector2 = Vector2(size.x * 0.5, _wave_y(sel))
	if mouse_pos.distance_to(node_pos) <= NODE_RADIUS + 8.0:
		_hovered_wave = sel
	else:
		_hovered_wave = -1
	queue_redraw()

func _draw() -> void:
	var sw: float = size.x
	var sh: float = size.y

	# Background
	draw_rect(Rect2(0.0, 0.0, sw, sh), Color(0.02, 0.01, 0.04, 0.96))

	# Stone block grid texture
	var cols: int = 13
	var rows: int = 8
	var cw: float = sw / float(cols)
	var ch: float = sh / float(rows)
	for row: int in rows:
		for col: int in cols:
			var idx: int = row * cols + col
			var n: float = fmod(absf(sin(float(row * 31 + col * 17)) * 4371.5), 1.0)
			var bcol: Color = Color(0.042 + n * 0.022, 0.012 + n * 0.006, 0.038 + n * 0.014)
			draw_rect(Rect2(float(col) * cw + 2.0, float(row) * ch + 2.0, cw - 4.0, ch - 4.0), bcol)
		draw_rect(Rect2(0.0, float(row) * ch, sw, 2.0), Color(0.010, 0.004, 0.018, 1.0))
	for col: int in cols:
		draw_rect(Rect2(float(col) * cw, 0.0, 2.0, sh), Color(0.010, 0.004, 0.018, 1.0))

	# Semi-dark overlay on top of stone (keeps it subtle)
	draw_rect(Rect2(0.0, 0.0, sw, sh), Color(0.0, 0.0, 0.0, 0.55))

	# Act title
	var font: Font = ThemeDB.fallback_font
	var act: Dictionary = EnemyStats.get_act_for_wave(GameData.current_wave)
	var title: String = act.get("name", "Act I")
	var title_size: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
	draw_string(font, Vector2(sw * 0.5 - title_size.x * 0.5, 52.0), title,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1.0, 0.85, 0.0, 1.0))

	var sel: int = _get_selectable()
	# In inventory mode: red circle = next wave to play (sel).
	# In read-only TAB mode: red circle = wave currently in progress (current_wave).
	var active: int = sel if not read_only else GameData.current_wave

	# Draw connecting lines first (under nodes)
	for wave: int in range(2, GameData.TOTAL_WAVES + 1):
		var y_from: float = _wave_y(wave - 1)
		var y_to: float = _wave_y(wave)
		var cx: float = sw * 0.5
		var line_col: Color
		if wave <= active:
			line_col = Color(0.30, 0.25, 0.35, 1.0)
		else:
			line_col = Color(0.20, 0.16, 0.28, 1.0)
		draw_line(Vector2(cx, y_from), Vector2(cx, y_to), line_col, 2.5)

	# Draw wave nodes
	for wave: int in range(1, GameData.TOTAL_WAVES + 1):
		var cy: float = _wave_y(wave)
		var cx: float = sw * 0.5
		var center: Vector2 = Vector2(cx, cy)

		var is_completed: bool = wave < active
		var is_active: bool = wave == active
		var is_hovered: bool = wave == _hovered_wave

		# Colors by state
		var fill_col: Color
		var border_col: Color
		var border_width: float
		var icon_col: Color
		var label_col: Color

		if is_completed:
			fill_col = Color(0.08, 0.06, 0.10)
			border_col = Color(0.25, 0.20, 0.25)
			border_width = 2.0
			icon_col = Color(0.30, 0.25, 0.30)
			label_col = Color(0.40, 0.35, 0.40)
		elif is_active:
			fill_col = Color(0.15, 0.05, 0.05)
			var pulse: float = 0.5 + 0.5 * sin(_time * 3.5)
			border_col = Color(0.85 + pulse * 0.15, 0.15, 0.10, 0.85 + pulse * 0.15)
			border_width = 3.0
			icon_col = Color(0.90, 0.80, 0.80)
			label_col = Color(1.0, 0.85, 0.0)
		else:
			fill_col = Color(0.06, 0.04, 0.10)
			border_col = Color(0.35, 0.28, 0.45)
			border_width = 1.5
			icon_col = Color(0.55, 0.45, 0.65)
			label_col = Color(0.55, 0.45, 0.65)

		# Node circle
		draw_circle(center, NODE_RADIUS, fill_col)
		draw_arc(center, NODE_RADIUS, 0.0, TAU, 32, border_col, border_width)

		# Hover glow ring for selectable
		if is_hovered:
			draw_arc(center, NODE_RADIUS + 5.0, 0.0, TAU, 32, Color(0.8, 0.5, 1.0, 0.4), 2.0)

		# Wave type icon
		var wave_type: int = EnemyStats.get_wave_type(wave)
		_draw_wave_icon(center, wave_type, icon_col)

		# Wave label (right of node)
		var label_text: String = "Wave %d" % wave
		if wave_type == EnemyStats.WaveType.BOSS:
			var boss_name: String = EnemyStats.get_boss_name(wave)
			if boss_name != "":
				label_text = "Wave %d  — %s" % [wave, boss_name]
		draw_string(font, Vector2(cx + NODE_RADIUS + 14.0, cy + 6.0),
			label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, label_col)

	# Close button
	var cr: Rect2 = _close_rect()
	draw_rect(cr, Color(0.12, 0.04, 0.04))
	draw_rect(cr, Color(0.55, 0.15, 0.10), false, 1.5)
	draw_line(cr.position + Vector2(8.0, 8.0), cr.end - Vector2(8.0, 8.0), Color(0.9, 0.3, 0.2), 2.0)
	draw_line(cr.position + Vector2(cr.size.x - 8.0, 8.0),
		cr.position + Vector2(8.0, cr.size.y - 8.0), Color(0.9, 0.3, 0.2), 2.0)

	# TAB hint when read-only
	if read_only:
		var hint: String = "Press TAB to close"
		var hint_size: Vector2 = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		draw_string(font, Vector2(sw * 0.5 - hint_size.x * 0.5, sh - 20.0),
			hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.5, 0.4, 0.6, 0.8))

func _draw_wave_icon(center: Vector2, wave_type: int, col: Color) -> void:
	match wave_type:
		EnemyStats.WaveType.FIGHT:
			# Sword: diagonal blade + cross-guard + pommel
			draw_line(center + Vector2(-10.0, -10.0), center + Vector2(10.0, 10.0), col, 2.5)
			draw_line(center + Vector2(-7.0, 3.0), center + Vector2(1.0, -5.0), col, 2.0)
			draw_circle(center + Vector2(10.0, 10.0), 2.5, col)
		EnemyStats.WaveType.BOSS:
			# Skull: dome + jaw + eyes + teeth
			draw_arc(center, 11.0, PI, TAU, 16, col, 2.0)
			draw_line(center + Vector2(-11.0, 0.0), center + Vector2(11.0, 0.0), col, 2.0)
			draw_circle(center + Vector2(-5.0, -3.0), 3.0, col)
			draw_circle(center + Vector2(5.0, -3.0), 3.0, col)
			for ti: int in 3:
				var tx: float = float(ti - 1) * 5.0
				draw_line(center + Vector2(tx, 0.0), center + Vector2(tx, 6.0), col, 1.8)
		EnemyStats.WaveType.SHOP:
			# Coin bag (future)
			draw_circle(center, 10.0, Color(col.r, col.g, col.b, col.a * 0.3))
			draw_arc(center, 10.0, 0.0, TAU, 16, col, 2.0)
			draw_string(ThemeDB.fallback_font, center + Vector2(-4.0, 6.0), "$",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
		EnemyStats.WaveType.SECRET:
			# Question mark
			draw_arc(center + Vector2(0.0, -4.0), 6.0, -TAU * 0.75, TAU * 0.1, 12, col, 2.0)
			draw_circle(center + Vector2(0.0, 5.0), 2.0, col)
