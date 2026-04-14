extends Node2D

enum GameState { PRE_WAVE, COMBAT, WAVE_COMPLETE, GAME_OVER, WIN }

const ENEMY_TYPE_NAMES := ["Demon", "Imp", "Hellhound", "Warlock"]
const ARENA_SIZE := Vector2(1920, 1280)

var _state: int = GameState.PRE_WAVE
var _current_grid: RoomGrid
var _player: CharacterBody2D
var _camera: Camera2D
var _hud: Control
var _hud_layer: CanvasLayer
var _arena_container: Node2D  # holds walls, floor, obstacles
var _enemy_container: Node2D
var _alive_count: int = 0
var _arena_size: Vector2 = ARENA_SIZE
var _boss_enemy: CharacterBody2D = null  # tracked boss for HUD health bar

# Boss mirror mechanic
var _boss_mirrors: Array = []
var _mirror_charge_timer: float = 0.0
var _mirror_charge_interval: float = 15.0  # seconds between mirror attacks
var _mirror_charging_idx: int = -1  # which mirror is charging (-1 = none)
var _mirror_charge_progress: float = 0.0
const MIRROR_CHARGE_DURATION := 5.0  # how long the mirror glows before releasing

# Overlays
var _gameover_overlay: Control
var _chest_overlay: ChestOverlay
var _shrine_overlay: ShrineOverlay
var _inventory_overlay: InventoryOverlay
var _advance_wave_on_next: bool = false
var _chest_pickup: Node2D = null

# Wave portal
var _wave_portal: Area2D = null
var _nav_astar: AStarGrid2D = null

# Act map overlay (TAB key)
var _act_map_overlay: ActMap = null
var _act_map_visible: bool = false

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

func _unhandled_input(event: InputEvent) -> void:
	if _state != GameState.COMBAT and _state != GameState.WAVE_COMPLETE:
		return
	if event.is_action_pressed("toggle_map"):
		if _act_map_visible:
			_hide_act_map_overlay()
		else:
			_show_act_map_overlay()
		get_viewport().set_input_as_handled()

func _show_act_map_overlay() -> void:
	_act_map_visible = true
	_act_map_overlay.visible = true
	Engine.time_scale = 0.0
	_player.set_process_unhandled_input(false)

func _hide_act_map_overlay() -> void:
	_act_map_visible = false
	_act_map_overlay.visible = false
	Engine.time_scale = 1.0
	if _state == GameState.COMBAT:
		_player.set_process_unhandled_input(true)

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

	var is_boss: bool = EnemyStats.get_encounter(wave) == EnemyStats.Encounter.BOSS
	_arena_size = ARENA_SIZE

	# Generate room grid (fixed size, changes shape per wave)
	var seed_val: int = wave * 73856093 + 12345
	_current_grid = RoomGrid.new()
	_current_grid.generate(seed_val, is_boss)

	# Floor + lava tilemap
	var floor_layer: TileMapLayer = TileMapLayer.new()
	floor_layer.set_script(load("res://scripts/arena/ArenaFloorTileMap.gd"))
	var TileSetBuilder: GDScript = load("res://scripts/arena/ArenaTileSet.gd")
	floor_layer.tile_set = TileSetBuilder.create()
	floor_layer.position = _current_grid.get_origin()
	_arena_container.add_child(floor_layer)
	floor_layer.populate(_current_grid)

	# Lava bubble animations
	var bubble_node: Node2D = Node2D.new()
	bubble_node.set_script(load("res://scripts/arena/LavaBubbleEffect.gd"))
	_arena_container.add_child(bubble_node)
	bubble_node.init(_current_grid, seed_val)

	# Build navigation grid for enemy pathfinding
	var no_obstacles: Array[Vector2] = []
	_nav_astar = _current_grid.build_astar(no_obstacles)

