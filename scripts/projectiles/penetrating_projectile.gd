# 穿透型投射物 — 命中敵人後不消失，繼續飛行
extends ProjectileBase
class_name PenetratingProjectile

var _hit_targets: Array[Node2D] = []

func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
	if body in _hit_targets:
		return
	_hit_targets.append(body)
	_apply_hit(body)
	hit_body.emit(body)
	# 不 queue_free — 繼續飛行
