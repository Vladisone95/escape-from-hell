extends CharacterBody2D

signal enemy_died(enemy: CharacterBody2D)
signal health_changed(current: int, mx: int)
signal boss_segment_lost(order_index: int)

enum State { IDLE, CHASE, ATTACK, COOLDOWN, DEAD }

var etype: int = 0
var health: int = 35
var max_health: int = 35
var attack_damage: int = 9
var armor: int = 2
var move_speed: float = 60.0
var attack_range: float = 45.0
var attack_cooldown: float = 1.5
var projectile_config: Dictionary = {}

var sprite: Node2D
var hurtbox: Area2D
var health_bar_node: Node2D
var player_ref: CharacterBody2D = null

var _state: int = State.IDLE
var _state_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _knockback_vel: Vector2 = Vector2.ZERO
var _separation_force: float = 160.0

# Hellhound charge
var _charge_windup: float = 0.0
var _charge_burst: float = 0.0
var _is_charging: bool = false

# Imp erratic
var _erratic_offset: Vector2 = Vector2.ZERO
var _erratic_timer: float = 0.0

# Attack telegraph
var _telegraph_node: Node2D = null
var _attack_dir: Vector2 = Vector2.RIGHT

# Warlock channel
var _channel_node: Node2D = null
var _channel_timer: float = 0.0
var _channel_duration: float = 1.0
var _channel_target: Vector2 = Vector2.ZERO

# Boss attack pattern cycling
var _boss_attack_pattern: int = 0
var _boss_segments_lost: int = 0

func init(et: int, player: CharacterBody2D) -> void:
	etype = et
	player_ref = player
	var type_name: String = EnemyStats.TYPE_ID.find_key(et)
	var stats: Dictionary = EnemyStats.get_stats(type_name, GameData.current_wave)
	health = stats["health"]
	max_health = health
	attack_damage = stats["attack"]
	armor = stats["armor"]
	move_speed = stats["speed"]
	attack_range = stats["attack_range"]
	attack_cooldown = stats["attack_cooldown"]
	if stats.has("projectile"):
		projectile_config = stats["projectile"]