func _spawn_mirrors() -> void:
	var is_boss_m: bool = EnemyStats.get_encounter(GameData.current_wave) == EnemyStats.Encounter.BOSS
	if not is_boss_m:
		return  # mirrors only appear on boss waves
	var hw := _arena_size.x * 0.5
	var mirror_a := Node2D.new()
	mirror_a.set_script(load("res://scripts/arena/TeleportMirror.gd"))
	mirror_a.position = Vector2(-hw * 0.55, _arena_size.y * 0.2)
	var mirror_b := Node2D.new()
	mirror_b.set_script(load("res://scripts/arena/TeleportMirror.gd"))
	mirror_b.position = Vector2(hw * 0.55, _arena_size.y * 0.2)
	var pair_color := Color(0.9, 0.15, 0.1)  # red glow for boss mirrors
	_arena_container.add_child(mirror_a)
	_arena_container.add_child(mirror_b)
	mirror_a.init(_player, pair_color, mirror_b, 15.0)
	mirror_b.init(_player, pair_color, mirror_a, 15.0)
	# Store references for boss mirror mechanic
	_boss_mirrors = [mirror_a, mirror_b]

func _spawn_shrines() -> void:
	# Spawn shrine on wave 1 for testing
	if GameData.current_wave != 1:
		return
	var shrine := Node2D.new()
	shrine.set_script(load("res://scripts/arena/SacrificialShrine.gd"))
	shrine.position = Vector2(0, -500)
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
	var hw: float = RoomGrid.GRID_W * RoomGrid.CELL_SIZE * 0.5
	var hh: float = RoomGrid.GRID_H * RoomGrid.CELL_SIZE * 0.5
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

	# Act map overlay (TAB key, read-only mid-combat)
	_act_map_overlay = ActMap.new()
	_act_map_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_act_map_overlay.read_only = true
	_act_map_overlay.visible = false
	_act_map_overlay.close_requested.connect(_hide_act_map_overlay)
	_hud_layer.add_child(_act_map_overlay)

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
	MusicManager.play_track(MusicManager.Track.INVENTORY)
	_advance_wave_on_next = advance_wave
	_state = GameState.PRE_WAVE
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_inventory_overlay.refresh()
	_inventory_overlay.set_advance_context(advance_wave)
	_inventory_overlay.visible = true
	_hud.visible = false

func _on_inventory_next_stage() -> void:
	_inventory_overlay.visible = false
	if _advance_wave_on_next:
		GameData.current_wave += 1
	_start_combat()

func _start_combat() -> void:
	_state = GameState.COMBAT

	# Clean up any lingering portal
	if is_instance_valid(_wave_portal):
		_wave_portal.queue_free()
		_wave_portal = null

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

	# Music — boss wave gets its own track
	if _boss_enemy != null:
		MusicManager.play_track(MusicManager.Track.BOSS)
	else:
		MusicManager.play_track(MusicManager.Track.COMBAT)

	# Wave announcement
	_show_wave_announcement()

