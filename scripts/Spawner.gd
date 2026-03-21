extends Node2D

# 這裡放入你做好的各種怪物場景
@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_radius = 600.0 # 離玩家多遠生成

var player = null

func _ready():
	player = get_tree().root.find_child("Player", true, false)
	# 連接 Timer 信號
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout():
	if !player: return
	
	# 1. 隨機選一種怪
	var random_enemy_scene = enemy_scenes.pick_random()
	var enemy = random_enemy_scene.instantiate()
	
	# 2. 計算生成位置 (以玩家為中心的一個圓圈上，避免直接生在玩家臉上)
	var random_angle = randf() * TAU # TAU 是 2*PI
	var offset = Vector2(cos(random_angle), sin(random_angle)) * spawn_radius
	enemy.global_position = player.global_position + offset
	
	# 3. 把怪物加進戰鬥場景
	# 建議加到 get_parent()，這樣怪物才不會跟著 Spawner 移動
	get_tree().root.find_child("EnemyNode", true, false).add_child(enemy)
