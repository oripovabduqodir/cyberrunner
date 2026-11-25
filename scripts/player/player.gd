extends CharacterBody2D
class_name Player

## CYBER RUNNER bosh qahramonining harakat va fizika boshqaruvchisi.
## Klaviatura va Android TouchScreenButton (Input Map) bilan mos ishlaydi.

@export_group("Harakat (Movement)")
@export var move_speed: float = 300.0
@export var acceleration: float = 2000.0
@export var deceleration: float = 2400.0
@export var air_acceleration: float = 1400.0
@export var air_deceleration: float = 900.0

@export_group("Sakrash va Gravitatsiya (Jump & Gravity)")
@export var jump_velocity: float = -480.0
@export var double_jump_velocity: float = -440.0
@export var gravity: float = 1250.0
@export var fall_gravity_multiplier: float = 1.35
@export var max_fall_speed: float = 950.0
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.12

@export_group("Dash")
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.55

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var dash_trail: CPUParticles2D = $DashTrail
@onready var land_particles: CPUParticles2D = $LandParticles

var _facing_direction: int = 1
var _can_double_jump: bool = true
var _is_dashing: bool = false
var _was_on_floor: bool = false
var _controls_enabled: bool = true
var _vfx_enabled: bool = true


func _ready() -> void:
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown
	coyote_timer.wait_time = coyote_time
	jump_buffer_timer.wait_time = jump_buffer_time

	dash_timer.timeout.connect(_on_dash_timer_timeout)
	if has_node("/root/SettingsManager"):
		SettingsManager.visual_effects_changed.connect(_on_visual_effects_changed)
		_on_visual_effects_changed(SettingsManager.visual_effects)


func _physics_process(delta: float) -> void:
	if _controls_enabled:
		_handle_action_inputs()

	if _is_dashing:
		velocity.x = _facing_direction * dash_speed
		velocity.y = 0.0
	else:
		_apply_gravity(delta)
		if _controls_enabled:
			_handle_horizontal_movement(delta)
			_handle_jump()
		else:
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	_was_on_floor = is_on_floor()
	move_and_slide()
	_update_floor_state()
	_update_animation()


func _handle_action_inputs() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start(jump_buffer_time)

	if Input.is_action_just_pressed("dash") and not _is_dashing and dash_cooldown_timer.is_stopped():
		_start_dash()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return

	var active_gravity: float = gravity
	if velocity.y > 0.0:
		active_gravity *= fall_gravity_multiplier

	velocity.y = minf(velocity.y + active_gravity * delta, max_fall_speed)


func _handle_horizontal_movement(delta: float) -> void:
	var input_axis: float = Input.get_axis("move_left", "move_right")

	if not is_zero_approx(input_axis):
		_facing_direction = 1 if input_axis > 0.0 else -1
		animated_sprite.flip_h = _facing_direction < 0

		var accel: float = acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, input_axis * move_speed, accel * delta)
	else:
		var decel: float = deceleration if is_on_floor() else air_deceleration
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)


func _handle_jump() -> void:
	if not jump_buffer_timer.is_stopped():
		if is_on_floor() or not coyote_timer.is_stopped():
			velocity.y = jump_velocity
			jump_buffer_timer.stop()
			coyote_timer.stop()
			_can_double_jump = true
			return

		if _can_double_jump:
			velocity.y = double_jump_velocity
			_can_double_jump = false
			jump_buffer_timer.stop()
			return

	# Qisqa bosilganda sakrash balandligini yumshoq kamaytirish
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.55


func _start_dash() -> void:
	_is_dashing = true
	velocity.y = 0.0
	velocity.x = _facing_direction * dash_speed
	dash_timer.start(dash_duration)
	dash_cooldown_timer.start(dash_cooldown)
	if _vfx_enabled:
		dash_trail.emitting = true


func _on_dash_timer_timeout() -> void:
	_is_dashing = false
	dash_trail.emitting = false
	velocity.x *= 0.5


func _update_floor_state() -> void:
	if is_on_floor():
		if not _was_on_floor and _vfx_enabled:
			land_particles.restart()
		_can_double_jump = true
		coyote_timer.stop()
	elif _was_on_floor and velocity.y >= 0.0:
		coyote_timer.start(coyote_time)


func _update_animation() -> void:
	var next_anim: StringName = &"idle"

	if _is_dashing:
		next_anim = &"dash"
	elif not is_on_floor():
		next_anim = &"jump" if velocity.y < 0.0 else &"fall"
	elif absf(velocity.x) > 15.0:
		next_anim = &"run"

	if animated_sprite.animation != next_anim:
		animated_sprite.play(next_anim)


func _on_visual_effects_changed(quality: int) -> void:
	_vfx_enabled = quality > 0
	if not _vfx_enabled:
		dash_trail.emitting = false


## Daraja yakunlanganda yoki pauzada boshqaruvni vaqtincha to'xtatish.
func set_controls_enabled(enabled: bool) -> void:
	_controls_enabled = enabled
	if not enabled:
		_is_dashing = false
		dash_trail.emitting = false
		dash_timer.stop()


## Daraja skripti kamera chegaralarini o'rnatishi uchun yordamchi metod.
func set_camera_limits(left: int, top: int, right: int, bottom: int) -> void:
	if camera == null:
		return
	camera.limit_left = left
	camera.limit_top = top
	camera.limit_right = right
	camera.limit_bottom = bottom


## Personajni ko'rsatilgan nuqtaga xavfsiz qaytaradi.
func respawn_at(target_position: Vector2) -> void:
	global_position = target_position
	velocity = Vector2.ZERO
	_is_dashing = false
	_can_double_jump = true
	dash_trail.emitting = false
	dash_timer.stop()
	coyote_timer.stop()
	jump_buffer_timer.stop()
