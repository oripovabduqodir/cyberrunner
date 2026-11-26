extends Node2D
class_name NeonCityLevel

## LEVEL 01 — NEON CITY boshqaruvchisi.
## 9216px uzunlikdagi 5 hududli daraja, dushmanlar, pickuplar, Checkpoint, Security Gate va CombatHUD ni boshqaradi.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const NEON_CITY_SCENE: String = "res://scenes/levels/neon_city.tscn"
const SECRET_LAB_SCENE: String = "res://scenes/levels/secret_laboratory.tscn"

const TEX_HOTEL_SIGN: Texture2D = preload("res://assets/props/neon_city/hotel-sign.png")
const TEX_BANNER_BIG: Texture2D = preload("res://assets/props/neon_city/banner-big-1.png")
const TEX_BANNER_NEON: Texture2D = preload("res://assets/props/neon_city/banner-neon-1.png")
const TEX_BANNER_COKE: Texture2D = preload("res://assets/props/neon_city/banner-coke-1.png")
const TEX_BANNER_OPEN: Texture2D = preload("res://assets/props/neon_city/banner-open.png")
const TEX_BANNER_ARROW: Texture2D = preload("res://assets/props/neon_city/banner-arrow.png")
const TEX_BANNER_SMALL: Texture2D = preload("res://assets/props/neon_city/banner-small.png")
const TEX_ANTENNA: Texture2D = preload("res://assets/props/neon_city/antenna.png")
const TEX_CTRL_1: Texture2D = preload("res://assets/props/neon_city/control-box-1.png")
const TEX_CTRL_2: Texture2D = preload("res://assets/props/neon_city/control-box-2.png")
const TEX_CTRL_3: Texture2D = preload("res://assets/props/neon_city/control-box-3.png")
const TEX_MONITOR: Texture2D = preload("res://assets/props/neon_city/monitor-face-1.png")
const TEX_BARREL_1: Texture2D = preload("res://assets/props/neon_city/Barrel1.png")
const TEX_BARREL_2: Texture2D = preload("res://assets/props/neon_city/Barrel2.png")
const TEX_BOARD_1: Texture2D = preload("res://assets/props/neon_city/Board1.png")
const TEX_FLAG: Texture2D = preload("res://assets/props/neon_city/Flag.png")
const TEX_V_POLICE: Texture2D = preload("res://assets/props/neon_city/v-police.png")
const TEX_V_RED: Texture2D = preload("res://assets/props/neon_city/v-red.png")

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
@onready var enemies_container: Node2D = $Enemies
@onready var rain_particles: CPUParticles2D = $AtmosphereLayer/RainParticles
@onready var fog_band_1: ColorRect = $AtmosphereLayer/FogBand1
@onready var fog_band_2: ColorRect = $AtmosphereLayer/FogBand2
@onready var flicker_timer: Timer = $FlickerTimer
@onready var combat_hud: CombatHUD = $CombatHUD

var _active_spawn_position: Vector2
var _level_completed: bool = false
var _flicker_enabled: bool = true
var _fog_enabled: bool = true
var _score: int = 0
var _kills: int = 0


func _ready() -> void:
	_build_neon_city_tiles()
	_populate_props()

	_active_spawn_position = spawn_point.global_position
	if player.camera:
		player.camera.zoom = Vector2(1.2, 1.2)
	player.set_camera_limits(
		level_bounds.position.x,
		level_bounds.position.y,
		level_bounds.end.x,
		level_bounds.end.y
	)
	player.respawn_at(_active_spawn_position, true)
	player.player_died.connect(_on_player_died)

	combat_hud.bind_player(player)
	combat_hud.set_score(_score)
	combat_hud.retry_checkpoint_pressed.connect(_on_retry_checkpoint_pressed)
	combat_hud.restart_level_pressed.connect(_on_restart_pressed)
	combat_hud.next_level_pressed.connect(_on_next_level_pressed)
	combat_hud.main_menu_pressed.connect(_on_main_menu_pressed)

	fall_zone.body_entered.connect(_on_fall_zone_body_entered)
	security_gate.gate_reached.connect(_on_security_gate_reached)
	flicker_timer.timeout.connect(_on_flicker_timer_timeout)

	for child in checkpoints_container.get_children():
		if child is Checkpoint:
			(child as Checkpoint).checkpoint_activated.connect(_on_checkpoint_activated)

	for enemy in enemies_container.get_children():
		if enemy is EnemyBase:
			(enemy as EnemyBase).enemy_died.connect(_on_enemy_died)

	if has_node("/root/SettingsManager"):
		SettingsManager.visual_effects_changed.connect(_apply_visual_quality)
		_apply_visual_quality(SettingsManager.visual_effects)

	combat_hud.show_banner("LEVEL 01 — NEON CITY", Color(0.0, 0.941176, 1.0, 1.0), 2.4)


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
		var src_id: int = 1
		if x == x_start:
			src_id = 0
		elif x == x_end:
			src_id = 2
		tile_map.set_cell(Vector2i(x, top_y), src_id, Vector2i.ZERO)

		for y in range(top_y + 1, 23):
			var fill_src: int = 3 if (x + y) % 2 == 0 else 4
			tile_map.set_cell(Vector2i(x, y), fill_src, Vector2i.ZERO)


