# RuneTooltip.gd
extends PanelContainer

@onready var title_label = $VBoxContainer/TitleLabel
@onready var desc_label = $VBoxContainer/DescLabel

func _ready():
	visible = false
	top_level = true # 確保在最上層
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func display(rune: RuneBase):
	title_label.text = rune.rune_name
	desc_label.text = rune.description
	
	# 設定最大寬度，防止敘述太長變成一橫條
	custom_minimum_size.x = 200
	
	visible = true
	_update_position()

func _process(_delta):
	if visible:
		_update_position()

func _update_position():
	var mouse_pos = get_global_mouse_position()
	var screen_size = get_viewport_rect().size
	var offset_y = -200.0 # 預設上方 200px
	
	# 邊界檢查：如果上方空間不足（滑鼠 y 座標小於 250 之類的）
	if mouse_pos.y + offset_y < 50:
		offset_y = 200.0 # 改到下方顯示
		
	# 計算目標位置並確保 Tooltip 本身不會超出螢幕左右邊界
	var target_pos = mouse_pos + Vector2(-size.x / 2, offset_y)
	target_pos.x = clamp(target_pos.x, 10, screen_size.x - size.x - 10)
	target_pos.y = clamp(target_pos.y, 10, screen_size.y - size.y - 10)
	
	global_position = target_pos

func hide_tooltip():
	visible = false
