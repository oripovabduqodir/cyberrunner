extends Control
class_name SettingsMenu

## O'yin sozlamalari oynasi: AudioServer buslari, Fullscreen (faqat PC) va Visual Effects.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@onready var master_slider: HSlider = $Center/MainPanel/Margin/VBox/FormGrid/MasterSliderRow/MasterSlider
@onready var master_value_label: Label = $Center/MainPanel/Margin/VBox/FormGrid/MasterSliderRow/MasterValue
@onready var music_slider: HSlider = $Center/MainPanel/Margin/VBox/FormGrid/MusicSliderRow/MusicSlider
@onready var music_value_label: Label = $Center/MainPanel/Margin/VBox/FormGrid/MusicSliderRow/MusicValue
@onready var sfx_slider: HSlider = $Center/MainPanel/Margin/VBox/FormGrid/SfxSliderRow/SfxSlider
@onready var sfx_value_label: Label = $Center/MainPanel/Margin/VBox/FormGrid/SfxSliderRow/SfxValue
@onready var fullscreen_label: Label = $Center/MainPanel/Margin/VBox/FormGrid/FullscreenLabel
@onready var fullscreen_check: CheckBox = $Center/MainPanel/Margin/VBox/FormGrid/FullscreenCheck
@onready var vfx_option: OptionButton = $Center/MainPanel/Margin/VBox/FormGrid/VisualEffectsOption
@onready var status_label: Label = $Center/MainPanel/Margin/VBox/StatusLabel
@onready var apply_button: CyberButton = $Center/MainPanel/Margin/VBox/ButtonsRow/ApplyButton
@onready var back_button: CyberButton = $Center/MainPanel/Margin/VBox/ButtonsRow/BackButton

var _has_unsaved_changes: bool = false


func _ready() -> void:
	_setup_vfx_options()
	_setup_platform_visibility()
	_load_from_manager()

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vfx_option.item_selected.connect(_on_vfx_selected)
	apply_button.pressed.connect(_on_apply_pressed)
	back_button.pressed.connect(_on_back_pressed)

	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _setup_vfx_options() -> void:
	vfx_option.clear()
	vfx_option.add_item("Low", SettingsManager.VisualQuality.LOW)
	vfx_option.add_item("Medium", SettingsManager.VisualQuality.MEDIUM)
	vfx_option.add_item("High", SettingsManager.VisualQuality.HIGH)


func _setup_platform_visibility() -> void:
	var is_pc: bool = SettingsManager.is_desktop_platform()
	fullscreen_label.visible = is_pc
	fullscreen_check.visible = is_pc


func _load_from_manager() -> void:
	master_slider.set_value_no_signal(roundf(SettingsManager.master_volume * 100.0))
	music_slider.set_value_no_signal(roundf(SettingsManager.music_volume * 100.0))
	sfx_slider.set_value_no_signal(roundf(SettingsManager.sfx_volume * 100.0))
	fullscreen_check.set_pressed_no_signal(SettingsManager.fullscreen)
	vfx_option.select(SettingsManager.visual_effects)
	_update_volume_labels()
	status_label.text = ""
	_has_unsaved_changes = false


func _update_volume_labels() -> void:
	master_value_label.text = "%d%%" % int(master_slider.value)
	music_value_label.text = "%d%%" % int(music_slider.value)
	sfx_value_label.text = "%d%%" % int(sfx_slider.value)


func _on_master_changed(val: float) -> void:
	_update_volume_labels()
	SettingsManager.set_bus_volume_linear(&"Master", val / 100.0)
	_mark_dirty()


func _on_music_changed(val: float) -> void:
	_update_volume_labels()
	SettingsManager.set_bus_volume_linear(&"Music", val / 100.0)
	_mark_dirty()


func _on_sfx_changed(val: float) -> void:
	_update_volume_labels()
	SettingsManager.set_bus_volume_linear(&"SFX", val / 100.0)
	_mark_dirty()


func _on_fullscreen_toggled(_pressed: bool) -> void:
	_mark_dirty()


func _on_vfx_selected(index: int) -> void:
	SettingsManager.visual_effects_changed.emit(index)
	_mark_dirty()


func _mark_dirty() -> void:
	_has_unsaved_changes = true
	status_label.text = ""


func _on_apply_pressed() -> void:
	SettingsManager.master_volume = master_slider.value / 100.0
	SettingsManager.music_volume = music_slider.value / 100.0
	SettingsManager.sfx_volume = sfx_slider.value / 100.0
	SettingsManager.fullscreen = fullscreen_check.button_pressed
	SettingsManager.visual_effects = vfx_option.get_selected_id()

	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()
	_has_unsaved_changes = false
	status_label.text = "SETTINGS SAVED"


func _on_back_pressed() -> void:
	if _has_unsaved_changes:
		SettingsManager.load_settings()
		SettingsManager.apply_all_settings()
	SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
