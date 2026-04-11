extends CharacterBody2D

signal enemy_died(enemy: CharacterBody2D)

enum State { IDLE, CHASE, ATTACK, COOLDOWN, DEAD }

var etype: int = 0
var health: int = 35
var max_health: int = 35
var attack_damage: int = 9
var armor: int = 2
var move_speed: float = 60.0
var attack_range: float = 45.0
var attack_cooldown: float = 1.5

var sprite: Node2D
var hurtbox: Area2D
var health_bar_node: Node2D
var player_ref: CharacterBody2D = null

var _state: int = State.IDLE
var _state_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _separation_force: float = 80.0

# Hellhound charge
var _charge_windup: float = 0.0
var _charge_burst: float = 0.0
var _is_charging: bool = false

# Imp erratic
var _erratic_offset: Vector2 = Vector2.ZERO
var _erratic_timer: float = 0.0

func init(et: int, player: CharacterBody2D) -> void:
	etype = et
	player_ref = player
	var s := GameData.wave_scale()
	health = int(GameData.ENEMY_BASE[et][0] * s)
	max_health = health
	attack_damage = int(GameData.ENEMY_BASE[et][1] * s)
	armor = int(GameData.ENEMY_BASE[et][3] * s)
	move_speed = GameData.enemy_speed(et)

	match et:
		0:  # DEMON
			attack_range = 45.0; attack_cooldown = 1.5
		1:  # IMP
			attack_range = 35.0; attack_cooldown = 0.8; move_speed *= 1.0
		2:  # HELLHOUND
			attack_range = 40.0; attack_cooldown = 1.2

func _ready() -> void:
	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	col.shape = shape
	add_child(col)
	collision_layer = 1 << 2  # layer 3: enemy_body
	collision_mask = (1 << 0) | (1 << 1) | (1 << 2)  # world + player + other enemies

	# Sprite
	sprite = Node2D.new()
	sprite.set_script(load("res://scripts/arena/EnemyArenaSprite.gd"))
	sprite.etype = etype
	add_child(sprite)
	sprite.start_idle()

	# Hurtbox
	hurtbox = Area2D.new()
	hurtbox.set_script(load("res://scripts/arena/Hurtbox.gd"))
	hurtbox.collision_layer = 1 << 2  # layer 3: enemy_body (for player hitbox detection)
	hurtbox.collision_mask = 1 << 3   # layer 4: player_attack
	var hb_shape := CollisionShape2D.new()
	var hb_circle := CircleShape2D.new()
	hb_circle.radius = 16.0
	hb_shape.shape = hb_circle
	hurtbox.add_child(hb_shape)
	add_child(hurtbox)
	hurtbox.hit_received.connect(_on_hit)

	# Health bar
	health_bar_node = Node2D.new()
	health_bar_node.set_script(load("res://scripts/arena/HealthBar.gd"))
	add_child(health_bar_node)

	_state = State.IDLE
	_state_timer = 0.5  # spawn delay

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if not is_instance_valid(player_ref):
		return

	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 500.0 * delta)

	match _state:
		State.IDLE:    _process_idle(delta)
		State.CHASE:   _process_chase(delta)
		State.ATTACK:  _process_attack(delta)
		State.COOLDOWN: _process_cooldown(delta)

func _process_idle(delta: float) -> void:
	_state_timer -= delta
	_face_player()
	velocity = _knockback_vel
	move_and_slide()
	if _state_timer <= 0.0:
		_change_state(State.CHASE)

