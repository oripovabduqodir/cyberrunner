extends Area2D
class_name Checkpoint

## Modulli Checkpoint komponenti.
## Player kirganda faollashadi, neon chiroq yonadi va spawn nuqtasini uzatadi.

signal checkpoint_activated(spawn_position: Vector2)

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var activation_particles: CPUParticles2D = $ActivationParticles
@onready var spawn_marker: Marker2D = $SpawnMarker

var is_activated: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	animated_sprite.play(&"inactive")


func _on_body_entered(body: Node2D) -> void:
	if is_activated or not (body is Player):
		return

	is_activated = true
	animated_sprite.play(&"active")

	if not has_node("/root/SettingsManager") or SettingsManager.visual_effects > 0:
		activation_particles.restart()

	var pop_tween: Tween = create_tween()
	pop_tween.tween_property(animated_sprite, "scale", Vector2(2.25, 2.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(animated_sprite, "scale", Vector2(2.0, 2.0), 0.14)

	checkpoint_activated.emit(spawn_marker.global_position)
