# 直線移動（子彈型態預設）
extends MovementModule
class_name LinearMovement

func move(projectile: ProjectileBase, delta: float) -> void:
	projectile.position += projectile.direction * projectile.speed * delta
