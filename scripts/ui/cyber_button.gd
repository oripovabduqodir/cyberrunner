extends Button
class_name CyberButton

## Qayta ishlatiladigan Cyberpunk uslubidagi tugma komponenti.
## Hover, Focus va Pressed holatlari uchun yengil Tween animatsiyalariga ega.

@export var hover_scale: Vector2 = Vector2(1.03, 1.03)
@export var press_scale: Vector2 = Vector2(0.96, 0.96)
@export var anim_duration: float = 0.09

var _scale_tween: Tween


func _ready() -> void:
	_update_pivot()
	resized.connect(_update_pivot)
	mouse_entered.connect(_on_hover_or_focus_entered)
	mouse_exited.connect(_on_hover_or_focus_exited)
	focus_entered.connect(_on_hover_or_focus_entered)
	focus_exited.connect(_on_hover_or_focus_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _on_hover_or_focus_entered() -> void:
	if disabled:
		return
	_animate_scale(hover_scale)


func _on_hover_or_focus_exited() -> void:
	if disabled:
		return
	if not has_focus() and not is_hovered():
		_animate_scale(Vector2.ONE)


func _on_button_down() -> void:
	if disabled:
		return
	_animate_scale(press_scale)


func _on_button_up() -> void:
	if disabled:
		return
	var target: Vector2 = hover_scale if (is_hovered() or has_focus()) else Vector2.ONE
	_animate_scale(target)


func _animate_scale(target_scale: Vector2) -> void:
	if _scale_tween and _scale_tween.is_running():
		_scale_tween.kill()
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", target_scale, anim_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
