class_name EffectRunes

class Fireball extends RuneBase:
	func _init() -> void:
		rune_name = "火球術"
		description = "消耗能量，發射火球\n\"別燒到我的雙馬尾！\""
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(1.0, 0.3, 0.1)
		audio = preload("res://resources/Audio/符文音檔1.wav")
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
		var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
		var player: Node2D = Player.Instance
		var spell_list: Array = []

		for dir: Vector2 in directions:
			var proj: ProjectileBase = scene.instantiate()
			proj.global_position = player.global_position
			proj.setup(player, dir, 400.0, damage, "burn", 5.0)
			proj.apply_form(form)
			Main.Instance.world.add_child(proj)
			spell_list.append({"node": proj, "scene": scene, "form": form,
				"direction": dir, "damage": damage,
				"speed": 400.0, "effect": "burn", "effect_time": 5.0})

		print("[火球術] 執行成功，消耗能量: %s" % energy)
		return {"spell": spell_list}

class EnergyBall extends RuneBase:
	func _init() -> void:
		rune_name = "能量彈"
		description = "消耗能量，發射基礎能量彈\n\"能量!...塑膠球?\""
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(1.0, 1.0, 0.4)
		audio = preload("res://resources/Audio/符文音檔3.wav")
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
		var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
		var player: Node2D = Player.Instance
		var spell_list: Array = []

		for dir: Vector2 in directions:
			var proj: ProjectileBase = scene.instantiate()
			proj.global_position = player.global_position
			proj.setup(player, dir, 500.0, damage, "None", 0.0)
			proj.apply_form(form)
			Main.Instance.world.add_child(proj)
			spell_list.append({"node": proj, "scene": scene, "form": form,
				"direction": dir, "damage": damage,
				"speed": 500.0, "effect": "None", "effect_time": 0.0})

		print("[能量彈] 執行成功，消耗能量: %s" % energy)
		return {"spell": spell_list}

class IceBall extends RuneBase:
	func _init() -> void:
		rune_name = "冰霰"
		description = "消耗能量，發射冰球，命中敵人時緩速\n\"讓你們全都透心涼!\""
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.5, 0.8, 1.0)
		audio = preload("res://resources/Audio/符文音檔2.wav")
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
		var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
		var player: Node2D = Player.Instance
		var spell_list: Array = []

		for dir: Vector2 in directions:
			var proj: ProjectileBase = scene.instantiate()
			proj.global_position = player.global_position
			proj.setup(player, dir, 350.0, damage, "slow", 3.0)
			proj.apply_form(form)
			Main.Instance.world.add_child(proj)
			spell_list.append({"node": proj, "scene": scene, "form": form,
				"direction": dir, "damage": damage,
				"speed": 350.0, "effect": "slow", "effect_time": 3.0})

		print("[冰霰] 執行成功，消耗能量: %s" % energy)
		return {"spell": spell_list}

class PoisonBall extends RuneBase:
	func _init() -> void:
		rune_name = "毒球"
		description = "消耗兩點能量，發射穿透毒球，中毒持續扣血\n\"嘔!這跟放了三天的隔夜便當一個味\""
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.4, 1.0, 0.2)
		audio = preload("res://resources/Audio/符文音檔6.wav")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
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
		var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
		var player: Node2D = Player.Instance
		var spell_list: Array = []

		for dir: Vector2 in directions:
			var proj: PenetratingProjectile = scene.instantiate() as PenetratingProjectile
			proj.global_position = player.global_position
			proj.setup(player, dir, 300.0, damage, "poison", total_energy)
			proj.apply_form(form)
			Main.Instance.world.add_child(proj)
			spell_list.append({"node": proj, "scene": scene, "form": form,
				"direction": dir, "damage": damage,
				"speed": 300.0, "effect": "poison", "effect_time": total_energy})

		print("[毒球] 執行成功，消耗能量: %s" % total_energy)
		return {"spell": spell_list}

class Heal extends RuneBase:
	const HEAL_AMOUNT: int = 20

	func _init() -> void:
		rune_name = "治療"
		description = "消耗能量，直接回復 %d 點生命值" % HEAL_AMOUNT + "\n\"呼呼!痛痛飛走了~\""
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.2, 1.0, 0.4)
		audio = preload("res://resources/Audio/符文音檔4.wav")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("energy2", RuneEnums.PortType.ENERGY),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(_inputs: Dictionary, _context: Node) -> Dictionary:
		Player.Instance.take_heal(HEAL_AMOUNT)
		print("[治療] 回復 %d 點生命值" % HEAL_AMOUNT)
		return {"spell": []}

class Debuff extends RuneBase:
	func _init() -> void:
		rune_name = "詛咒"
		description = "消耗能量，施加減益"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.6, 0.1, 0.8)
		audio = preload("res://resources/Audio/Paon.wav")
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
