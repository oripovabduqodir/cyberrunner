extends Node2D
class_name NeonCityLevel

## LEVEL 01 — NEON CITY boshqaruvchisi.
## 9216px uzunlikdagi 5 hududli daraja, Checkpoint, Security Gate, HUD va vizual effektlarni boshqaradi.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const NEON_CITY_SCENE: String = "res://scenes/levels/neon_city.tscn"
const PROPS_TEXTURE: Texture2D = preload("res://assets/tilesets/neon_city_props.png")

const TILE_SIZE: int = 32
const LEVEL_WIDTH_TILES: int = 288 # 288 * 32 = 9216 px
const LEVEL_HEIGHT_PX: int = 720

@export var level_bounds: Rect2i = Rect2i(0, 0, LEVEL_WIDTH_TILES * TILE_SIZE, LEVEL_HEIGHT_PX)

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var props_container: Node2D = $PropsContainer
@onready var neon_lights_container: Node2D = $NeonLightsContainer
@onready var player: Player = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var fall_zone: Area2D = $FallZone
@onready var security_gate: SecurityGate = $SecurityGate
@onready var checkpoints_container: Node2D = $Checkpoints
@onready var rain_particles: CPUParticles2D = $AtmosphereLayer/RainParticles
@onready var fog_band_1: ColorRect = $AtmosphereLayer/FogBand1
@onready var fog_band_2: ColorRect = $AtmosphereLayer/FogBand2
@onready var flicker_timer: Timer = $FlickerTimer
@onready var banner_label: Label = $HUD/BannerLabel
@onready var level_complete_overlay: ColorRect = $HUD/LevelCompleteOverlay
@onready var restart_button: CyberButton = $HUD/LevelCompleteOverlay/Center/Panel/Margin/VBox/ButtonsRow/RestartButton
@onready var main_menu_button: CyberButton = $HUD/LevelCompleteOverlay/Center/Panel/Margin/VBox/ButtonsRow/MainMenuButton

var _active_spawn_position: Vector2
var _level_completed: bool = false
var _flicker_enabled: bool = true
var _fog_enabled: bool = true
var _banner_tween: Tween


func _ready() -> void:
	_build_neon_city_tiles()
	_populate_props()

	_active_spawn_position = spawn_point.global_position
	player.set_camera_limits(
		level_bounds.position.x,
		level_bounds.position.y,
		level_bounds.end.x,
		level_bounds.end.y
	)
	player.respawn_at(_active_spawn_position)

	fall_zone.body_entered.connect(_on_fall_zone_body_entered)
	security_gate.gate_reached.connect(_on_security_gate_reached)
	flicker_timer.timeout.connect(_on_flicker_timer_timeout)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	for child in checkpoints_container.get_children():
		if child is Checkpoint:
			(child as Checkpoint).checkpoint_activated.connect(_on_checkpoint_activated)

	if has_node("/root/SettingsManager"):
		SettingsManager.visual_effects_changed.connect(_apply_visual_quality)
		_apply_visual_quality(SettingsManager.visual_effects)

	level_complete_overlay.visible = false
	_show_banner("LEVEL 01 — NEON CITY", Color(0.0, 0.941176, 1.0, 1.0), 2.4)


func _process(delta: float) -> void:
	if not _fog_enabled:
		return

	fog_band_1.position.x += 22.0 * delta
	if fog_band_1.position.x > 1280.0:
		fog_band_1.position.x = -fog_band_1.size.x

	if fog_band_2.visible:
		fog_band_2.position.x -= 16.0 * delta
		if fog_band_2.position.x < -fog_band_2.size.x:
			fog_band_2.position.x = 1280.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("restart"):
		SceneTransition.change_scene_to_file(NEON_CITY_SCENE, 0.22)
		get_viewport().set_input_as_handled()


