extends Node2D
class_name SecretLaboratoryLevel

## LEVEL 02 — SECRET LABORATORY boshqaruvchisi.
## 10880px uzunlikdagi 6 hududli laboratoriya: tuzoqlar, harakatlanuvchi platformalar, Keycard va Security Door.

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const SECRET_LAB_SCENE: String = "res://scenes/levels/secret_laboratory.tscn"
const FINAL_BATTLE_SCENE: String = "res://scenes/levels/final_battle.tscn"

const TEX_BIO_TANK: Texture2D = preload("res://assets/props/secret_lab/bio_tank.png")
const TEX_REACTOR_UNIT: Texture2D = preload("res://assets/props/secret_lab/reactor_unit.png")
const TEX_CONSOLE_1: Texture2D = preload("res://assets/props/secret_lab/console_1.png")
const TEX_CABLE_BRIDGE: Texture2D = preload("res://assets/props/secret_lab/cable_bridge.png")
const TEX_TUBE_1: Texture2D = preload("res://assets/props/secret_lab/tube_1.png")
const TEX_TUBE_3: Texture2D = preload("res://assets/props/secret_lab/tube_3.png")
const TEX_TUBE_4: Texture2D = preload("res://assets/props/secret_lab/tube_4.png")
const TEX_SCREEN_1: Texture2D = preload("res://assets/props/secret_lab/screen_1_sheet.png")
const TEX_SCREEN_2: Texture2D = preload("res://assets/props/secret_lab/screen_2_sheet.png")
const TEX_ENTRY_DOOR: Texture2D = preload("res://assets/props/secret_lab/entry_door_sheet.png")

const TILE_SIZE: int = 32
const LEVEL_WIDTH_TILES: int = 340 # 10880 px
const LEVEL_HEIGHT_PX: int = 720

@export var level_bounds: Rect2i = Rect2i(0, 0, LEVEL_WIDTH_TILES * TILE_SIZE, LEVEL_HEIGHT_PX)

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var props_container: Node2D = $PropsContainer
@onready var lights_container: Node2D = $LightsContainer
@onready var player: Player = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var fall_zone: Area2D = $FallZone
@onready var security_gate: SecurityGate = $SecurityGate
@onready var security_door: SecurityDoor = $SecurityDoor
@onready var keycard: KeycardPickup = $KeycardPickup
@onready var checkpoints_container: Node2D = $Checkpoints
@onready var enemies_container: Node2D = $Enemies
@onready var combat_hud: CombatHUD = $CombatHUD

var _active_spawn_position: Vector2
var _level_completed: bool = false
var _score: int = 0
var _kills: int = 0
var _has_keycard: bool = false


