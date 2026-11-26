extends CharacterBody2D
class_name Player

## CYBER RUNNER bosh qahramonining harakat, fizika, sog'liq, energiya va jang boshqaruvchisi.
## Klaviatura va Android TouchScreenButton (Input Map) bilan mos ishlaydi.

signal player_died

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

@export_group("Dash va Energiya (Dash & Energy)")
@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.55
@export var dash_energy_cost: float = 25.0
@export var energy_regen_rate: float = 18.0

@export_group("Jang (Combat)")
@export var knockback_force: Vector2 = Vector2(260.0, -220.0)
@export var knockback_lock_duration: float = 0.18

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var dash_trail: CPUParticles2D = $DashTrail
@onready var land_particles: CPUParticles2D = $LandParticles
@onready var health_component: HealthComponent = $HealthComponent
@onready var energy_component: EnergyComponent = $EnergyComponent
@onready var plasma_pistol: PlasmaPistol = $PlasmaPistol
@onready var cyber_blade: CyberBlade = $CyberBlade
@onready var aim_assist: AimAssist = $AimAssist

var _facing_direction: int = 1
var _can_double_jump: bool = true
var _is_dashing: bool = false
var _was_on_floor: bool = false
var _controls_enabled: bool = true
var _vfx_enabled: bool = true
var _knockback_timer: float = 0.0
var _action_anim_timer: float = 0.0
var _action_anim_name: StringName = &""
var _flash_tween: Tween


func _ready() -> void:
	add_to_group(&"player")
	dash_timer.wait_time = dash_duration
	dash_cooldown_timer.wait_time = dash_cooldown
	coyote_timer.wait_time = coyote_time
	jump_buffer_timer.wait_time = jump_buffer_time
	energy_component.regen_rate = energy_regen_rate

	dash_timer.timeout.connect(_on_dash_timer_timeout)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)

	if has_node("/root/SettingsManager"):
		SettingsManager.visual_effects_changed.connect(_on_visual_effects_changed)
		SettingsManager.mobile_settings_changed.connect(_sync_aim_assist_mode)
		_on_visual_effects_changed(SettingsManager.visual_effects)
		_sync_aim_assist_mode()


func _physics_process(delta: float) -> void:
	if health_component.is_dead():
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		move_and_slide()
		return

	if _knockback_timer > 0.0:
		_knockback_timer = maxf(0.0, _knockback_timer - delta)
	if _action_anim_timer > 0.0:
		_action_anim_timer = maxf(0.0, _action_anim_timer - delta)

	if _controls_enabled and _knockback_timer <= 0.0:
		_update_aim_direction()
		_handle_action_inputs()

	if _is_dashing:
		velocity.x = _facing_direction * dash_speed
		velocity.y = 0.0
	else:
		_apply_gravity(delta)
		if _controls_enabled and _knockback_timer <= 0.0:
			_handle_horizontal_movement(delta)
			_handle_jump()
		elif _knockback_timer <= 0.0:
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	_was_on_floor = is_on_floor()
	move_and_slide()
	_update_floor_state()
	_update_animation()
	_update_invincibility_blink()


func _sync_aim_assist_mode() -> void:
	var use_auto_aim: bool = SettingsManager.is_mobile_controls_active() and SettingsManager.auto_aim
	aim_assist.set_enabled(use_auto_aim)


func _update_aim_direction() -> void:
	var fallback_dir := Vector2(float(_facing_direction), 0.0)
	var aim_dir: Vector2 = fallback_dir
	var melee_dir: Vector2 = fallback_dir

	if SettingsManager.is_mobile_controls_active():
		if aim_assist.enabled:
			aim_dir = aim_assist.get_aim_direction(global_position, fallback_dir)
			melee_dir = aim_assist.get_melee_aim_direction(global_position, fallback_dir)
	else:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var delta_vec: Vector2 = mouse_pos - global_position
		if delta_vec.length_squared() > 4.0:
			aim_dir = delta_vec.normalized()
			melee_dir = aim_dir

	plasma_pistol.set_aim_direction(aim_dir)
	cyber_blade.set_aim_direction(melee_dir)


func _is_pointer_over_ui() -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	return hovered != null and hovered.mouse_filter == Control.MOUSE_FILTER_STOP


