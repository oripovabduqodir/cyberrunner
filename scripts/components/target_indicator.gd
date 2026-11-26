extends Node2D

## Tanlangan dushman ustida aylanuvchi kichik neon Target Indicator.

func _draw() -> void:
	var c_cyan := Color(0.0, 0.941176, 1.0, 0.92)
	var c_pink := Color(1.0, 0.0, 0.498039, 0.92)
	var r: float = 18.0
	draw_arc(Vector2.ZERO, r, 0.15, PI * 0.5 - 0.15, 8, c_cyan, 2.0)
	draw_arc(Vector2.ZERO, r, PI * 0.5 + 0.15, PI - 0.15, 8, c_pink, 2.0)
	draw_arc(Vector2.ZERO, r, PI + 0.15, PI * 1.5 - 0.15, 8, c_cyan, 2.0)
	draw_arc(Vector2.ZERO, r, PI * 1.5 + 0.15, TAU - 0.15, 8, c_pink, 2.0)
