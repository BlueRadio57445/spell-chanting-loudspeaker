extends Node2D

class_name Spawner
@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_radius = 1000.0

# --- 難度控制參數 ---
@export var start_wait_time: float = 4.0   # 初始間隔
@export var end_wait_time: float = 0.1     # 最終間隔
@export var total_ramp_time: float = 400.0 # 達到最高難度所需秒數

var player = null
var _elapsed_time: float = 0.0 # 紀錄遊戲開始後經過的時間

@onready var spawn_timer = $SpawnTimer

static var Instance : Spawner

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# 初始化 Timer 時間
	spawn_timer.wait_time = start_wait_time
	spawn_timer.start()
	
	Instance = self

func _process(delta: float):
	if _elapsed_time < total_ramp_time:
		_elapsed_time += delta
		
		# 1. 計算目前的進度百分比 (0.0 ~ 1.0)
		var progress = clamp(_elapsed_time / total_ramp_time, 0.0, 1.0)
		
		# 2. 使用 lerp 計算目前的等待時間
		# 從 4.0 慢慢變向 1.0
		var current_wait = lerp(start_wait_time, end_wait_time, progress)
		
		# 3. 更新 Timer 的間隔
		spawn_timer.wait_time = current_wait

func _on_spawn_timer_timeout():
	if !player: return
	
	var random_enemy_scene = enemy_scenes.pick_random()
	if not random_enemy_scene: return
	
	var enemy = random_enemy_scene.instantiate()
	
	var random_angle = randf() * TAU
	var offset = Vector2(cos(random_angle), sin(random_angle)) * spawn_radius
	enemy.global_position = player.global_position + offset
	
	var enemy_node = get_tree().root.find_child("EnemyNode", true, false)
	if enemy_node:
		enemy_node.add_child(enemy)
