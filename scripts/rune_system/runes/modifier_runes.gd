class_name ModifierRunes

class Giant extends RuneBase:
	func _init() -> void:
		rune_name = "巨化"
		description = "投射物體積增大\n\"登愣！大!還要更大！\""
		type_description="前修飾符文，描述法術的釋放型態，必須放在效果符文前面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(1.0, 0.6, 0.0)
		audio = preload("res://resources/Audio/符文音檔4.wav")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("form", RuneEnums.PortType.FORM, false),
		]
		ports_out = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("form", RuneEnums.PortType.FORM),
		]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var form: Dictionary = inputs.get("form", {})
		form["size_scale"] = form.get("size_scale", 1.0) * 2.0
		return {"energy": energy, "form": form}

class MultiShot extends RuneBase:
	func _init() -> void:
		rune_name = "多段連射"
		description = "每隔 100ms 連射同方向法術，共三發\n\"噠噠噠噠噠！機關槍連發\""
		type_description = "後修飾符文，在釋放法術後為法術附魔，必須放在效果符文後面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(1.0, 0.8, 0.2)
		audio = preload("res://resources/Audio/符文音檔7.wav")
		ports_in = [RunePort.create("spell", RuneEnums.PortType.SPELL)]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var spell_list: Array = inputs.get("spell", [])
		var expanded: Array = []

		for spell: Dictionary in spell_list:
			expanded.append(spell)
			var scene: PackedScene = spell.get("scene")
			if scene == null:
				continue

			# 從 spell dict 讀取已記錄的後修飾，不依賴 original 節點是否存活
			var recorded_modifiers: Array = spell.get("post_modifiers", [])

			for i: int in 2:
				var copy: ProjectileBase = scene.instantiate()
				copy.global_position = Player.Instance.global_position
				copy.setup(Player.Instance, spell["direction"],
					spell["speed"], spell["damage"],
					spell["effect"], spell["effect_time"])
				copy.apply_form(spell.get("form", {}))

				for modifier_id: String in recorded_modifiers:
					match modifier_id:
						"quad_shot":   copy.add_child(QuadShotPostModifier.new())
						"fire_trail":  copy.add_child(TrailPostModifier.new())
						"poison_pool": copy.add_child(PoisonPoolPostModifier.new())

				var copy_spell: Dictionary = {
					"node": copy, "scene": scene,
					"form": spell.get("form", {}),
					"direction": spell["direction"],
					"damage": spell["damage"], "speed": spell["speed"],
					"effect": spell["effect"], "effect_time": spell["effect_time"],
					"post_modifiers": recorded_modifiers.duplicate(),
				}
				expanded.append(copy_spell)

				var delay: float = 0.1 * (i + 1)
				Main.Instance.get_tree().create_timer(delay).timeout.connect(func() -> void:
					Main.Instance.world.add_child(copy)
				)

		return {"spell": expanded}

class QuadShot extends RuneBase:
	func _init() -> void:
		rune_name = "四射"
		description = "命中時朝四個隨機方向發射小投射物\n\"劈哩啪啦！魅力四射\""
		type_description = "後修飾符文，在釋放法術後為法術附魔，必須放在效果符文後面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(0.9, 0.9, 0.2)
		audio = preload("res://resources/Audio/符文音檔5.wav")
		ports_in = [RunePort.create("spell", RuneEnums.PortType.SPELL)]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var spell_list: Array = inputs.get("spell", [])

		for spell: Dictionary in spell_list:
			var node_obj: Variant = spell.get("node")
			var scene: PackedScene = spell.get("scene")
			if not is_instance_valid(node_obj) or scene == null:
				continue
			var proj: SpellNodeBase = node_obj as SpellNodeBase
			var modifier: QuadShotPostModifier = QuadShotPostModifier.new()
			proj.add_child(modifier)
			if not spell.has("post_modifiers"):
				spell["post_modifiers"] = []
			(spell["post_modifiers"] as Array).append("quad_shot")

		return {"spell": spell_list}

class Boomerang extends RuneBase:
	func _init() -> void:
		rune_name = "迴力"
		description = "投射物穿透敵人，抵達最大射程後回追玩家\n\"欸？你怎麼又飛回來了！\""
		type_description="前修飾符文，描述法術的釋放型態，必須放在效果符文前面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(0.4, 0.9, 0.5)
		audio = preload("res://resources/Audio/符文音檔4.wav")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("form", RuneEnums.PortType.FORM, false),
		]
		ports_out = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("form", RuneEnums.PortType.FORM),
		]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var form: Dictionary = inputs.get("form", {})
		form["movement"] = "boomerang"
		form["penetrating"] = true
		return {"energy": energy, "form": form}

