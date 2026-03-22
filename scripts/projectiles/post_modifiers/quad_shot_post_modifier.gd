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
	_spawn_attach_particles()

func _spawn_attach_particles() -> void:
	var pos: Vector2 = (get_parent() as ProjectileBase).global_position
	var tex: ImageTexture = _create_diamond_texture()

	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))

	var particles := CPUParticles2D.new()
	particles.texture = tex
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.scale_amount_min = 0.6
	particles.scale_amount_max = 1.0
	particles.color_ramp = gradient
	particles.gravity = Vector2.ZERO
	particles.z_index = 1
	particles.global_position = pos
	Main.Instance.world.add_child(particles)
	Main.Instance.get_tree().create_timer(particles.lifetime + 0.1).timeout.connect(particles.queue_free)

# 長稜形 texture（黃色填充 + 黑色外框）
func _create_diamond_texture() -> ImageTexture:
	const W: int = 6
	const H: int = 16
	var img: Image = Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	var cx: float = W / 2.0
	var cy: float = H / 2.0
	for x: int in range(W):
		for y: int in range(H):
			var dx: float = abs(x - cx + 0.5)
			var dy: float = abs(y - cy + 0.5)
			# 稜形條件：dx/cx + dy/cy <= 1
			if dx / cx + dy / cy <= 1.0:
				img.set_pixel(x, y, Color(1.0, 0.92, 0.05, 1.0))
			elif dx / cx + dy / cy <= 1.25:
				img.set_pixel(x, y, Color.BLACK)
	return ImageTexture.create_from_image(img)

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
