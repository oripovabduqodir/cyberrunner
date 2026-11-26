extends Node2D
class_name FinalBattleLevel

## LEVEL 03 — FINAL BATTLE boshqaruvchisi.
## Central Tower Entrance, Defense Corridor, AI Control Center va Boss Arena (OMEGA-X).

const MAIN_MENU_SCENE: String = "res://scenes/ui/main_menu.tscn"
const NEON_CITY_SCENE: String = "res://scenes/levels/neon_city.tscn"
const FINAL_BATTLE_SCENE: String = "res://scenes/levels/final_battle.tscn"
const DRONE_SCENE: PackedScene = preload("res://scenes/enemies/attack_drone.tscn")

const TEX_REACTOR: Texture2D = preload("res://assets/props/secret_lab/reactor_unit.png")
const TEX_CONSOLE: Texture2D = preload("res://assets/props/secret_lab/console_1.png")
const TEX_CABLE: Texture2D = preload("res://assets/props/secret_lab/cable_bridge.png")
const TEX_TUBE: Texture2D = preload("res://assets/props/secret_lab/tube_4.png")
const TEX_SCREEN_1: Texture2D = preload("res://assets/props/secret_lab/screen_1_sheet.png")
const TEX_SCREEN_2: Texture2D = preload("res://assets/props/secret_lab/screen_2_sheet.png")
const TEX_ENTRY: Texture2D = preload("res://assets/props/secret_lab/entry_door_sheet.png")

const TILE_SIZE: int = 32
const LEVEL_WIDTH_TILES: int = 155 # 4960 px
const LEVEL_HEIGHT_PX: int = 720

@export var level_bounds: Rect2i = Rect2i(0, 0, LEVEL_WIDTH_TILES * TILE_SIZE, LEVEL_HEIGHT_PX)

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var props_container: Node2D = $PropsContainer
@onready var lights_container: Node2D = $LightsContainer
@onready var player: Player = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var fall_zone: Area2D = $FallZone
@onready var checkpoints_container: Node2D = $Checkpoints
@onready var enemies_container: Node2D = $Enemies
@onready var boss: OmegaXBoss = $OmegaX
@onready var boss_trigger: Area2D = $BossArenaTrigger
@onready var arena_lock_door: StaticBody2D = $ArenaLockDoor
@onready var arena_lock_shape: CollisionShape2D = $ArenaLockDoor/CollisionShape2D
@onready var combat_hud: CombatHUD = $CombatHUD

var _active_spawn_position: Vector2
var _score: int = 0
var _kills: int = 0
var _boss_started: bool = false
var _boss_defeated_handled: bool = false
var _summoned_drones: Array[AttackDrone] = []


