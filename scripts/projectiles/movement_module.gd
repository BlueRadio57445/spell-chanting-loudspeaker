# 移動模組基類
# 所有移動模式繼承此類，作為 ProjectileBase 的子節點插拔
extends Node
class_name MovementModule

# 初始化，投射物 _ready 時呼叫
func init(_projectile: ProjectileBase) -> void:
	pass

# 每幀移動邏輯，由投射物 _physics_process 呼叫
func move(_projectile: ProjectileBase, _delta: float) -> void:
	pass
