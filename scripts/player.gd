class_name Player
extends CharacterBody2D

signal health_changed(current: int, maximum: int)

@export var SPEED = 200.0
@export var max_hp = 100
@export var hp = 100
@export var STOP_DISTANCE = 100 # 離目的地多近要停下

static var Instance : Player
var can_take_damage = true
var is_moving = false
var direction

var speed_modifier = 0.0 # 百分比，例如 0.2 代表 +20%
var speed_mod_timer = 0.0
var invisible_timer = 0.0

@onready var anim = $AnimatedSprite2D

func _ready() -> void:
	Instance = self
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
	var current_speed = SPEED * (1.0 + speed_modifier)
	if is_moving:
		# 如果距離大於停止距離，就移動
		velocity = direction * current_speed
		# 簡單的轉向：讓角色面向移動方向
		if direction.x != 0:
			$AnimatedSprite2D.flip_h = direction.x > 0
		move_and_slide()
		
	# 效果部分
	if speed_mod_timer > 0:
		speed_mod_timer -= _delta
		if speed_mod_timer <= 0: speed_modifier = 0.0
	anim.speed_scale = speed_modifier + 1
		
	if invisible_timer > 0:
		invisible_timer -= _delta
		if invisible_timer <= 0: modulate.a = 1.0 # 恢復可見

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
	health_changed.emit(hp, max_hp)
	print("玩家受傷！剩餘血量：", hp)
	
	# 觸發無敵時間
	can_take_damage = false
	
	# 受傷抖動鏡頭
	var camera = $Camera2D 
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(10.0) # 10.0 是震動力度，可以根據受傷程度調整
	
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
		print("對最近的敵人造成中毒！距離：", min_dist)
		
		# 這裡呼叫我們在 EnemyBase 寫好的 take_damage
	
	apply_speed_modifier(-0.8, 5)

func _on_player_hurtbox_area_entered(area: Area2D) -> void:
	print(area.name)
	if area.is_in_group("Obstacle"):
		velocity = direction * -200 
		move_and_slide() # 執行一次彈開
		
		is_moving = false
		
func take_heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
	print("玩家回血！剩餘血量：", hp)
	var tween := create_tween()
	tween.tween_property($AnimatedSprite2D, "modulate", Color.GREEN, 0.1)
	tween.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.2)

func apply_speed_modifier(percent: float, duration: float):
	# 覆蓋原本效果
	speed_modifier = percent
	speed_mod_timer = duration

func apply_invisibility(duration: float):
	# 增加持續時間
	invisible_timer += duration
	# 視覺回饋：變半透明
	modulate.a = 0.3

# 提供一個介面給敵人檢查
func is_invisible() -> bool:
	return invisible_timer > 0
