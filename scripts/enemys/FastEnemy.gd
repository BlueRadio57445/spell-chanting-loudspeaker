extends EnemyBase

@onready var sprite = $Sprite2D

func _physics_process(_delta):
	if is_stunned and speed >= 100:
		speed /= 1.0015
	super._physics_process(_delta)
		
func handle_movement(_delta):
	if(speed < 300):
		speed *= 1.0075
	else:
		speed = 300
	sprite.rotate(PI * get_process_delta_time() * (speed / 40))
	super.handle_movement(_delta)
