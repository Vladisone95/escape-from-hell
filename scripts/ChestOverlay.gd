class_name ChestOverlay
extends Control

## Animated chest loot screen.
## 1. Chest appears closed
## 2. Trembles on hover
## 3. Opens slowly on click with anticipation
## 4. 3 random items pop out into selection slots
## 5. Player hovers for tooltips, clicks to select, "Loot" to confirm

signal item_looted(item_id: String)

# ── State machine ────────────────────────────────────────────────────────
enum State { CLOSED, OPENING, ITEMS_SHOWN }
var _state: State = State.CLOSED

# ── Chest animation properties ───────────────────────────────────────────
var _chest_node: Control
var _chest_shake: float = 0.0
var _chest_lid_open: float = 0.0  # 0 = closed, 1 = fully open
var _chest_hovered: bool = false
var _shake_tween: Tween

# ── Item slots ───────────────────────────────────────────────────────────
var _item_ids: Array[String] = []
var _item_rarities: Array[int] = []
var _item_slots: Array[Control] = []
var _selected_index: int = -1

# ── UI refs ──────────────────────────────────────────────────────────────
var _items_container: HBoxContainer
var _loot_btn: Button
var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label
var _tooltip_rarity: Label
var _title_label: Label

func _ready() -> void:
	_build_ui()

func show_chest() -> void:
	_state = State.CLOSED
	_chest_lid_open = 0.0
	_chest_shake = 0.0
	_chest_hovered = false
	_selected_index = -1
	_loot_btn.visible = false
	_loot_btn.disabled = true
	_items_container.visible = false
	_tooltip.visible = false
	_chest_node.visible = true
	_chest_node.mouse_filter = Control.MOUSE_FILTER_STOP
	_title_label.text = "A chest appears..."
	visible = true
	SoundManager.play("chest_appear")

	# Clear old item slots
	for child in _items_container.get_children():
		child.queue_free()
	_item_slots.clear()

	# Roll items from pool
	_roll_items()

