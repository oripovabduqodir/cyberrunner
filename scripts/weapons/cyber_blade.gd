extends Node2D
class_name CyberBlade

## 360-darajali nishonga ega yaqin masofali energiya qilichi (Cyber Blade).
## Right Mouse Button yoki K tugmasi bilan hujum qiladi.

@export var damage: int = 35
@export var attack_cooldown: float = 0.5

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var slash_sprite: AnimatedSprite2D = $Hitbox/SlashSprite
@onready var cooldown_timer: Timer = $CooldownTimer

var _aim_direction: Vector2 = Vector2.RIGHT
var _is_attacking: bool = false
var _hit_targets_this_swing: Array[Node] = []


func _ready() -> void:
	cooldown_timer.wait_time = attack_cooldown
	hitbox_shape.disabled = true
	slash_sprite.visible = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.area_entered.connect(_on_hitbox_area_entered)
	slash_sprite.animation_finished.connect(_on_slash_finished)


func set_aim_direction(dir: Vector2) -> void:
	if dir.is_zero_approx():
		return
	_aim_direction = dir.normalized()
	rotation = _aim_direction.angle()
	slash_sprite.flip_v = _aim_direction.x < 0.0


func try_attack() -> bool:
	if _is_attacking or not cooldown_timer.is_stopped():
		return false

	_is_attacking = true
	_hit_targets_this_swing.clear()
	cooldown_timer.start(attack_cooldown)

	hitbox_shape.set_deferred("disabled", false)
	slash_sprite.visible = true
	slash_sprite.play(&"slash")
	return true


func _on_slash_finished() -> void:
	_is_attacking = false
	hitbox_shape.set_deferred("disabled", true)
	slash_sprite.visible = false


func _on_hitbox_body_entered(body: Node2D) -> void:
	_apply_hit(body)


func _on_hitbox_area_entered(area: Area2D) -> void:
	var target: Node = area if area.has_method("take_damage") else area.get_parent()
	if target != null:
		_apply_hit(target)


func _apply_hit(target: Node) -> void:
	if not _is_attacking or target == null or target in _hit_targets_this_swing:
		return
	if target.has_method("take_damage"):
		_hit_targets_this_swing.append(target)
		target.take_damage(damage, (_aim_direction + Vector2(0.0, -0.2)).normalized())
