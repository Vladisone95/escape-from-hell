extends Control

# =====================================================================
# WAVE DATA  (10 waves, progressively harder)
# =====================================================================
const TOTAL_WAVES := 10
const WAVE_CONFIGS: Array[Dictionary] = [
	{"count": 1, "health": 15,  "attack": 3},   # Wave 1
	{"count": 1, "health": 22,  "attack": 5},   # Wave 2
	{"count": 2, "health": 20,  "attack": 5},   # Wave 3
	{"count": 2, "health": 28,  "attack": 7},   # Wave 4
	{"count": 3, "health": 25,  "attack": 8},   # Wave 5
	{"count": 3, "health": 32,  "attack": 10},  # Wave 6
	{"count": 4, "health": 30,  "attack": 11},  # Wave 7
	{"count": 4, "health": 38,  "attack": 13},  # Wave 8
	{"count": 5, "health": 35,  "attack": 14},  # Wave 9
	{"count": 5, "health": 55,  "attack": 18},  # Wave 10 (Boss)
]

const ENEMY_NAMES  := ["Demon",   "Imp",      "Devil",     "Hellhound", "Wraith"]
const BOSS_NAMES   := ["Arch-Demon", "Lord of Darkness", "Hell's Guardian"]
const MAX_LOG_LINES := 5

# =====================================================================
# GAME STATE
# =====================================================================
var current_wave      := 1
var player_max_health := 100
var player_health     := 100
var player_attack     := 10
var enemies: Array    = []   # Array of Dictionaries

# =====================================================================
# UI NODE REFERENCES  (populated in _build_ui)
# =====================================================================
var ui_wave_label:      Label
var ui_status_label:    Label
var ui_player_visual:   Control
var ui_player_hp:       Label
var ui_player_atk:      Label
var ui_enemies_container: HBoxContainer
var ui_log:             RichTextLabel
var ui_action_btn:      Button
var ui_upgrade_overlay: Control
var ui_upgrade_title:   Label
var ui_gameover_overlay: Control

var _log_lines: Array[String] = []

# =====================================================================
# LIFECYCLE
# =====================================================================
func _ready() -> void:
	_build_ui()
	_show_pre_wave()

