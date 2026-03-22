extends Control
class_name Main

@onready var game_viewport_container: SubViewportContainer = $GameViewportContainer
@onready var rune_ui: Panel = $RuneUI
@onready var rune_canvas: RuneCanvas = $RuneUI/HSplitContainer/RuneCanvas
@onready var rune_inventory: RuneInventory = $RuneUI/HSplitContainer/RuneInventory
@onready var rune_executor: RuneExecutor = $RuneExecutor
@onready var game_viewport: SubViewport = $GameViewportContainer/GameViewport
@onready var world: Node2D = $GameViewportContainer/GameViewport/World
@onready var player: CharacterBody2D = $GameViewportContainer/GameViewport/World/Player

static var Instance: Main
var fullscreen_rune_ui: bool = false
var projectile_scene: PackedScene = preload("res://scenes/projectiles/projectile_base.tscn")

func _ready() -> void:
	Instance = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	rune_executor.graph = rune_canvas.graph

	# 遊戲世界在暫停時停止，UI 保持可操作
	game_viewport_container.process_mode = Node.PROCESS_MODE_PAUSABLE

	# 符文 UI 半透明背景
	var ui_style := StyleBoxFlat.new()
	ui_style.bg_color = Color(0.05, 0.05, 0.1, 0.65)
	ui_style.set_border_width_all(1)
	ui_style.border_color = Color(0.3, 0.3, 0.5, 0.8)
	rune_ui.add_theme_stylebox_override("panel", ui_style)

	# 雙向注入引用：畫布需要知道背包位置（canvas→inventory），背包需要知道畫布（inventory→canvas）
	rune_canvas.rune_inventory = rune_inventory
	rune_inventory.canvas = rune_canvas

	# 測試：給玩家幾個初始符文
	rune_inventory.add_rune(RuneRegistry.create_instance("fireball"))
	rune_inventory.add_rune(RuneRegistry.create_instance("heal"))
	#rune_inventory.add_rune(RuneRegistry.create_instance("debuff"))
	#rune_inventory.add_rune(RuneRegistry.create_instance("fireball"))
	rune_inventory.add_rune(RuneRegistry.create_instance("energy_ball"))
	rune_inventory.add_rune(RuneRegistry.create_instance("ice_ball"))
	rune_inventory.add_rune(RuneRegistry.create_instance("poison_ball"))
	rune_inventory.add_rune(RuneRegistry.create_instance("boomerang"))
	rune_inventory.add_rune(RuneRegistry.create_instance("giant"))
	rune_inventory.add_rune(RuneRegistry.create_instance("orbit"))
	rune_inventory.add_rune(RuneRegistry.create_instance("multi_shot"))
	rune_inventory.add_rune(RuneRegistry.create_instance("quad_shot"))
	rune_inventory.add_rune(RuneRegistry.create_instance("fire_trail"))
	rune_inventory.add_rune(RuneRegistry.create_instance("poison_pool"))
	rune_inventory.add_rune(RuneRegistry.create_instance("shotgun"))
	rune_inventory.add_rune(RuneRegistry.create_instance("deflect"))
	rune_inventory.add_rune(RuneRegistry.create_instance("kinetic_energy"))
	rune_inventory.add_rune(RuneRegistry.create_instance("meditation"))
	rune_inventory.add_rune(RuneRegistry.create_instance("blood_tribute"))
	rune_inventory.add_rune(RuneRegistry.create_instance("steadfast"))

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
	if event.is_action_pressed("pause"):  # 空白鍵
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

func _get_mouse_world_pos() -> Vector2:
	return game_viewport.get_canvas_transform().affine_inverse() * game_viewport.get_mouse_position()

func _get_aim_direction() -> Vector2:
	var mouse_pos: Vector2 = _get_mouse_world_pos()
	return (mouse_pos - player.global_position).normalized()

func _test_spawn_projectile_linear() -> void:
	var proj: ProjectileBase = projectile_scene.instantiate()
	proj.global_position = player.global_position
	proj.setup(player, _get_aim_direction(), 400.0, 10.0, "None", 0)
	# 預設就是 LinearMovement，不用額外設定
	world.add_child(proj)
	print("[Test] 直線子彈 → 方向: ", _get_aim_direction())

func _test_spawn_projectile_stationary() -> void:
	var proj: ProjectileBase = projectile_scene.instantiate()
	proj.global_position = _get_mouse_world_pos()
	proj.setup(player, Vector2.ZERO, 0.0, 10.0, "None", 0)
	proj.set_movement_module(StationaryMovement.new())
	world.add_child(proj)
	print("[Test] 靜止子彈 → 位置: ", proj.global_position)

func _test_spawn_projectile_orbit() -> void:
	var proj: ProjectileBase = projectile_scene.instantiate()
	proj.global_position = player.global_position + Vector2(80, 0)
	proj.setup(player, Vector2.ZERO, 0.0, 10.0, "None", 0)
	proj.set_movement_module(OrbitMovement.new())
	world.add_child(proj)
	print("[Test] 環繞子彈")

func _test_spawn_projectile_homing() -> void:
	var proj: ProjectileBase = projectile_scene.instantiate()
	proj.global_position = player.global_position
	proj.setup(player, _get_aim_direction(), 300.0, 10.0, "None", 0)
	proj.set_movement_module(HomingMovement.new())
	world.add_child(proj)
	print("[Test] 追蹤子彈")

# ===== 正式邏輯 =====

func _toggle_rune_ui_fullscreen() -> void:
	fullscreen_rune_ui = !fullscreen_rune_ui
	if fullscreen_rune_ui:
		rune_ui.anchor_top = 0.0  # 全螢幕覆蓋
	else:
		rune_ui.anchor_top = 1  # 只覆蓋下半部
