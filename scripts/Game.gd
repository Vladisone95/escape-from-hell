extends Control

# Enemy type names matching GameData.ENEMY_BASE indices
const ENEMY_TYPE_NAMES := ["Demon", "Imp", "Hellhound"]
const BOSS_NAMES       := ["Arch-Demon", "Lord of Darkness", "Hell's Guardian"]
const MAX_LOG_LINES := 5

# =====================================================================
# GAME STATE  (reads from GameData autoload)
# =====================================================================
var enemies: Array = []   # Array of Dictionaries

# =====================================================================
# UI NODE REFERENCES  (populated in _build_ui)
# =====================================================================
var ui_wave_label:      Label
var ui_status_label:    Label
var ui_player_visual:   PlayerSprite
var ui_player_hp:       Label
var ui_player_atk:      Label
var ui_player_armor:    Label
var ui_player_spikes:   Label
var ui_player_regen:    Label
var ui_enemies_container: HBoxContainer
var ui_log:             RichTextLabel
var ui_action_btn:      Button
var ui_back_btn:        Button
var ui_upgrade_overlay: Control
var ui_upgrade_title:   Label
var ui_gameover_overlay: Control
var ui_item_reward_overlay: Control
var ui_inventory_overlay: InventoryOverlay

var _log_lines: Array[String] = []
var _advance_wave_on_next: bool = false

# =====================================================================
# LIFECYCLE
# =====================================================================
func _ready() -> void:
	GameData.reset()
	_build_ui()
	_update_player_ui()
	_show_inventory_screen()

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

	ui_player_visual = PlayerSprite.new()
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

	ui_player_armor = Label.new()
	ui_player_armor.add_theme_font_size_override("font_size", 16)
	ui_player_armor.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	ui_player_armor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_vbox.add_child(ui_player_armor)

	ui_player_spikes = Label.new()
	ui_player_spikes.add_theme_font_size_override("font_size", 16)
	ui_player_spikes.add_theme_color_override("font_color", Color(0.9, 0.3, 0.7))
	ui_player_spikes.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_vbox.add_child(ui_player_spikes)

	ui_player_regen = Label.new()
	ui_player_regen.add_theme_font_size_override("font_size", 16)
	ui_player_regen.add_theme_color_override("font_color", Color(0.3, 0.9, 0.5))
	ui_player_regen.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_vbox.add_child(ui_player_regen)

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

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	bottom.add_child(btn_row)

	ui_back_btn = Button.new()
	ui_back_btn.text = "BACK"
	ui_back_btn.custom_minimum_size = Vector2(140, 56)
	ui_back_btn.add_theme_font_size_override("font_size", 24)
	ui_back_btn.pressed.connect(_on_back_pressed)
	btn_row.add_child(ui_back_btn)

	ui_action_btn = Button.new()
	ui_action_btn.text = "START WAVE"
	ui_action_btn.custom_minimum_size = Vector2(260, 56)
	ui_action_btn.add_theme_font_size_override("font_size", 24)
	ui_action_btn.pressed.connect(_on_start_wave_pressed)
	btn_row.add_child(ui_action_btn)

	# ── Upgrade overlay ──────────────────────────────────────────────
	ui_upgrade_overlay = _build_upgrade_overlay()
	ui_upgrade_overlay.visible = false
	add_child(ui_upgrade_overlay)

	# ── Game-over overlay ────────────────────────────────────────────
	ui_gameover_overlay = _build_gameover_overlay()
	ui_gameover_overlay.visible = false
	add_child(ui_gameover_overlay)

	# ── Item reward overlay (waves 3, 5, 7) ──────────────────────────
	ui_item_reward_overlay = _build_item_reward_overlay()
	ui_item_reward_overlay.visible = false
	add_child(ui_item_reward_overlay)

	# ── Inventory overlay (shown after reward choice) ────────────────
	ui_inventory_overlay = InventoryOverlay.new()
	ui_inventory_overlay.visible = false
	ui_inventory_overlay.next_stage_pressed.connect(_on_inventory_next_stage)
	add_child(ui_inventory_overlay)


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

