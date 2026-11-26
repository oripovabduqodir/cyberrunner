extends CharacterBody2D
class_name OmegaXBoss

## FINAL BOSS — OMEGA-X (Central AI Guardian).
## 1000 HP, 3 fazali State Machine: Ta'qib, Yaqin Zarba (Cleave), Plasma Attack, Laser Beam, Ground Slam, Drone Summoning.

signal boss_health_changed(current_health: int, max_health: int)
signal boss_phase_changed(phase_number: int, phase_title: String)
signal boss_defeated(score_reward: int)
signal summon_drone_requested(spawn_pos: Vector2)

enum Phase {
	PHASE_1_DEFENSE = 1,
	PHASE_2_ATTACK = 2,
	PHASE_3_OVERLOAD = 3,
}

enum BossState {
	DORMANT,
	IDLE,
	MOVE,
	ATTACK,
	PHASE_TRANSITION,
	DEAD,
}

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/weapons/projectile.tscn")

@export var score_reward: int = 5000
@export var move_speed: float = 95.0
@export var contact_damage: int = 15
@export var melee_damage: int = 20
@export var arena_left_x: float = 3660.0
@export var arena_right_x: float = 4780.0
@export var floor_y: float = 576.0

@onready var health_component: HealthComponent = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var contact_area: Area2D = $ContactArea
@onready var contact_shape: CollisionShape2D = $ContactArea/CollisionShape2D
@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var melee_shape: CollisionShape2D = $MeleeHitbox/CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle
@onready var laser_area: Area2D = $LaserArea
@onready var laser_warning_glow: ColorRect = $LaserArea/WarningGlow
@onready var laser_warning: ColorRect = $LaserArea/WarningLine
@onready var laser_beam: ColorRect = $LaserArea/BeamVisual
@onready var laser_beam_core: ColorRect = $LaserArea/BeamVisual/BeamCore
@onready var laser_shape: CollisionShape2D = $LaserArea/CollisionShape2D
@onready var action_timer: Timer = $ActionTimer
@onready var core_aura: CPUParticles2D = $CoreAura
@onready var phase_sparks: CPUParticles2D = $PhaseSparks
@onready var slam_particles: CPUParticles2D = $SlamParticles
@onready var death_burst: CPUParticles2D = $DeathBurst

var current_phase: Phase = Phase.PHASE_1_DEFENSE
var current_state: BossState = BossState.DORMANT

var _player_ref: Player = null
var _origin_pos: Vector2
var _facing_dir: int = -1
var _attack_cycle: int = 0
var _active_drones: int = 0
var _laser_active: bool = false
var _melee_active: bool = false
var _melee_hit_applied: bool = false
var _contact_cooldown: float = 0.0
var _hurt_anim_playing: bool = false
var _hurt_anim_cooldown: float = 0.0
var _death_handled: bool = false
var _defeat_emitted: bool = false
var _is_closing_in: bool = true
var _action_serial: int = 0
var _pulse_time: float = 0.0
var _boss_material: ShaderMaterial = null
var _flash_tween: Tween
var _slam_tween: Tween
var _warn_tween: Tween
var _active_temp_nodes: Array[Node] = []


func _ready() -> void:
	add_to_group(&"enemies")
	_origin_pos = global_position
	floor_y = _origin_pos.y
	if animated_sprite.material is ShaderMaterial:
		_boss_material = (animated_sprite.material as ShaderMaterial).duplicate() as ShaderMaterial
		animated_sprite.material = _boss_material

	_set_laser_warning_visible(false)
	laser_beam.visible = false
	laser_shape.disabled = true
	melee_shape.disabled = true
	contact_shape.disabled = true
	_face_dir(-1)
	_apply_phase_visuals(Phase.PHASE_1_DEFENSE)

	health_component.health_changed.connect(_on_health_changed)
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	action_timer.timeout.connect(_on_action_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)

	if has_node("/root/SettingsManager"):
		SettingsManager.visual_effects_changed.connect(_on_visual_effects_changed)

	# FinalBattle darajasida Player sahnada Boss dan keyin joylashgani sababli deferred va runtime da qidiriladi.
	_ensure_player_ref()
	call_deferred(&"_ensure_player_ref")