func _roll_items() -> void:
	_item_ids.clear()
	_item_rarities.clear()

	# Build available pool: exclude items at max stacks
	# Group by rarity for the two-step roll
	var by_rarity: Dictionary = {}  # rarity int -> Array[String]
	for item_id: String in Inventory.ITEMS:
		var def: Dictionary = Inventory.ITEMS[item_id]
		var current_stack := GameData.player_inventory.get_stack(item_id)
		if current_stack < def["max_stack"]:
			var r: int = def["rarity"]
			if not by_rarity.has(r):
				by_rarity[r] = []
			by_rarity[r].append(item_id)

	# Pick up to 3 unique items
	for _pick in range(3):
		# Step 1: Roll a rarity from those that still have items available
		var available_rarities: Array[int] = []
		var rarity_weights: Array[int] = []
		for r: int in by_rarity:
			if by_rarity[r].size() > 0:
				available_rarities.append(r)
				rarity_weights.append(Inventory.RARITY_WEIGHTS[r])

		if available_rarities.is_empty():
			break

		var total := 0
		for w: int in rarity_weights:
			total += w
		var roll := randi() % total
		var cumulative := 0
		var rolled_rarity: int = available_rarities[0]
		for i in range(available_rarities.size()):
			cumulative += rarity_weights[i]
			if roll < cumulative:
				rolled_rarity = available_rarities[i]
				break

		# Step 2: Pick a random item from that rarity
		var rarity_pool: Array = by_rarity[rolled_rarity]
		var idx := randi() % rarity_pool.size()
		var picked: String = rarity_pool[idx]

		_item_ids.append(picked)
		_item_rarities.append(rolled_rarity)

		# Remove from pool so it can't appear again in this chest
		rarity_pool.remove_at(idx)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.01, 0.03, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main layout
	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 80
	vbox.offset_right = -80
	vbox.offset_top = 30
	vbox.offset_bottom = -30
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)

	# Title
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 32)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	# Chest area
	var chest_center := CenterContainer.new()
	chest_center.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(chest_center)

	_chest_node = _ChestDrawer.new()
	_chest_node.overlay = self
	_chest_node.custom_minimum_size = Vector2(160, 140)
	_chest_node.mouse_filter = Control.MOUSE_FILTER_STOP
	_chest_node.mouse_entered.connect(_on_chest_mouse_entered)
	_chest_node.mouse_exited.connect(_on_chest_mouse_exited)
	_chest_node.gui_input.connect(_on_chest_input)
	chest_center.add_child(_chest_node)

	# Items container (hidden until chest opens)
	var items_center := CenterContainer.new()
	items_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(items_center)

	_items_container = HBoxContainer.new()
	_items_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_items_container.add_theme_constant_override("separation", 40)
	_items_container.visible = false
	_items_container.custom_minimum_size = Vector2(0, 160)
	items_center.add_child(_items_container)

	# Spacer between items and button
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)

	# Loot button
	var btn_center := CenterContainer.new()
	vbox.add_child(btn_center)

	_loot_btn = Button.new()
	_loot_btn.text = "LOOT"
	_loot_btn.custom_minimum_size = Vector2(240, 58)
	_loot_btn.add_theme_font_size_override("font_size", 26)
	_loot_btn.visible = false
	_loot_btn.disabled = true
	_loot_btn.pressed.connect(_on_loot_pressed)
	btn_center.add_child(_loot_btn)

	# Tooltip
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.z_index = 100
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
	tip_vbox.add_child(_tooltip_rarity)

	_tooltip_name = Label.new()
	_tooltip_name.add_theme_font_size_override("font_size", 18)
	_tooltip_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	tip_vbox.add_child(_tooltip_name)

	_tooltip_desc = Label.new()
	_tooltip_desc.add_theme_font_size_override("font_size", 14)
	_tooltip_desc.add_theme_color_override("font_color", Color(0.82, 0.82, 0.82))
	_tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc.custom_minimum_size = Vector2(220, 0)
	tip_vbox.add_child(_tooltip_desc)


# ── Chest hover / click ─────────────────────────────────────────────────
func _on_chest_mouse_entered() -> void:
	if _state != State.CLOSED:
		return
	_chest_hovered = true
	_start_tremble()

func _on_chest_mouse_exited() -> void:
	_chest_hovered = false
	_stop_tremble()

func _start_tremble() -> void:
	_stop_tremble()
	_shake_tween = create_tween().set_loops()
	_shake_tween.tween_property(self, "_chest_shake", 3.0, 0.04)
	_shake_tween.tween_property(self, "_chest_shake", -3.0, 0.04)
	_shake_tween.tween_property(self, "_chest_shake", 2.0, 0.03)
	_shake_tween.tween_property(self, "_chest_shake", -2.0, 0.03)

func _stop_tremble() -> void:
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = null
	_chest_shake = 0.0

func _on_chest_input(event: InputEvent) -> void:
	if _state != State.CLOSED:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_chest()

