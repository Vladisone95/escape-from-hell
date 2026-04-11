extends Node2D

enum GameState { PRE_WAVE, COMBAT, WAVE_COMPLETE, GAME_OVER, WIN }

const ENEMY_TYPE_NAMES := ["Demon", "Imp", "Hellhound"]
const ARENA_BASE_SIZE := Vector2(1000, 700)
const ARENA_GROW_PER_WAVE := Vector2(30, 20)
const MIN_OBSTACLE_COUNT := 2
const MAX_OBSTACLE_COUNT := 4

var _state: int = GameState.PRE_WAVE
var _player: CharacterBody2D
var _camera: Camera2D
var _hud: Control
var _hud_layer: CanvasLayer
var _arena_container: Node2D  # holds walls, floor, obstacles
var _enemy_container: Node2D
var _alive_count: int = 0
var _arena_size: Vector2 = ARENA_BASE_SIZE

# Overlays
var _upgrade_overlay: Control
var _upgrade_title: Label
var _gameover_overlay: Control
var _chest_overlay: ChestOverlay
var _inventory_overlay: InventoryOverlay
var _advance_wave_on_next: bool = false

# Wave announcement
var _wave_announce_label: Label

func _ready() -> void:
	GameData.reset()
	_build_arena()
	_spawn_player()
	_setup_camera()
	_build_hud_layer()
	_build_overlays()
	_show_inventory_screen()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

# ═══════════════════════════════════════════════════════════════════
# ARENA GENERATION
# ═══════════════════════════════════════════════════════════════════
func _build_arena() -> void:
	_arena_container = Node2D.new()
	add_child(_arena_container)
	_enemy_container = Node2D.new()
	add_child(_enemy_container)
	_generate_arena(GameData.current_wave)

func _generate_arena(wave: int) -> void:
	# Clear old arena
	for c in _arena_container.get_children():
		c.queue_free()

	_arena_size = ARENA_BASE_SIZE + ARENA_GROW_PER_WAVE * (wave - 1)
	var hw := _arena_size.x * 0.5
	var hh := _arena_size.y * 0.5
	var wall_thickness := 30.0

	# Floor
	var floor_node := Node2D.new()
	floor_node.set_script(load("res://scripts/arena/ArenaFloor.gd"))
	floor_node.set_meta("arena_size", _arena_size)
	_arena_container.add_child(floor_node)

	# Walls (4 StaticBody2D)
	_add_wall(Vector2(0, -hh - wall_thickness * 0.5), Vector2(_arena_size.x + wall_thickness * 2, wall_thickness))  # top
	_add_wall(Vector2(0, hh + wall_thickness * 0.5), Vector2(_arena_size.x + wall_thickness * 2, wall_thickness))   # bottom
	_add_wall(Vector2(-hw - wall_thickness * 0.5, 0), Vector2(wall_thickness, _arena_size.y))  # left
	_add_wall(Vector2(hw + wall_thickness * 0.5, 0), Vector2(wall_thickness, _arena_size.y))   # right

	# Random obstacles
	var obstacle_count := randi_range(MIN_OBSTACLE_COUNT, MAX_OBSTACLE_COUNT)
	for i in obstacle_count:
		var pos := Vector2(
			randf_range(-hw * 0.7, hw * 0.7),
			randf_range(-hh * 0.7, hh * 0.7)
		)
		# Don't place too close to center (player spawn)
		if pos.length() < 80.0:
			pos = pos.normalized() * 80.0
		_add_obstacle(pos)

