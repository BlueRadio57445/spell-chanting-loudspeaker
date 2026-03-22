# 毒池後修飾：投射物命中或自然消失時，在原位置留下持續的毒液區域
class_name PoisonPoolPostModifier extends PostModifier

const DAMAGE_AREA_SCENE: PackedScene = preload("res://scenes/damage_areas/damage_area.tscn")
const POOL_DAMAGE: float = 2.0
const POOL_EFFECT_TIME: float = 4.0
const POOL_DURATION: float = 5.0
const POOL_TICK_INTERVAL: float = 0.8

var _triggered: bool = false

func clone() -> PostModifier:
	return PoisonPoolPostModifier.new()

func _ready() -> void:
	var parent: SpellNodeBase = get_parent() as SpellNodeBase
	parent.hit_body.connect(_on_trigger)
	parent.tree_exiting.connect(_on_expire)

func _on_trigger(_body: Node2D) -> void:
	if _triggered:
		return
	_triggered = true
	var parent: SpellNodeBase = get_parent() as SpellNodeBase
	_spawn_pool(parent.global_position, parent.owner_node)

func _on_expire() -> void:
	if _triggered:
		return
	_triggered = true
	var parent: SpellNodeBase = get_parent() as SpellNodeBase
	_spawn_pool(parent.global_position, parent.owner_node)

const POOL_SCALE: float = 5

func _spawn_pool(pos: Vector2, pool_owner: Node2D) -> void:
	var area: DamageAreaBase = DAMAGE_AREA_SCENE.instantiate() as DamageAreaBase
	area.global_position = pos
	area.scale = Vector2(POOL_SCALE, POOL_SCALE)
	area.setup(pool_owner, POOL_DAMAGE, "poison", POOL_EFFECT_TIME, POOL_DURATION, POOL_TICK_INTERVAL, "poison")
	Main.Instance.world.add_child(area)
