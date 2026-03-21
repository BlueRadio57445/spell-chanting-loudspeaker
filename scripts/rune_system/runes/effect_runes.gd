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
			RunePort.create("form", RuneEnums.PortType.FORM, false),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var damage: float = energy * 10.0
		var form: Dictionary = inputs.get("form", {})
		var scene: PackedScene = preload("res://scenes/projectiles/fireball.tscn")

		var proj: ProjectileBase = scene.instantiate()
		var player: Node2D = Player.Instance
		var direction: Vector2 = Main.Instance._get_aim_direction()
		proj.global_position = player.global_position
		proj.setup(player, direction, 400.0, damage, "burn", 5.0)
		proj.apply_form(form)
		Main.Instance.world.add_child(proj)

		print("[火球術] 執行成功，消耗能量: %s" % energy)
		return {"spell": [{"node": proj, "scene": scene, "form": form,
			"direction": direction, "damage": damage,
			"speed": 400.0, "effect": "burn", "effect_time": 5.0}]}

class EnergyBall extends RuneBase:
	func _init() -> void:
		rune_name = "能量彈"
		description = "消耗能量，發射基礎能量彈"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(1.0, 1.0, 0.4)
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false),
			RunePort.create("form", RuneEnums.PortType.FORM, false),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var damage: float = energy * 10.0
		var form: Dictionary = inputs.get("form", {})
		var scene: PackedScene = preload("res://scenes/projectiles/energy_ball.tscn")

		var proj: ProjectileBase = scene.instantiate()
		var player: Node2D = Player.Instance
		var direction: Vector2 = Main.Instance._get_aim_direction()
		proj.global_position = player.global_position
		proj.setup(player, direction, 500.0, damage, "None", 0.0)
		proj.apply_form(form)
		Main.Instance.world.add_child(proj)

		print("[能量彈] 執行成功，消耗能量: %s" % energy)
		return {"spell": [{"node": proj, "scene": scene, "form": form,
			"direction": direction, "damage": damage,
			"speed": 500.0, "effect": "None", "effect_time": 0.0}]}

class IceBall extends RuneBase:
	func _init() -> void:
		rune_name = "冰霰"
		description = "消耗能量，發射冰球，命中敵人時緩速"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.5, 0.8, 1.0)
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false),
			RunePort.create("form", RuneEnums.PortType.FORM, false),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var damage: float = energy * 5.0
		var form: Dictionary = inputs.get("form", {})
		var scene: PackedScene = preload("res://scenes/projectiles/ice_ball.tscn")

		var proj: ProjectileBase = scene.instantiate()
		var player: Node2D = Player.Instance
		var direction: Vector2 = Main.Instance._get_aim_direction()
		proj.global_position = player.global_position
		proj.setup(player, direction, 350.0, damage, "slow", 3.0)
		proj.apply_form(form)
		Main.Instance.world.add_child(proj)

		print("[冰霰] 執行成功，消耗能量: %s" % energy)
		return {"spell": [{"node": proj, "scene": scene, "form": form,
			"direction": direction, "damage": damage,
			"speed": 350.0, "effect": "slow", "effect_time": 3.0}]}

class PoisonBall extends RuneBase:
	func _init() -> void:
		rune_name = "毒球"
		description = "消耗兩點能量，發射穿透毒球，中毒持續扣血"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.4, 1.0, 0.2)
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("energy2", RuneEnums.PortType.ENERGY),
			RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false),
			RunePort.create("form", RuneEnums.PortType.FORM, false),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var energy2: float = inputs.get("energy2", 1.0)
		var total_energy: float = energy + energy2
		var damage: float = total_energy * 2.5
		var form: Dictionary = inputs.get("form", {})
		var scene: PackedScene = preload("res://scenes/projectiles/poison_ball.tscn")

		var proj: PenetratingProjectile = scene.instantiate()
		var player: Node2D = Player.Instance
		var direction: Vector2 = Main.Instance._get_aim_direction()
		proj.global_position = player.global_position
		proj.setup(player, direction, 300.0, damage, "poison", total_energy)
		proj.apply_form(form)
		Main.Instance.world.add_child(proj)

		print("[毒球] 執行成功，消耗能量: %s" % total_energy)
		return {"spell": [{"node": proj, "scene": scene, "form": form,
			"direction": direction, "damage": damage,
			"speed": 300.0, "effect": "poison", "effect_time": total_energy}]}

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
