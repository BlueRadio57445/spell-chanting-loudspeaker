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

	func execute(inputs: Dictionary, context: Node) -> Dictionary:
		# context 現在就是你的 Main.gd
		var energy: float = inputs.get("energy", 1.0) # 預設給 1.0 能量
		var damage: float = energy * 10.0
			
		var proj: ProjectileBase = preload("res://scenes/projectiles/fireball.tscn").instantiate()
		var player = Player.Instance
		proj.global_position = player.global_position
		proj.setup(player, Main.Instance._get_aim_direction(), 400.0, damage, "burn", 5.0)
		Main.Instance.world.add_child(proj)
		print(proj.effect)
		
		print("[火球術] 執行成功，消耗能量: %s" % energy)
		return {"spell": {"type": "fireball", "damage": damage}}

class Heal extends RuneBase:
	func _init() -> void:
		rune_name = "治癒術"
		description = "消耗能量，恢復生命"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.2, 1.0, 0.4)
		ports_in = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var heal_amount: float = energy * 8.0
		
		# 假設 Player.gd 有 take_damage，我們寫一個負的傷害就是回血
		if context.player and context.player.has_method("take_damage"):
			context.player.take_damage(-heal_amount)
			
		print("[治癒術] 恢復生命: %s" % heal_amount)
		return {"spell": {"type": "heal", "amount": heal_amount}}

class Debuff extends RuneBase:
	func _init() -> void:
		rune_name = "詛咒"
		description = "消耗能量，施加減益"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.6, 0.1, 0.8)
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("target", RuneEnums.PortType.TARGET, false),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		# 這裡可以呼叫你之前寫的 apply_effect
		print("[詛咒] 施放成功")
		return {"spell": {"type": "debuff", "power": energy * 5.0}}
