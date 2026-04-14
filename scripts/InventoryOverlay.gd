class_name InventoryOverlay
extends Control

## Inter-wave inventory screen.
## Left: player sprite with idle animation.
## Right: inventory grid with item thumbnails.
## Bottom: "Next Stage" button.

signal next_stage_pressed

var _grid: GridContainer
var _upgrade_grid: GridContainer
var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label
var _tooltip_rarity: Label
var _player_sprite: Node2D
var _empty_label: Label
var _upgrade_empty_label: Label
var _stat_hp: Label
var _stat_atk: Label
var _stat_def: Label
var _stat_spk: Label
var _stat_reg: Label
var _stat_rng: Label
var _act_map: ActMap
var _advance_wave_ctx: bool = false

func _ready() -> void:
	_build_ui()
	refresh()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Stone wall background art
	var stone_bg := _StoneBackground.new()
	stone_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stone_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stone_bg)

	# Main horizontal split
	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left   = 60
	hbox.offset_right  = -60
	hbox.offset_top    = 40
	hbox.offset_bottom = -80
	hbox.add_theme_constant_override("separation", 40)
	add_child(hbox)

	# ── Left: Player character ──────────────────────────────────────────
	var left_panel := VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_stretch_ratio = 0.4
	left_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	left_panel.add_theme_constant_override("separation", 16)
	hbox.add_child(left_panel)

	var hero_title := Label.new()
	hero_title.text = "HERO"
	hero_title.add_theme_font_size_override("font_size", 28)
	hero_title.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(hero_title)

	var sprite_center := CenterContainer.new()
	sprite_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left_panel.add_child(sprite_center)

	var viewport_container := SubViewportContainer.new()
	viewport_container.custom_minimum_size = Vector2(300, 300)
	viewport_container.stretch = true
	sprite_center.add_child(viewport_container)

	var sub_viewport := SubViewport.new()
	sub_viewport.size = Vector2i(300, 300)
	sub_viewport.transparent_bg = true
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(sub_viewport)

	var arena_sprite = load("res://scripts/arena/PlayerArenaSprite.gd").new()
	arena_sprite.position = Vector2(150, 175)
	arena_sprite.scale = Vector2(5, 5)
	sub_viewport.add_child(arena_sprite)
	_player_sprite = arena_sprite

	# Stat labels (vertical list below sprite, hoverable for tooltips)
	var stats_box := VBoxContainer.new()
	stats_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	stats_box.add_theme_constant_override("separation", 4)
	stats_box.name = "StatsBox"
	left_panel.add_child(stats_box)

	_stat_hp = _make_stat_label("HP", Color(0.2, 1.0, 0.2), "Health", "Your life force. If it reaches 0, you die.")
	stats_box.add_child(_stat_hp)

	_stat_atk = _make_stat_label("ATK", Color(1.0, 0.8, 0.2), "Attack", "Damage dealt per strike each turn.")
	stats_box.add_child(_stat_atk)

	_stat_def = _make_stat_label("DEF", Color(0.6, 0.7, 0.85), "Armor", "Reduces incoming damage by a flat amount.")
	stats_box.add_child(_stat_def)

	_stat_spk = _make_stat_label("SPK", Color(0.9, 0.3, 0.7), "Spikes", "Reflects damage back to attackers when hit, reduced by their armor.")
	stats_box.add_child(_stat_spk)

	_stat_reg = _make_stat_label("REG", Color(0.3, 0.9, 0.5), "Regen", "Heals this amount of HP after your turn each round.")
	stats_box.add_child(_stat_reg)

	_stat_rng = _make_stat_label("RNG", Color(0.3, 0.7, 1.0), "Range", "Auto-attack reach. Enemies within this distance are targeted.")
	stats_box.add_child(_stat_rng)

	# ── Divider ─────────────────────────────────────────────────────────
	var divider := ColorRect.new()
	divider.color = Color(0.45, 0.30, 0.10)
	divider.custom_minimum_size = Vector2(2, 0)
	divider.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_child(divider)

	# ── Right: Inventory ────────────────────────────────────────────────
	var right_panel := VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_stretch_ratio = 0.6
	right_panel.add_theme_constant_override("separation", 16)
	hbox.add_child(right_panel)

	var inv_title := Label.new()
	inv_title.text = "INVENTORY"
	inv_title.add_theme_font_size_override("font_size", 28)
	inv_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_panel.add_child(inv_title)

	# Grid
	_grid = GridContainer.new()
	_grid.columns = 5
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(_grid)

	# Empty label (shown when no items)
	_empty_label = Label.new()
	_empty_label.text = "No items yet..."
	_empty_label.add_theme_font_size_override("font_size", 18)
	_empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(_empty_label)

	# ── Upgrades section ────────────────────────────────────────────────
	var upgrade_divider := HSeparator.new()
	upgrade_divider.add_theme_constant_override("separation", 8)
	right_panel.add_child(upgrade_divider)

	var upg_title := Label.new()
	upg_title.text = "UPGRADES"
	upg_title.add_theme_font_size_override("font_size", 28)
	upg_title.add_theme_color_override("font_color", Color(0.9, 0.20, 0.15))
	upg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_panel.add_child(upg_title)

	_upgrade_grid = GridContainer.new()
	_upgrade_grid.columns = 5
	_upgrade_grid.add_theme_constant_override("h_separation", 8)
	_upgrade_grid.add_theme_constant_override("v_separation", 8)
	_upgrade_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(_upgrade_grid)

	_upgrade_empty_label = Label.new()
	_upgrade_empty_label.text = "No blessings yet..."
	_upgrade_empty_label.add_theme_font_size_override("font_size", 18)
	_upgrade_empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_upgrade_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_upgrade_empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(_upgrade_empty_label)

	# ── Bottom: Next Stage button ───────────────────────────────────────
	var btn_bar := CenterContainer.new()
	btn_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	btn_bar.offset_top = -70
	add_child(btn_bar)

	var btn := Button.new()
	btn.text = "VIEW MAP"
	btn.custom_minimum_size = Vector2(280, 58)
	btn.add_theme_font_size_override("font_size", 26)
	btn.pressed.connect(_show_act_map)
	btn_bar.add_child(btn)

	# Act map sub-panel — layered on top of entire overlay
	_act_map = ActMap.new()
	_act_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_act_map.read_only = false
	_act_map.visible = false
	_act_map.wave_selected.connect(_on_act_map_wave_selected)
	_act_map.close_requested.connect(_hide_act_map)
	add_child(_act_map)

	# ── Tooltip (floating, hidden by default) ───────────────────────────
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 100
	# Style
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.10, 1.0)
	sb.border_color = Color(0.65, 0.50, 0.15)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(10)
	_tooltip.add_theme_stylebox_override("panel", sb)
	add_child(_tooltip)

	var tip_vbox := VBoxContainer.new()
	tip_vbox.add_theme_constant_override("separation", 4)
	_tooltip.add_child(tip_vbox)

	_tooltip_rarity = Label.new()
	_tooltip_rarity.add_theme_font_size_override("font_size", 13)
	_tooltip_rarity.visible = false
	tip_vbox.add_child(_tooltip_rarity)

	_tooltip_name = Label.new()
	_tooltip_name.add_theme_font_size_override("font_size", 18)
	_tooltip_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	tip_vbox.add_child(_tooltip_name)

	_tooltip_desc = Label.new()
	_tooltip_desc.add_theme_font_size_override("font_size", 14)
	_tooltip_desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.custom_minimum_size = Vector2(200, 0)
	tip_vbox.add_child(_tooltip_desc)


