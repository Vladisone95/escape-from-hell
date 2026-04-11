extends CharacterBody2D

signal health_changed(current: int, mx: int)
signal died()

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
var _regen_timer: float = 0.0
var _is_dead: bool = false

func _ready() -> void:
	# Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	add_child(col)

	# Sprite
	sprite = Node2D.new()
	sprite.set_script(load("res://scripts/arena/PlayerArenaSprite.gd"))
	add_child(sprite)
	sprite.start_idle()

	# Hurtbox
	hurtbox = Area2D.new()
	hurtbox.set_script(load("res://scripts/arena/Hurtbox.gd"))
	hurtbox.collision_layer = 1 << 1  # layer 2: player_body
	hurtbox.collision_mask = 1 << 4   # layer 5: enemy_attack
	var hb_shape := CollisionShape2D.new()
	var hb_circle := CircleShape2D.new()
	hb_circle.radius = 16.0
	hb_shape.shape = hb_circle
	hurtbox.add_child(hb_shape)
	add_child(hurtbox)
	hurtbox.hit_received.connect(_on_hit)

	# Health bar
	health_bar = Node2D.new()
	health_bar.set_script(load("res://scripts/arena/HealthBar.gd"))
	health_bar.bar_width = 40.0
	add_child(health_bar)

	# Body collision
	collision_layer = 1 << 1  # layer 2
	collision_mask = (1 << 0) | (1 << 2)  # layer 1 (world) + layer 3 (enemy_body)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	# Timers
	_attack_cooldown -= delta
	_dash_cooldown -= delta
	_regen_timer += delta

	# Regen every 5s
	if _regen_timer >= 5.0:
		_regen_timer -= 5.0
		var regen := GameData.effective_regen()
		var max_hp := GameData.effective_max_health()
		if regen > 0 and GameData.player_health < max_hp:
			GameData.player_health = mini(GameData.player_health + regen, max_hp)
			health_bar.update_health(GameData.player_health, max_hp)
			health_changed.emit(GameData.player_health, max_hp)

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
		velocity = input_dir.normalized() * GameData.player_speed + _knockback_vel

		if input_dir.length_squared() > 0.01:
			_facing_dir = input_dir.normalized()
			sprite.set_facing_from_vec(_facing_dir)
			sprite.start_walk()
		else:
			if sprite._is_walking:
				sprite._stop_walk()
				sprite.start_idle()

	# Knockback decay
	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 600.0 * delta)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return

	if event.is_action_pressed("attack") and _attack_cooldown <= 0.0:
		_do_attack()

	if event.is_action_pressed("dash") and _dash_cooldown <= 0.0 and not _is_dashing:
		_do_dash()

	if event.is_action_pressed("interact"):
		_do_interact()

func _do_attack() -> void:
	var cooldown := GameData.player_attack_cooldown
	if GameData.attacks_per_turn() > 1:
		cooldown *= 0.6
	_attack_cooldown = cooldown

	var dmg := GameData.effective_attack()
	var AttackHitbox := load("res://scripts/arena/AttackHitbox.gd")

	# Create arc hitbox
	var hitbox := Area2D.new()
	hitbox.set_script(AttackHitbox)
	hitbox.damage = dmg
	hitbox.knockback_force = 150.0
	hitbox.source = self
	hitbox.position = _facing_dir * 20.0
	hitbox.collision_layer = 1 << 3  # layer 4: player_attack
	hitbox.collision_mask = 1 << 2   # layer 3: enemy_body — actually we need enemy hurtbox

	# Build arc collision
	var angle_base := _facing_dir.angle()
	var arc_spread := deg_to_rad(60.0)
	for i in 5:
		var t := float(i) / 4.0
		var a := angle_base - arc_spread + t * arc_spread * 2.0
		var offset := Vector2(cos(a), sin(a)) * 20.0
		var s := CollisionShape2D.new()
		var c := CircleShape2D.new()
		c.radius = 14.0
		s.shape = c
		s.position = offset
		hitbox.add_child(s)

	# Hitbox detects enemy hurtboxes
	hitbox.collision_layer = 1 << 3  # layer 4: player_attack
	hitbox.collision_mask = 0  # We detect via area_entered with hurtboxes

	get_parent().add_child(hitbox)
	hitbox.global_position = global_position + _facing_dir * 20.0

	# Connect to detect hurtboxes
	var hit_targets: Array[Node] = []
	hitbox.area_entered.connect(func(area: Area2D):
		if area == hurtbox:
			return
		if area.has_method("receive_hit") and area not in hit_targets:
			hit_targets.append(area)
			var dir := (_facing_dir).normalized()
			area.receive_hit(dmg, dir * 150.0)
	)

	sprite.play_attack()

	# Hitbox lifetime
	get_tree().create_timer(0.15).timeout.connect(func():
		if is_instance_valid(hitbox):
			hitbox.queue_free()
	)

func _do_dash() -> void:
	_is_dashing = true
	_dash_dir = _facing_dir
	_dash_timer = GameData.player_dash_duration
	_dash_cooldown = GameData.player_dash_cooldown
	hurtbox.start_iframes(GameData.player_dash_duration)
	# Visual feedback
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 0.4), 0.05)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1.0), GameData.player_dash_duration)

func _do_interact() -> void:
	# Check for nearby interactable areas
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = global_position + _facing_dir * 30.0
	query.collision_mask = 1 << 5  # We'll use a specific interact layer later
	var results := space.intersect_point(query, 4)
	for r in results:
		var collider = r["collider"]
		if collider.has_method("interact"):
			collider.interact()
			return

func _on_hit(damage: int, knockback_dir: Vector2) -> void:
	if _is_dead:
		return
	var actual := maxi(0, damage - GameData.player_armor)
	GameData.player_health -= actual
	health_bar.update_health(GameData.player_health, GameData.effective_max_health())
	health_changed.emit(GameData.player_health, GameData.effective_max_health())

	_knockback_vel = knockback_dir
	hurtbox.start_iframes(GameData.player_iframes)
	sprite.play_hurt()

	# Spawn damage number
	var DmgNum := load("res://scripts/arena/DamageNumber.gd")
	DmgNum.spawn(get_parent(), global_position, actual, Color(1.0, 0.3, 0.2))

	if GameData.player_health <= 0:
		_is_dead = true
		sprite.play_die()
		died.emit()

func get_facing() -> Vector2:
	return _facing_dir

func reset_for_wave() -> void:
	_is_dead = false
	_attack_cooldown = 0.0
	_dash_cooldown = 0.0
	_regen_timer = 0.0
	sprite.visible = true
	sprite.modulate = Color.WHITE
	health_bar.update_health(GameData.player_health, GameData.effective_max_health())