func _ensure_player_ref() -> bool:
	if _player_ref != null and is_instance_valid(_player_ref):
		return true
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	for p in players:
		if p is Player:
			_player_ref = p as Player
			return true
	var search_root: Node = get_tree().current_scene
	if search_root == null:
		search_root = get_parent()
	if search_root != null:
		var found: Node = search_root.find_child("Player", true, false)
		if found is Player:
			_player_ref = found as Player
			return true
	return false


func _process(delta: float) -> void:
	if _hurt_anim_cooldown > 0.0:
		_hurt_anim_cooldown = maxf(0.0, _hurt_anim_cooldown - delta)
	if _contact_cooldown > 0.0:
		_contact_cooldown = maxf(0.0, _contact_cooldown - delta)

	if _boss_material == null:
		return

	if current_state == BossState.DEAD or not _are_vfx_enabled():
		_boss_material.set_shader_parameter(&"core_pulse", 0.0)
		return

	_pulse_time += delta
	var pulse_val: float = 0.04
	if current_state != BossState.DORMANT:
		match current_phase:
			Phase.PHASE_1_DEFENSE:
				pulse_val = 0.06 + 0.03 * sin(_pulse_time * 2.4)
			Phase.PHASE_2_ATTACK:
				pulse_val = 0.14 + 0.10 * sin(_pulse_time * 4.5)
			Phase.PHASE_3_OVERLOAD:
				pulse_val = 0.26 + 0.22 * sin(_pulse_time * 9.5)
	if current_state == BossState.PHASE_TRANSITION:
		pulse_val += 0.18
	_boss_material.set_shader_parameter(&"core_pulse", pulse_val)


func activate_boss() -> void:
	if current_state != BossState.DORMANT:
		return
	_ensure_player_ref()
	current_phase = Phase.PHASE_1_DEFENSE
	current_state = BossState.MOVE
	_is_closing_in = true
	contact_shape.set_deferred("disabled", false)
	if _player_ref != null:
		_face_dir(1 if _player_ref.global_position.x >= global_position.x else -1)
	else:
		_face_dir(-1)
	_apply_phase_visuals(Phase.PHASE_1_DEFENSE)
	animated_sprite.play(&"walk")
	boss_health_changed.emit(health_component.current_health, health_component.max_health)
	boss_phase_changed.emit(1, "PHASE 01 — DEFENSE MODE")
	action_timer.start(0.85)


func reset_boss() -> void:
	_action_serial += 1
	action_timer.stop()
	_kill_active_tweens()
	_clear_temp_effects()
	_laser_active = false
	_melee_active = false
	_melee_hit_applied = false
	_contact_cooldown = 0.0
	_hurt_anim_playing = false
	_hurt_anim_cooldown = 0.0
	_death_handled = false
	_defeat_emitted = false
	_is_closing_in = true
	_set_laser_warning_visible(false)
	laser_beam.visible = false
	laser_shape.set_deferred("disabled", true)
	melee_shape.set_deferred("disabled", true)
	contact_shape.set_deferred("disabled", true)

	global_position = _origin_pos
	floor_y = _origin_pos.y
	velocity = Vector2.ZERO
	_attack_cycle = 0
	_active_drones = 0
	current_phase = Phase.PHASE_1_DEFENSE
	current_state = BossState.DORMANT
	collision_shape.set_deferred("disabled", false)
	animated_sprite.modulate = Color.WHITE
	if _boss_material != null:
		_boss_material.set_shader_parameter(&"hit_flash", 0.0)
	_face_dir(-1)
	animated_sprite.play(&"idle")
	_apply_phase_visuals(Phase.PHASE_1_DEFENSE)
	health_component.reset_health()


func register_drone_died() -> void:
	_active_drones = maxi(0, _active_drones - 1)


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> bool:
	if current_state == BossState.DORMANT or current_state == BossState.DEAD or current_state == BossState.PHASE_TRANSITION:
		return false
	return health_component.take_damage(amount, knockback_dir)