# =====================================================================
# UI CONSTRUCTION  (entire UI is built in code — no child nodes needed)
# =====================================================================
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# ── Background ──────────────────────────────────────────────────
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.01, 0.02)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# ── Header strip ────────────────────────────────────────────────
	var header := PanelContainer.new()
	header.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	header.offset_bottom = 64
	add_child(header)

	var header_hb := HBoxContainer.new()
	header.add_child(header_hb)

	ui_wave_label = Label.new()
	ui_wave_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_wave_label.add_theme_font_size_override("font_size", 26)
	ui_wave_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	ui_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_wave_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	header_hb.add_child(ui_wave_label)

	ui_status_label = Label.new()
	ui_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_status_label.add_theme_font_size_override("font_size", 20)
	ui_status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	ui_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_status_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	header_hb.add_child(ui_status_label)

	# ── Battle area ──────────────────────────────────────────────────
	var battle := HBoxContainer.new()
	battle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battle.offset_top    = 70
	battle.offset_bottom = -200
	battle.add_theme_constant_override("separation", 10)
	add_child(battle)

	# -- Player panel --
	var player_vbox := VBoxContainer.new()
	player_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	player_vbox.add_theme_constant_override("separation", 8)
	battle.add_child(player_vbox)

	var player_center := CenterContainer.new()
	player_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_vbox.add_child(player_center)

	ui_player_visual = _make_char_rect(Color(0.15, 0.35, 0.85), "⚔")
	player_center.add_child(ui_player_visual)

	var p_name := Label.new()
	p_name.text = "HERO"
	p_name.add_theme_font_size_override("font_size", 20)
	p_name.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	p_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_vbox.add_child(p_name)

	ui_player_hp = Label.new()
	ui_player_hp.add_theme_font_size_override("font_size", 16)
	ui_player_hp.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
	ui_player_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_vbox.add_child(ui_player_hp)

	ui_player_atk = Label.new()
	ui_player_atk.add_theme_font_size_override("font_size", 16)
	ui_player_atk.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	ui_player_atk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_vbox.add_child(ui_player_atk)

	# -- VS label --
	var vs_lbl := Label.new()
	vs_lbl.text = "VS"
	vs_lbl.add_theme_font_size_override("font_size", 44)
	vs_lbl.add_theme_color_override("font_color", Color(0.9, 0.12, 0.08))
	vs_lbl.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	vs_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	battle.add_child(vs_lbl)

	# -- Enemies container --
	ui_enemies_container = HBoxContainer.new()
	ui_enemies_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui_enemies_container.alignment = BoxContainer.ALIGNMENT_CENTER
	ui_enemies_container.add_theme_constant_override("separation", 12)
	battle.add_child(ui_enemies_container)

	# ── Bottom bar ───────────────────────────────────────────────────
	var bottom := VBoxContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_top = -196
	bottom.add_theme_constant_override("separation", 4)
	add_child(bottom)

	var divider := ColorRect.new()
	divider.color = Color(0.45, 0.08, 0.08)
	divider.custom_minimum_size = Vector2(0, 2)
	bottom.add_child(divider)

	ui_log = RichTextLabel.new()
	ui_log.bbcode_enabled = true
	ui_log.scroll_active  = false
	ui_log.custom_minimum_size = Vector2(0, 110)
	ui_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui_log.add_theme_font_size_override("normal_font_size", 15)
	bottom.add_child(ui_log)

	var btn_center := CenterContainer.new()
	bottom.add_child(btn_center)

	ui_action_btn = Button.new()
	ui_action_btn.text = "START WAVE"
	ui_action_btn.custom_minimum_size = Vector2(260, 56)
	ui_action_btn.add_theme_font_size_override("font_size", 24)
	ui_action_btn.pressed.connect(_on_start_wave_pressed)
	btn_center.add_child(ui_action_btn)

	# ── Upgrade overlay ──────────────────────────────────────────────
	ui_upgrade_overlay = _build_upgrade_overlay()
	ui_upgrade_overlay.visible = false
	add_child(ui_upgrade_overlay)

	# ── Game-over overlay ────────────────────────────────────────────
	ui_gameover_overlay = _build_gameover_overlay()
	ui_gameover_overlay.visible = false
	add_child(ui_gameover_overlay)


func _make_char_rect(color: Color, symbol: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(90, 120)

	var rect := ColorRect.new()
	rect.color = color
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(rect)

	# Light top edge for depth
	var top_edge := ColorRect.new()
	top_edge.color = color.lightened(0.45)
	top_edge.anchor_right  = 1.0
	top_edge.anchor_bottom = 0.06
	c.add_child(top_edge)

	var sym := Label.new()
	sym.text = symbol
	sym.add_theme_font_size_override("font_size", 46)
	sym.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sym.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sym.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	c.add_child(sym)

	return c


func _build_upgrade_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -240
	vbox.offset_right  =  240
	vbox.offset_top    = -160
	vbox.offset_bottom =  160
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	overlay.add_child(vbox)

	ui_upgrade_title = Label.new()
	ui_upgrade_title.add_theme_font_size_override("font_size", 26)
	ui_upgrade_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	ui_upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_upgrade_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(ui_upgrade_title)

	var choose_lbl := Label.new()
	choose_lbl.text = "Choose your upgrade:"
	choose_lbl.add_theme_font_size_override("font_size", 20)
	choose_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	choose_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(choose_lbl)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 30)
	vbox.add_child(hb)

	var btn_hp := Button.new()
	btn_hp.text = "+ 30 Max Health"
	btn_hp.custom_minimum_size = Vector2(210, 58)
	btn_hp.add_theme_font_size_override("font_size", 20)
	btn_hp.pressed.connect(func(): _apply_upgrade("health"))
	hb.add_child(btn_hp)

	var btn_atk := Button.new()
	btn_atk.text = "+ 5 Attack"
	btn_atk.custom_minimum_size = Vector2(210, 58)
	btn_atk.add_theme_font_size_override("font_size", 20)
	btn_atk.pressed.connect(func(): _apply_upgrade("attack"))
	hb.add_child(btn_atk)

	return overlay


