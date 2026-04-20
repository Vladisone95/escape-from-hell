extends Control

var wave_label: Label
var log_display: RichTextLabel
var _log_lines: Array[String] = []

# Bottom-right health ring + dash indicator
var _ring_widget: Control
var _stats_widget: Control
var _current_hp: int = 100
var _max_hp: int = 100

# Boss health bar
var _boss_panel: Control
var _boss_bar: Control  # custom draw for the health bar
var _boss_name_label: Label
var _boss_hp_label: Label
var _boss_hp: int = 0
var _boss_max_hp: int = 1
var _dash_cooldown_remaining: float = 0.0
var _dash_cooldown_total: float = 10.0
var _player_ref: WeakRef = WeakRef.new()
var _segment_flash: float = 0.0
var _flash_frac: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()

func _process(_delta: float) -> void:
	# Poll dash cooldown from player
	var player: CharacterBody2D = _player_ref.get_ref() as CharacterBody2D
	if player and player.has_method("get_dash_cooldown_remaining"):
		_dash_cooldown_remaining = player.get_dash_cooldown_remaining()
		_dash_cooldown_total = player.get_dash_cooldown_total()
	if _ring_widget:
		_ring_widget.queue_redraw()
	if _segment_flash > 0.0:
		_segment_flash = maxf(0.0, _segment_flash - _delta * 2.2)
		if _boss_bar:
			_boss_bar.queue_redraw()

func set_player(player: CharacterBody2D) -> void:
	_player_ref = weakref(player)

func _build_ui() -> void:
	# Wave counter (top-center)
	wave_label = Label.new()
	wave_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	wave_label.offset_top = 10
	wave_label.add_theme_font_size_override("font_size", 22)
	wave_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wave_label)

	# Combat log (bottom)
	log_display = RichTextLabel.new()
	log_display.bbcode_enabled = true
	log_display.scroll_following = true
	log_display.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	log_display.offset_top = -90
	log_display.offset_left = 16
	log_display.offset_right = -16
	log_display.add_theme_font_size_override("normal_font_size", 13)
	log_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(log_display)

	# Boss health bar panel (bottom half of screen, hidden by default)
	_boss_panel = Control.new()
	_boss_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_boss_panel.offset_top = -220
	_boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_panel.visible = false
	add_child(_boss_panel)

	_boss_name_label = Label.new()
	_boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_boss_name_label.offset_top = 10
	_boss_name_label.offset_bottom = 70
	_boss_name_label.add_theme_font_size_override("font_size", 42)
	_boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.1))
	_boss_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_panel.add_child(_boss_name_label)

	_boss_bar = Control.new()
	_boss_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_boss_bar.offset_left = -300
	_boss_bar.offset_right = 300
	_boss_bar.offset_top = 30
	_boss_bar.offset_bottom = 80
	_boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_bar.draw.connect(_draw_boss_bar)
	_boss_panel.add_child(_boss_bar)

	_boss_hp_label = Label.new()
	_boss_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_hp_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_boss_hp_label.offset_top = 80
	_boss_hp_label.offset_bottom = 110
	_boss_hp_label.offset_left = -150
	_boss_hp_label.offset_right = 150
	_boss_hp_label.add_theme_font_size_override("font_size", 20)
	_boss_hp_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	_boss_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_panel.add_child(_boss_hp_label)

	# Bottom-right health ring + dash widget
	_ring_widget = Control.new()
	_ring_widget.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_ring_widget.offset_left = -160
	_ring_widget.offset_top = -160
	_ring_widget.offset_right = -16
	_ring_widget.offset_bottom = -16
	_ring_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_widget.draw.connect(_draw_ring_widget)
	add_child(_ring_widget)

	# Stats panel (bottom-left)
	_stats_widget = Control.new()
	_stats_widget.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_stats_widget.offset_left = 12
	_stats_widget.offset_right = 155
	_stats_widget.offset_top = -244
	_stats_widget.offset_bottom = -98
	_stats_widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_widget.draw.connect(_draw_stats_widget)
	add_child(_stats_widget)

