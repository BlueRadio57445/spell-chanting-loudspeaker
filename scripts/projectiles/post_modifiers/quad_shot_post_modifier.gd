# 四射後修飾：命中時向四個隨機方向發射小閃電
class_name QuadShotPostModifier extends PostModifier

const LIGHTNING_SCENE: PackedScene = preload("res://scenes/projectiles/lightning.tscn")
const SPAWN_COUNT: int = 4
const SPAWN_DAMAGE: float = 5.0
const SPAWN_SPEED: float = 300.0

func clone() -> PostModifier:
	return QuadShotPostModifier.new()

func _ready() -> void:
	(get_parent() as ProjectileBase).body_entered.connect(_on_hit)

func _on_hit(body: Node2D) -> void:
	var proj: ProjectileBase = get_parent() as ProjectileBase
	if body == proj.owner_node:
		return
	var pos: Vector2 = proj.global_position
	for i: int in SPAWN_COUNT:
		var rand_dir: Vector2 = Vector2.from_angle(randf() * TAU)
		var sub: ProjectileBase = LIGHTNING_SCENE.instantiate()
		sub.global_position = pos
		sub.setup(proj.owner_node, rand_dir, SPAWN_SPEED, SPAWN_DAMAGE, "None", 0.0)
		Main.Instance.world.add_child(sub)
