extends EnemyBase

@onready var sprite = $Sprite2D

func _physics_process(_delta):
	if is_stunned and speed >= 40:
		speed = 40
	super._physics_process(_delta)
		
func handle_movement(_delta):
	if(speed < 300):
		speed *= 1.0075
	else:
		speed = 300
	sprite.rotate(PI * get_process_delta_time() * (speed / 40))
	super.handle_movement(_delta)

func apply_hit_stop(duration = 3.0):
	is_stunned = true
	
	# 擊退：朝玩家的反方向彈開一小段距離
	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * -2000
	move_and_slide() # 執行一次彈開
	
	velocity = Vector2.ZERO
	get_tree().create_timer(duration).timeout.connect(func(): is_stunned = false)
