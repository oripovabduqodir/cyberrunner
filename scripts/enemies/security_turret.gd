extends EnemyBase
class_name SecurityTurret

## Bir joyda turuvchi, o'yinchini aniqlab qizil ogohlantirish chirog'i bilan snaryad otuvchi minora.

@export_group("Security Turret")
@export var projectile_speed: float = 420.0
@export var warning_duration: float = 0.48

@onready var muzzle: Marker2D = $Muzzle
@onready var warning_light: ColorRect = $WarningLight

var _is_firing_sequence: bool = false


func _ready() -> void:
	super._ready()
	current_state = State.IDLE
	warning_light.visible = false
	animated_sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(_delta: float) -> void:
	if current_state == State.DEAD:
		return

	if _can_see_player():
		var dir_x: int = 1 if _player_ref.global_position.x >= global_position.x else -1
		_face_direction(dir_x)
		muzzle.position.x = 24.0 * float(_facing_dir)

		if not _is_firing_sequence and attack_cooldown_timer.is_stopped():
			_start_fire_sequence()
	elif not _is_firing_sequence:
		current_state = State.IDLE
		if animated_sprite.animation != &"idle":
			animated_sprite.play(&"idle")


func _start_fire_sequence() -> void:
	current_state = State.ATTACK
	_is_firing_sequence = true
	attack_cooldown_timer.start(attack_cooldown)

	warning_light.visible = true
	animated_sprite.play(&"warn")

	await get_tree().create_timer(warning_duration).timeout
	if current_state == State.DEAD or not is_instance_valid(self):
		return

	warning_light.visible = false
	if _player_ref != null and is_instance_valid(_player_ref) and _can_see_player():
		animated_sprite.play(&"fire")
		var aim_dir: Vector2 = (_player_ref.global_position - muzzle.global_position).normalized()
		_spawn_enemy_projectile(muzzle.global_position, aim_dir, projectile_speed)

	await get_tree().create_timer(0.18).timeout
	_is_firing_sequence = false
	if current_state != State.DEAD:
		animated_sprite.play(&"idle")


func _on_animation_finished() -> void:
	if animated_sprite.animation == &"death":
		queue_free()


func _on_died() -> void:
	super._on_died()
	_is_firing_sequence = false
	warning_light.visible = false
	animated_sprite.play(&"death")
