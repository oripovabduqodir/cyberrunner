extends Control
class_name LevelSelect

## Darajalarni tanlash oynasi: LevelProgressManager asosida qulfni ochadi.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const NEON_CITY_SCENE: String = "res://scenes/levels/neon_city.tscn"
const SECRET_LAB_SCENE: String = "res://scenes/levels/secret_laboratory.tscn"
const FINAL_BATTLE_SCENE: String = "res://scenes/levels/final_battle.tscn"

@onready var play_level_1_button: CyberButton = $SafeArea/VBox/CardsRow/Card1/Margin/VBox/PlayLevel1Button
@onready var sector_1_label: Label = $SafeArea/VBox/CardsRow/Card1/Margin/VBox/Banner/SectorCode
@onready var play_level_2_button: CyberButton = $SafeArea/VBox/CardsRow/Card2/Margin/VBox/LockedButton2
@onready var sector_2_label: Label = $SafeArea/VBox/CardsRow/Card2/Margin/VBox/Banner/SectorCode
@onready var desc_2_label: Label = $SafeArea/VBox/CardsRow/Card2/Margin/VBox/Desc
@onready var play_level_3_button: CyberButton = $SafeArea/VBox/CardsRow/Card3/Margin/VBox/LockedButton3
@onready var sector_3_label: Label = $SafeArea/VBox/CardsRow/Card3/Margin/VBox/Banner/SectorCode
@onready var desc_3_label: Label = $SafeArea/VBox/CardsRow/Card3/Margin/VBox/Desc
@onready var back_button: CyberButton = $SafeArea/VBox/FooterRow/BackButton


func _ready() -> void:
	play_level_1_button.pressed.connect(func() -> void:
		LevelProgressManager.start_new_run()
		SceneTransition.change_scene_to_file(NEON_CITY_SCENE)
	)
	play_level_2_button.pressed.connect(func() -> void:
		SceneTransition.change_scene_to_file(SECRET_LAB_SCENE)
	)
	play_level_3_button.pressed.connect(func() -> void:
		SceneTransition.change_scene_to_file(FINAL_BATTLE_SCENE)
	)
	back_button.pressed.connect(_on_back_pressed)

	_refresh_unlock_state()
	play_level_1_button.grab_focus()


func _refresh_unlock_state() -> void:
	var l2_unlocked: bool = LevelProgressManager.is_level_unlocked(2)
	sector_1_label.text = "SECTOR // 01  [COMPLETED]" if l2_unlocked else "SECTOR // 01  [UNLOCKED]"

	play_level_2_button.disabled = not l2_unlocked
	play_level_2_button.text = "DEPLOY" if l2_unlocked else "LOCKED"
	var l3_unlocked: bool = LevelProgressManager.is_level_unlocked(3)
	if l3_unlocked:
		sector_2_label.text = "SECTOR // 02  [COMPLETED]"
	elif l2_unlocked:
		sector_2_label.text = "SECTOR // 02  [UNLOCKED]"
	else:
		sector_2_label.text = "SECTOR // 02  [LOCKED]"
	if l2_unlocked:
		desc_2_label.text = "Yashirin yerosti robotlar laboratoriyasi. Tuzoqlar va Keycard tizimi."

	play_level_3_button.disabled = not l3_unlocked
	play_level_3_button.text = "DEPLOY" if l3_unlocked else "LOCKED"
	sector_3_label.text = "SECTOR // 03  [UNLOCKED]" if l3_unlocked else "SECTOR // 03  [LOCKED]"
	if l3_unlocked:
		desc_3_label.text = "Markaziy boshqaruv tizimi yadrosi. OMEGA-X yakuniy jangi."


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _on_back_pressed() -> void:
	SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