func _physics_process(delta: float) -> void:
	if current_state == BossState.DORMANT or current_state == BossState.DEAD:
		return

	_ensure_player_ref()

	if _laser_active:
		for body in laser_area.get_overlapping_bodies():
			if body is Player:
				(body as Player).take_damage(22, Vector2(_facing_dir, -0.3))

	if _melee_active and not _melee_hit_applied:
		for body in melee_hitbox.get_overlapping_bodies():
			if body is Player:
				var melee_dmg: int = melee_damage + (4 if current_phase == Phase.PHASE_3_OVERLOAD else 0)
				if (body as Player).take_damage(melee_dmg, Vector2(_facing_dir, -0.35)):
					_melee_hit_applied = true
					break

	if current_state != BossState.PHASE_TRANSITION and _contact_cooldown <= 0.0:
		for body in contact_area.get_overlapping_bodies():
			if body is Player:
				var p := body as Player
				if not p.health_component.is_dead():
					var push_dir: float = signf(p.global_position.x - global_position.x)
					if is_zero_approx(push_dir):
						push_dir = float(_facing_dir)
					if p.take_damage(contact_damage, Vector2(push_dir, -0.45)):
						_contact_cooldown = 0.55
						break

	if current_state in [BossState.IDLE, BossState.MOVE]:
		if _player_ref != null and not _player_ref.health_component.is_dead():
			var dir_x: float = signf(_player_ref.global_position.x - global_position.x)
			if not is_zero_approx(dir_x):
				_face_dir(1 if dir_x >= 0.0 else -1)

			var speed_mult: float = 1.0
			var stop_dist: float = 130.0
			if current_phase == Phase.PHASE_2_ATTACK:
				speed_mult = 1.25
				stop_dist = 120.0
			elif current_phase == Phase.PHASE_3_OVERLOAD:
				speed_mult = 1.45
				stop_dist = 105.0

			var dist_x: float = absf(_player_ref.global_position.x - global_position.x)
			if _is_closing_in and dist_x <= stop_dist:
				_is_closing_in = false
			elif not _is_closing_in and dist_x >= stop_dist + 32.0:
				_is_closing_in = true

			var move_dir: float = dir_x if not is_zero_approx(dir_x) else float(_facing_dir)
			velocity.x = move_dir * move_speed * speed_mult if _is_closing_in else 0.0
			global_position.x = clampf(global_position.x + velocity.x * delta, arena_left_x + 80.0, arena_right_x - 80.0)
			global_position.y = floor_y

			if not _hurt_anim_playing:
				var move_anim: StringName = &"walk" if absf(velocity.x) > 1.0 else &"idle"
				if animated_sprite.animation != move_anim:
					animated_sprite.play(move_anim)

			# Kafolat: Boss harakatsiz qolib ketmasligi uchun action_timer to'xtagan bo'lsa qayta yoqiladi.
			if action_timer.is_stopped():
				action_timer.start(0.45)
		else:
			velocity.x = 0.0
			if not _hurt_anim_playing and animated_sprite.animation != &"idle":
				animated_sprite.play(&"idle")


func _face_dir(dir: int) -> void:
	_facing_dir = 1 if dir >= 0 else -1
	# Frost Guardian asl kadrlari chapga qaragan holda chizilgan
	animated_sprite.flip_h = _facing_dir > 0
	muzzle.position.x = 62.0 * float(_facing_dir)
	laser_area.scale.x = float(_facing_dir)
	melee_hitbox.position.x = 78.0 * float(_facing_dir)


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	boss_health_changed.emit(current_hp, max_hp)
	if current_hp <= 0 or current_state == BossState.DEAD or current_state == BossState.PHASE_TRANSITION:
		return

	var ratio: float = float(current_hp) / float(max_hp)
	if current_phase == Phase.PHASE_1_DEFENSE and ratio <= 0.70:
		_enter_phase(Phase.PHASE_2_ATTACK, "PHASE 02 — ATTACK MODE")
	elif current_phase == Phase.PHASE_2_ATTACK and ratio <= 0.30:
		_enter_phase(Phase.PHASE_3_OVERLOAD, "PHASE 03 — OVERLOAD MODE")


