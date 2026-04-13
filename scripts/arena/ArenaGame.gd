extends Node2D

enum GameState { PRE_WAVE, COMBAT, WAVE_COMPLETE, GAME_OVER, WIN }

const ENEMY_TYPE_NAMES := ["Demon", "Imp", "Hellhound", "Warlock"]
const ARENA_BASE_SIZE := Vector2(1000, 700)
const ARENA_GROW_PER_WAVE := Vector2(60, 40)
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
var _boss_enemy: CharacterBody2D = null  # tracked boss for HUD health bar

# Boss mirror mechanic
var _boss_mirrors: Array = []
var _mirror_charge_timer: float = 0.0
var _mirror_charge_interval: float = 20.0  # seconds between mirror attacks
var _mirror_charging_idx: int = -1  # which mirror is charging (-1 = none)
var _mirror_charge_progress: float = 0.0
const MIRROR_CHARGE_DURATION := 2.0  # how long the mirror glows before releasing

# Overlays
var _gameover_overlay: Control
var _chest_overlay: ChestOverlay
var _shrine_overlay: ShrineOverlay
var _inventory_overlay: InventoryOverlay
var _advance_wave_on_next: bool = false
var _chest_pickup: Node2D = null

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

func _process(delta: float) -> void:
	if _state != GameState.COMBAT or _boss_mirrors.is_empty():
		return
	_update_boss_mirror_mechanic(delta)

func _update_boss_mirror_mechanic(delta: float) -> void:
	if _mirror_charging_idx >= 0:
		# A mirror is currently charging
		_mirror_charge_progress += delta
		var mirror: Node2D = _boss_mirrors[_mirror_charging_idx]
		if is_instance_valid(mirror):
			mirror.set_meta("charge_progress", _mirror_charge_progress / MIRROR_CHARGE_DURATION)
		if _mirror_charge_progress >= MIRROR_CHARGE_DURATION:
			# Release the expanding ring
			_release_mirror_ring(_mirror_charging_idx)
			_mirror_charging_idx = -1
			_mirror_charge_progress = 0.0
			_mirror_charge_timer = 0.0
	else:
		_mirror_charge_timer += delta
		if _mirror_charge_timer >= _mirror_charge_interval:
			# Pick a random mirror to supercharge
			_mirror_charging_idx = randi() % _boss_mirrors.size()
			_mirror_charge_progress = 0.0
			var mirror: Node2D = _boss_mirrors[_mirror_charging_idx]
			if is_instance_valid(mirror):
				mirror.set_meta("charge_progress", 0.0)

func _release_mirror_ring(idx: int) -> void:
	var mirror: Node2D = _boss_mirrors[idx]
	if not is_instance_valid(mirror):
		return
	mirror.set_meta("charge_progress", -1.0)  # reset
	var Ring := load("res://scripts/arena/ExpandingRing.gd")
	Ring.fire(_arena_container, mirror.global_position, 50)

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

	# Check for boss wave — enlarge arena
	var _is_boss_wave: bool = EnemyStats.get_encounter(wave) == EnemyStats.Encounter.BOSS
	if _is_boss_wave:
		_arena_size = ARENA_BASE_SIZE * 2
	else:
		_arena_size = ARENA_BASE_SIZE + ARENA_GROW_PER_WAVE * (wave - 1)
	var hw := _arena_size.x * 0.5
	var hh := _arena_size.y * 0.5
	var wall_thickness := 60.0

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

	# Random obstacles (skip for boss waves — boss fills center)
	if _is_boss_wave:
		return
	var obstacle_count := randi_range(MIN_OBSTACLE_COUNT, MAX_OBSTACLE_COUNT)
	for i in obstacle_count:
		var pos := Vector2(
			randf_range(-hw * 0.7, hw * 0.7),
			randf_range(-hh * 0.7, hh * 0.7)
		)
		# Don't place too close to center (player spawn)
		if pos.length() < 160.0:
			pos = pos.normalized() * 160.0
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
	shape.radius = 44.0
	col.shape = shape
	obs.add_child(col)

	# Visual
	var vis := Node2D.new()
	vis.set_script(load("res://scripts/arena/ObstacleVisual.gd"))
	obs.add_child(vis)

	_arena_container.add_child(obs)

