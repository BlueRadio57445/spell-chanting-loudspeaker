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
	# 1. 偵測範圍傷害 (最快做法：檢查與玩家距離)
	var dist = global_position.distance_to(player.global_position)
	if dist < explode_range * 1.5:
		if player.has_method("take_damage"):
			player.take_damage(attack * 3) # 自爆通常傷害很高
			
	# 2. 播放特效或聲音 (Game Jam 必備)
	# spawn_explosion_effect()
	
	# 3. 消失
	queue_free()
