extends CanvasLayer
class_name CombatHUD

## Signallar asosida ishlovchi Cyberpunk Combat HUD, Boss Bar, Level Complete, Game Over va Game Completed oynalari.

signal retry_checkpoint_pressed
signal restart_level_pressed
signal next_level_pressed
signal replay_game_pressed
signal main_menu_pressed

@onready var level_label: Label = $TopLeftPanel/Margin/VBox/LevelLabel
@onready var health_bar: ProgressBar = $TopLeftPanel/Margin/VBox/HealthRow/HealthBar
@onready var health_value_label: Label = $TopLeftPanel/Margin/VBox/HealthRow/HealthValue
@onready var energy_bar: ProgressBar = $TopLeftPanel/Margin/VBox/EnergyRow/EnergyBar
@onready var energy_value_label: Label = $TopLeftPanel/Margin/VBox/EnergyRow/EnergyValue

@onready var weapon_name_label: Label = $TopRightPanel/Margin/VBox/WeaponRow/WeaponName
@onready var ammo_label: Label = $TopRightPanel/Margin/VBox/AmmoLabel
@onready var score_label: Label = $TopRightPanel/Margin/VBox/ScoreLabel

@onready var boss_panel: PanelContainer = $BossPanel
@onready var boss_health_bar: ProgressBar = $BossPanel/Margin/VBox/BossHealthBar
@onready var boss_health_value: Label = $BossPanel/Margin/VBox/HeaderRow/BossHealthValue
@onready var boss_phase_label: Label = $BossPanel/Margin/VBox/BossPhaseLabel

@onready var banner_label: Label = $BannerLabel

@onready var level_complete_overlay: ColorRect = $LevelCompleteOverlay
@onready var complete_sub_label: Label = $LevelCompleteOverlay/Center/Panel/Margin/VBox/CompleteSub
@onready var complete_next_btn: CyberButton = $LevelCompleteOverlay/Center/Panel/Margin/VBox/ButtonsRow/NextLevelButton
@onready var complete_restart_btn: CyberButton = $LevelCompleteOverlay/Center/Panel/Margin/VBox/ButtonsRow/RestartButton
@onready var complete_menu_btn: CyberButton = $LevelCompleteOverlay/Center/Panel/Margin/VBox/ButtonsRow/MainMenuButton

@onready var game_over_overlay: ColorRect = $GameOverOverlay
@onready var retry_checkpoint_btn: CyberButton = $GameOverOverlay/Center/Panel/Margin/VBox/ButtonsRow/RetryCheckpointButton
@onready var game_over_restart_btn: CyberButton = $GameOverOverlay/Center/Panel/Margin/VBox/ButtonsRow/RestartButton
@onready var game_over_menu_btn: CyberButton = $GameOverOverlay/Center/Panel/Margin/VBox/ButtonsRow/MainMenuButton

@onready var game_completed_overlay: ColorRect = $GameCompletedOverlay
@onready var total_score_label: Label = $GameCompletedOverlay/Center/Panel/Margin/VBox/TotalScoreLabel
@onready var enemies_defeated_label: Label = $GameCompletedOverlay/Center/Panel/Margin/VBox/EnemiesDefeatedLabel
@onready var replay_game_btn: CyberButton = $GameCompletedOverlay/Center/Panel/Margin/VBox/ButtonsRow/ReplayButton
@onready var completed_menu_btn: CyberButton = $GameCompletedOverlay/Center/Panel/Margin/VBox/ButtonsRow/MainMenuButton

@onready var crosshair: NeonCrosshair = $Crosshair
@onready var mobile_controls: MobileControls = $MobileControls
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var controls_hint: Label = $ControlsHint

var _banner_tween: Tween
var _hp_tween: Tween
var _low_hp_warned: bool = false


