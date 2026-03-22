extends CanvasLayer

# 預載圖片資源，避免滑過去的時候才讀取造成微小卡頓
var restart_normal = preload("res://resources/UI/Background/restartButton.png")
var restart_hover = preload("res://resources/UI/Background/restartButtonPressed.png")
var close_normal = preload("res://resources/UI/Background/closeButton.png")
var close_hover = preload("res://resources/UI/Background/closeButtonPressed.png")

func _ready():
	$RetryButton.pressed.connect(_on_retry_pressed)
	$HomeButton.pressed.connect(_on_home_pressed)
	
	# 連結滑鼠滑入/滑出的訊號
	$RetryButton.mouse_entered.connect(_on_retry_hover.bind(true))
	$RetryButton.mouse_exited.connect(_on_retry_hover.bind(false))
	
	$HomeButton.mouse_entered.connect(_on_home_hover.bind(true))
	$HomeButton.mouse_exited.connect(_on_home_hover.bind(false))

# --- 處理 RetryButton 換圖 ---
func _on_retry_hover(is_hover: bool):
	# 假設你使用的是 TextureButton，直接換 texture 屬性
	# 如果是普通 Button 則需要換 StyleBox (這裡以 TextureButton 為例)
	if is_hover:
		$RetryButton.texture_normal = restart_hover
	else:
		$RetryButton.texture_normal = restart_normal

# --- 處理 HomeButton 換圖 ---
func _on_home_hover(is_hover: bool):
	if is_hover:
		$HomeButton.texture_normal = close_hover
	else:
		$HomeButton.texture_normal = close_normal

# --- 原有邏輯 ---
func _on_retry_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_home_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func show_screen():
	self.visible = true
	# ⚠️ 重要：要確保此 CanvasLayer 的 Process Mode 設為 "Always"
	# 否則遊戲暫停時，這裡的按鈕也會沒反應
	get_tree().paused = true
