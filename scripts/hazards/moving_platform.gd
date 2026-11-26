extends AnimatableBody2D
class_name MovingPlatform

## Gorizontal va vertikal harakatlanuvchi platforma (sync_to_physics = true).
## Personaj ustida turganda platforma bilan birga ravon harakatlanadi.

@export var move_offset: Vector2 = Vector2(192.0, 0.0)
@export var speed: float = 95.0
@export var pause_time: float = 0.45

var _start_pos: Vector2
var _end_pos: Vector2
var _moving_to_end: bool = true
var _pause_timer: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	_start_pos = global_position
	_end_pos = _start_pos + move_offset


func _physics_process(delta: float) -> void:
	if move_offset.is_zero_approx():
		return

	if _pause_timer > 0.0:
		_pause_timer = maxf(0.0, _pause_timer - delta)
		return

	var target: Vector2 = _end_pos if _moving_to_end else _start_pos
	global_position = global_position.move_toward(target, speed * delta)

	if global_position.distance_squared_to(target) <= 1.0:
		global_position = target
		_moving_to_end = not _moving_to_end
		_pause_timer = pause_time