func _handle_action_inputs() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start(jump_buffer_time)

	if Input.is_action_just_pressed("dash") and not _is_dashing and dash_cooldown_timer.is_stopped():
		if energy_component.spend(dash_energy_cost):
			_start_dash()

	if Input.is_action_pressed("fire") and not _is_pointer_over_ui():
		if plasma_pistol.try_fire(self):
			_trigger_action_anim(&"shoot", 0.14)

	if Input.is_action_just_pressed("reload"):
		plasma_pistol.start_reload()
		if plasma_pistol.is_reloading():
			_trigger_action_anim(&"reload", 0.4)

	if Input.is_action_just_pressed("melee_attack") and not _is_pointer_over_ui():
		if cyber_blade.try_attack():
			_trigger_action_anim(&"melee", 0.2)


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
		animated_sprite.offset.x = -12.0 if _facing_direction < 0 else 12.0

		var intensity: float = MobileInputManager.get_horizontal_intensity() if has_node("/root/MobileInputManager") else 1.0
		var accel: float = acceleration if is_on_floor() else air_acceleration
		velocity.x = move_toward(velocity.x, input_axis * move_speed * intensity, accel * delta)
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
			_trigger_action_anim(&"double_jump", 0.35)
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


func _trigger_action_anim(anim_name: StringName, duration: float) -> void:
	_action_anim_name = anim_name
	_action_anim_timer = duration


func _update_animation() -> void:
	var next_anim: StringName = &"idle"

	if _is_dashing:
		next_anim = &"dash"
	elif _action_anim_timer > 0.0 and animated_sprite.sprite_frames.has_animation(_action_anim_name):
		next_anim = _action_anim_name
	elif not is_on_floor():
		next_anim = &"jump" if velocity.y < 0.0 else &"fall"
	elif absf(velocity.x) > 15.0:
		next_anim = &"run"

	if animated_sprite.animation != next_anim:
		animated_sprite.play(next_anim)


func _update_invincibility_blink() -> void:
	if health_component.is_invincible() and not health_component.is_dead():
		animated_sprite.modulate.a = 0.45 if int(Time.get_ticks_msec() / 70) % 2 == 0 else 1.0
	else:
		animated_sprite.modulate.a = 1.0


func _on_visual_effects_changed(quality: int) -> void:
	_vfx_enabled = quality > 0
	if not _vfx_enabled:
		dash_trail.emitting = false


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> bool:
	return health_component.take_damage(amount, knockback_dir)


func heal(amount: int) -> int:
	return health_component.heal(amount)


func restore_energy(amount: float) -> float:
	return energy_component.restore(amount)


func add_ammo(amount: int) -> void:
	plasma_pistol.add_ammo(amount)


func _on_damaged(_amount: int, knockback_dir: Vector2) -> void:
	if _is_dashing:
		_on_dash_timer_timeout()
		dash_timer.stop()

	var push_x: float = knockback_dir.x if not is_zero_approx(knockback_dir.x) else float(-_facing_direction)
	velocity.x = signf(push_x) * knockback_force.x
	velocity.y = knockback_force.y
	_knockback_timer = knockback_lock_duration
	_trigger_action_anim(&"hurt", 0.22)

	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	animated_sprite.modulate = Color(1.0, 0.25, 0.35, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(animated_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)


func _on_died() -> void:
	_controls_enabled = false
	_is_dashing = false
	dash_trail.emitting = false
	plasma_pistol.visible = false
	if animated_sprite.sprite_frames.has_animation(&"death"):
		animated_sprite.play(&"death")
	else:
		animated_sprite.stop()

	var death_tween: Tween = create_tween()
	death_tween.tween_property(animated_sprite, "modulate", Color(1.0, 0.25, 0.35, 0.9), 0.25)
	if animated_sprite.sprite_frames.has_animation(&"death"):
		await animated_sprite.animation_finished
	else:
		await death_tween.finished

	player_died.emit()


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
func respawn_at(target_position: Vector2, restore_vitals: bool = false) -> void:
	global_position = target_position
	velocity = Vector2.ZERO
	_is_dashing = false
	_can_double_jump = true
	_knockback_timer = 0.0
	_controls_enabled = true
	dash_trail.emitting = false
	dash_timer.stop()
	coyote_timer.stop()
	jump_buffer_timer.stop()

	animated_sprite.rotation_degrees = 0.0
	animated_sprite.modulate = Color.WHITE
	plasma_pistol.visible = true

	if restore_vitals:
		health_component.reset_health()
		energy_component.reset_energy()