func _enter_phase(new_phase: Phase, title: String) -> void:
	_action_serial += 1
	current_phase = new_phase
	current_state = BossState.PHASE_TRANSITION
	action_timer.stop()
	_kill_slam_tween()
	_kill_warn_tween()
	_attack_cycle = 0 if new_phase == Phase.PHASE_2_ATTACK else -1
	global_position.y = floor_y
	velocity = Vector2.ZERO
	_hurt_anim_playing = false
	_laser_active = false
	_melee_active = false
	_set_laser_warning_visible(false)
	laser_beam.visible = false
	laser_shape.set_deferred("disabled", true)
	melee_shape.set_deferred("disabled", true)

	boss_phase_changed.emit(int(new_phase), title)
	animated_sprite.play(&"phase_transition")
	_trigger_camera_shake(4.5, 0.3)
	_apply_phase_visuals(new_phase)
	_trigger_hit_flash(0.65, 0.38, Color(1.0, 0.72, 0.92, 1.0))

	var phase_serial: int = _action_serial
	await get_tree().create_timer(1.1).timeout

	if phase_serial != _action_serial or current_state != BossState.PHASE_TRANSITION or health_component.is_dead() or not is_instance_valid(self):
		return
	current_state = BossState.MOVE
	animated_sprite.play(&"walk")
	action_timer.start(0.55)


func _on_action_timer_timeout() -> void:
	if current_state in [BossState.DORMANT, BossState.DEAD, BossState.PHASE_TRANSITION, BossState.ATTACK]:
		return
	if not _ensure_player_ref() or _player_ref.health_component.is_dead():
		if animated_sprite.animation != &"idle":
			animated_sprite.play(&"idle")
		if current_state != BossState.DORMANT and current_state != BossState.DEAD:
			action_timer.start(0.4)
		return

	_action_serial += 1
	var my_serial: int = _action_serial
	_hurt_anim_playing = false
	_face_dir(1 if _player_ref.global_position.x >= global_position.x else -1)
	_attack_cycle += 1

	var dist_x: float = absf(_player_ref.global_position.x - global_position.x)
	var dist_y: float = absf(_player_ref.global_position.y - floor_y)
	var player_is_close: bool = dist_x <= 170.0 and dist_y <= 130.0

	match current_phase:
		Phase.PHASE_1_DEFENSE:
			if player_is_close and _attack_cycle % 2 == 1:
				await _do_melee_cleave(my_serial)
			elif _attack_cycle % 3 == 0:
				await _do_ground_slam(my_serial)
			else:
				await _do_plasma_attack(1, 360.0, my_serial)
			_schedule_next_action(1.15, my_serial)
		Phase.PHASE_2_ATTACK:
			var step: int = _attack_cycle % 4
			if player_is_close and step != 1:
				await _do_melee_cleave(my_serial)
			elif step == 0:
				await _do_plasma_attack(3, 400.0, my_serial)
			elif step == 1:
				await _do_laser_beam(0.65, 0.9, my_serial)
			elif step == 2:
				if _active_drones < 2:
					await _do_summon_drone(my_serial)
				else:
					await _do_ground_slam(my_serial)
			else:
				await _do_ground_slam(my_serial)
			_schedule_next_action(0.95, my_serial)
		Phase.PHASE_3_OVERLOAD:
			var step3: int = _attack_cycle % 4
			if step3 == 0:
				await _do_ground_slam(my_serial)
			elif step3 == 1:
				await _do_laser_beam(0.52, 1.05, my_serial)
			elif step3 == 2:
				if player_is_close:
					await _do_melee_cleave(my_serial)
				else:
					await _do_plasma_attack(3, 460.0, my_serial)
			else:
				if _active_drones < 2:
					await _do_summon_drone(my_serial)
				else:
					await _do_ground_slam(my_serial)
			_schedule_next_action(0.75, my_serial)