## Create a hoverable stat label that shows a tooltip.
func _make_stat_label(prefix: String, color: Color, tip_title: String, tip_desc: String) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.mouse_entered.connect(func() -> void:
		_tooltip_name.text = tip_title
		_tooltip_desc.text = tip_desc
		_tooltip.visible = true
		_tooltip.global_position = Vector2(lbl.global_position.x, lbl.global_position.y - 70)
	)
	lbl.mouse_exited.connect(func() -> void:
		_tooltip.visible = false
	)
	return lbl


## Rebuild the grid from current GameData inventory.
func refresh() -> void:
	# Clear grid
	for child in _grid.get_children():
		child.queue_free()

	var inv := GameData.player_inventory
	var slots := inv.get_slots()
	_empty_label.visible = slots.is_empty()
	_grid.visible = not slots.is_empty()

	for slot in slots:
		var thumb := ItemThumbnail.new(slot["id"], slot["count"])
		thumb.hovered.connect(_on_item_hovered)
		thumb.unhovered.connect(_on_item_unhovered)
		_grid.add_child(thumb)

	# Update stat labels (always show all stats on inventory screen)
	_stat_hp.text  = "Health:  %d / %d" % [GameData.player_health, GameData.effective_max_health()]
	_stat_atk.text = "Attack:  %d" % GameData.effective_attack()
	_stat_def.text = "Armor:  %d" % GameData.effective_armor()
	_stat_spk.text = "Spikes:  %d" % GameData.player_spikes
	_stat_reg.text = "Regen:  %d" % GameData.effective_regen()
	_stat_rng.text = "Range:  %d" % int(GameData.effective_attack_range())

	# Populate upgrade grid
	for child in _upgrade_grid.get_children():
		child.queue_free()

	var upg_slots: Array[Dictionary] = GameData.player_upgrades.slots
	_upgrade_empty_label.visible = upg_slots.is_empty()
	_upgrade_grid.visible = not upg_slots.is_empty()

	for slot: Dictionary in upg_slots:
		var thumb := UpgradeThumbnail.new(slot["id"], slot["count"])
		thumb.hovered.connect(_on_upgrade_hovered)
		thumb.unhovered.connect(_on_upgrade_unhovered)
		_upgrade_grid.add_child(thumb)


