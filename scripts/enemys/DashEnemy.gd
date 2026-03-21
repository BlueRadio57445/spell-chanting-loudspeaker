# DashEnemy.gd
extends EnemyBase

@export var dash_speed = 600.0
@export var prep_time = 0.3      # 預警/蓄力時間
@export var dash_duration = 0.3  # 衝刺持續時間

@onready var sprite = $Sprite2D

var is_dashing = false
var can_dash = true
var is_prepping = false # 新增：是否正在蓄力

func handle_movement(_delta):
	# 如果正在蓄力，原地不動（或緩慢轉向）
	if is_prepping:
		velocity = Vector2.ZERO
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	if is_dashing:
		# 衝刺中：根據你的邏輯持續追蹤或直線衝刺
		velocity = (player.global_position - global_position).normalized() * dash_speed
		move_and_slide()
	elif can_dash and dist < 200:
		start_dash()
	else:
		super.handle_movement(_delta)

func start_dash():
	can_dash = false
	is_prepping = true # 開始蓄力
	
	# --- 蓄力動畫 (壓扁) ---
	var tween = create_tween()
	# 壓扁：X軸變寬，Y軸變矮
	tween.tween_property(sprite, "scale", Vector2(0.15 * 1.5, 0.15 * 0.6), prep_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 蓄力時間結束後，正式開始衝刺
	tween.tween_callback(func():
		is_prepping = false
		is_dashing = true
		
		# --- 衝刺動畫 (拉長) ---
		var dash_tween = create_tween()
		# 瞬間拉長：X軸變窄，Y軸變長
		dash_tween.tween_property(sprite, "scale", Vector2(0.15 * 0.6, 0.15 * 1.6), 0.1)
		# 衝刺中段恢復原狀
		dash_tween.tween_property(sprite, "scale", Vector2(0.15 * 1.0, 0.15 * 1.0), 0.2)
		
		# 衝刺時間結束
		get_tree().create_timer(dash_duration).timeout.connect(func(): 
			is_dashing = false
		)
		
		# 冷卻時間結束
		get_tree().create_timer(1.5).timeout.connect(func(): 
			can_dash = true
		)
	)