func _ready() -> void:
	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	if etype == 5:       # VANITY_BOSS — large collision so player bumps into body
		shape.radius = 160.0
	elif etype == 4:     # ABOMINATION
		shape.radius = 44.0
	else:
		shape.radius = 24.0
	col.shape = shape
	add_child(col)
	collision_layer = 1 << 2  # layer 3: enemy_body
	collision_mask = (1 << 0) | (1 << 1) | (1 << 2)  # world + player + other enemies

	# Sprite
	sprite = Node2D.new()
	if etype == 5:  # VANITY_BOSS uses its own sprite
		sprite.set_script(load("res://scripts/arena/VanityBossSprite.gd"))
		sprite.scale = Vector2(2, 2)
	else:
		sprite.set_script(load("res://scripts/arena/EnemyArenaSprite.gd"))
		sprite.etype = etype
		sprite.scale = Vector2(2, 2)
	add_child(sprite)
	sprite.start_idle()

	# Hurtbox
	hurtbox = Area2D.new()
	hurtbox.set_script(load("res://scripts/arena/Hurtbox.gd"))
	hurtbox.collision_layer = 1 << 2  # layer 3: enemy_body (for player hitbox detection)
	hurtbox.collision_mask = 1 << 3   # layer 4: player_attack
	var hb_shape := CollisionShape2D.new()
	var hb_circle := CircleShape2D.new()
	if etype == 5:       # VANITY_BOSS — covers body + arms so melee can hit anywhere
		hb_circle.radius = 320.0
	elif etype == 4:     # ABOMINATION
		hb_circle.radius = 60.0
	else:
		hb_circle.radius = 32.0
	hb_shape.shape = hb_circle
	hurtbox.add_child(hb_shape)
	add_child(hurtbox)
	hurtbox.hit_received.connect(_on_hit)

	# Health bar
	health_bar_node = Node2D.new()
	health_bar_node.set_script(load("res://scripts/arena/HealthBar.gd"))
	health_bar_node.y_offset = -(hb_circle.radius + 12.0)
	add_child(health_bar_node)

	# Debug stat labels above head
	var debug_label := RichTextLabel.new()
	debug_label.name = "DebugStats"
	debug_label.bbcode_enabled = true
	debug_label.fit_content = true
	debug_label.scroll_active = false
	debug_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	debug_label.size = Vector2(160, 60)
	debug_label.position = Vector2(-80, -56)
	debug_label.add_theme_font_size_override("normal_font_size", 11)
	debug_label.add_theme_color_override("default_color", Color.WHITE)
	debug_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(debug_label)

	_state = State.IDLE
	_state_timer = 0.5  # spawn delay

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if not is_instance_valid(player_ref):
		return

	_knockback_vel = _knockback_vel.move_toward(Vector2.ZERO, 1000.0 * delta)

	var dl := get_node_or_null("DebugStats") as RichTextLabel
	if dl:
		dl.text = "[center][color=green]%d[/color] [color=red]%d[/color][/center]" % [health, attack_damage]

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

	# Stationary boss — just face player, no movement
	if move_speed <= 0.0:
		_face_player()
		velocity = _knockback_vel
		move_and_slide()
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

	# Warlock channeling phase
	if etype == 3 and _channel_node != null:
		_channel_timer += _delta
		var progress := clampf(_channel_timer / _channel_duration, 0.0, 1.0)
		_update_channel_orb(progress)
		if _channel_timer >= _channel_duration:
			# Fire the projectile
			sprite.play_cast()
			var Proj := load("res://scripts/arena/Projectile.gd")
			var fire_target := _channel_target
			if is_instance_valid(player_ref):
				fire_target = player_ref.global_position
			Proj.fire(get_parent(), global_position, fire_target, attack_damage, projectile_config)
			_clear_channel()
			_change_state(State.COOLDOWN)
		return

	if _state_timer <= 0.0:
		if etype == 5:  # VANITY_BOSS — cycling projectile patterns
			sprite.play_cast()
			var Proj := load("res://scripts/arena/Projectile.gd")
			var pattern := _boss_attack_pattern
			_boss_attack_pattern = (_boss_attack_pattern + 1) % 3
			match pattern:
				0:  # Mirror shards: 8 projectiles in spread toward player
					var to_p := (player_ref.global_position - global_position).normalized()
					var base_angle := to_p.angle()
					for i in range(8):
						var a := base_angle + deg_to_rad(-36.0 + 9.0 * i)
						var dir := Vector2(cos(a), sin(a))
						Proj.fire(get_parent(), global_position, global_position + dir * 800.0, attack_damage, projectile_config)
				1:  # Makeup explosion: 12 projectiles in ring
					for i in range(12):
						var angle := (TAU / 12.0) * i
						var dir := Vector2(cos(angle), sin(angle))
						Proj.fire(get_parent(), global_position, global_position + dir * 800.0, attack_damage, projectile_config)
				2:  # Comb swipe: 3 lines of 5 toward player
					var to_p := (player_ref.global_position - global_position).normalized()
					var base_angle := to_p.angle()
					for j in range(3):
						var offset_angle := base_angle + deg_to_rad(-15.0 + 15.0 * j)
						var dir := Vector2(cos(offset_angle), sin(offset_angle))
						for k in range(5):
							var spawn_pos := global_position + dir * (50.0 * k)
							Proj.fire(get_parent(), spawn_pos, spawn_pos + dir * 800.0, attack_damage, projectile_config)
			_change_state(State.COOLDOWN)
		elif etype == 4:  # ABOMINATION — 12 projectiles from outer edge
			sprite.play_cast()
			var Proj := load("res://scripts/arena/Projectile.gd")
			var edge_radius := 66.0  # spawn from outer edge of the body
			for i in range(12):
				var angle := (TAU / 12.0) * i
				var dir := Vector2(cos(angle), sin(angle))
				var spawn_pos := global_position + dir * edge_radius
				Proj.fire(get_parent(), spawn_pos, spawn_pos + dir * 400.0, attack_damage, projectile_config)
		elif etype == 3:  # WARLOCK — start channeling
			sprite.play_cast()
			_channel_timer = 0.0
			if is_instance_valid(player_ref):
				_channel_target = player_ref.global_position
			_spawn_channel_orb()
			return  # Don't transition to cooldown yet
		else:
			# Deal damage to player if in the telegraphed arc
			var to_player := player_ref.global_position - global_position
			var dist := to_player.length()
			var hit_reach := attack_range * 1.5
			var in_range := dist < hit_reach
			var angle_diff := absf(_attack_dir.angle_to(to_player.normalized()))
			var in_arc := angle_diff < deg_to_rad(45.0)
			if in_range and in_arc:
				var dir := to_player.normalized()
				if player_ref.hurtbox:
					player_ref.hurtbox.receive_hit(attack_damage, dir * 240.0)

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
			_state_timer = 0.5 if etype == 5 else 0.3  # boss gets longer wind-up
			if etype != 3 and etype != 4 and etype != 5:  # Non-ranged: melee telegraph
				_attack_dir = (player_ref.global_position - global_position).normalized()
				_spawn_melee_telegraph()
				var dir := _attack_dir
				var tw := create_tween()
				tw.tween_property(self, "position", position + dir * 8, 0.1)
				tw.tween_property(self, "position", position, 0.15).set_trans(Tween.TRANS_ELASTIC)
		State.COOLDOWN:
			_cooldown_timer = attack_cooldown
			sprite.start_idle()
			_clear_telegraph()
			_clear_channel()
		State.DEAD:
			sprite._stop_walk()
			_clear_telegraph()
			_clear_channel()
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
	if etype != 5:  # Boss is too heavy for knockback
		_knockback_vel = knockback_dir
	health_bar_node.update_health(health, max_health)
	health_changed.emit(health, max_health)
	sprite.play_hurt()

	# Boss HP segment check — destroy arm + meteor per 10% lost
	if etype == 5 and health > 0:
		var segment_size: float = float(max_health) / 10.0
		var new_segments_lost: int = clampi(int(ceil(float(max_health - health) / segment_size)), 0, 10)
		while _boss_segments_lost < new_segments_lost:
			sprite.destroy_arm(_boss_segments_lost)
			boss_segment_lost.emit(_boss_segments_lost)
			_boss_segments_lost += 1

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
		if dist < 60.0 and dist > 0.01:
			sep += diff.normalized() * (80.0 - dist) / 80.0
	return sep