func _schedule_next_action(delay: float, expected_serial: int) -> void:
	if expected_serial != _action_serial:
		return
	if current_state == BossState.DEAD or current_state == BossState.DORMANT or current_state == BossState.PHASE_TRANSITION:
		return
	current_state = BossState.MOVE
	animated_sprite.play(&"idle")
	action_timer.start(delay)


func _do_melee_cleave(expected_serial: int) -> void:
	current_state = BossState.ATTACK
	velocity = Vector2.ZERO
	_melee_active = false
	_melee_hit_applied = false

	# Hujumdan oldin vizual ogohlantirish
	animated_sprite.play(&"laser_charge")
	_trigger_hit_flash(0.45, 0.28, Color(1.0, 0.55, 0.25, 1.0))
	await get_tree().create_timer(0.32).timeout
	if expected_serial != _action_serial or current_state != BossState.ATTACK or health_component.is_dead() or not is_instance_valid(self):
		return

	if _ensure_player_ref():
		_face_dir(1 if _player_ref.global_position.x >= global_position.x else -1)
	animated_sprite.play(&"plasma_attack")
	await get_tree().create_timer(0.24).timeout
	if expected_serial != _action_serial or current_state != BossState.ATTACK or health_component.is_dead() or not is_instance_valid(self):
		return

	_melee_active = true
	melee_shape.set_deferred("disabled", false)
	for body in melee_hitbox.get_overlapping_bodies():
		if body is Player and not _melee_hit_applied:
			var melee_dmg: int = melee_damage + (4 if current_phase == Phase.PHASE_3_OVERLOAD else 0)
			if (body as Player).take_damage(melee_dmg, Vector2(_facing_dir, -0.35)):
				_melee_hit_applied = true
				break
	_trigger_camera_shake(2.6, 0.16)
	await get_tree().create_timer(0.22).timeout

	_melee_active = false
	melee_shape.set_deferred("disabled", true)
	if expected_serial != _action_serial:
		return
	await get_tree().create_timer(0.22).timeout


func _do_plasma_attack(count: int, speed: float, expected_serial: int) -> void:
	current_state = BossState.ATTACK
	velocity = Vector2.ZERO
	animated_sprite.play(&"plasma_attack")
	_trigger_hit_flash(0.35, 0.25, Color(0.75, 0.95, 1.0, 1.0))
	await get_tree().create_timer(0.38).timeout
	if expected_serial != _action_serial or current_state != BossState.ATTACK or health_component.is_dead() or not is_instance_valid(self):
		return
	if not _ensure_player_ref() or _player_ref.health_component.is_dead():
		return

	var spawn_origin: Vector2 = muzzle.global_position
	if absf(_player_ref.global_position.x - global_position.x) < 90.0:
		spawn_origin = Vector2(global_position.x + 24.0 * float(_facing_dir), muzzle.global_position.y)

	var base_dir: Vector2 = (_player_ref.global_position - spawn_origin).normalized()
	if base_dir.is_zero_approx():
		base_dir = Vector2(float(_facing_dir), 0.0)
	for i in range(count):
		var spread_angle: float = 0.0
		if count > 1:
			spread_angle = (float(i) - float(count - 1) * 0.5) * 0.16
		_spawn_boss_projectile(spawn_origin, base_dir.rotated(spread_angle), speed, 18)

	await get_tree().create_timer(0.28).timeout


func _do_laser_beam(warn_time: float, active_time: float, expected_serial: int) -> void:
	current_state = BossState.ATTACK
	velocity = Vector2.ZERO
	animated_sprite.play(&"laser_charge")
	_set_laser_warning_visible(true)
	await get_tree().create_timer(warn_time).timeout
	_set_laser_warning_visible(false)
	if expected_serial != _action_serial or current_state != BossState.ATTACK or health_component.is_dead() or not is_instance_valid(self):
		return

	animated_sprite.play(&"laser_fire")
	laser_beam.visible = true
	laser_shape.set_deferred("disabled", false)
	_laser_active = true
	for body in laser_area.get_overlapping_bodies():
		if body is Player:
			(body as Player).take_damage(22, Vector2(_facing_dir, -0.3))
	_trigger_camera_shake(2.2, 0.2)
	await get_tree().create_timer(active_time).timeout

	_laser_active = false
	laser_beam.visible = false
	laser_shape.set_deferred("disabled", true)
	if expected_serial != _action_serial:
		return


