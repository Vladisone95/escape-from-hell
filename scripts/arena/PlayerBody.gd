extends CharacterBody2D

signal health_changed(current: int, mx: int)
signal died()
signal dash_state_changed(cooldown_remaining: float, cooldown_total: float)

var sprite: Node2D
var hurtbox: Area2D
var health_bar: Node2D

var _attack_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_timer: float = 0.0
var _is_dashing: bool = false
var _dash_dir: Vector2 = Vector2.DOWN
var _knockback_vel: Vector2 = Vector2.ZERO
var _facing_dir: Vector2 = Vector2.DOWN
var _is_dead: bool = false

func _ready() -> void:
	add_to_group("player")
	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 28.0
	col.shape = shape
	add_child(col)

	# Sprite
	sprite = Node2D.new()
	sprite.set_script(load("res://scripts/arena/PlayerArenaSprite.gd"))
	sprite.scale = Vector2(2, 2)
	sprite.position.y = -20.0  # offset sprite up so collision sits at feet
	add_child(sprite)
	sprite.start_idle()

	# Hurtbox
	hurtbox = Area2D.new()
	hurtbox.set_script(load("res://scripts/arena/Hurtbox.gd"))
	hurtbox.position.y = -20.0  # match sprite offset
	hurtbox.collision_layer = 1 << 1  # layer 2: player_body
	hurtbox.collision_mask = 1 << 4   # layer 5: enemy_attack
	var hb_shape := CollisionShape2D.new()
	var hb_circle := CircleShape2D.new()
	hb_circle.radius = 32.0
	hb_shape.shape = hb_circle
	hurtbox.add_child(hb_shape)
	add_child(hurtbox)
	hurtbox.hit_received.connect(_on_hit)

	# Health bar
	health_bar = Node2D.new()
	health_bar.set_script(load("res://scripts/arena/HealthBar.gd"))
	health_bar.bar_width = 80.0
	health_bar.y_offset = -82.0  # adjusted for sprite offset
	add_child(health_bar)

	# Body collision
	collision_layer = 1 << 1  # layer 2
	collision_mask = (1 << 0) | (1 << 2) | (1 << 6)  # world + enemy_body + meteor_obstacles

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# Timers
	_attack_cooldown -= delta
	_dash_cooldown -= delta

	# Dash timer
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false

	# Movement
	if _is_dashing:
		velocity = _dash_dir * GameData.player_dash_speed  # dash speed stays raw
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_dir.normalized() * GameData.effective_speed() + _knockback_vel

		if input_dir.length_squared() > 0.01:
			var new_dir := input_dir.normalized()
			# Only update facing when direction changes meaningfully (>15° shift)
			if _facing_dir.dot(new_dir) < 0.966:
				sprite.set_facing_from_vec(new_dir)
			_facing_dir = new_dir
			sprite.start_walk()
		else:
			if sprite._is_walking:
				sprite._stop_walk()
				sprite.start_idle()

	# Auto-attack nearest enemy in range
	if _attack_cooldown <= 0.0:
		var target: CharacterBody2D = _find_nearest_enemy()
		if target != null:
			_do_auto_attack(target)

	# Knockback decay
	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 1200.0 * delta)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return

	if event.is_action_pressed("dash") and _dash_cooldown <= 0.0 and not _is_dashing:
		_do_dash()

	if event.is_action_pressed("interact"):
		_do_interact()

func _do_attack() -> void:
	var cooldown: float = GameData.effective_attack_cooldown()
	_attack_cooldown = cooldown

	var strike_count: int = GameData.attacks_per_press()
	for strike in strike_count:
		if strike > 0:
			await get_tree().create_timer(0.15).timeout
			if not is_inside_tree():
				return
		_spawn_strike(cooldown)

func _spawn_strike(cooldown: float = 0.5) -> void:
	var dmg := GameData.effective_attack()
	var AttackHitbox := load("res://scripts/arena/AttackHitbox.gd")

	# Create arc hitbox
	var hitbox := Area2D.new()
	hitbox.set_script(AttackHitbox)
	hitbox.damage = dmg
	hitbox.knockback_force = 300.0
	hitbox.source = self
	hitbox.position = _facing_dir * 40.0
	hitbox.collision_layer = 1 << 3  # layer 4: player_attack
	hitbox.collision_mask = 1 << 2   # layer 3: enemy_body — actually we need enemy hurtbox

	# Build arc collision
	var angle_base := _facing_dir.angle()
	var arc_spread := deg_to_rad(60.0)
	for i in 5:
		var t := float(i) / 4.0
		var a := angle_base - arc_spread + t * arc_spread * 2.0
		var offset := Vector2(cos(a), sin(a)) * 40.0
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 28.0
		s.shape = c
		s.position = offset
		hitbox.add_child(s)

	# Hitbox detects enemy hurtboxes (layer 3 = enemy_body, where hurtboxes live)
	hitbox.collision_layer = 1 << 3  # layer 4: player_attack
	hitbox.collision_mask = 1 << 2   # layer 3: enemy hurtboxes

	get_parent().add_child(hitbox)
	hitbox.global_position = global_position + _facing_dir * 40.0

	# Attack arc visual — white semi-transparent fan showing attack range
	var arc_vis := Node2D.new()
	arc_vis.z_index = 10
	get_parent().add_child(arc_vis)
	arc_vis.global_position = global_position + _facing_dir * 40.0
	var _angle_base_vis := _facing_dir.angle()
	var _arc_spread_vis := deg_to_rad(60.0)
	var _arc_radius_vis := 68.0
	arc_vis.draw.connect(func():
		var pts := PackedVector2Array()
		pts.append(Vector2.ZERO)
		for i in 13:
			var t := float(i) / 12.0
			var a := _angle_base_vis - _arc_spread_vis + t * _arc_spread_vis * 2.0
			pts.append(Vector2(cos(a), sin(a)) * _arc_radius_vis)
		arc_vis.draw_polygon(pts, PackedColorArray([Color(1, 1, 1, 0.35)]))
	)
	arc_vis.queue_redraw()
	get_tree().create_timer(cooldown).timeout.connect(func():
		if is_instance_valid(arc_vis):
			arc_vis.queue_free()
	)

	sprite.play_attack(cooldown)
	SoundManager.play("attack")