func _draw_ring_widget() -> void:
	var widget: Control = _ring_widget
	var center := widget.size * 0.5
	var outer_radius: float = minf(widget.size.x, widget.size.y) * 0.5 - 4.0
	var ring_width: float = 8.0
	var inner_radius: float = outer_radius - ring_width

	# Health fraction
	var hp_frac: float = clampf(float(_current_hp) / float(maxi(_max_hp, 1)), 0.0, 1.0)

	# Background ring (dark gray)
	_draw_arc_filled(widget, center, inner_radius, outer_radius, 0.0, TAU, Color(0.15, 0.15, 0.15, 0.7), 64)

	# Green health arc — starts at top (-PI/2), goes clockwise
	if hp_frac > 0.0:
		var start_angle: float = -PI / 2.0
		var end_angle: float = start_angle + TAU * hp_frac
		var green_color := Color(0.2, 0.85, 0.2)
		if hp_frac < 0.3:
			green_color = Color(0.85, 0.2, 0.2)  # red when low
		elif hp_frac < 0.6:
			green_color = Color(0.85, 0.7, 0.1)  # yellow when medium
		_draw_arc_filled(widget, center, inner_radius, outer_radius, start_angle, end_angle, green_color, 64)

	# HP text in the ring area
	var font: Font = ThemeDB.fallback_font
	var hp_text: String = "%d" % _current_hp
	var font_size: int = 14
	var text_size: Vector2 = font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	widget.draw_string(font, Vector2(center.x - text_size.x * 0.5, center.y - outer_radius + ring_width + 14), hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.9, 0.9, 0.9))

	# Dash icon area — inside the ring
	var icon_center := center + Vector2(0, 6)
	var dash_on_cooldown: bool = _dash_cooldown_remaining > 0.1
	var icon_color := Color(1.0, 1.0, 1.0) if not dash_on_cooldown else Color(0.4, 0.4, 0.4)

	# Draw boot icon
	_draw_boot_icon(widget, icon_center + Vector2(-8, 0), icon_color)

	# Draw wind gust lines beside the boot
	var gust_color := Color(0.7, 0.85, 1.0) if not dash_on_cooldown else Color(0.3, 0.35, 0.4)
	_draw_wind_gust(widget, icon_center + Vector2(18, -4), gust_color)

	# Cooldown timer text below icon
	if dash_on_cooldown:
		var cd_text: String = "%.1f" % _dash_cooldown_remaining
		var cd_size: Vector2 = font.get_string_size(cd_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		widget.draw_string(font, Vector2(center.x - cd_size.x * 0.5, icon_center.y + 30), cd_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.9, 0.6, 0.2))
	else:
		var ready_text: String = "READY"
		var ready_size: Vector2 = font.get_string_size(ready_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
		widget.draw_string(font, Vector2(center.x - ready_size.x * 0.5, icon_center.y + 28), ready_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.3, 0.9, 0.3))

func _draw_arc_filled(widget: Control, center: Vector2, r_inner: float, r_outer: float, start: float, end: float, color: Color, segments: int) -> void:
	var pts := PackedVector2Array()
	var angle_span: float = end - start
	# Outer arc forward
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var a: float = start + t * angle_span
		pts.append(center + Vector2(cos(a), sin(a)) * r_outer)
	# Inner arc backward
	for i in range(segments, -1, -1):
		var t: float = float(i) / float(segments)
		var a: float = start + t * angle_span
		pts.append(center + Vector2(cos(a), sin(a)) * r_inner)
	if pts.size() >= 3:
		widget.draw_polygon(pts, PackedColorArray([color]))

func _draw_boot_icon(widget: Control, pos: Vector2, color: Color) -> void:
	# Simplified boot shape — side view
	# Boot shaft (vertical part)
	var shaft := PackedVector2Array([
		pos + Vector2(-5, -16),
		pos + Vector2(3, -16),
		pos + Vector2(3, -2),
		pos + Vector2(-5, -2),
	])
	widget.draw_polygon(shaft, PackedColorArray([color]))

	# Boot sole/foot (horizontal part extending forward)
	var sole := PackedVector2Array([
		pos + Vector2(-6, -2),
		pos + Vector2(12, -2),
		pos + Vector2(14, 2),
		pos + Vector2(14, 5),
		pos + Vector2(-6, 5),
		pos + Vector2(-7, 2),
	])
	widget.draw_polygon(sole, PackedColorArray([color]))

	# Boot cuff (top detail)
	var cuff := PackedVector2Array([
		pos + Vector2(-7, -16),
		pos + Vector2(5, -16),
		pos + Vector2(5, -13),
		pos + Vector2(-7, -13),
	])
	widget.draw_polygon(cuff, PackedColorArray([color * 0.8]))

	# Sole detail line
	widget.draw_line(pos + Vector2(-6, 3), pos + Vector2(14, 3), color * 0.6, 1.5)

func _draw_wind_gust(widget: Control, pos: Vector2, color: Color) -> void:
	# Three wavy horizontal lines representing wind/speed
	for i in 3:
		var y_off: float = float(i) * 7.0 - 7.0
		var start_pt := pos + Vector2(0, y_off)
		var line_len: float = 14.0 - float(i) * 2.0
		# Slightly curved line
		var pts := PackedVector2Array()
		for s in 8:
			var t: float = float(s) / 7.0
			var x: float = t * line_len
			var y: float = sin(t * PI * 1.5) * 2.0
			pts.append(start_pt + Vector2(x, y))
		widget.draw_polyline(pts, color, 1.5)

