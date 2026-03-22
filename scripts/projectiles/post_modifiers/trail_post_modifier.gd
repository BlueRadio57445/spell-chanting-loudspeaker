# 燃燒軌跡後修飾：投射物移動時定期在原位置留下火焰傷害區域
class_name TrailPostModifier extends PostModifier

const DAMAGE_AREA_SCENE: PackedScene = preload("res://scenes/damage_areas/damage_area.tscn")
const SPAWN_INTERVAL: float = 0.12  # 每隔多久留一個區域（秒）
const AREA_DURATION: float = 2.0    # 火焰區域存在時間（秒）
const AREA_DAMAGE: float = 3.0      # 每次 tick 傷害
const AREA_EFFECT_TIME: float = 3.0 # 燃燒效果持續時間
const AREA_TICK_INTERVAL: float = 0.5

var _elapsed: float = 0.0

func clone() -> PostModifier:
	return TrailPostModifier.new()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= SPAWN_INTERVAL:
		_elapsed = 0.0
		_spawn_trail_area()

func _spawn_trail_area() -> void:
	var proj: SpellNodeBase = get_parent() as SpellNodeBase
	if not is_instance_valid(proj):
		return
	var area: DamageAreaBase = DAMAGE_AREA_SCENE.instantiate() as DamageAreaBase
	area.global_position = proj.global_position
	area.setup(proj.owner_node, AREA_DAMAGE, "burn", AREA_EFFECT_TIME, AREA_DURATION, AREA_TICK_INTERVAL)
	Main.Instance.world.add_child(area)