func _find_nearest_enemy() -> CharacterBody2D:
	var attack_range: float = GameData.effective_attack_range()
	var best_dist: float = attack_range
	var best_target: CharacterBody2D = null
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is CharacterBody2D:
			continue
		if enemy.get("_state") == 4:  # State.DEAD
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		# Subtract hurtbox radius so large enemies (boss) are targetable at their edge
		var hb: Area2D = enemy.get("hurtbox") as Area2D
		if hb != null and hb.get_child_count() > 0:
			var shape_node: CollisionShape2D = hb.get_child(0) as CollisionShape2D
			if shape_node != null and shape_node.shape is CircleShape2D:
				dist -= (shape_node.shape as CircleShape2D).radius
		if dist < best_dist:
			best_dist = dist
			best_target = enemy
	return best_target

func _do_auto_attack(target: CharacterBody2D) -> void:
	var dir_to_target: Vector2 = (target.global_position - global_position).normalized()
	_facing_dir = dir_to_target
	sprite.set_facing_from_vec(dir_to_target)

	if GameData.player_weapon_type == GameData.WeaponType.RANGED:
		_do_ranged_attack(target)
	else:
		_do_attack()

func _do_ranged_attack(target: CharacterBody2D) -> void:
	var cooldown: float = GameData.effective_attack_cooldown()
	_attack_cooldown = cooldown
	var dmg: int = GameData.effective_attack()

	var strike_count: int = GameData.attacks_per_press()
	for strike: int in strike_count:
		if strike > 0:
			await get_tree().create_timer(0.15).timeout
			if not is_inside_tree():
				return
		_fire_projectile(target, dmg)

	sprite.play_attack(cooldown)
	SoundManager.play("attack")

func _fire_projectile(target: CharacterBody2D, dmg: int) -> void:
	var target_pos: Vector2 = target.global_position if is_instance_valid(target) else global_position + _facing_dir * 200.0
	var Proj: GDScript = load("res://scripts/arena/Projectile.gd")

	var config: Dictionary = {
		"color_core": Color(0.3, 0.6, 1.0, 0.85),
		"color_inner": Color(0.5, 0.8, 1.0, 0.95),
		"color_center": Color(0.85, 0.95, 1.0),
		"color_glow": Color(0.2, 0.5, 1.0, 0.5),
		"max_distance": GameData.effective_attack_range() * 1.2,
		"override_layer": 1 << 3,
		"override_mask": (1 << 2) | (1 << 0),
	}

	Proj.fire(get_parent(), global_position, target_pos, dmg, config)

func get_dash_cooldown_remaining() -> float:
	return maxf(0.0, _dash_cooldown)

func get_dash_cooldown_total() -> float:
	return GameData.effective_dash_cooldown()

func _do_dash() -> void:
	_is_dashing = true
	_dash_dir = _facing_dir
	_dash_timer = GameData.player_dash_duration
	_dash_cooldown = GameData.effective_dash_cooldown()
	SoundManager.play("dash")
	dash_state_changed.emit(_dash_cooldown, GameData.effective_dash_cooldown())
	hurtbox.start_iframes(GameData.player_dash_duration)
	# Visual feedback
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 0.4), 0.05)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1.0), GameData.player_dash_duration)

func _do_interact() -> void:
	# Find nearest interactable in range
	var best_dist := 999999.0
	var best_target: Node2D = null
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is Node2D and node.has_method("interact"):
			var dist := global_position.distance_to(node.global_position)
			if dist < best_dist:
				best_dist = dist
				best_target = node
	if best_target and best_dist <= 120.0:
		best_target.interact()

func _on_hit(damage: int, knockback_dir: Vector2) -> void:
	if _is_dead:
		return
	var actual := maxi(0, damage - GameData.effective_armor())
	GameData.player_health -= actual
	health_bar.update_health(GameData.player_health, GameData.effective_max_health())
	health_changed.emit(GameData.player_health, GameData.effective_max_health())

	_knockback_vel = knockback_dir
	hurtbox.start_iframes(GameData.effective_iframes())
	sprite.play_hurt()
	SoundManager.play("hurt_p")
	_flash_iframes(GameData.effective_iframes())

	# Spawn damage number
	var DmgNum := load("res://scripts/arena/DamageNumber.gd")
	DmgNum.spawn(get_parent(), global_position, actual, Color(1.0, 0.3, 0.2))

	if GameData.player_health <= 0:
		_is_dead = true
		sprite.play_die()
		SoundManager.play("die_p")
		died.emit()

func _flash_iframes(duration: float) -> void:
	var tw := create_tween()
	var flashes := int(duration / 0.1)
	for i in flashes:
		tw.tween_property(sprite, "modulate:a", 0.2, 0.05)
		tw.tween_property(sprite, "modulate:a", 1.0, 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.0)

func grant_iframes(duration: float) -> void:
	hurtbox.start_iframes(duration)
	_flash_iframes(duration)

func get_facing() -> Vector2:
	return _facing_dir

func reset_for_wave() -> void:
	_is_dead = false
	_attack_cooldown = 0.0
	_dash_cooldown = 0.0
	sprite.visible = true
	sprite.modulate = Color.WHITE
	health_bar.update_health(GameData.player_health, GameData.effective_max_health())
