extends StaticBody2D
class_name SecurityDoor

## Tegishli Keycard mavjud bo'lganda ochiladigan xavfsizlik eshigi.

signal door_locked_attempted(required_keycard_id: String)
signal door_opened

@export var required_keycard_id: String = "lab_alpha"

@onready var door_sprite: Sprite2D = $DoorSprite
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var trigger_area: Area2D = $TriggerArea

var _is_open: bool = false
var _unlocked_by_keycard: bool = false


func _ready() -> void:
	trigger_area.body_entered.connect(_on_trigger_body_entered)


func unlock() -> void:
	_unlocked_by_keycard = true


func open_door() -> void:
	if _is_open:
		return
	_is_open = true
	door_sprite.region_rect = Rect2(192, 0, 64, 64)
	body_collision.set_deferred("disabled", true)

	var tween: Tween = create_tween()
	tween.tween_property(door_sprite, "position:y", door_sprite.position.y - 80.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(door_sprite, "modulate:a", 0.3, 0.4)
	door_opened.emit()


func _on_trigger_body_entered(body: Node2D) -> void:
	if _is_open or not (body is Player):
		return

	if _unlocked_by_keycard:
		open_door()
	else:
		door_locked_attempted.emit(required_keycard_id)
