extends Node2D
class_name PlasmaPistol

## 360-darajali nishonga ega Plasma Pistol qurol tizimi.
## Avtomatik otish (cooldown bilan), qayta o'qlash, Muzzle Flash va Object Pooling ni boshqaradi.

signal ammo_changed(magazine: int, max_magazine: int, reserve: int)
signal reload_started
signal reload_finished
signal fired

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/weapons/projectile.tscn")

@export var weapon_name: String = "PLASMA PISTOL"
@export var damage: int = 20
@export var magazine_capacity: int = 12
@export var reserve_ammo: int = 48
@export var fire_cooldown: float = 0.25
@export var reload_time: float = 1.2
@export var projectile_speed: float = 720.0
@export var pool_initial_size: int = 14
@export var orbit_radius: float = 12.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var muzzle: Marker2D = $Muzzle
@onready var muzzle_flash: ColorRect = $Muzzle/MuzzleFlash
@onready var muzzle_fx: Sprite2D = $Muzzle/MuzzleFx
@onready var muzzle_particles: CPUParticles2D = $Muzzle/MuzzleParticles
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var reload_timer: Timer = $ReloadTimer

var current_magazine: int = 12
var current_reserve: int = 48
var _is_reloading: bool = false
var _aim_direction: Vector2 = Vector2.RIGHT
var _pool: Array[Projectile] = []
var _pool_root: Node = null
var _anim_tween: Tween


func _ready() -> void:
	current_magazine = magazine_capacity
	current_reserve = reserve_ammo
	cooldown_timer.wait_time = fire_cooldown
	reload_timer.wait_time = reload_time
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	muzzle_flash.visible = false
	ammo_changed.emit(current_magazine, magazine_capacity, current_reserve)


## 360° nishon yo'nalishini o'rnatadi; chapga qaratilganda tasvir teskari bo'lib qolmaydi.
func set_aim_direction(dir: Vector2) -> void:
	if dir.is_zero_approx():
		return
	_aim_direction = dir.normalized()
	rotation = _aim_direction.angle()
	position = _aim_direction * orbit_radius + Vector2(0.0, 2.0)

	var aiming_left: bool = _aim_direction.x < 0.0
	sprite.flip_v = aiming_left
	muzzle.position.y = 3.0 if aiming_left else -3.0


func is_reloading() -> bool:
	return _is_reloading


func try_fire(owner_node: Node) -> bool:
	if _is_reloading or not cooldown_timer.is_stopped():
		return false

	if current_magazine <= 0:
		if current_reserve > 0:
			start_reload()
		return false

	current_magazine = maxi(0, current_magazine - 1)
	cooldown_timer.start(fire_cooldown)
	ammo_changed.emit(current_magazine, magazine_capacity, current_reserve)

	_spawn_projectile(owner_node)
	_play_shoot_fx()
	fired.emit()

	if current_magazine == 0 and current_reserve > 0:
		start_reload()
	return true


func start_reload() -> void:
	if _is_reloading or current_magazine >= magazine_capacity or current_reserve <= 0:
		return

	_is_reloading = true
	reload_started.emit()
	reload_timer.start(reload_time)
	_play_reload_animation()


func add_ammo(amount: int) -> void:
	if amount <= 0:
		return
	current_reserve = maxi(0, current_reserve + amount)
	ammo_changed.emit(current_magazine, magazine_capacity, current_reserve)


func reset_ammo() -> void:
	_is_reloading = false
	reload_timer.stop()
	current_magazine = magazine_capacity
	current_reserve = reserve_ammo
	sprite.rotation = 0.0
	sprite.position = Vector2.ZERO
	ammo_changed.emit(current_magazine, magazine_capacity, current_reserve)


func _on_reload_timer_timeout() -> void:
	var needed: int = magazine_capacity - current_magazine
	var loaded: int = mini(needed, current_reserve)
	current_magazine += loaded
	current_reserve = maxi(0, current_reserve - loaded)
	_is_reloading = false
	sprite.rotation = 0.0
	ammo_changed.emit(current_magazine, magazine_capacity, current_reserve)
	reload_finished.emit()


func _spawn_projectile(owner_node: Node) -> void:
	_ensure_pool()
	var proj: Projectile = _acquire_projectile()
	proj.launch(
		muzzle.global_position,
		_aim_direction,
		projectile_speed,
		damage,
		false,
		owner_node,
		true
	)


func _ensure_pool() -> void:
	if _pool_root != null and is_instance_valid(_pool_root):
		return

	var target_parent: Node = get_tree().current_scene
	if target_parent == null:
		target_parent = get_tree().root

	_pool_root = Node.new()
	_pool_root.name = "PlayerProjectilePool"
	target_parent.add_child(_pool_root)

	for i in range(pool_initial_size):
		var proj := PROJECTILE_SCENE.instantiate() as Projectile
		proj.visible = false
		proj.recycle_requested.connect(_on_projectile_recycled)
		_pool_root.add_child(proj)
		_pool.append(proj)


func _acquire_projectile() -> Projectile:
	while not _pool.is_empty():
		var p: Projectile = _pool.pop_back()
		if is_instance_valid(p):
			return p

	var new_proj := PROJECTILE_SCENE.instantiate() as Projectile
	new_proj.recycle_requested.connect(_on_projectile_recycled)
	_pool_root.add_child(new_proj)
	return new_proj


func _on_projectile_recycled(proj: Projectile) -> void:
	if is_instance_valid(proj) and not _pool.has(proj):
		_pool.append(proj)


func _play_shoot_fx() -> void:
	muzzle_fx.visible = true
	muzzle_fx.frame = 0
	if not has_node("/root/SettingsManager") or SettingsManager.visual_effects > 0:
		muzzle_particles.restart()

	if _anim_tween and _anim_tween.is_running():
		_anim_tween.kill()
	sprite.position = Vector2(-5.0, 0.0)
	_anim_tween = create_tween()
	_anim_tween.tween_property(sprite, "position", Vector2.ZERO, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.03).timeout
	if is_instance_valid(muzzle_fx):
		muzzle_fx.frame = 2
	await get_tree().create_timer(0.03).timeout
	if is_instance_valid(muzzle_fx):
		muzzle_fx.visible = false


func _play_reload_animation() -> void:
	if _anim_tween and _anim_tween.is_running():
		_anim_tween.kill()
	_anim_tween = create_tween()
	var tilt: float = 0.55 if sprite.flip_v else -0.55
	_anim_tween.tween_property(sprite, "rotation", tilt, 0.2)
	_anim_tween.tween_interval(maxf(0.1, reload_time - 0.4))
	_anim_tween.tween_property(sprite, "rotation", 0.0, 0.2)
