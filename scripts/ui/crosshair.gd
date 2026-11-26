extends Control
class_name NeonCrosshair

## Sichqoncha kursori uchun kichik neon kiberpank nishon (Crosshair).

@export var reticle_color: Color = Color(0.0, 0.941176, 1.0, 0.95)
@export var accent_color: Color = Color(1.0, 0.0, 0.498039, 0.9)

var _active: bool = true
var _pulse_scale: float = 1.0
var _pulse_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_active(not OS.has_feature("mobile"))


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(_delta: float) -> void:
	if not _active:
		return
	global_position = get_viewport().get_mouse_position()


func set_active(active: bool) -> void:
	_active = active
	visible = active
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if active else Input.MOUSE_MODE_VISIBLE)


func pulse() -> void:
	if not _active:
		return
	if _pulse_tween and _pulse_tween.is_running():
		_pulse_tween.kill()
	_pulse_scale = 1.35
	_pulse_tween = create_tween()
	_pulse_tween.tween_method(_set_pulse_scale, 1.35, 1.0, 0.1)


func _set_pulse_scale(val: float) -> void:
	_pulse_scale = val
	queue_redraw()


func _draw() -> void:
	var gap: float = 5.0 * _pulse_scale
	var arm: float = 6.0 * _pulse_scale

	# 4 ta neon chiziq
	draw_line(Vector2(-gap - arm, 0), Vector2(-gap, 0), reticle_color, 2.0)
	draw_line(Vector2(gap, 0), Vector2(gap + arm, 0), reticle_color, 2.0)
	draw_line(Vector2(0, -gap - arm), Vector2(0, -gap), reticle_color, 2.0)
	draw_line(Vector2(0, gap), Vector2(0, gap + arm), reticle_color, 2.0)

	# Markaziy nuqta
	draw_circle(Vector2.ZERO, 2.0, accent_color)
