extends Control
class_name CreditsMenu

## O'yin mualliflari va tasdiqlangan grafik litsenziyalari oynasi.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var back_button: CyberButton = $Center/MainPanel/Margin/VBox/Footer/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _on_back_pressed() -> void:
	SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