func _process_chase(delta: float) -> void:
	var to_player := player_ref.global_position - global_position
	var dist := to_player.length()

	if dist < attack_range:
		_change_state(State.ATTACK)
		return

	var dir := to_player.normalized()

	# Imp erratic movement
	if etype == 1:
		_erratic_timer -= delta
		if _erratic_timer <= 0.0:
			_erratic_timer = randf_range(0.2, 0.5)
			_erratic_offset = dir.orthogonal() * randf_range(-0.5, 0.5)
		dir = (dir + _erratic_offset).normalized()

	# Hellhound charge
	var spd := move_speed
	if etype == 2:
		if not _is_charging:
			_charge_windup += delta
			if _charge_windup >= 0.3:
				_is_charging = true
				_charge_burst = 0.5
				_charge_windup = 0.0
		else:
			_charge_burst -= delta
			spd *= 2.0
			if _charge_burst <= 0.0:
				_is_charging = false

	# Separation from other enemies
	var sep := _get_separation()
	dir = (dir + sep * 0.5).normalized()

	velocity = dir * spd + _knockback_vel
	_face_player()
	sprite.start_walk()
	move_and_slide()

func _process_attack(_delta: float) -> void:
	velocity = _knockback_vel
	move_and_slide()
	_state_timer -= _delta

	if _state_timer <= 0.0:
		# Deal damage to player if in range
		var dist := global_position.distance_to(player_ref.global_position)
		if dist < attack_range * 1.5:
			var dir := (player_ref.global_position - global_position).normalized()
			if player_ref.hurtbox:
				player_ref.hurtbox.receive_hit(attack_damage, dir * 120.0)

			# Spikes reflection
			if GameData.player_spikes > 0:
				var spike_dmg := maxi(0, GameData.player_spikes - armor)
				if spike_dmg > 0:
					_take_damage(spike_dmg, -dir)

		_change_state(State.COOLDOWN)

func _process_cooldown(delta: float) -> void:
	_cooldown_timer -= delta
	velocity = _knockback_vel
	move_and_slide()
	_face_player()
	if _cooldown_timer <= 0.0:
		_change_state(State.CHASE)

func _change_state(new_state: int) -> void:
	_state = new_state
	match new_state:
		State.CHASE:
			sprite.start_walk()
			if etype == 2:
				_charge_windup = 0.0
				_is_charging = false
		State.ATTACK:
			sprite._stop_walk()
			sprite.start_idle()
			_state_timer = 0.3  # wind-up before hit
			# Lunge visual
			var dir := (player_ref.global_position - global_position).normalized()
			var tw := create_tween()
			tw.tween_property(self, "position", position + dir * 8, 0.1)
			tw.tween_property(self, "position", position, 0.15).set_trans(Tween.TRANS_ELASTIC)
		State.COOLDOWN:
			_cooldown_timer = attack_cooldown
			sprite.start_idle()
		State.DEAD:
			sprite._stop_walk()
			collision_layer = 0
			collision_mask = 0
			hurtbox.collision_layer = 0
			hurtbox.collision_mask = 0

func _face_player() -> void:
	if is_instance_valid(player_ref):
		var dir := (player_ref.global_position - global_position).normalized()
		sprite.set_facing_from_vec(dir)

func _on_hit(damage: int, knockback_dir: Vector2) -> void:
	if _state == State.DEAD:
		return
	var actual := maxi(0, damage - armor)
	_take_damage(actual, knockback_dir)

func _take_damage(amount: int, knockback_dir: Vector2) -> void:
	if _state == State.DEAD:
		return
	health -= amount
	_knockback_vel = knockback_dir
	health_bar_node.update_health(health, max_health)
	sprite.play_hurt()

	# Damage number
	var DmgNum := load("res://scripts/arena/DamageNumber.gd")
	DmgNum.spawn(get_parent(), global_position, amount)

	if health <= 0:
		_change_state(State.DEAD)
		sprite.play_die()
		await get_tree().create_timer(0.5).timeout
		enemy_died.emit(self)
		queue_free()

func _get_separation() -> Vector2:
	var sep := Vector2.ZERO
	for body in get_tree().get_nodes_in_group("enemies"):
		if body == self or not is_instance_valid(body):
			continue
		var diff: Vector2 = global_position - body.global_position
		var dist := diff.length()
		if dist < 40.0 and dist > 0.01:
			sep += diff.normalized() * (40.0 - dist) / 40.0
	return sep
