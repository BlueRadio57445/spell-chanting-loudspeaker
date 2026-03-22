# EnemyBase.gd
extends CharacterBody2D
class_name EnemyBase # 定義類別名稱，讓子類別可以 extends 它

@export var speed = 50.0
@export var health = 50
@export var attack = 3

@export_group("Loot Settings")
# 設定每個符文對應的權重 (數字越大機率越高)
@export var loot_weights : Dictionary[String, int] = {
	"None" : 50
}
@export var loot_item_scene: PackedScene # 放剛才建立的 RuneItem.tscn

var status_effects = {
	"burn": { "stacks": 0, "timer": 0.0 },
	"slow": { "time_left": 0.0 },
	"freeze": { "time_left": 0.0 },
	"poison": { "stacks": 0, "timer": 0.0 }
}

var player = null
var is_stunned = false

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	setup_enemy() # 留給子類別初始化的「鉤子」

func setup_enemy():
	pass # 子類別可以覆寫這裡

func _physics_process(_delta):
	if !player or health <= 0 or is_stunned: return
	handle_movement(_delta) # 讓子類別決定怎麼動
	handle_effect_timers(_delta)
	var direction = (player.global_position - global_position).normalized()
	if direction.x != 0:
		$Sprite2D.flip_h = direction.x > 0

func handle_movement(_delta):
	# 預設追蹤邏輯
	if not player.is_invisible():
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * get_modified_speed(speed)
		move_and_slide()

func take_damage(amount):
	health -= amount
	
	# 受傷動畫簡易效果：閃紅燈
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color.RED, 0.1)
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
	
	if health <= 0: die()

func apply_hit_stop(duration = 0.8):
	is_stunned = true
	
	# 擊退：朝玩家的反方向彈開一小段距離
	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * 200 
	move_and_slide() # 執行一次彈開
	
	velocity = Vector2.ZERO
	get_tree().create_timer(duration).timeout.connect(func(): is_stunned = false)



# 連接 Hitbox 信號 (在父類別寫好，子類別就不用重複寫)
func _on_hitbox_area_entered(area):
	# 擊退：朝玩家的反方向彈開一小段距離
	var knockback_dir = (global_position - player.global_position).normalized()
	velocity = knockback_dir * 200 
	move_and_slide() # 執行一次彈開
	
	if is_stunned: return
	
	if area.name == "PlayerHurtbox" and status_effects["freeze"]["time_left"] <= 0:
		if player.has_method("take_damage"):
			player.take_damage(attack)
			apply_hit_stop()

# 死亡的邏輯
func die():
	calculate_loot()
	queue_free()

func calculate_loot():
	# 1. 計算總權重
	var total_weight = 0
	for weight in loot_weights.values():
		total_weight += weight
	
	# 2. 取隨機值
	var roll = randi() % total_weight
	var current_sum = 0
	
	# 3. 區間判定
	for rune in loot_weights:
		current_sum += loot_weights[rune]
		if roll < current_sum:
			if rune != "None":
				spawn_loot(rune)
			return # 抽中了就結束

func spawn_loot(type):
	if loot_item_scene:
		var item = loot_item_scene.instantiate()
		item.global_position = global_position # 掉在怪物死掉的位置
		get_parent().add_child(item)
		item.onSummon(type) # 通知掉落物它是哪種符文

# 效果邏輯
func apply_effect(effect_name: String, value: float = 0.0):
	match effect_name:
		"burn":
			# 衝突檢查：移除緩速與冰凍
			status_effects["slow"]["time_left"] = 0.0
			status_effects["freeze"]["time_left"] = 0.0
			status_effects["burn"]["stacks"] += value
			
		"slow":
			# 衝突檢查：如果有冰凍，移除緩速
			if status_effects["freeze"]["time_left"] > 0:
				status_effects["slow"]["time_left"] = 0.0
				return
			# 衝突檢查：移除燃燒
			status_effects["burn"]["stacks"] = 0.0
			status_effects["burn"]["timer"] = 0.0
			# 疊加持續時間
			status_effects["slow"]["time_left"] += value
			
		"freeze":
			# 衝突檢查：移除燃燒與緩速
			status_effects["burn"]["stacks"] = 0.0
			status_effects["burn"]["timer"] = 0.0
			status_effects["slow"]["time_left"] = 0.0
			status_effects["freeze"]["time_left"] += value
			
		"poison":
			# 無衝突，無限持續
			status_effects["poison"]["stacks"] += value
	

func handle_effect_timers(delta):
	# 處理緩速與冰凍的倒數
	if status_effects["slow"]["time_left"] > 0:
		status_effects["slow"]["time_left"] -= delta
		
	if status_effects["freeze"]["time_left"] > 0:
		status_effects["freeze"]["time_left"] -= delta

	# 每 1 秒觸發一次 Dot (燃燒 & 中毒)
	tick_dot_damage(delta, "burn")
	tick_dot_damage(delta, "poison")

func tick_dot_damage(delta, type):
	status_effects[type]["timer"] += delta
	if status_effects[type]["timer"] >= 1.0:
		var s = status_effects[type]["stacks"]
		if s > 0:
			take_damage(s) # 受到 n 點傷害
			if type == "burn":
				status_effects[type]["stacks"] -= 1 # 燃燒每秒減 1 層
		status_effects[type]["timer"] = 0.0

# 修改原本的 handle_movement 來套用效果
func get_modified_speed(s) -> float:
	if status_effects["freeze"]["time_left"] > 0:
		return 0.0 # 冰凍無法行動
	if status_effects["slow"]["time_left"] > 0:
		return s * 0.25 # 減少 75%
	return s