func _build_item_reward_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.90)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left   = -320
	vbox.offset_right  =  320
	vbox.offset_top    = -200
	vbox.offset_bottom =  200
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	overlay.add_child(vbox)

	var title := Label.new()
	title.name = "RewardTitle"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(title)

	var choose_lbl := Label.new()
	choose_lbl.text = "Choose a reward:"
	choose_lbl.add_theme_font_size_override("font_size", 20)
	choose_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	choose_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(choose_lbl)

	# Item row
	var item_row := HBoxContainer.new()
	item_row.alignment = BoxContainer.ALIGNMENT_CENTER
	item_row.add_theme_constant_override("separation", 20)
	item_row.name = "ItemRow"
	vbox.add_child(item_row)

	var btn_dagger := Button.new()
	btn_dagger.name = "BtnDagger"
	btn_dagger.text = "Dagger\n(+10 ATK, stackable)"
	btn_dagger.custom_minimum_size = Vector2(210, 62)
	btn_dagger.add_theme_font_size_override("font_size", 17)
	btn_dagger.pressed.connect(func(): _apply_item_reward("dagger"))
	item_row.add_child(btn_dagger)

	var btn_slice := Button.new()
	btn_slice.name = "BtnSlice"
	btn_slice.text = "Slice and Dice\n(Attack twice/turn)"
	btn_slice.custom_minimum_size = Vector2(210, 62)
	btn_slice.add_theme_font_size_override("font_size", 17)
	btn_slice.pressed.connect(func(): _apply_item_reward("slice_and_dice"))
	item_row.add_child(btn_slice)

	var btn_heart := Button.new()
	btn_heart.name = "BtnHeart"
	btn_heart.text = "Demon Heart\n(+3 Regen, stackable)"
	btn_heart.custom_minimum_size = Vector2(210, 62)
	btn_heart.add_theme_font_size_override("font_size", 17)
	btn_heart.pressed.connect(func(): _apply_item_reward("demon_heart"))
	item_row.add_child(btn_heart)

	var btn_skin := Button.new()
	btn_skin.name = "BtnSkin"
	btn_skin.text = "Thick Skin\n(+25 Max HP, stackable)"
	btn_skin.custom_minimum_size = Vector2(210, 62)
	btn_skin.add_theme_font_size_override("font_size", 17)
	btn_skin.pressed.connect(func(): _apply_item_reward("thick_skin"))
	item_row.add_child(btn_skin)

	# Divider
	var sep := Label.new()
	sep.text = "— or choose a stat upgrade —"
	sep.add_theme_font_size_override("font_size", 16)
	sep.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sep)

	# Stat upgrades row
	var stat_row := HBoxContainer.new()
	stat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_row.add_theme_constant_override("separation", 20)
	vbox.add_child(stat_row)

	var btn_hp := Button.new()
	btn_hp.text = "+ 30 Max Health"
	btn_hp.custom_minimum_size = Vector2(210, 54)
	btn_hp.add_theme_font_size_override("font_size", 18)
	btn_hp.pressed.connect(func(): _apply_item_reward("health"))
	stat_row.add_child(btn_hp)

	var btn_atk := Button.new()
	btn_atk.text = "+ 5 Attack"
	btn_atk.custom_minimum_size = Vector2(210, 54)
	btn_atk.add_theme_font_size_override("font_size", 18)
	btn_atk.pressed.connect(func(): _apply_item_reward("attack"))
	stat_row.add_child(btn_atk)

	return overlay


func _apply_item_reward(choice: String) -> void:
	ui_item_reward_overlay.visible = false

	match choice:
		"dagger":
			if GameData.player_inventory.add_item("dagger"):
				_log("[center][color=orange]+ Dagger (+10 ATK)![/color][/center]")
			else:
				_log("[center][color=gray]Dagger stack is full![/color][/center]")
		"slice_and_dice":
			if GameData.player_inventory.add_item("slice_and_dice"):
				_log("[center][color=orange]+ Slice and Dice![/color][/center]")
			else:
				_log("[center][color=gray]Already have Slice and Dice![/color][/center]")
		"demon_heart":
			if GameData.player_inventory.add_item("demon_heart"):
				_log("[center][color=green]+ Demon Heart (+3 Regen)![/color][/center]")
			else:
				_log("[center][color=gray]Demon Heart stack is full![/color][/center]")
		"thick_skin":
			if GameData.player_inventory.add_item("thick_skin"):
				_log("[center][color=green]+ Thick Skin (+25 Max HP)![/color][/center]")
			else:
				_log("[center][color=gray]Thick Skin stack is full![/color][/center]")
		"health":
			GameData.player_max_health += 30
			_log("[center][color=green]+ 30 Max Health![/color][/center]")
		"attack":
			GameData.player_attack += 5
			_log("[center][color=orange]+ 5 Attack![/color][/center]")

	# Full heal then show inventory screen
	GameData.player_health = GameData.effective_max_health()
	_show_inventory_screen(true)


func _show_inventory_screen(advance_wave: bool = false) -> void:
	_advance_wave_on_next = advance_wave
	ui_inventory_overlay.refresh()
	ui_inventory_overlay.visible = true


func _on_inventory_next_stage() -> void:
	ui_inventory_overlay.visible = false
	if _advance_wave_on_next:
		GameData.current_wave += 1
	_show_pre_wave()


