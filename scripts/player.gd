extends CharacterBody2D

@export var SPEED = 200.0
@export var hp = 100
var can_take_damage = true

func _ready() -> void:
	print("ready")

func _physics_process(_delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	velocity = direction.normalized() * SPEED if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

func take_damage(amount):
	if not can_take_damage or hp <= 0: return
	
	hp -= amount
	print("玩家受傷！剩餘血量：", hp)
	
	# 觸發無敵時間
	can_take_damage = false
	
	# 受傷回饋：閃爍並在 0.5 秒後恢復
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color.RED, 0.1)
	tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
	tween.set_parallel(false)
	tween.tween_callback(func(): can_take_damage = true).set_delay(0.5)

	if hp <= 0:
		# 觸發 DataCenter 的死亡信號 (剛才提到的 AutoLoad)
		# DataCenter.emit_signal("player_died")
		pass