# ── Stats panel drawing ─────────────────────────────────────

func _draw_stats_widget() -> void:
	var w: Control = _stats_widget
	var sz: Vector2 = w.size

	# Panel background
	w.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.06, 0.04, 0.04, 0.8))
	w.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.55, 0.18, 0.08, 0.6), false, 1.0)

	var font: Font = ThemeDB.fallback_font
	var fs: int = 14
	var text_col := Color(0.92, 0.88, 0.82)
	var ix: float = 14.0
	var tx: float = 34.0
	var y0: float = 20.0
	var rh: float = 26.0

	# Attack
	_draw_icon_swords(w, Vector2(ix, y0), Color(1.0, 0.5, 0.15))
	w.draw_string(font, Vector2(tx, y0 + 5), str(GameData.effective_attack()), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

	# Attack Speed
	var y1: float = y0 + rh
	_draw_icon_sword_wind(w, Vector2(ix, y1), Color(0.6, 0.85, 1.0))
	var aps: float = 1.0 / maxf(GameData.effective_attack_cooldown(), 0.01)
	w.draw_string(font, Vector2(tx, y1 + 5), "%.1f/s" % aps, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

	# Movement Speed
	var y2: float = y0 + rh * 2
	_draw_icon_boot(w, Vector2(ix, y2), Color(0.4, 0.9, 0.35))
	w.draw_string(font, Vector2(tx, y2 + 5), str(int(GameData.effective_speed())), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

	# Armor
	var y3: float = y0 + rh * 3
	_draw_icon_shield(w, Vector2(ix, y3), Color(0.55, 0.65, 0.95))
	w.draw_string(font, Vector2(tx, y3 + 5), str(GameData.effective_armor()), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

	# Range
	var y4: float = y0 + rh * 4
	_draw_icon_range(w, Vector2(ix, y4), Color(1.0, 0.75, 0.3))
	w.draw_string(font, Vector2(tx, y4 + 5), str(int(GameData.effective_attack_range())), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, text_col)

func _draw_icon_swords(w: Control, c: Vector2, color: Color) -> void:
	w.draw_line(c + Vector2(-6, 7), c + Vector2(6, -7), color, 2.0)
	w.draw_line(c + Vector2(6, 7), c + Vector2(-6, -7), color, 2.0)
	w.draw_circle(c + Vector2(6, -7), 1.2, Color(1, 1, 1, 0.4))
	w.draw_circle(c + Vector2(-6, -7), 1.2, Color(1, 1, 1, 0.4))

func _draw_icon_sword_wind(w: Control, c: Vector2, color: Color) -> void:
	w.draw_line(c + Vector2(-2, 8), c + Vector2(-2, -8), color, 2.0)
	w.draw_line(c + Vector2(-5, 2), c + Vector2(1, 2), color * 0.7, 1.5)
	w.draw_circle(c + Vector2(-2, 8), 1.5, color * 0.6)
	for i in 3:
		var yo: float = float(i) * 5.0 - 5.0
		var pts := PackedVector2Array()
		for s in 5:
			var t: float = float(s) / 4.0
			pts.append(c + Vector2(3 + t * 8.0, yo + sin(t * PI) * 1.5))
		w.draw_polyline(pts, color * 0.5, 1.0)

func _draw_icon_boot(w: Control, c: Vector2, color: Color) -> void:
	var shaft := PackedVector2Array([
		c + Vector2(-3, -7), c + Vector2(2, -7),
		c + Vector2(2, 1), c + Vector2(-3, 1),
	])
	w.draw_polygon(shaft, PackedColorArray([color]))
	var sole := PackedVector2Array([
		c + Vector2(-4, 1), c + Vector2(7, 1),
		c + Vector2(8, 4), c + Vector2(-4, 4),
	])
	w.draw_polygon(sole, PackedColorArray([color * 0.8]))

func _draw_icon_shield(w: Control, c: Vector2, color: Color) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0, -8), c + Vector2(7, -5),
		c + Vector2(7, 1), c + Vector2(0, 8),
		c + Vector2(-7, 1), c + Vector2(-7, -5),
	])
	w.draw_polygon(pts, PackedColorArray([color]))
	w.draw_polyline(PackedVector2Array([
		c + Vector2(0, -5), c + Vector2(4, -3),
		c + Vector2(4, 0), c + Vector2(0, 5),
	]), Color(1, 1, 1, 0.2), 1.0)

func _draw_icon_range(w: Control, c: Vector2, color: Color) -> void:
	w.draw_arc(c, 7.0, -0.5, 0.5, 12, color, 1.5)
	w.draw_arc(c, 4.0, -0.5, 0.5, 8, color * 0.7, 1.5)
	w.draw_line(c, c + Vector2(8, 0), color * 0.5, 1.0)
	w.draw_circle(c + Vector2(8, 0), 1.5, color)

func update_hp(current: int, mx: int) -> void:
	_current_hp = current
	_max_hp = mx

func update_wave(wave: int) -> void:
	wave_label.text = "WAVE %d / %d" % [wave, GameData.TOTAL_WAVES]

func update_stats() -> void:
	if _stats_widget:
		_stats_widget.queue_redraw()

func log_msg(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > 5:
		_log_lines = _log_lines.slice(-5)
	log_display.clear()
	log_display.append_text("\n".join(_log_lines))

func clear_log() -> void:
	_log_lines.clear()
	log_display.clear()

# ── Boss health bar ──────────────────────────────────────────

func show_boss_bar(boss_name: String, current: int, mx: int) -> void:
	_boss_hp = current
	_boss_max_hp = mx
	_boss_name_label.text = boss_name
	_boss_hp_label.text = "%d / %d" % [current, mx]
	_boss_panel.visible = true
	_boss_bar.queue_redraw()

func update_boss_bar(current: int, mx: int) -> void:
	_boss_hp = current
	_boss_max_hp = mx
	_boss_hp_label.text = "%d / %d" % [current, mx]
	_boss_bar.queue_redraw()
	if current <= 0:
		_boss_panel.visible = false

func hide_boss_bar() -> void:
	_boss_panel.visible = false

func flash_boss_segment(order_index: int) -> void:
	_flash_frac = float(9 - order_index) / 10.0
	_segment_flash = 1.0
	if _boss_bar:
		_boss_bar.queue_redraw()

func _draw_boss_bar() -> void:
	var w: Control = _boss_bar
	var bar_size: Vector2 = w.size
	var frac: float = clampf(float(_boss_hp) / float(maxi(_boss_max_hp, 1)), 0.0, 1.0)

	# Background
	w.draw_rect(Rect2(Vector2.ZERO, bar_size), Color(0.1, 0.05, 0.05, 0.85))

	# Border
	w.draw_rect(Rect2(Vector2.ZERO, bar_size), Color(0.6, 0.15, 0.1), false, 2.0)

	# Health fill
	var fill_width: float = bar_size.x * frac
	var fill_color: Color
	if frac > 0.5:
		fill_color = Color(0.8, 0.15, 0.1)
	elif frac > 0.25:
		fill_color = Color(0.9, 0.5, 0.1)
	else:
		fill_color = Color(0.95, 0.2, 0.2)
	w.draw_rect(Rect2(Vector2.ZERO, Vector2(fill_width, bar_size.y)), fill_color)

	# Inner glow line at top of fill
	if fill_width > 2.0:
		w.draw_line(Vector2(1, 2), Vector2(fill_width - 1, 2), Color(1.0, 0.6, 0.3, 0.4), 2.0)

	# Segment dividers every 10% — prominently marked
	for i in range(1, 10):
		var x: float = bar_size.x * (float(i) / 10.0)
		w.draw_line(Vector2(x, 0), Vector2(x, bar_size.y), Color(0.0, 0.0, 0.0, 0.95), 3.5)
		w.draw_line(Vector2(x - 1.5, 0), Vector2(x - 1.5, bar_size.y), Color(1.0, 0.55, 0.1, 0.55), 1.5)
		w.draw_line(Vector2(x + 1.0, 1), Vector2(x + 1.0, bar_size.y - 1), Color(1.0, 0.3, 0.05, 0.2), 1.0)
		# Small tick mark above the bar to make thresholds obvious
		w.draw_line(Vector2(x, -5), Vector2(x, 0), Color(1.0, 0.55, 0.15, 0.8), 2.0)

	# Flash effect when a segment threshold is triggered
	if _segment_flash > 0.0:
		var fx: float = bar_size.x * _flash_frac
		var alpha: float = _segment_flash
		w.draw_line(Vector2(fx, 0), Vector2(fx, bar_size.y), Color(1.0, 0.9, 0.2, alpha * 0.95), 5.0)
		w.draw_line(Vector2(fx - 3, 0), Vector2(fx - 3, bar_size.y), Color(1.0, 0.6, 0.1, alpha * 0.5), 2.0)
		w.draw_line(Vector2(fx + 3, 0), Vector2(fx + 3, bar_size.y), Color(1.0, 0.6, 0.1, alpha * 0.5), 2.0)
		# Tick glow
		w.draw_line(Vector2(fx, -8), Vector2(fx, 0), Color(1.0, 0.9, 0.2, alpha), 3.0)