func _on_item_hovered(item_def: Dictionary, gpos: Vector2) -> void:
	_tooltip_rarity.visible = false
	_tooltip_name.text = item_def.get("name", "")
	_tooltip_desc.text = item_def.get("description", "")
	_tooltip.visible = true
	_tooltip.global_position = Vector2(gpos.x, gpos.y - 70)

func _on_item_unhovered() -> void:
	_tooltip.visible = false

func _on_upgrade_hovered(upgrade_def: Dictionary, gpos: Vector2) -> void:
	var rarity: int = upgrade_def.get("rarity", 0)
	_tooltip_rarity.text = Inventory.RARITY_NAMES[rarity]
	_tooltip_rarity.add_theme_color_override("font_color", Inventory.RARITY_COLORS[rarity])
	_tooltip_rarity.visible = true
	_tooltip_name.text = upgrade_def.get("name", "")
	_tooltip_desc.text = upgrade_def.get("description", "")
	_tooltip.visible = true
	_tooltip.global_position = Vector2(gpos.x, gpos.y - 85)

func _on_upgrade_unhovered() -> void:
	_tooltip.visible = false

func set_advance_context(advance: bool) -> void:
	_advance_wave_ctx = advance

func _show_act_map() -> void:
	# Compute selectable wave at click-time using the freshest context
	var sel: int = GameData.current_wave + 1 if _advance_wave_ctx else GameData.current_wave
	_act_map.selectable_wave = sel
	_act_map.visible = true

func _hide_act_map() -> void:
	_act_map.visible = false

func _on_act_map_wave_selected(_wave_num: int) -> void:
	_hide_act_map()
	next_stage_pressed.emit()


