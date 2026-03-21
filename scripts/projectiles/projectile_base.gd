# 投射物基類
# 所有投射物繼承此類，移動模式透過子節點 MovementModule 插拔
extends Area2D
class_name ProjectileBase

@export var speed: float = 300.0
@export var damage: float = 10.0
@export var size_scale: float = 1.0
@export var lifetime: float = 5.0

@export var effect: String = "None";
@export var effect_time: float = 0.0

var direction: Vector2 = Vector2.RIGHT
var owner_node: Node2D = null
var movement_module: MovementModule = null

func _ready() -> void:
	# 找到第一個 MovementModule 子節點
	for child in get_children():
		if child is MovementModule:
			movement_module = child
			break

	# 沒有移動模組就預設直線
	if movement_module == null:
		var linear = LinearMovement.new()
		add_child(linear)
		movement_module = linear

	movement_module.init(self)
	scale = Vector2(size_scale, size_scale)

	# 生命週期計時
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	movement_module.move(self, delta)
	$Sprite2D.rotation = direction.angle() - PI
	print(effect)

# 設定投射物參數，由 SpellSpawner 呼叫
func setup(p_owner: Node2D, p_direction: Vector2, p_speed: float, p_damage: float, p_effect: String, p_effect_time: float) -> void:
	owner_node = p_owner
	direction = p_direction.normalized() if p_direction != Vector2.ZERO else Vector2.RIGHT
	speed = p_speed
	damage = p_damage
	effect = p_effect         # 👈 同步更新
	effect_time = p_effect_time # 👈 同步更新
	
# 替換移動模組（可在加入場景樹前或後呼叫）
func set_movement_module(new_module: MovementModule) -> void:
	if movement_module:
		movement_module.queue_free()
	movement_module = new_module
	add_child(new_module)
	# 已在場景樹中才立即 init，否則等 _ready
	if is_inside_tree():
		movement_module.init(self)

# 碰撞處理，子類可覆寫
func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	print("Effect=", effect)
	if effect != "None":
		print("Effect1=", effect)
		body.apply_effect(effect, effect_time)
	queue_free()
