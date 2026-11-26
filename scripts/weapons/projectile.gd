extends Area2D
class_name Projectile

## Player va dushmanlar uchun umumiy energiya snaryadi.
## Object Pooling (recycle_requested) va oddiy queue_free() ni qo'llab-quvvatlaydi.

signal recycle_requested(projectile: Projectile)

const PLAYER_BULLET_TEX: Texture2D = preload("res://assets/weapons/plasma_bullet.png")
const ENEMY_BULLET_TEX: Texture2D = preload("res://assets/weapons/fx/enemy-shot-1.png")

@export var default_lifetime: float = 2.2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var trail_particles: CPUParticles2D = $TrailParticles
@onready var hit_particles: CPUParticles2D = $HitParticles
@onready var impact_sprite: Sprite2D = $ImpactSprite

var _speed: float = 650.0
var _damage: int = 20
var _direction: Vector2 = Vector2.RIGHT
var _owner_node: Node = null
var _is_active: bool = false
var _is_pooled: bool = false
var _life_timer: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	set_physics_process(false)


func launch(
	spawn_pos: Vector2,
	direction: Vector2,
	speed: float,
	damage: int,
	is_enemy: bool,
	owner_node: Node,
	pooled: bool = false
) -> void:
	global_position = spawn_pos
	_direction = direction.normalized()
	_speed = speed
	_damage = damage
	_owner_node = owner_node
	_is_pooled = pooled
	_life_timer = default_lifetime
	_is_active = true

	rotation = _direction.angle()

	# Collision layers:
	# 1: world, 2: player, 3: enemies, 4: player_projectiles (8), 5: enemy_projectiles (16)
	if is_enemy:
		collision_layer = 16
		collision_mask = 3 # world + player
		sprite.texture = ENEMY_BULLET_TEX
		sprite.region_enabled = false
		sprite.scale = Vector2(1.5, 1.5)
		sprite.modulate = Color(1.0, 0.35, 0.45, 1.0)
		impact_sprite.modulate = Color(1.0, 0.35, 0.45, 0.95)
		trail_particles.color = Color(1.0, 0.25, 0.35, 0.7)
		hit_particles.color = Color(1.0, 0.35, 0.2, 0.9)
	else:
		collision_layer = 8
		collision_mask = 5 # world + enemies
		sprite.texture = PLAYER_BULLET_TEX
		sprite.region_enabled = false
		sprite.scale = Vector2(2.6, 2.6)
		sprite.modulate = Color.WHITE
		impact_sprite.modulate = Color(0.25, 0.95, 1.0, 0.95)
		trail_particles.color = Color(0.0, 0.941176, 1.0, 0.7)
		hit_particles.color = Color(0.0, 0.941176, 1.0, 0.95)

	impact_sprite.visible = false
	visible = true
	sprite.visible = true
	collision_shape.set_deferred("disabled", false)
	var vfx_on: bool = not has_node("/root/SettingsManager") or SettingsManager.visual_effects > 0
	trail_particles.emitting = vfx_on
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	global_position += _direction * _speed * delta
	_life_timer -= delta
	if _life_timer <= 0.0:
		_impact(false)


func _on_body_entered(body: Node2D) -> void:
	if not _is_active or body == _owner_node:
		return

	if body.has_method("take_damage"):
		body.take_damage(_damage, _direction)

	_impact(true)


func _on_area_entered(area: Area2D) -> void:
	if not _is_active or area == _owner_node:
		return

	var parent_node: Node = area.get_parent()
	if parent_node == _owner_node:
		return

	if area.has_method("take_damage"):
		area.take_damage(_damage, _direction)
		_impact(true)
	elif parent_node != null and parent_node.has_method("take_damage"):
		parent_node.take_damage(_damage, _direction)
		_impact(true)


func _impact(show_hit_vfx: bool) -> void:
	if not _is_active:
		return
	_is_active = false
	set_physics_process(false)
	collision_shape.set_deferred("disabled", true)
	sprite.visible = false
	trail_particles.emitting = false

	var vfx_on: bool = show_hit_vfx and (not has_node("/root/SettingsManager") or SettingsManager.visual_effects > 0)
	if vfx_on:
		impact_sprite.visible = true
		hit_particles.restart()
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(impact_sprite):
			impact_sprite.visible = false
		await get_tree().create_timer(0.14).timeout

	visible = false
	if _is_pooled:
		recycle_requested.emit(self)
	else:
		queue_free()