func _build_neon_city_tiles() -> void:
	# 1. Spawn Area (0..39)
	_fill_street(0, 22, 18)
	_fill_street(26, 39, 18)
	_fill_bridge(30, 35, 14)

	# 2. City Streets (40..105)
	_fill_street(43, 60, 18)
	_place_crate(49, 17)
	_fill_bridge(52, 57, 14)

	_fill_street(64, 83, 18)
	_place_barrier(69, 17)
	_fill_rooftop(72, 78, 14, 1)
	_place_crate(75, 13)

	_fill_street(88, 105, 18) # Checkpoint 1 at x=100 (3200px)
	_fill_bridge(91, 95, 14)

	# 3. Rooftops (106..179)
	_fill_rooftop(109, 121, 16, 6)
	_fill_bridge(124, 129, 13)
	_fill_rooftop(132, 144, 12, 10)
	_place_crate(138, 11)
	_fill_bridge(147, 152, 10)
	_fill_rooftop(155, 166, 13, 9)
	_place_barrier(160, 12)
	_fill_rooftop(170, 180, 15, 7) # Checkpoint 2 at x=174 (5568px)

	# 4. Industrial Zone (181..257)
	_fill_hazard_platform(184, 198, 18, 4)
	_place_crate(190, 17)
	_fill_bridge(193, 199, 14)

	_fill_hazard_platform(204, 217, 16, 6)
	_place_barrier(210, 15)
	_fill_bridge(221, 226, 13)

	_fill_hazard_platform(230, 241, 15, 7)
	_place_crate(235, 14)
	_fill_hazard_platform(246, 257, 18, 4) # Checkpoint 3 at x=252 (8064px)

	# 5. Security Gate Approach (258..287)
	_fill_street(261, 287, 18)
	_fill_bridge(265, 270, 14)
	_place_barrier(263, 17)


func _fill_street(x_start: int, x_end: int, top_y: int) -> void:
	for x in range(x_start, x_end + 1):
		var top_tile: Vector2i = Vector2i(1, 0)
		if x == x_start:
			top_tile = Vector2i(0, 0)
		elif x == x_end:
			top_tile = Vector2i(2, 0)
		tile_map.set_cell(Vector2i(x, top_y), 0, top_tile)

		for y in range(top_y + 1, 23):
			var fill_tile: Vector2i = Vector2i(3, 0) if (x + y) % 2 == 0 else Vector2i(4, 0)
			tile_map.set_cell(Vector2i(x, y), 0, fill_tile)


func _fill_rooftop(x_start: int, x_end: int, top_y: int, depth: int) -> void:
	for x in range(x_start, x_end + 1):
		var top_tile: Vector2i = Vector2i(1, 1)
		if x == x_start:
			top_tile = Vector2i(0, 1)
		elif x == x_end:
			top_tile = Vector2i(2, 1)
		tile_map.set_cell(Vector2i(x, top_y), 0, top_tile)

		for y in range(top_y + 1, top_y + 1 + depth):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(3, 0))


func _fill_bridge(x_start: int, x_end: int, y_pos: int) -> void:
	for x in range(x_start, x_end + 1):
		var tile: Vector2i = Vector2i(1, 2)
		if x == x_start:
			tile = Vector2i(0, 2)
		elif x == x_end:
			tile = Vector2i(2, 2)
		tile_map.set_cell(Vector2i(x, y_pos), 0, tile)


func _fill_hazard_platform(x_start: int, x_end: int, top_y: int, depth: int) -> void:
	for x in range(x_start, x_end + 1):
		tile_map.set_cell(Vector2i(x, top_y), 0, Vector2i(0, 3))
		for y in range(top_y + 1, top_y + 1 + depth):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(4, 0))


func _place_crate(x: int, y: int) -> void:
	tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 3))


func _place_barrier(x: int, y: int) -> void:
	tile_map.set_cell(Vector2i(x, y), 0, Vector2i(2, 3))


