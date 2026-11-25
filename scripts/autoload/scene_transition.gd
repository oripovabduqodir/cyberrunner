extends CanvasLayer

## Sahnalar o'rtasida ravon Fade Out / Fade In o'tish tizimi (Autoload: SceneTransition).

@onready var fade_rect: ColorRect = $FadeRect

var _is_transitioning: bool = false


func _ready() -> void:
	fade_rect.color = Color(0.02, 0.02, 0.05, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_in(duration: float = 0.45) -> void:
	fade_rect.color.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func change_scene_to_file(scene_path: String, duration: float = 0.3) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var out_tween: Tween = create_tween()
	out_tween.tween_property(fade_rect, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await out_tween.finished

	get_tree().change_scene_to_file(scene_path)

	var in_tween: Tween = create_tween()
	in_tween.tween_property(fade_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await in_tween.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
