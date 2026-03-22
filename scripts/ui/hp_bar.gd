extends PanelContainer

@onready var _bar: TextureProgressBar = $ProgressBar
var _old_hp: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().process_frame
	var p = Player.Instance 
	if p:
		_bar.max_value = p.max_hp
		_bar.value = p.hp
		_old_hp = p.hp # 記錄初始血量
		p.health_changed.connect(_on_health_changed)

func _on_health_changed(current: int, maximum: int) -> void:
	# 1. 判斷是受傷還是回血
	var flash_color = Color.WHITE
	if current < _old_hp:
		flash_color = Color(1, 0.3, 0.3) # 受傷閃紅
	elif current > _old_hp:
		flash_color = Color(0.3, 1, 0.3) # 回血閃綠
	
	_old_hp = current # 更新舊血量紀錄
	
	# 2. 建立 Tween 動效
	var tween = create_tween()
	# 設定並行：同時跑數值變動與顏色閃爍
	tween.set_parallel(true)
	
	# 數值平滑滑動
	tween.tween_property(_bar, "value", current, 0.2).set_trans(Tween.TRANS_SINE)
	
	# 顏色閃爍：從閃爍色變回白色 (或是你原本設定的顏色)
	# 我們針對 tint_progress 進行操作，這只會影響填充條
	_bar.tint_progress = flash_color
	tween.tween_property(_bar, "tint_progress", Color.WHITE, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# 如果上限有變動也同步更新
	_bar.max_value = maximum