func _do_ground_slam(expected_serial: int) -> void:
	current_state = BossState.ATTACK
	velocity = Vector2.ZERO
	animated_sprite.play(&"ground_slam")
	_trigger_hit_flash(0.42, 0.30, Color(1.0, 0.45, 0.18, 1.0))

	_kill_slam_tween()
	_slam_tween = create_tween()
	_slam_tween.tween_property(self, "global_position:y", floor_y - 42.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_slam_tween.tween_property(self, "global_position:y", floor_y, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _slam_tween.finished
	if expected_serial != _action_serial or current_state != BossState.ATTACK or health_component.is_dead() or not is_instance_valid(self):
		global_position.y = floor_y
		return
	global_position.y = floor_y
	if _are_vfx_enabled():
		slam_particles.restart()
	_trigger_camera_shake(4.0, 0.22)

	# Yaqin masofadagi zarba + chap va o'ngga sakrab o'tiladigan yer zarbasi snaryadlari
	if _ensure_player_ref() and not _player_ref.health_component.is_dead():
		var dx: float = _player_ref.global_position.x - global_position.x
		var dy: float = absf(_player_ref.global_position.y - floor_y)
		if absf(dx) <= 135.0 and dy <= 96.0:
			var push_x: float = signf(dx) if not is_zero_approx(dx) else float(_facing_dir)
			_player_ref.take_damage(22, Vector2(push_x, -0.45))

	_spawn_boss_projectile(Vector2(global_position.x - 36.0, floor_y - 16.0), Vector2.LEFT, 330.0, 22)
	_spawn_boss_projectile(Vector2(global_position.x + 36.0, floor_y - 16.0), Vector2.RIGHT, 330.0, 22)
	await get_tree().create_timer(0.24).timeout


func _do_summon_drone(expected_serial: int) -> void:
	current_state = BossState.ATTACK
	velocity = Vector2.ZERO
	animated_sprite.play(&"laser_charge")
	_trigger_hit_flash(0.38, 0.25, Color(1.0, 0.25, 0.72, 1.0))
	await get_tree().create_timer(0.22).timeout
	if expected_serial != _action_serial or current_state != BossState.ATTACK or health_component.is_dead() or not is_instance_valid(self):
		return
	_active_drones += 1
	var offset_x: float = -120.0 if _active_drones % 2 == 1 else 120.0
	summon_drone_requested.emit(Vector2(clampf(global_position.x + offset_x, arena_left_x + 100.0, arena_right_x - 100.0), floor_y - 220.0))
	await get_tree().create_timer(0.25).timeout


func _spawn_boss_projectile(origin: Vector2, dir: Vector2, speed: float, dmg: int) -> void:
	var proj := PROJECTILE_SCENE.instantiate() as Projectile
	var parent_node: Node = get_tree().current_scene
	if parent_node == null:
		parent_node = get_tree().root
	parent_node.add_child(proj)
	_active_temp_nodes.append(proj)
	proj.launch(origin, dir, speed, dmg, true, self, false)


func _clear_temp_effects() -> void:
	for n in _active_temp_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_active_temp_nodes.clear()


func _on_damaged(_amount: int, _knockback_dir: Vector2) -> void:
	if current_state == BossState.DEAD:
		return
	_trigger_hit_flash(0.88, 0.12, Color(1.0, 0.85, 0.90, 1.0))
	if current_state in [BossState.IDLE, BossState.MOVE] and _hurt_anim_cooldown <= 0.0 and not _hurt_anim_playing:
		_hurt_anim_playing = true
		_hurt_anim_cooldown = 0.90
		animated_sprite.play(&"hurt")


func _on_died() -> void:
	if _death_handled or current_state == BossState.DEAD:
		return
	_action_serial += 1
	_death_handled = true
	current_state = BossState.DEAD
	action_timer.stop()
	_kill_active_tweens()
	global_position.y = floor_y
	velocity = Vector2.ZERO
	_hurt_anim_playing = false
	_laser_active = false
	_melee_active = false
	_set_laser_warning_visible(false)
	laser_beam.visible = false
	core_aura.emitting = false
	phase_sparks.emitting = false
	laser_shape.set_deferred("disabled", true)
	melee_shape.set_deferred("disabled", true)
	contact_shape.set_deferred("disabled", true)
	collision_shape.set_deferred("disabled", true)
	animated_sprite.modulate = Color.WHITE
	if _boss_material != null:
		_boss_material.set_shader_parameter(&"hit_flash", 0.0)
	animated_sprite.play(&"death")
	if _are_vfx_enabled():
		death_burst.restart()
	_trigger_camera_shake(6.0, 0.4)


func _apply_phase_visuals(phase: Phase) -> void:
	var vfx_on: bool = _are_vfx_enabled()
	match phase:
		Phase.PHASE_2_ATTACK:
			_set_boss_palette(
				Color(0.11, 0.06, 0.15, 1.0),
				Color(0.58, 0.45, 0.64, 1.0),
				Color(0.24, 0.02, 0.16, 1.0),
				Color(1.0, 0.04, 0.44, 1.0),
				Color(1.0, 0.80, 0.90, 1.0),
				0.80,
				0.94
			)
			core_aura.color = Color(1.0, 0.12, 0.48, 0.78)
			core_aura.amount = 10
			core_aura.emitting = vfx_on
			laser_warning_glow.color = Color(1.0, 0.12, 0.50, 0.28)
			laser_warning.color = Color(1.0, 0.35, 0.68, 0.92)
			laser_beam.color = Color(1.0, 0.06, 0.38, 0.94)
			laser_beam_core.color = Color(1.0, 0.85, 0.95, 0.98)
			laser_beam.offset_top = -12.0
			laser_beam.offset_bottom = 12.0
			laser_beam_core.offset_top = 8.0
			laser_beam_core.offset_bottom = 16.0
			phase_sparks.emitting = false
		Phase.PHASE_3_OVERLOAD:
			_set_boss_palette(
				Color(0.14, 0.05, 0.05, 1.0),
				Color(0.62, 0.44, 0.38, 1.0),
				Color(0.32, 0.04, 0.00, 1.0),
				Color(1.0, 0.28, 0.04, 1.0),
				Color(1.0, 0.92, 0.58, 1.0),
				0.76,
				0.96
			)
			core_aura.color = Color(1.0, 0.42, 0.08, 0.88)
			core_aura.amount = 12
			core_aura.emitting = vfx_on
			laser_warning_glow.color = Color(1.0, 0.35, 0.05, 0.32)
			laser_warning.color = Color(1.0, 0.68, 0.22, 0.95)
			laser_beam.color = Color(1.0, 0.22, 0.05, 0.96)
			laser_beam_core.color = Color(1.0, 0.94, 0.72, 0.98)
			laser_beam.offset_top = -14.0
			laser_beam.offset_bottom = 14.0
			laser_beam_core.offset_top = 9.0
			laser_beam_core.offset_bottom = 19.0
			phase_sparks.emitting = vfx_on
		_:
			_set_boss_palette(
				Color(0.08, 0.10, 0.17, 1.0),
				Color(0.62, 0.72, 0.84, 1.0),
				Color(0.05, 0.10, 0.30, 1.0),
				Color(0.00, 0.82, 0.98, 1.0),
				Color(0.84, 0.98, 1.00, 1.0),
				0.78,
				0.75
			)
			core_aura.color = Color(0.00, 0.88, 1.00, 0.65)
			core_aura.amount = 8
			core_aura.emitting = vfx_on
			laser_warning_glow.color = Color(0.00, 0.85, 1.00, 0.24)
			laser_warning.color = Color(1.0, 0.55, 0.20, 0.85)
			laser_beam.color = Color(0.05, 0.75, 1.00, 0.92)
			laser_beam_core.color = Color(0.88, 0.98, 1.00, 0.98)
			laser_beam.offset_top = -12.0
			laser_beam.offset_bottom = 12.0
			laser_beam_core.offset_top = 8.0
			laser_beam_core.offset_bottom = 16.0
			phase_sparks.emitting = false


func _set_boss_palette(
	armor_shadow: Color,
	armor_highlight: Color,
	energy_shadow: Color,
	energy_mid: Color,
	energy_highlight: Color,
	armor_blend: float,
	energy_blend: float
) -> void:
	if _boss_material == null:
		return
	_boss_material.set_shader_parameter(&"armor_shadow", armor_shadow)
	_boss_material.set_shader_parameter(&"armor_highlight", armor_highlight)
	_boss_material.set_shader_parameter(&"energy_shadow", energy_shadow)
	_boss_material.set_shader_parameter(&"energy_mid", energy_mid)
	_boss_material.set_shader_parameter(&"energy_highlight", energy_highlight)
	_boss_material.set_shader_parameter(&"armor_blend", armor_blend)
	_boss_material.set_shader_parameter(&"energy_blend", energy_blend)


func _trigger_hit_flash(strength: float, duration: float, color: Color) -> void:
	if _boss_material == null:
		return
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	_boss_material.set_shader_parameter(&"flash_color", color)
	_boss_material.set_shader_parameter(&"hit_flash", strength)
	_flash_tween = create_tween()
	_flash_tween.tween_method(
		func(val: float) -> void:
			if _boss_material != null:
				_boss_material.set_shader_parameter(&"hit_flash", val),
		strength,
		0.0,
		duration
	)


func _set_laser_warning_visible(is_visible: bool) -> void:
	_kill_warn_tween()
	laser_warning.visible = is_visible
	laser_warning_glow.visible = is_visible
	if is_visible:
		laser_warning.modulate.a = 1.0
		laser_warning_glow.modulate.a = 1.0
		_warn_tween = create_tween().set_loops()
		_warn_tween.tween_property(laser_warning, "modulate:a", 0.35, 0.08)
		_warn_tween.parallel().tween_property(laser_warning_glow, "modulate:a", 0.15, 0.08)
		_warn_tween.tween_property(laser_warning, "modulate:a", 1.0, 0.08)
		_warn_tween.parallel().tween_property(laser_warning_glow, "modulate:a", 1.0, 0.08)


func _on_visual_effects_changed(_level: int) -> void:
	if current_state == BossState.DEAD:
		core_aura.emitting = false
		phase_sparks.emitting = false
		return
	var vfx_on: bool = _are_vfx_enabled()
	core_aura.emitting = vfx_on
	phase_sparks.emitting = vfx_on and current_phase == Phase.PHASE_3_OVERLOAD


func _are_vfx_enabled() -> bool:
	return not has_node("/root/SettingsManager") or SettingsManager.visual_effects > 0


func _kill_active_tweens() -> void:
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	_kill_slam_tween()
	_kill_warn_tween()


func _kill_slam_tween() -> void:
	if _slam_tween and _slam_tween.is_running():
		_slam_tween.kill()


func _kill_warn_tween() -> void:
	if _warn_tween and _warn_tween.is_running():
		_warn_tween.kill()


func _trigger_camera_shake(strength: float, duration: float) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref) or _player_ref.camera == null:
		return
	if not _are_vfx_enabled():
		return
	var cam: Camera2D = _player_ref.camera
	var shake: Tween = create_tween()
	var steps: int = 5
	var step_t: float = duration / float(steps)
	for _i in range(steps - 1):
		var off := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		shake.tween_property(cam, "offset", off, step_t)
	shake.tween_property(cam, "offset", Vector2.ZERO, step_t)


func _on_animation_finished() -> void:
	if animated_sprite.animation == &"hurt":
		_hurt_anim_playing = false
	elif animated_sprite.animation == &"death":
		if _defeat_emitted:
			return
		_defeat_emitted = true
		boss_defeated.emit(score_reward)
		queue_free()
