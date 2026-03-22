class_name PassiveRunes

class PassiveRuneBase extends RuneBase:
	var stored_charges: int = 0
	var max_charges: int = 3
	var _charges_to_drain: int = -1  # -1 表示全部消耗（預設行為）

	func prepare_drain(count: int) -> void:
		_charges_to_drain = count

	func _drain_charges() -> Dictionary:
		var result: Dictionary = {}
		var to_drain: int = stored_charges if _charges_to_drain < 0 else min(stored_charges, _charges_to_drain)
		_charges_to_drain = -1
		if to_drain >= 1: result["energy"] = 1.0
		if to_drain >= 2: result["energy2"] = 1.0
		if to_drain >= 3: result["energy3"] = 1.0
		stored_charges -= to_drain
		return result


class KineticEnergy extends PassiveRuneBase:
	const DISTANCE_PER_CHARGE: float = 200.0

	var _distance_accumulated: float = 0.0

	func _init() -> void:
		rune_name = "動能"
		description = "每移動 200 單位儲存一格能量，最多三格"
		category = RuneEnums.RuneCategory.PASSIVE_TRIGGER
		icon_color = Color(0.9, 0.7, 0.2)
		audio = preload("res://resources/Audio/Paon.wav")
		max_charges = 3
		ports_out = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("energy2", RuneEnums.PortType.ENERGY),
			RunePort.create("energy3", RuneEnums.PortType.ENERGY),
		]

	func accumulate_movement(distance: float) -> void:
		if stored_charges >= max_charges:
			return
		_distance_accumulated += distance
		while _distance_accumulated >= DISTANCE_PER_CHARGE and stored_charges < max_charges:
			_distance_accumulated -= DISTANCE_PER_CHARGE
			stored_charges += 1

	func execute(_inputs: Dictionary, _context: Node) -> Dictionary:
		return _drain_charges()


class Meditation extends PassiveRuneBase:
	const SECONDS_PER_CHARGE: float = 3.0

	var _timer: float = 0.0

	func _init() -> void:
		rune_name = "冥想"
		description = "停止施法每 3 秒儲存一格能量，最多兩格"
		category = RuneEnums.RuneCategory.PASSIVE_TRIGGER
		icon_color = Color(0.6, 0.4, 1.0)
		audio = preload("res://resources/Audio/Leopard.wav")
		max_charges = 2
		ports_out = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("energy2", RuneEnums.PortType.ENERGY),
		]

	func accumulate_time(delta: float) -> void:
		# 如果遊戲目前是暫停狀態，直接返回，不執行後面的計時邏輯
		if Engine.get_main_loop().root.get_tree().paused:
			return
			
		if stored_charges >= max_charges:
			return
		_timer += delta
		while _timer >= SECONDS_PER_CHARGE and stored_charges < max_charges:
			_timer -= SECONDS_PER_CHARGE
			stored_charges += 1

	func reset_timer() -> void:
		_timer = 0.0

	func execute(_inputs: Dictionary, _context: Node) -> Dictionary:
		return _drain_charges()


class BloodTribute extends PassiveRuneBase:
	const HP_PER_CHARGE: float = 30.0

	var _hp_accumulated: float = 0.0

	func _init() -> void:
		rune_name = "鮮血償還"
		description = "每累積失血 30 點儲存一格能量，最多三格"
		category = RuneEnums.RuneCategory.PASSIVE_TRIGGER
		icon_color = Color(1.0, 0.2, 0.2)
		audio = preload("res://resources/Audio/Coccinelle.wav")
		max_charges = 3
		ports_out = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("energy2", RuneEnums.PortType.ENERGY),
			RunePort.create("energy3", RuneEnums.PortType.ENERGY),
		]

	func accumulate_damage(amount: float) -> void:
		# 如果遊戲目前是暫停狀態，直接返回，不執行後面的計時邏輯
		if Engine.get_main_loop().root.get_tree().paused:
			return
			
		if stored_charges >= max_charges:
			return
			
		_hp_accumulated += amount
		while _hp_accumulated >= HP_PER_CHARGE and stored_charges < max_charges:
			_hp_accumulated -= HP_PER_CHARGE
			stored_charges += 1

	func execute(_inputs: Dictionary, _context: Node) -> Dictionary:
		
		_hp_accumulated = 0.0
		return _drain_charges()


class Steadfast extends PassiveRuneBase:
	const SECONDS_PER_CHARGE: float = 3.0

	var _timer: float = 0.0

	func _init() -> void:
		rune_name = "堅守"
		description = "完全靜止每 3 秒儲存一格能量，最多三格"
		category = RuneEnums.RuneCategory.PASSIVE_TRIGGER
		icon_color = Color(0.4, 0.8, 1.0)
		audio = preload("res://resources/Audio/Paon.wav")
		max_charges = 3
		ports_out = [
			RunePort.create("energy", RuneEnums.PortType.ENERGY),
			RunePort.create("energy2", RuneEnums.PortType.ENERGY),
			RunePort.create("energy3", RuneEnums.PortType.ENERGY),
		]

	func accumulate_stillness(delta: float) -> void:
		# 如果遊戲目前是暫停狀態，直接返回，不執行後面的計時邏輯
		if Engine.get_main_loop().root.get_tree().paused:
			return
			
		if stored_charges >= max_charges:
			return
			
		_timer += delta
		while _timer >= SECONDS_PER_CHARGE and stored_charges < max_charges:
			_timer -= SECONDS_PER_CHARGE
			stored_charges += 1

	func reset_timer() -> void:
		_timer = 0.0

	func execute(_inputs: Dictionary, _context: Node) -> Dictionary:
		return _drain_charges()