# ── Stone wall background art ─────────────────────────────────────────────────
class _StoneBackground extends Control:
	var _time: float = 0.0
	var _particles: Array = []
	var _stone_noise: Array = []
	var _cracks: Array[PackedVector2Array] = []

	func _ready() -> void:
		# Precompute per-cell noise using a deterministic formula
		for row in 8:
			for col in 13:
				var n: float = fmod(absf(sin(float(row * 31 + col * 17)) * 4371.5), 1.0)
				_stone_noise.append(n)

		# Precompute crack paths with fixed seed
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		for ci in 8:
			var path := PackedVector2Array()
			var x := float(ci * 210 + 120)
			var y := float(rng.randi_range(40, 180))
			path.append(Vector2(x, y))
			for _j in 4:
				x += rng.randf_range(-55.0, 75.0)
				y += rng.randf_range(55.0, 160.0)
				path.append(Vector2(x, y))
			_cracks.append(path)

		# Init floating rune particles
		for _i in 15:
			_particles.append(_new_rune(true))

	func _new_rune(scatter: bool) -> Dictionary:
		var x   := randf_range(80.0, 1840.0)
		var ml  := randf_range(4.0, 9.0)
		var y   := randf_range(80.0, 900.0) if scatter else 1050.0
		return {
			"pos":      Vector2(x, y),
			"vel":      Vector2(randf_range(-5.0, 5.0), randf_range(-18.0, -8.0)),
			"life":     randf_range(0.0, ml) if scatter else ml,
			"max_life": ml,
			"sym":      randi() % 4,
		}

	func _process(delta: float) -> void:
		_time += delta
		for i in _particles.size():
			var p: Dictionary = _particles[i]
			p["life"] -= delta
			if p["life"] <= 0.0:
				_particles[i] = _new_rune(false)
				continue
			p["pos"] += p["vel"] * delta
			_particles[i] = p
		queue_redraw()

	func _draw() -> void:
		var sw := size.x
		var sh := size.y

		# 1. Base dark fill
		draw_rect(Rect2(0.0, 0.0, sw, sh), Color(0.025, 0.008, 0.035, 1.0))

		# 2. Stone block grid (13×8)
		var cols := 13
		var rows := 8
		var cw   := sw / cols
		var ch   := sh / rows
		for row in rows:
			for col in cols:
				var idx := row * cols + col
				var n: float = _stone_noise[idx] if idx < _stone_noise.size() else 0.5
				var bcol := Color(0.042 + n * 0.022, 0.012 + n * 0.006, 0.038 + n * 0.014)
				draw_rect(Rect2(col * cw + 2.0, row * ch + 2.0, cw - 4.0, ch - 4.0), bcol)
			# Horizontal grout line
			draw_rect(Rect2(0.0, row * ch, sw, 2.0), Color(0.010, 0.004, 0.018, 1.0))
		# Vertical grout lines
		for col in cols:
			draw_rect(Rect2(col * cw, 0.0, 2.0, sh), Color(0.010, 0.004, 0.018, 1.0))

		# 3. Glowing cracks
		for crack in _cracks:
			var pulse: float = 0.14 + sin(_time * 1.7 + crack[0].x * 0.004) * 0.07
			draw_polyline(crack, Color(0.75, 0.22, 0.0, pulse), 2.5)
			draw_polyline(crack, Color(1.0, 0.52, 0.10, pulse * 0.45), 1.0)

		# 4. Bottom ember glow
		for gi in 8:
			var gy: float = sh - float(gi) * 32.0
			var ga: float = maxf(0.28 - gi * 0.034, 0.0)
			draw_rect(Rect2(0.0, gy, sw, 36.0), Color(0.55, 0.08, 0.0, ga))

		# 5. Corner rune marks
		var corners := [
			Vector2(55.0, 55.0), Vector2(sw - 55.0, 55.0),
			Vector2(55.0, sh - 55.0), Vector2(sw - 55.0, sh - 55.0),
		]
		for cn in corners:
			var pulse: float = 0.55 + sin(_time * 1.3 + cn.x * 0.001) * 0.12
			var rcol := Color(0.65, 0.40, 0.10, pulse)
			draw_arc(cn, 28.0, 0.0, TAU, 16, rcol, 1.8)
			draw_line(cn + Vector2(-22.0, 0.0), cn + Vector2(22.0, 0.0), rcol, 1.5)
			draw_line(cn + Vector2(0.0, -22.0), cn + Vector2(0.0, 22.0), rcol, 1.5)
			draw_arc(cn, 14.0, 0.0, TAU, 12, Color(rcol.r, rcol.g, rcol.b, rcol.a * 0.5), 1.0)

		# 6. Floating rune particles
		for p in _particles:
			var alpha: float = (p["life"] / p["max_life"]) * 0.65
			var sz    := 5.5
			var pos: Vector2 = p["pos"]
			var rcol := Color(0.58, 0.34, 0.10, alpha)
			match int(p["sym"]):
				0: # Cross rune
					draw_line(pos + Vector2(-sz, 0.0), pos + Vector2(sz, 0.0), rcol, 1.2)
					draw_line(pos + Vector2(0.0, -sz), pos + Vector2(0.0, sz), rcol, 1.2)
				1: # Triangle rune
					var t0 := pos + Vector2(0.0, -sz)
					var t1 := pos + Vector2(sz * 0.87, sz * 0.5)
					var t2 := pos + Vector2(-sz * 0.87, sz * 0.5)
					draw_polyline(PackedVector2Array([t0, t1, t2, t0]), rcol, 1.0)
				2: # Diamond rune
					draw_line(pos + Vector2(-sz, 0.0), pos + Vector2(0.0, -sz), rcol, 1.0)
					draw_line(pos + Vector2(0.0, -sz), pos + Vector2(sz, 0.0), rcol, 1.0)
					draw_line(pos + Vector2(sz, 0.0),  pos + Vector2(0.0, sz),  rcol, 1.0)
					draw_line(pos + Vector2(0.0, sz),  pos + Vector2(-sz, 0.0), rcol, 1.0)
				3: # Circle rune with centre dot
					draw_arc(pos, sz, 0.0, TAU, 12, rcol, 1.0)
					draw_circle(pos, 1.8, rcol)
