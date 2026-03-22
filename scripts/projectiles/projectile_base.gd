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
var penetrating: bool = false

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
	if movement_module != OrbitMovement:
		get_tree().create_timer(lifetime, false).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	movement_module.move(self, delta)
	$Sprite2D.rotation = direction.angle() - PI

# 設定投射物參數，由 SpellSpawner 呼叫
func setup(p_owner: Node2D, p_direction: Vector2, p_speed: float, p_damage: float, p_effect: String, p_effect_time: float) -> void:
	owner_node = p_owner
	direction = p_direction.normalized() if p_direction != Vector2.ZERO else Vector2.RIGHT
	speed = p_speed
	damage = p_damage
	effect = p_effect         # 👈 同步更新
	effect_time = p_effect_time # 👈 同步更新
	
# 套用 Form 字典（由符文系統傳入）
# form = { "movement": "homing"/"orbit"/"ground"/..., "size_scale": 2.0, ... }
func apply_form(form: Dictionary) -> void:
	# 移動方式（互斥，後蓋前）
	var movement_type: String = form.get("movement", "bullet")
	match movement_type:
		"homing":
			set_movement_module(HomingMovement.new())
		"orbit":
			set_movement_module(OrbitMovement.new())
		"ground":
			set_movement_module(StationaryMovement.new())
		"boomerang":
			set_movement_module(BoomerangMovement.new())
		# "bullet" 或未知值 → 不動，保留預設 LinearMovement

	# 穿透（命中不消失）
	if form.get("penetrating", false):
		penetrating = true

	# 形體變化：巨化
	if form.has("size_scale"):
		size_scale *= form["size_scale"]

# 替換移動模組（可在加入場景樹前或後呼叫）
func set_movement_module(new_module: MovementModule) -> void:
	if movement_module:
		movement_module.queue_free()
	movement_module = new_module
	add_child(new_module)
	# 已在場景樹中才立即 init，否則等 _ready
	if is_inside_tree():
		movement_module.init(self)

# 命中時共用邏輯（傷害、狀態），後修飾行為由子節點 PostModifier 處理
func _apply_hit(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)

	if effect != "None" and body.has_method("apply_effect"):
		body.apply_effect(effect, effect_time)

# 碰撞處理，子類可覆寫
var _penetrating_hit_targets: Array[Node2D] = []

func _on_body_entered(body: Node2D) -> void:
	if body == owner_node:
		return
	if penetrating:
		if body in _penetrating_hit_targets:
			return
		_penetrating_hit_targets.append(body)
		_apply_hit(body)
	else:
		_apply_hit(body)
		queue_free()