func _spawn_wave_enemies() -> void:
	_alive_count = 0
	_boss_enemy = null
	var wave_def: Array = EnemyStats.get_wave_def(GameData.current_wave)
	var is_boss_encounter: bool = EnemyStats.get_encounter(GameData.current_wave) == EnemyStats.Encounter.BOSS
	var edge_floors: Array[Vector2i] = []
	if _current_grid != null:
		edge_floors = _current_grid.get_edge_floor_positions(3, true)
	var hw: float = _arena_size.x * 0.5 - 200
	var hh: float = _arena_size.y * 0.5 - 200

	for group in wave_def:
		var et: int = EnemyStats.type_id(group["type"])
		var count: int = group["count"]
		var stats: Dictionary = EnemyStats.BASE.get(group["type"], {})
		var is_boss: bool = stats.get("is_boss", false)
		for i in count:
			var enemy: CharacterBody2D = CharacterBody2D.new()
			enemy.set_script(load("res://scripts/arena/EnemyBody.gd"))

			var pos: Vector2 = Vector2.ZERO
			if is_boss:
				pos = Vector2.ZERO
			elif edge_floors.size() > 0:
				var cell: Vector2i = edge_floors[randi() % edge_floors.size()]
				pos = _current_grid.grid_to_world(cell.x, cell.y)
			else:
				var edge: int = randi() % 4
				match edge:
					0: pos = Vector2(randf_range(-hw, hw), -hh)
					1: pos = Vector2(randf_range(-hw, hw), hh)
					2: pos = Vector2(-hw, randf_range(-hh, hh))
					3: pos = Vector2(hw, randf_range(-hh, hh))

			enemy.position = pos
			enemy.init(et, _player)
			enemy.set_nav(_nav_astar, _current_grid)
			_enemy_container.add_child(enemy)
			enemy.add_to_group("enemies")
			enemy.enemy_died.connect(_on_enemy_died)
			_alive_count += 1

			# Track boss enemy for HUD health bar
			if is_boss and is_boss_encounter:
				_boss_enemy = enemy
				enemy.health_changed.connect(_on_boss_health_changed)
				enemy.boss_segment_lost.connect(_on_boss_segment_lost)

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
	SoundManager.play("wave_done")
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

	_hud.log_msg("[center][color=#c89aff]Find the portal to advance![/color][/center]")
	_spawn_wave_portal()
	if GameData.is_item_reward_wave():
		_spawn_chest_pickup()

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

func _spawn_wave_portal() -> void:
	if is_instance_valid(_wave_portal):
		_wave_portal.queue_free()
		_wave_portal = null
	var WavePortalScript: GDScript = load("res://scripts/arena/WavePortal.gd")
	_wave_portal = Area2D.new()
	_wave_portal.set_script(WavePortalScript)
	_arena_container.add_child(_wave_portal)
	_wave_portal.global_position = _find_portal_placement()
	_wave_portal.init(_player)
	_wave_portal.portal_entered.connect(_on_portal_entered)

func _find_portal_placement() -> Vector2:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var floor_cells: Array[Vector2i] = _current_grid.get_floor_positions()
	var center_x: int = _current_grid.width / 2
	var center_y: int = _current_grid.height / 2
	for _attempt: int in 30:
		var cell: Vector2i = floor_cells[rng.randi_range(0, floor_cells.size() - 1)]
		if absi(cell.x - center_x) < 6 and absi(cell.y - center_y) < 6:
			continue
		if not _current_grid.is_floor(cell.x - 2, cell.y) or not _current_grid.is_floor(cell.x + 2, cell.y):
			continue
		if not _current_grid.is_floor(cell.x, cell.y - 2) or not _current_grid.is_floor(cell.x, cell.y + 2):
			continue
		var pos: Vector2 = _current_grid.grid_to_world(cell.x, cell.y)
		if pos.distance_to(Vector2.ZERO) < 360.0:
			continue
		return pos
	return Vector2(_arena_size.x * 0.3, -_arena_size.y * 0.3)

func _on_portal_entered() -> void:
	if is_instance_valid(_wave_portal):
		_wave_portal.queue_free()
		_wave_portal = null
	_show_inventory_screen(true)

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
	# Re-enable player — portal is already in the arena, player walks to it
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)

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

func _on_boss_segment_lost(_order_index: int) -> void:
	if not is_instance_valid(_player):
		return
	var MeteorScript: GDScript = load("res://scripts/arena/MeteorStrike.gd")
	MeteorScript.fire(_arena_container, _player.global_position)
	_hud.flash_boss_segment(_order_index)
	_hud.log_msg("[center][color=red]A hand shatters! The sky trembles![/color][/center]")

# ═══════════════════════════════════════════════════════════════════
# POLISH
# ═══════════════════════════════════════════════════════════════════
func _show_wave_announcement() -> void:
	SoundManager.play("wave_start")
	_wave_announce_label.text = "WAVE %d" % GameData.current_wave
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