func _ready() -> void:
	_build_lab_tiles()
	_populate_lab_props()

	_active_spawn_position = spawn_point.global_position
	if player.camera:
		player.camera.zoom = Vector2(1.2, 1.2)
	player.set_camera_limits(0, 0, level_bounds.end.x, level_bounds.end.y)
	player.respawn_at(_active_spawn_position, true)
	player.player_died.connect(_on_player_died)

	combat_hud.set_level_info("LEVEL 02 — SECRET LAB", "SECTOR 02 — SECRET LABORATORY CLEARED")
	combat_hud.bind_player(player)
	combat_hud.set_score(_score)
	combat_hud.retry_checkpoint_pressed.connect(_on_retry_checkpoint_pressed)
	combat_hud.restart_level_pressed.connect(_on_restart_pressed)
	combat_hud.next_level_pressed.connect(_on_next_level_pressed)
	combat_hud.main_menu_pressed.connect(_on_main_menu_pressed)

	fall_zone.body_entered.connect(_on_fall_zone_body_entered)
	security_gate.gate_reached.connect(_on_security_gate_reached)
	keycard.keycard_collected.connect(_on_keycard_collected)
	security_door.door_locked_attempted.connect(_on_door_locked_attempted)

	for child in checkpoints_container.get_children():
		if child is Checkpoint:
			(child as Checkpoint).checkpoint_activated.connect(_on_checkpoint_activated)

	for enemy in enemies_container.get_children():
		if enemy is EnemyBase:
			(enemy as EnemyBase).enemy_died.connect(_on_enemy_died)

	combat_hud.show_banner("LEVEL 02 — SECRET LABORATORY", Color(0.12, 0.92, 0.43, 1.0), 2.4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart"):
		SceneTransition.change_scene_to_file(SECRET_LAB_SCENE, 0.22)
		get_viewport().set_input_as_handled()


func _build_lab_tiles() -> void:
	# 1. Laboratory Entrance (0..45)
	_fill_lab_floor(0, 45, 18)
	_fill_catwalk(22, 28, 14)

	# 2. Research Sector (46..108) -> Checkpoint 1 at x=105 (3360)
	_fill_lab_floor(48, 72, 18)
	_fill_catwalk(56, 63, 14)
	_fill_lab_floor(76, 108, 18)
	_fill_catwalk(84, 91, 14)

	# 3. Toxic Chambers (109..182) -> Keycard at x=162 (5184), Checkpoint 2 at x=177 (5664)
	_fill_lab_floor(109, 120, 18)
	# Toxic pit 121..136 with bridge & moving platform
	_fill_lab_floor(121, 136, 21) # basin floor under toxic liquid
	_fill_catwalk(126, 131, 16)
	_fill_lab_floor(137, 152, 18)
	# Toxic pit 153..168 + elevated keycard platform
	_fill_lab_floor(153, 168, 21)
	_fill_catwalk(158, 165, 12)
	_fill_lab_floor(169, 182, 18)

	# 4. Security Sector (183..255) -> SecurityDoor at x=192 (6144), Checkpoint 3 at x=250 (8000)
	_fill_lab_floor(183, 214, 18)
	_fill_catwalk(198, 206, 14)
	_fill_lab_floor(218, 255, 18)
	_fill_catwalk(226, 234, 13)

	# 5. Central Reactor (256..312)
	_fill_lab_floor(258, 274, 18)
	_fill_catwalk(278, 286, 14)
	_fill_lab_floor(290, 312, 18)
	_fill_catwalk(296, 304, 13)

	# 6. Exit Gate (313..339)
	_fill_lab_floor(315, 339, 18)


func _fill_lab_floor(x_start: int, x_end: int, top_y: int) -> void:
	for x in range(x_start, x_end + 1):
		var t: Vector2i = Vector2i(1, 0)
		if x == x_start:
			t = Vector2i(0, 0)
		elif x == x_end:
			t = Vector2i(2, 0)
		tile_map.set_cell(Vector2i(x, top_y), 0, t)
		for y in range(top_y + 1, 23):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(1, 1) if (x + y) % 2 == 0 else Vector2i(4, 1))


func _fill_catwalk(x_start: int, x_end: int, y_pos: int) -> void:
	for x in range(x_start, x_end + 1):
		var t: Vector2i = Vector2i(1, 3)
		if x == x_start:
			t = Vector2i(0, 3)
		elif x == x_end:
			t = Vector2i(2, 3)
		tile_map.set_cell(Vector2i(x, y_pos), 0, t)


