extends CanvasLayer

func _ready():
	$RetryButton.pressed.connect(_on_retry_pressed)
	$HomeButton.pressed.connect(_on_home_pressed)

func _on_retry_pressed():
	get_tree().paused = false # 記得解除暫停
	get_tree().reload_current_scene() # 重新載入當前關卡

func _on_home_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func show_screen():
	self.visible = true
	get_tree().paused = true # 讓遊戲世界停止，但 UI 繼續跑