# =====================================================================
# GAME STATE MANAGEMENT
# =====================================================================
func _show_pre_wave() -> void:
	MusicManager.play_track(MusicManager.Track.IDLE)
	ui_wave_label.text   = "Wave  %d / %d" % [GameData.current_wave, GameData.TOTAL_WAVES]
	ui_status_label.text = "Ready for Battle"
	_update_player_ui()
	_spawn_wave_enemies()
	ui_action_btn.text    = "START WAVE"
	ui_action_btn.visible = true
	ui_back_btn.visible   = true
	_clear_log()
	_log("[center][color=yellow]Wave %d — Prepare yourself![/color][/center]" % GameData.current_wave)


func _spawn_wave_enemies() -> void:
	# Remove old enemy nodes
	for child in ui_enemies_container.get_children():
		child.queue_free()
	enemies.clear()

	var wave_def: Array = GameData.WAVE_ENEMIES[GameData.current_wave - 1]
	var is_boss_wave: bool = GameData.is_last_wave()

	for group in wave_def:
		var etype: int = group[0]
		var count: int = group[1]
		for i in range(count):
			var ename: String
			if is_boss_wave and enemies.is_empty():
				ename = BOSS_NAMES[randi() % BOSS_NAMES.size()]
			else:
				ename = ENEMY_TYPE_NAMES[etype]

			var ehealth: int = GameData.enemy_health(etype)
			var eattack: int = GameData.enemy_attack(etype)
			var earmor: int  = GameData.enemy_armor(etype)

			# Build the enemy column
			var evbox := VBoxContainer.new()
			evbox.alignment = BoxContainer.ALIGNMENT_CENTER
			evbox.add_theme_constant_override("separation", 6)
			ui_enemies_container.add_child(evbox)

			var center := CenterContainer.new()
			center.size_flags_vertical = Control.SIZE_EXPAND_FILL
			evbox.add_child(center)

			var vis := EnemySprite.new(etype as EnemySprite.EType)
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
				"health":     ehealth,
				"max_health": ehealth,
				"attack":     eattack,
				"armor":      earmor,
				"alive":      true,
				"visual":     vis,
				"hp_label":   hp_lbl,
				"atk_label":  atk_lbl,
			}
			enemies.append(e)
			_update_enemy_ui(e)


func _on_start_wave_pressed() -> void:
	ui_action_btn.visible = false
	ui_back_btn.visible   = false
	ui_status_label.text  = "⚔  COMBAT"
	MusicManager.play_track(MusicManager.Track.COMBAT)
	_run_combat()


func _on_back_pressed() -> void:
	_show_inventory_screen()


func _apply_upgrade(kind: String) -> void:
	ui_upgrade_overlay.visible = false

	if kind == "health":
		GameData.player_max_health += 30
		_log("[center][color=green]+ 30 Max Health![/color][/center]")
	else:
		GameData.player_attack += 5
		_log("[center][color=orange]+ 5 Attack![/color][/center]")

	# Full heal then show inventory screen
	GameData.player_health = GameData.effective_max_health()
	_show_inventory_screen(true)

# =====================================================================
# COMBAT LOOP  (async — uses await so animations play sequentially)
# =====================================================================
func _run_combat() -> void:
	await get_tree().create_timer(0.35).timeout

	while _alive_enemies().size() > 0 and GameData.player_health > 0:
		if not is_inside_tree():
			return

		# ── Player's turn ────────────────────────────────────────────
		var atk_count := GameData.attacks_per_turn()
		var eff_atk   := GameData.effective_attack()

		for _strike in range(atk_count):
			if _alive_enemies().is_empty():
				break
			if not is_inside_tree():
				return

			var alive := _alive_enemies()
			var target: Dictionary = alive[randi() % alive.size()]

			_log("[color=cyan]Hero strikes [b]%s[/b] for %d dmg.[/color]" % [target["name"], eff_atk])
			await ui_player_visual.play_attack()

			target["health"] = max(0, target["health"] - eff_atk)
			_update_enemy_ui(target)
			await target["visual"].play_hurt()

			if target["health"] <= 0:
				target["alive"] = false
				_log("[color=red][b]%s[/b] has been slain![/color]" % target["name"])
				await target["visual"].play_die()

		if _alive_enemies().is_empty():
			break

		# ── Regen after player's turn ────────────────────────────────
		var regen := GameData.effective_regen()
		if regen > 0 and GameData.player_health < GameData.effective_max_health():
			var healed := mini(regen, GameData.effective_max_health() - GameData.player_health)
			GameData.player_health += healed
			_update_player_ui()
			_log("[color=green]+%d HP (regen)[/color]" % healed)

		await get_tree().create_timer(0.38).timeout
		if not is_inside_tree():
			return

		# ── Enemies' turn ────────────────────────────────────────────
		for enemy in _alive_enemies():
			if not is_inside_tree():
				return
			var raw_dmg: int = enemy["attack"]
			var actual_dmg: int = max(0, raw_dmg - GameData.player_armor)
			if GameData.player_armor > 0 and actual_dmg < raw_dmg:
				_log("[color=orange][b]%s[/b] attacks for %d dmg. [color=gray](-%d armor)[/color][/color]" % [enemy["name"], actual_dmg, raw_dmg - actual_dmg])
			else:
				_log("[color=orange][b]%s[/b] attacks Hero for %d dmg.[/color]" % [enemy["name"], actual_dmg])
			await enemy["visual"].play_attack()

			GameData.player_health = max(0, GameData.player_health - actual_dmg)
			_update_player_ui()
			await ui_player_visual.play_hurt()

			# Spikes reflection (dealt after receiving the hit)
			if GameData.player_spikes > 0 and enemy["alive"]:
				var spike_dmg: int = max(0, GameData.player_spikes - enemy["armor"])
				if spike_dmg > 0:
					_log("[color=magenta][b]Spikes[/b] reflect %d dmg to [b]%s[/b]![/color]" % [spike_dmg, enemy["name"]])
					enemy["health"] = max(0, enemy["health"] - spike_dmg)
					_update_enemy_ui(enemy)
					await enemy["visual"].play_hurt()
					if enemy["health"] <= 0:
						enemy["alive"] = false
						_log("[color=red][b]%s[/b] was killed by spikes![/color]" % enemy["name"])
						await enemy["visual"].play_die()
				else:
					_log("[color=gray]Spikes blocked by [b]%s[/b]'s armor.[/color]" % enemy["name"])

			if GameData.player_health <= 0:
				break

		if GameData.player_health <= 0:
			break

		await get_tree().create_timer(0.38).timeout

	# ── Outcome ───────────────────────────────────────────────────────
	if not is_inside_tree():
		return

	if GameData.player_health <= 0:
		await _handle_defeat()
	else:
		await _wave_complete()