func _add_wall(pos: Vector2, sz: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = pos
	wall.collision_layer = 1 << 0  # layer 1: world
	wall.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = sz
	col.shape = rect
	wall.add_child(col)
	_arena_container.add_child(wall)

func _add_obstacle(pos: Vector2) -> void:
	var obs := StaticBody2D.new()
	obs.position = pos
	obs.collision_layer = 1 << 0  # world
	obs.collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 22.0
	col.shape = shape
	obs.add_child(col)

	# Visual
	var vis := Node2D.new()
	vis.set_script(load("res://scripts/arena/ObstacleVisual.gd"))
	obs.add_child(vis)

	_arena_container.add_child(obs)

# ═══════════════════════════════════════════════════════════════════
# PLAYER
# ═══════════════════════════════════════════════════════════════════
func _spawn_player() -> void:
	_player = CharacterBody2D.new()
	_player.set_script(load("res://scripts/arena/PlayerBody.gd"))
	_player.position = Vector2.ZERO
	add_child(_player)
	_player.health_changed.connect(_on_player_health_changed)
	_player.died.connect(_on_player_died)

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0
	_player.add_child(_camera)
	_update_camera_limits()

func _update_camera_limits() -> void:
	var hw := _arena_size.x * 0.5 + 30
	var hh := _arena_size.y * 0.5 + 30
	_camera.limit_left = int(-hw)
	_camera.limit_right = int(hw)
	_camera.limit_top = int(-hh)
	_camera.limit_bottom = int(hh)

# ═══════════════════════════════════════════════════════════════════
# HUD & OVERLAYS
# ═══════════════════════════════════════════════════════════════════
func _build_hud_layer() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 10
	add_child(_hud_layer)

	_hud = Control.new()
	_hud.set_script(load("res://scripts/arena/ArenaHUD.gd"))
	_hud_layer.add_child(_hud)

func _build_overlays() -> void:
	# Upgrade overlay
	_upgrade_overlay = _build_upgrade_overlay()
	_upgrade_overlay.visible = false
	_hud_layer.add_child(_upgrade_overlay)

	# Game over overlay
	_gameover_overlay = _build_gameover_overlay()
	_gameover_overlay.visible = false
	_hud_layer.add_child(_gameover_overlay)

	# Chest overlay
	_chest_overlay = ChestOverlay.new()
	_chest_overlay.visible = false
	_chest_overlay.item_looted.connect(_on_chest_item_looted)
	_hud_layer.add_child(_chest_overlay)

	# Inventory overlay
	_inventory_overlay = InventoryOverlay.new()
	_inventory_overlay.visible = false
	_inventory_overlay.next_stage_pressed.connect(_on_inventory_next_stage)
	_hud_layer.add_child(_inventory_overlay)

	# Wave announcement
	_wave_announce_label = Label.new()
	_wave_announce_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_wave_announce_label.add_theme_font_size_override("font_size", 52)
	_wave_announce_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.05))
	_wave_announce_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wave_announce_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wave_announce_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wave_announce_label.visible = false
	_hud_layer.add_child(_wave_announce_label)

func _build_upgrade_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.88)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left = -240; vbox.offset_right = 240
	vbox.offset_top = -160; vbox.offset_bottom = 160
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	overlay.add_child(vbox)

	_upgrade_title = Label.new()
	_upgrade_title.add_theme_font_size_override("font_size", 30)
	_upgrade_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	_upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_upgrade_title)

	var sub := Label.new()
	sub.text = "Choose your reward:"
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 30)
	vbox.add_child(btn_row)

	var btn_hp := Button.new()
	btn_hp.text = "+30 Max Health"
	btn_hp.custom_minimum_size = Vector2(180, 56)
	btn_hp.add_theme_font_size_override("font_size", 20)
	btn_hp.pressed.connect(func(): _apply_upgrade("health"))
	btn_row.add_child(btn_hp)

	var btn_atk := Button.new()
	btn_atk.text = "+5 Attack"
	btn_atk.custom_minimum_size = Vector2(180, 56)
	btn_atk.add_theme_font_size_override("font_size", 20)
	btn_atk.pressed.connect(func(): _apply_upgrade("attack"))
	btn_row.add_child(btn_atk)

	return overlay

func _build_gameover_overlay() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.92)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.offset_left = -200; vbox.offset_right = 200
	vbox.offset_top = -120; vbox.offset_bottom = 120
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	overlay.add_child(vbox)

	var title := Label.new()
	title.text = "YOU DIED"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Wave %d" % GameData.current_wave
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	var btn := Button.new()
	btn.text = "RETURN TO MENU"
	btn.custom_minimum_size = Vector2(220, 56)
	btn.add_theme_font_size_override("font_size", 22)
	btn.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	vbox.add_child(btn)

	return overlay

# ═══════════════════════════════════════════════════════════════════
# WAVE FLOW
# ═══════════════════════════════════════════════════════════════════
func _show_inventory_screen(advance_wave: bool = false) -> void:
	_advance_wave_on_next = advance_wave
	_state = GameState.PRE_WAVE
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_inventory_overlay.refresh()
	_inventory_overlay.visible = true
	_hud.visible = false

func _on_inventory_next_stage() -> void:
	_inventory_overlay.visible = false
	if _advance_wave_on_next:
		GameData.current_wave += 1
	_start_combat()

func _start_combat() -> void:
	_state = GameState.COMBAT

	# Regenerate arena
	_generate_arena(GameData.current_wave)
	_update_camera_limits()

	# Clear old enemies
	for c in _enemy_container.get_children():
		c.queue_free()

	# Reset player
	_player.position = Vector2.ZERO
	_player.reset_for_wave()
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)

	# HUD
	_hud.visible = true
	_hud.update_wave(GameData.current_wave)
	_hud.update_hp(GameData.player_health, GameData.effective_max_health())
	_hud.update_stats()
	_hud.clear_log()

	# Spawn enemies
	_spawn_wave_enemies()

	# Music
	MusicManager.play_track(MusicManager.Track.COMBAT)

	# Wave announcement
	_show_wave_announcement()

