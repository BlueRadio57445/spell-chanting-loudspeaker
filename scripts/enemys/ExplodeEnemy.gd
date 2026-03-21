extends EnemyBase

@export var explode_range = 80.0
var is_exploding = false

func _on_hitbox_area_entered(area):
	prepare_explosion()
	
func handle_movement(_delta):
	if is_exploding:
		velocity = Vector2.ZERO # 確保閃爍時停在原地
		return
	super.handle_movement(_delta) # 平時正常追蹤
	
func prepare_explosion():
	is_exploding = true
	# 停止移動
	velocity = Vector2.ZERO
	
	# 閃爍預警動畫
	var tween = create_tween()
	# 快速閃爍三次
	for i in range(3):
		tween.tween_property($Sprite2D, "modulate", Color.ORANGE_RED, 0.1)
		tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
	
	# 動畫結束後呼叫爆炸
	tween.tween_callback(explode_now)

func explode_now():
	# 1. 隱藏本體，顯示粒子
	$Sprite2D.visible = false
	var part = $ParticleSprite2D
	part.visible = true
	
	# 設定初始位置與縮放 (根據你的需求)
	part.position = Vector2(4.25, -15.5)
	part.scale = Vector2(0.1, 0.1)
	part.modulate.a = 1.0 # 確保是顯示的
	
	# 2. 建立爆炸動畫 Tween
	var tween = create_tween()
	
	# 設定為並行執行 (位移與縮放同時發生)
	tween.set_parallel(true)
	# 0.3 秒放大並移動到指定方位
	tween.tween_property(part, "scale", Vector2(0.4, 0.4), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(part, "position", Vector2(-29, 38), 0.3)
	
	# 3. 動畫完成後的後續處理 (使用 chain 回到序列執行)
	tween.set_parallel(false)
	# 0.1 秒漸隱
	tween.tween_property(part, "modulate:a", 0.0, 0.1)
	
	# 4. 傷害判定 (建議在爆炸動畫開始時或中間判定，這裡維持原樣)
	var dist = global_position.distance_to(player.global_position)
	if dist < explode_range * 1.5:
		if player.has_method("take_damage"):
			player.take_damage(attack * 3)

	# 5. 特效放完後消失
	tween.tween_callback(queue_free)
