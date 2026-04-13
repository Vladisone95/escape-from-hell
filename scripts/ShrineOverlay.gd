class_name ShrineOverlay
extends Control

signal upgrade_chosen(upgrade_id: String)

var _upgrade_data: Array[Dictionary] = []  # [{id, rarity}, ...]
var _upgrade_slots: Array[Control] = []
var _selected_index: int = -1

var _items_container: HBoxContainer
var _accept_btn: Button
var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label
var _tooltip_rarity: Label
var _title_label: Label

func _ready() -> void:
	_build_ui()

func show_upgrades(rolled: Array[Dictionary]) -> void:
	_upgrade_data = []
	for d: Dictionary in rolled:
		_upgrade_data.append(d)
	_selected_index = -1
	_accept_btn.visible = false
	_accept_btn.disabled = true
	_tooltip.visible = false

	for child in _items_container.get_children():
		child.queue_free()
	_upgrade_slots.clear()

	_title_label.text = "The Shrine offers..."
	visible = true

	# Create upgrade slots
	var rarity_labels: Array[Label] = []
	for i in range(_upgrade_data.size()):
		var uid: String = _upgrade_data[i]["id"]
		var rarity: int = _upgrade_data[i]["rarity"]
		var def: Dictionary = Upgrades.UPGRADES[uid]
		var slot := _create_upgrade_slot(i, uid, rarity, def)
		_items_container.add_child(slot)
		_upgrade_slots.append(slot)

		slot.modulate = Color(1, 1, 1, 0)
		slot.scale = Vector2(0.5, 0.5)
		slot.pivot_offset = Vector2(120, 150) / 2.0
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var rlbl := Label.new()
		rlbl.text = Inventory.RARITY_NAMES[rarity]
		var rcol: Color = Inventory.RARITY_COLORS[rarity]
		rlbl.add_theme_font_size_override("font_size", 20)
		rlbl.add_theme_color_override("font_color", rcol)
		rlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rlbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		rlbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rlbl.modulate = Color(1, 1, 1, 0)
		slot.add_child(rlbl)
		rarity_labels.append(rlbl)

	# Stagger reveal
	for i in range(_upgrade_data.size()):
		var slot := _upgrade_slots[i]
		var rlbl := rarity_labels[i]
		var base_delay := i * 0.75

		var tw := create_tween()
		tw.tween_interval(base_delay)
		tw.tween_property(rlbl, "modulate", Color.WHITE, 0.15)
		tw.parallel().tween_property(slot, "scale", Vector2(0.7, 0.7), 0.15) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.35)
		tw.tween_property(rlbl, "modulate", Color(1, 1, 1, 0), 0.15)
		tw.parallel().tween_property(slot, "modulate", Color.WHITE, 0.2)
		tw.parallel().tween_property(slot, "scale", Vector2(1.18, 1.18), 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(slot, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func() -> void:
			slot.mouse_filter = Control.MOUSE_FILTER_STOP
			rlbl.queue_free()
		)

	var total_reveal := _upgrade_data.size() * 0.75 + 0.8
	var tw_ui := create_tween()
	tw_ui.tween_interval(total_reveal)
	tw_ui.tween_callback(func() -> void:
		_title_label.text = "Choose your blessing!"
		_accept_btn.visible = true
		_accept_btn.disabled = (_selected_index < 0)
	)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.02, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 80
	vbox.offset_right = -80
	vbox.offset_top = 60
	vbox.offset_bottom = -30
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	add_child(vbox)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(0.9, 0.20, 0.15))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	var items_center := CenterContainer.new()
	items_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(items_center)

	_items_container = HBoxContainer.new()
	_items_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_items_container.add_theme_constant_override("separation", 40)
	_items_container.custom_minimum_size = Vector2(0, 160)
	items_center.add_child(_items_container)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var btn_center := CenterContainer.new()
	vbox.add_child(btn_center)

	_accept_btn = Button.new()
	_accept_btn.text = "ACCEPT"
	_accept_btn.custom_minimum_size = Vector2(240, 58)
	_accept_btn.add_theme_font_size_override("font_size", 26)
	_accept_btn.visible = false
	_accept_btn.disabled = true
	_accept_btn.pressed.connect(_on_accept_pressed)
	btn_center.add_child(_accept_btn)

	# Tooltip
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 100
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.04, 0.06, 1.0)
	sb.border_color = Color(0.70, 0.20, 0.15)
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
	tip_vbox.add_child(_tooltip_rarity)

	_tooltip_name = Label.new()
	_tooltip_name.add_theme_font_size_override("font_size", 18)
	_tooltip_name.add_theme_color_override("font_color", Color(0.9, 0.20, 0.15))
	tip_vbox.add_child(_tooltip_name)

	_tooltip_desc = Label.new()
	_tooltip_desc.add_theme_font_size_override("font_size", 14)
	_tooltip_desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.custom_minimum_size = Vector2(220, 0)
	tip_vbox.add_child(_tooltip_desc)