func _fill_rooftop(x_start: int, x_end: int, top_y: int, depth: int) -> void:
	for x in range(x_start, x_end + 1):
		var src_id: int = 6
		if x == x_start:
			src_id = 5
		elif x == x_end:
			src_id = 7
		tile_map.set_cell(Vector2i(x, top_y), src_id, Vector2i.ZERO)

		for y in range(top_y + 1, top_y + 1 + depth):
			tile_map.set_cell(Vector2i(x, y), 3, Vector2i.ZERO)


func _fill_bridge(x_start: int, x_end: int, y_pos: int) -> void:
	for x in range(x_start, x_end + 1):
		var src_id: int = 9 if x > x_start else 8
		tile_map.set_cell(Vector2i(x, y_pos), src_id, Vector2i.ZERO)


func _fill_hazard_platform(x_start: int, x_end: int, top_y: int, depth: int) -> void:
	for x in range(x_start, x_end + 1):
		var src_id: int = 10 if x % 2 == 0 else 11
		tile_map.set_cell(Vector2i(x, top_y), src_id, Vector2i.ZERO)
		for y in range(top_y + 1, top_y + 1 + depth):
			tile_map.set_cell(Vector2i(x, y), 12, Vector2i.ZERO)


func _place_crate(x: int, y: int) -> void:
	tile_map.set_cell(Vector2i(x, y), 13, Vector2i.ZERO)


func _place_barrier(x: int, y: int) -> void:
	tile_map.set_cell(Vector2i(x, y), 14, Vector2i.ZERO)


func _populate_props() -> void:
	# 1. Spawn Area (0..1248 px)
	_add_prop_tex(TEX_HOTEL_SIGN, Vector2(210, 486), 2.0, true)
	_add_prop_tex(TEX_MONITOR, Vector2(360, 548), 2.0, true)
	_add_prop_tex(TEX_CTRL_1, Vector2(440, 546), 2.0, false)
	_add_prop_tex(TEX_BANNER_OPEN, Vector2(620, 496), 2.0, true)
	_add_prop_tex(TEX_BANNER_ARROW, Vector2(960, 514), 2.0, true)

	# 2. City Streets (1248..3360 px)
	_add_prop_tex(TEX_BANNER_BIG, Vector2(1520, 420), 1.8, true)
	_add_prop_tex(TEX_CTRL_2, Vector2(1660, 549), 2.0, false)
	_add_prop_tex(TEX_BANNER_NEON, Vector2(2140, 470), 2.0, true)
	_add_prop_tex(TEX_BANNER_COKE, Vector2(2500, 440), 1.8, true)
	_add_prop_tex(TEX_CTRL_3, Vector2(2860, 546), 2.0, false)
	_add_prop_tex(TEX_BANNER_SMALL, Vector2(2980, 514), 2.0, true)

	# 3. Rooftops (3392..5760 px)
	_add_prop_tex(TEX_ANTENNA, Vector2(3540, 420), 2.0, false)
	_add_prop_tex(TEX_CTRL_1, Vector2(3820, 482), 2.0, false)
	_add_prop_tex(TEX_BANNER_NEON, Vector2(4280, 310), 1.8, true)
	_add_prop_tex(TEX_ANTENNA, Vector2(4480, 290), 2.0, false)
	_add_prop_tex(TEX_CTRL_2, Vector2(5060, 389), 2.0, false)
	_add_prop_tex(TEX_ANTENNA, Vector2(5480, 386), 2.0, false)

	# 4. Industrial Zone (5792..8224 px)
	_add_prop_tex(TEX_BARREL_1, Vector2(5960, 550), 2.0, false)
	_add_prop_tex(TEX_BOARD_1, Vector2(6040, 544), 2.0, false)
	_add_prop_tex(TEX_BARREL_2, Vector2(6640, 486), 2.0, false)
	_add_prop_tex(TEX_FLAG, Vector2(6860, 448), 2.0, false)
	_add_prop_tex(TEX_CTRL_3, Vector2(7420, 450), 2.0, false)
	_add_prop_tex(TEX_BARREL_1, Vector2(7960, 550), 2.0, false)

	# 5. Security Gate Approach (8256..9216 px)
	_add_prop_tex(TEX_BOARD_1, Vector2(8420, 544), 2.0, false)
	_add_prop_tex(TEX_MONITOR, Vector2(8560, 548), 2.0, true)
	_add_prop_tex(TEX_BANNER_ARROW, Vector2(8740, 514), 2.0, true)
	_add_prop_tex(TEX_CTRL_1, Vector2(9040, 546), 2.0, false)

	# Uzoqdagi uchuvchi transport vositalari (fon chuqurligi)
	_spawn_flying_vehicle(TEX_V_POLICE, Vector2(1400, 175), 32.0)
	_spawn_flying_vehicle(TEX_V_RED, Vector2(4200, 130), -26.0)

	# Nam ko'cha yuzalaridagi neon akslar
	var reflections: Array[Array] = [
		[Vector2(180, 578), 90.0, Color(0.0, 0.941176, 1.0, 0.25)],
		[Vector2(580, 578), 110.0, Color(1.0, 0.0, 0.498039, 0.22)],
		[Vector2(1440, 578), 100.0, Color(0.0, 0.941176, 1.0, 0.25)],
		[Vector2(2110, 578), 120.0, Color(0.541176, 0.168627, 0.886275, 0.24)],
		[Vector2(8380, 578), 110.0, Color(0.0, 0.941176, 1.0, 0.25)],
	]
	for r in reflections:
		var strip := ColorRect.new()
		strip.position = r[0]
		strip.size = Vector2(float(r[1]), 4.0)
		strip.color = r[2]
		neon_lights_container.add_child(strip)


