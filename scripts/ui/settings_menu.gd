extends Control
class_name SettingsMenu

## O'yin sozlamalari oynasi: Audio, Fullscreen (PC), FPS Limit, Visual Effects va Mobil boshqaruv.

signal closed

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"

@export var embedded_mode: bool = false

@onready var cyber_background: CyberBackground = $CyberBackground
@onready var master_slider: HSlider = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/MasterSliderRow/MasterSlider
@onready var master_value_label: Label = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/MasterSliderRow/MasterValue
@onready var music_slider: HSlider = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/MusicSliderRow/MusicSlider
@onready var music_value_label: Label = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/MusicSliderRow/MusicValue
@onready var sfx_slider: HSlider = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/SfxSliderRow/SfxSlider
@onready var sfx_value_label: Label = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/SfxSliderRow/SfxValue
@onready var fullscreen_label: Label = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/FullscreenLabel
@onready var fullscreen_check: CheckBox = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/FullscreenCheck
@onready var fps_option: OptionButton = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/FpsOption
@onready var vfx_option: OptionButton = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/VisualEffectsOption
@onready var preview_label: Label = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/PreviewLabel
@onready var preview_check: CheckBox = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/PreviewCheck
@onready var auto_aim_check: CheckBox = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/AutoAimCheck
@onready var touch_opacity_slider: HSlider = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/OpacityRow/OpacitySlider
@onready var touch_opacity_value: Label = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/OpacityRow/OpacityValue
@onready var touch_size_slider: HSlider = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/SizeRow/SizeSlider
@onready var touch_size_value: Label = $Center/MainPanel/Margin/VBox/Scroll/FormGrid/SizeRow/SizeValue

@onready var status_label: Label = $Center/MainPanel/Margin/VBox/StatusLabel
@onready var apply_button: CyberButton = $Center/MainPanel/Margin/VBox/ButtonsRow/ApplyButton
@onready var reset_button: CyberButton = $Center/MainPanel/Margin/VBox/ButtonsRow/ResetButton
@onready var back_button: CyberButton = $Center/MainPanel/Margin/VBox/ButtonsRow/BackButton

var _has_unsaved_changes: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if embedded_mode:
		cyber_background.visible = false

	_setup_options()
	_setup_platform_visibility()
	_load_from_manager()

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(func(_p: bool) -> void: _mark_dirty())
	fps_option.item_selected.connect(func(_i: int) -> void: _mark_dirty())
	vfx_option.item_selected.connect(_on_vfx_selected)
	preview_check.toggled.connect(func(_p: bool) -> void: _mark_dirty())
	auto_aim_check.toggled.connect(func(_p: bool) -> void: _mark_dirty())
	touch_opacity_slider.value_changed.connect(_on_touch_opacity_changed)
	touch_size_slider.value_changed.connect(_on_touch_size_changed)

	apply_button.pressed.connect(_on_apply_pressed)
	reset_button.pressed.connect(_on_reset_defaults_pressed)
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _setup_options() -> void:
	vfx_option.clear()
	vfx_option.add_item("Low", SettingsManager.VisualQuality.LOW)
	vfx_option.add_item("Medium", SettingsManager.VisualQuality.MEDIUM)
	vfx_option.add_item("High", SettingsManager.VisualQuality.HIGH)

	fps_option.clear()
	fps_option.add_item("30 FPS", 30)
	fps_option.add_item("60 FPS", 60)
	fps_option.add_item("Unlimited", 0)


func _setup_platform_visibility() -> void:
	var is_pc: bool = SettingsManager.is_desktop_platform()
	fullscreen_label.visible = is_pc
	fullscreen_check.visible = is_pc
	preview_label.visible = is_pc
	preview_check.visible = is_pc


