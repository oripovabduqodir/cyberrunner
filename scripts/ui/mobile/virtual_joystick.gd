extends Control
class_name CyberVirtualJoystick

## Multi-touch qo'llab-quvvatlaydigan Cyberpunk Virtual Joystick.
## Android ScreenTouch va Windows Mobile Preview sichqoncha sinovi bilan ishlaydi.

@export var max_radius: float = 56.0
@export var deadzone: float = 0.2
@export var base_color: Color = Color(0.0, 0.941176, 1.0, 0.28)
@export var ring_color: Color = Color(0.0, 0.941176, 1.0, 0.85)
@export var knob_color: Color = Color(0.0, 0.941176, 1.0, 0.95)

var _touch_index: int = -1
var _mouse_active: bool = false
var _knob_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _exit_tree() -> void:
	_reset_stick()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		if _touch_index != -1 or _mouse_active:
			_reset_stick()
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index == -1 and get_global_rect().has_point(touch.position):
				_touch_index = touch.index
				_update_stick_from_global_pos(touch.position)
		elif touch.index == _touch_index:
			_reset_stick()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_stick_from_global_pos(drag.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _touch_index == -1 and get_global_rect().has_point(mb.position):
					_mouse_active = true
					_update_stick_from_global_pos(mb.position)
			elif _mouse_active:
				_reset_stick()
	elif event is InputEventMouseMotion:
		if _mouse_active:
			_update_stick_from_global_pos((event as InputEventMouseMotion).position)


func _update_stick_from_global_pos(global_pos: Vector2) -> void:
	var center: Vector2 = global_position + size * 0.5
	var delta: Vector2 = global_pos - center
	var scaled_radius: float = max_radius * scale.x
	if scaled_radius <= 1.0:
		scaled_radius = max_radius

	if delta.length() > scaled_radius:
		delta = delta.normalized() * scaled_radius

	_knob_offset = delta / maxf(scale.x, 0.1)
	var norm_x: float = clampf(delta.x / scaled_radius, -1.0, 1.0)
	if absf(norm_x) < deadzone:
		norm_x = 0.0

	MobileInputManager.set_move_axis(norm_x)
	queue_redraw()


func _reset_stick() -> void:
	_touch_index = -1
	_mouse_active = false
	_knob_offset = Vector2.ZERO
	MobileInputManager.set_move_axis(0.0)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	draw_circle(center, max_radius, Color(0.03, 0.05, 0.12, 0.45))
	draw_arc(center, max_radius, 0.0, TAU, 40, ring_color, 2.5)
	draw_arc(center, max_radius * 0.52, 0.0, TAU, 28, base_color, 1.5)

	# Chap/o'ng yo'nalish belgilari
	draw_line(center + Vector2(-max_radius + 10, 0), center + Vector2(-max_radius + 18, -6), ring_color, 2.0)
	draw_line(center + Vector2(-max_radius + 10, 0), center + Vector2(-max_radius + 18, 6), ring_color, 2.0)
	draw_line(center + Vector2(max_radius - 10, 0), center + Vector2(max_radius - 18, -6), ring_color, 2.0)
	draw_line(center + Vector2(max_radius - 10, 0), center + Vector2(max_radius - 18, 6), ring_color, 2.0)

	# Tugma (knob)
	var knob_pos: Vector2 = center + _knob_offset
	draw_circle(knob_pos, 22.0, Color(0.0, 0.941176, 1.0, 0.3))
	draw_arc(knob_pos, 22.0, 0.0, TAU, 24, knob_color, 2.5)
	draw_circle(knob_pos, 7.0, Color(1.0, 0.0, 0.498039, 0.9))
