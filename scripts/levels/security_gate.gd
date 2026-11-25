extends Area2D
class_name SecurityGate

## Daraja oxiridagi futuristik Security Gate komponenti.
## Player yetib kelganda gate_reached signalini yuboradi.

signal gate_reached

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var portal_particles: CPUParticles2D = $PortalParticles

var _triggered: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	animated_sprite.play(&"idle")
	if has_node("/root/SettingsManager"):
		SettingsManager.visual_effects_changed.connect(_on_vfx_changed)
		_on_vfx_changed(SettingsManager.visual_effects)


func _on_body_entered(body: Node2D) -> void:
	if _triggered or not (body is Player):
		return
	_triggered = true
	gate_reached.emit()


func _on_vfx_changed(quality: int) -> void:
	portal_particles.emitting = quality > 0
