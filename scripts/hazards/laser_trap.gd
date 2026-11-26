extends Area2D
class_name LaserTrap

## Vaqti-vaqti bilan faollashadigan lazer tuzog'i (ogohlantirish fazasi bilan).

enum State { INACTIVE, WARNING, ACTIVE }

@export var damage: int = 20
@export var inactive_duration: float = 2.0
@export var warning_duration: float = 0.65
@export var active_duration: float = 1.5
@export var beam_length: float = 192.0
@export var start_delay: float = 0.0

@onready var beam_visual: ColorRect = $BeamVisual
@onready var warning_line: ColorRect = $WarningLine
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var state_timer: Timer = $StateTimer

var _state: State = State.INACTIVE
var _player_inside: Player = null


func _ready() -> void:
	_setup_geometry()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	state_timer.timeout.connect(_on_state_timer_timeout)
	_enter_inactive(start_delay if start_delay > 0.0 else inactive_duration)


func _setup_geometry() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12.0, beam_length)
	collision_shape.shape = rect
	collision_shape.position = Vector2(0.0, beam_length * 0.5)

	beam_visual.position = Vector2(-5.0, 0.0)
	beam_visual.size = Vector2(10.0, beam_length)

	warning_line.position = Vector2(-1.5, 0.0)
	warning_line.size = Vector2(3.0, beam_length)


func _physics_process(_delta: float) -> void:
	if _state == State.ACTIVE and _player_inside != null and is_instance_valid(_player_inside):
		_player_inside.take_damage(damage, Vector2(0.0, -0.3))


func _enter_inactive(wait: float) -> void:
	_state = State.INACTIVE
	beam_visual.visible = false
	warning_line.visible = false
	collision_shape.set_deferred("disabled", true)
	state_timer.start(wait)


func _enter_warning() -> void:
	_state = State.WARNING
	beam_visual.visible = false
	warning_line.visible = true
	collision_shape.set_deferred("disabled", true)
	state_timer.start(warning_duration)


func _enter_active() -> void:
	_state = State.ACTIVE
	warning_line.visible = false
	beam_visual.visible = true
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
