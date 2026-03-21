extends Camera2D

@export var shake_fade = 5.0 # 震動衰減速度，越高停得越快
var shake_strength = 0.0     # 當前震動強度

func _process(delta):
	if shake_strength > 0:
		# 隨時間線性衰減強度
		shake_strength = lerp(shake_strength, 0.0, shake_fade * delta)
		# 隨機偏移座標
		offset = get_random_offset()

func get_random_offset() -> Vector2:
	return Vector2(
		randf_range(-shake_strength, shake_strength),
		randf_range(-shake_strength, shake_strength)
	)

# 外部呼叫此函式來觸發震動
func apply_shake(strength: float):
	shake_strength = strength
