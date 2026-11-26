extends Area2D
class_name ToxicLiquid

## Zaharli yashil suyuqlik hududi. Ichida qolgan o'yinchiga ma'lum intervalda zarar yetkazadi.

@export var damage: int = 12
@export var damage_interval: float = 0.65
@export var width_px: float = 192.0
@export var height_px: float = 40.0

@onready var visual_rect: ColorRect = $VisualRect
@onready var surface_glow: ColorRect = $SurfaceGlow
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tick_timer: Timer = $TickTimer

var _player_inside: Player = null
var _pulse_time: float = 0.0


func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_px, height_px)
	collision_shape.shape = rect
	collision_shape.position = Vector2(width_px * 0.5, height_px * 0.5)

	visual_rect.size = Vector2(width_px, height_px)
	surface_glow.size = Vector2(width_px, 6.0)

	tick_timer.wait_time = damage_interval
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_pulse_time += delta * 4.0
	surface_glow.color.a = 0.65 + 0.3 * sin(_pulse_time)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = body as Player
		_player_inside.take_damage(damage, Vector2.UP)
		tick_timer.start(damage_interval)


func _on_body_exited(body: Node2D) -> void:
	if body == _player_inside:
		_player_inside = null
		tick_timer.stop()


func _on_tick_timer_timeout() -> void:
	if _player_inside != null and is_instance_valid(_player_inside):
		_player_inside.take_damage(damage, Vector2.UP)
	else:
		tick_timer.stop()
