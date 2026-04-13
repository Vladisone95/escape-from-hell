extends Area2D

signal hit_received(damage: int, knockback_dir: Vector2)

var i_frames_timer: float = 0.0

func _ready() -> void:
	# Keep collision_layer and collision_mask set by the parent script
	pass

func _physics_process(delta: float) -> void:
	if i_frames_timer > 0.0:
		i_frames_timer -= delta

func receive_hit(damage: int, knockback_dir: Vector2) -> void:
	if i_frames_timer > 0.0:
		return
	hit_received.emit(damage, knockback_dir)

func start_iframes(duration: float) -> void:
	i_frames_timer = duration