func _clear_telegraph() -> void:
	if is_instance_valid(_telegraph_node):
		_telegraph_node.queue_free()
	_telegraph_node = null

func _spawn_melee_telegraph() -> void:
	_clear_telegraph()
	var hit_reach := attack_range * 1.5
	var dir := _attack_dir
	var angle_base := dir.angle()
	var arc_spread := deg_to_rad(45.0)

	_telegraph_node = Node2D.new()
	_telegraph_node.z_index = -1
	get_parent().add_child(_telegraph_node)
	_telegraph_node.global_position = global_position

	# Capture for draw closure
	var _t_angle := angle_base
	var _t_spread := arc_spread
	var _t_reach := hit_reach
	var _t_color := Color(1.0, 0.15, 0.05, 0.0)
	var tnode := _telegraph_node

	tnode.draw.connect(func():
		# Draw filled arc fan
		var pts := PackedVector2Array()
		pts.append(Vector2.ZERO)
		for i in 13:
			var t := float(i) / 12.0
			var a := _t_angle - _t_spread + t * _t_spread * 2.0
			pts.append(Vector2(cos(a), sin(a)) * _t_reach)
		tnode.draw_polygon(pts, PackedColorArray([_t_color]))
		# Edge outline
		for i in 12:
			var t0 := float(i) / 12.0
			var t1 := float(i + 1) / 12.0
			var a0 := _t_angle - _t_spread + t0 * _t_spread * 2.0
			var a1 := _t_angle - _t_spread + t1 * _t_spread * 2.0
			tnode.draw_line(
				Vector2(cos(a0), sin(a0)) * _t_reach,
				Vector2(cos(a1), sin(a1)) * _t_reach,
				Color(1.0, 0.3, 0.1, _t_color.a * 2.0), 1.5)
		tnode.draw_line(Vector2.ZERO, Vector2(cos(_t_angle - _t_spread), sin(_t_angle - _t_spread)) * _t_reach, Color(1.0, 0.3, 0.1, _t_color.a * 2.0), 1.5)
		tnode.draw_line(Vector2.ZERO, Vector2(cos(_t_angle + _t_spread), sin(_t_angle + _t_spread)) * _t_reach, Color(1.0, 0.3, 0.1, _t_color.a * 2.0), 1.5)
	)

	# Animate: fade in over the wind-up period, then flash on hit
	var tw := create_tween()
	tw.tween_method(func(alpha: float):
		_t_color.a = alpha
		if is_instance_valid(tnode):
			tnode.queue_redraw()
	, 0.0, 0.3, 0.2)  # fade in over 0.2s
	tw.tween_method(func(alpha: float):
		_t_color.a = alpha
		if is_instance_valid(tnode):
			tnode.queue_redraw()
	, 0.3, 0.5, 0.1)  # brighten at hit moment

