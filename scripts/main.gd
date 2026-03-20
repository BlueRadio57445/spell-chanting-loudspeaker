extends Control

@onready var game_viewport_container: SubViewportContainer = $VBoxContainer/GameViewportContainer
@onready var rune_ui: Panel = $VBoxContainer/RuneUI

func _ready() -> void:
	# 確保暫停模式：UI 節點不受 pause 影響
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # 空白鍵
		get_tree().paused = !get_tree().paused
