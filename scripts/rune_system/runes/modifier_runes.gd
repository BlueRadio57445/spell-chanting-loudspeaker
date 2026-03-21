class_name ModifierRunes

class Giant extends RuneBase:
	func _init() -> void:
		rune_name = "巨化"
		description = "投射物體積增大"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(1.0, 0.6, 0.0)
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
		description = "每隔 100ms 連射同方向法術，共三發"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(1.0, 0.8, 0.2)
		ports_in = [RunePort.create("spell", RuneEnums.PortType.SPELL)]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var spell_list: Array = inputs.get("spell", [])
		var expanded: Array = []

		for spell: Dictionary in spell_list:
			expanded.append(spell)
			var scene: PackedScene = spell.get("scene")
			var original: ProjectileBase = spell.get("node")
			if scene == null or not is_instance_valid(original):
				continue

			# 建立第 2、3 發的節點（尚未加入場景，供下游後修飾先掛上去）
			for i: int in 2:
				var copy: ProjectileBase = scene.instantiate()
				copy.global_position = Player.Instance.global_position
				copy.setup(original.owner_node, spell["direction"],
					spell["speed"], spell["damage"],
					spell["effect"], spell["effect_time"])
				copy.apply_form(spell.get("form", {}))

				# 把 original 上已掛的 PostModifier 複製到 copy
				for child: Node in original.get_children():
					if child is PostModifier:
						copy.add_child((child as PostModifier).clone())

				var copy_spell: Dictionary = {
					"node": copy, "scene": scene,
					"form": spell.get("form", {}),
					"direction": spell["direction"],
					"damage": spell["damage"], "speed": spell["speed"],
					"effect": spell["effect"], "effect_time": spell["effect_time"],
				}
				expanded.append(copy_spell)

				# 延遲加入場景（下游後修飾已在節點上，_ready 時會初始化）
				var delay: float = 0.1 * (i + 1)
				original.get_tree().create_timer(delay).timeout.connect(func() -> void:
					Main.Instance.world.add_child(copy)
				)

		return {"spell": expanded}

class QuadShot extends RuneBase:
	func _init() -> void:
		rune_name = "四射"
		description = "命中時朝四個隨機方向發射小投射物"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(0.9, 0.9, 0.2)
		ports_in = [RunePort.create("spell", RuneEnums.PortType.SPELL)]
		ports_out = [RunePort.create("spell", RuneEnums.PortType.SPELL)]

	func execute(inputs: Dictionary, _context: Node) -> Dictionary:
		var spell_list: Array = inputs.get("spell", [])

		for spell: Dictionary in spell_list:
			var proj: ProjectileBase = spell.get("node")
			var scene: PackedScene = spell.get("scene")
			if not is_instance_valid(proj) or scene == null:
				continue
			var modifier: QuadShotPostModifier = QuadShotPostModifier.new()
			modifier.spawn_scene = scene
			proj.add_child(modifier)

		return {"spell": spell_list}

class Orbit extends RuneBase:
	func _init() -> void:
		rune_name = "環繞"
		description = "投射物環繞玩家旋轉"
		category = RuneEnums.RuneCategory.MODIFIER
		icon_color = Color(0.2, 0.8, 0.9)
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
