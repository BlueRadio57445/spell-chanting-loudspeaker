extends CanvasLayer

func _ready():
	$StartButton.pressed.connect(_on_start_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)
	
# 引用勾選框節點
@onready var play_mv_check_box: CheckBox = $PlayMvCheckBox

func _on_start_pressed():
		# 檢查勾選框是否被選中
	if not play_mv_check_box.button_pressed:
		print("玩家選擇：播放 MV")
		# 切換到你製作的影片播放場景 (就是上一題教你的 VideoStreamPlayer 場景)
		get_tree().change_scene_to_file("res://scenes/MV.tscn")
	else:
		print("玩家選擇：跳過動畫，直接進入戰鬥")
		# 直接切換到戰鬥地圖
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
	
