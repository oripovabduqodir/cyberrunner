extends Control
class_name PauseMenu

## O'yin ichidagi Pauza menyusi (process_mode = ALWAYS).
## RESUME, SETTINGS, RESTART LEVEL va MAIN MENU ni boshqaradi.

signal resumed
signal restart_requested
signal main_menu_requested

const SETTINGS_SCENE: PackedScene = preload("res://scenes/ui/settings_menu.tscn")

@onready var main_panel: PanelContainer = $Center/MainPanel
@onready var resume_btn: CyberButton = $Center/MainPanel/Margin/VBox/ResumeButton
@onready var settings_btn: CyberButton = $Center/MainPanel/Margin/VBox/SettingsButton
@onready var restart_btn: CyberButton = $Center/MainPanel/Margin/VBox/RestartButton
@onready var menu_btn: CyberButton = $Center/MainPanel/Margin/VBox/MainMenuButton

var _settings_instance: SettingsMenu = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	resume_btn.pressed.connect(close_pause)
	settings_btn.pressed.connect(_on_settings_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_main_menu_pressed)


func _exit_tree() -> void:
	if get_tree().paused:
		get_tree().paused = false


func open_pause() -> void:
	if visible:
		return
	visible = true
	main_panel.visible = true
	get_tree().paused = true
	MobileInputManager.release_all_actions()
	resume_btn.grab_focus()


func close_pause() -> void:
	if _settings_instance != null and is_instance_valid(_settings_instance):
		_settings_instance.queue_free()
		_settings_instance = null
	visible = false
	get_tree().paused = false
	resumed.emit()


func _on_settings_pressed() -> void:
	if _settings_instance != null and is_instance_valid(_settings_instance):
		return
	main_panel.visible = false
	_settings_instance = SETTINGS_SCENE.instantiate() as SettingsMenu
	_settings_instance.embedded_mode = true
	_settings_instance.closed.connect(_on_settings_closed)
	add_child(_settings_instance)


func _on_settings_closed() -> void:
	if _settings_instance != null and is_instance_valid(_settings_instance):
		_settings_instance.queue_free()
		_settings_instance = null
	main_panel.visible = true
	settings_btn.grab_focus()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	visible = false
	restart_requested.emit()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	visible = false
	main_menu_requested.emit()
