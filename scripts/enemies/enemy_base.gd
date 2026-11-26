extends CharacterBody2D
class_name EnemyBase

## Barcha dushmanlar uchun umumiy baza klassi.
## State Machine, Health, Line-of-Sight (devor ortidan ko'rmaslik), Hit Flash va Score Reward ni boshqaradi.

signal enemy_died(enemy: EnemyBase, score_reward: int)

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HURT,
	DEAD,
}

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/weapons/projectile.tscn")

@export_group("Asosiy Parametrlar")
@export var damage: int = 15
@export var score_reward: int = 100
@export var detection_range: float = 340.0
@export var attack_range: float = 48.0
@export var attack_cooldown: float = 1.1

@onready var health_component: HealthComponent = $HealthComponent
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var los_ray: RayCast2D = $LineOfSightRay
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

var current_state: State = State.PATROL
var _player_ref: Player = null
var _facing_dir: int = 1
var _flash_tween: Tween


func _ready() -> void:
	add_to_group(&"enemies")
	attack_cooldown_timer.wait_time = attack_cooldown
	health_component.damaged.connect(_on_damaged)
	health_component.died.connect(_on_died)
	_find_player()


func _find_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if not players.is_empty() and players[0] is Player:
		_player_ref = players[0] as Player


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> bool:
	if current_state == State.DEAD:
		return false
	return health_component.take_damage(amount, knockback_dir)


func _can_see_player() -> bool:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_find_player()
	if _player_ref == null or _player_ref.health_component.is_dead():
		return false

	var to_player: Vector2 = _player_ref.global_position - global_position
	if to_player.length_squared() > detection_range * detection_range:
		return false

	los_ray.target_position = to_local(_player_ref.global_position)
	los_ray.force_raycast_update()
	return not los_ray.is_colliding()


func _distance_to_player() -> float:
	if _player_ref == null or not is_instance_valid(_player_ref):
		return INF
	return global_position.distance_to(_player_ref.global_position)


func _face_direction(dir: int) -> void:
	_facing_dir = 1 if dir >= 0 else -1
	animated_sprite.flip_h = _facing_dir < 0


func _spawn_enemy_projectile(origin: Vector2, direction: Vector2, speed: float) -> void:
	var proj := PROJECTILE_SCENE.instantiate() as Projectile
	var parent_node: Node = get_tree().current_scene
	if parent_node == null:
		parent_node = get_tree().root
	parent_node.add_child(proj)
	proj.launch(origin, direction, speed, damage, true, self, false)


func _on_damaged(_amount: int, _knockback_dir: Vector2) -> void:
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	animated_sprite.modulate = Color(2.0, 0.35, 0.45, 1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.14)


func _on_died() -> void:
	current_state = State.DEAD
	collision_shape.set_deferred("disabled", true)
	velocity = Vector2.ZERO
	enemy_died.emit(self, score_reward)
