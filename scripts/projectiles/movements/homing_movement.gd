# 追蹤移動（自動飛向目標）
# 可透過 set_target() 從外部指定目標（符文系統 Target port），
# 未指定時自動追蹤最近敵人，完全找不到則退化成直線。
extends MovementModule
class_name HomingMovement

@export var turn_speed: float = 5.0

var target: Node2D = null
var _has_explicit_target: bool = false
var _fallback_linear: bool = false

# 由外部呼叫，設定符文系統傳入的 Target
func set_target(t: Node2D) -> void:
	target = t
	_has_explicit_target = true

func init(projectile: ProjectileBase) -> void:
	if not _has_explicit_target:
		_find_nearest_target(projectile)
	# 初始化時就找不到任何目標，直接退化成直線
	if not is_instance_valid(target):
		_fallback_linear = true

func move(projectile: ProjectileBase, delta: float) -> void:
	if _fallback_linear:
		projectile.position += projectile.direction * projectile.speed * delta
		return

	if not is_instance_valid(target):
		if _has_explicit_target:
			# 指定目標死了，退化成直線
			_fallback_linear = true
			projectile.position += projectile.direction * projectile.speed * delta
			return
		# 自動模式：嘗試重新搜尋
		_find_nearest_target(projectile)
		if not is_instance_valid(target):
			_fallback_linear = true
			projectile.position += projectile.direction * projectile.speed * delta
			return

	# 逐漸轉向目標
	var desired_dir: Vector2 = (target.global_position - projectile.global_position).normalized()
	projectile.direction = projectile.direction.lerp(desired_dir, turn_speed * delta).normalized()
	projectile.position += projectile.direction * projectile.speed * delta

func _find_nearest_target(projectile: ProjectileBase) -> void:
	var mobs: Array[Node] = projectile.get_tree().get_nodes_in_group("Enemy")
	var min_dist: float = INF
	target = null
	for mob in mobs:
		if not is_instance_valid(mob):
			continue
		var dist: float = projectile.global_position.distance_squared_to(mob.global_position)
		if dist < min_dist:
			min_dist = dist
			target = mob as Node2D
