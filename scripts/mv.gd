extends VideoStreamPlayer

func _ready():
	# 連結播放結束的訊號
	self.finished.connect(_on_video_finished)
	
	# 開始播放
	self.play()

func _on_video_finished():
	print("CG 播放完畢，準備進入遊戲...")
	# 切換到主畫面或遊戲畫面
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event):
	# 資工系貼心設計：按任意鍵跳過 CG
	if event is InputEventKey and event.pressed:
		_on_video_finished()
