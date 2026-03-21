class_name StarterRunes

class StarterQ extends RuneBase:
	func _init() -> void:
		rune_name = "起始・Q"
		description = "按下 Q 提供 1 點能量"
		category = RuneEnums.RuneCategory.STARTER
		icon_color = Color(1.0, 0.9, 0.3)
		ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

	func execute(_inputs: Dictionary, context: Node) -> Dictionary:
		return {"energy": 1.0}

class StarterW extends RuneBase:
	func _init() -> void:
		rune_name = "起始・W"
		description = "按下 W 提供 1 點能量"
		category = RuneEnums.RuneCategory.STARTER
		icon_color = Color(0.3, 1.0, 0.5)
		ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

	func execute(_inputs: Dictionary, context: Node) -> Dictionary:
		return {"energy": 1.0}

class StarterE extends RuneBase:
	func _init() -> void:
		rune_name = "起始・E"
		description = "按下 E 提供 1 點能量"
		category = RuneEnums.RuneCategory.STARTER
		icon_color = Color(0.3, 0.6, 1.0)
		ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

	func execute(_inputs: Dictionary, context: Node) -> Dictionary:
		return {"energy": 1.0}

class StarterR extends RuneBase:
	func _init() -> void:
		rune_name = "起始・R"
		description = "按下 R 提供 1 點能量"
		category = RuneEnums.RuneCategory.STARTER
		icon_color = Color(1.0, 0.4, 0.4)
		ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

	func execute(_inputs: Dictionary, context: Node) -> Dictionary:
		return {"energy": 1.0}
