# 穿透型投射物 — 命中敵人後不消失，繼續飛行
extends ProjectileBase
class_name PenetratingProjectile

var _hit_targets: Array[Node2D] = []

func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
	# 同一個敵人只打一次
	if body in _hit_targets:
		return
	_hit_targets.append(body)

	if body.has_method("take_damage"):
		body.take_damage(damage)

	if effect != "None" and body.has_method("apply_effect"):
		body.apply_effect(effect, effect_time)
	# 不 queue_free — 繼續飛行