func _ready() -> void:
	boss_panel.visible = false
	level_complete_overlay.visible = false
	game_over_overlay.visible = false
	game_completed_overlay.visible = false

	complete_next_btn.pressed.connect(func() -> void: next_level_pressed.emit())
	complete_restart_btn.pressed.connect(func() -> void: restart_level_pressed.emit())
	complete_menu_btn.pressed.connect(func() -> void: main_menu_pressed.emit())

	retry_checkpoint_btn.pressed.connect(func() -> void: retry_checkpoint_pressed.emit())
	game_over_restart_btn.pressed.connect(func() -> void: restart_level_pressed.emit())
	game_over_menu_btn.pressed.connect(func() -> void: main_menu_pressed.emit())

	replay_game_btn.pressed.connect(func() -> void: replay_game_pressed.emit())
	completed_menu_btn.pressed.connect(func() -> void: main_menu_pressed.emit())

	mobile_controls.pause_requested.connect(_open_pause_menu)
	pause_menu.resumed.connect(_on_pause_resumed)
	pause_menu.restart_requested.connect(func() -> void: restart_level_pressed.emit())
	pause_menu.main_menu_requested.connect(func() -> void: main_menu_pressed.emit())

	SettingsManager.mobile_settings_changed.connect(_sync_input_mode_ui)
	_sync_input_mode_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if not level_complete_overlay.visible and not game_over_overlay.visible and not game_completed_overlay.visible:
			if pause_menu.visible:
				pause_menu.close_pause()
			else:
				_open_pause_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if level_complete_overlay.visible or game_over_overlay.visible or game_completed_overlay.visible:
			return
		if pause_menu.visible:
			pause_menu.close_pause()
		else:
			_open_pause_menu()
		get_viewport().set_input_as_handled()


func set_level_info(title_text: String, complete_sub_text: String) -> void:
	level_label.text = title_text
	complete_sub_label.text = complete_sub_text


func bind_player(player: Player) -> void:
	player.health_component.health_changed.connect(_on_health_changed)
	player.energy_component.energy_changed.connect(_on_energy_changed)
	player.plasma_pistol.ammo_changed.connect(_on_ammo_changed)
	player.plasma_pistol.reload_started.connect(_on_reload_started)
	player.plasma_pistol.reload_finished.connect(_on_reload_finished)
	player.plasma_pistol.fired.connect(func() -> void: crosshair.pulse())
	mobile_controls.bind_player(player)

	weapon_name_label.text = player.plasma_pistol.weapon_name
	_on_health_changed(player.health_component.current_health, player.health_component.max_health)
	_on_energy_changed(player.energy_component.current_energy, player.energy_component.max_energy)
	_on_ammo_changed(
		player.plasma_pistol.current_magazine,
		player.plasma_pistol.magazine_capacity,
		player.plasma_pistol.current_reserve
	)


func bind_boss(boss: OmegaXBoss) -> void:
	boss.boss_health_changed.connect(_on_boss_health_changed)
	boss.boss_phase_changed.connect(_on_boss_phase_changed)


func set_boss_hud_visible(is_visible: bool) -> void:
	boss_panel.visible = is_visible


func set_score(score: int) -> void:
	score_label.text = "SCORE: %d" % score


func show_banner(message: String, color: Color, hold_time: float = 2.0) -> void:
	if _banner_tween and _banner_tween.is_running():
		_banner_tween.kill()

	banner_label.text = message
	banner_label.modulate = Color(color.r, color.g, color.b, 0.0)
	banner_label.visible = true

	_banner_tween = create_tween()
	_banner_tween.tween_property(banner_label, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(hold_time)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.4)


func show_level_complete(has_next_level: bool = true) -> void:
	crosshair.set_active(false)
	mobile_controls.set_controls_visible(false)
	complete_next_btn.visible = has_next_level
	level_complete_overlay.visible = true
	if has_next_level:
		complete_next_btn.grab_focus()
	else:
		complete_restart_btn.grab_focus()