func _build_gameover_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -220
	vbox.offset_right  =  220
	vbox.offset_top    = -120
	vbox.offset_bottom =  120
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 22)
	overlay.add_child(vbox)

	var title := Label.new()
	title.text = "YOU DIED"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.95, 0.05, 0.05))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Hell has claimed your soul..."
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var btn := Button.new()
	btn.text = "Return to Main Menu"
	btn.custom_minimum_size = Vector2(260, 58)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(btn)

	return overlay

# =====================================================================
# GAME STATE MANAGEMENT
# =====================================================================
func _show_pre_wave() -> void:
	ui_wave_label.text   = "Wave  %d / %d" % [current_wave, TOTAL_WAVES]
	ui_status_label.text = "Ready for Battle"
	_update_player_ui()
	_spawn_wave_enemies()
	ui_action_btn.text    = "START WAVE"
	ui_action_btn.visible = true
	_clear_log()
	_log("[center][color=yellow]Wave %d — Prepare yourself![/color][/center]" % current_wave)


func _spawn_wave_enemies() -> void:
	# Remove old enemy nodes
	for child in ui_enemies_container.get_children():
		child.queue_free()
	enemies.clear()

	var cfg: Dictionary  = WAVE_CONFIGS[current_wave - 1]
	var is_boss_wave: bool = (current_wave == TOTAL_WAVES)

	for i in range(cfg["count"]):
		var ename: String
		if is_boss_wave and i == 0:
			ename = BOSS_NAMES[randi() % BOSS_NAMES.size()]
		else:
			ename = ENEMY_NAMES[randi() % ENEMY_NAMES.size()]

		var ecol := Color(0.72, 0.08, 0.08) if is_boss_wave else Color(0.52, 0.05, 0.05)

		# Build the enemy column
		var evbox := VBoxContainer.new()
		evbox.alignment = BoxContainer.ALIGNMENT_CENTER
		evbox.add_theme_constant_override("separation", 6)
		ui_enemies_container.add_child(evbox)

		var center := CenterContainer.new()
		center.size_flags_vertical = Control.SIZE_EXPAND_FILL
		evbox.add_child(center)

		var vis := _make_char_rect(ecol, "☠")
		center.add_child(vis)

		var name_lbl := Label.new()
		name_lbl.text = ename
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.38, 0.18))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		evbox.add_child(name_lbl)

		var hp_lbl := Label.new()
		hp_lbl.add_theme_font_size_override("font_size", 13)
		hp_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		evbox.add_child(hp_lbl)

		var atk_lbl := Label.new()
		atk_lbl.add_theme_font_size_override("font_size", 13)
		atk_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		atk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		evbox.add_child(atk_lbl)

		var e := {
			"name":       ename,
			"health":     cfg["health"],
			"max_health": cfg["health"],
			"attack":     cfg["attack"],
			"alive":      true,
			"visual":     vis,
			"hp_label":   hp_lbl,
			"atk_label":  atk_lbl,
		}
		enemies.append(e)
		_update_enemy_ui(e)


func _on_start_wave_pressed() -> void:
	ui_action_btn.visible = false
	ui_status_label.text  = "⚔  COMBAT"
	_run_combat()


func _apply_upgrade(kind: String) -> void:
	ui_upgrade_overlay.visible = false
	current_wave += 1

	if kind == "health":
		player_max_health += 30
		_log("[center][color=green]+ 30 Max Health![/color][/center]")
	else:
		player_attack += 5
		_log("[center][color=orange]+ 5 Attack![/color][/center]")

	# Full heal at the start of each new wave
	player_health = player_max_health
	_show_pre_wave()

