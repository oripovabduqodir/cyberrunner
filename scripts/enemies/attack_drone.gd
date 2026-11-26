extends EnemyBase
class_name AttackDrone

## Havoda patrul qiluvchi, ogohlantiruvchi va energiya snaryadini otuvchi dron.

@export_group("Attack Drone")
@export var patrol_speed: float = 95.0
@export var patrol_distance: float = 160.0
@export var projectile_speed: float = 360.0
@export var warning_duration: float = 0.42

@onready var muzzle: Marker2D = $Muzzle

var _origin_pos: Vector2
var _bob_time: float = 0.0
var _is_warning: bool = false


func _ready() -> void:
	super._ready()
	_origin_pos = global_position
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_bob_time += delta * 2.6

	if _is_warning:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _can_see_player():
		current_state = State.CHASE
		var dir_vec: Vector2 = _player_ref.global_position - global_position
		_face_direction(1 if dir_vec.x >= 0.0 else -1)

		if _distance_to_player() <= attack_range and attack_cooldown_timer.is_stopped():
			_begin_attack_warning()
			return

		# Ma'lum masofani saqlab yaqinlashish
		if _distance_to_player() > 160.0:
			velocity = dir_vec.normalized() * patrol_speed
		else:
			velocity = Vector2(0.0, sin(_bob_time) * 28.0)
	else:
		current_state = State.PATROL
		var offset_x: float = global_position.x - _origin_pos.x
		if offset_x > patrol_distance:
			_face_direction(-1)
		elif offset_x < -patrol_distance:
			_face_direction(1)

		velocity.x = _facing_dir * patrol_speed
		velocity.y = sin(_bob_time) * 32.0

	move_and_slide()
	if animated_sprite.animation != &"hover":
		animated_sprite.play(&"hover")


func _begin_attack_warning() -> void:
	current_state = State.ATTACK
	_is_warning = true
	attack_cooldown_timer.start(attack_cooldown)
	animated_sprite.play(&"warn")

	await get_tree().create_timer(warning_duration).timeout
	if current_state == State.DEAD or not is_instance_valid(self):
		return

	if _player_ref != null and is_instance_valid(_player_ref) and _can_see_player():
		var aim_dir: Vector2 = (_player_ref.global_position - muzzle.global_position).normalized()
		_spawn_enemy_projectile(muzzle.global_position, aim_dir, projectile_speed)

	_is_warning = false
	if current_state != State.DEAD:
		current_state = State.CHASE


func _on_animation_finished() -> void:
	if animated_sprite.animation == &"death":
		queue_free()


func _on_died() -> void:
	super._on_died()
	_is_warning = false
	animated_sprite.play(&"death")
