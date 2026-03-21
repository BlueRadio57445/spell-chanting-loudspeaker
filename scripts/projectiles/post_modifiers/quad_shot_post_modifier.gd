# 四射後修飾：命中時向四個隨機方向發射小投射物
class_name QuadShotPostModifier extends PostModifier

var spawn_scene: PackedScene
var spawn_count: int = 4
var spawn_damage_ratio: float = 0.4
var spawn_scale: float = 0.6

func clone() -> PostModifier:
	var c := QuadShotPostModifier.new()
	c.spawn_scene = spawn_scene
	c.spawn_count = spawn_count
	c.spawn_damage_ratio = spawn_damage_ratio
	c.spawn_scale = spawn_scale
	return c

func _ready() -> void:
	(get_parent() as ProjectileBase).body_entered.connect(_on_hit)

func _on_hit(body: Node2D) -> void:
	var proj: ProjectileBase = get_parent() as ProjectileBase
	if body == proj.owner_node:
		return
	var pos: Vector2 = proj.global_position
	for i: int in spawn_count:
		var rand_dir: Vector2 = Vector2.from_angle(randf() * TAU)
		var sub: ProjectileBase = spawn_scene.instantiate()
		sub.global_position = pos
		sub.setup(proj.owner_node, rand_dir,
			proj.speed * 0.8, proj.damage * spawn_damage_ratio,
			proj.effect, proj.effect_time)
		sub.size_scale = spawn_scale
		Main.Instance.world.add_child(sub)
