extends CharacterBody2D

signal health_changed(current: int, mx: int)
signal died()
signal dash_state_changed(cooldown_remaining: float, cooldown_total: float)

var sprite: Node2D
var hurtbox: Area2D
var health_bar: Node2D
var _fork: Node2D
var _attack_overlay: Node2D

var _attack_cooldown: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_timer: float = 0.0
var _is_dashing: bool = false
var _dash_dir: Vector2 = Vector2.DOWN
var _knockback_vel: Vector2 = Vector2.ZERO
var _facing_dir: Vector2 = Vector2.DOWN
var _is_dead: bool = false
var _attack_grace: float = 0.0

func _ready() -> void:
	add_to_group("player")
	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)

	# Sprite
	sprite = Node2D.new()
	sprite.set_script(load("res://scripts/arena/PlayerArenaSprite.gd"))
	sprite.scale = Vector2(0.35, 0.35)
	sprite.position.y = -12.0
	add_child(sprite)
	sprite.start_idle()

	# Sword weapon (visual only)
	_fork = Node2D.new()
	_fork.set_script(load("res://scripts/arena/ForkWeapon.gd"))
	_fork.z_index = 10
	_fork.position.y = -12.0
	add_child(_fork)

	# Attack overlay (range circle + cone flash)
	_attack_overlay = Node2D.new()
	_attack_overlay.set_script(load("res://scripts/arena/PlayerAttackOverlay.gd"))
	_attack_overlay.position = Vector2(0, -12)
	add_child(_attack_overlay)

	# Hurtbox
	hurtbox = Area2D.new()
	hurtbox.set_script(load("res://scripts/arena/Hurtbox.gd"))
	hurtbox.position.y = -8.0
	hurtbox.collision_layer = 1 << 1
	hurtbox.collision_mask = 1 << 4
	var hb_shape := CollisionShape2D.new()
	var hb_circle := CircleShape2D.new()
	hb_circle.radius = 14.0
	hb_shape.shape = hb_circle
	hurtbox.add_child(hb_shape)
	add_child(hurtbox)
	hurtbox.hit_received.connect(_on_hit)

	# Health bar
	health_bar = Node2D.new()
	health_bar.set_script(load("res://scripts/arena/HealthBar.gd"))
	health_bar.bar_width = 48.0
	health_bar.y_offset = -46.0
	add_child(health_bar)

	# Body collision
	collision_layer = 1 << 1
	collision_mask = (1 << 0) | (1 << 2) | (1 << 6)

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
		velocity = _dash_dir * GameData.player_dash_speed
	else:
		var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_dir.normalized() * GameData.effective_speed() + _knockback_vel

		if input_dir.length_squared() > 0.01:
			sprite.start_walk()
		else:
			if sprite._is_walking:
				sprite._stop_walk()
				sprite.start_idle()

		# Face the mouse cursor (LEFT=2, RIGHT=3 from SpriteBase.Facing)
		var mouse_dir: Vector2 = (get_global_mouse_position() - global_position).normalized()
		if mouse_dir.length_squared() > 0.001:
			var new_facing: int = 3 if mouse_dir.x >= 0.0 else 2
			if sprite.facing != new_facing:
				sprite.facing = new_facing
				sprite._apply_flip()
			_facing_dir = mouse_dir

	# Hold-to-attack: left mouse button
	if _attack_grace > 0.0:
		_attack_grace -= delta
	elif _attack_cooldown <= 0.0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_do_mouse_attack()

	# Knockback decay
	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 520.0 * delta)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return

	if event.is_action_pressed("dash") and _dash_cooldown <= 0.0 and not _is_dashing:
		_do_dash()

	if event.is_action_pressed("interact"):
		_do_interact()

func _do_mouse_attack() -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	var dir: Vector2 = (mouse_pos - global_position).normalized()
	if dir.length_squared() < 0.001:
		dir = _facing_dir
	_facing_dir = dir

	var cooldown: float = GameData.effective_attack_cooldown()
	_attack_cooldown = cooldown

	# Instant cone damage
	var atk_range: float = GameData.effective_attack_range()
	var dmg: int = GameData.effective_attack()
	var strikes: int = GameData.attacks_per_press()
	var half_arc: float = TAU / 6.0
	var dir_angle: float = dir.angle()

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > atk_range:
			continue
		var angle_diff: float = absf(wrapf(dir_angle - to_enemy.angle(), -PI, PI))
		if angle_diff > half_arc:
			continue
		if enemy.hurtbox:
			var kb_dir: Vector2 = to_enemy.normalized()
			if kb_dir == Vector2.ZERO:
				kb_dir = dir
			for i in strikes:
				enemy.hurtbox.receive_hit(dmg, kb_dir * 130.0)

	_attack_overlay.flash_cone(dir)
	_fork.start_swing(dir, cooldown)
	sprite.play_attack(cooldown)
	SoundManager.play("attack")

func get_dash_cooldown_remaining() -> float:
	return maxf(0.0, _dash_cooldown)

func get_dash_cooldown_total() -> float:
	return GameData.effective_dash_cooldown()

func _do_dash() -> void:
	_is_dashing = true
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	_dash_dir = input_dir.normalized() if input_dir.length_squared() > 0.01 else _facing_dir
	_dash_timer = GameData.player_dash_duration
	_dash_cooldown = GameData.effective_dash_cooldown()
	SoundManager.play("dash")
	dash_state_changed.emit(_dash_cooldown, GameData.effective_dash_cooldown())
	hurtbox.start_iframes(GameData.player_dash_duration)

func _do_interact() -> void:
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