func _open_chest() -> void:
	_state = State.OPENING
	_stop_tremble()
	_chest_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_label.text = "Opening..."

	# Slow open animation with anticipation
	var tw := create_tween()
	# Initial creak -- slow start
	tw.tween_property(self, "_chest_lid_open", 0.15, 0.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Pause for tension
	tw.tween_property(self, "_chest_lid_open", 0.12, 0.25) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Second push
	tw.tween_property(self, "_chest_lid_open", 0.45, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Another small pause
	tw.tween_property(self, "_chest_lid_open", 0.40, 0.15) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	# Final burst open
	tw.tween_property(self, "_chest_lid_open", 1.0, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.finished.connect(_on_chest_opened)

func _on_chest_opened() -> void:
	_state = State.ITEMS_SHOWN
	SoundManager.play("chest_open")
	_chest_node.visible = false
	_items_container.visible = true
	# Reveal items one at a time with stagger
	_spawn_item_slots_staggered()


# ── Item slots ───────────────────────────────────────────────────────────
func _spawn_item_slots_staggered() -> void:
	for child in _items_container.get_children():
		child.queue_free()
	_item_slots.clear()

	# Pre-create all slots (hidden) so HBoxContainer lays them out
	var rarity_labels: Array[Label] = []
	for i in range(_item_ids.size()):
		var item_id: String = _item_ids[i]
		var rarity: int = _item_rarities[i]
		var def: Dictionary = Inventory.ITEMS[item_id]
		var slot := _create_item_slot(i, item_id, rarity, def)
		_items_container.add_child(slot)
		_item_slots.append(slot)

		# Start fully hidden
		slot.modulate = Color(1, 1, 1, 0)
		slot.scale = Vector2(0.5, 0.5)
		slot.pivot_offset = Vector2(120, 150) / 2.0
		# Disable input until revealed
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Rarity label centered over the slot (will flash before item reveals)
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

	# Stagger reveal: each item gets ~0.7s apart
	for i in range(_item_ids.size()):
		var slot := _item_slots[i]
		var rlbl := rarity_labels[i]
		var rarity: int = _item_rarities[i]
		var _rcol: Color = Inventory.RARITY_COLORS[rarity]
		var base_delay := i * 0.75

		# Phase 1: Rarity label flashes in
		var tw_rarity := create_tween()
		tw_rarity.tween_interval(base_delay)
		# Scale the rarity label big then shrink
		tw_rarity.tween_property(rlbl, "modulate", Color.WHITE, 0.15)
		tw_rarity.parallel().tween_property(slot, "scale", Vector2(0.7, 0.7), 0.15) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw_rarity.tween_interval(0.35)
		# Phase 2: Fade rarity label out, reveal the actual item card
		tw_rarity.tween_property(rlbl, "modulate", Color(1, 1, 1, 0), 0.15)
		tw_rarity.parallel().tween_property(slot, "modulate", Color.WHITE, 0.2)
		tw_rarity.parallel().tween_property(slot, "scale", Vector2(1.18, 1.18), 0.22) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_rarity.tween_property(slot, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Enable input after reveal
		var _reveal_idx: int = i
		tw_rarity.tween_callback(func() -> void:
			slot.mouse_filter = Control.MOUSE_FILTER_STOP
			rlbl.queue_free()
			SoundManager.play("item_reveal", 1.0 + _reveal_idx * 0.26)
		)

	# Show title and loot button after all items revealed
	var total_reveal := _item_ids.size() * 0.75 + 0.8
	var tw_ui := create_tween()
	tw_ui.tween_interval(total_reveal)
	tw_ui.tween_callback(func() -> void:
		_title_label.text = "Choose your loot!"
		_loot_btn.visible = true
		_loot_btn.disabled = (_selected_index < 0)
	)


func _create_item_slot(index: int, item_id: String, rarity: int, def: Dictionary) -> Control:
	var rarity_col: Color = Inventory.RARITY_COLORS[rarity]
	var rarity_name: String = Inventory.RARITY_NAMES[rarity]

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(120, 150)
	wrapper.mouse_filter = Control.MOUSE_FILTER_STOP

	# ── Card background (infernal style) ─────────────────────────────
	var card_bg := _InfernalCard.new()
	card_bg.rarity = rarity
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(card_bg)

	# Rarity aura (behind card, extends outward)
	var aura := _RarityAura.new()
	aura.rarity = rarity
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aura.offset_left = -14
	aura.offset_top = -14
	aura.offset_right = 14
	aura.offset_bottom = 14
	wrapper.add_child(aura)

	# Particle effects
	var particles := _ParticleField.new()
	particles.rarity = rarity
	particles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	particles.offset_left = -18
	particles.offset_top = -18
	particles.offset_right = 18
	particles.offset_bottom = 18
	wrapper.add_child(particles)

	# Item thumbnail (centered in upper portion of card)
	var thumb := ItemThumbnail.new(item_id, 1)
	thumb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	thumb.offset_left = -32
	thumb.offset_right = 32
	thumb.offset_top = -38
	thumb.offset_bottom = 26
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(thumb)

	# Item name label at bottom of card
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

	# Rarity tag at top of card
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

	# Selection border (hidden by default)
	var sel_border := ColorRect.new()
	sel_border.name = "SelectBorder"
	sel_border.color = Color(1.0, 0.85, 0.0, 0.0)
	sel_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sel_border.offset_left = -4
	sel_border.offset_top = -4
	sel_border.offset_right = 4
	sel_border.offset_bottom = 4
	sel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(sel_border)

	# Input handling — hover animation (array wrapper so lambdas can mutate)
	var _hover_ref := [null]  # _hover_ref[0] = Tween
	wrapper.mouse_entered.connect(func() -> void:
		_tooltip_rarity.text = rarity_name
		_tooltip_rarity.add_theme_color_override("font_color", rarity_col)
		_tooltip_name.text = def["name"]
		_tooltip_desc.text = def["description"]
		_tooltip.visible = true
		_tooltip.global_position = Vector2(wrapper.global_position.x, wrapper.global_position.y - 85)
		# Hover scale bump
		if _hover_ref[0] and _hover_ref[0].is_valid():
			_hover_ref[0].kill()
		_hover_ref[0] = create_tween()
		var target_scale := Vector2(1.15, 1.15) if _selected_index == index else Vector2(1.08, 1.08)
		_hover_ref[0].tween_property(wrapper, "scale", target_scale, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
	wrapper.mouse_exited.connect(func() -> void:
		_tooltip.visible = false
		# Return to base scale
		if _hover_ref[0] and _hover_ref[0].is_valid():
			_hover_ref[0].kill()
		_hover_ref[0] = create_tween()
		var target_scale := Vector2(1.12, 1.12) if _selected_index == index else Vector2.ONE
		# Dim unselected items if something is selected
		if _selected_index >= 0 and _selected_index != index:
			target_scale = Vector2(0.93, 0.93)
		_hover_ref[0].tween_property(wrapper, "scale", target_scale, 0.15) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	wrapper.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_item(index)
	)

	return wrapper


func _select_item(index: int) -> void:
	_selected_index = index
	_loot_btn.disabled = false

	for i in range(_item_slots.size()):
		var slot := _item_slots[i]
		var border := slot.find_child("SelectBorder") as ColorRect
		var is_sel := (i == index)
		var rarity_col: Color = Inventory.RARITY_COLORS[_item_rarities[i]]

		# Animate scale and brightness
		var tw := create_tween().set_parallel(true)
		if is_sel:
			# Selected: pop up, full brightness, colored border
			tw.tween_property(slot, "scale", Vector2(1.15, 1.15), 0.18) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(slot, "modulate", Color.WHITE, 0.15)
			if border:
				border.color = Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.45)
		else:
			# Unselected: shrink slightly, dim
			tw.tween_property(slot, "scale", Vector2(0.93, 0.93), 0.2) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(slot, "modulate", Color(0.55, 0.55, 0.55, 1.0), 0.2)
			if border:
				border.color = Color(1.0, 0.85, 0.0, 0.0)


func _on_loot_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _item_ids.size():
		return
	var item_id: String = _item_ids[_selected_index]
	SoundManager.play("item_loot")
	visible = false
	item_looted.emit(item_id)


# ── Process (for chest redraw) ───────────────────────────────────────────
func _process(_delta: float) -> void:
	if _state != State.ITEMS_SHOWN:
		_chest_node.queue_redraw()


# ── Chest drawing ────────────────────────────────────────────────────────
func _draw_chest(node: Control) -> void:
	var w := node.size.x
	var h := node.size.y
	var cx := w / 2.0
	var shake := _chest_shake

	# Colors
	var wood_dark := Color(0.35, 0.18, 0.08)
	var wood_mid := Color(0.50, 0.28, 0.10)
	var wood_light := Color(0.62, 0.38, 0.14)
	var metal := Color(0.55, 0.50, 0.35)
	var metal_light := Color(0.72, 0.65, 0.45)
	var lock_col := Color(0.70, 0.60, 0.20)
	var glow_col := Color(1.0, 0.85, 0.2, 0.0)

	var lid_open := _chest_lid_open

	# -- Body (bottom half)
	var body_top := h * 0.42
	var body_rect := Rect2(shake + 10, body_top, w - 20, h - body_top - 8)
	node.draw_rect(body_rect, wood_dark)
	node.draw_rect(Rect2(shake + 14, body_top + 4, body_rect.size.x - 8, body_rect.size.y - 8), wood_mid)
	for py in [body_top + 16, body_top + 30]:
		node.draw_line(Vector2(shake + 14, py), Vector2(shake + w - 14, py), wood_dark, 1.5)
	for band_x in [shake + 30, shake + w - 34]:
		node.draw_rect(Rect2(band_x, body_top, 4, body_rect.size.y), metal)

	# -- Lid
	var lid_h := h * 0.32
	var lid_y := body_top - lid_h * (1.0 - lid_open * 0.7)
	var lid_squeeze := lid_open * 0.15
	var lid_rect := Rect2(shake + 10, lid_y, w - 20, lid_h * (1.0 - lid_squeeze))

	if lid_open < 1.0:
		node.draw_rect(lid_rect, wood_dark)
		node.draw_rect(lid_rect.grow(-3), wood_light)
		for band_x in [shake + 30, shake + w - 34]:
			node.draw_rect(Rect2(band_x, lid_rect.position.y, 4, lid_rect.size.y), metal)
		node.draw_rect(Rect2(lid_rect.position.x, lid_rect.position.y, lid_rect.size.x, 3), metal_light)
	else:
		var open_lid_rect := Rect2(shake + 14, body_top - lid_h * 0.85, w - 28, 8)
		node.draw_rect(open_lid_rect, wood_light)
		node.draw_rect(Rect2(open_lid_rect.position.x, open_lid_rect.position.y, open_lid_rect.size.x, 2), metal_light)

	# -- Lock / keyhole
	if lid_open < 0.5:
		var lock_x := shake + cx - 6
		var lock_y := body_top - 4
		node.draw_rect(Rect2(lock_x, lock_y, 12, 10), lock_col)
		node.draw_rect(Rect2(lock_x + 2, lock_y + 2, 8, 6), Color(0.25, 0.18, 0.08))
		node.draw_circle(Vector2(shake + cx, lock_y + 5), 2.0, lock_col)

	# -- Glow when opening
	if lid_open > 0.3:
		var glow_alpha := (lid_open - 0.3) / 0.7 * 0.6
		glow_col.a = glow_alpha
		var glow_rect := Rect2(shake + 16, body_top - 6, w - 32, 10)
		node.draw_rect(glow_rect, glow_col)
		if lid_open > 0.6:
			var ray_alpha := (lid_open - 0.6) / 0.4 * 0.4
			var ray_col := Color(1.0, 0.9, 0.3, ray_alpha)
			for rx in [-20.0, 0.0, 20.0]:
				node.draw_line(
					Vector2(shake + cx + rx * 0.3, body_top - 4),
					Vector2(shake + cx + rx, body_top - 30 * lid_open),
					ray_col, 2.0
				)

	# -- Base shadow
	node.draw_rect(Rect2(shake + 6, h - 8, w - 12, 6), Color(0.0, 0.0, 0.0, 0.3))


# ═══════════════════════════════════════════════════════════════════════════
# INNER CLASSES
# ═══════════════════════════════════════════════════════════════════════════

class _ChestDrawer extends Control:
	var overlay: ChestOverlay
	func _draw() -> void:
		if not overlay:
			return
		overlay._draw_chest(self)


# ── Infernal Card Background ───────────────────────────────────────────
# Dark charred card with ember edges, subtle cracks, and flame-licked corners.
class _InfernalCard extends Control:
	var rarity: int = Inventory.Rarity.COMMON
	var _time: float = 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		var rcol: Color = Inventory.RARITY_COLORS.get(rarity, Color.WHITE)

		# Card fill — dark charred
		draw_rect(rect, Color(0.08, 0.04, 0.06))
		# Slightly lighter inner
		var inner := rect.grow(-3)
		draw_rect(inner, Color(0.12, 0.07, 0.09))

		# Subtle ember gradient at bottom
		var ember_pulse := (sin(_time * 2.5) + 1.0) / 2.0
		for row in range(5):
			var frac := row / 5.0
			var y := size.y - (5 - row) * 4.0
			var alpha := (0.04 + ember_pulse * 0.04) * (1.0 - frac)
			draw_rect(Rect2(4, y, size.x - 8, 4), Color(0.8, 0.25, 0.05, alpha))

		# Subtle ember gradient at top
		for row in range(3):
			var frac := row / 3.0
			var y := row * 3.0
			var alpha := (0.03 + ember_pulse * 0.03) * (1.0 - frac)
			draw_rect(Rect2(4, y, size.x - 8, 3), Color(0.8, 0.25, 0.05, alpha))

		# Cracks / veins (dark lines)
		draw_line(Vector2(8, size.y * 0.3), Vector2(18, size.y * 0.55), Color(0.04, 0.02, 0.02, 0.5), 1.0)
		draw_line(Vector2(size.x - 10, size.y * 0.25), Vector2(size.x - 20, size.y * 0.5), Color(0.04, 0.02, 0.02, 0.5), 1.0)
		draw_line(Vector2(18, size.y * 0.55), Vector2(12, size.y * 0.75), Color(0.04, 0.02, 0.02, 0.35), 0.8)

		# Outer border — dark iron
		draw_rect(rect, Color(0.25, 0.15, 0.10), false, 2.0)
		# Inner accent border with rarity tint
		var accent := rect.grow(-2)
		var border_alpha := 0.25 + ember_pulse * 0.15
		draw_rect(accent, Color(rcol.r, rcol.g, rcol.b, border_alpha), false, 1.0)

		# Corner ember dots (animated)
		var dot_alpha := 0.3 + ember_pulse * 0.4
		var dot_col := Color(0.9, 0.35, 0.05, dot_alpha)
		var corner_sz := 3.0
		draw_circle(Vector2(corner_sz + 1, corner_sz + 1), corner_sz, dot_col)
		draw_circle(Vector2(size.x - corner_sz - 1, corner_sz + 1), corner_sz, dot_col)
		draw_circle(Vector2(corner_sz + 1, size.y - corner_sz - 1), corner_sz, dot_col)
		draw_circle(Vector2(size.x - corner_sz - 1, size.y - corner_sz - 1), corner_sz, dot_col)

		# Flame wisps at corners for rare+
		if rarity >= Inventory.Rarity.RARE:
			var wisp_alpha := 0.15 + ember_pulse * 0.2
			var wisp_col := Color(rcol.r, rcol.g * 0.6, 0.1, wisp_alpha)
			# Bottom corners: small flame shapes
			for cx in [8.0, size.x - 8.0]:
				var base_y := size.y - 6.0
				for fi in range(3):
					var flicker := sin(_time * (5.0 + fi * 1.3) + cx) * 2.0
					var fy := base_y - fi * 5.0 + flicker
					var fr := 2.5 - fi * 0.6
					draw_circle(Vector2(cx, fy), fr, wisp_col)

		# Horizontal divider line above name area
		var div_y := size.y - 26.0
		draw_line(Vector2(6, div_y), Vector2(size.x - 6, div_y), Color(0.3, 0.15, 0.10, 0.5), 1.0)


# ── Rarity Aura ─────────────────────────────────────────────────────────
# Draws a glowing background rectangle whose color, intensity, and
# animation speed scale with rarity.
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
				# Subtle gray background, gentle pulse
				var pulse := (sin(_time * 2.0) + 1.0) / 2.0
				var alpha := 0.06 + pulse * 0.08
				draw_rect(rect, Color(col.r, col.g, col.b, alpha))
				draw_rect(rect, Color(col.r, col.g, col.b, 0.15 + pulse * 0.1), false, 1.5)

			Inventory.Rarity.RARE:
				# Blue glow, moderate pulse
				var pulse := (sin(_time * 3.0) + 1.0) / 2.0
				var alpha := 0.10 + pulse * 0.15
				draw_rect(rect, Color(col.r, col.g, col.b, alpha))
				draw_rect(rect, Color(col.r, col.g, col.b, 0.3 + pulse * 0.25), false, 2.0)
				# Inner border
				var inner := rect.grow(-3)
				draw_rect(inner, Color(col.r, col.g, col.b, 0.08 + pulse * 0.10), false, 1.0)

			Inventory.Rarity.EPIC:
				# Purple glow, strong double pulse
				var pulse := (sin(_time * 4.0) + 1.0) / 2.0
				var pulse2 := (sin(_time * 6.5 + 1.0) + 1.0) / 2.0
				var alpha := 0.14 + pulse * 0.20
				draw_rect(rect, Color(col.r, col.g, col.b, alpha))
				# Outer border
				draw_rect(rect, Color(col.r, col.g, col.b, 0.4 + pulse * 0.4), false, 2.5)
				# Inner border (offset phase)
				var inner := rect.grow(-4)
				draw_rect(inner, Color(col.r * 1.2, col.g * 0.8, col.b, 0.15 + pulse2 * 0.25), false, 1.5)
				# Corner flashes
				var flash: float = max(0.0, sin(_time * 8.0)) * 0.4
				if flash > 0.1:
					var flash_col := Color(col.r, col.g, col.b, flash)
					draw_circle(rect.position + Vector2(3, 3), 4.0, flash_col)
					draw_circle(rect.position + Vector2(rect.size.x - 3, 3), 4.0, flash_col)
					draw_circle(rect.position + Vector2(3, rect.size.y - 3), 4.0, flash_col)
					draw_circle(rect.position + Vector2(rect.size.x - 3, rect.size.y - 3), 4.0, flash_col)

			Inventory.Rarity.MYTHICAL:
				# Intense golden glow, fast pulse, shimmer
				var pulse := (sin(_time * 5.0) + 1.0) / 2.0
				var pulse2 := (sin(_time * 7.0 + 2.0) + 1.0) / 2.0
				var alpha := 0.18 + pulse * 0.25
				# Background fill
				draw_rect(rect, Color(col.r, col.g, col.b, alpha))
				# Warm orange undertone
				draw_rect(rect, Color(1.0, 0.5, 0.05, 0.06 + pulse2 * 0.10))
				# Triple border
				draw_rect(rect, Color(col.r, col.g, col.b, 0.5 + pulse * 0.5), false, 3.0)
				var mid := rect.grow(-3)
				draw_rect(mid, Color(1.0, 0.9, 0.5, 0.25 + pulse2 * 0.35), false, 2.0)
				var inner := rect.grow(-6)
				draw_rect(inner, Color(col.r, col.g, col.b, 0.15 + pulse * 0.2), false, 1.0)
				# Light rays from center
				var cx := rect.size.x / 2.0
				var cy := rect.size.y / 2.0
				var center := Vector2(cx, cy)
				for angle_i in range(6):
					var a := _time * 1.5 + angle_i * TAU / 6.0
					var ray_len := 20.0 + pulse * 10.0
					var ray_alpha := 0.15 + pulse2 * 0.2
					var endpoint := center + Vector2(cos(a), sin(a)) * ray_len
					draw_line(center, endpoint, Color(1.0, 0.9, 0.4, ray_alpha), 1.5)


# ── Particle Field ──────────────────────────────────────────────────────
# Procedural particles around each item slot. Particle count, speed, size,
# and visual complexity increase with rarity.
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
				# Slow drifting motes
				p["vx"] = (randf() - 0.5) * 6.0
				p["vy"] = -randf() * 8.0 - 2.0
				p["size"] = 1.0 + randf() * 1.5
				p["color"] = Color(col.r, col.g, col.b, 0.3 + randf() * 0.2)
				p["type"] = "dot"

			Inventory.Rarity.RARE:
				# Blue sparkles floating up
				p["vx"] = (randf() - 0.5) * 12.0
				p["vy"] = -randf() * 18.0 - 8.0
				p["size"] = 1.5 + randf() * 2.0
				p["color"] = Color(col.r * 0.8 + randf() * 0.2, col.g * 0.8 + randf() * 0.2, col.b, 0.4 + randf() * 0.3)
				p["type"] = "sparkle"

			Inventory.Rarity.EPIC:
				# Purple spiraling particles
				p["vx"] = (randf() - 0.5) * 16.0
				p["vy"] = -randf() * 22.0 - 10.0
				p["size"] = 2.0 + randf() * 2.5
				p["color"] = Color(col.r + randf() * 0.15, col.g, col.b + randf() * 0.1, 0.5 + randf() * 0.3)
				p["type"] = ["sparkle", "ring", "dot"][randi() % 3]
				p["orbit"] = randf() * TAU
				p["orbit_speed"] = (randf() - 0.5) * 4.0

			Inventory.Rarity.MYTHICAL:
				# Golden fire-like particles with trails
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

			# Orbit motion for epic/mythical
			if p.has("orbit"):
				p["orbit"] += p["orbit_speed"] * delta
				p["x"] += cos(p["orbit"]) * 12.0 * delta
				p["y"] += sin(p["orbit"]) * 8.0 * delta

			# Respawn when expired or out of bounds
			if p["lifetime"] >= p["max_life"] or p["y"] < -10 or p["x"] < -10 or p["x"] > size.x + 10:
				_particles[i] = _new_particle()
				# Start from edges for visual variety
				if randf() > 0.5:
					_particles[i]["y"] = size.y + randf() * 5.0
				else:
					_particles[i]["x"] = randf() * size.x
					_particles[i]["y"] = size.y * 0.5 + randf() * size.y * 0.5

	func _draw() -> void:
		for p: Dictionary in _particles:
			var life_frac: float = p["lifetime"] / p["max_life"]
			# Fade in then fade out
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
					# 4-pointed star sparkle
					var arm := sz * 1.8
					var thin := sz * 0.4
					draw_line(pos - Vector2(arm, 0), pos + Vector2(arm, 0), col, thin)
					draw_line(pos - Vector2(0, arm), pos + Vector2(0, arm), col, thin)
					# Center bright dot
					draw_circle(pos, sz * 0.5, Color(col.r, col.g, col.b, col.a * 1.3))

				"ring":
					draw_arc(pos, sz * 1.2, 0.0, TAU, 12, col, 1.0)
					draw_circle(pos, sz * 0.3, col)

				"star":
					# 6-pointed star
					var arm_len := sz * 2.2
					for si in range(6):
						var a := si * TAU / 6.0 + _time * 2.0
						var tip := pos + Vector2(cos(a), sin(a)) * arm_len
						draw_line(pos, tip, col, sz * 0.3)
					draw_circle(pos, sz * 0.6, Color(min(col.r * 1.3, 1.0), min(col.g * 1.3, 1.0), col.b, col.a))

			# Trail effect for mythical
			if p.get("trail", false) and life_frac > 0.1:
				var trail_col := Color(col.r, col.g, col.b, col.a * 0.35)
				var trail_offset := Vector2(-p["vx"], -p["vy"]).normalized() * sz * 2.5
				draw_circle(pos + trail_offset, sz * 0.6, trail_col)
				draw_circle(pos + trail_offset * 1.8, sz * 0.35, Color(trail_col.r, trail_col.g, trail_col.b, trail_col.a * 0.5))
