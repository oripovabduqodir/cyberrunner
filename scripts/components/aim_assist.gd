extends Node2D
class_name AimAssist

## Mobil boshqaruv uchun Auto-Aim tizimi (EnemyBase va OmegaXBoss bilan ishlaydi).
## Anti-jitter gisterezis, Line-of-Sight tekshiruvi va vizual Target Indicator ga ega.

@export var enabled: bool = false
@export var max_range: float = 480.0
@export var melee_range: float = 120.0

@onready var los_ray: RayCast2D = $LineOfSightRay
@onready var target_indicator: Node2D = $TargetIndicator

var _locked_target: Node2D = null
var _indicator_angle: float = 0.0


func _ready() -> void:
	target_indicator.visible = false
	target_indicator.top_level = true


func _process(delta: float) -> void:
	if not enabled or _locked_target == null or not is_instance_valid(_locked_target) or _is_target_dead(_locked_target):
		target_indicator.visible = false
		return

	target_indicator.visible = true
	target_indicator.global_position = _get_target_aim_point(_locked_target)
	_indicator_angle += delta * 2.8
	target_indicator.rotation = _indicator_angle


func set_enabled(is_enabled: bool) -> void:
	enabled = is_enabled
	if not enabled:
		_locked_target = null
		target_indicator.visible = false


func get_aim_direction(origin: Vector2, fallback_dir: Vector2) -> Vector2:
	if not enabled:
		return fallback_dir

	_locked_target = _select_target(origin, max_range)
	if _locked_target != null:
		return (_get_target_aim_point(_locked_target) - origin).normalized()
	return fallback_dir


func get_melee_aim_direction(origin: Vector2, fallback_dir: Vector2) -> Vector2:
	if not enabled:
		return fallback_dir

	var melee_target: Node2D = _find_closest_valid_target(origin, melee_range)
	if melee_target != null:
		return (_get_target_aim_point(melee_target) - origin).normalized()
	return fallback_dir


func _select_target(origin: Vector2, range_limit: float) -> Node2D:
	# Anti-jitter: joriy nishon hali tirik, ko'rinadigan va masofada bo'lsa, keskin almashtirmaslik
	var keep_dist_sq: float = INF
	if _locked_target != null and is_instance_valid(_locked_target) and not _is_target_dead(_locked_target):
		var cur_point: Vector2 = _get_target_aim_point(_locked_target)
		var cur_d2: float = origin.distance_squared_to(cur_point)
		if cur_d2 <= (range_limit * 1.12) * (range_limit * 1.12) and _has_line_of_sight(origin, cur_point):
			keep_dist_sq = cur_d2

	var candidate: Node2D = _find_closest_valid_target(origin, range_limit)
	if candidate == null:
		return _locked_target if keep_dist_sq < INF else null

	if keep_dist_sq < INF and candidate != _locked_target:
		var cand_d2: float = origin.distance_squared_to(_get_target_aim_point(candidate))
		if cand_d2 > keep_dist_sq * 0.62:
			return _locked_target

	return candidate


func _find_closest_valid_target(origin: Vector2, range_limit: float) -> Node2D:
	var enemies: Array[Node] = get_tree().get_nodes_in_group(&"enemies")
	var best_target: Node2D = null
	var best_dist_sq: float = range_limit * range_limit

	for node in enemies:
		if not (node is Node2D):
			continue
		var enemy := node as Node2D
		if _is_target_dead(enemy):
			continue

		var aim_pt: Vector2 = _get_target_aim_point(enemy)
		var dist_sq: float = origin.distance_squared_to(aim_pt)
		if dist_sq > best_dist_sq:
			continue

		if _has_line_of_sight(origin, aim_pt):
			best_dist_sq = dist_sq
			best_target = enemy

	return best_target


func _is_target_dead(node: Node2D) -> bool:
	if node is EnemyBase:
		var eb := node as EnemyBase
		return eb.current_state == EnemyBase.State.DEAD or eb.health_component.is_dead()
	if node is OmegaXBoss:
		var boss := node as OmegaXBoss
		return boss.current_state == OmegaXBoss.BossState.DORMANT or boss.current_state == OmegaXBoss.BossState.DEAD or boss.health_component.is_dead()
	var hc: Node = node.get_node_or_null("HealthComponent")
	if hc is HealthComponent:
		return (hc as HealthComponent).is_dead()
	return false


func _get_target_aim_point(node: Node2D) -> Vector2:
	if node is OmegaXBoss:
		return node.global_position + Vector2(0.0, -64.0)
	if node is SecurityTurret:
		return node.global_position + Vector2(0.0, -32.0)
	return node.global_position


func _has_line_of_sight(origin: Vector2, target_pos: Vector2) -> bool:
	los_ray.global_position = origin
	los_ray.target_position = los_ray.to_local(target_pos)
	los_ray.force_raycast_update()
	return not los_ray.is_colliding()
