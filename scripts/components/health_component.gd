extends Node
class_name HealthComponent

## Qayta ishlatiladigan modulli sog'liq (HP) komponenti.
## Player va barcha dushmanlar uchun umumiy zarar, tiklanish, i-frames va o'limni boshqaradi.

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int, knockback_dir: Vector2)
signal healed(amount: int)
signal died

@export var max_health: int = 100
@export var invincibility_duration: float = 0.0

var current_health: int = 100
var _invincibility_timer: float = 0.0
var _is_dead: bool = false


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func _process(delta: float) -> void:
	if _invincibility_timer > 0.0:
		_invincibility_timer = maxf(0.0, _invincibility_timer - delta)


func is_invincible() -> bool:
	return _invincibility_timer > 0.0


func is_dead() -> bool:
	return _is_dead


func take_damage(amount: int, knockback_dir: Vector2 = Vector2.ZERO) -> bool:
	if _is_dead or amount <= 0 or is_invincible():
		return false

	current_health = maxi(0, current_health - amount)
	if invincibility_duration > 0.0:
		_invincibility_timer = invincibility_duration

	health_changed.emit(current_health, max_health)
	damaged.emit(amount, knockback_dir)

	if current_health == 0:
		_is_dead = true
		died.emit()

	return true


func heal(amount: int) -> int:
	if _is_dead or amount <= 0 or current_health >= max_health:
		return 0

	var previous: int = current_health
	current_health = mini(max_health, current_health + amount)
	var gained: int = current_health - previous
	if gained > 0:
		health_changed.emit(current_health, max_health)
		healed.emit(gained)
	return gained


func reset_health() -> void:
	_is_dead = false
	_invincibility_timer = 0.0
	current_health = max_health
	health_changed.emit(current_health, max_health)
