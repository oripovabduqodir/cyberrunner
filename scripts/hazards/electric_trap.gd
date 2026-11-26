extends Area2D
class_name ElectricTrap

## Elektr toki bilan zararlaydigan platforma tuzog'i (faol, ogohlantirish va nofaol holatlar).

enum State { INACTIVE, WARNING, ACTIVE }

@export var damage: int = 18
@export var inactive_duration: float = 2.0
@export var warning_duration: float = 0.6
@export var active_duration: float = 1.5
@export var start_delay: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var warning_bar: ColorRect = $WarningBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var state_timer: Timer = $StateTimer

var _state: State = State.INACTIVE
var _player_inside: Player = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	state_timer.timeout.connect(_on_state_timer_timeout)
	_enter_inactive(start_delay if start_delay > 0.0 else inactive_duration)


func _physics_process(_delta: float) -> void:
	if _state == State.ACTIVE and _player_inside != null and is_instance_valid(_player_inside):
		_player_inside.take_damage(damage, Vector2.UP)


func _enter_inactive(wait: float) -> void:
	_state = State.INACTIVE
	sprite.play(&"inactive")
	warning_bar.visible = false
	collision_shape.set_deferred("disabled", true)
	state_timer.start(wait)


func _enter_warning() -> void:
	_state = State.WARNING
	sprite.play(&"inactive")
	warning_bar.visible = true
	collision_shape.set_deferred("disabled", true)
	state_timer.start(warning_duration)


func _enter_active() -> void:
	_state = State.ACTIVE
	warning_bar.visible = false
	sprite.play(&"active")
	collision_shape.set_deferred("disabled", false)
	state_timer.start(active_duration)


func _on_state_timer_timeout() -> void:
	match _state:
		State.INACTIVE:
			_enter_warning()
		State.WARNING:
			_enter_active()
		State.ACTIVE:
			_enter_inactive(inactive_duration)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = body as Player


func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null
