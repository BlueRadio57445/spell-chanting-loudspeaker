# InvisibleEnemy.gd
extends "res://scripts/enemys/BaseEnemy.gd"

var sprite: Sprite2D
var visibility_timer: Timer

func setup_enemy():
	# 取得第一個子節點 (假設是 Sprite2D)
	sprite = get_child(0)
	
	# 初始狀態設為全透明 (Alpha = 0)
	sprite.modulate.a = 0.0
	
	# 建立一個循環計時器，每 1 秒觸發一次顯影循環
	visibility_timer = Timer.new()
	add_child(visibility_timer)
	visibility_timer.wait_time = 1.0
	visibility_timer.timeout.connect(_on_visibility_cycle)
	visibility_timer.start()

func _on_visibility_cycle():
	var tween = create_tween()
	
	# 1. 漸顯 0.1 秒 (Alpha 從 0 到 1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	
	# 2. 停留一小段時間 (可選，這裡設定為顯示 0.1 秒讓玩家看清楚)
	tween.tween_interval(0.1)
	
	# 3. 漸隱 0.1 秒 (Alpha 從 1 回到 0)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)

# 注意：如果怪物隱形時不應該被攻擊，可以覆寫 take_damage
func take_damage(amount):
	# 只有在透明度大於某個值時才受傷，或者強制顯影
	if sprite.modulate.a > 0.2:
		super.take_damage(amount)