func _load_from_manager() -> void:
	master_slider.set_value_no_signal(roundf(SettingsManager.master_volume * 100.0))
	music_slider.set_value_no_signal(roundf(SettingsManager.music_volume * 100.0))
	sfx_slider.set_value_no_signal(roundf(SettingsManager.sfx_volume * 100.0))
	fullscreen_check.set_pressed_no_signal(SettingsManager.fullscreen)
	vfx_option.select(SettingsManager.visual_effects)

	var fps_idx: int = fps_option.get_item_index(SettingsManager.fps_limit)
	fps_option.select(fps_idx if fps_idx != -1 else 1)

	preview_check.set_pressed_no_signal(SettingsManager.mobile_controls_preview)
	auto_aim_check.set_pressed_no_signal(SettingsManager.auto_aim)
	touch_opacity_slider.set_value_no_signal(roundf(SettingsManager.touch_opacity * 100.0))
	touch_size_slider.set_value_no_signal(roundf(SettingsManager.touch_scale * 100.0))

	_update_labels()
	status_label.text = ""
	_has_unsaved_changes = false


func _update_labels() -> void:
	master_value_label.text = "%d%%" % int(master_slider.value)
	music_value_label.text = "%d%%" % int(music_slider.value)
	sfx_value_label.text = "%d%%" % int(sfx_slider.value)
	touch_opacity_value.text = "%d%%" % int(touch_opacity_slider.value)
	touch_size_value.text = "%d%%" % int(touch_size_slider.value)


func _on_master_changed(val: float) -> void:
	_update_labels()
	SettingsManager.set_bus_volume_linear(&"Master", val / 100.0)
	_mark_dirty()


func _on_music_changed(val: float) -> void:
	_update_labels()
	SettingsManager.set_bus_volume_linear(&"Music", val / 100.0)
	_mark_dirty()


func _on_sfx_changed(val: float) -> void:
	_update_labels()
	SettingsManager.set_bus_volume_linear(&"SFX", val / 100.0)
	_mark_dirty()


func _on_vfx_selected(index: int) -> void:
	SettingsManager.visual_effects_changed.emit(index)
	_mark_dirty()


func _on_touch_opacity_changed(_val: float) -> void:
	_update_labels()
	_mark_dirty()


func _on_touch_size_changed(_val: float) -> void:
	_update_labels()
	_mark_dirty()


func _mark_dirty() -> void:
	_has_unsaved_changes = true
	status_label.text = ""


func _on_apply_pressed() -> void:
	SettingsManager.master_volume = master_slider.value / 100.0
	SettingsManager.music_volume = music_slider.value / 100.0
	SettingsManager.sfx_volume = sfx_slider.value / 100.0
	SettingsManager.fullscreen = fullscreen_check.button_pressed
	SettingsManager.fps_limit = fps_option.get_selected_id()
	SettingsManager.visual_effects = vfx_option.get_selected_id()
	SettingsManager.mobile_controls_preview = preview_check.button_pressed
	SettingsManager.auto_aim = auto_aim_check.button_pressed
	SettingsManager.touch_opacity = touch_opacity_slider.value / 100.0
	SettingsManager.touch_scale = touch_size_slider.value / 100.0

	SettingsManager.apply_all_settings()
	SettingsManager.save_settings()
	_has_unsaved_changes = false
	status_label.text = "SETTINGS SAVED"


func _on_reset_defaults_pressed() -> void:
	master_slider.set_value_no_signal(85.0)
	music_slider.set_value_no_signal(75.0)
	sfx_slider.set_value_no_signal(90.0)
	fullscreen_check.set_pressed_no_signal(false)
	var fps_idx: int = fps_option.get_item_index(60)
	fps_option.select(fps_idx if fps_idx != -1 else 1)
	vfx_option.select(SettingsManager.VisualQuality.HIGH)
	preview_check.set_pressed_no_signal(false)
	auto_aim_check.set_pressed_no_signal(true)
	touch_opacity_slider.set_value_no_signal(72.0)
	touch_size_slider.set_value_no_signal(100.0)
	_update_labels()
	_on_apply_pressed()
	status_label.text = "DEFAULTS RESTORED"


func _on_back_pressed() -> void:
	if _has_unsaved_changes:
		SettingsManager.load_settings()
		SettingsManager.apply_all_settings()

	if embedded_mode:
		closed.emit()
	else:
		SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
