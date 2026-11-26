extends Control
class_name MobileActionButton

## Multi-touch qo'llab-quvvatlaydigan Cyberpunk sensorli harakat tugmasi.
## Cooldown, Energy yetishmasligi va bosilish animatsiyasini ko'rsatadi.

signal button_tapped

@export var action_name: StringName = &""
@export var label_text: String = "ACT"
@export var accent_color: Color = Color(0.0, 0.941176, 1.0, 0.95)
@export var radius: float = 34.0

var _touch_index: int = -1
var _mouse_active: bool = false
var _is_pressed: bool = false
var _cooldown_ratio: float = 0.0 # 0 = tayyor, 1 = to'liq cooldown
var _resource_available: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size * 0.5


func _exit_tree() -> void:
	_release()


func set_cooldown_ratio(ratio: float) -> void:
	var clamped: float = clampf(ratio, 0.0, 1.0)
	if not is_equal_approx(_cooldown_ratio, clamped):
		_cooldown_ratio = clamped
		queue_redraw()


func set_resource_available(available: bool) -> void:
	if _resource_available != available:
		_resource_available = available
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		if _is_pressed:
			_release()
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _touch_index == -1 and get_global_rect().has_point(touch.position):
				_touch_index = touch.index
				_press()
		elif touch.index == _touch_index:
			_release()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _touch_index == -1 and get_global_rect().has_point(mb.position):
					_mouse_active = true
					_press()
			elif _mouse_active:
				_release()


func _press() -> void:
	if _is_pressed:
		return
	_is_pressed = true
	scale = Vector2(0.9, 0.9)
	if not action_name.is_empty():
		MobileInputManager.set_action_pressed(action_name, true)
	button_tapped.emit()
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_mouse_active = false
	if not _is_pressed:
		return
	_is_pressed = false
	scale = Vector2.ONE
	if not action_name.is_empty():
		MobileInputManager.set_action_pressed(action_name, false)
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var draw_col: Color = accent_color if _resource_available else Color(0.45, 0.48, 0.58, 0.65)
	var fill_alpha: float = 0.42 if _is_pressed else 0.22

	draw_circle(center, radius, Color(0.04, 0.06, 0.14, 0.65))
	draw_circle(center, radius - 3.0, Color(draw_col.r, draw_col.g, draw_col.b, fill_alpha))
	draw_arc(center, radius, 0.0, TAU, 32, draw_col, 2.5)

	if _cooldown_ratio > 0.01:
		draw_arc(center, radius - 4.0, -PI * 0.5, -PI * 0.5 + TAU * _cooldown_ratio, 24, Color(1.0, 0.0, 0.498039, 0.85), 3.5)

	var font: Font = ThemeDB.fallback_font
	var font_size: int = 14
	var text_size: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, center - Vector2(text_size.x * 0.5, -text_size.y * 0.32), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.99, 1.0, 0.95 if _resource_available else 0.5))
