class_name InventoryOverlay
extends Control

## Inter-wave inventory screen.
## Left: player sprite with idle animation.
## Right: inventory grid with item thumbnails.
## Bottom: "Next Stage" button.

signal next_stage_pressed

var _grid: GridContainer
var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label
var _player_sprite: PlayerSprite
var _empty_label: Label
var _stat_hp: Label
var _stat_atk: Label
var _stat_def: Label
var _stat_spk: Label
var _stat_reg: Label

func _ready() -> void:
	_build_ui()
	refresh()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Dark overlay background
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.04, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

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

	_player_sprite = PlayerSprite.new()
	sprite_center.add_child(_player_sprite)

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

	# ── Bottom: Next Stage button ───────────────────────────────────────
	var btn_bar := CenterContainer.new()
	btn_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	btn_bar.offset_top = -70
	add_child(btn_bar)

	var btn := Button.new()
	btn.text = "NEXT STAGE"
	btn.custom_minimum_size = Vector2(280, 58)
	btn.add_theme_font_size_override("font_size", 26)
	btn.pressed.connect(func(): next_stage_pressed.emit())
	btn_bar.add_child(btn)

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
	_stat_def.text = "Armor:  %d" % GameData.player_armor
	_stat_spk.text = "Spikes:  %d" % GameData.player_spikes
	_stat_reg.text = "Regen:  %d" % GameData.effective_regen()


func _on_item_hovered(item_def: Dictionary, gpos: Vector2) -> void:
	_tooltip_name.text = item_def.get("name", "")
	_tooltip_desc.text = item_def.get("description", "")
	_tooltip.visible = true
	# Position above the thumbnail
	_tooltip.global_position = Vector2(gpos.x, gpos.y - 70)

func _on_item_unhovered() -> void:
	_tooltip.visible = false
