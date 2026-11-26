extends EnemyBase
class_name EliteRobot

## Kuchaytirilgan Elite Robot: 120 HP, 25 Damage, 300 Score, hujumdan oldin vizual ogohlantirish.

@export_group("Elite Robot")
@export var patrol_speed: float = 90.0
@export var chase_speed: float = 160.0
@export var gravity: float = 1200.0
@export var warn_duration: float = 0.38

@onready var floor_check_ray: RayCast2D = $FloorCheckRay
@onready var wall_check_ray: RayCast2D = $WallCheckRay
@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var melee_shape: CollisionShape2D = $MeleeHitbox/CollisionShape2D

var _hurt_timer: float = 0.0
var _is_attacking: bool = false
var _attack_hit_applied: bool = false


func _ready() -> void:
	super._ready()
	melee_shape.disabled = true
	melee_hitbox.body_entered.connect(_on_melee_body_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	_update_ray_directions()


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, 900.0)

	match current_state:
		State.HURT:
			_hurt_timer -= delta
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _hurt_timer <= 0.0:
				current_state = State.CHASE if _can_see_player() else State.PATROL
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		State.PATROL:
			_process_patrol()
		State.CHASE:
			_process_chase()
		State.IDLE:
			velocity.x = 0.0
			if _can_see_player():
				current_state = State.CHASE

	move_and_slide()
	_update_animation()


func _process_patrol() -> void:
	if _can_see_player():
		current_state = State.CHASE
		return

	if is_on_floor() and (wall_check_ray.is_colliding() or not floor_check_ray.is_colliding()):
		_face_direction(-_facing_dir)
		_update_ray_directions()

	velocity.x = _facing_dir * patrol_speed


func _process_chase() -> void:
	if not _can_see_player():
		current_state = State.PATROL
		return

	var dir_to_player: int = 1 if _player_ref.global_position.x >= global_position.x else -1
	if dir_to_player != _facing_dir:
		_face_direction(dir_to_player)
		_update_ray_directions()

	if _distance_to_player() <= attack_range and attack_cooldown_timer.is_stopped():
		_start_attack_sequence()
		return

	if is_on_floor() and (wall_check_ray.is_colliding() or not floor_check_ray.is_colliding()):
		velocity.x = 0.0
	else:
		velocity.x = _facing_dir * chase_speed


func _start_attack_sequence() -> void:
	current_state = State.ATTACK
	_is_attacking = true
	_attack_hit_applied = false
	attack_cooldown_timer.start(attack_cooldown)

	animated_sprite.modulate = Color(1.6, 0.4, 0.2, 1.0)
	animated_sprite.play(&"warn")
	await get_tree().create_timer(warn_duration).timeout
	if current_state == State.DEAD or not is_instance_valid(self) or not _is_attacking:
		return

	animated_sprite.modulate = Color.WHITE
	animated_sprite.play(&"attack")
	melee_shape.set_deferred("disabled", false)


func _on_melee_body_entered(body: Node2D) -> void:
	if not _is_attacking or _attack_hit_applied:
		return
	if body is Player:
		_attack_hit_applied = true
		(body as Player).take_damage(damage, Vector2(_facing_dir, -0.35))


func _on_animation_finished() -> void:
	if animated_sprite.animation == &"attack":
		_is_attacking = false
		melee_shape.set_deferred("disabled", true)
		if current_state != State.DEAD:
			current_state = State.CHASE if _can_see_player() else State.PATROL
	elif animated_sprite.animation == &"death":
		queue_free()


func _update_ray_directions() -> void:
	floor_check_ray.position.x = 22.0 * float(_facing_dir)
	wall_check_ray.target_position.x = 28.0 * float(_facing_dir)
	melee_hitbox.position.x = 32.0 * float(_facing_dir)
	animated_sprite.offset.x = 21.0 * float(_facing_dir)


func _update_animation() -> void:
	if current_state in [State.DEAD, State.ATTACK, State.HURT]:
		return
	var next_anim: StringName = &"walk" if absf(velocity.x) > 8.0 else &"idle"
	if animated_sprite.animation != next_anim:
		animated_sprite.play(next_anim)


func _on_damaged(amount: int, knockback_dir: Vector2) -> void:
	super._on_damaged(amount, knockback_dir)
	if current_state == State.DEAD:
		return
	if current_state != State.ATTACK:
		current_state = State.HURT
		_hurt_timer = 0.14
		velocity.x = signf(knockback_dir.x) * 90.0 if not is_zero_approx(knockback_dir.x) else 0.0
		animated_sprite.play(&"hurt")


func _on_died() -> void:
	super._on_died()
	_is_attacking = false
	melee_shape.set_deferred("disabled", true)
	animated_sprite.modulate = Color.WHITE
	animated_sprite.play(&"death")
