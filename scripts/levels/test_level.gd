extends Node2D
class_name TestLevel

## 2-bosqich uchun sinov xaritasi boshqaruvchisi.
## Kamera chegaralarini o'rnatadi, chuqurlikka tushganda va R bosilganda qayta tiklaydi.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@export var level_bounds: Rect2i = Rect2i(0, 0, 2560, 720)

@onready var player: Player = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var fall_zone: Area2D = $FallZone


func _ready() -> void:
	player.set_camera_limits(
		level_bounds.position.x,
		level_bounds.position.y,
		level_bounds.end.x,
		level_bounds.end.y
	)
	player.respawn_at(spawn_point.global_position)
	fall_zone.body_entered.connect(_on_fall_zone_body_entered)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart"):
		player.respawn_at(spawn_point.global_position)


func _on_fall_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).respawn_at(spawn_point.global_position)
