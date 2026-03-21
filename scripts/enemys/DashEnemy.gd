# DashEnemy.gd
extends EnemyBase

@export var dash_speed = 600.0
var is_dashing = false
var can_dash = true

func handle_movement(_delta):
	var dist = global_position.distance_to(player.global_position)
	
	if is_dashing:
		velocity = (player.global_position - global_position).normalized() * dash_speed
		move_and_slide()
	elif can_dash and dist < 200:
		start_dash()
	else:
		super.handle_movement(_delta) # 呼叫父類別的預設追蹤

func start_dash():
	is_dashing = true
	can_dash = false
	# 衝刺 0.3 秒後結束
	get_tree().create_timer(0.3).timeout.connect(func(): is_dashing = false)
	# 冷卻 1.5 秒
	get_tree().create_timer(1.5).timeout.connect(func(): can_dash = true)