func _spawn_mirrors() -> void:
	var is_boss_m: bool = EnemyStats.get_encounter(GameData.current_wave) == EnemyStats.Encounter.BOSS
	if not is_boss_m:
		return  # mirrors only appear on boss waves
	var hw := _arena_size.x * 0.5
	var mirror_a := Node2D.new()
	mirror_a.set_script(load("res://scripts/arena/TeleportMirror.gd"))
	mirror_a.position = Vector2(-hw * 0.55, 0)
	var mirror_b := Node2D.new()
	mirror_b.set_script(load("res://scripts/arena/TeleportMirror.gd"))
	mirror_b.position = Vector2(hw * 0.55, 0)
	var pair_color := Color(0.9, 0.15, 0.1)  # red glow for boss mirrors
	_arena_container.add_child(mirror_a)
	_arena_container.add_child(mirror_b)
	mirror_a.init(_player, pair_color, mirror_b, 999.0)  # no teleporting — boss mechanic only
	mirror_b.init(_player, pair_color, mirror_a, 999.0)
	# Store references for boss mirror mechanic
	_boss_mirrors = [mirror_a, mirror_b]

func _spawn_shrines() -> void:
	# Spawn shrine on wave 1 for testing
	if GameData.current_wave != 1:
		return
	var shrine := Node2D.new()
	shrine.set_script(load("res://scripts/arena/SacrificialShrine.gd"))
	shrine.position = Vector2(0, -250)
	_arena_container.add_child(shrine)
	shrine.init(_player)
	shrine.shrine_used.connect(_on_shrine_used)
	_hud.log_msg("[center][color=red]A Sacrificial Shrine looms nearby...[/color][/center]")

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
	var hw := _arena_size.x * 0.5 + 60
	var hh := _arena_size.y * 0.5 + 60
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
	_hud.set_player(_player)

func _build_overlays() -> void:
	# Game over overlay
	_gameover_overlay = _build_gameover_overlay()
	_gameover_overlay.visible = false
	_hud_layer.add_child(_gameover_overlay)

	# Chest overlay
	_chest_overlay = ChestOverlay.new()
	_chest_overlay.visible = false
	_chest_overlay.item_looted.connect(_on_chest_item_looted)
	_hud_layer.add_child(_chest_overlay)

	# Shrine overlay
	_shrine_overlay = ShrineOverlay.new()
	_shrine_overlay.visible = false
	_shrine_overlay.upgrade_chosen.connect(_on_shrine_upgrade_chosen)
	_hud_layer.add_child(_shrine_overlay)

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

	# Reset boss mirror state
	_boss_mirrors = []
	_mirror_charge_timer = 0.0
	_mirror_charging_idx = -1
	_mirror_charge_progress = 0.0

	# Regenerate arena
	_generate_arena(GameData.current_wave)
	_spawn_mirrors()
	_spawn_shrines()
	_update_camera_limits()

	# Clear old enemies
	for c in _enemy_container.get_children():
		c.queue_free()

	# Reset player — offset for boss waves so player doesn't spawn inside boss
	var boss_wave: bool = EnemyStats.get_encounter(GameData.current_wave) == EnemyStats.Encounter.BOSS
	if boss_wave:
		_player.position = Vector2(0, _arena_size.y * 0.5 - 200)  # near bottom edge
	else:
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
	_boss_enemy = null
	var wave_def: Array = EnemyStats.get_wave_def(GameData.current_wave)
	var is_boss_encounter: bool = EnemyStats.get_encounter(GameData.current_wave) == EnemyStats.Encounter.BOSS
	var hw := _arena_size.x * 0.5 - 100
	var hh := _arena_size.y * 0.5 - 100

	for group in wave_def:
		var et: int = EnemyStats.type_id(group["type"])
		var count: int = group["count"]
		var stats: Dictionary = EnemyStats.BASE.get(group["type"], {})
		var is_boss: bool = stats.get("is_boss", false)
		for i in count:
			var enemy := CharacterBody2D.new()
			enemy.set_script(load("res://scripts/arena/EnemyBody.gd"))

			var pos := Vector2.ZERO
			if is_boss:
				pos = Vector2.ZERO  # boss spawns at center
			else:
				# Spawn at random edge
				var edge := randi() % 4
				match edge:
					0: pos = Vector2(randf_range(-hw, hw), -hh)  # top
					1: pos = Vector2(randf_range(-hw, hw), hh)   # bottom
					2: pos = Vector2(-hw, randf_range(-hh, hh))  # left
					3: pos = Vector2(hw, randf_range(-hh, hh))   # right

			enemy.position = pos
			enemy.init(et, _player)
			_enemy_container.add_child(enemy)
			enemy.add_to_group("enemies")
			enemy.enemy_died.connect(_on_enemy_died)
			_alive_count += 1

			# Track boss enemy for HUD health bar
			if is_boss and is_boss_encounter:
				_boss_enemy = enemy
				enemy.health_changed.connect(_on_boss_health_changed)

			# Fade in
			enemy.modulate = Color(1, 1, 1, 0)
			var tw := create_tween()
			tw.tween_property(enemy, "modulate", Color(1, 1, 1, 1), 0.3)

	# Show boss health bar on HUD
	if is_boss_encounter and _boss_enemy != null:
		var boss_name: String = EnemyStats.get_boss_name(GameData.current_wave)
		_hud.show_boss_bar(boss_name, _boss_enemy.health, _boss_enemy.max_health)