func _clear_channel() -> void:
	if is_instance_valid(_channel_node):
		_channel_node.queue_free()
	_channel_node = null

func _spawn_channel_orb() -> void:
	_clear_channel()
	_channel_node = Node2D.new()
	_channel_node.z_index = 2
	add_child(_channel_node)
	_channel_node.position = Vector2.ZERO

	var cfg := projectile_config
	var core_col: Color = cfg.get("color_core", Color(1.0, 0.45, 0.05, 0.85))
	var inner_col: Color = cfg.get("color_inner", Color(1.0, 0.7, 0.1, 0.95))
	var center_col: Color = cfg.get("color_center", Color(1.0, 0.95, 0.7))
	var glow_col: Color = cfg.get("color_glow", Color(1.0, 0.3, 0.0, 0.5))
	var final_radius: float = cfg.get("radius", 16.0)

	var _ch_progress := 0.0
	var _ch_flicker := 0.0
	var cnode := _channel_node

	cnode.draw.connect(func():
		var r := lerpf(3.0, final_radius, _ch_progress)
		var glow_r := r + 6.0 + sin(_ch_flicker) * 2.0
		# Pulsing glow ring
		var ring_alpha := 0.15 + _ch_progress * 0.3
		_draw_arc_segments(cnode, Vector2.ZERO, glow_r + 4.0, 0.0, TAU, 32,
			Color(glow_col.r, glow_col.g, glow_col.b, ring_alpha), 2.0)
		# Glow
		cnode.draw_circle(Vector2.ZERO, glow_r, Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * _ch_progress))
		# Core
		cnode.draw_circle(Vector2.ZERO, r, Color(core_col.r, core_col.g, core_col.b, core_col.a * _ch_progress))
		# Inner
		cnode.draw_circle(Vector2.ZERO, r * 0.625, Color(inner_col.r, inner_col.g, inner_col.b, inner_col.a * _ch_progress))
		# Center bright spot
		cnode.draw_circle(Vector2.ZERO, r * 0.3125, Color(center_col.r, center_col.g, center_col.b, _ch_progress))
		# Direction indicator line toward target
		if is_instance_valid(player_ref):
			var dir_to_player := (player_ref.global_position - global_position).normalized()
			var line_len := 30.0 + _ch_progress * 20.0
			var line_alpha := 0.2 + _ch_progress * 0.5
			cnode.draw_line(dir_to_player * (r + 4.0), dir_to_player * (r + line_len),
				Color(core_col.r, core_col.g, core_col.b, line_alpha), 2.0)
	)

	# Store references for updating
	_channel_node.set_meta("progress", 0.0)
	_channel_node.set_meta("flicker", 0.0)
	_channel_node.set_meta("set_progress", func(p: float, f: float):
		_ch_progress = p
		_ch_flicker = f
		if is_instance_valid(cnode):
			cnode.queue_redraw()
	)

func _update_channel_orb(progress: float) -> void:
	if not is_instance_valid(_channel_node):
		return
	var setter = _channel_node.get_meta("set_progress", null)
	if setter:
		var flicker := _channel_timer * 10.0
		setter.call(progress, flicker)

func _draw_arc_segments(node: Node2D, center: Vector2, r: float, start: float, end: float, segments: int, color: Color, width: float) -> void:
	for i in segments:
		var a0 := start + (end - start) * float(i) / float(segments)
		var a1 := start + (end - start) * float(i + 1) / float(segments)
		node.draw_line(center + Vector2(cos(a0), sin(a0)) * r, center + Vector2(cos(a1), sin(a1)) * r, color, width)
