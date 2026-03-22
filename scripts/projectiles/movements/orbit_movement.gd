# 環繞移動（繞玩家旋轉）
extends MovementModule
class_name OrbitMovement

@export var orbit_radius: float = 180.0
@export var orbit_speed: float = 3.0

var angle: float = 0.0

func init(projectile: ProjectileBase) -> void:
	# 以投射物出生時相對 owner 的角度作為起始角
	if projectile.owner_node:
		var offset: Vector2 = projectile.global_position - projectile.owner_node.global_position
		angle = offset.angle()

func move(projectile: ProjectileBase, delta: float) -> void:
	if not projectile.owner_node:
		return
	angle += orbit_speed * delta
	var offset = Vector2(cos(angle), sin(angle)) * orbit_radius
	projectile.global_position = projectile.owner_node.global_position + offset