class Orbit extends RuneBase:
	func _init() -> void:
		rune_name = "環繞"
		description = "投射物環繞玩家旋轉\n\"走開!別靠近我\""
		type_description="前修飾符文，描述法術的釋放型態，必須放在效果符文前面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(0.2, 0.8, 0.9)
		audio = preload("res://resources/Audio/符文音檔2.wav")
		ports_in = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("form", RuneEnums.PortType.FORM, false),
		]
		ports_out = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("form", RuneEnums.PortType.FORM),
		]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var energy: float = inputs.get("energy", 1.0)
		var form: Dictionary = inputs.get("form", {})
		form["movement"] = "orbit"
		return {"energy": energy, "form": form}


class Shotgun extends RuneBase:
	func _init() -> void:
		rune_name = "霰彈"
		description = "在原方向兩側各增加 15 度角的方向，共三發\n\"喀嚓、轟！買一送二\""
		type_description="前修飾符文，描述法術的釋放型態，必須放在效果符文前面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(1.0, 0.7, 0.2)
		audio = preload("res://resources/Audio/符文音檔4.wav")
		ports_in = [RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false)]
		ports_out = [RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
		var result: Array = []
		for dir: Vector2 in directions:
			result.append(dir.rotated(deg_to_rad(-15.0)))
			result.append(dir)
			result.append(dir.rotated(deg_to_rad(15.0)))
		return {"direction": result}


class Deflect extends RuneBase:
	func _init() -> void:
		rune_name = "偏折"
		description = "創造正反兩個方向\n\"背後偷襲!\""
		type_description="前修飾符文，描述法術的釋放型態，必須放在效果符文前面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(0.3, 0.7, 1.0)
		audio = preload("res://resources/Audio/符文音檔5.wav")
		ports_in = [RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR, false)]
		ports_out = [RunePort.create("direction", RuneEnums.PortType.DIRECTION_VECTOR)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var directions: Array = inputs.get("direction", [Main.Instance._get_aim_direction()])
		var result: Array = []
		for dir: Vector2 in directions:
			result.append(-dir)
		result.append_array(directions)
		return {"direction": result}


class Trail extends RuneBase:
	func _init() -> void:
		rune_name = "燃燒軌跡"
		description = "投射物移動時沿路留下火焰傷害區域\n\"哈哈哈!誰敢越界\""
		type_description = "後修飾符文，在釋放法術後為法術附魔，必須放在效果符文後面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(1.0, 0.35, 0.05)
		audio = preload("res://resources/Audio/符文音檔5.wav")
		ports_in = [RunePort.create("spell", RuneEnums.PortType.SPELL)]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var spell_list: Array = inputs.get("spell", [])
		for spell: Dictionary in spell_list:
			var node_obj: Variant = spell.get("node")
			if not is_instance_valid(node_obj):
				continue
			var proj: SpellNodeBase = node_obj as SpellNodeBase
			if proj == null:
				continue
			var modifier: TrailPostModifier = TrailPostModifier.new()
			proj.add_child(modifier)
			if not spell.has("post_modifiers"):
				spell["post_modifiers"] = []
			(spell["post_modifiers"] as Array).append("fire_trail")
		return {"spell": spell_list}


class PoisonPool extends RuneBase:
	func _init() -> void:
		rune_name = "毒池"
		description = "投射物命中或消失時留下持續的毒液區域\n\"特調濃湯\""
		type_description = "後修飾符文，在釋放法術後為法術附魔，必須放在效果符文後面"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(0.6, 0.0, 0.85)
		audio = preload("res://resources/Audio/符文音檔5.wav")
		ports_in = [RunePort.create("spell", RuneEnums.PortType.SPELL)]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var spell_list: Array = inputs.get("spell", [])
		for spell: Dictionary in spell_list:
			var node_obj: Variant = spell.get("node")
			if not is_instance_valid(node_obj):
				continue
			var proj: SpellNodeBase = node_obj as SpellNodeBase
			if proj == null:
				continue
			var modifier: PoisonPoolPostModifier = PoisonPoolPostModifier.new()
			proj.add_child(modifier)
			if not spell.has("post_modifiers"):
				spell["post_modifiers"] = []
			(spell["post_modifiers"] as Array).append("poison_pool")
		return {"spell": spell_list}