func _create_upgrade_slot(index: int, uid: String, rarity: int, def: Dictionary) -> Control:
	var rarity_col: Color = Inventory.RARITY_COLORS[rarity]
	var rarity_name: String = Inventory.RARITY_NAMES[rarity]

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(120, 150)
	wrapper.mouse_filter = Control.MOUSE_FILTER_STOP

	# Card background (reuse ChestOverlay inner class pattern)
	var card_bg := _InfernalCard.new()
	card_bg.rarity = rarity
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(card_bg)

	# Rarity aura
	var aura := _RarityAura.new()
	aura.rarity = rarity
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aura.offset_left = -14
	aura.offset_top = -14
	aura.offset_right = 14
	aura.offset_bottom = 14
	wrapper.add_child(aura)

	# Particles
	var particles := _ParticleField.new()
	particles.rarity = rarity
	particles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	particles.offset_left = -18
	particles.offset_top = -18
	particles.offset_right = 18
	particles.offset_bottom = 18
	wrapper.add_child(particles)

	# Upgrade thumbnail
	var thumb := UpgradeThumbnail.new(uid, 1)
	thumb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	thumb.offset_left = -32
	thumb.offset_right = 32
	thumb.offset_top = -38
	thumb.offset_bottom = 26
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(thumb)

	# Name label
	var name_lbl := Label.new()
	name_lbl.text = def["name"]
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", rarity_col)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -22
	name_lbl.offset_bottom = -4
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(name_lbl)

	# Rarity tag
	var rarity_tag := Label.new()
	rarity_tag.text = rarity_name
	rarity_tag.add_theme_font_size_override("font_size", 11)
	rarity_tag.add_theme_color_override("font_color", Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.85))
	rarity_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_tag.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	rarity_tag.offset_top = 4
	rarity_tag.offset_bottom = 18
	rarity_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(rarity_tag)

	# Selection border
	var sel_border := ColorRect.new()
	sel_border.name = "SelectBorder"
	sel_border.color = Color(1.0, 0.20, 0.10, 0.0)
	sel_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sel_border.offset_left = -4
	sel_border.offset_top = -4
	sel_border.offset_right = 4
	sel_border.offset_bottom = 4
	sel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(sel_border)

	# Hover / click
	var _hover_ref := [null]
	wrapper.mouse_entered.connect(func() -> void:
		_tooltip_rarity.text = rarity_name
		_tooltip_rarity.add_theme_color_override("font_color", rarity_col)
		_tooltip_name.text = def["name"]
		_tooltip_desc.text = def["description"]
		_tooltip.visible = true
		_tooltip.global_position = Vector2(wrapper.global_position.x, wrapper.global_position.y - 85)
		if _hover_ref[0] and _hover_ref[0].is_valid():
			_hover_ref[0].kill()
		_hover_ref[0] = create_tween()
		var target_scale := Vector2(1.15, 1.15) if _selected_index == index else Vector2(1.08, 1.08)
		_hover_ref[0].tween_property(wrapper, "scale", target_scale, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	wrapper.mouse_exited.connect(func() -> void:
		_tooltip.visible = false
		if _hover_ref[0] and _hover_ref[0].is_valid():
			_hover_ref[0].kill()
		_hover_ref[0] = create_tween()
		var target_scale := Vector2(1.12, 1.12) if _selected_index == index else Vector2.ONE
		if _selected_index >= 0 and _selected_index != index:
			target_scale = Vector2(0.93, 0.93)
		_hover_ref[0].tween_property(wrapper, "scale", target_scale, 0.15) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	wrapper.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_upgrade(index)
	)

	return wrapper


func _select_upgrade(index: int) -> void:
	_selected_index = index
	_accept_btn.disabled = false

	for i in range(_upgrade_slots.size()):
		var slot := _upgrade_slots[i]
		var border := slot.find_child("SelectBorder") as ColorRect
		var is_sel := (i == index)
		var rarity_col: Color = Inventory.RARITY_COLORS[_upgrade_data[i]["rarity"]]

		var tw := create_tween().set_parallel(true)
		if is_sel:
			tw.tween_property(slot, "scale", Vector2(1.15, 1.15), 0.18) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(slot, "modulate", Color.WHITE, 0.15)
			if border:
				border.color = Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.45)
		else:
			tw.tween_property(slot, "scale", Vector2(0.93, 0.93), 0.2) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(slot, "modulate", Color(0.55, 0.55, 0.55, 1.0), 0.2)
			if border:
				border.color = Color(1.0, 0.20, 0.10, 0.0)


func _on_accept_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _upgrade_data.size():
		return
	var uid: String = _upgrade_data[_selected_index]["id"]
	visible = false
	upgrade_chosen.emit(uid)


# ═══════════════════════════════════════════════════════════════════════════
# INNER CLASSES (same pattern as ChestOverlay)
# ═══════════════════════════════════════════════════════════════════════════

class _InfernalCard extends Control:
	var rarity: int = Inventory.Rarity.COMMON
	var _time: float = 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var rcol: Color = Inventory.RARITY_COLORS.get(rarity, Color.WHITE)
		draw_rect(rect, Color(0.08, 0.04, 0.06))
		var inner := rect.grow(-3)
		draw_rect(inner, Color(0.12, 0.07, 0.09))
		var ember_pulse := (sin(_time * 2.5) + 1.0) / 2.0
		for row in range(5):
			var frac := row / 5.0
			var y := size.y - (5 - row) * 4.0
			var alpha := (0.04 + ember_pulse * 0.04) * (1.0 - frac)
			draw_rect(Rect2(4, y, size.x - 8, 4), Color(0.8, 0.15, 0.05, alpha))
		for row in range(3):
			var frac := row / 3.0
			var y := row * 3.0
			var alpha := (0.03 + ember_pulse * 0.03) * (1.0 - frac)
			draw_rect(Rect2(4, y, size.x - 8, 3), Color(0.8, 0.15, 0.05, alpha))
		draw_line(Vector2(8, size.y * 0.3), Vector2(18, size.y * 0.55), Color(0.04, 0.02, 0.02, 0.5), 1.0)
		draw_line(Vector2(size.x - 10, size.y * 0.25), Vector2(size.x - 20, size.y * 0.5), Color(0.04, 0.02, 0.02, 0.5), 1.0)
		draw_rect(rect, Color(0.25, 0.12, 0.08), false, 2.0)
		var accent := rect.grow(-2)
		var border_alpha := 0.25 + ember_pulse * 0.15
		draw_rect(accent, Color(rcol.r, rcol.g, rcol.b, border_alpha), false, 1.0)
		var dot_alpha := 0.3 + ember_pulse * 0.4
		var dot_col := Color(0.9, 0.15, 0.05, dot_alpha)
		var corner_sz := 3.0
		draw_circle(Vector2(corner_sz + 1, corner_sz + 1), corner_sz, dot_col)
		draw_circle(Vector2(size.x - corner_sz - 1, corner_sz + 1), corner_sz, dot_col)
		draw_circle(Vector2(corner_sz + 1, size.y - corner_sz - 1), corner_sz, dot_col)
		draw_circle(Vector2(size.x - corner_sz - 1, size.y - corner_sz - 1), corner_sz, dot_col)
		if rarity >= Inventory.Rarity.RARE:
			var wisp_alpha := 0.15 + ember_pulse * 0.2
			var wisp_col := Color(rcol.r, rcol.g * 0.6, 0.1, wisp_alpha)
			for cx in [8.0, size.x - 8.0]:
				var base_y := size.y - 6.0
				for fi in range(3):
					var flicker := sin(_time * (5.0 + fi * 1.3) + cx) * 2.0
					var fy := base_y - fi * 5.0 + flicker
					var fr := 2.5 - fi * 0.6
					draw_circle(Vector2(cx, fy), fr, wisp_col)
		var div_y := size.y - 26.0
		draw_line(Vector2(6, div_y), Vector2(size.x - 6, div_y), Color(0.3, 0.12, 0.08, 0.5), 1.0)


class _RarityAura extends Control:
	var rarity: int = Inventory.Rarity.COMMON
	var _time: float = 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var col: Color = Inventory.RARITY_COLORS.get(rarity, Color.WHITE)
		match rarity:
			Inventory.Rarity.COMMON:
				var pulse := (sin(_time * 2.0) + 1.0) / 2.0
				var alpha := 0.06 + pulse * 0.08
				draw_rect(rect, Color(col.r, col.g, col.b, alpha))
				draw_rect(rect, Color(col.r, col.g, col.b, 0.15 + pulse * 0.1), false, 1.5)
			Inventory.Rarity.RARE:
				var pulse := (sin(_time * 3.0) + 1.0) / 2.0
				var alpha := 0.10 + pulse * 0.15
				draw_rect(rect, Color(col.r, col.g, col.b, alpha))
				draw_rect(rect, Color(col.r, col.g, col.b, 0.3 + pulse * 0.25), false, 2.0)
				var inner := rect.grow(-3)
				draw_rect(inner, Color(col.r, col.g, col.b, 0.08 + pulse * 0.10), false, 1.0)
			Inventory.Rarity.EPIC:
				var pulse := (sin(_time * 4.0) + 1.0) / 2.0
				var pulse2 := (sin(_time * 6.5 + 1.0) + 1.0) / 2.0
				var alpha := 0.14 + pulse * 0.20
				draw_rect(rect, Color(col.r, col.g, col.b, alpha))
				draw_rect(rect, Color(col.r, col.g, col.b, 0.4 + pulse * 0.4), false, 2.5)
				var inner := rect.grow(-4)
				draw_rect(inner, Color(col.r * 1.2, col.g * 0.8, col.b, 0.15 + pulse2 * 0.25), false, 1.5)
				var flash: float = max(0.0, sin(_time * 8.0)) * 0.4
				if flash > 0.1:
					var flash_col := Color(col.r, col.g, col.b, flash)
					draw_circle(rect.position + Vector2(3, 3), 4.0, flash_col)
					draw_circle(rect.position + Vector2(rect.size.x - 3, 3), 4.0, flash_col)
					draw_circle(rect.position + Vector2(3, rect.size.y - 3), 4.0, flash_col)
					draw_circle(rect.position + Vector2(rect.size.x - 3, rect.size.y - 3), 4.0, flash_col)
			Inventory.Rarity.MYTHICAL:
				var pulse := (sin(_time * 5.0) + 1.0) / 2.0
				var pulse2 := (sin(_time * 7.0 + 2.0) + 1.0) / 2.0
				var alpha := 0.18 + pulse * 0.25
				draw_rect(rect, Color(col.r, col.g, col.b, alpha))
				draw_rect(rect, Color(1.0, 0.5, 0.05, 0.06 + pulse2 * 0.10))
				draw_rect(rect, Color(col.r, col.g, col.b, 0.5 + pulse * 0.5), false, 3.0)
				var mid := rect.grow(-3)
				draw_rect(mid, Color(1.0, 0.9, 0.5, 0.25 + pulse2 * 0.35), false, 2.0)
				var inner := rect.grow(-6)
				draw_rect(inner, Color(col.r, col.g, col.b, 0.15 + pulse * 0.2), false, 1.0)
				var cx := rect.size.x / 2.0
				var cy := rect.size.y / 2.0
				var center := Vector2(cx, cy)
				for angle_i in range(6):
					var a := _time * 1.5 + angle_i * TAU / 6.0
					var ray_len := 20.0 + pulse * 10.0
					var ray_alpha := 0.15 + pulse2 * 0.2
					var endpoint := center + Vector2(cos(a), sin(a)) * ray_len
					draw_line(center, endpoint, Color(1.0, 0.9, 0.4, ray_alpha), 1.5)


class _ParticleField extends Control:
	var rarity: int = Inventory.Rarity.COMMON
	var _particles: Array[Dictionary] = []
	var _time: float = 0.0
	var _initialized: bool = false

	func _process(delta: float) -> void:
		_time += delta
		if not _initialized:
			_initialized = true
			_spawn_particles()
		_update_particles(delta)
		queue_redraw()

	func _spawn_particles() -> void:
		_particles.clear()
		var count := 0
		match rarity:
			Inventory.Rarity.COMMON:   count = 3
			Inventory.Rarity.RARE:     count = 7
			Inventory.Rarity.EPIC:     count = 12
			Inventory.Rarity.MYTHICAL: count = 18
		for _i in range(count):
			_particles.append(_new_particle())

	func _new_particle() -> Dictionary:
		var col: Color = Inventory.RARITY_COLORS.get(rarity, Color.WHITE)
		var p := {}
		p["x"] = randf() * size.x
		p["y"] = randf() * size.y
		p["lifetime"] = 0.0
		p["max_life"] = 1.5 + randf() * 2.5
		match rarity:
			Inventory.Rarity.COMMON:
				p["vx"] = (randf() - 0.5) * 6.0
				p["vy"] = -randf() * 8.0 - 2.0
				p["size"] = 1.0 + randf() * 1.5
				p["color"] = Color(col.r, col.g, col.b, 0.3 + randf() * 0.2)
				p["type"] = "dot"
			Inventory.Rarity.RARE:
				p["vx"] = (randf() - 0.5) * 12.0
				p["vy"] = -randf() * 18.0 - 8.0
				p["size"] = 1.5 + randf() * 2.0
				p["color"] = Color(col.r * 0.8 + randf() * 0.2, col.g * 0.8 + randf() * 0.2, col.b, 0.4 + randf() * 0.3)
				p["type"] = "sparkle"
			Inventory.Rarity.EPIC:
				p["vx"] = (randf() - 0.5) * 16.0
				p["vy"] = -randf() * 22.0 - 10.0
				p["size"] = 2.0 + randf() * 2.5
				p["color"] = Color(col.r + randf() * 0.15, col.g, col.b + randf() * 0.1, 0.5 + randf() * 0.3)
				p["type"] = ["sparkle", "ring", "dot"][randi() % 3]
				p["orbit"] = randf() * TAU
				p["orbit_speed"] = (randf() - 0.5) * 4.0
			Inventory.Rarity.MYTHICAL:
				p["vx"] = (randf() - 0.5) * 22.0
				p["vy"] = -randf() * 30.0 - 12.0
				p["size"] = 2.5 + randf() * 3.0
				var hue_shift := randf() * 0.1
				p["color"] = Color(col.r, col.g - hue_shift, col.b - hue_shift * 2.0, 0.6 + randf() * 0.3)
				p["type"] = ["sparkle", "ring", "star", "star"][randi() % 4]
				p["orbit"] = randf() * TAU
				p["orbit_speed"] = (randf() - 0.5) * 6.0
				p["trail"] = true
		return p

	func _update_particles(delta: float) -> void:
		for i in range(_particles.size()):
			var p := _particles[i]
			p["lifetime"] += delta
			p["x"] += p["vx"] * delta
			p["y"] += p["vy"] * delta
			if p.has("orbit"):
				p["orbit"] += p["orbit_speed"] * delta
				p["x"] += cos(p["orbit"]) * 12.0 * delta
				p["y"] += sin(p["orbit"]) * 8.0 * delta
			if p["lifetime"] >= p["max_life"] or p["y"] < -10 or p["x"] < -10 or p["x"] > size.x + 10:
				_particles[i] = _new_particle()
				if randf() > 0.5:
					_particles[i]["y"] = size.y + randf() * 5.0
				else:
					_particles[i]["x"] = randf() * size.x
					_particles[i]["y"] = size.y * 0.5 + randf() * size.y * 0.5

	func _draw() -> void:
		for p: Dictionary in _particles:
			var life_frac: float = p["lifetime"] / p["max_life"]
			var fade: float
			if life_frac < 0.15:
				fade = life_frac / 0.15
			elif life_frac > 0.7:
				fade = 1.0 - (life_frac - 0.7) / 0.3
			else:
				fade = 1.0
			var col: Color = p["color"]
			col.a *= fade
			if col.a < 0.01:
				continue
			var pos := Vector2(p["x"], p["y"])
			var sz: float = p["size"]
			var ptype: String = p["type"]
			match ptype:
				"dot":
					draw_circle(pos, sz, col)
				"sparkle":
					var arm := sz * 1.8
					var thin := sz * 0.4
					draw_line(pos - Vector2(arm, 0), pos + Vector2(arm, 0), col, thin)
					draw_line(pos - Vector2(0, arm), pos + Vector2(0, arm), col, thin)
					draw_circle(pos, sz * 0.5, Color(col.r, col.g, col.b, col.a * 1.3))
				"ring":
					draw_arc(pos, sz * 1.2, 0.0, TAU, 12, col, 1.0)
					draw_circle(pos, sz * 0.3, col)
				"star":
					var arm_len := sz * 2.2
					for si in range(6):
						var a := si * TAU / 6.0 + _time * 2.0
						var tip := pos + Vector2(cos(a), sin(a)) * arm_len
						draw_line(pos, tip, col, sz * 0.3)
					draw_circle(pos, sz * 0.6, Color(min(col.r * 1.3, 1.0), min(col.g * 1.3, 1.0), col.b, col.a))
			if p.get("trail", false) and life_frac > 0.1:
				var trail_col := Color(col.r, col.g, col.b, col.a * 0.35)
				var trail_offset := Vector2(-p["vx"], -p["vy"]).normalized() * sz * 2.5
				draw_circle(pos + trail_offset, sz * 0.6, trail_col)
				draw_circle(pos + trail_offset * 1.8, sz * 0.35, Color(trail_col.r, trail_col.g, trail_col.b, trail_col.a * 0.5))
