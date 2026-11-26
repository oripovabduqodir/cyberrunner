extends Control
class_name MobileControls

## Mobil sensorli boshqaruv paneli (Safe Area, Responsive Anchors, Cooldown & Energy indikatorlari).

signal pause_requested

@onready var safe_margin: MarginContainer = $SafeMargin
@onready var joystick: Control = $SafeMargin/BottomRow/LeftArea/VirtualJoystick
@onready var fire_btn: MobileActionButton = $SafeMargin/BottomRow/RightArea/FireButton
@onready var jump_btn: MobileActionButton = $SafeMargin/BottomRow/RightArea/JumpButton
@onready var dash_btn: MobileActionButton = $SafeMargin/BottomRow/RightArea/DashButton
@onready var slash_btn: MobileActionButton = $SafeMargin/BottomRow/RightArea/SlashButton
@onready var reload_btn: MobileActionButton = $SafeMargin/BottomRow/RightArea/ReloadButton
@onready var pause_btn: MobileActionButton = $SafeMargin/TopBar/PauseButton

var _player_ref: Player = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_btn.button_tapped.connect(func() -> void: pause_requested.emit())

	SettingsManager.mobile_settings_changed.connect(_apply_settings)
	get_viewport().size_changed.connect(_update_safe_area)

	_apply_settings()
	_update_safe_area()


func bind_player(player: Player) -> void:
	_player_ref = player


func set_controls_visible(should_show: bool) -> void:
	visible = should_show
	if not should_show:
		MobileInputManager.release_all_actions()


func _process(_delta: float) -> void:
	if not visible or _player_ref == null or not is_instance_valid(_player_ref):
		return

	# Dash energiya va cooldown indikatori
	var can_dash_energy: bool = _player_ref.energy_component.can_spend(_player_ref.dash_energy_cost)
	dash_btn.set_resource_available(can_dash_energy)
	var dash_cd: Timer = _player_ref.dash_cooldown_timer
	dash_btn.set_cooldown_ratio(dash_cd.time_left / maxf(dash_cd.wait_time, 0.01) if not dash_cd.is_stopped() else 0.0)

	# CyberBlade cooldown
	var blade_cd: Timer = _player_ref.cyber_blade.cooldown_timer
	slash_btn.set_cooldown_ratio(blade_cd.time_left / maxf(blade_cd.wait_time, 0.01) if not blade_cd.is_stopped() else 0.0)

	# Reload indikatori
	var pistol: PlasmaPistol = _player_ref.plasma_pistol
	if pistol.is_reloading():
		var rel_t: Timer = pistol.reload_timer
		reload_btn.set_cooldown_ratio(rel_t.time_left / maxf(rel_t.wait_time, 0.01))
		fire_btn.set_resource_available(false)
	else:
		reload_btn.set_cooldown_ratio(0.0)
		fire_btn.set_resource_available(pistol.current_magazine > 0 or pistol.current_reserve > 0)


func _apply_settings() -> void:
	modulate.a = SettingsManager.touch_opacity
	var s: float = SettingsManager.touch_scale
	joystick.scale = Vector2(s, s)
	$SafeMargin/BottomRow/RightArea.scale = Vector2(s, s)
	set_controls_visible(SettingsManager.is_mobile_controls_active())


func _update_safe_area() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	var safe_rect := Rect2i(DisplayServer.get_display_safe_area())
	var screen_size := Vector2(DisplayServer.screen_get_size())
	var left_pad: int = 20
	var right_pad: int = 20
	var top_pad: int = 16
	var bottom_pad: int = 16

	if screen_size.x > 0.0 and screen_size.y > 0.0 and safe_rect.size.x > 0 and safe_rect.size.y > 0:
		var scale_x: float = vp_size.x / screen_size.x
		var scale_y: float = vp_size.y / screen_size.y
		left_pad = maxi(20, int(float(safe_rect.position.x) * scale_x) + 12)
		top_pad = maxi(16, int(float(safe_rect.position.y) * scale_y) + 8)
		right_pad = maxi(20, int((screen_size.x - float(safe_rect.end.x)) * scale_x) + 12)
		bottom_pad = maxi(16, int((screen_size.y - float(safe_rect.end.y)) * scale_y) + 8)

	safe_margin.add_theme_constant_override("margin_left", left_pad)
	safe_margin.add_theme_constant_override("margin_right", right_pad)
	safe_margin.add_theme_constant_override("margin_top", top_pad)
	safe_margin.add_theme_constant_override("margin_bottom", bottom_pad)