func _on_enemy_died(_enemy: CharacterBody2D) -> void:
	_alive_count -= 1
	if _alive_count <= 0 and _state == GameState.COMBAT:
		_wave_complete()

func _wave_complete() -> void:
	_state = GameState.WAVE_COMPLETE
	_boss_enemy = null
	_hud.hide_boss_bar()
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
		_spawn_chest_pickup()
	else:
		_show_inventory_screen(true)

func _spawn_chest_pickup() -> void:
	_chest_pickup = Node2D.new()
	_chest_pickup.set_script(load("res://scripts/arena/ChestPickup.gd"))
	_chest_pickup.position = Vector2.ZERO
	add_child(_chest_pickup)
	_chest_pickup.init(_player)
	_chest_pickup.chest_opened.connect(_on_chest_pickup_opened)
	_hud.log_msg("[center][color=orange]A chest has appeared![/color][/center]")

func _on_chest_pickup_opened() -> void:
	_chest_pickup = null
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_chest_overlay.show_chest()

func _on_shrine_used() -> void:
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	var rolled := GameData.player_upgrades.roll_upgrades(3)
	if rolled.is_empty():
		# No upgrades available — just re-enable player
		_player.set_physics_process(true)
		_player.set_process_unhandled_input(true)
		_hud.log_msg("[center][color=gray]The shrine has nothing left to offer.[/color][/center]")
		return
	_shrine_overlay.show_upgrades(rolled)

func _on_shrine_upgrade_chosen(upgrade_id: String) -> void:
	if GameData.player_upgrades.add_upgrade(upgrade_id):
		var def: Dictionary = Upgrades.UPGRADES.get(upgrade_id, {})
		_hud.log_msg("[center][color=red]+ %s![/color][/center]" % def.get("name", upgrade_id))
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)
	_hud.update_hp(GameData.player_health, GameData.effective_max_health())

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

func _on_boss_health_changed(current: int, mx: int) -> void:
	_hud.update_boss_bar(current, mx)

# ═══════════════════════════════════════════════════════════════════
# POLISH
# ═══════════════════════════════════════════════════════════════════
func _show_wave_announcement() -> void:
	var is_boss_w: bool = EnemyStats.get_encounter(GameData.current_wave) == EnemyStats.Encounter.BOSS
	if is_boss_w:
		var boss_name: String = EnemyStats.get_boss_name(GameData.current_wave)
		_wave_announce_label.text = boss_name if boss_name != "" else "BOSS"
		_wave_announce_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	else:
		_wave_announce_label.text = "WAVE %d" % GameData.current_wave
		_wave_announce_label.remove_theme_color_override("font_color")
	_wave_announce_label.visible = true
	_wave_announce_label.modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(_wave_announce_label, "modulate", Color(1, 1, 1, 1), 0.3)
	tw.tween_interval(1.0)
	tw.tween_property(_wave_announce_label, "modulate", Color(1, 1, 1, 0), 0.4)
	tw.tween_callback(func(): _wave_announce_label.visible = false)

func shake_camera(intensity: float = 6.0, duration: float = 0.1) -> void:
	if not is_instance_valid(_camera): return
	var tw := create_tween()
	var steps := 4
	for i in steps:
		var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(_camera, "offset", offset, duration / steps)
	tw.tween_property(_camera, "offset", Vector2.ZERO, 0.05)
