extends EnemyBase

@export var explode_range = 80.0
# 新增：控制擺動的參數（企劃如果覺得不夠快或不夠抖，改這裡）
@export var swing_speed: float = 15.0 # 擺動速度（頻率），數字越大擺越快
@export var swing_amplitude: float = 0.3 # 擺動幅度（弧度），數字越大轉越開 (約 17 度)

var is_exploding = false
var _time_passed: float = 0.0 # 用來記錄經過的時間，供 sin 函式使用

@onready var sprite = $Sprite2D

func _on_hitbox_area_entered(area):
	# 這裡維持原本的判斷邏輯，通常是檢查 body 或者是特定的 Area
	if area.name == "PlayerHurtbox":
		prepare_explosion()

func handle_movement(delta):
	# 1. 處理移動邏輯
	if is_exploding:
		velocity = Vector2.ZERO # 閃爍預警時停在原地
	else:
		super.handle_movement(delta) # 這行在EnemyBase應該是處理追蹤玩家的 velocity
		
	# 2. 處理視覺擺動動畫 (資工系解法：三角函數)
	_time_passed += delta
	
	# 如果正在準備爆炸，我們可以讓它擺動得更劇烈（選配）
	var current_swing_speed = swing_speed
	var current_swing_amplitude = swing_amplitude
	if is_exploding:
		current_swing_speed *= 2.0 # 爆炸前抖動快一倍
		current_swing_amplitude *= 1.2 # 幅度稍微變大
		
	# 計算新的旋轉角度： amplitude * sin(time * speed)
	# 這會讓 sprite.rotation 在 (-amplitude, +amplitude) 之間平滑變動
	sprite.rotation = current_swing_amplitude * sin(_time_passed * current_swing_speed)

	# 3. 執行物理移動
	move_and_slide() # 確保最後有呼叫這個，或者 super 裡面有呼叫
	
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
