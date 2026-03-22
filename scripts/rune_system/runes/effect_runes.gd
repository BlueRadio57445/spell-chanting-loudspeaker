class_name EffectRunes

class Fireball extends RuneBase:
	func _init() -> void:
		rune_name = "火球術"
		description = "消耗能量，發射火球\n\"別燒到我的雙馬尾！\""
		type_description = "效果符文，描述法術的主體效果"
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
		type_description = "效果符文，描述法術的主體效果"
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
		type_description = "效果符文，描述法術的主體效果"
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
		type_description = "效果符文，描述法術的主體效果"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.4, 1.0, 0.2)
		audio = preload("res://resources/Audio/符文音檔9.wav")
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
		type_description = "效果符文，描述法術的主體效果"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.2, 1.0, 0.4)
		audio = preload("res://resources/Audio/符文音檔10.wav")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("energy2", RuneEnums.PortType.ENERGY),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(_inputs: Dictionary, _context: Node) -> Dictionary:
		Player.Instance.take_heal(HEAL_AMOUNT)
		print("[治療] 回復 %d 點生命值" % HEAL_AMOUNT)
		return {"spell": []}

class Arson extends RuneBase:
	func _init() -> void:
		rune_name = "縱火"
		description = "消耗能量，在指定位置留下燃燒火焰\n\"燒吧，燒吧！\""
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(1.0, 0.45, 0.0)
		audio = preload("res://resources/Audio/符文音檔1.wav")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("form", RuneEnums.PortType.FORM, false),
			RunePort.create("target", RuneEnums.PortType.TARGET, false),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var damage: float = energy * 8.0
		var form: Dictionary = inputs.get("form", {})
		var targets: Array = inputs.get("target", [Player.Instance])
		var scene: PackedScene = preload("res://scenes/damage_areas/fire_damage_area.tscn")
		var spell_list: Array = []

		for target: Variant in targets:
			if not is_instance_valid(target) or not target is Node2D:
				continue
			var area: DamageAreaBase = scene.instantiate() as DamageAreaBase
			area.global_position = (target as Node2D).global_position
			area.setup(Player.Instance, damage, "burn", 3.0, 5.0, 0.5, "fire")
			area.apply_form(form)
			Main.Instance.world.add_child(area)
			spell_list.append({
				"node": area, "scene": scene, "form": form,
				"direction": Vector2.ZERO, "damage": damage,
				"speed": 0.0, "effect": "burn", "effect_time": 3.0
			})

		print("[縱火] 執行成功，消耗能量: %s，目標數: %d" % [energy, spell_list.size()])
		return {"spell": spell_list}

class IceDomain extends RuneBase:
	func _init() -> void:
		rune_name = "冰凍領域"
		description = "消耗能量，在指定位置留下冰凍地帶，緩速範圍內敵人\n\"別想逃！\""
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.5, 0.8, 1.0)
		audio = preload("res://resources/Audio/符文音檔2.wav")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("form", RuneEnums.PortType.FORM, false),
			RunePort.create("target", RuneEnums.PortType.TARGET, false),
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var damage: float = energy * 5.0
		var form: Dictionary = inputs.get("form", {})
		var targets: Array = inputs.get("target", [Player.Instance])
		var scene: PackedScene = preload("res://scenes/damage_areas/ice_damage_area.tscn")
		var spell_list: Array = []

		for target: Variant in targets:
			if not is_instance_valid(target) or not target is Node2D:
				continue
			var area: DamageAreaBase = scene.instantiate() as DamageAreaBase
			area.global_position = (target as Node2D).global_position
			area.setup(Player.Instance, damage, "slow", 3.0, 5.0, 0.5, "ice")
			area.apply_form(form)
			Main.Instance.world.add_child(area)
			spell_list.append({
				"node": area, "scene": scene, "form": form,
				"direction": Vector2.ZERO, "damage": damage,
				"speed": 0.0, "effect": "slow", "effect_time": 3.0
			})

		print("[冰凍領域] 執行成功，消耗能量: %s，目標數: %d" % [energy, spell_list.size()])
		return {"spell": spell_list}

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

class Invisible extends RuneBase:
	func _init() -> void:
		rune_name = "隱形"
		description = "消耗能量，施加隱形 3 秒\n\"我思故我在，只要不想到自己就沒有人能看到我!\""
		type_description = "效果符文，描述法術的主體效果"
		category = RuneEnums.RuneCategory.EFFECT
		icon_color = Color(0.046, 0.2, 0.257, 1.0)
		audio = preload("res://resources/Audio/nut.WAV")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("energy2", RuneEnums.PortType.ENERGY)
		]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		# 這裡可以呼叫你之前寫的 apply_effect
		Player.Instance.apply_invisibility(3)
		print("[隱形] 施放成功")
		return {"spell": {"type": "debuff", "power": energy * 5.0}}
