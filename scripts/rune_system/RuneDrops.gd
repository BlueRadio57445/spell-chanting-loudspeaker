extends CharacterBody2D
class_name RuneDrops

@export var ATTRACT_DISTANCE = 150.0
@export var PULL_SPEED = 400.0
var player = null
var rune_type
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

func onSummon(type: String):
	rune_type = type
	
	# 1. 組合圖片路徑
	var image_path = "res://resources/Runes/%s.png" % type
	
	# 2. 檢查檔案是否存在 (防止因為 type 拼錯導致遊戲閃退)
	if FileAccess.file_exists(image_path):
		# 載入圖片並設定給 Sprite2D
		var tex = load(image_path)
		$Sprite2D.texture = tex
	else:
		push_warning("警告：找不到符文圖片路徑: " + image_path)
		# 這裡可以選擇設定一個預設的錯誤圖片，或者維持原樣
	
func _on_area_entered(area):
	if area.name == "PlayerHurtbox":
		print("玩家撿到了符文！ ID 為: ", rune_type)
		
		# 1. 找到背包
		var inv = get_tree().root.find_child("RuneInventory", true, false)
		
		if inv:
			# 2. 關鍵修正：使用 RuneRegistry 產生一個真正的實例 (Instance)
			# 假設你的 rune_type 儲存的是像 "fireball" 這樣的字串 ID
			var new_rune_instance = RuneRegistry.create_instance(rune_type)
			
			# 3. 把實例交給背包
			inv.add_rune(new_rune_instance)
			
		queue_free()
