extends EnemyBase

@onready var sprite = $Sprite2D

func handle_movement(_delta):
	sprite.rotate(PI * get_process_delta_time() * 5)
	super.handle_movement(_delta)
