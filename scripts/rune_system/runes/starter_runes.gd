class_name StarterRunes

class StarterQ extends RuneBase:
	func _init() -> void:
		rune_name = "起始・Q"
		description = "按下 Q 提供 1 點能量\n\"嗶嗶！一號電纜接通！有電就給我送出去！\""
		type_description="起始符文，控制法術的釋放時機，是整條符文鍊的開頭"
		category = RuneEnums.RuneCategory.STARTER
		icon_color = Color(1.0, 0.9, 0.3)
		ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

	func execute(_inputs: Dictionary, context: Node) -> Dictionary:
		return {"energy": 1.0}

class StarterW extends RuneBase:
	func _init() -> void:
		rune_name = "起始・W"
		description = "按下 W 提供 1 點能量\n\"滋滋滋...這條線聞起來怎麼有烤焦味？管他的，會漏電打人比較痛啦！\""
		type_description="起始符文，控制法術的釋放時機，是整條符文鍊的開頭"
		category = RuneEnums.RuneCategory.STARTER
		icon_color = Color(0.3, 1.0, 0.5)
		ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

	func execute(_inputs: Dictionary, context: Node) -> Dictionary:
		return {"energy": 1.0}

class StarterE extends RuneBase:
	func _init() -> void:
		rune_name = "起始・E"
		description = "按下 E 提供 1 點能量\n\"啪！系統報錯？紅燈閃個不停？用大聲公對著它吼回去就乖了！\""
		type_description="起始符文，控制法術的釋放時機，是整條符文鍊的開頭"
		category = RuneEnums.RuneCategory.STARTER
		icon_color = Color(0.3, 0.6, 1.0)
		ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

	func execute(_inputs: Dictionary, context: Node) -> Dictionary:
		return {"energy": 1.0}

class StarterR extends RuneBase:
	func _init() -> void:
		rune_name = "起始・R"
		description = "按下 R 提供 1 點能量\n\"轟！四號保險絲直接拔除！大聲公最大功率，通通給我閃開！\""
		type_description="起始符文，控制法術的釋放時機，是整條符文鍊的開頭"
		category = RuneEnums.RuneCategory.STARTER
		icon_color = Color(1.0, 0.4, 0.4)
		ports_out = [RunePort.create("energy", RuneEnums.PortType.ENERGY)]

	func execute(_inputs: Dictionary, context: Node) -> Dictionary:
		return {"energy": 1.0}