# =====================================================================
# COMBAT LOOP  (async — uses await so animations play sequentially)
# =====================================================================
func _run_combat() -> void:
	await get_tree().create_timer(0.35).timeout

	while _alive_enemies().size() > 0 and player_health > 0:
		if not is_inside_tree():
			return

		# ── Player's turn ────────────────────────────────────────────
		var alive := _alive_enemies()
		var target: Dictionary = alive[randi() % alive.size()]

		_log("[color=cyan]Hero strikes [b]%s[/b] for %d dmg.[/color]" % [target["name"], player_attack])
		await _anim_attack_flash(ui_player_visual)

		target["health"] = max(0, target["health"] - player_attack)
		_update_enemy_ui(target)
		await _anim_hit_flash(target["visual"])

		if target["health"] <= 0:
			target["alive"] = false
			_log("[color=red][b]%s[/b] has been slain![/color]" % target["name"])
			await _anim_death(target["visual"])

		if _alive_enemies().is_empty():
			break

		await get_tree().create_timer(0.38).timeout
		if not is_inside_tree():
			return

		# ── Enemies' turn ────────────────────────────────────────────
		for enemy in _alive_enemies():
			if not is_inside_tree():
				return
			_log("[color=orange][b]%s[/b] attacks Hero for %d dmg.[/color]" % [enemy["name"], enemy["attack"]])
			await _anim_attack_flash(enemy["visual"])

			player_health = max(0, player_health - enemy["attack"])
			_update_player_ui()
			await _anim_hit_flash(ui_player_visual)

			if player_health <= 0:
				break

		if player_health <= 0:
			break

		await get_tree().create_timer(0.38).timeout

	# ── Outcome ───────────────────────────────────────────────────────
	if not is_inside_tree():
		return

	if player_health <= 0:
		await _handle_defeat()
	else:
		await _wave_complete()


func _wave_complete() -> void:
	_log("[center][color=yellow][b]Wave %d Complete![/b][/color][/center]" % current_wave)
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return

	if current_wave >= TOTAL_WAVES:
		get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
		return

	# Restore health, then show upgrade choice
	player_health = player_max_health

	ui_upgrade_title.text = (
		"Wave %d Complete!\n\nYour stats:  HP %d / %d   |   ATK %d"
		% [current_wave, player_health, player_max_health, player_attack]
	)
	ui_upgrade_overlay.visible = true


func _handle_defeat() -> void:
	_log("[center][color=red][b]Hero has fallen...[/b][/color][/center]")
	await _anim_death(ui_player_visual)
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		ui_gameover_overlay.visible = true

# =====================================================================
# ANIMATIONS  (each is an awaitable coroutine via internal await)
# =====================================================================

# Bright "outgoing attack" flash on the attacker
func _anim_attack_flash(node: Control) -> void:
	if not is_instance_valid(node):
		return
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color(2.2, 2.0, 0.4, 1.0), 0.10)
	tw.tween_property(node, "modulate", Color.WHITE, 0.18)
	await tw.finished


# Red flash on the target when it receives damage
func _anim_hit_flash(node: Control) -> void:
	if not is_instance_valid(node):
		return
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color(2.4, 0.15, 0.15, 1.0), 0.12)
	tw.tween_property(node, "modulate", Color.WHITE, 0.22)
	await tw.finished


# Shrink + fade to red on death
func _anim_death(node: Control) -> void:
	if not is_instance_valid(node):
		return
	# Centre the scale pivot using the declared minimum size
	var ms := node.get_minimum_size()
	node.pivot_offset = ms / 2.0 if ms.length() > 0.0 else Vector2(45.0, 60.0)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "modulate", Color(1.0, 0.0, 0.0, 0.0), 0.55)
	tw.tween_property(node, "scale",    Vector2(0.05, 0.05),        0.55)
	await tw.finished
	node.visible = false

# =====================================================================
# UI HELPERS
# =====================================================================
func _update_player_ui() -> void:
	ui_player_hp.text  = "HP:  %d / %d" % [max(0, player_health), player_max_health]
	ui_player_atk.text = "ATK: %d"       % player_attack


func _update_enemy_ui(e: Dictionary) -> void:
	e["hp_label"].text  = "HP:  %d / %d" % [max(0, e["health"]), e["max_health"]]
	e["atk_label"].text = "ATK: %d"       % e["attack"]


func _alive_enemies() -> Array:
	return enemies.filter(func(e: Dictionary) -> bool: return e["alive"])


func _log(text: String) -> void:
	_log_lines.append(text)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines = _log_lines.slice(_log_lines.size() - MAX_LOG_LINES)
	ui_log.text = "\n".join(_log_lines)


func _clear_log() -> void:
	_log_lines.clear()
	ui_log.text = ""
