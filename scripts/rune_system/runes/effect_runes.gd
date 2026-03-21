class_name EffectRunes

class Fireball extends RuneBase:
	func _init() -> void:
		rune_name = "火球術"
		description = "消耗能量，發射火球"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(1.0, 0.3, 0.1)
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary) -> Dictionary:
		var energy: float = inputs.get("energy", 0.0)
		var direction: Vector2 = inputs.get("direction", Vector2.RIGHT)
		var damage: float = energy * 10.0
		print("[火球術] 傷害: %s, 方向: %s" % [damage, direction])
		return {"spell": {"type": "fireball", "damage": damage, "direction": direction}}

class Heal extends RuneBase:
	func _init() -> void:
		rune_name = "治癒術"
		description = "消耗能量，恢復生命"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.2, 1.0, 0.4)
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary) -> Dictionary:
		var energy: float = inputs.get("energy", 0.0)
		var heal_amount: float = energy * 8.0
		print("[治癒術] 回血: %s" % heal_amount)
		return {"spell": {"type": "heal", "amount": heal_amount}}

class Debuff extends RuneBase:
	func _init() -> void:
		rune_name = "詛咒"
		description = "消耗能量，對目標施加減益效果"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.6, 0.1, 0.8)
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("target", RuneEnums.PortType.TARGET, false),
		]
		ports_out = [
			RunePort.create("spell", RuneEnums.PortType.SPELL),
			RunePort.create("target", RuneEnums.PortType.TARGET),
		]

	func execute(inputs: Dictionary) -> Dictionary:
		var energy: float = inputs.get("energy", 0.0)
		var target = inputs.get("target", null)
		var debuff_power: float = energy * 5.0
		print("[詛咒] 減益: %s, 目標: %s" % [debuff_power, target])
		return {
			"spell": {"type": "debuff", "power": debuff_power, "target": target},
			"target": target,
		}