func _add_prop_tex(tex: Texture2D, pos: Vector2, prop_scale: float, is_neon_light: bool) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(prop_scale, prop_scale)
	sprite.position = pos
	if is_neon_light:
		neon_lights_container.add_child(sprite)
	else:
		props_container.add_child(sprite)


func _spawn_flying_vehicle(tex: Texture2D, start_pos: Vector2, speed_x: float) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(1.25, 1.25)
	sprite.position = start_pos
	sprite.z_index = -3
	sprite.modulate = Color(0.65, 0.72, 0.9, 0.55)
	sprite.flip_h = speed_x < 0.0
	props_container.add_child(sprite)

	var tween: Tween = create_tween().set_loops()
	var end_x: float = start_pos.x + (1100.0 if speed_x > 0.0 else -1100.0)
	var duration: float = absf(end_x - start_pos.x) / maxf(10.0, absf(speed_x))
	tween.tween_property(sprite, "position:x", end_x, duration)
	tween.tween_property(sprite, "position:x", start_pos.x, 0.01)


func _on_checkpoint_activated(new_spawn_pos: Vector2) -> void:
	_active_spawn_position = new_spawn_pos
	combat_hud.show_banner("CHECKPOINT ACTIVATED", Color(0.0, 0.941176, 1.0, 1.0), 1.8)


func _on_enemy_died(_enemy: EnemyBase, score_reward: int) -> void:
	_score += score_reward
	_kills += 1
	combat_hud.set_score(_score)


func _on_fall_zone_body_entered(body: Node2D) -> void:
	if body is Player:
		var p := body as Player
		if p.health_component.is_dead():
			return
		p.take_damage(20, Vector2.UP)
		if not p.health_component.is_dead():
			p.respawn_at(_active_spawn_position, false)


func _on_player_died() -> void:
	combat_hud.show_game_over()


func _on_retry_checkpoint_pressed() -> void:
	combat_hud.hide_game_over()
	player.respawn_at(_active_spawn_position, true)


func _on_security_gate_reached() -> void:
	if _level_completed or player.health_component.is_dead():
		return
	_level_completed = true
	player.set_controls_enabled(false)
	LevelProgressManager.commit_level_result(1, _score, _kills)
	LevelProgressManager.unlock_level(2)
	combat_hud.show_level_complete(true)


func _on_next_level_pressed() -> void:
	SceneTransition.change_scene_to_file(SECRET_LAB_SCENE)


func _on_restart_pressed() -> void:
	SceneTransition.change_scene_to_file(NEON_CITY_SCENE, 0.25)


func _on_main_menu_pressed() -> void:
	SceneTransition.change_scene_to_file(MAIN_MENU_SCENE, 0.3)


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
