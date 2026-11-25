extends Control
class_name LevelSelect

## Darajalarni tanlash oynasi: Level 01 (ochiq), Level 02 va Level 03 (qulflangan).

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const NEON_CITY_SCENE: String = "res://scenes/levels/neon_city.tscn"

@onready var play_level_1_button: CyberButton = $SafeArea/VBox/CardsRow/Card1/Margin/VBox/PlayLevel1Button
@onready var back_button: CyberButton = $SafeArea/VBox/FooterRow/BackButton


func _ready() -> void:
	play_level_1_button.pressed.connect(_on_play_level_1_pressed)
	back_button.pressed.connect(_on_back_pressed)
	play_level_1_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _on_play_level_1_pressed() -> void:
	SceneTransition.change_scene_to_file(NEON_CITY_SCENE)


func _on_back_pressed() -> void:
	SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
