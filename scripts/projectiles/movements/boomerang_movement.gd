# 迴力移動：飛行一段距離後轉向追蹤主人
# Phase 1（OUTWARD）：直線飛行直到抵達 max_range
# Phase 2（RETURN） ：追蹤 owner_node，抵達後 queue_free
extends MovementModule
class_name BoomerangMovement

@export var max_range: float = 300.0
@export var return_turn_speed: float = 6.0

enum Phase { OUTWARD, RETURN }
var _phase: Phase = Phase.OUTWARD
var _traveled: float = 0.0

func move(projectile: ProjectileBase, delta: float) -> void:
	match _phase:
		Phase.OUTWARD:
			var step: float = projectile.speed * delta
			projectile.position += projectile.direction * step
			_traveled += step
			if _traveled >= max_range:
				_phase = Phase.RETURN

		Phase.RETURN:
			if not is_instance_valid(projectile.owner_node):
				# 主人消失就直接銷毀
				projectile.queue_free()
				return
			var to_owner: Vector2 = (projectile.owner_node.global_position - projectile.global_position)
			if to_owner.length() < 16.0:
				projectile.queue_free()
				return
			var desired: Vector2 = to_owner.normalized()
			projectile.direction = projectile.direction.lerp(desired, return_turn_speed * delta).normalized()
			projectile.position += projectile.direction * projectile.speed * delta
