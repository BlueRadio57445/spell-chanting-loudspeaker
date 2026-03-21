extends CharacterBody2D

@export var SPEED = 200.0
@export var hp = 100
@export var STOP_DISTANCE = 100 # 離目的地多近要停下
var can_take_damage = true
var is_moving = false
var direction

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	# 1. 檢查是否為滑鼠左鍵點擊
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# 2. 只有在按下的一瞬間執行
		if event.pressed:
			# 3. 獲取滑鼠點擊的位置
			var target_position = get_global_mouse_position()
			if global_position.distance_to(target_position) < STOP_DISTANCE:
				is_moving = false
			else:
				direction = (target_position - global_position).normalized()
				is_moving = true
				
	if event.is_action_pressed("Die"): # 預設是空白鍵或 Enter
		attack_nearest_enemy()

func _physics_process(_delta: float) -> void:
	if is_moving:
		# 如果距離大於停止距離，就移動
		velocity = direction * SPEED
		# 簡單的轉向：讓角色面向移動方向
		if direction.x != 0:
			$AnimatedSprite2D.flip_h = direction.x > 0
		move_and_slide()
	
	# 動畫部分
	run_animated()

func run_animated():
	# 優先檢查是否正在「釋放符文」
	if anim.animation == "cast" and anim.is_playing():
		# 正在播技能動畫，不被打斷
		return
		
	# 檢查是否有移動速度
	if is_moving:
		# 播放走路動畫
		if anim.animation != "walk":
			anim.play("walk")
	else:
		anim.play("idle")

func take_damage(amount):
	if not can_take_damage or hp <= 0: return
	
	hp -= amount
	print("玩家受傷！剩餘血量：", hp)
	
	# 觸發無敵時間
	can_take_damage = false
	
	# 受傷回饋：閃爍並在 0.5 秒後恢復
	var tween = create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color.RED, 0.1)
	tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.1)
	# 這裡修正一個潛在錯誤：set_parallel(false) 是預設值，且應在 tween 啟動前設定
	tween.chain().tween_callback(func(): can_take_damage = true).set_delay(0.5)

	if hp <= 0:
		die()

func die():
	# 尋找場景中的 GameOverUI 節點並顯示它
	var game_over_screen = get_tree().root.find_child("EndMenu", true, false)
	if game_over_screen:
		game_over_screen.show_screen()
	

func attack_nearest_enemy():
	# 1. 取得所有在 "mobs" 群組裡的怪物 (記得你的怪物要加入這個群組)
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	if enemies.size() == 0:
		print("場面上沒有敵人可以測試")
		return
		
	var nearest_enemy = null
	var min_dist = INF # 初始值設為無限大
	
	# 2. 遍歷所有怪物找出最近的
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_enemy = enemy
			
	# 3. 執行傷害
	if nearest_enemy != null:
		print("對最近的敵人造成傷害！距離：", min_dist)
		
		# 這裡呼叫我們在 EnemyBase 寫好的 take_damage
		if nearest_enemy.has_method("take_damage"):
			nearest_enemy.take_damage(100) 
			
			# 額外視覺回饋：在玩家與目標之間畫一條簡單的線 (測試用)
			# draw_debug_line(nearest_enemy.global_position)
