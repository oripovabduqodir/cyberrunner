extends Control
class_name MainMenu

## CYBER RUNNER asosiy menyusi.
## Logotip glitch animatsiyasi, Fade In, navigatsiya va Exit tasdiqlash oynasini boshqaradi.

const NEON_CITY_SCENE: String = "res://scenes/levels/neon_city.tscn"
const LEVEL_SELECT_SCENE: String = "res://scenes/ui/level_select.tscn"
const SETTINGS_SCENE: String = "res://scenes/ui/settings_menu.tscn"
const CREDITS_SCENE: String = "res://scenes/ui/credits_menu.tscn"

@onready var content_root: Control = $SafeArea/MainContainer
@onready var logo_main: Label = $SafeArea/MainContainer/HeaderBox/LogoWrapper/LogoMain
@onready var logo_glitch: Label = $SafeArea/MainContainer/HeaderBox/LogoWrapper/LogoGlitch
@onready var play_button: CyberButton = $SafeArea/MainContainer/MenuButtons/PlayButton
@onready var select_level_button: CyberButton = $SafeArea/MainContainer/MenuButtons/SelectLevelButton
@onready var settings_button: CyberButton = $SafeArea/MainContainer/MenuButtons/SettingsButton
@onready var credits_button: CyberButton = $SafeArea/MainContainer/MenuButtons/CreditsButton
@onready var exit_button: CyberButton = $SafeArea/MainContainer/MenuButtons/ExitButton
@onready var exit_overlay: ColorRect = $ExitOverlay
@onready var yes_button: CyberButton = $ExitOverlay/Center/ConfirmPanel/Margin/VBox/ButtonsRow/YesButton
@onready var cancel_button: CyberButton = $ExitOverlay/Center/ConfirmPanel/Margin/VBox/ButtonsRow/CancelButton
@onready var glitch_timer: Timer = $GlitchTimer

var _logo_glitch_base_pos: Vector2


func _ready() -> void:
	_logo_glitch_base_pos = logo_glitch.position
	exit_overlay.visible = false

	play_button.pressed.connect(_on_play_pressed)
	select_level_button.pressed.connect(_on_select_level_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	yes_button.pressed.connect(_on_exit_confirmed)
	cancel_button.pressed.connect(_on_exit_cancelled)
	glitch_timer.wait_time = 4.2
	glitch_timer.timeout.connect(_on_glitch_timer_timeout)

	content_root.modulate.a = 0.0
	var fade_tween: Tween = create_tween()
	fade_tween.tween_property(content_root, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	SceneTransition.fade_in(0.35)
	play_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if exit_overlay.visible and event.is_action_pressed("ui_cancel"):
		_on_exit_cancelled()
		get_viewport().set_input_as_handled()


func _on_play_pressed() -> void:
	LevelProgressManager.start_new_run()
	SceneTransition.change_scene_to_file(NEON_CITY_SCENE)


func _on_select_level_pressed() -> void:
	SceneTransition.change_scene_to_file(LEVEL_SELECT_SCENE)


func _on_settings_pressed() -> void:
	SceneTransition.change_scene_to_file(SETTINGS_SCENE)


func _on_credits_pressed() -> void:
	SceneTransition.change_scene_to_file(CREDITS_SCENE)


func _on_exit_pressed() -> void:
	exit_overlay.visible = true
	cancel_button.grab_focus()


func _on_exit_confirmed() -> void:
	get_tree().quit()


func _on_exit_cancelled() -> void:
	exit_overlay.visible = false
	exit_button.grab_focus()


func _on_glitch_timer_timeout() -> void:
	if SettingsManager.visual_effects == SettingsManager.VisualQuality.LOW:
		return

	var tween: Tween = create_tween()
	tween.tween_property(logo_glitch, "position", _logo_glitch_base_pos + Vector2(2.5, -1.0), 0.04)
	tween.parallel().tween_property(logo_main, "position:x", -1.0, 0.04)
	tween.tween_property(logo_glitch, "position", _logo_glitch_base_pos + Vector2(-2.0, 1.0), 0.04)
	tween.parallel().tween_property(logo_main, "position:x", 1.0, 0.04)
	tween.tween_property(logo_glitch, "position", _logo_glitch_base_pos, 0.05)
	tween.parallel().tween_property(logo_main, "position:x", 0.0, 0.05)
