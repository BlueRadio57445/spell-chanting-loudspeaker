extends EnemyBase
@onready var sprite = $Sprite2D

var is_wobbling = false

func handle_movement(_delta):
	# 1. 執行父類別的移動 (包含 move_and_slide)
	super.handle_movement(_delta)
	
	# 2. 史萊姆擠壓拉伸動畫
	# 當速度夠快且沒在播動畫時觸發
	if velocity.length() > 10.0 and not is_wobbling:
		_play_wobble()

func _play_wobble():
	is_wobbling = true
	var tween = create_tween()
	
	# 擠壓 (變成扁平)
	tween.tween_property(sprite, "scale", Vector2(0.128 * 1.4, 0.128 * 0.6), 0.5).set_trans(Tween.TRANS_SINE)
	# 拉伸 (變成細長)
	tween.tween_property(sprite, "scale", Vector2(0.128 * 0.7, 0.128 * 1.3), 0.5).set_trans(Tween.TRANS_SINE)

	# 動畫結束標記
	tween.tween_callback(func(): is_wobbling = false)