func _ready() -> void:
	_build_tower_tiles()
	_populate_tower_props()
	arena_lock_door.visible = false
	arena_lock_shape.disabled = true

	_active_spawn_position = spawn_point.global_position
	if player.camera:
		player.camera.zoom = Vector2(1.15, 1.15)
	player.set_camera_limits(0, 0, level_bounds.end.x, level_bounds.end.y)
	player.respawn_at(_active_spawn_position, true)
	player.player_died.connect(_on_player_died)

	combat_hud.set_level_info("LEVEL 03 — FINAL BATTLE", "CENTRAL AI CORE")
	combat_hud.bind_player(player)
	combat_hud.bind_boss(boss)
	combat_hud.set_score(_score)
	combat_hud.retry_checkpoint_pressed.connect(_on_retry_checkpoint_pressed)
	combat_hud.restart_level_pressed.connect(_on_restart_pressed)
	combat_hud.replay_game_pressed.connect(_on_replay_game_pressed)
	combat_hud.main_menu_pressed.connect(_on_main_menu_pressed)

	fall_zone.body_entered.connect(_on_fall_zone_body_entered)
	boss_trigger.body_entered.connect(_on_boss_trigger_entered)
	boss.boss_defeated.connect(_on_boss_defeated)
	boss.summon_drone_requested.connect(_on_boss_summon_drone)

	for child in checkpoints_container.get_children():
		if child is Checkpoint:
			(child as Checkpoint).checkpoint_activated.connect(_on_checkpoint_activated)

	for enemy in enemies_container.get_children():
		if enemy is EnemyBase:
			(enemy as EnemyBase).enemy_died.connect(_on_enemy_died)

	combat_hud.show_banner("LEVEL 03 — FINAL BATTLE", Color(1.0, 0.0, 0.498039, 1.0), 2.4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		SceneTransition.change_scene_to_file(MAIN_MENU_SCENE)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart"):
		SceneTransition.change_scene_to_file(FINAL_BATTLE_SCENE, 0.22)
		get_viewport().set_input_as_handled()


func _build_tower_tiles() -> void:
	# 1. Central Tower Entrance (0..32)
	_fill_tower_floor(0, 32, 18)

	# 2. Defense Corridor (33..74)
	_fill_tower_floor(35, 52, 18)
	_fill_catwalk(42, 48, 14)
	_fill_tower_floor(56, 74, 18)

	# 3. AI Control Center & Pre-Boss Safe Checkpoint (75..108)
	_fill_tower_floor(76, 108, 18)
	_fill_catwalk(84, 92, 14)

	# 4. Boss Arena (109..154)
	_fill_tower_floor(109, 154, 18)
	_fill_catwalk(117, 124, 14)
	_fill_catwalk(136, 143, 14)


func _fill_tower_floor(x_start: int, x_end: int, top_y: int) -> void:
	for x in range(x_start, x_end + 1):
		var t: Vector2i = Vector2i(1, 1)
		if x == x_start:
			t = Vector2i(0, 1)
		elif x == x_end:
			t = Vector2i(2, 1)
		tile_map.set_cell(Vector2i(x, top_y), 0, t)
		for y in range(top_y + 1, 23):
			tile_map.set_cell(Vector2i(x, y), 0, Vector2i(3, 0) if (x + y) % 2 == 0 else Vector2i(4, 0))


func _fill_catwalk(x_start: int, x_end: int, y_pos: int) -> void:
	for x in range(x_start, x_end + 1):
		var src_id: int = 2 if x > x_start else 1
		tile_map.set_cell(Vector2i(x, y_pos), src_id, Vector2i.ZERO)


func _populate_tower_props() -> void:
	# 1. Central Tower Entrance (0..1024 px)
	_add_tower_sprite(TEX_ENTRY, Vector2(96, 512), 2.0, Rect2(192, 0, 64, 64))
	_add_tower_screen(TEX_SCREEN_2, Vector2(240, 510), 4, 32, 42)
	_add_tower_beacon(Vector2(540, 420), Color(1.0, 0.12, 0.25, 0.9))

	# 2. Defense Corridor (1056..2368 px)
	_add_tower_sprite(TEX_CABLE, Vector2(1320, 560), 2.0)
	_add_tower_beacon(Vector2(1600, 420), Color(1.0, 0.12, 0.25, 0.9))
	_add_tower_sprite(TEX_TUBE, Vector2(2040, 490), 2.0)

	# 3. AI Control Center & Pre-Boss Safe Checkpoint (2400..3456 px)
	_add_tower_sprite(TEX_REACTOR, Vector2(2520, 498), 2.2)
	_add_tower_screen(TEX_SCREEN_1, Vector2(2920, 512), 4, 32, 32)
	_add_tower_sprite(TEX_CONSOLE, Vector2(3140, 550), 2.0)
	_add_tower_beacon(Vector2(3328, 430), Color(0.0, 0.941176, 1.0, 0.9))

	# 4. Boss Arena (3488..4960 px)
	_add_tower_sprite(TEX_REACTOR, Vector2(3780, 498), 2.3)
	_add_tower_beacon(Vector2(4080, 390), Color(0.75, 0.15, 1.0, 0.9))
	_add_tower_beacon(Vector2(4440, 390), Color(1.0, 0.12, 0.25, 0.9))
	_add_tower_sprite(TEX_REACTOR, Vector2(4840, 498), 2.3)


func _add_tower_sprite(tex: Texture2D, pos: Vector2, prop_scale: float, region: Rect2 = Rect2()) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(prop_scale, prop_scale)
	sprite.position = pos
	sprite.modulate = Color(0.88, 0.78, 0.96, 1.0)
	if region.size != Vector2.ZERO:
		sprite.region_enabled = true
		sprite.region_rect = region
	props_container.add_child(sprite)


func _add_tower_screen(tex: Texture2D, pos: Vector2, frames: int, fw: int, fh: int) -> void:
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


func _add_tower_beacon(pos: Vector2, light_color: Color) -> void:
	var beacon := ColorRect.new()
	beacon.position = pos
	beacon.size = Vector2(20, 10)
	beacon.color = light_color
	lights_container.add_child(beacon)
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(beacon, "modulate:a", 0.2, 0.5)
	tween.tween_property(beacon, "modulate:a", 1.0, 0.5)


func _on_boss_trigger_entered(body: Node2D) -> void:
	if _boss_started or not (body is Player):
		return
	_boss_started = true
	arena_lock_door.visible = true
	arena_lock_shape.set_deferred("disabled", false)
	combat_hud.set_boss_hud_visible(true)
	boss.activate_boss()


func _on_boss_summon_drone(spawn_pos: Vector2) -> void:
	var drone := DRONE_SCENE.instantiate() as AttackDrone
	drone.global_position = spawn_pos
	drone.enemy_died.connect(_on_summoned_drone_died)
	add_child(drone)
	_summoned_drones.append(drone)


func _on_summoned_drone_died(enemy: EnemyBase, reward: int) -> void:
	_score += reward
	_kills += 1
	combat_hud.set_score(_score)
	if is_instance_valid(boss):
		boss.register_drone_died()
	if enemy is AttackDrone:
		_summoned_drones.erase(enemy as AttackDrone)


func _on_boss_defeated(reward: int) -> void:
	if _boss_defeated_handled:
		return
	_boss_defeated_handled = true
	_score += reward
	_kills += 1
	combat_hud.set_score(_score)
	_clear_summoned_drones()
	arena_lock_door.visible = false
	arena_lock_shape.set_deferred("disabled", true)

	player.set_controls_enabled(false)
	LevelProgressManager.commit_level_result(3, _score, _kills)
	combat_hud.show_game_completed(
		LevelProgressManager.get_total_score(),
		LevelProgressManager.get_total_enemies_defeated()
	)


func _clear_summoned_drones() -> void:
	for d in _summoned_drones:
		if is_instance_valid(d):
			d.queue_free()
	_summoned_drones.clear()


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
	if _boss_started and is_instance_valid(boss) and boss.current_state != OmegaXBoss.BossState.DEAD:
		_boss_started = false
		_clear_summoned_drones()
		boss.reset_boss()
		combat_hud.set_boss_hud_visible(false)
		arena_lock_door.visible = false
		arena_lock_shape.set_deferred("disabled", true)
	player.respawn_at(_active_spawn_position, true)


func _on_restart_pressed() -> void:
	SceneTransition.change_scene_to_file(FINAL_BATTLE_SCENE, 0.25)


func _on_replay_game_pressed() -> void:
	LevelProgressManager.start_new_run()
	SceneTransition.change_scene_to_file(NEON_CITY_SCENE, 0.3)


func _on_main_menu_pressed() -> void:
	SceneTransition.change_scene_to_file(MAIN_MENU_SCENE, 0.3)
