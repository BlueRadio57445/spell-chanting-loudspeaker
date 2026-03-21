extends Control

@onready var game_viewport_container: SubViewportContainer = $VBoxContainer/GameViewportContainer
@onready var rune_ui: Panel = $VBoxContainer/RuneUI
@onready var rune_canvas: RuneCanvas = $VBoxContainer/RuneUI/HSplitContainer/RuneCanvas
@onready var rune_inventory: RuneInventory = $VBoxContainer/RuneUI/HSplitContainer/RuneInventory
@onready var rune_executor: RuneExecutor = $RuneExecutor

var fullscreen_rune_ui: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rune_executor.graph = rune_canvas.graph

	# 背包選擇符文 → 畫布進入放置模式
	rune_inventory.rune_selected.connect(func(rune_id: String) -> void:
		rune_canvas.start_placing(rune_id)
	)

	# 圖變更時同步給 executor
	rune_canvas.graph_changed.connect(func() -> void:
		rune_executor.graph = rune_canvas.graph
	)

	rune_executor.casting_started.connect(func(id: String) -> void:
		print("[Main] 施法開始: %s" % id)
	)
	rune_executor.casting_finished.connect(func() -> void:
		print("[Main] 施法結束")
	)
	rune_executor.casting_failed.connect(func(reason: String) -> void:
		print("[Main] 施法失敗: %s" % reason)
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):  # 空白鍵
		get_tree().paused = !get_tree().paused
		_toggle_rune_ui_fullscreen()

	# Q/W/E/R 觸發起始符文（僅在非暫停時）
	if not get_tree().paused:
		if event is InputEventKey:
			var key_event: InputEventKey = event as InputEventKey
			if key_event.pressed and not key_event.echo:
				match key_event.keycode:
					KEY_Q: rune_executor.trigger_starter(0)
					KEY_W: rune_executor.trigger_starter(1)
					KEY_E: rune_executor.trigger_starter(2)
					KEY_R: rune_executor.trigger_starter(3)

func _toggle_rune_ui_fullscreen() -> void:
	fullscreen_rune_ui = !fullscreen_rune_ui
	if fullscreen_rune_ui:
		game_viewport_container.visible = false
		rune_ui.size_flags_stretch_ratio = 1.0
	else:
		game_viewport_container.visible = true
		rune_ui.size_flags_stretch_ratio = 1.0
