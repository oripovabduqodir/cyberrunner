extends Node

## Mobil sensorli boshqaruv menejeri (Autoload: MobileInputManager).
## Virtual Joystick va Action tugmalaridan keladigan kirishlarni Input Map action'lariga xavfsiz uzatadi.

var _pressed_actions: Dictionary = {}
var _virtual_move_axis: float = 0.0
var _is_joystick_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_all_actions()


func set_move_axis(axis_x: float) -> void:
	_virtual_move_axis = clampf(axis_x, -1.0, 1.0)
	_is_joystick_active = not is_zero_approx(_virtual_move_axis)

	var left_pressed: bool = _virtual_move_axis < -0.2
	var right_pressed: bool = _virtual_move_axis > 0.2
	set_action_pressed(&"move_left", left_pressed)
	set_action_pressed(&"move_right", right_pressed)


func get_horizontal_intensity() -> float:
	if _is_joystick_active:
		return absf(_virtual_move_axis)
	return 1.0


func set_action_pressed(action: StringName, pressed: bool) -> void:
	var currently_pressed: bool = bool(_pressed_actions.get(action, false))
	if currently_pressed == pressed:
		return

	_pressed_actions[action] = pressed
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func release_all_actions() -> void:
	_virtual_move_axis = 0.0
	_is_joystick_active = false
	for action in _pressed_actions.keys():
		if bool(_pressed_actions[action]):
			Input.action_release(action)
		_pressed_actions[action] = false
