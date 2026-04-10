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
var _item_slots: Array[Control] = []
var _selected_index: int = -1

# ── UI refs ──────────────────────────────────────────────────────────────
var _items_container: HBoxContainer
var _loot_btn: Button
var _tooltip: PanelContainer
var _tooltip_name: Label
var _tooltip_desc: Label
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
	_title_label.text = "A chest appears..."
	visible = true

	# Clear old item slots
	for child in _items_container.get_children():
		child.queue_free()
	_item_slots.clear()

	# Roll items from pool
	_roll_items()

func _roll_items() -> void:
	_item_ids.clear()
	var pool: Array[String] = []

	# Build pool: exclude items at max stacks
	for item_id: String in Inventory.ITEMS:
		var def: Dictionary = Inventory.ITEMS[item_id]
		var current_stack := GameData.player_inventory.get_stack(item_id)
		var max_stack: int = def["max_stack"]
		if current_stack < max_stack:
			pool.append(item_id)

	# Pick up to 3 random items (can repeat stackable ones)
	for _i in range(mini(3, pool.size())):
		var idx := randi() % pool.size()
		var picked: String = pool[idx]
		_item_ids.append(picked)
		# Remove unique items from pool after picking
		var def: Dictionary = Inventory.ITEMS[picked]
		if not def["stackable"]:
			pool.remove_at(idx)
			if pool.is_empty():
				break


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

	_chest_node = Control.new()
	_chest_node.custom_minimum_size = Vector2(160, 140)
	_chest_node.mouse_filter = Control.MOUSE_FILTER_STOP
	_chest_node.mouse_entered.connect(_on_chest_mouse_entered)
	_chest_node.mouse_exited.connect(_on_chest_mouse_exited)
	_chest_node.gui_input.connect(_on_chest_input)
	chest_center.add_child(_chest_node)

	# Items container (hidden until chest opens)
	_items_container = HBoxContainer.new()
	_items_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_items_container.add_theme_constant_override("separation", 40)
	_items_container.visible = false
	_items_container.custom_minimum_size = Vector2(0, 140)
	vbox.add_child(_items_container)

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
	# Initial creak — slow start
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
	_title_label.text = "Choose your loot!"
	_chest_node.visible = false
	_spawn_item_slots()
	_items_container.visible = true
	_loot_btn.visible = true
	_loot_btn.disabled = true


# ── Item slots ───────────────────────────────────────────────────────────
func _spawn_item_slots() -> void:
	for child in _items_container.get_children():
		child.queue_free()
	_item_slots.clear()

	for i in range(_item_ids.size()):
		var item_id: String = _item_ids[i]
		var def: Dictionary = Inventory.ITEMS[item_id]
		var slot := _create_item_slot(i, item_id, def)
		_items_container.add_child(slot)
		_item_slots.append(slot)

		# Pop-in animation: start scaled down and invisible
		slot.scale = Vector2(0.1, 0.1)
		slot.modulate = Color(1, 1, 1, 0)
		slot.pivot_offset = Vector2(100, 120) / 2.0

		var delay := i * 0.18
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(slot, "scale", Vector2(1.15, 1.15), 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(slot, "modulate", Color.WHITE, 0.2)
		tw.tween_property(slot, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _create_item_slot(index: int, item_id: String, def: Dictionary) -> Control:
	var is_unique: bool = not def["stackable"]

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(100, 120)
	wrapper.mouse_filter = Control.MOUSE_FILTER_STOP

	# Aura (drawn behind)
	var aura := _AuraRect.new()
	aura.is_unique = is_unique
	aura.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	aura.offset_left = -8
	aura.offset_top = -8
	aura.offset_right = 8
	aura.offset_bottom = 8
	wrapper.add_child(aura)

	# Item thumbnail
	var thumb := ItemThumbnail.new(item_id, 1)
	thumb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	thumb.offset_left = -32
	thumb.offset_right = 32
	thumb.offset_top = -32
	thumb.offset_bottom = 32
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(thumb)

	# Item name label below
	var name_lbl := Label.new()
	name_lbl.text = def["name"]
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	name_lbl.offset_top = -20
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(name_lbl)

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

	# Input handling
	wrapper.mouse_entered.connect(func() -> void:
		_tooltip_name.text = def["name"]
		_tooltip_desc.text = def["description"]
		_tooltip.visible = true
		_tooltip.global_position = Vector2(wrapper.global_position.x, wrapper.global_position.y - 70)
	)
	wrapper.mouse_exited.connect(func() -> void:
		_tooltip.visible = false
	)
	wrapper.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_item(index)
	)

	return wrapper


func _select_item(index: int) -> void:
	_selected_index = index
	_loot_btn.disabled = false

	# Update selection visuals
	for i in range(_item_slots.size()):
		var slot := _item_slots[i]
		var border := slot.find_child("SelectBorder") as ColorRect
		if border:
			if i == index:
				border.color = Color(1.0, 0.85, 0.0, 0.35)
			else:
				border.color = Color(1.0, 0.85, 0.0, 0.0)


func _on_loot_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _item_ids.size():
		return
	var item_id: String = _item_ids[_selected_index]
	visible = false
	item_looted.emit(item_id)


# ── Process (for chest redraw) ───────────────────────────────────────────
func _process(_delta: float) -> void:
	if _state != State.ITEMS_SHOWN:
		_chest_node.queue_redraw()


# ── Chest drawing ────────────────────────────────────────────────────────
func _draw() -> void:
	pass  # Drawing is done in _chest_node


# Called by _chest_node's _draw — we connect via a subclass
class _ChestDrawer extends Control:
	var overlay: ChestOverlay
	func _draw() -> void:
		if not overlay:
			return
		overlay._draw_chest(self)


# We can't easily subclass the chest_node inline, so we'll override _chest_node
# creation to use a drawing callback. Let me refactor _build_ui for this.

# Actually, let's handle chest drawing via _notification on the main overlay.
# Simpler: make _chest_node a custom inner Control.


# ── Aura inner class ────────────────────────────────────────────────────
class _AuraRect extends Control:
	var is_unique: bool = false
	var _time: float = 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		if is_unique:
			# Pulsing yellow glow
			var pulse := (sin(_time * 4.0) + 1.0) / 2.0
			var alpha := 0.15 + pulse * 0.25
			draw_rect(rect, Color(1.0, 0.85, 0.0, alpha))
			# Shimmering border
			var border_alpha := 0.4 + pulse * 0.5
			draw_rect(rect, Color(1.0, 0.80, 0.1, border_alpha), false, 2.5)
			# Inner glow line
			var inner := rect.grow(-4)
			draw_rect(inner, Color(1.0, 0.90, 0.3, alpha * 0.6), false, 1.0)
		else:
			# Soft white aura
			var pulse := (sin(_time * 2.5) + 1.0) / 2.0
			var alpha := 0.08 + pulse * 0.12
			draw_rect(rect, Color(1.0, 1.0, 1.0, alpha))
			draw_rect(rect, Color(0.9, 0.9, 1.0, 0.2 + pulse * 0.15), false, 1.5)
