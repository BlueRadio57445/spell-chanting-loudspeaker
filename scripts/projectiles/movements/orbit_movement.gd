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
	
	# 1. 更新角度
	angle += orbit_speed * delta
	
	# 2. 計算新的位置偏移
	var offset = Vector2(cos(angle), sin(angle)) * orbit_radius
	projectile.global_position = projectile.owner_node.global_position + offset
	
	# 3. 計算切線方向 (Tangent)
	# 方法 A：利用垂直向量原理 (x, y) 的垂直向量是 (-y, x)
	var tangent_dir = Vector2(-sin(angle), cos(angle))
	
	# 如果你的 orbit_speed 是負的（逆時針），切線方向要反轉
	if orbit_speed < 0:
		tangent_dir = -tangent_dir
	
	# 4. 更新子彈的方向
	projectile.direction = tangent_dir
