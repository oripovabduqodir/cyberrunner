extends Area2D
class_name Pickup

## Qayta ishlatiladigan Pickup tizimi: Health Pack (+25 HP), Ammo Pack (+24), Energy Cell (+30).

signal collected(pickup: Pickup)

enum PickupType {
	HEALTH_PACK,
	AMMO_PACK,
	ENERGY_CELL,
}

@export var pickup_type: PickupType = PickupType.HEALTH_PACK
@export var health_amount: int = 25
@export var ammo_amount: int = 24
@export var energy_amount: float = 30.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _base_y: float = 0.0
var _time: float = 0.0
var _is_collected: bool = false


func _ready() -> void:
	_base_y = sprite.position.y
	_apply_visual_type()
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _is_collected:
		return
	_time += delta * 3.0
	sprite.position.y = _base_y + sin(_time) * 4.0


func _apply_visual_type() -> void:
	match pickup_type:
		PickupType.HEALTH_PACK:
			sprite.region_rect = Rect2(0, 0, 32, 32)
		PickupType.AMMO_PACK:
			sprite.region_rect = Rect2(32, 0, 32, 32)
		PickupType.ENERGY_CELL:
			sprite.region_rect = Rect2(64, 0, 32, 32)


func _on_body_entered(body: Node2D) -> void:
	if _is_collected or not (body is Player):
		return

	var player := body as Player
	var applied: bool = false

	match pickup_type:
		PickupType.HEALTH_PACK:
			applied = player.heal(health_amount) > 0
		PickupType.AMMO_PACK:
			player.add_ammo(ammo_amount)
			applied = true
		PickupType.ENERGY_CELL:
			applied = player.restore_energy(energy_amount) > 0.0

	if not applied:
		return

	_is_collected = true
	collision_shape.set_deferred("disabled", true)
	collected.emit(self)

	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(2.2, 2.2), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.18)
	await tween.finished
	queue_free()