func _populate_lab_props() -> void:
	# 1. Laboratory Entrance (0..1440 px)
	_add_lab_sprite(TEX_ENTRY_DOOR, Vector2(96, 512), 2.0, false, Rect2(192, 0, 64, 64))
	_add_animated_screen(TEX_SCREEN_1, Vector2(240, 512), 4, 32, 32)
	_add_lab_sprite(TEX_TUBE_1, Vector2(520, 490), 2.0, false)
	_add_lab_sprite(TEX_CONSOLE_1, Vector2(960, 550), 2.0, false)

	# 2. Research Sector (1472..3456 px)
	_add_lab_sprite(TEX_BIO_TANK, Vector2(1620, 500), 2.0, false)
	_add_animated_screen(TEX_SCREEN_2, Vector2(1820, 510), 4, 32, 42)
	_add_lab_sprite(TEX_BIO_TANK, Vector2(2120, 500), 2.0, false)
	_add_lab_sprite(TEX_CONSOLE_1, Vector2(2440, 550), 2.0, false)
	_add_animated_screen(TEX_SCREEN_1, Vector2(3040, 512), 4, 32, 32)

	# 3. Toxic Chambers (3488..5824 px)
	_add_lab_sprite(TEX_TUBE_4, Vector2(3640, 490), 2.0, false)
	_add_lab_sprite(TEX_BIO_TANK, Vector2(4500, 500), 2.0, false)
	_add_lab_sprite(TEX_TUBE_3, Vector2(5480, 512), 2.0, false)

	# 4. Security Sector (5856..8160 px)
	_add_warning_beacon(Vector2(6040, 430), Color(1.0, 0.15, 0.25, 0.9))
	_add_animated_screen(TEX_SCREEN_2, Vector2(6320, 510), 4, 32, 42)
	_add_warning_beacon(Vector2(6880, 430), Color(1.0, 0.15, 0.25, 0.9))
	_add_lab_sprite(TEX_CABLE_BRIDGE, Vector2(7200, 560), 2.0, false)
	_add_warning_beacon(Vector2(7840, 430), Color(1.0, 0.15, 0.25, 0.9))

	# 5. Central Reactor (8192..9984 px)
	_add_lab_sprite(TEX_REACTOR_UNIT, Vector2(8360, 498), 2.2, false)
	_add_warning_beacon(Vector2(8680, 390), Color(0.0, 0.941176, 1.0, 0.9))
	_add_lab_sprite(TEX_REACTOR_UNIT, Vector2(9360, 498), 2.2, false)
	_add_lab_sprite(TEX_TUBE_4, Vector2(9680, 490), 2.0, false)

	# 6. Exit Gate (10016..10880 px)
	_add_animated_screen(TEX_SCREEN_1, Vector2(10240, 512), 4, 32, 32)
	_add_lab_sprite(TEX_CONSOLE_1, Vector2(10400, 550), 2.0, false)


func _add_lab_sprite(tex: Texture2D, pos: Vector2, prop_scale: float, is_light: bool, region: Rect2 = Rect2()) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(prop_scale, prop_scale)
	sprite.position = pos
	if region.size != Vector2.ZERO:
		sprite.region_enabled = true
		sprite.region_rect = region
	if is_light:
		lights_container.add_child(sprite)
	else:
		props_container.add_child(sprite)


func _add_animated_screen(tex: Texture2D, pos: Vector2, frames: int, fw: int, fh: int) -> void:
	var sf := SpriteFrames.new()
	sf.add_animation(&"idle")
	sf.set_animation_loop(&"idle", true)
	sf.set_animation_speed(&"idle", 5.0)
	for i in range(frames):
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame(&"idle", at)
	var anim := AnimatedSprite2D.new()
	anim.sprite_frames = sf
	anim.animation = &"idle"
	anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	anim.scale = Vector2(2.0, 2.0)
	anim.position = pos
	anim.play(&"idle")
	lights_container.add_child(anim)


func _add_warning_beacon(pos: Vector2, light_color: Color) -> void:
	var beacon := ColorRect.new()
	beacon.position = pos
	beacon.size = Vector2(18, 10)
	beacon.color = light_color
	lights_container.add_child(beacon)
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(beacon, "modulate:a", 0.2, 0.55)
	tween.tween_property(beacon, "modulate:a", 1.0, 0.55)


func _on_keycard_collected(_id: String) -> void:
	_has_keycard = true
	security_door.unlock()
	combat_hud.show_banner("KEYCARD ACQUIRED — DOOR UNLOCKED", Color(0.0, 0.941176, 1.0, 1.0), 2.0)


func _on_door_locked_attempted(_id: String) -> void:
	combat_hud.show_banner("KEYCARD REQUIRED", Color(1.0, 0.25, 0.35, 1.0), 1.4)


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
	if _has_keycard:
		security_door.unlock()


func _on_security_gate_reached() -> void:
	if _level_completed or player.health_component.is_dead():
		return
	_level_completed = true
	player.set_controls_enabled(false)
	LevelProgressManager.commit_level_result(2, _score, _kills)
	LevelProgressManager.unlock_level(3)
	combat_hud.show_level_complete(true)


func _on_next_level_pressed() -> void:
	SceneTransition.change_scene_to_file(FINAL_BATTLE_SCENE)


func _on_restart_pressed() -> void:
	SceneTransition.change_scene_to_file(SECRET_LAB_SCENE, 0.25)


func _on_main_menu_pressed() -> void:
	SceneTransition.change_scene_to_file(MAIN_MENU_SCENE, 0.3)
