extends CharacterBody2D
class_name RuneDrops

@export var ATTRACT_DISTANCE = 150.0
@export var PULL_SPEED = 400.0
var player = null
enum RuneType { NONE, FIRE, WATER, WIND, EARTH }
var rune_type = RuneType.NONE
var is_being_pulled = false

func _ready():
	# 取得玩家引用
	player = get_tree().root.find_child("Player", true, false)
	
	# 出現時的小動畫
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _physics_process(delta):
	if !player: return
	
	# 計算與玩家的距離
	var dist = global_position.distance_to(player.global_position)
	
	# 如果進入吸取範圍，標記為「被吸引狀態」
	if dist < ATTRACT_DISTANCE:
		is_being_pulled = true
		
	# 執行吸取移動
	if is_being_pulled:
		# 計算朝向玩家的方向向量
		var direction = (player.global_position - global_position).normalized()
		
		# 讓掉落物飛向玩家
		# 隨著距離變近，我們可以讓速度越來越快
		global_position += direction * PULL_SPEED * delta
		
		# 如果離玩家非常近了，直接觸發撿取
		if dist < 15:
			_collect()

func _collect():
	print("玩家成功吸收符文：", rune_type)
	# 這裡可以播放一個小音效或特效
	queue_free()

func onSummon(type):
	rune_type = type
	# 根據類型換顏色
	match type:
		RuneType.FIRE: modulate = Color.RED
		RuneType.WATER: modulate = Color.BLUE
		RuneType.WIND: modulate = Color.GREEN
		RuneType.EARTH: modulate = Color.BROWN

func _on_area_entered(area):
	if area.name == "PlayerHurtbox":
		# 撿取邏輯 (現在先留空)
		print("玩家撿到了符文！")
		queue_free() # 消失
