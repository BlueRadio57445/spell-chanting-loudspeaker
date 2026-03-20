extends CharacterBody2D

const SPEED = 200.0

func _ready() -> void:
	var polygon := Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16),
		Vector2(16, 16), Vector2(-16, 16)
	])
	polygon.color = Color.CYAN
	add_child(polygon)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	add_child(collision)

func _physics_process(_delta: float) -> void:
	var direction := Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	)
	velocity = direction.normalized() * SPEED if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()
