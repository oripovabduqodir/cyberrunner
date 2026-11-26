extends Node

## Global sozlamalar boshqaruvchisi (Autoload: SettingsManager).
## Audio buslar, ekran rejimi, FPS limit, vizual effektlar va mobil boshqaruv sozlamalarini boshqaradi.

signal visual_effects_changed(quality: int)
signal mobile_settings_changed

const SETTINGS_PATH: String = "user://settings.cfg"

enum VisualQuality {
	LOW = 0,
	MEDIUM = 1,
	HIGH = 2,
}

var master_volume: float = 0.85
var music_volume: float = 0.75
var sfx_volume: float = 0.85
var fullscreen: bool = false
var visual_effects: int = VisualQuality.HIGH

# Mobil va unumdorlik sozlamalari
var mobile_controls_preview: bool = false
var auto_aim: bool = true
var touch_opacity: float = 0.8
var touch_scale: float = 1.0
var fps_limit: int = 60 # 30, 60, 0 (Unlimited)


func _ready() -> void:
	_ensure_audio_buses()
	if not is_desktop_platform():
		fps_limit = 60
	load_settings()
	apply_all_settings()


func is_desktop_platform() -> bool:
	return OS.get_name() in ["Windows", "Linux", "macOS"]


func is_mobile_controls_active() -> bool:
	return OS.has_feature("mobile") or (OS.get_name() in ["Android", "iOS"]) or mobile_controls_preview


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index(&"Music") == -1:
		var music_idx: int = AudioServer.bus_count
		AudioServer.add_bus(music_idx)
		AudioServer.set_bus_name(music_idx, &"Music")
		AudioServer.set_bus_send(music_idx, &"Master")

	if AudioServer.get_bus_index(&"SFX") == -1:
		var sfx_idx: int = AudioServer.bus_count
		AudioServer.add_bus(sfx_idx)
		AudioServer.set_bus_name(sfx_idx, &"SFX")
		AudioServer.set_bus_send(sfx_idx, &"Master")


func set_bus_volume_linear(bus_name: StringName, linear_value: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return
	var clamped: float = clampf(linear_value, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_idx, clamped <= 0.001)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(maxf(clamped, 0.0001)))


func apply_audio_settings() -> void:
	set_bus_volume_linear(&"Master", master_volume)
	set_bus_volume_linear(&"Music", music_volume)
	set_bus_volume_linear(&"SFX", sfx_volume)


func apply_display_settings() -> void:
	Engine.max_fps = fps_limit
	if not is_desktop_platform():
		return
	var target_mode: DisplayServer.WindowMode = (
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if DisplayServer.window_get_mode() != target_mode:
		DisplayServer.window_set_mode(target_mode)


func apply_visual_settings() -> void:
	visual_effects_changed.emit(visual_effects)


func apply_mobile_settings() -> void:
	mobile_settings_changed.emit()


func apply_all_settings() -> void:
	apply_audio_settings()
	apply_display_settings()
	apply_visual_settings()
	apply_mobile_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "fps_limit", fps_limit)
	config.set_value("graphics", "visual_effects", visual_effects)
	config.set_value("mobile", "mobile_controls_preview", mobile_controls_preview)
	config.set_value("mobile", "auto_aim", auto_aim)
	config.set_value("mobile", "touch_opacity", touch_opacity)
	config.set_value("mobile", "touch_scale", touch_scale)
	config.save(SETTINGS_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var err: Error = config.load(SETTINGS_PATH)
	if err != OK:
		return

	master_volume = clampf(float(config.get_value("audio", "master_volume", 0.85)), 0.0, 1.0)
	music_volume = clampf(float(config.get_value("audio", "music_volume", 0.75)), 0.0, 1.0)
	sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", 0.85)), 0.0, 1.0)
	fullscreen = bool(config.get_value("display", "fullscreen", false))
	var default_fps: int = 60
	fps_limit = int(config.get_value("display", "fps_limit", default_fps))
	if not (fps_limit in [0, 30, 60]):
		fps_limit = 60
	visual_effects = clampi(int(config.get_value("graphics", "visual_effects", VisualQuality.HIGH)), 0, 2)

	mobile_controls_preview = bool(config.get_value("mobile", "mobile_controls_preview", false))
	auto_aim = bool(config.get_value("mobile", "auto_aim", true))
	touch_opacity = clampf(float(config.get_value("mobile", "touch_opacity", 0.8)), 0.3, 1.0)
	touch_scale = clampf(float(config.get_value("mobile", "touch_scale", 1.0)), 0.75, 1.35)