func _populate_props() -> void:
	# Neon ko'cha chiroqlari (Spawn & Streets & Gate)
	var lamp_positions: Array[Vector2] = [
		Vector2(220, 512), Vector2(620, 512), Vector2(960, 512),
		Vector2(1480, 512), Vector2(2150, 512), Vector2(2920, 512),
		Vector2(8420, 512), Vector2(8760, 512)
	]
	for pos in lamp_positions:
		_add_prop(Rect2(96, 0, 32, 64), pos, true)

	# Chiqindi qutilari
	for pos in [Vector2(360, 544), Vector2(1660, 544), Vector2(2860, 544)]:
		_add_prop(Rect2(128, 0, 32, 32), pos, false)

	# Neon reklama panellari
	for pos in [Vector2(480, 380), Vector2(1740, 350), Vector2(2520, 380), Vector2(3680, 360), Vector2(5120, 290)]:
		_add_prop(Rect2(160, 0, 64, 32), pos, true)

	# Sanoat quvurlari va ventilyatsiya (Industrial Zone)
	for pos in [Vector2(5980, 512), Vector2(6108, 512), Vector2(6640, 448), Vector2(7420, 416), Vector2(7960, 512)]:
		_add_prop(Rect2(0, 0, 64, 32), pos, false)
	for pos in [Vector2(6040, 470), Vector2(6720, 405), Vector2(7520, 375)]:
		_add_prop(Rect2(64, 0, 32, 32), pos, false)


func _add_prop(region: Rect2, pos: Vector2, is_neon_light: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PROPS_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(2, 2)
	sprite.position = pos
	if is_neon_light:
		neon_lights_container.add_child(sprite)
	else:
		props_container.add_child(sprite)


func _on_checkpoint_activated(new_spawn_pos: Vector2) -> void:
	_active_spawn_position = new_spawn_pos
	_show_banner("CHECKPOINT ACTIVATED", Color(0.0, 0.941176, 1.0, 1.0), 1.8)


func _on_fall_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		(body as Player).respawn_at(_active_spawn_position)


func _on_security_gate_reached() -> void:
	if _level_completed:
		return
	_level_completed = true
	player.set_controls_enabled(false)
	level_complete_overlay.visible = true
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	SceneTransition.change_scene_to_file(NEON_CITY_SCENE, 0.25)


func _on_main_menu_pressed() -> void:
	SceneTransition.change_scene_to_file(MAIN_MENU_SCENE, 0.3)


func _show_banner(message: String, color: Color, hold_time: float) -> void:
	if _banner_tween and _banner_tween.is_running():
		_banner_tween.kill()

	banner_label.text = message
	banner_label.modulate = Color(color.r, color.g, color.b, 0.0)
	banner_label.visible = true

	_banner_tween = create_tween()
	_banner_tween.tween_property(banner_label, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(hold_time)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.4)


func _apply_visual_quality(quality: int) -> void:
	match quality:
		SettingsManager.VisualQuality.LOW:
			_flicker_enabled = false
			_fog_enabled = false
			rain_particles.emitting = false
			rain_particles.visible = false
			fog_band_1.visible = false
			fog_band_2.visible = false
		SettingsManager.VisualQuality.MEDIUM:
			_flicker_enabled = true
			_fog_enabled = true
			rain_particles.visible = true
			rain_particles.amount = 75
			rain_particles.emitting = true
			fog_band_1.visible = true
			fog_band_2.visible = false
		_:
			_flicker_enabled = true
			_fog_enabled = true
			rain_particles.visible = true
			rain_particles.amount = 160
			rain_particles.emitting = true
			fog_band_1.visible = true
			fog_band_2.visible = true


func _on_flicker_timer_timeout() -> void:
	if not _flicker_enabled:
		return
	var children: Array[Node] = neon_lights_container.get_children()
	if children.is_empty():
		return
	var target := children[randi() % children.size()] as CanvasItem
	if target == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(target, "modulate:a", 0.35, 0.06)
	tween.tween_property(target, "modulate:a", 1.0, 0.08)
	tween.tween_property(target, "modulate:a", 0.5, 0.05)
	tween.tween_property(target, "modulate:a", 1.0, 0.09)