func show_game_over() -> void:
	crosshair.set_active(false)
	mobile_controls.set_controls_visible(false)
	game_over_overlay.visible = true
	retry_checkpoint_btn.grab_focus()


func hide_game_over() -> void:
	game_over_overlay.visible = false
	_sync_input_mode_ui()


func show_game_completed(total_score: int, enemies_defeated: int) -> void:
	crosshair.set_active(false)
	mobile_controls.set_controls_visible(false)
	boss_panel.visible = false
	total_score_label.text = "TOTAL SCORE: %d" % total_score
	enemies_defeated_label.text = "Enemies Defeated: %d" % enemies_defeated
	game_completed_overlay.visible = true
	replay_game_btn.grab_focus()


func _open_pause_menu() -> void:
	crosshair.set_active(false)
	mobile_controls.set_controls_visible(false)
	pause_menu.open_pause()


func _on_pause_resumed() -> void:
	_sync_input_mode_ui()


func _sync_input_mode_ui() -> void:
	var mobile_active: bool = SettingsManager.is_mobile_controls_active()
	var any_overlay: bool = level_complete_overlay.visible or game_over_overlay.visible or game_completed_overlay.visible or pause_menu.visible
	mobile_controls.set_controls_visible(mobile_active and not any_overlay)
	crosshair.set_active(not mobile_active and not any_overlay)
	controls_hint.visible = not mobile_active


func _on_health_changed(current_hp: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	if _hp_tween and _hp_tween.is_running():
		_hp_tween.kill()
	_hp_tween = create_tween()
	_hp_tween.tween_property(health_bar, "value", float(current_hp), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	health_value_label.text = "%d / %d" % [current_hp, max_hp]

	var is_low: bool = current_hp > 0 and max_hp > 0 and (float(current_hp) / float(max_hp)) < 0.25
	health_value_label.add_theme_color_override("font_color", Color(1.0, 0.188, 0.31, 1.0) if is_low else Color(0.88, 0.98, 1.0, 1.0))
	if is_low and not _low_hp_warned:
		_low_hp_warned = true
		show_banner("WARNING: LOW HEALTH", Color(1.0, 0.188, 0.31, 1.0), 1.1)
	elif not is_low:
		_low_hp_warned = false


func _on_energy_changed(current_en: float, max_en: float) -> void:
	energy_bar.max_value = max_en
	energy_bar.value = current_en
	energy_value_label.text = "%d" % int(roundf(current_en))


func _on_ammo_changed(mag: int, max_mag: int, reserve: int) -> void:
	if mag == 0:
		ammo_label.text = "RELOAD!  0 / %d  (%d)" % [max_mag, reserve]
		ammo_label.add_theme_color_override("font_color", Color(1.0, 0.188, 0.31, 1.0))
	else:
		ammo_label.text = "AMMO: %d / %d  (%d)" % [mag, max_mag, reserve]
		ammo_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))


func _on_reload_started() -> void:
	ammo_label.text = "RELOADING..."
	ammo_label.add_theme_color_override("font_color", Color(0.0, 0.898, 1.0, 1.0))


func _on_reload_finished() -> void:
	pass


func _on_boss_health_changed(current_hp: int, max_hp: int) -> void:
	boss_health_bar.max_value = max_hp
	boss_health_bar.value = current_hp
	boss_health_value.text = "%d / %d" % [current_hp, max_hp]


func _on_boss_phase_changed(phase_number: int, phase_title: String) -> void:
	boss_phase_label.text = phase_title
	var phase_color: Color = Color(0.0, 0.898, 1.0, 1.0)
	if phase_number == 2:
		phase_color = Color(1.0, 0.0, 0.498, 1.0)
	elif phase_number >= 3:
		phase_color = Color(1.0, 0.188, 0.31, 1.0)
	boss_phase_label.add_theme_color_override("font_color", phase_color)
	show_banner(phase_title, phase_color, 1.6)