func _wave_complete() -> void:
	_log("[center][color=yellow][b]Wave %d Complete![/b][/color][/center]" % GameData.current_wave)
	MusicManager.play_track(MusicManager.Track.IDLE)
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return

	if GameData.is_last_wave():
		get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
		return

	# Restore health
	GameData.player_health = GameData.effective_max_health()

	if GameData.is_item_reward_wave():
		# Item reward waves (3, 5, 7): show items + stat upgrades
		var title_node := ui_item_reward_overlay.find_child("RewardTitle") as Label
		if title_node:
			title_node.text = (
				"Wave %d Complete!\n\nHP %d / %d  |  ATK %d  |  DEF %d"
				% [GameData.current_wave, GameData.player_health, GameData.effective_max_health(), GameData.effective_attack(), GameData.player_armor]
			)
		# Disable buttons for items the player can't pick up
		var btn_dagger := ui_item_reward_overlay.find_child("BtnDagger") as Button
		var btn_slice := ui_item_reward_overlay.find_child("BtnSlice") as Button
		var btn_heart := ui_item_reward_overlay.find_child("BtnHeart") as Button
		var btn_skin := ui_item_reward_overlay.find_child("BtnSkin") as Button
		if btn_dagger:
			btn_dagger.disabled = GameData.player_inventory.get_stack("dagger") >= 5
		if btn_slice:
			btn_slice.disabled = GameData.player_inventory.has_item("slice_and_dice")
		if btn_heart:
			btn_heart.disabled = GameData.player_inventory.get_stack("demon_heart") >= 5
		if btn_skin:
			btn_skin.disabled = GameData.player_inventory.get_stack("thick_skin") >= 5
		ui_item_reward_overlay.visible = true
	else:
		# Normal upgrade waves
		ui_upgrade_title.text = (
			"Wave %d Complete!\n\nHP %d / %d  |  ATK %d  |  DEF %d"
			% [GameData.current_wave, GameData.player_health, GameData.effective_max_health(), GameData.effective_attack(), GameData.player_armor]
		)
		ui_upgrade_overlay.visible = true


func _handle_defeat() -> void:
	_log("[center][color=red][b]Hero has fallen...[/b][/color][/center]")
	await ui_player_visual.play_die()
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		ui_gameover_overlay.visible = true

# =====================================================================
# UI HELPERS
# =====================================================================
func _update_player_ui() -> void:
	ui_player_hp.text      = "HP:  %d / %d" % [max(0, GameData.player_health), GameData.effective_max_health()]
	ui_player_atk.text     = "ATK: %d"       % GameData.effective_attack()
	ui_player_armor.text   = "DEF: %d"       % GameData.player_armor
	ui_player_armor.visible = GameData.player_armor > 0
	ui_player_spikes.text  = "SPK: %d"       % GameData.player_spikes
	ui_player_spikes.visible = GameData.player_spikes > 0
	ui_player_regen.text   = "REG: %d"       % GameData.effective_regen()
	ui_player_regen.visible = GameData.effective_regen() > 0


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
