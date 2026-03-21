class_name ModifierRunes

class Giant extends RuneBase:
	func _init() -> void:
		rune_name = "巨化"
		description = "消耗能量，投射物體積增大"
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

class Orbit extends RuneBase:
	func _init() -> void:
		rune_name = "環繞"
		description = "消耗能量，投射物環繞玩家旋轉"
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