func _spawn_wave_enemies() -> void:
	_alive_count = 0
	var wave_def: Array = GameData.WAVE_ENEMIES[GameData.current_wave - 1]
	var hw := _arena_size.x * 0.5 - 50
	var hh := _arena_size.y * 0.5 - 50

	for group in wave_def:
		var et: int = group[0]
		var count: int = group[1]
		for i in count:
			var enemy := CharacterBody2D.new()
			enemy.set_script(load("res://scripts/arena/EnemyBody.gd"))

			# Spawn at random edge
			var edge := randi() % 4
			var pos := Vector2.ZERO
			match edge:
				0: pos = Vector2(randf_range(-hw, hw), -hh)  # top
				1: pos = Vector2(randf_range(-hw, hw), hh)   # bottom
				2: pos = Vector2(-hw, randf_range(-hh, hh))  # left
				3: pos = Vector2(hw, randf_range(-hh, hh))   # right

			enemy.position = pos
			_enemy_container.add_child(enemy)
			enemy.init(et, _player)
			enemy.add_to_group("enemies")
			enemy.enemy_died.connect(_on_enemy_died)
			_alive_count += 1

			# Fade in
			enemy.modulate = Color(1, 1, 1, 0)
			var tw := create_tween()
			tw.tween_property(enemy, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_enemy_died(_enemy: CharacterBody2D) -> void:
	_alive_count -= 1
	if _alive_count <= 0 and _state == GameState.COMBAT:
		_wave_complete()

func _wave_complete() -> void:
	_state = GameState.WAVE_COMPLETE
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	MusicManager.play_track(MusicManager.Track.IDLE)
	_hud.log_msg("[center][color=yellow][b]Wave %d Complete![/b][/color][/center]" % GameData.current_wave)

	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree(): return

	if GameData.is_last_wave():
		get_tree().change_scene_to_file("res://scenes/WinScreen.tscn")
		return

	# Regen at end of wave (health carries over between waves)
	var regen := GameData.effective_regen()
	if regen > 0 and GameData.player_health < GameData.effective_max_health():
		var healed := mini(regen, GameData.effective_max_health() - GameData.player_health)
		GameData.player_health += healed
		_hud.update_hp(GameData.player_health, GameData.effective_max_health())
		_hud.log_msg("[color=green]+%d HP (regen)[/color]" % healed)

	if GameData.is_item_reward_wave():
		_chest_overlay.show_chest()
	else:
		_upgrade_overlay.visible = true
		_upgrade_title.text = "Wave %d Complete!" % GameData.current_wave

func _apply_upgrade(kind: String) -> void:
	_upgrade_overlay.visible = false
	if kind == "health":
		GameData.player_max_health += 30
	else:
		GameData.player_attack += 5
	_show_inventory_screen(true)

func _on_chest_item_looted(item_id: String) -> void:
	var def: Dictionary = Inventory.ITEMS.get(item_id, {})
	if GameData.player_inventory.add_item(item_id):
		_hud.log_msg("[center][color=orange]+ %s![/color][/center]" % def.get("name", item_id))
	else:
		_hud.log_msg("[center][color=gray]%s is full![/color][/center]" % def.get("name", item_id))
	_show_inventory_screen(true)

func _on_player_died() -> void:
	_state = GameState.GAME_OVER
	MusicManager.play_track(MusicManager.Track.IDLE)
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		_gameover_overlay.visible = true

func _on_player_health_changed(current: int, mx: int) -> void:
	_hud.update_hp(current, mx)

# ═══════════════════════════════════════════════════════════════════
# POLISH
# ═══════════════════════════════════════════════════════════════════
func _show_wave_announcement() -> void:
	_wave_announce_label.text = "WAVE %d" % GameData.current_wave
	_wave_announce_label.visible = true
	_wave_announce_label.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_wave_announce_label, "modulate", Color(1, 1, 1, 1), 0.3)
	tw.tween_interval(1.0)
	tw.tween_property(_wave_announce_label, "modulate", Color(1, 1, 1, 0), 0.4)
	tw.tween_callback(func(): _wave_announce_label.visible = false)

func shake_camera(intensity: float = 3.0, duration: float = 0.1) -> void:
	if not is_instance_valid(_camera): return
	var tw := create_tween()
	var steps := 4
	for i in steps:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(_camera, "offset", offset, duration / steps)
	tw.tween_property(_camera, "offset", Vector2.ZERO, 0.05)
