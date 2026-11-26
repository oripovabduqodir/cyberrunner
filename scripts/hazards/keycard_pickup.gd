extends Area2D
class_name KeycardPickup

## Xavfsizlik eshiklarini ochish uchun maxsus Keycard obyekti.

signal keycard_collected(keycard_id: String)

@export var keycard_id: String = "lab_alpha"

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _base_y: float = 0.0
var _time: float = 0.0
var _collected: bool = false


func _ready() -> void:
	_base_y = sprite.position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta * 3.2
	sprite.position.y = _base_y + sin(_time) * 5.0
	var frame_idx: int = int(_time * 2.5) % 8
	sprite.region_rect = Rect2(frame_idx * 24, 0, 24, 24)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not (body is Player):
		return

	_collected = true
	collision_shape.set_deferred("disabled", true)
	keycard_collected.emit(keycard_id)

	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(2.4, 2.4), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
