# 傷害區域基類：靜止於場上，定期對範圍內敵人造成傷害並 emit hit_body
# 後修飾符文可掛在此節點上，連接 hit_body signal 來擴充行為
extends SpellNodeBase
class_name DamageAreaBase

var damage: float = 5.0
var effect: String = "None"
var effect_time: float = 0.0
var tick_interval: float = 0.5
var duration: float = 3.0
var visual: String = "fire"

func setup(
	p_owner: Node2D,
	p_damage: float,
	p_effect: String,
	p_effect_time: float,
	p_duration: float,
	p_tick_interval: float,
	p_visual: String = "fire"
) -> void:
	owner_node = p_owner
	damage = p_damage
	effect = p_effect
	effect_time = p_effect_time
	duration = p_duration
	tick_interval = p_tick_interval
	visual = p_visual

func _ready() -> void:
	monitoring = true
	if duration > 0.0:
		get_tree().create_timer(duration, false).timeout.connect(queue_free)
	var timer := Timer.new()
	timer.wait_time = tick_interval
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)
	match visual:
		"fire":   add_child(_create_fire_particles())
		"poison": add_child(_create_poison_particles())

func _create_poison_particles() -> CPUParticles2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.7, 0.0, 0.9, 1.0))
	gradient.set_color(1, Color(0.25, 0.0, 0.4, 0.0))

	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 200
	particles.lifetime = 1.2
	particles.explosiveness = 0.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 30.0
	particles.spread = 60.0
	particles.direction = Vector2(0.0, -1.0)
	particles.initial_velocity_min = 8.0
	particles.initial_velocity_max = 25.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 8.0
	particles.gravity = Vector2(0.0, 5.0)
	particles.color_ramp = gradient
	particles.z_index = 1
	return particles

func _create_fire_particles() -> CPUParticles2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 0.75, 0.1, 1.0))
	gradient.set_color(1, Color(0.7, 0.05, 0.0, 0.0))

	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 24
	particles.lifetime = 0.8
	particles.explosiveness = 0.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 30.0
	particles.spread = 20.0
	particles.direction = Vector2(0.0, -1.0)
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 65.0
	particles.scale_amount_min = 5.0
	particles.scale_amount_max = 9.0
	particles.gravity = Vector2(0.0, 20.0)
	particles.color_ramp = gradient
	particles.z_index = 1
	return particles

func _on_tick() -> void:
	for body: Node2D in get_overlapping_bodies():
		if body == owner_node:
			continue
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if effect != "None" and body.has_method("apply_effect"):
			body.apply_effect(effect, effect_time)
		hit_body.emit(body)

func apply_form(form: Dictionary) -> void:
	if form.has("size_scale"):
		scale = Vector2(form["size_scale"] as float, form["size_scale"] as float)
